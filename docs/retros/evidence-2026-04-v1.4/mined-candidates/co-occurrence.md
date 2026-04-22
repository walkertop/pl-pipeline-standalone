# Pattern 2 · 事件共现分析

- traces scanned: **10**
- unique item types: **29**
- rules (support≥2, confidence≥0.6): **30**

> 挖掘 **在同一 trace_id 里经常一起出现** 的事件对。
> lift > 1 表示正相关（A 出现时 B 出现的概率 > B 在总体的平均概率），
> lift 越高越有意义。

## Top 关联规则

| antecedent (前件) | consequent (后件) | support | confidence | lift |
|---|---|---|---|---|
| `check.run:probe:register:pass` | `gate.eval:E_smoke:passed` | 3 | 1.00 | 3.33 |
| `check.run:probe:register:pass` | `gate.eval:G:passed` | 3 | 1.00 | 3.33 |
| `check.run:probe:register:pass` | `piao.contract_drift.detected` | 3 | 1.00 | 3.33 |
| `check.run:probe:register:pass` | `pl.rule_scan.completed` | 3 | 1.00 | 3.33 |
| `check.run:probe:register:pass` | `state.transition:OBSERVE→ARCHIVE` | 3 | 1.00 | 3.33 |
| `check.run:probe:register:pass` | `state.transition:SMOKE→OBSERVE` | 3 | 1.00 | 3.33 |
| `gate.eval:E_smoke:passed` | `gate.eval:G:passed` | 3 | 1.00 | 3.33 |
| `gate.eval:E_smoke:passed` | `piao.contract_drift.detected` | 3 | 1.00 | 3.33 |
| `gate.eval:E_smoke:passed` | `pl.rule_scan.completed` | 3 | 1.00 | 3.33 |
| `gate.eval:E_smoke:passed` | `state.transition:OBSERVE→ARCHIVE` | 3 | 1.00 | 3.33 |
| `gate.eval:E_smoke:passed` | `state.transition:SMOKE→OBSERVE` | 3 | 1.00 | 3.33 |
| `gate.eval:G:passed` | `piao.contract_drift.detected` | 3 | 1.00 | 3.33 |
| `gate.eval:G:passed` | `pl.rule_scan.completed` | 3 | 1.00 | 3.33 |
| `gate.eval:G:passed` | `state.transition:OBSERVE→ARCHIVE` | 3 | 1.00 | 3.33 |
| `gate.eval:G:passed` | `state.transition:SMOKE→OBSERVE` | 3 | 1.00 | 3.33 |
| `piao.contract_drift.detected` | `pl.rule_scan.completed` | 3 | 1.00 | 3.33 |
| `piao.contract_drift.detected` | `state.transition:OBSERVE→ARCHIVE` | 3 | 1.00 | 3.33 |
| `piao.contract_drift.detected` | `state.transition:SMOKE→OBSERVE` | 3 | 1.00 | 3.33 |
| `pl.rule_scan.completed` | `state.transition:OBSERVE→ARCHIVE` | 3 | 1.00 | 3.33 |
| `pl.rule_scan.completed` | `state.transition:SMOKE→OBSERVE` | 3 | 1.00 | 3.33 |
| `state.transition:OBSERVE→ARCHIVE` | `state.transition:SMOKE→OBSERVE` | 3 | 1.00 | 3.33 |
| `gate.eval:D:passed` | `gate.eval:E:passed` | 4 | 1.00 | 2.50 |
| `gate.eval:D:passed` | `smoke.boot` | 4 | 1.00 | 2.50 |
| `gate.eval:D:passed` | `smoke.ready` | 4 | 1.00 | 2.50 |
| `gate.eval:D:passed` | `smoke.shutdown` | 4 | 1.00 | 2.50 |
| `gate.eval:D:passed` | `state.transition:IMPLEMENT→VERIFY` | 4 | 1.00 | 2.50 |
| `gate.eval:D:passed` | `state.transition:VERIFY→SMOKE` | 4 | 1.00 | 2.50 |
| `gate.eval:E:passed` | `smoke.boot` | 4 | 1.00 | 2.50 |
| `gate.eval:E:passed` | `smoke.ready` | 4 | 1.00 | 2.50 |
| `gate.eval:E:passed` | `smoke.shutdown` | 4 | 1.00 | 2.50 |

## 如何解读

- **support**：两个事件在同一 trace 出现的次数
- **confidence(A→B)**：A 出现时 B 也出现的概率
- **lift**：相关强度（>1 正相关、=1 独立、<1 负相关）

**建议**：关注 `lift > 2 && support >= 3` 的规则，可能是新的经验。