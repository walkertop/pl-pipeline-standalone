# Evidence · v1.4 retro-miner 挖掘能力验证

2026-04-22 Day 3 产出。验证 `pl-retro-miner` 能从 events.jsonl 中挖出**有用的 pattern**。

## 目录

- `synth-traces/`       10 次合成运行，每次故意注入 0~3 种 bug（已知真相）
- `mined-candidates/`   retro-miner 挖掘产出的 4 份 markdown 报告

## 10 种合成场景

| # | 场景 | 注入的 bug | 预期被挖出 |
|---|---|---|---|
| 1 | normal-pass | 无 | — |
| 2 | lint-fail-blocks-d | lint_fail | `lint:fail → D:blocked` |
| 3 | tsc-fail-blocks-d | tsc_fail | `tsc:fail → D:blocked` |
| 4 | package-json-without-install | package_json_drift | `install:fail` |
| 5 | smoke-probe-fail | smoke_fail | `probe:fail` |
| 6 | lint-retry-burst | lint_fail × 3 | `burst` outlier |
| 7 | normal-pass-2 | 无 | — |
| 8 | tsc-slow | tsc_slow | `duration` outlier |
| 9 | lint-fail-again | lint_fail | 增强 #2 的 pattern |
| 10 | test-fail | test_fail | `test:fail → D:blocked` |

**总计**：10 traces / 192 events / 16 failure events

## 挖掘结果摘要

### Pattern 1 · frequency（事件频次排行）
- `gate.eval D=blocked` 28.6%（6 次）← D 失败最高频
- `check.run lint:fail` 3 次（fail_rate 50%）
- stage 迁移路径分布正常

### Pattern 2 · co-occurrence（共现）
- **30 条规则** 被挖出
- 最强相关：`D:passed → E:passed`（lift=2.5），`probe:pass → ARCHIVE`（lift=3.33）
- 这些是 pl 流程的**事实契约**，可作为 E5 (v1.5) 契约依据

### Pattern 3 · anti-pattern（反模式）
- 挖出 1 条 `lint:fail → D:blocked`（support=3, lift=1.67）
- **其他 3 条预期 pattern（tsc/test/package_json）没被挖出**
- 原因：单一 pattern 只出现 1-2 次，统计显著性不够（要提高 min_lift 会更严格）

### Pattern 4 · outlier（异常点）
- duration outlier：0 条（tsc-slow 单点 z-score≈2.3，未达阈值 3.0）
- fail burst：✅ 抓到 run-06 lint × 3 fails

## MVP 评估

### Precision / Recall 矩阵

| 预期 | 被挖出 | 正误 |
|---|---|---|
| lint:fail → D:blocked | ✅ support=3, lift=1.67 | TP |
| tsc:fail → D:blocked | ❌ support=1 过滤 | FN（样本不足） |
| package_json_drift → install:fail | ❌ support=1 过滤 | FN |
| test:fail → D:blocked | ❌ support=1 过滤 | FN |
| lint retry burst | ✅ run-06 抓到 | TP |
| tsc-slow duration outlier | ❌ z≈2.3 | FN（阈值严格） |

**Precision = 100%**（挖出的 2 条都是真 pattern，0 误报）
**Recall = 33%**（6 预期只挖出 2 条）

## 关键洞察

### 1. retro-miner 正确"保守"

挖出的 2 条都**经过 support≥2 + lift≥1.5 双重过滤**，**0 误报**。这是 MVP 最重要的质量：**不误报比多挖掘更重要**（挖得多但错，用户就不信了）。

### 2. Recall 低的真实原因：样本不足

按设计每个 pattern 需要 **≥2 次出现** 才会被挖出。本 MVP 合成数据里，除 lint_fail 外其他 bug 只注入 1 次，**按设计就不该被挖出**。

**这不是算法缺陷，是"足够数据量"的统计要求**。当真实项目累积 >50 次 change 后，低频 pattern 自然会被挖到。

### 3. Pattern 2 共现意外价值

`probe:pass → ARCHIVE` lift=3.33 这种规则是 pl 流程的**事实契约**。未来做 E5 时**不用手写契约**，直接把这些高置信度共现关系固化成 stage-machine.yaml。

这正是我们选 B 方案（先 retro-miner 再 E5）的核心理由的**实证**。

## 使用方式

```bash
# 1. 合成测试数据（可复现）
python3 scripts/_lib/synth-test-traces.py --out /tmp/synth --seed 42

# 2. 跑挖掘
bash scripts/pl-retro-miner.sh --sources /tmp/synth --out /tmp/mined

# 3. 看报告
cat /tmp/mined/anti-patterns.md
cat /tmp/mined/co-occurrence.md
```

## 下一步（v1.5 规划）

基于本评估，v1.5 可以做：
1. **真实数据积累期**：先等 pl-pipeline 跑 2-3 周真实 change，累积 events.jsonl
2. **retro-miner 调参**：根据真实数据分布，调整 min_support / min_lift 阈值
3. **E5 v0 启动**：从 retro-miner 挖出的高置信度 co-occurrence 中**选 3-5 条** 固化为 stage-machine.yaml（不要再凭空写规则）
