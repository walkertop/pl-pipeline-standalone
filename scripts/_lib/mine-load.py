#!/usr/bin/env python3
"""mine-load.py — retro-miner 的数据加载层

职责：从多个项目 / 多条 events.jsonl 读取事件，归一化成统一的 DataFrame-like
结构（但用纯 stdlib，不依赖 pandas）。

用法：
  python3 mine-load.py \\
    --sources path1.jsonl path2.jsonl path3/pipeline-output/trace/*.jsonl \\
    --out /tmp/mined-events.json

输出：单一 JSON 数组，每条事件加了 _source_file / _source_line 字段。
"""

import argparse
import glob
import json
import sys
from pathlib import Path


def load_jsonl(path: Path):
    """加载一个 jsonl 文件，返回事件列表。"""
    events = []
    if not path.exists():
        return events
    for lineno, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        line = line.strip()
        if not line:
            continue
        try:
            ev = json.loads(line)
            ev["_source_file"] = str(path)
            ev["_source_line"] = lineno
            events.append(ev)
        except json.JSONDecodeError:
            continue
    return events


def expand_sources(patterns):
    """把 --sources 里的 glob 展开成实际文件列表。"""
    files = []
    for p in patterns:
        if any(c in p for c in ["*", "?", "["]):
            files.extend(sorted(Path(m) for m in glob.glob(p, recursive=True)))
        else:
            pp = Path(p)
            if pp.is_dir():
                # 目录则递归扫 *.events.jsonl
                files.extend(sorted(pp.rglob("*.events.jsonl")))
            elif pp.is_file():
                files.append(pp)
    return files


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--sources", nargs="+", required=True,
                    help="jsonl 文件路径或 glob，也可以是目录")
    ap.add_argument("--out", required=True, help="输出 JSON 文件路径")
    ap.add_argument("--verbose", action="store_true")
    args = ap.parse_args()

    files = expand_sources(args.sources)
    if not files:
        print("[mine-load] no source files found", file=sys.stderr)
        sys.exit(1)

    all_events = []
    file_stats = []
    for f in files:
        evs = load_jsonl(f)
        all_events.extend(evs)
        file_stats.append((str(f), len(evs)))

    # 稳定排序：按 ts + trace_id
    all_events.sort(key=lambda e: (e.get("ts", ""), e.get("trace_id", "")))

    out = Path(args.out)
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(all_events, ensure_ascii=False, indent=None))

    if args.verbose:
        for f, n in file_stats:
            print(f"  {n:>5} events  {f}")
    print(f"[mine-load] loaded {len(all_events)} events from {len(files)} file(s) -> {out}")


if __name__ == "__main__":
    main()
