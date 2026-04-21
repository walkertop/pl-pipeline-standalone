---
urn: urn:piao:snapshot:kernel:m4_final_decisions@v1
kind: snapshot
artifact_type: snapshot
rev: v1
status: published
produced_by:
  actor: m4-review-2026-04-19
  task_urn: urn:piao:task:m4:snapshot_milestone_closeout
  trigger_event_type: stage.exited
supersedes: null
upstream:
  - urn:piao:snapshot:kernel:m1_final_decisions@v1
  - urn:piao:artifact:kernel:m4_snapshot_draft_review@v1
  - urn:piao:proposal:kernel:m4_snapshot_kernel_alignment@v1
  - urn:piao:proposal:kernel:post_m1_kickoff@v1
wordcheck_exempt: true
---

# M4 Final Decisions · Kernel Snapshot 模型收敛快照

> 本文档是 **M4 review（2026-04-19）** 的最终决议快照，对标 `M1-final-decisions.md`。
> 定位：作为 `04-version-snapshot.md @v1.1 published` 的"发布证书"与后续 M5 drift 层的基线引用目标。
> 快照即事实：本文件**一经产出不再修改**；若未来推翻某条决议，新开 `m4_final_decisions@v2` 并在 v1 中标注 `superseded_by`。

---

## 0. 快照覆盖范围

- **受管文档**：
  - `docs/piao-pipeline/kernel/04-version-snapshot.md`（本次 milestone 的核心产出）
  - `docs/piao-pipeline/kernel/03-layered-architecture.md`（因路径 B 承接 R12/R13 而原地修订）
  - `docs/piao-pipeline/kernel/01-identity-model.md`（因路径 B 承接 R14 升 @v1.2）
  - `docs/piao-pipeline/kernel/02-artifact-model.md`（因路径 B 承接 R15/R16 升 @v1.2）
- **决议时间窗**：2026-04-18 23:55（04 @v1 draft 起稿）至 2026-04-19 02:10（04 @v1.1 draft → published）
- **依据**：
  - `_review/m4-snapshot-draft-review.md`（路径 A + 路径 B 全过程追述）
  - `_review/m4-snapshot-kernel-alignment-proposal.md`（路径 B 的 proposal 承载）

---

## 1. 五项最终决议

M4 milestone 要回答 `post-m1-kickoff.md §4` 锁定的**四个必答问题**；下表以决议形式正式入档，补第五条为跨篇一致性维护结论。

### 决议 1 — 何时打 snapshot：阶段边界为唯一触发点

**问题**：snapshot 的产出时机是仅限阶段切换（`stage.entered` / `stage.exited`），还是允许手动触发？

**决议**：**阶段边界为唯一客观触发点**；`task.finished` 可作为辅助触发（当 task 是 snapshot-producing 型）。**禁止**按 `task.started` / `task.finished`（普通任务）/ `artifact.superseded` / `evolution.scanned` / `drift.detected` 触发 snapshot。

**正式入档位置**：`04-version-snapshot.md §2`（§2.1 触发源 + §2.2 产出契约 + §2.3 非触发点 + §2.4 触发判定的客观性）。

**关键约束**：触发判定 100% 基于 L1 事件存在性，不依赖业务层信号。

---

### 决议 2 — 快照装什么：URN 集合 + sha256 双轨

**问题**：snapshot 的 body 是装 L1 event 指针（轻）还是完整 artifact 内容（重）？

**决议**：**方案 C · URN 集合 + sha256 双轨**。body 为有序 `frozen_artifacts` 列表，每行 `artifact_urn + content_sha256 + producer_event_id + producer_task_urn + artifact_type` 五元组。

**方案权衡**：

| 方案 | 装什么 | 单 snapshot 体积 | drift 查询复杂度 |
|-----|-------|---------------|----------------|
| A · 纯 event 指针 | 仅 last_event_id + 各 urn 最新 event_id | 几十字节 | O(N 事件数) |
| B · 完整 artifact 内容 | 每个 artifact 的完整 body | MB–数百 MB | O(1) 但体积不可控 |
| **C · URN + sha256 双轨** | URN + sha256 + producer_event_id | KB 级 | **O(1) 差分** |

**选择 C 的决定性理由**：
1. piao-pipeline 的 artifact **不删除只升 rev**（`02 §6`），C 方案依赖的"物理文件可解析"已被既有契约兜底
2. B 方案的"完全自给自足"是伪需求——drift 只需要"变没变"，不需要 artifact 内容
3. C 方案体积控制在 KB 级，允许高频打快照也不会把仓库撑爆

**正式入档位置**：`04-version-snapshot.md §3.1 / §3.2 / §3.2.1`。

---

### 决议 3 — 如何寻址：scope_kind 五类封板

**问题**：`urn:piao:snapshot:<scope>:<name>@v<rev>` 的 scope 语义——按 unit？stage？taskdag？adapter？kernel？

**决议**：**scope_kind 枚举封板为五类**（不可扩展，同 `03 §3.1` L1 事件封板原则）。

**最终 scope_kind 枚举**（`04-version-snapshot.md §3.3`）：

| scope_kind | 含义 | 典型触发 |
|-----------|------|---------|
| `unit` | 一个业务 unit 的某阶段边界快照 | `stage.entered` / `stage.exited` |
| `stage` | 跨 unit 的某同名 stage 的全局快照 | pipeline-orchestrator 编排事件 |
| `taskdag` | 一个 taskdag 实例执行过程的所有 artifact | taskdag 完整执行完；**依赖 stage 事件的 `related_taskdag_urn` 字段（必填约束见 §2.2）** |
| `adapter` | 一个 adapter 的整体 published 状态 | `artifact.published` 且 URN scope=adapter |
| `kernel` | kernel 文档集整体的 milestone 级快照 | milestone review 收尾（本快照即为 kernel scope_kind 的实例） |

**封板理由**：
1. scope_kind 一旦开放，adapter 可自定义 scope 会让 drift 的 sha 对比失去确定性
2. 五类覆盖实测场景（M1–M4 review + 首个 adapter charter 写作均可归位）
3. 若未来真出现第六类，走 kernel rev 升降而非 adapter 自扩展

**正式入档位置**：`04-version-snapshot.md §3.3 + §4`。

---

### 决议 4 — 与 drift 的接口：snapshot_diff 算子

**问题**：drift engine 读两个 snapshot 时如何在 O(1) 内识别"哪些 artifact URN 变了"？

**决议**：**定义 `snapshot_diff(s1, s2)` 算子**，输入两个 snapshot 的 URN 或路径，输出四类差分集合：`added` / `removed` / `sha_changed` / `unchanged`。算子的可重复性由 `content_sha256` 的 canonical YAML 规范化契约保证。

**算子契约要点**（`04-version-snapshot.md §5`）：
- 输入：两个 snapshot 文档（file 或 URN）
- 输出：四个 URN 集合（`added` / `removed` / `sha_changed` / `unchanged`）
- 实现复杂度：O(|s1.frozen| + |s2.frozen|)，但**不需要**回放 L1 事件
- 可重复性：同样 `frozen_artifacts` 规范化字节流 → 同样 `content_sha256`（见 `04 §3.2.1`）

**前置契约**：
- `02 §6` artifact 不删除只升 rev（保证 URN 可解析性）
- `04 §3.2.1` canonical YAML 规范化五步骤

**正式入档位置**：`04-version-snapshot.md §5`（M5 drift 层将基于此算子起稿）。

---

### 决议 5 — 跨篇一致性：路径 A + 路径 B 全量对接

**问题**：04 draft 完成后，在 review 过程中识别到的 Q8–Q14 七条缺口（3 条涉及 03/01/02 kernel 升降），如何与 04 本身的 draft→published 协调？

**决议**：**采用"先 A 后 B 再反向对接"五步执行序**，分别在 `m4-snapshot-draft-review.md §4.3` 与 `m4-snapshot-kernel-alignment-proposal.md` 锁定。

**五步执行序**（全部已完成）：

| Step | 动作 | 结果 | 产出 URN |
|------|------|------|---------|
| 1 | 路径 A：R8–R11 在 04 draft 内原地消化（不升 rev） | ✅ | `04 @v1 (draft · 路径 A 原地消化)` |
| 2 | 路径 B：启动 `m4_snapshot_kernel_alignment@v1` proposal，R12–R16 合并落地 | ✅ | `03 draft 原地修订` + `01 @v1.1→@v1.2` + `02 @v1.1→@v1.2` |
| 3 | 反向对接：04 @v1 draft → @v1.1 draft（六处锚点/schema 微调，仍 draft） | ✅ | `04 @v1.1 (draft)` |
| 4 | **本步**：04 @v1.1 draft → @v1.1 published + 本快照产出 | ✅（当前） | `04 @v1.1 published` + `m4_final_decisions@v1` |
| 5 | 收尾：M1-debt-ledger @v4→@v5（Q8–Q14 登记并一次性 consumed）+ post-m1-kickoff @v1 → superseded | ✅（当前） | `m1_debt_ledger@v5` + `post_m1_kickoff@v1 superseded` |

**R8–R16 九条修订的最终落地矩阵**：

| 修订 | 源自 | 目标 | 落地 rev | 路径 |
|-----|-----|------|---------|-----|
| R8 | Q10 | `04 §3.2 front-matter + §3.4` 加 `artifact_type: snapshot` | draft 内原地 | A |
| R9 | Q11 | `04 §3.2.1` content_sha256 规范化规则（新增小节） | draft 内原地 | A |
| R10 | Q13 | `04 §3.2.2` 为何 snapshot 不需要 depends_on（新增小节） | draft 内原地 | A |
| R11 | Q14 | `04 §2.2` event_id 预留契约（补段） | draft 内原地 | A |
| R12 | Q8 | `03 §3.3.1` 原子写入契约（新增小节） | draft 原地修订 | B |
| R13 | Q9 | `03 §3.1/§3.2` stage 事件加 `related_taskdag_urn?` | draft 原地修订 | B |
| R14 | Q12 | `01 §7.2` 存储位置表按 scope_kind 五类细分 | @v1.1→@v1.2 | B |
| R15 | Q13 联动 | `02 §5.3.1` snapshot 特化查询（lineage） | @v1.1→@v1.2 | B |
| R16 | Q14 联动 | `02 §4.3.1` snapshot 走预留流程 | @v1.1→@v1.2 | B |

**理由**：
1. 路径 A 先消化保证 04 draft 形态稳定，路径 B 可由稳定的 04 驱动
2. 路径 B 完成后 04 仅需反向对接锚点（schema 骨架不变），不需要结构性重写
3. 本 Step 4 的 published 事件同时承载"M4 milestone 收官"与"kernel 跨篇双向可追溯建立"

**正式入档位置**：`04-version-snapshot.md §10 rev_history` + `m4-snapshot-draft-review.md §4.3/§5/§6` + `m4-snapshot-kernel-alignment-proposal.md`。

---

## 2. 快照产出清单

| 文件 | 本快照对应的 rev / status |
|------|-------------------------|
| `04-version-snapshot.md` | **v1.1 / published**（M4 milestone 核心产出） |
| `03-layered-architecture.md` | v1 / draft（M1 review 周期内，按 `01 §10.1` 原地修订；R12/R13 已落地） |
| `01-identity-model.md` | v1.2 / published（R14 落地） |
| `02-artifact-model.md` | v1.2 / published（R15/R16 落地） |
| `07-extensibility.md` | v1.1 / published（本次 M4 未改动，沿用 M2 路径 A 状态） |
| `scenario-wordlist.md` | v1 / draft（本次 M4 未改动） |

### 2.1 三份 kernel review artifact（本 milestone 周期配套产出）

| 文件 | URN | 状态 |
|------|-----|------|
| `_review/m4-snapshot-draft-review.md` | `urn:piao:artifact:kernel:m4_snapshot_draft_review@v1` | published（路径 A §5 + 路径 B §6 双过程记录） |
| `_review/m4-snapshot-kernel-alignment-proposal.md` | `urn:piao:proposal:kernel:m4_snapshot_kernel_alignment@v1` | published（R12–R16 打包处置） |
| `_review/m4-final-decisions.md` | `urn:piao:snapshot:kernel:m4_final_decisions@v1` | **published（本快照）** |

---

## 3. 引用方式

其他文档引用本快照时使用：

```
见 M4 最终决议快照：
urn:piao:snapshot:kernel:m4_final_decisions@v1
（docs/piao-pipeline/kernel/_review/m4-final-decisions.md）
```

---

## 4. 下一步（M5 Drift 入口检查清单）

本快照**不规定** M5 做什么，但记录 M5 入口前应确认的状态：

- [x] `04 §5 snapshot_diff 算子契约` 已 published（为 M5 drift 算法提供基础算子）
- [x] `04 §3.2.1 content_sha256 canonical YAML 规范化规则` 已 published（保证 drift 算子可重复性）
- [x] `04 §3.3 scope_kind 五类封板` 已 published（限定 drift 对比的边界语义）
- [ ] `scripts/snapshot-produce.sh` + `scripts/snapshot-diff.sh` 骨架（M4 工具链侧，M5 启动前落地）
- [ ] M5 启动 proposal（`urn:piao:proposal:kernel:m5_drift_kickoff@v1`）——规划 drift 传播算法与 evolution 接口
- [ ] kernel 05-drift-propagation.md 首版 draft 起稿

**非目标**（M5 不做）：
- snapshot GC / 归档策略（M7 之后）
- drift 的 UI 可视化层（工具链侧，非 kernel）

---

## 5. M4 milestone 成色自评

- **四问回答**：✅ 充分（决议 1–4 各对应一个必答问题）
- **跨篇一致性**：✅ 已闭环（决议 5 · R8–R16 九条全部 consumed，03/01/02/04 四篇文档锚点双向可追溯）
- **债务登记完整性**：✅ `M1-debt-ledger §1.2` Q8–Q14 将在本 milestone 收尾同步登记并 consumed（见 @v5 升版）
- **配套 review 产出**：✅ draft-review / kernel-alignment-proposal / final-decisions 三件套齐备
- **wordcheck**：✅ 04 @v1.1 published 与基线一致（6 BAN + 5 WARN 遗留，与 M4 无关）

---

**快照状态**：published（M4 review 终点的冻结照片）
**上游**：
- `urn:piao:snapshot:kernel:m1_final_decisions@v1`（M1 基线）
- `urn:piao:artifact:kernel:m4_snapshot_draft_review@v1`（M4 review 过程记录）
- `urn:piao:proposal:kernel:m4_snapshot_kernel_alignment@v1`（路径 B 提案）
- `urn:piao:proposal:kernel:post_m1_kickoff@v1`（M4 milestone 触发源，将在本 milestone 收尾同步标 superseded）

**下游锚点**：
- 本快照是任何引用 "M4 review 决议" / "snapshot 模型最终形态" 的文档的正式 URN 目标
- `M1-debt-ledger @v5` 将 Q8–Q14 对齐到本快照
- `post-m1-kickoff @v1` 将标 `superseded_by: urn:piao:snapshot:kernel:m4_final_decisions@v1`
- M5 drift 层文档（`05-drift-propagation.md` 待起稿）将以本快照为基线
