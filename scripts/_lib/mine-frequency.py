#!/usr/bin/env python3
"""mine-frequency.py — Pattern 1：事件频次排行

职责：从事件流里按多个维度统计频次，产出"最常见的 X"列表，帮人发现"哪些检
查最常 fail / 哪些 rule 最常命中 / 哪些 stage 迁移最常见"。

统计的维度：
  1. 最频繁的 failing check（按 checker 分组）
  2. 最频繁的 rule 违规（如果接入了 pl-rule-scan）
  3. 最频繁的 artifact 修改路径（哪些文件被反复改）
  4. 最频繁的 state.transition（from → to 统计）
  5. 事件类型总分布

输出：markdown 报告
"""

import argparse
import json
from collections import Counter
from pathlib import Path


def count_by(events, filter_fn, key_fn):
    """对满足 filter 的事件，按 key 聚合计数。返回 Counter。"""
    c = Counter()
    for e in events:
        try:
            if filter_fn(e):
                k = key_fn(e)
                if k is not None:
                    c[k] += 1
        except (TypeError, KeyError):
            pass
    return c


def render_top_table(counter: Counter, headers, top_n=10):
    """Counter → markdown 表格。"""
    if not counter:
        return "_(no data)_"
    lines = ["| " + " | ".join(headers) + " |",
             "|" + "|".join(["---"] * len(headers)) + "|"]
    total = sum(counter.values())
    for key, cnt in counter.most_common(top_n):
        pct = (cnt * 100 / total) if total else 0
        if isinstance(key, tuple):
            row = [str(x) for x in key] + [str(cnt), f"{pct:.1f}%"]
        else:
            row = [str(key), str(cnt), f"{pct:.1f}%"]
        lines.append("| " + " | ".join(row) + " |")
    return "\n".join(lines)


def mine(events):
    sections = []

    # 1. 事件类型分布
    all_types = count_by(
        events,
        filter_fn=lambda e: True,
        key_fn=lambda e: e.get("event", "?"),
    )
    sections.append(("事件类型分布", render_top_table(all_types, ["event", "count", "%"], top_n=15)))

    # 2. 最频繁的 failing check
    fail_checks = count_by(
        events,
        filter_fn=lambda e: e.get("event") == "check.run" and (e.get("data") or {}).get("status") == "fail",
        key_fn=lambda e: (e.get("data") or {}).get("checker", "?"),
    )
    total_checks = count_by(
        events,
        filter_fn=lambda e: e.get("event") == "check.run",
        key_fn=lambda e: (e.get("data") or {}).get("checker", "?"),
    )
    # 计算 fail_rate
    fail_rate_rows = []
    for checker, fail_cnt in fail_checks.most_common(20):
        total = total_checks.get(checker, fail_cnt)
        rate = fail_cnt * 100 / total if total else 0
        fail_rate_rows.append((checker, fail_cnt, total, f"{rate:.1f}%"))
    sections.append((
        "最频繁的 failing check",
        "| checker | fail | total | fail_rate |\n|---|---|---|---|\n" +
        "\n".join("| " + " | ".join(str(x) for x in r) + " |" for r in fail_rate_rows)
        if fail_rate_rows else "_(no failing check)_",
    ))

    # 3. rule 违规 Top（通过 pl.rule_scan.completed 里的 counts 暂时抓不到具体 rule；
    #    先抓 inferred_by 字段的 observe-rules 推断统计）
    rule_hits = count_by(
        events,
        filter_fn=lambda e: "inferred_by" in (e.get("data") or {}),
        key_fn=lambda e: (e.get("data") or {}).get("inferred_by"),
    )
    sections.append(("observe-rule 触发频次", render_top_table(rule_hits, ["rule_id", "count", "%"], top_n=10)))

    # 4. 最频繁修改的 artifact 路径
    mod_paths = count_by(
        events,
        filter_fn=lambda e: e.get("event") in ("artifact.modified", "artifact.created"),
        key_fn=lambda e: (e.get("data") or {}).get("path", "?"),
    )
    sections.append(("最频繁被触及的 artifact 路径", render_top_table(mod_paths, ["path", "count", "%"], top_n=15)))

    # 5. state.transition 路径统计
    transitions = count_by(
        events,
        filter_fn=lambda e: e.get("event") == "state.transition",
        key_fn=lambda e: (
            (e.get("data") or {}).get("from_stage", "?"),
            (e.get("data") or {}).get("to_stage", "?"),
        ),
    )
    sections.append(("stage 迁移路径", render_top_table(transitions, ["from", "to", "count", "%"], top_n=10)))

    # 6. gate.eval 结果分布
    gate_results = count_by(
        events,
        filter_fn=lambda e: e.get("event") == "gate.eval",
        key_fn=lambda e: (
            (e.get("data") or {}).get("gate", "?"),
            (e.get("data") or {}).get("result", "?"),
        ),
    )
    sections.append(("gate.eval 结果分布", render_top_table(gate_results, ["gate", "result", "count", "%"], top_n=20)))

    return sections


def render_md(sections, total_events, total_traces):
    lines = [
        "# Pattern 1 · 频次排行",
        "",
        f"- events scanned: **{total_events}**",
        f"- distinct trace_id: **{total_traces}**",
        "",
        "> retro-miner 纯统计产出。**非强制规则**，供人 review 后决定是否升级为正式契约。",
        "",
    ]
    for title, body in sections:
        lines.append(f"## {title}")
        lines.append("")
        lines.append(body)
        lines.append("")
    return "\n".join(lines)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--events", required=True)
    ap.add_argument("--out", required=True)
    args = ap.parse_args()

    events = json.loads(Path(args.events).read_text())
    traces = {e.get("trace_id") for e in events}

    sections = mine(events)
    md = render_md(sections, len(events), len(traces))

    Path(args.out).write_text(md, encoding="utf-8")
    print(f"[mine-frequency] {len(events)} events -> {args.out}")


if __name__ == "__main__":
    main()
