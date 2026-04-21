---
urn: urn:piao:proposal:kernel:m5_drift_kickoff@v1
kind: proposal
rev: v1
status: superseded
superseded_by: urn:piao:snapshot:kernel:m5_final_decisions@v1
superseded_at: 2026-04-19T15:40:00+08:00
produced_by: m4-milestone-closeout-2026-04-19
published_at: 2026-04-19T02:40:00+08:00
upstream:
  - urn:piao:snapshot:kernel:m4_final_decisions@v1
  - urn:piao:spec:architecture:version_snapshot@v1.1
  - urn:piao:spec:architecture:layered_architecture@v1
  - urn:piao:evolution_source:kernel:m1_debt_ledger@v5
supersedes: urn:piao:proposal:kernel:post_m1_kickoff@v1
wordcheck_exempt: true
---

> **⚠️ 本 proposal 已 superseded（2026-04-19 15:40）**
>
> **承接快照**：`urn:piao:snapshot:kernel:m5_final_decisions@v1`（见 `_review/m5-final-decisions.md`）
>
> **关闭原因**：本 proposal §6 关闭条件四项全达成——
> 1. ✅ 工作流 T（阶段 α · M4 工具链补齐）· `piao-snapshot-produce.sh` + `piao-snapshot-diff.sh` + `m4-toolchain-review.md @v1 published` 三件已产出（见 `§10.1` 追述）
> 2. ✅ 工作流 D（阶段 β · M5 Drift 规格起稿）· `05-drift-propagation.md @v1.1 published`（2026-04-19 15:40 封版 · §8.2 四门控全达成）
> 3. ✅ `_review/m5-drift-draft-review.md @v1 published`（kernel 锚点 20/20 存在 · 五问 R1–R5 五硬约束证据完备 · 路径 A R17–R20 + 路径 B R21–R25 九条裁定全产出）
> 4. ✅ `_review/m5-final-decisions.md @v1 published`（M5 milestone 终态快照 · 六大决议矩阵 + 九 commit 证据链 · §6 kickoff 生命周期闭合表 + §7 05 published 门控复核表）
>
> **保留本正文不修改**作为历史追溯锚点；如需查询 M5 milestone 最终形态，请直接引用 `m5_final_decisions@v1`。本 proposal 的承接点是"milestone 收官快照"（而非下一 kickoff proposal）· 与 `post-m1-kickoff @v1 superseded_by: m4_final_decisions@v1` 范式同构。
>
> **下一 kickoff proposal**：`urn:piao:proposal:kernel:m6_evolution_kickoff@v1`（待产出 · M5→M6 过渡 · 接力本 proposal 的"kickoff 角色"· 以本篇 §6 drift→evolution 接口 + `m5_final_decisions@v1` 决议 5 为强约束输入）

# M5 Drift Kickoff · M4 milestone 收官后的 drift 层起稿工作编排

> 本文档是 **M4 milestone 收官后的工作编排 proposal**（2026-04-19 02:40），承接 `post-m1-kickoff@v1 (superseded)` 的角色——由 M4 milestone 推进到 M5 milestone 起稿阶段。
>
> **定位**：`kind: proposal`（不是 snapshot，因为计划可能被 drift 早期工具链证据调整）。
>
> **消费方式**：进入任一工作项前，把对应段落转为 `task.*` L1 事件并关联回本 proposal 的 URN。
>
> **阅读路径**：先读 `m4-final-decisions.md`（已决议的约束）→ 再读 `05-drift-propagation.md @v0.1`（M5 起稿骨架）→ 再读 `M1-debt-ledger.md @v5`（已知遗留）→ 最后读本文档（下一步去哪）。

---

## 0. 当前位置总览

按 `00-overview.md §1 核心公式` 的 7 维进度（M4 收官时刻 · 2026-04-19 02:10）：

| 维度 | 状态 | 下一步触发条件 |
|------|------|---------------|
| Identity（M1） | ✅ @v1.2 published | 稳定；新 kind 走 `01 §2.4 append-only` |
| Artifact（M2） | ✅ @v1.2 published（带 6 条 BAN 遗留 + Q4 WARN） | 阶段 3 `02@v2` 清理 §1.1 六条 BAN + §1.2 Q4 |
| Layering × Event（M3） | 🔄 @v1 draft | M1 review 周期内持续原地修订；draft→published 待 M5 draft 稳定后合并推进 |
| **Snapshot（M4）** | ✅ **@v1.1 published**（2026-04-19 02:10 收官） | 无未决项；本 proposal 为其下游延伸 |
| **Drift（M5）** | 🚧 **本 proposal 的核心推进目标** | 见 §2 执行顺序 |
| Evolution（M6） | 🚧 规划中 | 依赖 M5 §6 drift→evolution 接口 schema 先定 |
| Extensibility（M7） | ✅ @v1.1 published | 稳定 |

**结论**：kernel 侧的**下一个 milestone 是 M5 Drift 模型**，但**必须先解决工具链底座空缺**——`scripts/snapshot-produce.sh` / `scripts/snapshot-diff.sh` 在 M4 milestone 收官时**仍未实现**（见 §2.1），这是 M5 起稿的硬门控。

---

## 1. 工作流总览

本 proposal 管理两条工作流：

- **工作流 T · M4 工具链补齐**（详见 §3）—— 阶段 α 执行主体（当前冻结前置）
- **工作流 D · M5 Drift 模型起稿**（详见 §4）—— 阶段 β 执行主体，依赖工作流 T 输出

执行顺序锁定为"**T 先行、D 跟进**"，详见 §2。这与 `post-m1-kickoff @v1` 的"**B 先行、A 跟进**"范式同构（真实证据驱动规格起草）。

---

## 2. 执行顺序：方案 T 优先（两阶段门控）

> 本节是 `status: published` 锁定的**唯一路径**。曾评估过的 D 优先 / 并行 两个选项及其淘汰理由见本节末。

### 2.1 核心判断

**背景事实**：

1. M4 milestone 已完成 kernel 侧 schema 封板（`04 §5 snapshot_diff 算子契约` + `04 §3.2.1 规范化规则`），但**工具链侧**的 `snapshot-produce.sh` / `snapshot-diff.sh` **尚未实现**（见 `m4-final-decisions §4` 与 `05 §5` 明确列出的遗留）。
2. M5 drift 层的五个必答问题（Q5.1-Q5.5 见 `05 §1`）中，Q5.2（触发时机）与 Q5.4（归因算法）**本质上需要 diff 算子的实际运行证据**来定形——否则纯论证产出的 drift schema 与 M4 的 snapshot schema 之间会出现**"纸面契约"级漂移**（同 M1→M4 阶段曾评估的 A 优先方案被淘汰的原因）。
3. 项目已有同名脚本 `scripts/snapshot-generator.sh`，它是**道聚城 Kuikly 架构扫描器**（与 piao-pipeline 无关），命名空间冲突风险已知（见 §3.1 规避方案）。

**依赖方向判断**：工具链 T 是规格 D 的**事实生成器**，规格 D 是工具链 T 的**正确性约束**。两者互为上下游，但**触发顺序锁定为 T→D**：

- T 可先以 `04 @v1.1 published` 为唯一规格依据落地 MVP（无需等待 D）
- D 若脱离 T 实操证据起草，`05 §5 归因算法` / `05 §3 触发契约` 都会沦为"推理层语义"——与 M4 评估"A 优先脱离 adapter 证据"的反模式同构

### 2.2 阶段 α（立即）· 工作流 T 最小闭环

**目标**：用最小 MVP 的两个脚本，把 `04 §5 snapshot_diff 算子契约` 走一遍真实的可执行路径。

**产出**：

1. `scripts/piao-snapshot-produce.sh`（**只做 1 份 MVP**，不贪多）
   - **命名避让**：前缀 `piao-` 以规避 `scripts/snapshot-generator.sh` 的命名空间冲突
   - 输入：`--scope-kind {unit|stage|taskdag|adapter|kernel}` + `--scope-ref <urn>` + `--frozen-artifacts <list>`
   - 输出：按 `04 §3.2 schema` 五元组生成的 snapshot yaml（写入 `pipeline-output/snapshots/`）
   - 契约承诺：产出的 yaml 经 `04 §3.2.1 canonical YAML 五步规范化`后可再现同样的 `content_sha256`

2. `scripts/piao-snapshot-diff.sh`（**只做 1 份 MVP**）
   - 输入：`<snapshot_path_1> <snapshot_path_2>`
   - 输出：四个 URN 集合 `added` / `removed` / `sha_changed` / `unchanged`（JSON 或文本两种模式）
   - 契约承诺：实现复杂度 O(|s1.frozen| + |s2.frozen|)，符合 `04 §5` 算子契约

**门控（全部满足方可退出阶段 α）**：

- [ ] 两脚本对 `m4_final_decisions@v1` 作为输入时，`diff(m4_final_decisions@v1, m4_final_decisions@v1) == {unchanged: [...全部], 其余: []}`（**自反性验证**）
- [ ] 两脚本对"M1 snapshot vs M4 snapshot"作为输入时，能正确识别 `01` / `02` / `04` 三份 URN 的 `sha_changed`（**真实差分验证**）
- [ ] 手动跑 `./scripts/kernel-wordcheck.sh` 确认 scripts/ 目录不纳入词表（命名不引入新违规）
- [ ] 产出 `_review/m4-toolchain-review.md`，记录三件事：
  1. 实现过程中发现的 `04 §3.2.1 规范化规则`的**操作歧义**（若有）
  2. 实现过程中发现的 `04 §5 snapshot_diff 算子契约`的**边界用例缺失**（若有）
  3. 对 M5 drift 层 §3 触发契约的**工具链视角建议**（规格起草的输入）

### 2.3 阶段 β（阶段 α 完成后）· 消化工具链证据 → 决定 M5 draft 起稿

根据 `_review/m4-toolchain-review.md` 中「工具链视角发现」条目数分支：

**分支 β-1：发现 ≥ 3 条 kernel 契约歧义 / 边界缺失**

- 先把所有歧义登记进 `M1-debt-ledger.md §1.4`（新开 v6 升版 · 对标 §1.2 / §1.3 范式）
- **不立刻起 M5 draft**，优先做 `04 @v1.1 → @v1.2` 的补充性小升（类似 M4 路径 A 的原地消化）
- 补升完成后再进入分支 β-2

**分支 β-2：发现 ≤ 2 条且均为小歧义**

- 说明 M4 契约健壮度够
- **开启工作流 D**：起草 `05-drift-propagation.md` 的正式 draft（当前 @v0.1 骨架升 @v1 draft）
- 起草路径对标 M4：先 draft → 再 draft-review（配对 `_review/m5-drift-draft-review.md`）→ 再 milestone 收官（`_review/m5-final-decisions.md`）

### 2.4 被淘汰的方案（决策溯源）

| 方案 | 淘汰理由 |
|------|---------|
| **D 优先（先 M5 draft）** | M5 §5 归因算法 / §3 触发契约脱离实际 diff 运行证据，会沦为"纸面语义"——与 M4 评估"A 优先"被淘汰的原因同构 |
| **并行（同日启动 T + D）** | 两条工作流共享 `04` 契约且需要双向反馈（T 发现歧义 → D 修 04 引用；D 起草疑问 → T 提供证据），并行会产生 04 锚点争用；单人工作流并行 = 频繁上下文切换，质量下降 |

### 2.5 与 `post-m1-kickoff @v1` 的同构关系

| 维度 | post-m1-kickoff @v1 | m5-drift-kickoff @v1（本 proposal） |
|------|---------------------|-----------------------------------|
| 触发时刻 | M1 milestone 收官（2026-04-18 22:10） | **M4 milestone 收官（2026-04-19 02:10）** |
| 先行工作流 | 工作流 B（adapter 落地，证据驱动） | **工作流 T（工具链落地，证据驱动）** |
| 跟进工作流 | 工作流 A（M4 Snapshot 规格） | **工作流 D（M5 Drift 规格）** |
| 执行顺序理由 | "规格脱离真实证据会推翻重来" | **同上** |
| 承接快照 | `m4_final_decisions@v1` | **`m5_final_decisions@v1`**（待产出） |

**策略连贯性**：本 proposal 延续 `post-m1-kickoff` 的"真实证据驱动规格起草"范式，避免走回 A 优先的反模式。

---

## 3. 工作流 T（阶段 α 执行主体）· M4 工具链补齐

### 3.1 命名空间规避

**背景**：`scripts/snapshot-generator.sh` 已被道聚城项目占用（Kuikly 架构扫描器，业务侧），与 piao-pipeline 无直接关系但命名接近。

**规避方案**：

- 所有 piao-pipeline 工具链脚本统一加 `piao-` 前缀
- `scripts/piao-snapshot-produce.sh`（本 proposal 新增）
- `scripts/piao-snapshot-diff.sh`（本 proposal 新增）
- 未来 `scripts/piao-drift-compute.sh` 等同样加前缀（M5 draft 产出时登记）

### 3.2 产出物

1. `scripts/piao-snapshot-produce.sh`（阶段 α 核心产出）
2. `scripts/piao-snapshot-diff.sh`（阶段 α 核心产出）
3. `docs/piao-pipeline/kernel/_review/m4-toolchain-review.md`（阶段 α 退出门）

**不做**（阶段 α 非目标）：
- drift 算法本体（M5 规格，工作流 D 范畴）
- snapshot GC / 归档（M7 之后）
- 可视化 dashboard（工具链进阶，kernel 无关）
- 完整 CI 集成（MVP 仅要求手动可运行且自反性/真实差分两项验证通过）

### 3.3 依赖已定契约

- `04 §2.2 产出契约`（三步原子顺序：`artifact.published(snapshot) → stage.exited → artifact.published(下一产出)`）
- `04 §3.2 snapshot schema`（front-matter 五要素 + body 五元组列表）
- `04 §3.2.1 content_sha256 canonical YAML 五步规范化`
- `04 §3.3 scope_kind 五类枚举封板`
- `04 §5 snapshot_diff 算子契约`（输入/输出/复杂度/可重复性四要素）

### 3.4 review 文档的强制格式（m4-toolchain-review.md）

对标 `post-m1-kickoff §3.3` 的 adapter review 三段式：

```markdown
## 1. 引用的 kernel 锚点
- `kernel/04-version-snapshot.md §X.Y` — 用于 [目的]
- ...

## 2. 实现过程中发现的 kernel 契约歧义/缺失
- [T1] [具体描述] — [触发场景]
- ...

## 3. 对 M5 drift 规格起草的工具链视角建议
- [TB1] [建议条目] — [Q5.X 对应]
- ...
```

这一强约束与 `m4-snapshot-draft-review.md` / `adapter-charter-review.md` 对等，建立 **M5 起稿前的最后一道证据门**。

---

## 4. 工作流 D（阶段 β 分支 β-2 触发）· M5 Drift 规格起稿

**产出物**：`docs/piao-pipeline/kernel/05-drift-propagation.md`（@v0.1 骨架 → @v1 首版 draft）

**依赖已定契约**：
- 本 proposal 工作流 T 的产出（`piao-snapshot-produce.sh` + `piao-snapshot-diff.sh` + `m4-toolchain-review.md`）
- `04 §5 snapshot_diff 算子`（drift 归因的直接基础）
- `04 §3.2.1 content_sha256 规范化`（drift 可重复性的前提）
- `04 §3.3 scope_kind 五类封板`（drift 对比的边界语义）
- `02 §4 provenance 四元组` + `02 §5 lineage 查询器`（含 `§5.3.1 snapshot 特化`）
- `03 §3.1 L1 十类事件封板`（drift 不新增 L1 类型的封板约束）
- `01 §2.1 kind 枚举`（`drift` 已是核心 kind 之一）

**必须回答的五个问题**（M5 验收必要条件，对标 `post-m1-kickoff §4` 的四个必答问题）：

1. **drift 的身份（Q5.1）**：drift 本身是 artifact 吗？`artifact_type` 候选 `drift.propagation_record`
2. **drift 的触发（Q5.2）**：drift 算法何时运行？每次 `artifact.published` 后自动？阶段切换批量？手动？
3. **drift 的 scope（Q5.3）**：drift 对比的"两张 snapshot"如何选？邻接两次？同 scope_kind 最近两次？调用方指定？
4. **drift 的归因（Q5.4）**：如何把"A 的 sha 变了"追溯到"B 事件触发的"？依赖 `produced_by.event_id` provenance 链
5. **drift→evolution 的接口（Q5.5）**：drift 应输出什么 schema 让 M6 evolution O(1) 决策？

**非目标**（M5 不做）：
- snapshot GC / 归档策略（M7 之后）
- drift 的可视化层 / dashboard UI（工具链侧，非 kernel）
- evolution 模型本体（M6 的范畴；M5 只提供 drift→evolution 接口 schema）

**启动前置**：阶段 α 的分支判定结果为 **β-2**（工具链发现 ≤ 2 条小歧义）。若为 **β-1**，本工作流继续冻结直至 `04 @v1.1 → @v1.2` 补升完成。

---

## 5. 里程碑地图（参考节奏）

```
2026-04-19 02:10 ┤ M4 milestone 收官（04 @v1.1 published + m4_final_decisions@v1）
                 │   ├── post-m1-kickoff @v1 → superseded
                 │   ├── M1-debt-ledger @v4 → @v5（Q8-Q14 consumed）
                 │   └── 05-drift-propagation.md @v0.1 起稿骨架
                 │
2026-04-19 02:40 ┤ 本 proposal @v1 published（当前位置）
                 │
2026-04-2x       ┤ 阶段 α 完成：piao-snapshot-produce.sh + piao-snapshot-diff.sh + m4-toolchain-review.md
                 │   └── MVP 自反性 + 真实差分 双验证通过
                 │
2026-05-xx       ┤ 阶段 β 分支判定
                 │   ├── 若 β-1：`04 @v1.1 → @v1.2` 补升 + M1-debt-ledger @v5 → @v6
                 │   └── 若 β-2：启动工作流 D（05-drift-propagation.md @v0.1 → @v1 draft）
                 │
2026-05-xx       ┤ M5 draft → draft-review → milestone 收官
                 │   └── m5_final_decisions@v1 + m5-drift-draft-review.md
                 │
2026-06-xx       ┤ M6 Evolution 起稿（依赖 M5 §6 drift→evolution 接口）
                 │   └── post-m5-kickoff 或 m6_evolution_kickoff proposal 承接
                 │
2026-xx-xx       ┤ v0.1 里程碑（kernel 七大模型全部 published）
```

**注意**：上述日期为**参考节奏**，不是硬性承诺。实际调度以 `task.*` 事件的 `planned_at` 字段为准。

---

## 6. 本 proposal 的演进

- **当前 status**：`published`（2026-04-19 02:40 · `produced_by: m4-milestone-closeout-2026-04-19`）
- **锁定范围**：§2 执行顺序（方案 T 优先两阶段）是 published 的硬约束；§3–§5 为执行细则，细节调整不构成 rev 升降
- **触发 rev v2 的条件**：
  - §2 执行顺序被事实证据否决（如阶段 α 发现 `04 §5` 算子契约根本无法被脚本实现）
  - 工作流 T / D 的**目标**被重新定义（不仅是产出物清单变动）
- **消费事件**：每启动一个工作项发一条 `task.started`，关联 `parent_proposal: urn:piao:proposal:kernel:m5_drift_kickoff@v1`
- **关闭条件**：工作流 T 产出 MVP 双脚本 + m4-toolchain-review.md published + 工作流 D 首版 draft 落地 + M5 milestone 收官 → `status: published → superseded`（由 `m5_final_decisions@v1` 承接）

---

## 7. 与 `post-m1-kickoff @v1` 的接力关系

本 proposal **显式 supersedes** `post-m1-kickoff @v1`：

- front-matter `supersedes: urn:piao:proposal:kernel:post_m1_kickoff@v1`
- 角色接力：post-m1-kickoff 处理 "M1→M4 过渡"，本 proposal 处理 "M4→M5 过渡"
- 不改动 post-m1-kickoff 的 `superseded_by` 指向（仍为 `m4_final_decisions@v1`，因其承接点是 milestone 收官快照而非下一 kickoff；这与本 proposal 的 supersedes 语义是**不同的双向锚点**——承接快照 vs 承接 proposal）
- **双向可追溯**：post-m1-kickoff @v1 的篇尾下游追述将追补"承接 proposal: m5_drift_kickoff@v1"一行（见 §9 动作清单）

---

## 8. 对 `M1-debt-ledger` 的影响

- **§1.1 六条 BAN**：仍延期至阶段 3 `02@v2` 清理，不受本 proposal 影响
- **§1.2 Q4**：同上（与 §1.1 合并）
- **§1.3 Q8-Q14**：已全部 consumed（@v5），本 proposal 不重复处置
- **§1.4 待新建**：若阶段 α 发现 `04` 契约歧义，将在本 proposal 工作流 T 退出时触发 `@v5 → @v6` 升版，§1.4 登记新条目（登记 + consume 同轮，对标 @v4→@v5 范式）

---

## 9. 本 proposal 的配套动作清单

本 proposal published 时同步完成的动作：

- [x] front-matter `supersedes: post_m1_kickoff@v1` 已声明
- [ ] `05-drift-propagation.md @v0.1 → @v0.2`：front-matter `upstream` 追加本 proposal URN + `§5 起稿节奏建议`修订为引用本 proposal §2 的两阶段门控（取代原来的概括性五步建议）
- [ ] `post-m1-kickoff @v1` 篇尾"下游追述"段**追补一行**：`承接 proposal: urn:piao:proposal:kernel:m5_drift_kickoff@v1 ✅ 已产出`（保留 superseded 状态，不升 rev，按 `01 §10.1` append-only 追述合规）
- [ ] `m4-final-decisions @v1 §4 下一步清单` 勾选最后两项（`m5_drift_kickoff@v1` 产出 ✅ + `05-drift-propagation.md` 骨架 ✅）——**不做**：final-decisions 是快照即事实（`01 §14`），产出后不修改。改为在本 proposal §7 以追述方式闭合即可

---

**本 proposal 状态**：**superseded**（2026-04-19 15:40 · 由 `urn:piao:snapshot:kernel:m5_final_decisions@v1` 承接 · 原 published 状态自 2026-04-19 02:40 起至 2026-04-19 15:40 有效 · 共计约 13 小时完成 M4→M5 全周期）
**上游锚点**：
- `urn:piao:snapshot:kernel:m4_final_decisions@v1`（M4 收官快照 + 本 proposal 触发源）
- `urn:piao:spec:architecture:version_snapshot@v1.1 published`（M4 规格本体）
- `urn:piao:spec:architecture:layered_architecture@v1 draft`（M3 事件分层规格，drift 事件 L1 类型依赖）
- `urn:piao:evolution_source:kernel:m1_debt_ledger@v5`（债务账本当前状态）
**supersedes**：`urn:piao:proposal:kernel:post_m1_kickoff@v1`（接力 M1→M4 过渡 proposal 的角色）
**superseded_by**：`urn:piao:snapshot:kernel:m5_final_decisions@v1`（M5 milestone 收官快照承接 · 与 `post-m1-kickoff @v1 → m4_final_decisions@v1` 对称范式）
**实际下游产出**（published 周期内陆续落地）：
- ✅ `scripts/piao-snapshot-produce.sh`（293 行 · 阶段 α 核心产出）
- ✅ `scripts/piao-snapshot-diff.sh`（204 行 · 阶段 α 核心产出）
- ✅ `scripts/piao-drift-compute.sh`（555 行 · 阶段 α 扩展产出 · 四场景冒烟全通 · commit `bcc56229`）
- ✅ `_review/m4-toolchain-review.md @v1 published`（阶段 α 退出门）
- ✅ `05-drift-propagation.md @v1.1 published`（阶段 β 主产出 · 分支 β-2 触发路径 + 路径 A 原地 + 路径 B 跟随升版 · §8.2 四门控全达成）
- ✅ `_review/m5-drift-draft-review.md @v1 published`（阶段 β 工作流 D 退出门 · commit `596f2ad2`）
- ✅ `_review/m5-drift-kernel-alignment-proposal.md @v1 published`（路径 B R21–R25 打包处置 · commit `78134de8`）
- ✅ `_review/m5-final-decisions.md @v1 published`（M5 milestone 收官快照 · 本 proposal 关闭承接点 · commit `b8f877f9`）
- ⏳ `M1-debt-ledger @v5 → @v6`（同批提交 · 登记 Q15–Q20 六条 + R17–R25 九条 consumed · 对标 @v3→@v4 + @v4→@v5 范式）
**关闭承接点**：`urn:piao:snapshot:kernel:m5_final_decisions@v1`（**已落地**）

---

## 10. 追述（append-only · 不升 rev · 按 `01 §10.1` 合规）

### 10.1 阶段 α 退出点（2026-04-19 03:30 追补）

**事实记录**（本 proposal 状态保持 published @v1 不变，仅追述过程里程碑）：

- ✅ `scripts/piao-snapshot-produce.sh` MVP 已产出（293 行 · bash + python3）· 命名避让 `snapshot-generator.sh` 完成
- ✅ `scripts/piao-snapshot-diff.sh` MVP 已产出（204 行 · bash + python3）· 命名避让完成
- ✅ 四项端到端验证全通：①自反性 `diff(s,s)==unchanged:7` ②真实差分 `diff(s_a,s_b)` 精确识别 `added:1/removed:1/sha_changed:1/unchanged:5` ③`§5.3` 跨 scope_kind 拒绝 ④`--format json` 有效
- ✅ `_review/m4-toolchain-review.md @v1 published`（阶段 α 退出门产出 · 对标 `post-m1-kickoff §3.3` 三段式 + `m4-snapshot-draft-review` 范式）
- ✅ wordcheck 零新增违规（6 BAN + 5 WARN 基线不变）· IDE lints 0 错误
- ✅ 分支判定：**β-2**（发现 5 条但无一触发 β-1 条件 · 详见 `m4-toolchain-review §2.6`）
- ⏭ 下一步：按本 proposal §2.3 分支 β-2 启动工作流 D · `05-drift-propagation.md @v0.2 → @v1 draft`（以 `m4-toolchain-review §3` 四条 TB 建议为强约束输入）

**阶段 α 意外收获**：MVP 实施过程实测印证了 `04 §3.2.1` canonical 规范化的核心特性——跨 scope_kind 产出的 snapshot 若 `frozen_artifacts` 相同则 `content_sha256` 相同（front-matter 不参与 sha 计算）。这让"dedup 识别"从规格声明变成了实测证据。

### 10.2 阶段 β 退出点 + M5 milestone 收官（2026-04-19 15:40 追补）

**事实记录**（本 proposal 状态由 `published → superseded` · 状态转换同步完成 · 详见 front-matter + 篇首 superseded 通告）：

- ✅ `05-drift-propagation.md @v0.2 → @v1 draft` 起稿（阶段 β 工作流 D 首版）· 以 `m4-toolchain-review §3` TB1–TB5 四条建议为强约束输入 · R1–R5 五硬约束全展开
- ✅ `_review/m5-drift-draft-review.md @v1 published`（阶段 β 退出门 · commit `596f2ad2`）· 对标 `m4-snapshot-draft-review.md` 三段式 · kernel 锚点 20/20 存在 · 五问 R1–R5 证据完备 · 路径 A R17–R20 + 路径 B R21–R25 九条裁定全产出 · 识别 Q15–Q20 六条可完善空间
- ✅ `05 @v1 draft` 路径 A 原地消化（2026-04-19 14:10）· R17–R20 四条改写完毕 · 不升 rev（按 `01 §10.1` draft 可原地修订契约）
- ✅ `_review/m5-drift-kernel-alignment-proposal.md @v1 published`（commit `78134de8`）· 路径 B R21–R25 打包 proposal
- ✅ 路径 B 三处外部消化同步落地：
  - `03 §3.3.1` 原地泛化 N 条 L1 事件同 txn（R22 · commit `49608733`）
  - `04 @v1.1 → @v1.2 published`（R21 新增 §3.2.3 canonical YAML 通用工具 + R24 `modified/sha_changed` 双名 alias · commit `c3b8fe82`）
  - `02 @v1.2 → @v1.3 published`（R23 扩为通用 lineage 特化注册表含 kind=drift 条目 + R25 派生类型注册 §2.2.4 补 `wordcheck_policy` 字段 · commit `f25dc403`）
- ✅ `05 @v1 draft → @v1.1 draft` 跟随升版（commit `d6ee71ac`）· 反映 04/02/03 外部升降 · schema 骨架与 R1–R5 五硬约束字面保持不变
- ✅ `m5-drift-draft-review §5` 路径 A/B 消化记录追补 + 05 §9 Q1/Q5 "已 consumed" 注释补齐（commit `c0991418`）
- ✅ `scripts/piao-drift-compute.sh` MVP 首版（555 行 · bash + python3 · commit `bcc56229`）· 阶段 α 扩展产出 · 端到端四场景冒烟全通：
  - ① `content_drift` · `added=3/removed=2/sha_changed=0/unchanged=2` · sha=`2601de6c`（幂等）
  - ② `initial_snapshot` · 四字段全零 · sha=`1126a39f`
  - ③ `no_change_drift` · `unchanged=4` · sha=`da03ff6d`
  - ④ `cross-scope` 拒绝 · 退出码 1 + 错误引用 `05 §4.1 R3`
- ✅ **R1–R5 五硬约束在 MVP 实施中全部反证通过**（schema / 唯一触发器 / scope 拒绝 / 归因降级 `attribution_mode=sha_only` / 双 producer_event_id 前缀分离 · SHA_WHITELIST 六字段不变性验证通过）
- ✅ `_review/m5-final-decisions.md @v1 published`（commit `b8f877f9`）· M5 milestone 收官快照 · 对标 `m4-final-decisions.md` 六大结构 · 决议 1–6 矩阵 + 九 commit 证据链 + §6 本 proposal 生命周期闭合表 + §7 05 published 门控复核表
- ✅ `05-drift-propagation.md @v1.1 draft → @v1.1 published`（commit `f224dcfa` · 2026-04-19 15:40）· 同 rev 内部状态转换（不升 rev · 不触发 supersedes）· §8.2 四门控全达成 · schema / R1–R5 / §2–§7 正文字面保持不变（封版守恒）

**本 proposal 生命周期闭环**（与 `post-m1-kickoff @v1` 对称范式）：

| 维度 | post-m1-kickoff @v1 | m5_drift_kickoff @v1（本 proposal） |
|------|---------------------|-----------------------------------|
| 起始时刻 | 2026-04-18 22:10 published | 2026-04-19 02:40 published |
| 封顶时刻 | 2026-04-19 02:10 superseded | **2026-04-19 15:40 superseded** |
| published 周期 | 约 4 小时 | **约 13 小时** |
| 承接快照 | `m4_final_decisions@v1` | **`m5_final_decisions@v1`** |
| 接力 proposal | `m5_drift_kickoff@v1`（本 proposal） | **`m6_evolution_kickoff@v1`**（待产出） |
| 实际执行与 §2 规划偏差 | A 优先被淘汰 · B 先行落地（与规划一致） | T 先行 · 分支 β-2 触发（与规划一致） |

**阶段 β 意外收获**：
- 路径 A + 路径 B 双通道分治范式在本 milestone 首次完整落地（M4 milestone 路径 A/B 是 _kernel 契约_ 侧 draft → published 迁移 · M5 milestone 是 _kernel 新模型_ 侧 draft → published 首版 · 两者范式同构但对象不同），反证"真实证据驱动规格起草"范式在 kernel 深层扩展时同样成立
- `piao-drift-compute.sh` MVP 的四场景冒烟同时反证 R1–R5 五硬约束，让"规格形式化保证"从 05 §0.1 矩阵声明变成 scripts + shell 返回值双源证据，这是比 `piao-snapshot-diff.sh` 阶段 α 更进一步的"工具链 ↔ 规格"双向验证闭环
- 本 proposal §2.3 "分支 β-2" 路径在实测中一次性通过（未触发 β-1 的 `04 @v1.1 → @v1.2` 补升分支）· 证明 kickoff proposal 的分支判定条件设计合理（`m4-toolchain-review §2.6` 5 条工具链侧发现均为"TB 建议"级 · 无"契约根本无法被脚本实现"级反例）

**M5 milestone 关闭总结**：按 `§6` 关闭条件四项全达成 · `m5_final_decisions@v1` 承接 · 本 proposal 角色终结 · 进入 `M1-debt-ledger @v6` 登记 + M6 Evolution milestone 起稿阶段（`m6_evolution_kickoff@v1` 接力候选 · 本篇 §6 drift→evolution 双通道 + C1–C4 前置契约 + `m5_final_decisions@v1` §1 决议 5 已锁定接口 schema）。
