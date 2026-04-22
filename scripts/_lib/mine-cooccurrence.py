#!/usr/bin/env python3
"""mine-cooccurrence.py — Pattern 2：事件共现分析

在同一 trace_id 窗口内，找出**经常一起出现**的事件对 (A, B)。
输出：support（两个事件一起出现的 trace 次数）+ confidence（A 出现时 B 也出现的概率）

算法：2-itemset Apriori（简化版）
  - 每个 trace 内生成事件 item 集合
  - 枚举所有事件对 (A, B)
  - 支持度 = |{trace | A ∈ trace && B ∈ trace}|
  - 置信度 A→B = |trace(A,B)| / |trace(A)|
  - 过滤：min_support + min_confidence

输出：markdown（按 lift 排序，lift = confidence / baseline_prob(B)，突出"真有相关性"）
"""

import argparse
import json
from collections import defaultdict, Counter
from itertools import combinations
from pathlib import Path


def event_to_item(e):
    """把一条事件压成一个 item 字符串（去噪细节，留核心语义）。"""
    ev = e.get("event", "?")
    d = e.get("data") or {}

    # 对高信息量事件保留关键字段
    if ev == "check.run":
        return f"{ev}:{d.get('checker','?')}:{d.get('status','?')}"
    if ev == "gate.eval":
        return f"{ev}:{d.get('gate','?')}:{d.get('result','?')}"
    if ev == "state.transition":
        return f"{ev}:{d.get('from_stage','?')}→{d.get('to_stage','?')}"
    if ev == "asset.promoted":
        return f"{ev}:{d.get('kind','?')}"
    if ev.startswith("artifact."):
        # path 太细，按文件扩展名聚合
        path = d.get("path", "")
        ext = Path(path).suffix or "noext"
        return f"{ev}:{ext}"
    if ev == "plan.task.added":
        return ev  # 不区分具体 task，避免碎片化
    return ev


def mine(events, min_support=2, min_confidence=0.6, top_n=30):
    # 按 trace_id 分组
    traces = defaultdict(set)
    for e in events:
        tid = e.get("trace_id", "?")
        item = event_to_item(e)
        traces[tid].add(item)

    n_traces = len(traces)
    if n_traces < 2:
        return {
            "n_traces": n_traces,
            "rules": [],
            "warning": f"only {n_traces} trace(s), cooccurrence mining requires >= 3 for meaningful stats",
        }

    # 单 item 支持度
    item_support = Counter()
    for items in traces.values():
        for it in items:
            item_support[it] += 1

    # 2-item 支持度
    pair_support = Counter()
    for items in traces.values():
        for a, b in combinations(sorted(items), 2):
            pair_support[(a, b)] += 1

    # 生成关联规则（A → B 和 B → A 都考虑）
    rules = []
    for (a, b), sup in pair_support.items():
        if sup < min_support:
            continue
        # A → B
        conf_ab = sup / item_support[a] if item_support[a] else 0
        # B → A
        conf_ba = sup / item_support[b] if item_support[b] else 0
        # lift = conf_ab / baseline_prob(b)
        baseline_b = item_support[b] / n_traces
        lift = conf_ab / baseline_b if baseline_b else 0

        if conf_ab >= min_confidence:
            rules.append({
                "antecedent": a, "consequent": b,
                "support": sup, "confidence": conf_ab, "lift": lift,
            })
        if conf_ba >= min_confidence:
            rules.append({
                "antecedent": b, "consequent": a,
                "support": sup, "confidence": conf_ba,
                "lift": sup / item_support[a] if item_support[a] else 0,
            })

    # 按 lift 降序（去除 lift 接近 1 的"平庸"规则）
    rules.sort(key=lambda r: (-r["lift"], -r["support"]))

    return {
        "n_traces": n_traces,
        "n_unique_items": len(item_support),
        "rules": rules[:top_n],
    }


def render_md(result):
    n_traces = result["n_traces"]
    rules = result["rules"]

    lines = [
        "# Pattern 2 · 事件共现分析",
        "",
        f"- traces scanned: **{n_traces}**",
        f"- unique item types: **{result.get('n_unique_items', 0)}**",
        f"- rules (support≥2, confidence≥0.6): **{len(rules)}**",
        "",
        "> 挖掘 **在同一 trace_id 里经常一起出现** 的事件对。",
        "> lift > 1 表示正相关（A 出现时 B 出现的概率 > B 在总体的平均概率），",
        "> lift 越高越有意义。",
        "",
    ]

    if result.get("warning"):
        lines.append(f"⚠ **警告**：{result['warning']}")
        lines.append("")

    if not rules:
        lines.append("_(no co-occurrence rules found)_")
        return "\n".join(lines)

    lines.append("## Top 关联规则")
    lines.append("")
    lines.append("| antecedent (前件) | consequent (后件) | support | confidence | lift |")
    lines.append("|---|---|---|---|---|")
    for r in rules:
        lines.append(
            f"| `{r['antecedent']}` | `{r['consequent']}` "
            f"| {r['support']} | {r['confidence']:.2f} | {r['lift']:.2f} |"
        )
    lines.append("")

    lines.append("## 如何解读")
    lines.append("")
    lines.append("- **support**：两个事件在同一 trace 出现的次数")
    lines.append("- **confidence(A→B)**：A 出现时 B 也出现的概率")
    lines.append("- **lift**：相关强度（>1 正相关、=1 独立、<1 负相关）")
    lines.append("")
    lines.append("**建议**：关注 `lift > 2 && support >= 3` 的规则，可能是新的经验。")

    return "\n".join(lines)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--events", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--min-support", type=int, default=2)
    ap.add_argument("--min-confidence", type=float, default=0.6)
    args = ap.parse_args()

    events = json.loads(Path(args.events).read_text())
    result = mine(events, args.min_support, args.min_confidence)
    md = render_md(result)
    Path(args.out).write_text(md, encoding="utf-8")
    print(f"[mine-cooccurrence] {len(events)} events / {result['n_traces']} traces "
          f"-> {len(result['rules'])} rules -> {args.out}")


if __name__ == "__main__":
    main()
