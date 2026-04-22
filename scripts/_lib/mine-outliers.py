#!/usr/bin/env python3
"""mine-outliers.py — Pattern 4：异常点挖掘

找数值/频次偏离常态的事件。v1 先做两件事：
  1. check.run 的 duration_sec 异常（z-score）
  2. 某 checker 在某 trace 里 fail 次数异常高

输出：markdown，按 z-score 降序。
"""

import argparse
import json
import statistics
from collections import defaultdict
from pathlib import Path


def mine_duration(events, z_threshold=3.0, min_samples=5):
    """对每个 checker 算 duration_sec 的 z-score，找超出阈值的异常点。"""
    by_checker = defaultdict(list)  # checker -> [(duration, event)]
    for e in events:
        if e.get("event") != "check.run":
            continue
        d = e.get("data") or {}
        dur = d.get("duration_sec")
        checker = d.get("checker", "?")
        if dur is None:
            continue
        try:
            dur = float(dur)
        except (TypeError, ValueError):
            continue
        by_checker[checker].append((dur, e))

    outliers = []
    for checker, samples in by_checker.items():
        if len(samples) < min_samples:
            continue  # 样本太少
        values = [s[0] for s in samples]
        mean = statistics.mean(values)
        stdev = statistics.stdev(values) if len(values) > 1 else 0
        if stdev == 0:
            continue
        for dur, e in samples:
            z = (dur - mean) / stdev
            if abs(z) >= z_threshold:
                outliers.append({
                    "checker": checker,
                    "duration": dur,
                    "mean": mean,
                    "stdev": stdev,
                    "z": z,
                    "trace_id": e.get("trace_id", "?"),
                    "source_line": e.get("_source_line"),
                })
    outliers.sort(key=lambda o: -abs(o["z"]))
    return outliers


def mine_fail_bursts(events, min_bursts=3):
    """找同一 trace 内同 checker 连续失败的 burst。"""
    by_trace_checker = defaultdict(list)  # (trace, checker) -> [status]
    for e in events:
        if e.get("event") != "check.run":
            continue
        d = e.get("data") or {}
        tid = e.get("trace_id", "?")
        ch = d.get("checker", "?")
        st = d.get("status", "?")
        by_trace_checker[(tid, ch)].append(st)

    bursts = []
    for (tid, ch), statuses in by_trace_checker.items():
        fail_cnt = sum(1 for s in statuses if s == "fail")
        if fail_cnt >= min_bursts:
            bursts.append({
                "trace_id": tid,
                "checker": ch,
                "fail_count": fail_cnt,
                "total": len(statuses),
            })
    bursts.sort(key=lambda b: -b["fail_count"])
    return bursts


def render_md(duration_outliers, fail_bursts, total_events):
    lines = [
        "# Pattern 4 · 异常点",
        "",
        f"- events scanned: **{total_events}**",
        "",
        "## 4.1 check.run duration 异常（z-score ≥ 3）",
        "",
    ]
    if not duration_outliers:
        lines.append("_(no duration outliers detected)_")
    else:
        lines.append("| checker | duration(s) | 常态 (mean ± stdev) | z-score | trace_id |")
        lines.append("|---|---|---|---|---|")
        for o in duration_outliers:
            normal = f"{o['mean']:.1f} ± {o['stdev']:.1f}"
            lines.append(
                f"| `{o['checker']}` | {o['duration']:.1f} "
                f"| {normal} | {o['z']:.2f} | `{o['trace_id']}` |"
            )
    lines.append("")

    lines.append("## 4.2 check.run 失败 burst（同 trace 同 checker 失败 ≥ 3 次）")
    lines.append("")
    if not fail_bursts:
        lines.append("_(no fail bursts detected)_")
    else:
        lines.append("| trace_id | checker | fail / total |")
        lines.append("|---|---|---|")
        for b in fail_bursts:
            lines.append(f"| `{b['trace_id']}` | `{b['checker']}` | {b['fail_count']} / {b['total']} |")
    lines.append("")
    lines.append("**提示**：duration 异常常指向 CI/网络/资源问题；fail burst 常指向 retry-heavy 的 check（改完代码直接跑没过就再跑）。")
    return "\n".join(lines)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--events", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--z-threshold", type=float, default=3.0)
    ap.add_argument("--min-samples", type=int, default=5)
    ap.add_argument("--min-bursts", type=int, default=3)
    args = ap.parse_args()

    events = json.loads(Path(args.events).read_text())
    outliers = mine_duration(events, args.z_threshold, args.min_samples)
    bursts = mine_fail_bursts(events, args.min_bursts)
    md = render_md(outliers, bursts, len(events))
    Path(args.out).write_text(md, encoding="utf-8")
    print(f"[mine-outliers] {len(events)} events -> "
          f"{len(outliers)} duration outliers, {len(bursts)} fail bursts -> {args.out}")


if __name__ == "__main__":
    main()
