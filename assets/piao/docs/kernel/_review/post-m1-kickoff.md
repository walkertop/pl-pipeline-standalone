---
urn: urn:piao:proposal:kernel:post_m1_kickoff@v1
kind: proposal
rev: v1
status: superseded
superseded_by: urn:piao:snapshot:kernel:m4_final_decisions@v1
superseded_at: 2026-04-19T02:10:00+08:00
produced_by: m1-review-2026-04-18
published_at: 2026-04-18T22:10:00+08:00
upstream:
  - urn:piao:snapshot:kernel:m1_final_decisions@v1
  - urn:piao:evolution_source:kernel:m1_debt_ledger@v1
  - urn:piao:evolution_source:kernel:m1_exit_check@v1
wordcheck_exempt: true
---

> **⚠️ 本 proposal 已 superseded（2026-04-19 02:10）**
>
> **承接快照**：`urn:piao:snapshot:kernel:m4_final_decisions@v1`（见 `_review/m4-final-decisions.md`）
>
> **关闭原因**：本 proposal §4 的工作流 A 目标（M4 Snapshot Model 首版 draft）不仅已达成，且已 published @v1.1；工作流 B 的前两份 adapter review artifact（charter / task-types）也已产出。§6 关闭条件中"M1-debt-ledger consumed"条款：§1.2 / §1.3 已 consumed，§1.1 六条 BAN 按 `§2.4` 原文约定属独立阶段 3 清理轨道（不阻断本 proposal 的 superseded 判定）。
>
> **保留本正文不修改**作为历史追溯锚点；如需查询 M4 milestone 最终形态，请直接引用 `m4_final_decisions@v1`。

# Post-M1 Kickoff · M1 review 定稿后的下一批工作

> 本文档是 **M1 review 收尾后的工作编排草案**，定位 `kind: proposal`（不是 snapshot，因为计划可能被讨论后调整）。
>
> 写作日期：2026-04-18（M1 收尾当日）
> 消费方式：进入任一工作项前，把对应段落转为 `task.*` L1 事件并关联回本 proposal 的 URN。
>
> 阅读路径：先读 `M1-final-decisions.md`（已决议的约束）→ 再读 `M1-debt-ledger.md`（已知遗留）→ 再读 `M1-exit-check.md`（入口状态）→ 最后读本文档（下一步去哪）。

---

## 0. 当前位置总览

按 `00-overview.md §1 核心公式` 的 7 维进度：

| 维度 | 状态 | 下一步触发条件 |
|------|------|---------------|
| Identity（M1） | ✅ | 遵循 `M1-final-decisions.md`；kind 新增走 `01 §2.4 append-only` |
| Artifact（M2） | ✅ 主体 | 带 6 条 BAN 遗留（见 `M1-debt-ledger.md §1.1`） |
| Layering × Event（M3） | ✅ | 无未决项 |
| **Snapshot（M4）** | 🚧 规划中 | **本 proposal 的核心推进目标** |
| Drift（M5） | 🚧 规划中 | 依赖 M4 snapshot schema 先定 |
| Evolution（M6） | 🚧 规划中 | 依赖 L1 events + M4 snapshot 一起喂数据 |
| Extensibility（M7） | ✅ | 在 M1 附带定稿 |

**结论**：kernel 侧的**下一个 milestone 是 M4 Snapshot 模型**，但**先落地首个 adapter 的 charter**（方案 B 优先，详见 §2），由真实 adapter 证据驱动 M4 起稿时机。

---

## 1. 工作流总览

本 proposal 管理两条工作流：

- **工作流 B · 首个 adapter 落地**（详见 §3）—— 阶段 1–2 执行主体
- **工作流 A · M4 Snapshot Model**（详见 §4）—— 阶段 2 分支 2b 触发，当前冻结

执行顺序锁定为"**B 先行、A 跟进**"，详见 §2。

---

---

## 2. 执行顺序：方案 B 优先（三阶段门控）

> 本节是 `status: published` 锁定的**唯一路径**。曾评估过的 A 优先 / 并行 两个选项及其淘汰理由见本节末。

### 2.1 核心判断

依赖方向上 kernel 是 adapter 的上游，但 kernel 的**正确性只有通过 adapter 的真实落地验证**才能确认。M4 Snapshot 模型若脱离真实 adapter 落地直接起草，产出仍是"纸面契约"，推翻重来概率高；而 adapter 落地会**反向暴露 M1–M3 kernel 的遗漏**（最有价值的信息）。

因此放弃并行，采用 **B 先行、A 跟进** 的串行顺序。

### 2.2 阶段 1（立即）· 首个 adapter 的最小闭环

**目标**：用一份最小但完整的 adapter 文档，把 kernel 的 7 维契约走一遍真实的落地路径。

**产出**：
- `adapters/<adapter_name>/00-charter.md`（**只做 1 份**，不贪多）
  - adapter 身份声明：scope 边界、上游 kernel rev
  - 四扩展点（Task 类型 / Acceptance / Trace / Evolution Source）的**占位声明**
  - 该 adapter **当下要解决什么业务问题**的一句话陈述

**门控（全部满足方可退出阶段 1）**：
- [ ] charter 必须显式引用 kernel **≥5 篇章节锚点**（验证 kernel 足够"可被引用"）
- [ ] 手动跑 `./scripts/kernel-wordcheck.sh --file docs/piao-pipeline/adapters/<adapter_name>/00-charter.md` 确认豁免边界正确（adapters/ 默认豁免，但脚本应返回 0）
- [ ] 产出 `adapters/<adapter_name>/_review/adapter-charter-review.md`，记录三件事：
  1. 引用的 kernel 锚点清单
  2. 在 kernel 中**找不到答案**的问题（歧义 / 缺口 / 卡点）
  3. 对 kernel 的**建议修订**（初步条目，未分类）

### 2.3 阶段 2（阶段 1 完成后）· 消化反馈 → 决定 M4 起稿

根据 `adapter-charter-review.md` 中「kernel 缺口」条目数分支：

**分支 2a：缺口 ≥ 3 条**
- 先把所有缺口登记进 `M1-debt-ledger.md §1.2`（新开条目）
- **不立刻起 M4**，继续写第 2 份 adapter 文档（如 `10-event-mapping.md`）积累更多证据
- 目的：凑够 5–7 条真实缺口后再**统一**处理，避免 kernel 被零散打补丁

**分支 2b：缺口 ≤ 2 条且均为小缺口**
- 说明 M1–M3 kernel 健壮度够
- **开启工作流 A**：起草 `04-version-snapshot.md` （由 adapter 实战证据支撑 snapshot scope 语义）

### 2.4 阶段 3（阶段 2 后）· 回补 M1-debt-ledger §1.1 的 6 条 BAN

- 前两阶段都在"画边界"，本阶段是**清理既有违规**
- 6 条 BAN 都在 `02-artifact-model.md`，逐条处理（改写 / 反引号包裹 / 迁入 adapter）
- **不能先做**的理由：改 02 会触发 M2 rev v1→v2 的版本抬升，现阶段抬升会与 adapter 落地和 M4 起稿产生版本冲突

### 2.5 被淘汰的方案（决策溯源）

| 方案 | 淘汰理由 |
|------|---------|
| A. Kernel 优先（先 M4） | M4 脱离真实场景凭空构造，后续 adapter 落地时推翻重来概率高；只能自审，可观测性低 |
| C. 并行（同日启动 A + B） | 两条工作流共享同一 kernel 语汇表，并行编辑易产生概念漂移；单人工作流并行 = 频繁上下文切换，质量下降；合并/review 需两次认知加载 |

---

## 3. 工作流 B（阶段 1–2 执行主体）· 首个 adapter 落地

> 工作流 A（M4 Snapshot Model）的详细要求移至 §4，**必须先完成阶段 1 才进入**。

### 3.1 产出物

1. `docs/piao-pipeline/adapters/<adapter_name>/00-charter.md`（阶段 1）
2. `docs/piao-pipeline/adapters/<adapter_name>/_review/adapter-charter-review.md`（阶段 1）
3. 后续文档（10-event-mapping.md / task-types.md / acceptance-criteria.md / trace-impl.md / evolution-sources.md）按 `adapters/README.md` 目录结构顺序展开，每份文档产出前**必须先产出配对的 `_review/*-review.md`**，不产 review 不合并

### 3.2 依赖已定契约

- `07-extensibility.md §2` 的四个扩展点（Task 类型 / Acceptance / Trace / Evolution Source）
- `01-identity-model.md §1.1` URN grammar + §2 kind 枚举
- `02-artifact-model.md §6` artifact 生命周期 + §4 provenance
- `03-layered-architecture.md §3.1` L1 事件枚举
- `scenario-wordlist.md`（adapter 目录虽豁免，但词表仍是双向沟通的"通用词表"）

### 3.3 review 文档的强制格式

adapter 侧的 `_review/*-review.md` 必须包含以下三段：

```markdown
## 1. 引用的 kernel 锚点
- `kernel/01-identity-model.md §X.Y` — 用于 [目的]
- ...

## 2. 在 kernel 中找不到答案的问题
- [Q1] [具体描述] — [触发场景]
- ...

## 3. 对 kernel 的建议修订
- [R1] [建议条目] — [影响范围]
- ...
```

这一强约束与 kernel 侧的 `M1-exit-check.md` / `M1-debt-ledger.md` 对等，建立 adapter 侧自己的"退出门"。

---

## 4. 工作流 A（阶段 2 分支 2b 触发）· M4 Snapshot Model

**产出物**：`docs/piao-pipeline/kernel/04-version-snapshot.md`（首版 draft）

**依赖已定契约**：
- `01 §5` event_id 格式 + `01 §14` 快照即事实原则
- `02 §6` artifact 生命周期 + `02 §4` provenance 四元组
- `03 §3.1` L1 事件枚举

**必须回答的四个问题**（M4 验收必要条件）：
1. **何时打快照**：阶段切换边界（SPEC→PLAN、PLAN→IMPLEMENT、…）是唯一触发点，还是允许手动触发？
2. **快照装什么**：L1 event 流指针（轻）还是完整 artifact 集合的引用（重）？
3. **快照如何寻址**：`urn:piao:snapshot:<scope>:<name>@v<rev>` 的 scope 语义（按 unit？按 stage？按 taskdag 实例？）
4. **快照与 drift 的接口**：drift engine 读两个 snapshot 时，应能在 O(1) 内识别"哪些 artifact URN 变了"——snapshot schema 必须支持这一查询

**非目标**（M4 不做）：
- drift 传播算法（M5）
- snapshot GC / 归档策略（可推后到 M7 之后）

**启动前置**：阶段 2 的分支判定结果为 **2b**（缺口 ≤ 2 条）。若为 **2a**，本工作流继续冻结。

---

## 5. 里程碑地图（参考节奏）

```
2026-04-18 ┤ M1 review 收尾 + 本 proposal published（当前位置）
           │   ├── M1-final-decisions.md   snapshot@v1 published
           │   ├── M1-debt-ledger.md       published（6 条 BAN 遗留）
           │   ├── M1-exit-check.md       published
           │   └── post-m1-kickoff.md     proposal@v1 published (本文件)
           │
2026-04-2x ┤ 阶段 1 完成：首个 adapter 00-charter.md + adapter-charter-review.md
           │
2026-05-xx ┤ 阶段 2 分支判定
           │   ├── 若 2a：写第 2 份 adapter 文档，缺口登记至 M1-debt-ledger §1.2
           │   └── 若 2b：启动工作流 A（04-version-snapshot.md 首版 draft）
           │
2026-05-xx ┤ 阶段 3：02-artifact-model.md@v2 published（6 条 BAN 清零）
           │   └── M1-debt-ledger → consumed
           │
2026-06-xx ┤ M4 published → 启动 M5 Drift
           │
2026-xx-xx ┤ v0.1 里程碑（kernel 七大模型全部 published + 首个 adapter 最小实现）
```

**注意**：上述日期为**参考节奏**，不是硬性承诺。实际调度以 `task.*` 事件的 `planned_at` 字段为准。

---

## 6. 本 proposal 的演进

- **当前 status**：`published`（2026-04-18 升级，见 front-matter `published_at`）
- **锁定范围**：§2 执行顺序（方案 B 优先三阶段）是 published 的硬约束；§3–§5 为执行细则，细节调整不构成 rev 升降
- **触发 rev v2 的条件**：
  - §2 执行顺序被事实证据否决（如阶段 1 发现 kernel 根本无法支撑任何 adapter 起稿）
  - 工作流 A / B 的**目标**被重新定义（不仅是产出物清单变动）
- **消费事件**：每启动一个工作项发一条 `task.started`，关联 `parent_proposal: urn:piao:proposal:kernel:post_m1_kickoff@v1`
- **关闭条件**：工作流 A 首版 draft 落地 + 工作流 B 至少两份 adapter 文档 published + M1-debt-ledger consumed → `status: published → superseded`（由 M2 或 post-M4 的新 proposal 承接）

---

**本 proposal 状态**：**superseded**（2026-04-19 02:10 · 由 `urn:piao:snapshot:kernel:m4_final_decisions@v1` 承接；原 published 状态自 2026-04-18 22:10 起至 2026-04-19 02:10 有效）
**上游锚点**：M1 三份收尾文档（见 front-matter `upstream`）
**下游追述**：
- `docs/piao-pipeline/adapters/<adapter_name>/00-charter.md`（阶段 1 首产出）✅ 已产出配对 review
- `docs/piao-pipeline/kernel/04-version-snapshot.md`（阶段 2 分支 2b 产出）✅ **已 published @v1.1（M4 milestone 收官）**
- `02-artifact-model.md@v2`（阶段 3 rev 升降）⏳ 仍在规划
- **承接快照** `urn:piao:snapshot:kernel:m4_final_decisions@v1` ✅ 已产出（M4 milestone 完成点）
- **承接 proposal** `urn:piao:proposal:kernel:m5_drift_kickoff@v1` ✅ 已产出（2026-04-19 02:40 · M4→M5 过渡编排，接力本 proposal 的"kickoff 角色"；本条追述属 `01 §10.1` append-only 合规增补，不升 rev）
