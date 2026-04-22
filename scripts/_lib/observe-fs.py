#!/usr/bin/env python3
"""observe-fs.py — 纯 Python 轮询式文件系统观察器

职责：
  1. 扫描 $PL_PROJECT 下指定路径，记录每个文件的 mtime + sha256
  2. 对比上一次 snapshot，产生 artifact.{created,modified,deleted} 事件
  3. 事件以 v1.3 信封格式写入 $PL_PROJECT/pipeline-output/trace/<change>.events.jsonl

用法：
  python3 observe-fs.py \\
    --project /path/to/project \\
    --change  add-todo-list \\
    --phase   PLAN \\
    --watch-glob "pl/changes/**" ".codebuddy/**" "app/**" \\
    --trace-id my_trace_id_here

模式：
  --once              跑一次即退出（MVP 推荐，集成到脚本里）
  --loop --interval 2 循环模式，每 N 秒扫一次（daemon 化）

设计：
  - 依赖：仅 Python 3 stdlib（零 fswatch / inotify）
  - 状态：存 $PL_PROJECT/pipeline-output/observe/snapshot.json
"""

import argparse
import hashlib
import json
import os
import sys
import time
from pathlib import Path
from datetime import datetime, timezone


DEFAULT_WATCH_GLOBS = [
    "pl/changes/**",
    ".codebuddy/**",
    ".cursor/**",
    ".claude/**",
    "adapters/**",
    "app/**",
    "src/**",
    "shared/**",
    "scripts/**",
]

# 排除路径（避免噪音爆炸）
DEFAULT_EXCLUDE_SUBSTR = [
    "node_modules/",
    ".git/",
    ".next/",
    "__pycache__/",
    ".venv/",
    "dist/",
    "build/",
    "pipeline-output/",   # 关键：不观察自己的输出
    ".DS_Store",
]


def sha256_of(path: Path, limit_bytes: int = 8 * 1024 * 1024) -> str:
    """算文件 sha256。大文件截断（超过 8MB 只算前 8MB，防止卡住）"""
    h = hashlib.sha256()
    try:
        with path.open("rb") as f:
            data = f.read(limit_bytes)
            h.update(data)
        return h.hexdigest()
    except (OSError, PermissionError):
        return "UNREADABLE"


def expand_globs(project: Path, globs):
    """把用户给的 glob 展开成实际存在的文件集合"""
    result = set()
    for g in globs:
        # glob 后没有通配符（单文件/目录）—— 走 Path.glob 也行
        for p in project.glob(g):
            if p.is_file():
                result.add(p)
            elif p.is_dir():
                for sub in p.rglob("*"):
                    if sub.is_file():
                        result.add(sub)
    # 过滤排除
    filtered = set()
    for p in result:
        rel = str(p.relative_to(project))
        if any(ex in rel or rel.startswith(ex.rstrip("/")) for ex in DEFAULT_EXCLUDE_SUBSTR):
            continue
        filtered.add(p)
    return filtered


def scan(project: Path, globs):
    """扫当前状态，返回 {rel_path: (mtime, sha256)}"""
    files = expand_globs(project, globs)
    snap = {}
    for f in files:
        try:
            st = f.stat()
        except OSError:
            continue
        rel = str(f.relative_to(project))
        # mtime 作为 hash 的先行筛选；相同 mtime 跳 sha
        snap[rel] = {
            "mtime": st.st_mtime,
            "size": st.st_size,
            # 延迟算 sha（diff 时才算），先不算减少启动开销
            "sha256": None,
        }
    return snap


def compute_sha_for_diff(project: Path, paths):
    """只对 diff 中涉及的文件算 sha256（性能优化）"""
    result = {}
    for rel in paths:
        full = project / rel
        if full.exists():
            result[rel] = sha256_of(full)
    return result


def diff_snapshots(prev: dict, curr: dict, project: Path):
    """返回 (created, modified, deleted) 三个集合 + 路径 → sha256 字典"""
    prev_paths = set(prev.keys())
    curr_paths = set(curr.keys())

    created = curr_paths - prev_paths
    deleted = prev_paths - curr_paths

    modified = set()
    for p in curr_paths & prev_paths:
        # mtime 不同才比 sha（快路径）
        if curr[p]["mtime"] != prev[p].get("mtime"):
            modified.add(p)

    # 为了精确，给 created/modified 计算当前 sha；deleted 用 prev 里的
    changed_paths = created | modified
    shas = compute_sha_for_diff(project, changed_paths)

    # 再次过滤 modified：sha 相同就不算真修改（mtime 变但内容没变）
    real_modified = set()
    for p in modified:
        new_sha = shas.get(p)
        old_sha = prev[p].get("sha256")
        if old_sha is None or new_sha != old_sha:
            real_modified.add(p)

    return created, real_modified, deleted, shas


def make_event(trace_id, change_id, phase, event_type, data):
    """组装 v1.3 信封"""
    return {
        "ts": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "trace_id": trace_id,
        "change_id": change_id,
        "phase": phase,
        "actor": "fs-watcher:observe-fs@1.0.0",
        "event": event_type,
        "data": data,
    }


def emit_events(events, trace_file: Path):
    trace_file.parent.mkdir(parents=True, exist_ok=True)
    with trace_file.open("a", encoding="utf-8") as f:
        for e in events:
            f.write(json.dumps(e, ensure_ascii=False) + "\n")


def load_snapshot(snap_file: Path):
    if snap_file.exists():
        try:
            return json.loads(snap_file.read_text())
        except Exception:
            return {}
    return {}


def save_snapshot(snap_file: Path, snap: dict):
    snap_file.parent.mkdir(parents=True, exist_ok=True)
    snap_file.write_text(json.dumps(snap, indent=2), encoding="utf-8")


def run_once(project: Path, change_id: str, phase: str, trace_id: str,
             globs, verbose=False) -> int:
    """扫一次 → diff → 写事件 → 更新 snapshot。返回新事件数。"""
    out_dir = project / "pipeline-output"
    trace_file = out_dir / "trace" / f"{change_id}.events.jsonl"
    snap_file = out_dir / "observe" / "snapshot.json"

    prev = load_snapshot(snap_file)
    curr_raw = scan(project, globs)

    created, modified, deleted, shas = diff_snapshots(prev, curr_raw, project)

    # 更新 curr 里的 sha256（只对变化的）
    for p in created | modified:
        if p in shas:
            curr_raw[p]["sha256"] = shas[p]
    # 未变化的文件，继承上次 sha
    for p, meta in curr_raw.items():
        if meta["sha256"] is None and p in prev:
            curr_raw[p]["sha256"] = prev[p].get("sha256")

    events = []
    for p in sorted(created):
        events.append(make_event(trace_id, change_id, phase, "artifact.created", {
            "path": p,
            "sha256_after": shas.get(p),
            "size": curr_raw[p]["size"],
        }))
    for p in sorted(modified):
        events.append(make_event(trace_id, change_id, phase, "artifact.modified", {
            "path": p,
            "sha256_before": prev[p].get("sha256"),
            "sha256_after": shas.get(p),
            "size": curr_raw[p]["size"],
        }))
    for p in sorted(deleted):
        events.append(make_event(trace_id, change_id, phase, "artifact.deleted", {
            "path": p,
            "sha256_before": prev[p].get("sha256"),
        }))

    if events:
        emit_events(events, trace_file)

    save_snapshot(snap_file, curr_raw)

    if verbose:
        print(f"[observe-fs] scanned={len(curr_raw)} "
              f"created={len(created)} modified={len(modified)} deleted={len(deleted)} "
              f"-> {trace_file}")

    return len(events)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--project", required=True, help="项目根目录")
    parser.add_argument("--change", required=True, help="change_id")
    parser.add_argument("--phase", default="IMPLEMENT", help="phase")
    parser.add_argument("--trace-id", default=None,
                        help="trace_id，不给就自动生成 <change>_<YYYYmmdd>_<HHMMSS>")
    parser.add_argument("--watch-glob", action="append", default=None,
                        help="多个 --watch-glob 累加，默认扫常见目录")
    parser.add_argument("--once", action="store_true", default=True,
                        help="扫一次退出（默认）")
    parser.add_argument("--loop", action="store_true", help="循环模式")
    parser.add_argument("--interval", type=float, default=2.0, help="循环间隔秒数")
    parser.add_argument("--verbose", action="store_true")
    args = parser.parse_args()

    project = Path(args.project).resolve()
    if not project.exists():
        print(f"project not found: {project}", file=sys.stderr)
        sys.exit(1)

    trace_id = args.trace_id or f"{args.change}_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
    globs = args.watch_glob or DEFAULT_WATCH_GLOBS

    if args.loop:
        print(f"[observe-fs] loop mode, interval={args.interval}s. ^C to stop.")
        try:
            while True:
                run_once(project, args.change, args.phase, trace_id, globs, args.verbose)
                time.sleep(args.interval)
        except KeyboardInterrupt:
            print("\n[observe-fs] stopped.")
    else:
        n = run_once(project, args.change, args.phase, trace_id, globs, args.verbose)
        print(f"[observe-fs] emitted {n} event(s)")


if __name__ == "__main__":
    main()
