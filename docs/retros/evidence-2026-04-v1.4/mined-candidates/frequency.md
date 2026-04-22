# Pattern 1 · 频次排行

- events scanned: **192**
- distinct trace_id: **10**

> retro-miner 纯统计产出。**非强制规则**，供人 review 后决定是否升级为正式契约。

## 事件类型分布

| event | count | % |
|---|---|---|
| plan.task.added | 50 | 26.0% |
| artifact.created | 30 | 15.6% |
| check.run | 28 | 14.6% |
| state.transition | 24 | 12.5% |
| gate.eval | 21 | 10.9% |
| artifact.modified | 11 | 5.7% |
| gate.start | 10 | 5.2% |
| smoke.boot | 4 | 2.1% |
| smoke.ready | 4 | 2.1% |
| smoke.shutdown | 4 | 2.1% |
| piao.contract_drift.detected | 3 | 1.6% |
| pl.rule_scan.completed | 3 | 1.6% |

## 最频繁的 failing check

| checker | fail | total | fail_rate |
|---|---|---|---|
| lint | 5 | 12 | 41.7% |
| tsc | 1 | 10 | 10.0% |
| install | 1 | 1 | 100.0% |
| probe:register | 1 | 4 | 25.0% |
| test | 1 | 1 | 100.0% |

## observe-rule 触发频次

_(no data)_

## 最频繁被触及的 artifact 路径

| path | count | % |
|---|---|---|
| app/todos/page.tsx | 10 | 24.4% |
| pl/changes/demo-run-01/spec.md | 1 | 2.4% |
| pl/changes/demo-run-01/plan.md | 1 | 2.4% |
| pl/changes/demo-run-01/taskdag.md | 1 | 2.4% |
| pl/changes/demo-run-02/spec.md | 1 | 2.4% |
| pl/changes/demo-run-02/plan.md | 1 | 2.4% |
| pl/changes/demo-run-02/taskdag.md | 1 | 2.4% |
| pl/changes/demo-run-03/spec.md | 1 | 2.4% |
| pl/changes/demo-run-03/plan.md | 1 | 2.4% |
| pl/changes/demo-run-03/taskdag.md | 1 | 2.4% |
| pl/changes/demo-run-04/spec.md | 1 | 2.4% |
| pl/changes/demo-run-04/plan.md | 1 | 2.4% |
| pl/changes/demo-run-04/taskdag.md | 1 | 2.4% |
| package.json | 1 | 2.4% |
| pl/changes/demo-run-05/spec.md | 1 | 2.4% |

## stage 迁移路径

| from | to | count | % |
|---|---|---|---|
| SPEC | PLAN | 10 | 41.7% |
| IMPLEMENT | VERIFY | 4 | 16.7% |
| VERIFY | SMOKE | 4 | 16.7% |
| SMOKE | OBSERVE | 3 | 12.5% |
| OBSERVE | ARCHIVE | 3 | 12.5% |

## gate.eval 结果分布

| gate | result | count | % |
|---|---|---|---|
| D | blocked | 6 | 28.6% |
| D | passed | 4 | 19.0% |
| E | passed | 4 | 19.0% |
| E_smoke | passed | 3 | 14.3% |
| G | passed | 3 | 14.3% |
| E_smoke | blocked | 1 | 4.8% |
