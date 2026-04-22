#!/usr/bin/env python3
"""mine-anti-pattern.py — Pattern 3：反模式挖掘

问：什么事件 pattern **经常导致** gate blocked / check fail？

算法：
  1. 找所有"失败事件"（gate.eval blocked / check.run fail）作为 target
  2. 往前回溯同 trace_id 里的 W 条事件（默认 window=10）
  3. 统计每个回溯事件作为"前件"导致 target 的频率
  4. 计算 fail_conditional_prob = P(target | antecedent)
  5. 对比 baseline = P(target)，输出 lift 高的"可疑前件"

输出：markdown，按 lift 排序。
"""

import argparse
import json
from collections import defaultdict, Counter
from pathlib import Path


def event_to_item(e):
    """和 cooccurrence 保持一致。"""
    ev = e.get("event", "?")
    d = e.get("data") or {}
    if ev == "check.run":
        return f"{ev}:{d.get('checker','?')}:{d.get('status','?')}"
    if ev == "gate.eval":
        return f"{ev}:{d.get('gate','?')}:{d.get('result','?')}"
    if ev.startswith("artifact."):
        ext = Path(d.get("path", "")).suffix or "noext"
        return f"{ev}:{ext}"
    if ev == "state.transition":
        return f"{ev}:{d.get('from_stage','?')}→{d.get('to_stage','?')}"
    return ev


def is_failure_event(e):
    """定义哪些事件算"失败"。"""
    ev = e.get("event")
    d = e.get("data") or {}
    if ev == "gate.eval" and d.get("result") == "blocked":
        return True
    if ev == "check.run" and d.get("status") == "fail":
        return True
    return False


def mine(events, window=10, min_support=2, min_lift=1.5, top_n=30):
    # 按 trace_id 分组 + 保序
    by_trace = defaultdict(list)
    for e in events:
        by_trace[e.get("trace_id", "?")].append(e)

    # 构造 target 集合（每个失败事件记录其 item + 在 trace 中的 index）
    targets = []  # [(item, trace_id, idx)]
    for tid, evs in by_trace.items():
        for i, e in enumerate(evs):
            if is_failure_event(e):
                targets.append((event_to_item(e), tid, i, e))

    if not targets:
        return {"targets": 0, "rules": [], "warning": "no failure events found"}

    # 按 target item 分组
    by_target = defaultdict(list)
    for item, tid, idx, e in targets:
        by_target[item].append((tid, idx))

    all_items = Counter()  # item 在所有 trace 中出现的频率
    for evs in by_trace.values():
        seen = set()
        for e in evs:
            it = event_to_item(e)
            if it not in seen:  # 按 trace 去重，避免多次累加
                all_items[it] += 1
                seen.add(it)

    total_traces = len(by_trace)

    rules = []
    for target_item, target_locations in by_target.items():
        # 每次 target 发生，回溯 window 内的事件作为"前件候选"
        antecedent_counts = Counter()
        target_support = len(target_locations)

        for tid, idx in target_locations:
            evs = by_trace[tid]
            start = max(0, idx - window)
            prior_items = set()
            for j in range(start, idx):
                prior_items.add(event_to_item(evs[j]))
            for ant in prior_items:
                if ant == target_item:
                    continue  # 别把自己算进去
                antecedent_counts[ant] += 1

        # 对每个 antecedent 计算 lift
        # P(target | ant) = antecedent_counts[ant] / all_items[ant]
        # baseline P(target) = target_support / total_traces
        # lift = P(target | ant) / baseline
        baseline = target_support / total_traces

        for ant, cnt in antecedent_counts.items():
            if cnt < min_support:
                continue
            ant_total = all_items.get(ant, cnt)
            conditional = cnt / ant_total if ant_total else 0
            lift = conditional / baseline if baseline else 0
            if lift >= min_lift:
                rules.append({
                    "antecedent": ant,
                    "target": target_item,
                    "support": cnt,
                    "conditional_prob": conditional,
                    "lift": lift,
                })

    rules.sort(key=lambda r: (-r["lift"], -r["support"]))
    return {
        "targets": len(targets),
        "distinct_targets": len(by_target),
        "total_traces": total_traces,
        "rules": rules[:top_n],
    }


def render_md(result):
    lines = [
        "# Pattern 3 · 反模式（失败前因）",
        "",
        f"- failure events scanned: **{result.get('targets', 0)}**",
        f"- distinct target types: **{result.get('distinct_targets', 0)}**",
        f"- total traces: **{result.get('total_traces', 0)}**",
        f"- rules (support≥2, lift≥1.5): **{len(result.get('rules', []))}**",
        "",
        "> 挖掘 **出现 X 后（10 事件窗口内）很容易发生 Y 失败** 的 pattern。",
        "> lift 越大，这种 antecedent → failure 关联越强。",
        "",
    ]
    if result.get("warning"):
        lines.append(f"⚠ **警告**：{result['warning']}")
        lines.append("")

    rules = result.get("rules", [])
    if not rules:
        lines.append("_(no anti-patterns found)_")
        return "\n".join(lines)

    lines.append("## Top 失败前因")
    lines.append("")
    lines.append("| 前件（Antecedent） | → | 失败（Target） | support | P(fail\\|ant) | lift |")
    lines.append("|---|---|---|---|---|---|")
    for r in rules:
        lines.append(
            f"| `{r['antecedent']}` | → | `{r['target']}` "
            f"| {r['support']} | {r['conditional_prob']:.2f} | {r['lift']:.2f} |"
        )
    lines.append("")
    lines.append("## 如何解读")
    lines.append("")
    lines.append("- **support**：前件出现且随后发生目标失败的次数")
    lines.append("- **P(fail|ant)**：前件发生时，后续发生目标失败的条件概率")
    lines.append("- **lift**：相对基线的倍数（>1 表示显著高于平均）")
    lines.append("")
    lines.append("**建议**：lift > 3 且 support >= 3 的 pattern 值得看，可能是新的工程坑。")
    return "\n".join(lines)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--events", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--window", type=int, default=10)
    ap.add_argument("--min-support", type=int, default=2)
    ap.add_argument("--min-lift", type=float, default=1.5)
    args = ap.parse_args()

    events = json.loads(Path(args.events).read_text())
    result = mine(events, args.window, args.min_support, args.min_lift)
    md = render_md(result)
    Path(args.out).write_text(md, encoding="utf-8")
    print(f"[mine-anti-pattern] {len(events)} events / {result.get('targets',0)} failures "
          f"-> {len(result.get('rules',[]))} rules -> {args.out}")


if __name__ == "__main__":
    main()
