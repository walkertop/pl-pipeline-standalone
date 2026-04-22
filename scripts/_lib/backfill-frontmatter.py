#!/usr/bin/env python3
"""补齐 adapter 资产（agent/skill/rule）的 frontmatter 里 id + version 字段。

幂等：已有 id 的不覆盖；有 name 无 id 的用 name 作为 id；没有 version 的补 1.0.0。
"""
import re
import sys
from pathlib import Path

DEFAULT_VERSION = "1.0.0"

def patch_file(path: Path) -> tuple[bool, str]:
    text = path.read_text(encoding="utf-8")
    if not text.startswith("---\n"):
        # 完全没有 frontmatter，生成最小 frontmatter
        slug = path.stem
        fm = f"---\nid: {slug}\nversion: {DEFAULT_VERSION}\nfrontmatter_added_by: backfill-v1.3\n---\n\n"
        return True, fm + text

    # 已有 frontmatter
    m = re.match(r"^---\n(.*?)\n---\n", text, re.S)
    if not m:
        return False, text
    fm_body = m.group(1)
    rest = text[m.end():]

    lines = fm_body.splitlines()
    has_id = any(re.match(r"^\s*id\s*:", l) for l in lines)
    has_version = any(re.match(r"^\s*version\s*:", l) for l in lines)
    name_match = next((re.match(r"^\s*name\s*:\s*(.+)$", l) for l in lines if re.match(r"^\s*name\s*:", l)), None)

    changed = False
    new_lines = list(lines)
    if not has_id:
        slug = name_match.group(1).strip().strip('"').strip("'") if name_match else path.stem
        # 放到 frontmatter 顶部
        new_lines.insert(0, f"id: {slug}")
        changed = True
    if not has_version:
        new_lines.append(f"version: {DEFAULT_VERSION}")
        changed = True

    if not changed:
        return False, text

    new_text = "---\n" + "\n".join(new_lines) + "\n---\n" + rest
    return True, new_text


def main():
    root = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(".")
    targets = []
    for sub in ["adapters/*/agents/*.md", "adapters/*/skills/*.md", "adapters/*/rules/*.md"]:
        targets.extend(root.glob(sub))

    changed_count = 0
    for f in sorted(targets):
        changed, new_text = patch_file(f)
        if changed:
            f.write_text(new_text, encoding="utf-8")
            changed_count += 1
            print(f"patched: {f}")

    print(f"\ntotal files scanned: {len(targets)}, patched: {changed_count}")


if __name__ == "__main__":
    main()
