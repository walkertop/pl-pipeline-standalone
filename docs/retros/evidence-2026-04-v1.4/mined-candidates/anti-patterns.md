# Pattern 3 · 反模式（失败前因）

- failure events scanned: **16**
- distinct target types: **7**
- total traces: **10**
- rules (support≥2, lift≥1.5): **1**

> 挖掘 **出现 X 后（10 事件窗口内）很容易发生 Y 失败** 的 pattern。
> lift 越大，这种 antecedent → failure 关联越强。

## Top 失败前因

| 前件（Antecedent） | → | 失败（Target） | support | P(fail\|ant) | lift |
|---|---|---|---|---|---|
| `check.run:lint:fail` | → | `gate.eval:D:blocked` | 3 | 1.00 | 1.67 |

## 如何解读

- **support**：前件出现且随后发生目标失败的次数
- **P(fail|ant)**：前件发生时，后续发生目标失败的条件概率
- **lift**：相对基线的倍数（>1 表示显著高于平均）

**建议**：lift > 3 且 support >= 3 的 pattern 值得看，可能是新的工程坑。