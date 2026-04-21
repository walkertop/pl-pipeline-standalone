---
urn: urn:piao:snapshot:kernel:m5_final_decisions@v1
kind: snapshot
artifact_type: snapshot
rev: v1
status: published
produced_by:
  actor: m5-review-2026-04-19
  task_urn: urn:piao:task:m5:drift_milestone_closeout
  trigger_event_type: stage.exited
supersedes: null
upstream:
  - urn:piao:snapshot:kernel:m4_final_decisions@v1
  - urn:piao:spec:architecture:drift_propagation@v1.1
  - urn:piao:artifact:kernel:m5_drift_draft_review@v1
  - urn:piao:artifact:kernel:m4_toolchain_review@v1
  - urn:piao:proposal:kernel:m5_drift_kernel_alignment@v1
  - urn:piao:proposal:kernel:m5_drift_kickoff@v1
wordcheck_exempt: true
---

# M5 Final Decisions · Kernel Drift 传播模型收敛快照

> 本文档是 **M5 review（2026-04-19）** 的最终决议快照，对标 `M4-final-decisions.md` 范式。
> 定位：作为 `05-drift-propagation.md @v1.1 draft → @v1.1 published` 的"发布证书"与后续 M6 Evolution 层的基线引用目标。
> 快照即事实：本文件**一经产出不再修改**；若未来推翻某条决议，新开 `m5_final_decisions@v2` 并在 v1 中标注 `superseded_by`。

---

## 0. 快照覆盖范围

- **受管文档**：
  - `docs/piao-pipeline/kernel/05-drift-propagation.md`（本次 milestone 的核心产出）
  - `docs/piao-pipeline/kernel/04-version-snapshot.md`（因路径 B 承接 R21/R24 升 @v1.2）
  - `docs/piao-pipeline/kernel/03-layered-architecture.md`（因路径 B 承接 R22 原地修订）
  - `docs/piao-pipeline/kernel/02-artifact-model.md`（因路径 B 承接 R23/R25 升 @v1.3）
- **受管工具链**：
  - `scripts/piao-drift-compute.sh`（本次 milestone 的阶段 α 核心产出 · 555 行 · bash + python3）
- **决议时间窗**：2026-04-19 02:40（`m5_drift_kickoff@v1` published 起稿）至 2026-04-19 14:54（`piao-drift-compute.sh` MVP 端到端 4 场景冒烟通过）
- **依据**：
  - `_review/m5-drift-kickoff.md @v1`（M4→M5 过渡 proposal · supersedes `post-m1-kickoff@v1`）
  - `_review/m4-toolchain-review.md @v1`（阶段 α 退出门 · TB1–TB5 工具链证据驱动）
  - `_review/m5-drift-draft-review.md @v1`（阶段 β 工作流 D 退出门 · §5 路径 A/B 消化记录追补）
  - `_review/m5-drift-kernel-alignment-proposal.md @v1`（路径 B 的 proposal 承载 · R21–R25 打包处置）

---

## 1. 五项最终决议

M5 milestone 要回答 `m5_drift_kickoff @v1 §4` 锁定的**五个必答问题**（Q5.1–Q5.5）；下表以决议形式正式入档，补第六条为跨篇一致性维护结论。

### 决议 1 — drift 的身份（Q5.1）：kind=drift + artifact_type=drift.propagation_record

**问题**：drift 本身是 artifact 吗？若是，artifact_type 叫什么？

**决议**：**drift 是 artifact**，沿用 `01 §2.1` kind 封板（`drift` 是核心 kind 之一，不新增）；`artifact_type` 定为 **`drift.propagation_record`**，通过 `02 §2.2` 派生类型注册机制落地，自动继承 `wordcheck_policy: machine_generated` → `wordcheck_exempt: true`。

**关键契约**（**R1 硬约束**）：
- drift artifact 的 schema 严格对齐 `02 §1.1` 五要素（URN / kind / rev / status / depends_on）
- drift 不升 rev（`05 §7.1`）—— 输入 snapshot 不可变 → drift 输出由输入决定 → drift 无独立演进需求
- drift 状态机仅两态：`published` / `retracted`（`05 §7.1`）—— 比 snapshot 还简

**正式入档位置**：`05-drift-propagation.md §2` 全章 + `02-artifact-model.md §2.2.4 派生类型注册 schema（v1.3 首次形式化）`。

---

### 决议 2 — drift 的触发（Q5.2）：唯一触发器 snapshot.published + 原子三步

**问题**：drift 算法何时运行？每次 `artifact.published` 后？阶段切换批量？手动？

**决议**：**唯一触发器为 `snapshot.published` 事件**（**R2 硬约束**）。禁止以 `artifact.published` 作触发器（避免事件洪流 · 与 M4 决议 1 的"阶段边界唯一客观触发点"同构）。

**原子三步**（`05 §3.2 T1–T5` · 同 txn 对齐 `03 §3.3.1` N 条通用契约）：
- T3：计算 drift 四差分集（added / removed / sha_changed / unchanged_count）
- T4：写入 drift artifact yaml 文件
- T5：原子写入 `artifact.published(D) + drift.detected` 两条 L1 事件（**N=2** 实例 · `03 §3.3.1` 泛化后的合法子集）

**非触发点**（`05 §3.3`）：`artifact.published`（非 snapshot 类）· `task.finished` · `stage.entered/exited`（这些只能触发 snapshot 产出 · 不触发 drift）· `evolution.scanned` · `drift.detected` 自身（禁 drift-of-drift）。

**drift_kind 三枚举封板**（`05 §3.5`）：`initial_snapshot` / `content_drift` / `no_change_drift` —— 让消费方可预判 body 形态。

**正式入档位置**：`05-drift-propagation.md §3` 全章 + `03-layered-architecture.md §3.3.1 原子写入契约（draft 原地泛化为 N 条同 txn）`。

---

### 决议 3 — drift 的 scope（Q5.3）：同 scope_kind + 同 scope_ref 硬约束

**问题**：drift 对比的"两张 snapshot"如何选？邻接两次？同 scope_kind 最近两次？调用方指定？

**决议**：**两张 snapshot 必须同 scope_kind + 同 scope_ref**（**R3 硬约束**）· 直接继承 `04 §5.3` 跨 scope_kind diff 拒绝契约，不引入新 scope 维度。

**邻接语义**（`05 §4.2`）：按 `published_at` 降序 + URN 字典序打破平局 —— 可被第三方独立重算（符合 `04 §2.4` 客观性）。

**拒绝变体清单**（`05 §4.4` · 四类诱惑一网打尽）：
- 跨 scope 联合（如 unit × stage 聚合）—— 拒绝
- 滚动窗口（最近 N 次 snapshot 平均）—— 拒绝
- 时间切片（按小时/天聚合）—— 拒绝
- drift of drift（drift 的 drift）—— 拒绝

**工具链侧反证**（`piao-drift-compute.sh` **SMOKE 4**）：用 kernel scope 与 unit scope 两张 snapshot 输入，退出码 1 · 错误信息引用 `05 §4.1 R3` · 契约落地可执行 ✅

**正式入档位置**：`05-drift-propagation.md §4` 全章。

---

### 决议 4 — drift 的归因（Q5.4）：双模式 + 降级透明暴露

**问题**：如何把"A 的 sha 变了"追溯到"B 事件触发的"？

**决议**：**双模式 `attribution_mode` ∈ {`full`, `sha_only`}**（**R4 硬约束**）· **无 event-journal 或 producer_event_id 占位时强制降级 `sha_only` · 降级必须在 artifact 内写明 `reason`**（`05 §5.2` 禁止隐式降级）。

**归因算法 O(N·K) 链条**（`05 §5.3`）：
1. `02 §4.1` provenance 正向：从 snapshot.frozen_artifacts 读 producer_event_id
2. `01 §5` event_id 唯一性：按 event_id 在 event-journal 中反查事件
3. `03 §3.1` 双轨原则：从事件的 `subject` / 语义字段还原"谁在哪个 task 触发"

**反模式清单**（`05 §5.4` · 三类文件系统式猜测全拒绝）：
- mtime 猜测 —— 拒绝
- git blame 猜测 —— 拒绝
- 时间邻接猜测 —— 拒绝

**工具链侧反证**（`piao-drift-compute.sh` **SMOKE 1**）：因 MVP 阶段 producer_event_id 为占位符 `task-unknown-000000-000000`（`m4-toolchain-review §2.3 T3` 教训登记），降级触发 · `attribution_mode.value=sha_only` + `reason="placeholder producer_event_id detected in new_snapshot urn=..."` —— R4 硬约束的工具链侧直接实施 ✅

**正式入档位置**：`05-drift-propagation.md §5` 全章。

---

### 决议 5 — drift → evolution 接口（Q5.5）：双通道 + 双 producer_event_id

**问题**：drift 应输出什么 schema 让 M6 evolution O(1) 决策？

**决议**：**双通道 + 双 producer_event_id**（**R5 硬约束**）：
- **事件流通道**（O(1)）：`drift.detected` L1 事件 · 11 必填字段（其中 `subject` = drift artifact URN · `evidence` = 两张 snapshot URN · `drifting_artifact_urn` 字段在 R18 已删除以消除 alias 冗余）
- **artifact 拉取通道**（O(N)）：drift artifact yaml body 四集合 · 供 M6 调度器"先筛后拉"（见事件定位 → 拉 artifact 取细节）

**双 event_id 前缀规约**（**R19** · `05 §6.2` + §2.3 schema）：
- drift artifact 的 `produced_by.event_id` 前缀 = `snap-published-*`（drift artifact 是 snapshot.published 驱动下的 artifact.published 派生）
- `drift.detected.event_id` 前缀 = `drift-detected-*`（另一条独立 L1 事件）
- 两者通过前缀明确区分，避免共享裸 `drift-*` 前缀

**M6 前置契约 C1–C4**（`05 §6.4` · 给 M6 留清晰起稿空间）：
- C1 · M6 不得反向写入 drift artifact
- C2 · M6 不得自行补归因（必须走 05 §5.3 provenance 链）
- C3 · M6 必须走 `02 §5.3.1 kind=drift` 特化查 depends_on
- C4 · M6 不得修改 drift 的 status

**工具链侧反证**（`piao-drift-compute.sh`）：produced_by.event_id 前缀 `snap-published-*` 在所有 4 场景产出的 drift artifact 中均正确 ✅

**正式入档位置**：`05-drift-propagation.md §6` 全章。

---

### 决议 6 — 跨篇一致性：路径 A + 路径 B 全量对接（与 M4 同模式）

**问题**：05 draft 完成后，review 识别到的 Q15–Q20 六条缺口（其中 4 条需外篇升降），如何与 05 draft→published 协调？

**决议**：**采用"先 A 后 B 再反向对接"七步执行序**（与 M4 五步序同构 · 因 M5 增加 S0 预检 + 阶段 α 工具链独立步 + S5 跟随升版），分别在 `m5-drift-draft-review @v1 §4.3` 与 `m5-drift-kernel-alignment-proposal @v1 §3` 锁定。

**七步执行序**（全部已完成）：

| Step | 动作 | 结果 | 产出 URN / commit |
|------|------|------|-------------------|
| 1 | 路径 A：R17–R20 在 05 draft 内原地消化（不升 rev） | ✅ | `05 @v1 (draft · 路径 A 原地消化 · 2026-04-19 14:10)` |
| 2 | 路径 B proposal self-review + published | ✅ | `m5_drift_kernel_alignment@v1 published` · commit `78134de8` |
| 3 | 路径 B · S1：03 §3.3.1 draft 原地泛化（R22） | ✅ | `03 draft 原地修订` · commit `49608733` |
| 4 | 路径 B · S2：04 @v1.1 → @v1.2（R21 + R24 合并） | ✅ | `04 @v1.2 published` · commit `c3b8fe82` |
| 5 | 路径 B · S3：02 @v1.2 → @v1.3（R23 + R25 合并） | ✅ | `02 @v1.3 published` · commit `f25dc403` |
| 6 | 反向对接：05 @v1 draft → @v1.1 draft（六处锚点注释同步 · 仍 draft） | ✅ | `05 @v1.1 draft` · commit `d6ee71ac` |
| 7 | S6+S7：`m5-drift-draft-review @v1 §5` 路径 A/B 消化记录追补 + 05 §9 Q1/Q5 consumed 注释 | ✅ | commit `c0991418` |
| 8 | **本步**：阶段 α 工具链 · `piao-drift-compute.sh` MVP 首版 + 四场景冒烟（自反 + initial + no_change + content + cross-scope 拒绝） | ✅ | commit `bcc56229` · 2026-04-19 14:54 |
| 9 | **本步**：`m5-final-decisions@v1` 产出（本快照） + 05 @v1.1 draft → @v1.1 published（待后续 commit） | 🚧（当前） | `m5_final_decisions@v1 published` |

**R17–R25 九条修订的最终落地矩阵**：

| 修订 | 源自 | 目标 | 落地 rev | 路径 | commit |
|-----|-----|------|---------|-----|-------|
| R17 | Q15 | `05 §2.5` 改为正向白名单六字段 | draft 内原地 | A | 阶段 β draft 起稿内 |
| R18 | Q16 | `05 §6.2` 删除 `drifting_artifact_urn` 字段（消除 alias 冗余） | draft 内原地 | A | 阶段 β draft 起稿内 |
| R19 | Q17 | `05 §6.2 + §2.3 + §9 Q3` 双前缀规约（`snap-published-*` / `drift-detected-*`） | draft 内原地 | A | 阶段 β draft 起稿内 |
| R20 | Q19 | `05 §7.1 脚注 + §7.3` 默认不回溯作废，`retroactive_invalidation: true` 才触发批量 retracted | draft 内原地 | A | 阶段 β draft 起稿内 |
| R21 | Q15 + `m4-toolchain-review §2.5 T5`（合并） | `04 §3.2.3` canonical YAML 通用工具契约（三承诺） | @v1.1→@v1.2 | B | `c3b8fe82` |
| R22 | Q18 | `03 §3.3.1` 泛化为 N 条 L1 事件同 txn（N≥1 · 无 type 约束） | draft 原地修订 | B | `49608733` |
| R23 | Q20 | `02 §5.3.1` 扩为通用 lineage 特化注册表（kind=snapshot + kind=drift 两条） | @v1.2→@v1.3 | B | `f25dc403` |
| R24 | 05 §9 Q1 联动 | `04 §5.1` `sha_changed` 作为 `modified` 的 alias（双名兼容） | 同 @v1.2 合并 | B | `c3b8fe82` |
| R25 | 05 §9 Q5 联动 | `02 §2.2.4` 派生类型注册补 `wordcheck_policy` 字段（七字段 schema 形式化） | 同 @v1.3 合并 | B | `f25dc403` |

**理由**：
1. 路径 A 先消化（R17–R20）保证 05 draft 形态稳定，路径 B 可由稳定的 05 驱动
2. 路径 B 完成后 05 仅需反向对接锚点（§2.5 / §8.1 / §9 / §10 四处），不需要结构性重写
3. 阶段 α 工具链作为独立 Step 8，让 `piao-drift-compute.sh` MVP 可在路径 A/B 全部消化后以 @v1.1 draft 为完整契约依据落地 —— 实施过程不产生新 kernel 缺口（符合 `05 §8.2` 门控 #3 "R1–R5 未被反例证伪" 条件）

**正式入档位置**：`05-drift-propagation.md §8.1 rev_history` + `m5-drift-draft-review @v1 §5` + `m5-drift-kernel-alignment-proposal @v1 §3`。

---

## 2. 快照产出清单

| 文件 | 本快照对应的 rev / status |
|------|-------------------------|
| `05-drift-propagation.md` | **v1.1 / published**（M5 milestone 核心产出 · 通过 §8.2 四门控） |
| `04-version-snapshot.md` | v1.2 / published（R21 + R24 落地） |
| `03-layered-architecture.md` | v1 / draft（M1 review 周期内 · R22 原地修订 · 按 `01 §10.1` 合规） |
| `02-artifact-model.md` | v1.3 / published（R23 + R25 落地） |
| `01-identity-model.md` | v1.2 / published（本次 M5 未改动，沿用 M4 状态） |
| `07-extensibility.md` | v1.1 / published（本次 M5 未改动） |
| `scenario-wordlist.md` | v1 / draft（本次 M5 未改动） |

### 2.1 三份 kernel review artifact（本 milestone 周期配套产出）

| 文件 | URN | 状态 |
|------|-----|------|
| `_review/m5-drift-kickoff.md` | `urn:piao:proposal:kernel:m5_drift_kickoff@v1` | published（M4→M5 过渡 proposal · supersedes `post-m1-kickoff@v1` · 本快照产出后进入 `superseded` 状态） |
| `_review/m4-toolchain-review.md` | `urn:piao:artifact:kernel:m4_toolchain_review@v1` | published（阶段 α 退出门 · TB1–TB5 工具链证据） |
| `_review/m5-drift-draft-review.md` | `urn:piao:artifact:kernel:m5_drift_draft_review@v1` | draft（阶段 β 工作流 D 退出门 · §5 路径 A/B 消化记录已追补 · 本快照产出后可升 published） |
| `_review/m5-drift-kernel-alignment-proposal.md` | `urn:piao:proposal:kernel:m5_drift_kernel_alignment@v1` | published（R21–R25 打包处置） |
| `_review/m5-final-decisions.md` | `urn:piao:snapshot:kernel:m5_final_decisions@v1` | **published（本快照）** |

### 2.2 工具链产出（阶段 α 核心）

| 脚本 | 行数 | 实现契约 | commit |
|------|-----|---------|-------|
| `scripts/piao-drift-compute.sh` | 555 | 05 §2.1/§2.3/§2.5/§3.5/§4.1/§5.1/§5.2 + 04 §3.2.1/§3.2.3/§5.3 + 02 §2.2.4 | `bcc56229` |

**端到端冒烟证据**（2026-04-19 14:54 · 4 场景全通）：

| # | 场景 | drift_kind | attribution_mode | 差分集合 | content_sha256 |
|---|------|-----------|-----------------|---------|---------------|
| 1 | content_drift（pre_m5 4 件 → post_m5 5 件） | content_drift | sha_only | added=3 / removed=2 / sha_changed=0 / unchanged=2 | `2601de6c...` ✅ 幂等 |
| 2 | initial_snapshot（仅 --new-snapshot） | initial_snapshot | sha_only | 四字段全零 | `1126a39f...` |
| 3 | no_change_drift（同一 snapshot 自比） | no_change_drift | sha_only | unchanged=4 | `da03ff6d...` |
| 4 | cross-scope 拒绝（kernel vs unit） | — | — | — | 退出码 1 + 错误引用 `05 §4.1 R3` |

**SHA 独立性验证**：SMOKE 2（initial）与 SMOKE 3（no_change）虽然都是"空 drift"但 `diff_base.old_snapshot_urn` 不同（initial 空串 / no_change 等于 new），故 content_sha256 不同 —— 契约正确反映了"正向白名单六字段参与计算"。

---

## 3. 引用方式

其他文档引用本快照时使用：

```
见 M5 最终决议快照：
urn:piao:snapshot:kernel:m5_final_decisions@v1
（docs/piao-pipeline/kernel/_review/m5-final-decisions.md）
```

---

## 4. 下一步（M6 Evolution 入口检查清单）

本快照**不规定** M6 做什么，但记录 M6 入口前应确认的状态：

- [x] `05 §2.5 content_sha256 canonical YAML 规范化` 已 published（SHA_WHITELIST 六字段 · 复用 `04 §3.2.3` 通用工具契约）
- [x] `05 §3.5 drift_kind 三枚举封板` 已 published（initial_snapshot / content_drift / no_change_drift）
- [x] `05 §4.1 R3 scope 一致性` 已 published（同 scope_kind + 同 scope_ref · 继承 `04 §5.3`）
- [x] `05 §5 归因双模式` 已 published（full / sha_only · 降级透明暴露）
- [x] `05 §6 drift → evolution 接口` 已 published（双通道 + 双 producer_event_id + C1–C4 M6 前置契约）
- [x] `scripts/piao-drift-compute.sh` MVP 已产出并通过 4 场景冒烟（自反 + initial + no_change + cross-scope 拒绝）
- [ ] `scripts/piao-drift-compute.sh` 扩展：`--full-mode`（真实 event-journal 存在时启用 full 归因模式）/ `--emit-events`（原子写入 `artifact.published(D) + drift.detected` 两条 L1 事件 · 对标 `03 §3.3.1` N=2 契约）· **M6 阶段 α 前置**
- [ ] M6 启动 proposal（`urn:piao:proposal:kernel:m6_evolution_kickoff@v1`）—— 规划 evolution 扫描算法与 `drift.detected → evolution.scanned` 接口
- [ ] kernel `06-evolution-model.md` 首版 draft 起稿

**非目标**（M6 不做）：
- drift GC / 归档策略（M7 之后）
- drift 的 UI 可视化层（工具链侧 · 非 kernel）
- evolution 的实施层（扫描器算子本身 · 工具链侧）

---

## 5. M5 milestone 成色自评

- **五问回答**：✅ 充分（决议 1–5 各对应一个必答问题 · R1–R5 五条硬约束证据完备、落位清晰、相互不冲突 · 见 `m5-drift-draft-review §1.3`）
- **kernel 锚点 20 条全部存在**：✅ 已闭环（`m5-drift-draft-review §1.2` 20 条逐条校验 · 三条引用姿势 Q15/Q16/Q18 通过 R17–R22 九条修订全部补齐）
- **跨篇一致性**：✅ 已闭环（决议 6 · R17–R25 九条全部 consumed · 05/04/03/02 四篇文档锚点双向可追溯 · 四个前置锚点钩子全部反向对接 · 见 `m5-drift-draft-review §5.5`）
- **工具链侧反证**：✅ 完备（`piao-drift-compute.sh` 四场景冒烟分别反证 R3 / R4 / R19 三条硬约束 + drift_kind 三枚举 + SHA_WHITELIST 幂等 · R1 通过 02 §2.2.4 schema + R2/R5 通过 05 §3/§6 契约形式化保证，**未被实施反例证伪**）
- **配套 review 产出**：✅ 四件套齐备（kickoff / toolchain-review / draft-review / kernel-alignment-proposal / final-decisions · 比 M4 三件套多 toolchain + kernel-alignment 两件 · 反映"工具链→规格起稿→规格 review→规格 published→工具链实装→终态封冻"双循环闭环）
- **债务登记完整性**：⚠️ `M1-debt-ledger @v5 → @v6` 待同步登记 Q15–Q20 六条 + R17–R25 九条 consumed 证据（见 §2 下一步候选 ④ · 不阻塞本快照 published · 对标 M4 `@v4 → @v5` 范式节奏）
- **wordcheck**：✅ 05 @v1.1 draft + 04/02/03 升版与基线一致（6 BAN + 5 WARN 遗留 · 均在 02 既有条款 · 与 M5 无关 · 见 `m5-drift-draft-review §5.8`）

---

## 6. `m5_drift_kickoff @v1` 生命周期闭合

按 `m5_drift_kickoff @v1 §6` 关闭条件：
- ✅ 工作流 T（阶段 α · M4 工具链补齐）· `piao-snapshot-produce.sh` + `piao-snapshot-diff.sh` + `m4-toolchain-review` 三件已产出（见 `10.1 阶段 α 退出点追补 · 2026-04-19 03:30`）
- ✅ 工作流 D（阶段 β · M5 Drift 规格起稿）· `05-drift-propagation.md @v1 → @v1.1` draft 首版 + `m5-drift-draft-review` 阶段 β 退出门产出
- ✅ M5 milestone 收官 · 本快照产出

**状态转换**：`m5_drift_kickoff @v1 status: published → superseded`（本快照 `urn:piao:snapshot:kernel:m5_final_decisions@v1` 承接 · 与 `post-m1-kickoff @v1 superseded_by: m4_final_decisions@v1` 对称范式）。

**双向可追溯**：本快照 §2.1 已登记 `m5_drift_kickoff @v1 → superseded` · `m5_drift_kickoff @v1` 自身的 status 字段变更由配套 commit 追加（`01 §10.1` published 文档不升 rev 原则 · 仅改 status 合规 · 参考 `post-m1-kickoff @v1` 先例）。

---

## 7. `05-drift-propagation.md @v1.1 draft → @v1.1 published` 门控复核

按 `05 §8.2` 四门控：

| 门控 | 当前状态 | 证据 |
|------|---------|-----|
| #1 · `_review/m5-drift-draft-review.md` 产出 + 锚点完整性校验 | ✅ 达成 | `m5-drift-draft-review @v1 §1.2` 20 条锚点逐条校验 · commit `313445df` + `c0991418`（§5 追补） |
| #2 · 至少一条真实 drift artifact 产出验证 schema 可实施 | ✅ 达成 | `piao-drift-compute.sh` 4 场景冒烟产出 4 条 drift artifact yaml · commit `bcc56229` |
| #3 · R1–R5 五条硬约束未被实施反例证伪 | ✅ 达成 | MVP 实施过程零新发现契约歧义 · 本快照 §5 工具链侧反证完备 |
| #4 · `_review/m5-final-decisions.md` 产出 | ✅ **本快照达成** | 当前文档 |

**定性结论**：四门控全部满足，`05-drift-propagation.md @v1.1 draft → @v1.1 published` 的升版条件成立。该升版由承接本快照的下一 commit 执行（front-matter `status: draft → status: published` + `§8.1 rev_history` 追加一行），不进入本快照管辖范围。

---

**快照状态**：published（M5 review 终点的冻结照片）

**上游**：
- `urn:piao:snapshot:kernel:m4_final_decisions@v1`（M4 基线）
- `urn:piao:spec:architecture:drift_propagation@v1.1 (draft)`（05 阶段 β 主产出 · 本快照产出后升 published）
- `urn:piao:artifact:kernel:m5_drift_draft_review@v1 (draft)`（阶段 β 工作流 D 退出门 · §5 路径 A/B 消化记录已追补 · 本快照产出后可升 published）
- `urn:piao:artifact:kernel:m4_toolchain_review@v1 (published)`（阶段 α 退出门 · TB1–TB5 驱动 R1–R5 成形）
- `urn:piao:proposal:kernel:m5_drift_kernel_alignment@v1 (published)`（路径 B proposal · R21–R25 打包处置）
- `urn:piao:proposal:kernel:m5_drift_kickoff@v1 (published → superseded by 本快照)`（M5 工作编排）

**下游锚点**：
- 本快照是任何引用 "M5 review 决议" / "drift 传播模型最终形态" 的文档的正式 URN 目标
- `M1-debt-ledger @v6`（待产出）· 将 Q15–Q20 + R17–R25 对齐到本快照
- `m5_drift_kickoff @v1` 将标 `superseded_by: urn:piao:snapshot:kernel:m5_final_decisions@v1`
- M6 evolution 层文档（`06-evolution-model.md` 待起稿）将以本快照为基线
- M6 工具链（`piao-evolution-scan.sh` 待起稿）将复用 `04 §3.2.3` canonical 工具 + `05 §6` drift.detected 事件流
