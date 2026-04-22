#!/usr/bin/env python3
"""synth-test-traces.py — 合成带"已知 bug"的多 trace 数据，用于验证 retro-miner

为什么要合成？
  demo 只跑过 1-2 次，events 数量 < 50，统计量不足以验证 retro-miner 算法。
  合成 10+ 次运行（每次注入不同 bug）后，可以：
    1. 跑 retro-miner 看能否挖出"我们注入的 bug pattern"
    2. 计算 precision / recall，给 MVP 质量把关

用法：
  python3 synth-test-traces.py --out /tmp/synth-traces/ --runs 10
  bash scripts/pl-retro-miner.sh --sources /tmp/synth-traces/ --out /tmp/synth-mined
"""

import argparse
import json
import random
from datetime import datetime, timedelta, timezone
from pathlib import Path


# ─── 事件模板 ─────────────────────────────────────────────────────────
def mk_event(trace_id, change_id, phase, actor, event, data, ts):
    return {
        "ts": ts.strftime("%Y-%m-%dT%H:%M:%SZ"),
        "trace_id": trace_id,
        "change_id": change_id,
        "phase": phase,
        "actor": actor,
        "event": event,
        "data": data,
    }


# ─── 10 种场景，每种对应一类典型开发过程 ─────────────────────────────
SCENARIOS = [
    # 1. 正常 change（all-pass）
    {
        "name": "normal-pass",
        "bugs": [],
        "expected_patterns": [],
    },
    # 2. lint fail 导致 D blocked（retro-v2 B3 的"再现"）
    {
        "name": "lint-fail-blocks-d",
        "bugs": ["lint_fail"],
        "expected_patterns": [
            {"antecedent": "check.run:lint:fail", "target": "gate.eval:D:blocked"},
        ],
    },
    # 3. tsc fail
    {
        "name": "tsc-fail-blocks-d",
        "bugs": ["tsc_fail"],
        "expected_patterns": [
            {"antecedent": "check.run:tsc:fail", "target": "gate.eval:D:blocked"},
        ],
    },
    # 4. 改 package.json 后没 install
    {
        "name": "package-json-without-install",
        "bugs": ["package_json_drift"],
        "expected_patterns": [
            {"antecedent": "artifact.modified:.json", "target": "check.run:install:fail"},
        ],
    },
    # 5. smoke probe fail
    {
        "name": "smoke-probe-fail",
        "bugs": ["smoke_fail"],
        "expected_patterns": [
            {"antecedent": "smoke.boot", "target": "check.run:probe:register:fail"},
        ],
    },
    # 6. lint retry burst（连续 3 次 lint fail）
    {
        "name": "lint-retry-burst",
        "bugs": ["lint_fail", "lint_fail", "lint_fail"],
        "expected_patterns": [],  # outlier detection 会抓
    },
    # 7. 另一个正常 change
    {
        "name": "normal-pass-2",
        "bugs": [],
        "expected_patterns": [],
    },
    # 8. tsc 异常慢（outlier duration）
    {
        "name": "tsc-slow",
        "bugs": ["tsc_slow"],
        "expected_patterns": [],  # outlier duration 会抓
    },
    # 9. lint fail（再来一次，增加 retro-v2 B3 的 support）
    {
        "name": "lint-fail-again",
        "bugs": ["lint_fail"],
        "expected_patterns": [],
    },
    # 10. test fail
    {
        "name": "test-fail",
        "bugs": ["test_fail"],
        "expected_patterns": [
            {"antecedent": "check.run:test:fail", "target": "gate.eval:D:blocked"},
        ],
    },
]


def gen_trace(scenario, base_ts, run_id):
    """生成单次运行的事件流。"""
    change_id = f"demo-run-{run_id:02d}"
    trace_id = f"{change_id}_{base_ts.strftime('%Y%m%d_%H%M%S')}"
    events = []
    t = base_ts

    def emit(phase, event, data, actor="script:pl-runner", dt=1):
        nonlocal t
        t = t + timedelta(seconds=dt)
        events.append(mk_event(trace_id, change_id, phase, actor, event, data, t))

    bugs = set(scenario["bugs"])
    repeat_bugs = scenario["bugs"]  # 可能含重复

    # ─── SPEC → PLAN ─────────────────────────────────────────────
    emit("SPEC", "artifact.created", {"path": f"pl/changes/{change_id}/spec.md", "sha256_after": "a" * 8})
    emit("PLAN", "artifact.created", {"path": f"pl/changes/{change_id}/plan.md", "sha256_after": "b" * 8})
    emit("PLAN", "artifact.created", {"path": f"pl/changes/{change_id}/taskdag.md", "sha256_after": "c" * 8})
    for i in range(1, 6):
        emit("PLAN", "plan.task.added", {"task_id": f"T{i:02d}", "task_name": f"task {i}"},
             actor="script:pl-observe-rules@1.0.0")
    emit("PLAN", "state.transition", {"from_stage": "SPEC", "to_stage": "PLAN"},
         actor="script:pl-observe-rules@1.0.0")

    # ─── IMPLEMENT → D gate ──────────────────────────────────────
    emit("IMPLEMENT", "artifact.modified", {"path": "app/todos/page.tsx", "sha256_after": "d" * 8})
    if "package_json_drift" in bugs:
        emit("IMPLEMENT", "artifact.modified", {"path": "package.json", "sha256_after": "e" * 8})

    emit("IMPLEMENT", "gate.start", {"gate": "D", "from": "IMPLEMENT", "to": "VERIFY"})

    # compile check
    if "tsc_fail" in bugs:
        emit("IMPLEMENT", "check.run", {"checker": "tsc", "cmd": "npx tsc --noEmit",
                                         "status": "fail", "duration_sec": 2, "reason": "TS2322"})
    elif "tsc_slow" in bugs:
        emit("IMPLEMENT", "check.run", {"checker": "tsc", "cmd": "npx tsc --noEmit",
                                         "status": "pass", "duration_sec": 45})  # 异常慢
    else:
        emit("IMPLEMENT", "check.run", {"checker": "tsc", "cmd": "npx tsc --noEmit",
                                         "status": "pass", "duration_sec": random.randint(1, 3)})

    # install check（只在 package_json drift 时会 fail）
    if "package_json_drift" in bugs:
        emit("IMPLEMENT", "check.run", {"checker": "install", "cmd": "npm install",
                                         "status": "fail", "duration_sec": 3, "reason": "lockfile mismatch"})

    # lint check（可能连续失败）
    lint_fail_count = repeat_bugs.count("lint_fail")
    if lint_fail_count > 0:
        for i in range(lint_fail_count):
            emit("IMPLEMENT", "check.run", {"checker": "lint", "cmd": "npx next lint",
                                             "status": "fail", "duration_sec": 1, "reason": "exit_code=1"})
    else:
        emit("IMPLEMENT", "check.run", {"checker": "lint", "cmd": "npx next lint",
                                         "status": "pass", "duration_sec": 1})

    # test check
    if "test_fail" in bugs:
        emit("IMPLEMENT", "check.run", {"checker": "test", "cmd": "npm test",
                                         "status": "fail", "duration_sec": 5, "reason": "1 failing"})

    # D gate.eval
    has_failure = any(b in bugs for b in ["lint_fail", "tsc_fail", "test_fail", "package_json_drift"])
    if has_failure:
        emit("IMPLEMENT", "gate.eval", {"gate": "D", "result": "blocked",
                                         "eval": "all_checks.pass", "pass": 1, "fail": 1})
        return events  # D blocked 后停

    emit("IMPLEMENT", "gate.eval", {"gate": "D", "result": "passed",
                                     "eval": "all_checks.pass", "pass": 3, "fail": 0})

    # ─── VERIFY → SMOKE ──────────────────────────────────────────
    emit("IMPLEMENT", "state.transition", {"from_stage": "IMPLEMENT", "to_stage": "VERIFY"},
         actor="script:pl-observe-rules@1.0.0")
    emit("VERIFY", "gate.eval", {"gate": "E", "result": "passed"})
    emit("VERIFY", "state.transition", {"from_stage": "VERIFY", "to_stage": "SMOKE"},
         actor="script:pl-observe-rules@1.0.0")

    # SMOKE
    emit("SMOKE", "smoke.boot", {"pid": 1234}, actor="script:pl-smoke")
    emit("SMOKE", "smoke.ready", {"attempts": 2}, actor="script:pl-smoke")
    if "smoke_fail" in bugs:
        emit("SMOKE", "check.run", {"checker": "probe:register",
                                     "status": "fail", "status_code": 500, "duration_sec": 1},
             actor="script:pl-smoke")
        emit("SMOKE", "gate.eval", {"gate": "E_smoke", "result": "blocked"})
        emit("SMOKE", "smoke.shutdown", {"pid": 1234}, actor="script:pl-smoke")
        return events
    emit("SMOKE", "check.run", {"checker": "probe:register",
                                 "status": "pass", "status_code": 201, "duration_sec": random.randint(1, 2)},
         actor="script:pl-smoke")
    emit("SMOKE", "gate.eval", {"gate": "E_smoke", "result": "passed"})
    emit("SMOKE", "smoke.shutdown", {"pid": 1234}, actor="script:pl-smoke")

    # ─── OBSERVE → ARCHIVE ───────────────────────────────────────
    emit("OBSERVE", "state.transition", {"from_stage": "SMOKE", "to_stage": "OBSERVE"},
         actor="script:pl-observe-rules@1.0.0")
    emit("OBSERVE", "piao.contract_drift.detected",
         {"adapter": "nextjs-web", "counts": {"total": 0, "error": 0}})
    emit("OBSERVE", "pl.rule_scan.completed",
         {"counts": {"total": 0, "error": 0}, "executable_rules": 4})
    emit("ARCHIVE", "state.transition", {"from_stage": "OBSERVE", "to_stage": "ARCHIVE"},
         actor="script:pl-observe-rules@1.0.0")
    emit("ARCHIVE", "gate.eval", {"gate": "G", "result": "passed"})

    return events


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", required=True, help="输出目录")
    ap.add_argument("--seed", type=int, default=42)
    args = ap.parse_args()

    random.seed(args.seed)
    out_dir = Path(args.out)
    out_dir.mkdir(parents=True, exist_ok=True)

    base = datetime.now(timezone.utc).replace(microsecond=0)
    scenario_summary = []

    for i, sc in enumerate(SCENARIOS, 1):
        ts = base + timedelta(minutes=i * 5)
        events = gen_trace(sc, ts, i)
        fname = f"run-{i:02d}-{sc['name']}.events.jsonl"
        p = out_dir / fname
        with p.open("w", encoding="utf-8") as f:
            for e in events:
                f.write(json.dumps(e, ensure_ascii=False) + "\n")
        scenario_summary.append({
            "run": i,
            "scenario": sc["name"],
            "events": len(events),
            "expected_patterns": sc["expected_patterns"],
        })
        print(f"[synth] run-{i:02d} {sc['name']:30s} {len(events):3d} events -> {p.name}")

    # 写一份 expected.json，用于 precision/recall 评估
    (out_dir / "_expected.json").write_text(
        json.dumps({"scenarios": scenario_summary}, indent=2, ensure_ascii=False)
    )
    print(f"\n[synth] {len(SCENARIOS)} traces -> {out_dir}")
    print(f"[synth] expected patterns written to {out_dir}/_expected.json")


if __name__ == "__main__":
    main()
