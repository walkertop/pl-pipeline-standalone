#!/usr/bin/env python3
"""pl-pipeline IDE sync 核心实现。

依赖：python3 + PyYAML（与 pl 其它脚本保持一致；缺失时给出明确报错）。

被 scripts/pl-ide.sh 调用。提供以下子命令：
  detect    扫描项目目录，输出 IDE id 列表（每行一个）
  manifest  解析指定 IDE manifest，输出归一化后的 JSON（供 shell 读取）
  sync      把 pl/{rules,agents,...} 同步到指定 IDE 目录
  unsync    撤回 sync 写入的文件（依赖 hash 标记识别）
  list      列出 sync 写过的所有文件（hash 标记识别）

设计要点
--------
1. **Hash 标记**：所有 pl 写入的文件首行（或 frontmatter 之后第一行）插入：
       <!-- pl-managed: hash=<sha256-12> source=<path> ide=<id> -->
   - unsync 严格要求该行存在，且 hash 等于"剔除该行后再 sha256"得到的值。
     若不等，说明用户手改过 → 默认拒绝删除，需 --force。
2. **三层 source_chain**：按顺序找第一个存在的目录作为 source。
3. **frontmatter 策略**：
   - strip_frontmatter=true：删除 codebuddy 的 `---...---`
   - add_frontmatter='...'：在文件最前面追加（{name} 占位会被替换）
4. **不复制 / 仅引用**：enabled=false 的 section 完全跳过；
   AGENTS.md 由 sync 命令负责生成"reference 列表"。
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import shutil
import sys
from pathlib import Path
from typing import Any

try:
    import yaml  # type: ignore
except ImportError:
    sys.stderr.write(
        "[pl-ide] 致命错误：缺少 PyYAML。请运行 `pip3 install --user pyyaml` 后重试。\n"
    )
    sys.exit(2)


HASH_MARKER_RE = re.compile(
    r"<!--\s*pl-managed:\s*hash=([0-9a-f]{12})\s+source=(\S+)\s+ide=(\S+)\s*-->"
)
FRONTMATTER_RE = re.compile(r"^---\n.*?\n---\n", re.DOTALL)


# ---------------------------------------------------------------------------
# 工具函数
# ---------------------------------------------------------------------------
def _expand(template: str, ctx: dict[str, str]) -> str:
    """简单 {VAR} 替换；不支持嵌套。"""
    out = template
    for k, v in ctx.items():
        out = out.replace("{" + k + "}", v)
    return out


def _sha256_12(text: str) -> str:
    return hashlib.sha256(text.encode("utf-8")).hexdigest()[:12]


def _strip_marker(content: str) -> str:
    """剔除文件中所有 hash 标记行（用于校验和重新计算 hash）。"""
    return "\n".join(
        line for line in content.splitlines() if not HASH_MARKER_RE.search(line)
    ) + ("\n" if content.endswith("\n") else "")


def _strip_frontmatter(content: str) -> str:
    return FRONTMATTER_RE.sub("", content, count=1)


def _build_marker(source_path: str, ide_id: str, body_without_marker: str) -> str:
    return (
        f"<!-- pl-managed: hash={_sha256_12(body_without_marker)} "
        f"source={source_path} ide={ide_id} -->"
    )


# ---------------------------------------------------------------------------
# manifest 解析 + path 归一化
# ---------------------------------------------------------------------------
def load_manifest(pl_home: Path, ide_id: str) -> dict[str, Any]:
    path = pl_home / "ide-integrations" / ide_id / "manifest.yaml"
    if not path.exists():
        sys.stderr.write(f"[pl-ide] 未知 IDE: {ide_id}（找不到 {path}）\n")
        sys.exit(2)
    with path.open() as f:
        return yaml.safe_load(f)


def list_supported_ides(pl_home: Path) -> list[str]:
    root = pl_home / "ide-integrations"
    if not root.exists():
        return []
    return sorted(
        d.name for d in root.iterdir()
        if d.is_dir() and (d / "manifest.yaml").exists()
    )


def resolve_source_dir(
    section: dict[str, Any], pl_home: Path, pl_project: Path
) -> Path | None:
    """从 source / source_chain 选第一个存在的目录。"""
    ctx = {"PL_HOME": str(pl_home), "PL_PROJECT": str(pl_project)}
    if "source" in section:
        candidate = Path(_expand(section["source"], ctx))
        if not candidate.is_absolute():
            candidate = pl_home / candidate
        return candidate if candidate.exists() else None
    for raw in section.get("source_chain", []):
        candidate = Path(_expand(raw, ctx))
        if candidate.exists() and any(candidate.iterdir()):
            return candidate
    return None


# ---------------------------------------------------------------------------
# detect
# ---------------------------------------------------------------------------
def cmd_detect(args: argparse.Namespace) -> int:
    pl_project = Path(args.pl_project).resolve()
    pl_home = Path(args.pl_home).resolve()
    found = []
    for ide_id in list_supported_ides(pl_home):
        m = load_manifest(pl_home, ide_id)
        for marker in m.get("detect", {}).get("any_of", []):
            if (pl_project / marker).exists():
                found.append(ide_id)
                break
    print("\n".join(found))
    return 0


# ---------------------------------------------------------------------------
# sync
# ---------------------------------------------------------------------------
def _sync_section(
    section_name: str,
    section: dict[str, Any],
    manifest: dict[str, Any],
    pl_home: Path,
    pl_project: Path,
    dry_run: bool,
    force: bool,
) -> tuple[int, int, list[str]]:
    """同步一个 section（rules / commands / agents / skills）。

    返回 (written, skipped, paths_written)。
    """
    if not section.get("enabled"):
        return 0, 0, []
    src_dir = resolve_source_dir(section, pl_home, pl_project)
    if src_dir is None:
        return 0, 0, []
    target_dir = pl_project / section["target"]
    target_dir.mkdir(parents=True, exist_ok=True)
    target_ext = section["target_ext"]
    name_prefix = section.get("name_prefix", "")
    strip_fm = section.get("strip_frontmatter", False)
    add_fm_template = section.get("add_frontmatter", "") or ""
    ide_id = manifest["ide_id"]

    written = 0
    skipped = 0
    paths_written: list[str] = []
    for src in sorted(src_dir.iterdir()):
        if not src.is_file() or src.name.startswith("README") or src.name.startswith("."):
            continue
        if src.suffix not in (".md", ".mdc"):
            continue
        stem = src.stem
        target_name = f"{name_prefix}{stem}{target_ext}"
        target = target_dir / target_name

        # 读取源
        body = src.read_text(encoding="utf-8")
        if strip_fm:
            body = _strip_frontmatter(body)
        if add_fm_template:
            body = _expand(add_fm_template, {"name": stem}) + body

        marker = _build_marker(
            source_path=str(src.relative_to(pl_home)),
            ide_id=ide_id,
            body_without_marker=body,
        )
        # 把 marker 放在 frontmatter 之后第一行
        if body.startswith("---\n"):
            end = body.find("\n---\n", 4)
            if end != -1:
                end += len("\n---\n")
                final = body[:end] + marker + "\n" + body[end:]
            else:
                final = marker + "\n" + body
        else:
            final = marker + "\n" + body

        # 已存在 → 校验是否被用户手改
        if target.exists():
            existing = target.read_text(encoding="utf-8")
            ex_match = HASH_MARKER_RE.search(existing)
            if ex_match is None:
                if not force:
                    sys.stderr.write(
                        f"  [skip] {target} 已存在但非 pl 管理（无 hash 标记），跳过；--force 覆盖\n"
                    )
                    skipped += 1
                    continue
            else:
                claimed = ex_match.group(1)
                actual = _sha256_12(_strip_marker(existing))
                if claimed != actual and not force:
                    sys.stderr.write(
                        f"  [skip] {target} 被手工修改过（hash 不匹配），跳过；--force 覆盖\n"
                    )
                    skipped += 1
                    continue
            # 内容一样就别重写（避免 mtime 抖动）
            if existing == final:
                continue

        if dry_run:
            sys.stderr.write(f"  [dry-run] would write {target}\n")
        else:
            target.write_text(final, encoding="utf-8")
        written += 1
        paths_written.append(str(target.relative_to(pl_project)))

    return written, skipped, paths_written


def _scan_managed(target_dir: Path, ide_id: str) -> list[str]:
    """扫描 target_dir 下所有标了本 IDE pl-managed 标记的文件。返回相对项目根的路径。"""
    if not target_dir.exists():
        return []
    out: list[str] = []
    for p in sorted(target_dir.rglob("*")):
        if not p.is_file() or p.suffix not in (".md", ".mdc"):
            continue
        try:
            head = p.read_text(encoding="utf-8", errors="ignore")[:2000]
        except OSError:
            continue
        m = HASH_MARKER_RE.search(head)
        if m and m.group(3) == ide_id:
            out.append(p)
    return out


def _build_agents_md_section(
    manifest: dict[str, Any],
    pl_project: Path,
    pl_home: Path,
    written_by_section: dict[str, list[str]],
) -> str:
    """生成根 AGENTS.md 中由 pl 管理的那一段。"""
    ide_id = manifest["ide_id"]
    lines: list[str] = []
    lines.append(f"## pl-pipeline ({ide_id})")
    lines.append("")
    lines.append("> 本节由 `pl ide sync` 自动生成，不要手工编辑（编辑请改 `pl/AGENTS.md`）。")
    lines.append("")

    # rules / commands / agents 的当前总状态（扫描标记，不依赖本次写入数）
    for section_name in ("rules", "commands", "agents"):
        section = manifest.get("sync", {}).get(section_name, {})
        if not section.get("enabled"):
            continue
        target_dir = pl_project / section["target"]
        managed = _scan_managed(target_dir, ide_id)
        if managed:
            lines.append(f"### {section_name}（{len(managed)} 个）")
            for p in managed:
                rel = p.relative_to(pl_project)
                lines.append(f"- `{rel}`")
            lines.append("")

    # 引用型：agents / skills 没有复制时也要在 AGENTS.md 列出来
    for section_name in ("agents", "skills"):
        section = manifest.get("sync", {}).get(section_name, {})
        if section.get("enabled"):
            continue
        src = resolve_source_dir(section, pl_home, pl_project) if section else None
        # fallback：找 pl/<section>
        if src is None:
            cand = pl_project / "pl" / section_name
            if cand.exists():
                src = cand
        if src is None:
            continue
        files = sorted(
            f for f in src.iterdir()
            if f.is_file() and f.suffix == ".md" and not f.name.startswith("README")
        )
        if not files:
            continue
        lines.append(f"### {section_name}（引用模式，无复制）")
        for f in files:
            try:
                rel = f.relative_to(pl_project)
            except ValueError:
                rel = f
            lines.append(f"- `@{rel}`")
        lines.append("")

    return "\n".join(lines).rstrip() + "\n"


def _update_root_agents_md(
    pl_project: Path,
    manifest: dict[str, Any],
    new_section: str,
    dry_run: bool,
) -> None:
    cfg = manifest.get("root_agents_md", {})
    if not cfg.get("enabled"):
        return
    begin = cfg["marker_begin"]
    end = cfg["marker_end"]
    target = pl_project / "AGENTS.md"
    block = f"{begin}\n{new_section}{end}\n"

    if target.exists():
        existing = target.read_text(encoding="utf-8")
        if begin in existing and end in existing:
            pattern = re.compile(
                re.escape(begin) + r".*?" + re.escape(end) + r"\n?",
                re.DOTALL,
            )
            new_content = pattern.sub(block, existing)
        else:
            sep = "" if existing.endswith("\n") else "\n"
            new_content = existing + sep + "\n" + block
    else:
        new_content = (
            "# AGENTS.md\n\n"
            "> 本项目使用 [pl-pipeline](https://github.com/) 管理 AI 工作流。\n"
            "> 完整工作流定义见 `pl/AGENTS.md`（canonical source）。\n\n"
            f"{block}"
        )

    if dry_run:
        sys.stderr.write(f"  [dry-run] would update {target}\n")
        return
    target.write_text(new_content, encoding="utf-8")


def cmd_sync(args: argparse.Namespace) -> int:
    pl_home = Path(args.pl_home).resolve()
    pl_project = Path(args.pl_project).resolve()
    ide_id = args.ide
    manifest = load_manifest(pl_home, ide_id)

    sys.stderr.write(f"\n[{ide_id}] sync → {pl_project}\n")
    written_by_section: dict[str, list[str]] = {}
    total_written = 0
    total_skipped = 0
    for section_name in ("rules", "commands", "agents", "skills"):
        section = manifest.get("sync", {}).get(section_name, {})
        if not section.get("enabled"):
            continue
        sys.stderr.write(f"  [{section_name}]\n")
        w, s, paths = _sync_section(
            section_name, section, manifest, pl_home, pl_project,
            dry_run=args.dry_run, force=args.force,
        )
        sys.stderr.write(f"    written={w} skipped={s}\n")
        total_written += w
        total_skipped += s
        written_by_section[section_name] = paths

    section_text = _build_agents_md_section(
        manifest, pl_project, pl_home, written_by_section
    )
    _update_root_agents_md(pl_project, manifest, section_text, args.dry_run)

    sys.stderr.write(
        f"  → 共 written={total_written}, skipped={total_skipped}\n"
    )
    return 0


# ---------------------------------------------------------------------------
# unsync
# ---------------------------------------------------------------------------
def cmd_unsync(args: argparse.Namespace) -> int:
    pl_home = Path(args.pl_home).resolve()
    pl_project = Path(args.pl_project).resolve()
    ide_id = args.ide
    manifest = load_manifest(pl_home, ide_id)

    sys.stderr.write(f"\n[{ide_id}] unsync ← {pl_project}\n")
    removed = 0
    skipped = 0
    for section_name in ("rules", "commands", "agents", "skills"):
        section = manifest.get("sync", {}).get(section_name, {})
        if not section.get("enabled"):
            continue
        target_dir = pl_project / section["target"]
        if not target_dir.exists():
            continue
        for f in sorted(target_dir.iterdir()):
            if not f.is_file():
                continue
            content = f.read_text(encoding="utf-8")
            m = HASH_MARKER_RE.search(content)
            if m is None:
                sys.stderr.write(f"  [skip] {f} 无 pl 标记\n")
                skipped += 1
                continue
            if m.group(3) != ide_id:
                sys.stderr.write(f"  [skip] {f} 属于 {m.group(3)} 而非 {ide_id}\n")
                skipped += 1
                continue
            claimed = m.group(1)
            actual = _sha256_12(_strip_marker(content))
            if claimed != actual and not args.force:
                sys.stderr.write(f"  [skip] {f} 被手工修改, --force 强删\n")
                skipped += 1
                continue
            if args.dry_run:
                sys.stderr.write(f"  [dry-run] would rm {f}\n")
            else:
                f.unlink()
            removed += 1
        # 目录空了顺手 rmdir
        if target_dir.exists() and not any(target_dir.iterdir()) and not args.dry_run:
            try:
                target_dir.rmdir()
            except OSError:
                pass

    # AGENTS.md 段落剔除
    cfg = manifest.get("root_agents_md", {})
    if cfg.get("enabled"):
        target = pl_project / "AGENTS.md"
        if target.exists():
            begin = cfg["marker_begin"]
            end = cfg["marker_end"]
            existing = target.read_text(encoding="utf-8")
            pattern = re.compile(
                r"\n*" + re.escape(begin) + r".*?" + re.escape(end) + r"\n?",
                re.DOTALL,
            )
            new_content = pattern.sub("\n", existing)
            if new_content != existing and not args.dry_run:
                target.write_text(new_content, encoding="utf-8")

    sys.stderr.write(f"  → removed={removed}, skipped={skipped}\n")
    return 0


# ---------------------------------------------------------------------------
# list
# ---------------------------------------------------------------------------
def cmd_list(args: argparse.Namespace) -> int:
    pl_project = Path(args.pl_project).resolve()
    items: list[dict[str, str]] = []
    for root, _dirs, files in os.walk(pl_project):
        # 跳过 .git / node_modules
        if any(seg in Path(root).parts for seg in (".git", "node_modules")):
            continue
        for name in files:
            if not name.endswith((".md", ".mdc")):
                continue
            p = Path(root) / name
            try:
                head = p.read_text(encoding="utf-8", errors="ignore")[:2000]
            except OSError:
                continue
            m = HASH_MARKER_RE.search(head)
            if m is None:
                continue
            items.append({
                "path": str(p.relative_to(pl_project)),
                "hash": m.group(1),
                "source": m.group(2),
                "ide": m.group(3),
            })
    print(json.dumps(items, indent=2, ensure_ascii=False))
    return 0


# ---------------------------------------------------------------------------
# main
# ---------------------------------------------------------------------------
def main() -> int:
    parser = argparse.ArgumentParser(prog="pl_ide_sync")
    sub = parser.add_subparsers(dest="cmd", required=True)

    common = argparse.ArgumentParser(add_help=False)
    common.add_argument("--pl-home", required=True)
    common.add_argument("--pl-project", required=True)

    p_detect = sub.add_parser("detect", parents=[common])
    p_detect.set_defaults(func=cmd_detect)

    p_sync = sub.add_parser("sync", parents=[common])
    p_sync.add_argument("--ide", required=True)
    p_sync.add_argument("--dry-run", action="store_true")
    p_sync.add_argument("--force", action="store_true")
    p_sync.set_defaults(func=cmd_sync)

    p_unsync = sub.add_parser("unsync", parents=[common])
    p_unsync.add_argument("--ide", required=True)
    p_unsync.add_argument("--dry-run", action="store_true")
    p_unsync.add_argument("--force", action="store_true")
    p_unsync.set_defaults(func=cmd_unsync)

    p_list = sub.add_parser("list", parents=[common])
    p_list.set_defaults(func=cmd_list)

    args = parser.parse_args()
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
