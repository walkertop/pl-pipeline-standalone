---
urn: urn:piao:spec:architecture:drift_propagation@v1
kind: spec
rev: v1.1
status: published
supersedes: null
produced_by: m5-drift-kickoff-stage-beta-2026-04-19
produced_at: 2026-04-19T02:10:00+08:00
last_modified_at: 2026-04-19T15:40:00+08:00
upstream:
  - urn:piao:snapshot:kernel:m4_final_decisions@v1
  - urn:piao:snapshot:kernel:m5_final_decisions@v1
  - urn:piao:spec:architecture:version_snapshot@v1.2
  - urn:piao:spec:architecture:layered_architecture@v1
  - urn:piao:spec:architecture:artifact_model@v1.3
  - urn:piao:spec:architecture:identity_model@v1.2
  - urn:piao:proposal:kernel:m5_drift_kickoff@v1
  - urn:piao:artifact:kernel:m4_toolchain_review@v1
  - urn:piao:artifact:kernel:m5_drift_draft_review@v1
  - urn:piao:proposal:kernel:m5_drift_kernel_alignment@v1
wordcheck_exempt: true
---

# kernel · 05 Drift Propagation Model（M5 · 首版 @v1.1 published）

> **@v1.1 published 定稿说明**（2026-04-19 15:40）
>
> 本篇由 `m5_drift_kickoff@v1 §2.3` **分支 β-2** 触发（条件：`m4-toolchain-review@v1` 发现 ≤ 2 条 04 契约小歧义），从 @v0.2 骨架升为首版 draft · 经 M5 milestone review 周期（路径 A 原地追述 + 路径 B 跟随升版 + 工具链 MVP 反证 + final-decisions 门控复核）后封为 published。
>
> **升版全路径**：`@v0.2 draft`（骨架 · 仅大纲）→ `@v1 draft`（首版 · §2/§3/§4/§5/§6/§7 正文起稿）→ `@v1 draft · 路径 A 原地追述（14:10）`→ `@v1.1 draft · 路径 B 跟随升版（14:45）`→ **`@v1.1 published`（定稿 · 15:40）**。@v0.1/@v0.2 阶段的骨架被**无缝替换**（无 supersedes 关系，因为骨架本身是 draft，不是 published 快照）· v1 → v1.1 内部小升同样无 supersedes（按 `01 §10.1` draft 契约）· `@v1.1 draft → @v1.1 published` 无 supersedes（同 rev 内部状态转换 · 不升 rev）。
>
> **@v1.1 published 封版前提**（`§8.2` 四条门控全部达成 · 由 `m5-final-decisions@v1` 复核确认）：
> - #1 ✅ `_review/m5-drift-draft-review.md @v1 published`（kernel 锚点 20 条 100% 存在 · 五问 R1–R5 五硬约束证据完备 · 路径 A/B 裁定全产出）
> - #2 ✅ `scripts/piao-drift-compute.sh` MVP 工具链产出（555 行 · 阶段 α 四场景冒烟全通：content_drift / initial_snapshot / no_change_drift / cross-scope 拒绝 · commit `bcc56229`）
> - #3 ✅ R1–R5 五硬约束在 MVP 实施中**未被反例证伪**（schema / 触发器 / scope / 归因降级 / 双 producer_event_id 全反证通过）
> - #4 ✅ `_review/m5-final-decisions.md @v1 published`（决议 1–6 矩阵 + 九 commit 证据链 + kickoff 生命周期闭合 · commit `b8f877f9`）
>
> **强约束输入**（不可绕过 · published 后转为 kernel 层硬契约）：
> - `m5_drift_kickoff @v1 §4`：Q5.1–Q5.5 五个必答问题（全部 consumed · 见 §1）
> - `m4-toolchain-review @v1 §3`：TB1–TB5 工具链视角建议（TB1 归因降级路径 → R4 · TB2 snapshot.published 触发 → R2 · TB3 scope 继承 → R3 · TB4 双 producer_event_id → R5）
> - `04 §5.1 snapshot_diff` 算子字段契约（`added` / `removed` / `modified` / `unchanged_count` · `sha_changed` alias @v1.2 起）
>
> **阅读路径**：
> 1. 先读 `04-version-snapshot.md @v1.2 §3.2.3 + §5`（drift 的直接上游契约 + canonical YAML 通用工具 + snapshot_diff 双名）
> 2. 再读 `02-artifact-model.md @v1.3 §5.3.1 + §2.2.4`（lineage 特化注册表 + 派生类型注册 schema · drift 两条反向对接均在此）
> 3. 再读 `_review/m4-toolchain-review.md @v1 §3`（TB1–TB5 理解本篇设计取舍的由来）
> 4. 再读本篇 §2–§6（核心 5 问的答复 · 即 kernel 层 drift 最终契约）
> 5. 最后读 §7（生命周期）/ §8（验收标准 · published 达成记录）/ §9（开放问题 · Q1–Q5 全部已 consumed · 保留作历史追溯）
> 6. 收官快照 `_review/m5-final-decisions.md @v1`（六大决议矩阵 + 九 commit 证据链）

---

## 0. 定位

M1（身份）回答"实体叫什么"，M2（artifact）回答"实体长什么样"，M3（事件分层）回答"实体之间怎么流动"，M4（snapshot）回答"怎么把流动封冻成 O(N) 可对比的照片"。

**M5 回答：两张照片之间的差，如何被解释、归因、传播。**

drift 不是"snapshot 的高级 diff"——`04 §5 snapshot_diff` 算子已经给出字节级差分能力（`added` / `removed` / `modified` / `unchanged_count` 四集合输出）。drift 是**在差分之上**的**语义层**：

- **归因**：某 artifact 的 sha 变了，是谁驱动的？（某次 task？某条 rule 升版？某个 adapter 升 rev？）
- **传播**：一条差分如何向下游（依赖它的其他 artifact / adapter / rule）传递？是立即打破还是容忍？
- **消化**：传播到终点的差分，如何转化为新的 `task.*` 或 `proposal` 事件让系统"接住"它？

### 0.1 设计取舍总览（强约束先行）

| # | 设计决策 | 来源 | 对应 kickoff 必答问题 |
|---|---------|------|--------------------|
| R1 | drift 本身是 artifact（`kind=drift` · `artifact_type=drift.propagation_record`） | 本篇 §2 · `01 §2.1 kind 枚举` 已含 drift | Q5.1 |
| R2 | drift 的**唯一触发器**是 `snapshot.published`（不是 `artifact.published`） | `m4-toolchain-review §3.2 TB2` · 本篇 §3 | Q5.2 |
| R3 | drift 的两个输入 snapshot **必须同 scope_kind + 同 scope_ref** | `04 §5.3` · `m4-toolchain-review §3.3 TB3` · 本篇 §4 | Q5.3 |
| R4 | 归因**强依赖** event-journal；无 event-journal 时 drift 只输出 `sha_changed` 集合，**不承诺归因**（降级透明暴露） | `m4-toolchain-review §3.1 TB1 选项 ①` · 本篇 §5 | Q5.4 |
| R5 | drift→evolution 接口携带 `old_producer_event_id` + `new_producer_event_id` 双字段 | `m4-toolchain-review §3.4 TB4` · 本篇 §6 | Q5.5 |

以上 5 条是**本 @v1 draft 的硬约束**，任何细节章节的展开都必须与其兼容；若发现不兼容，优先修章节细节，不修 R1–R5。

---

## 1. M5 必答问题清单（对标 kickoff §4）

| # | 问题 | 本篇答复章节 | 答复摘要 |
|---|------|-----------|---------|
| Q5.1 | drift 的身份（是否 artifact？artifact_type 怎么写？） | §2 | 是 artifact · `artifact_type=drift.propagation_record` |
| Q5.2 | drift 的触发（何时运行？） | §3 | `snapshot.published` 事件触发 · 非 `artifact.published` · 非时间驱动 |
| Q5.3 | drift 的 scope（两张 snapshot 怎么选？） | §4 | 同 scope_kind + 同 scope_ref 下邻接两次 published snapshot |
| Q5.4 | drift 的归因（sha 变了怎么反追到驱动事件？） | §5 | 强依赖 event-journal · `producer_event_id` 反查 · 无 journal 时不承诺归因 |
| Q5.5 | drift → evolution 接口（M6 O(1) 决策的 schema） | §6 | `drift.propagation_record` artifact + `drift.detected` L1 事件双通道 |

---

## 2. drift 的身份与 artifact 形态（回答 Q5.1）

### 2.1 drift 是 artifact

drift 的一次运行结果**是** artifact——具体类型如下：

| 字段 | 取值 | 依据 |
|------|------|------|
| `kind` | `drift` | `01 §2.1 核心 kind 枚举`（drift 已是封板核心 kind） |
| `artifact_type` | `drift.propagation_record` | 本篇新定义；遵循 `02 §2.2 派生类型注册方式`（kernel 层派生，不通过 adapter_type） |
| `scope` | 继承自输入 snapshot 的 `frozen_scope`（见 §4） | `04 §3.3 scope_kind` 对齐 |
| URN 模板 | `urn:piao:drift:<scope>:<name>@<rev>` | `01 §1.1` URN grammar |

### 2.2 为什么必须是 artifact，而不仅是"一过性的运行输出"

- **可追溯性**：drift 作为 artifact 可被 `02 §4 provenance 四元组`记账（`produced_by.task_urn` + `produced_by.event_id` 明确来源）
- **可引用性**：evolution（M6）消费 drift 时通过 URN 引用具体某次 drift 结果，而非某个内存对象
- **可归档性**：`02 §6 生命周期`对 drift 同样适用——drift 产出后进入 `published`，异常情况下可 `retracted`
- **客观性原则**：与 `04 §2.4 触发判定的客观性`同构——drift 的结果必须可被第三方独立重算（给定同两张 snapshot，drift 必产出相同 artifact）

### 2.3 drift artifact 的 schema

front-matter 强制字段（继承 `02 §1.1` 五要素 · 扩展 drift 特化四字段）：

```yaml
urn: urn:piao:drift:<scope>:<name>@<rev>
kind: drift
artifact_type: drift.propagation_record
rev: v<N>
status: draft | published | retracted
produced_by:
  task_urn: urn:piao:task:...                  # 触发本次 drift 计算的 task
  event_id: snap-published-<YYMMDDHHmmss>-<rand6>
                                               # 驱动本次 drift 的 artifact.published(D) 事件 id
                                               # 前缀 `snap-published-*` 与 drift.detected 的
                                               # `drift-detected-*` 明确分离（R19 裁定 · 见 §9 Q3）
# ↑ 以上为 `02 §1.1` 标准五要素

# 以下为 drift 特化字段
diff_base:
  old_snapshot_urn: urn:piao:snapshot:<scope>:<name>@<rev>
  new_snapshot_urn: urn:piao:snapshot:<scope>:<name>@<rev>
scope:                                # 从两张 snapshot 继承，必须一致（见 §4）
  scope_kind: <unit|stage|taskdag|adapter|kernel>
  scope_ref: <URN>
attribution_mode:                     # 见 §5：full | sha_only
  value: <full|sha_only>
  reason: <若 sha_only，说明降级原因，如 "no event journal">
```

body 结构（五元组 propagation_records 列表 · 对标 `04 §3.2` frozen_artifacts 列表的对偶结构）：

```yaml
# §5.1 定义的四集合语义化展开
added:
  - artifact_urn: urn:piao:...
    new_sha256: <hex>
    new_producer_event_id: <event_id>   # sha_only 模式下可为 null
removed:
  - artifact_urn: urn:piao:...
    old_sha256: <hex>
    old_producer_event_id: <event_id>   # sha_only 模式下可为 null
sha_changed:                           # 对齐 kickoff §2.2 命名（= 04 §5.1 的 modified · 见本篇 §9 开放问题 Q1）
  - artifact_urn: urn:piao:...
    old_sha256: <hex>
    new_sha256: <hex>
    old_producer_event_id: <event_id>   # sha_only 模式下可为 null
    new_producer_event_id: <event_id>   # sha_only 模式下可为 null
unchanged_count: <int>                  # 仅记数量，不记明细（对齐 04 §5.1 的体积预算）
```

### 2.4 drift 与 snapshot 的对偶性

| 维度 | snapshot（04） | drift（05） |
|------|---------------|------------|
| 本质 | 某时刻实体状态的**点快照** | 两个点快照之间的**差分快照** |
| URN kind | `snapshot` | `drift` |
| 输入 | scope 下所有 artifact + 事件 | 两张 snapshot |
| body 主体 | `frozen_artifacts` 五元组列表 | `added` / `removed` / `sha_changed` 三列表 + `unchanged_count` |
| 触发 | `stage.exited` 等阶段边界（`04 §2.1`） | `snapshot.published`（本篇 §3） |
| 幂等保证 | canonical YAML + SHA-256（`04 §3.2.1`） | 同样契约（本篇 §2.5） |

### 2.5 drift 的 content_sha256 可重复性（R17 · 2026-04-19 · 正向白名单改写）

drift artifact 的 content_sha256 计算**复用** `04 §3.2.1 canonical YAML 五步规范化`，采用**正向白名单**机制——参与计算的字段**仅**以下六项，任何不在白名单的字段（无论当前存在还是未来新增）均**不**参与 sha 计算：

| # | 字段路径 | 序语 |
|---|---------|------|
| 1 | `diff_base.old_snapshot_urn` | 标量（URN 字符串） |
| 2 | `diff_base.new_snapshot_urn` | 标量（URN 字符串） |
| 3 | `added` | 列表 · 按 `artifact_urn` 字典序排序 |
| 4 | `removed` | 列表 · 按 `artifact_urn` 字典序排序 |
| 5 | `sha_changed` | 列表 · 按 `artifact_urn` 字典序排序 |
| 6 | `unchanged_count` | 标量（整数） |

**工具实施契约**：

```
drift_content_sha256 = sha256( canonical_yaml( pick_fields(drift_body, SHA_WHITELIST) ) )
SHA_WHITELIST = [
    "diff_base.old_snapshot_urn",
    "diff_base.new_snapshot_urn",
    "added",
    "removed",
    "sha_changed",
    "unchanged_count",
]
```

**为什么改用正向白名单**（替代 @v1 初稿的"反向排除清单"机制 · Q15 / R17）：

- **反向排除的风险**：未来若补 `priority` / `labels` 之类新字段而忘记更新排除清单，该字段会意外参与 sha，破坏可重复性（等价于 `m4-toolchain-review §2.5 T5` 发现的 key 正则遗漏教训）
- **正向白名单的安全性**：新字段默认**不参与**，除非显式加入白名单——安全默认（fail-safe）
- **与 04 §3.2.1 对齐**：04 的 canonical YAML 工具链本就是 `pick_fields(front_matter, KEY_ORDER)` 的正向取字段模型，05 沿用同一工具语义，避免在同一 kernel 内出现两套"选字段规则"

**仍然保持不参与 sha 计算的语义**（仅作说明 · 实施靠"不在白名单"自然排除）：

- `produced_by` / `produced_at` / `event_id`：scope 相关元数据 · 每次产出必然不同
- `attribution_mode`：仅影响 `producer_event_id` 字段是否为占位符 · 不应让"有 journal / 无 journal"两次运行产出不同 drift content_sha256
- `scope`：从 `diff_base` 的两 snapshot URN 可间接推出（两 URN 已在白名单） · 单独再计一次属冗余

**等价替身规则**（`02 §5.3.1` snapshot 特化的对偶）：`lineage_query` 访问 drift artifact 时，把 `diff_base.old_snapshot_urn` + `diff_base.new_snapshot_urn` 视为 drift 的**等价 strong `depends_on`**（本对偶规则的 02 侧已反向对接 · 见 `02 §5.3.1 lineage 特化注册表 · kind=drift 条目`（`m5_drift_kernel_alignment@v1 §4.4 / S3` 落地 · 2026-04-19 · 02 @v1.3）· 对应 `m5-drift-draft-review@v1 §2 Q20 → §3.2 R23` 已 consumed）。

**与 `04 §3.2.3 canonical YAML 通用工具契约`的对接**（v1.1 新增 · 2026-04-19 14:45 由 `m5_drift_kernel_alignment@v1 §4.2 / S2` 落地）：本节的 `SHA_WHITELIST` 六字段模式即 `04 §3.2.3 承诺 3`（`SHA_WHITELIST` 声明范式）的**首个复用案例**——drift content_sha256 的计算链路 `sha256( canonical_yaml( pick_fields(drift_body, SHA_WHITELIST) ) )` 与 `04 §3.2.3 承诺 2`（正向白名单 `pick_fields`）字面对齐 · kernel 层通用契约的首次跨篇复用验证。

---

## 3. drift 触发与产出契约（回答 Q5.2）

### 3.1 唯一触发器：`snapshot.published`

**硬约束 R2**：drift 的触发器**必须是** `snapshot.published` 事件（snapshot 作为 artifact 被发布时写入的 `artifact.published` 事件的特化），**不是** `artifact.published`（一般意义的 artifact 发布）。

**工具链证据来源**：`m4-toolchain-review @v1 §3.2 TB2`——

> MVP 实施印证：snapshot 作为 drift 输入的最小必要信息量（URN + sha256 五元组列表）恰好是 snapshot schema 的本体。每次单独 artifact 发布若都触发 drift，会造成 drift 事件洪流（artifact 数 × N 倍于 snapshot 数）。

### 3.2 触发流程（原子三步）

对齐 `04 §2.2 阶段边界 snapshot 的产出契约` 与 `03 §3.3.1 原子写入契约`，drift 的产出流程如下：

```
T0  ← 外部事件：某 scope 下产生新 snapshot S_new
                   ↓
┌─ 同一 txn（03 §3.3.1 承诺 1）──────────────────────────────┐
│  T1  artifact.published(S_new)        ← 标志 S_new 发布    │
│  T2  查询同 scope 下最近的 published snapshot S_old          │
│  T3  调用 snapshot_diff(S_old, S_new) → DiffReport          │
│  T4  构造 drift artifact D（按 §2.3 schema）                 │
│  T5  写入 D 文件 + artifact.published(D) + drift.detected    │
└───────────────────────────────────────────────────────────┘
                   ↓
T6  ← 后续消费：evolution 引擎读 drift.detected 事件 → 拉 D 做决策
```

**关键契约**：

1. **T1–T5 同一 txn**：若 T3 失败（例如两张 snapshot 跨 scope 触发 `04 §5.3` 拒绝），则整个 txn 回滚——S_new 的 `artifact.published` 不会提交（符合 `03 §3.3.1` 承诺 1）
2. **T2 查询语义**：若 scope 下**不存在** `S_old`（S_new 是该 scope 的首张 snapshot），drift 不产出——发一条 `drift.detected` 事件且 body 为空 drift artifact（`added=[]` + `removed=[]` + `sha_changed=[]` + `unchanged_count=0`），同时 `drift_kind=initial_snapshot`（见 §3.5）
3. **T5 双写**：`drift.detected` L1 事件（见 `03 §3.1` 已封板）+ `artifact.published(D)` 两条事件同 txn · `drift.detected.subject = D.urn`（符合 `03 §3.1 双轨原则`）

### 3.3 非触发点（明确不跑 drift）

| 非触发场景 | 理由 |
|----------|------|
| `artifact.published`（非 snapshot 类） | 见 §3.1 R2：会造成事件洪流 |
| `stage.entered` | 阶段进入时 snapshot 尚未产出，无输入 |
| `task.finished` | task 级粒度过细；task 产出的 artifact 若进入某 snapshot，该 snapshot 的 published 会自然触发 drift |
| 时间驱动 / 定时扫描 | 违反 `04 §2.4 客观性原则`——drift 必须由可追溯事件驱动，不能由挂历驱动 |
| `drift.detected`（避免递归） | drift 本身的发布不触发新 drift · 由 T5 同 txn 已完成，无需递归 |

### 3.4 触发判定的客观性

**对齐 `04 §2.4`**：drift 是否被触发完全由 L1 事件流决定——同样的 L1 事件流重放，drift 产出 artifact 集合完全一致（sha256 级幂等）。这是第三方审计 drift 正确性的基础。

### 3.5 `drift.detected` 事件的 `drift_kind` 字段语义

`03 §3.1` 封板的 `drift.detected` 事件含 `drift_kind` 字段，本篇定义如下枚举（kernel 层封板 · 业务层不可扩展）：

| drift_kind | 语义 | 对应 body 形态 |
|-----------|------|--------------|
| `initial_snapshot` | 某 scope 首次产生 snapshot · 无 S_old 可对比 | 空 drift（四字段全零） |
| `content_drift` | S_old / S_new 均存在 · `added ∪ removed ∪ sha_changed` 非空 | 标准 drift |
| `no_change_drift` | S_old / S_new 均存在 · 三列表全空 · `unchanged_count > 0` | 空 drift（但非 initial） |

> **补注**：`no_change_drift` 不是冗余——它是**"snapshot rev 升了但内容不变"**的证据（用途：debug "为什么 S_new 被重新发布了"）。

---

## 4. drift 的 scope 语义（回答 Q5.3）

### 4.1 硬约束 R3：同 scope_kind + 同 scope_ref

drift 的两个输入 snapshot **必须**满足：

1. `S_old.frozen_scope.scope_kind == S_new.frozen_scope.scope_kind`
2. `S_old.frozen_scope.scope_ref == S_new.frozen_scope.scope_ref`

**依据**：`04 §5.3 跨 scope_kind 的 snapshot diff` 已契约"跨 scope_kind 直接抛错"。drift 作为 diff 的消费者，继承该契约——scope 语义在 kernel 层仅有一处真源（04 §5.3），drift 不引入新的 scope 维度。

**工具链证据**：`m4-toolchain-review §0.1 验证 ③`——MVP `piao-snapshot-diff.sh` 在跨 scope_kind 时已实现"退出码 1 + 报错指向 §5.3"，drift 引擎沿用该实现即可。

### 4.2 scope 继承（而非重新定义）

drift artifact 的 `scope` 字段（见 §2.3）**直接继承**自输入 snapshot：

```
D.scope.scope_kind = S_new.frozen_scope.scope_kind  （= S_old.frozen_scope.scope_kind）
D.scope.scope_ref  = S_new.frozen_scope.scope_ref   （= S_old.frozen_scope.scope_ref）
```

这让 drift 在 URN 寻址层（`01 §3`）与 snapshot 同属一个 scope 命名空间，便于 `lineage_query` 的 **scope 聚合查询**（"给我这个 scope 下所有 drift"）。

### 4.3 邻接语义（"最近一次"的客观定义）

"同 scope 下最近的 published snapshot"的定义如下：

```
S_old = 在 {s ∈ snapshots | s.scope == S_new.scope ∧ s.status == published ∧ s.urn ≠ S_new.urn} 中，
        按 published_at 时间戳降序排序后的首元素。
```

**边界情况**：
- 若结果集为空 → `drift_kind=initial_snapshot`（见 §3.5）
- 若 published_at 出现并列（同毫秒）→ 以 `subject_urn` 字典序降序作为第二关键字打破平局

**幂等性保证**：published_at 是 `03 §3.3` L1 事件的不可变字段，邻接查询结果在 journal 不变时必然一致——这让 drift 的 sha256 具备可重复性（重算同样的 S_old/S_new 对得到同 content_sha256）。

### 4.4 被明确拒绝的 scope 语义变体

| 变体 | 拒绝理由 |
|-----|---------|
| "跨 scope 的联合 drift"（例如对比不同 unit 的 snapshot） | 污染 kernel 原子算子；应在应用层用两次单 scope drift 聚合 |
| "滚动窗口 drift"（N 次内的累积差） | 违反 `04 §5` 的"两张 snapshot"二元契约；可以在 evolution（M6）层基于多条 drift 记录聚合 |
| "时间切片 drift"（例如"今日 drift"） | 时间不是 scope 维度；按 `04 §2.4` 客观性 drift 必须由事件驱动不是时间驱动 |
| "drift of drift"（对两个 drift artifact 做 drift） | drift 本身的 scope_kind 归属其输入 snapshot 的 scope_kind（不是新 scope_kind 类），无对偶递归语义；若未来需要，升 kernel rev 而非本篇 |

---

## 5. drift 归因算法（回答 Q5.4）

### 5.1 硬约束 R4：两种归因模式

drift artifact 在 §2.3 的 `attribution_mode.value` 字段声明两种归因模式：

| value | 语义 | 前置条件 |
|-------|------|---------|
| `full` | 每个 `added` / `removed` / `sha_changed` 条目都携带**有效**的 `producer_event_id` | 运行环境存在 event-journal（L1 事件完整且可反查）且 snapshot 的 `frozen_artifacts` 中 `producer_event_id` **非占位符** |
| `sha_only` | drift 只承诺输出四集合（URN + sha256）· `producer_event_id` 字段可为 null 或占位符 | 上述前置条件不满足（例如 MVP 阶段工具链写入的占位符 `task-unknown-000000-000000`） |

**工具链证据来源**：`m4-toolchain-review @v1 §2.3 T3` + `§3.1 TB1 选项 ①`——

> MVP 实施印证：`piao-snapshot-produce.sh` 在 event-journal 未落地时用占位符 `task-unknown-000000-000000` 填充 `producer_event_id`。若 drift 归因算法盲信该字段，会得到一个恒为 `task-unknown` 的"归因结果"——这是比"不归因"**更危险**的反模式（虚假的确定性）。

### 5.2 降级透明暴露（不承诺隐式降级）

**强约束**：drift 引擎**不得**在 `attribution_mode.value` 之外隐藏降级行为。实现规范：

1. 若环境不满足 `full` 前置条件，drift 引擎**必须**：
   - 在 drift artifact 的 `attribution_mode.value` 写 `sha_only`
   - 在 `attribution_mode.reason` 写明降级原因（例：`"no event journal"` / `"placeholder producer_event_id detected in S_new"` / `"event journal txn mismatch"`）
   - 在对应 `drift.detected` 事件中也携带 `attribution_mode: sha_only`（下游消费者不需拉 artifact 即可知晓）

2. drift 引擎**不得**：
   - 用 mtime / git blame / 文件时间戳等替代 `producer_event_id`（这是 `m4-toolchain-review §3.1 TB1 选项 ②`**明确拒绝**的反模式——"精度差 + 依赖业务层诚信"）
   - 静默填充占位符让调用方误以为是有效归因

### 5.3 full 模式的归因算法

当 `attribution_mode.value == full` 时，对每个 `sha_changed` / `added` / `removed` 条目，归因链如下：

```
输入：artifact_urn A（发生漂移）+ producer_event_id E（来自 snapshot 的 frozen_artifacts.producer_event_id）
步骤：
  1. 按 event_id E 在 L1 journal 中反查 → 得到原始事件 Ev（类型必为 artifact.published / artifact.superseded / artifact.retracted · 01 §5.3 双轨约束）
  2. 读 Ev.producer_task_urn（task URN · 03 §3.1 语义字段）
  3. 按 task_urn T 反查 task.started / task.finished / task.failed 事件族
  4. 返回归因元组：{driver_event: Ev, driver_task: T}
```

**复杂度契约**：

| 步骤 | 复杂度 | 依据 |
|-----|------|------|
| 步骤 1 | O(1)：event_id 在 journal 层支持哈希索引 | `01 §5` event_id 唯一性 |
| 步骤 2 | O(1)：Ev 的字段直读 | `03 §3.1` 语义字段强制 |
| 步骤 3 | O(K)：K 为该 task 的事件数 · K 通常 ≤ 3 | 单个 task 生命周期仅有 started/finished/failed |
| **总体** | **O(N·K)** · N 为 drift 条目数 · K ≤ 3 | 线性于 drift 体积 |

### 5.4 被明确拒绝的归因反模式

| 反模式 | 拒绝理由 |
|-------|---------|
| 用 mtime 推断 driver_task（m4-toolchain-review TB1 选项 ②） | mtime 可被 `git checkout` / `touch` / 工具链 bug 污染 · 违反 `04 §2.4` 客观性 |
| 用 `git blame` 推断 | cherry-pick / rebase / squash 后 blame 结果不稳定 · 违反幂等性 |
| 用"最近的 task.finished"时间邻接猜归因 | 同一时刻可能有并发 task · 违反 `01 §5` event_id 唯一性设计初衷 |
| 归因结果写入 drift artifact 的可执行字段（例如 "auto_fix_task_urn"） | drift 只描述"发生了什么 + 谁驱动"，不承担"下一步该做什么"——后者是 M6 evolution 的职责 |

### 5.5 与 `02 §4 provenance` 的关系

归因算法本质上是 `02 §4.1 provenance 四元组` 的**反向查询**：

```
provenance（正向）：task → 事件 → artifact      （02 §4.1）
attribution（反向）：artifact → 事件 → task      （本篇 §5.3）
```

**对偶性结论**：只要 `02 §4.3 provenance 不可伪造` 成立（即写入端强制 event_id + task_urn 双字段冗余记账），本篇 §5.3 的反向查询必然幂等且可审计。

### 5.6 对 `02 §5.3 lineage 的 drift 应用` 的完善

`02 §5.3` 原有定义：

> 当上游发出 `artifact.superseded`（升 rev）或 `artifact.retracted`（作废），下游所有 strong 依赖者都被打上 `stale` 标记

本篇 **不改动** `02 §5.3` 的 stale 传播语义，但**补充一条**：

> **drift artifact 自身不触发下游的 stale 标记**——drift 是对 snapshot 之间差分的**描述**，不是上游事实本身的变更。
>
> 真正触发 stale 的是**drift 所揭示的底层 artifact.superseded 事件**（本篇 §5.3 归因结果中的 driver_event），该事件在被 drift 揭示**之前**已经在 journal 里写入，stale 传播也已经发生。drift 只是后置地"解释"了传播，不主动发起新传播。

**推论**：`lineage_query(direction=downstream, strength=strong)` 若遇到 drift URN，按 `02 §5.3.1 snapshot 特化` 对偶规则应用—— drift 的等价 depends_on 为 `diff_base.old_snapshot_urn` + `diff_base.new_snapshot_urn`（见本篇 §2.5），两者均已 published · 不产生循环。

---

## 6. drift → evolution 接口（回答 Q5.5）

### 6.1 双通道设计

M6 evolution 引擎以两条通道消费 drift：

| 通道 | 载体 | 用途 | 复杂度 |
|-----|------|-----|-------|
| **A · 事件流通道** | `drift.detected` L1 事件（`03 §3.1` 封板） | evolution 对全量 drift 做 O(1) "有没有新 drift"判定 | O(1) 事件读 |
| **B · 详情拉取通道** | drift artifact 本体（按 `drift.detected.subject` URN 拉取） | evolution 对关注的 drift 做详细消化（归因 + 传播） | O(N) · N 为 drift 三列表总长度 |

**设计理由**：事件流通道让 M6 的调度器可以以极低代价扫描"过去 24h 有哪些 drift 值得处理"，只在决定消化某条 drift 时才拉取 artifact（避免把大 drift 载荷塞进事件流）。

### 6.2 `drift.detected` 事件必填字段清单

对齐 `03 §3.1` 封板，本篇锁定 `drift.detected` 事件的 kernel 语义字段：

| 字段 | 类型 | 语义 | 必填 |
|------|------|-----|------|
| `event_id` | `drift-detected-<YYMMDDHHmmss>-<rand6>` | `01 §5` 事件 id 规约 · 前缀 `drift-detected-*` 与 drift artifact 自身的 `produced_by.event_id`（`snap-published-*`）分离（R19 裁定 · 见 §9 Q3） | ✅ |
| `event_type` | `drift.detected` | `03 §3.1` 枚举 | ✅ |
| `event_layer` | `L1` | `03 §3.2` 通用骨架 | ✅ |
| `emitted_at` | ISO8601+tz | `03 §3.2` | ✅ |
| `emitted_by` | actor URN | `03 §3.2` | ✅ |
| `subject` | drift artifact URN | `03 §3.1` 双轨原则 · 事件主语 = drift artifact 本身 | ✅ |
| `drift_kind` | `initial_snapshot` / `content_drift` / `no_change_drift` | 本篇 §3.5 | ✅ |
| `evidence` | `{old_snapshot_urn, new_snapshot_urn}` | `03 §3.1` 语义字段 · 记录驱动本次 drift 的两张 snapshot（即"怎么样"补充信息） | ✅ |
| `attribution_mode` | `full` / `sha_only` | 本篇 §5.1 · 让消费方无需拉 artifact 就知晓归因能力 | ✅ |
| `counts` | `{added: int, removed: int, sha_changed: int, unchanged: int}` | drift 的四集合大小速览 · 消费方做"值不值得拉取"判断 | ✅ |

> **R18 · 2026-04-19 · 字段精简**：@v1 初稿曾列 `drifting_artifact_urn` 字段（与 `subject` 同值的 alias），经 m5-drift-draft-review §3.1 R18 裁定**删除**——理由：
>
> - 违反 `03 §3.1` 双轨原则本意（"`subject` 承载 who/what · 语义字段承载 how"），alias 字段不承载额外"how"信息
> - 造成消费方困惑（"到底读 subject 还是 drifting_artifact_urn"）
> - 事件的"驱动上下文"信息（两张 snapshot URN）已由 `evidence` 字段完整承载，无缺失

**工具链证据**：`m4-toolchain-review @v1 §3.4 TB4`——

> MVP diff 输出已经对每个 `sha_changed` 条目记录了两个 producer_event_id（虽然 MVP 用的是占位符）。这让"drift 事件"关联回"触发变化的 task 链路"天然可行。

### 6.3 evolution 对 drift 的消费契约（M6 前置预留）

本篇**不**规定 evolution 如何消化 drift（那是 M6 的 §X），但**锁定**以下前置契约（M6 起稿时不可违反）：

| 契约 | 内容 | 对应本篇 |
|-----|------|--------|
| C1 | M6 evolution 只允许从 `drift.detected` 事件**单向读**；不得反向写入 drift artifact | 本篇 §2（drift 是 artifact）+ `02 §6` 生命周期 |
| C2 | M6 对 `attribution_mode=sha_only` 的 drift **不得**尝试自行补全归因（不得调用 mtime / git blame） | 本篇 §5.4 反模式列表 |
| C3 | M6 消化 drift 后若产生新的 task / proposal，**必须**通过 `02 §4` provenance 链关联回本 drift 的 URN | `02 §4.1` 四元组必填 |
| C4 | M6 不得以"已消化 drift A"为由修改 drift A 的 status 或内容 —— drift 是 append-only artifact | `02 §6 生命周期` + `03 §3.3` append-only |

### 6.4 非本篇承诺（留给 M6）

- drift 消化的**优先级算法**（哪些 drift 先处理）
- drift 消化的**批处理策略**（按 scope 聚合 / 按时间窗批处理）
- drift 消化产生的新 task 如何纳入 taskdag（M3 taskdag 模型的范畴）

这些都是 M6 起稿时的 §X 内容。本篇只承诺"数据结构与事件通道"。

---

## 7. drift 生命周期与通胀控制（参考 04 §6/§7 范式）

### 7.1 状态机（仅两态 · 对齐 `04 §7.1`）

```
  draft ──┬── artifact.published ──▶ published (永久态 · append-only)
          │
          └── 极罕见情况：artifact.retracted ──▶ retracted（例：发现 drift 是由损坏 snapshot 输入触发 · 见 §7.3）
```

**不引入** `superseded` 态——drift artifact **不升 rev**，因为：
- drift 的 rev 本应由输入 snapshot 的 rev 决定，但 snapshot 不可变（`04 §7.1`）
- 如果发现 drift 算法本身有 bug → 升的是 kernel rev（本篇 §8.2），不是单条 drift 的 rev

> **R20 脚注 · 2026-04-19 · 历史 drift 的回溯作废策略**：
>
> kernel 层 05 rev 升版**默认不回溯作废**已 published 的 drift artifact——历史 drift 保持 published 状态，继续作为"彼时契约下的客观差分证据"。
>
> **例外触发条件**：新 rev 的 `rev_history` 条目显式声明 `retroactive_invalidation: true`（且需在条目描述中列明"为何当前已 published 的 drift 必须失效"），才触发批量 retracted。这一约束保护 `02 §6` 生命周期"artifact 产出后一般不可回溯作废"的精神——除非 kernel 层明确宣告"旧语义失效"，否则旧 drift 继续可被审计 / 追溯 / 引用。

### 7.2 体积预算

| 项 | 预期值 | 上限 | 依据 |
|----|------|-----|------|
| 单条 drift artifact 大小 | < 5 KB | < 500 KB | 对标 `04 §6.1` 单 snapshot 预算 · drift 通常小于 snapshot（仅三列表 + 计数） |
| `added ∪ removed ∪ sha_changed` 条目总数 | 几～几十 | < 1000 | drift 是"变化"集合 · 通常远小于 snapshot 的 `frozen_artifacts` 总数 |
| 每 scope_ref 生命周期内 drift 总数 | 与 snapshot 总数近似（N-1） | < 10,000 | `04 §6.1` 同 scope snapshot 上限约束 |

### 7.3 retracted 的唯一合法场景

drift artifact 仅在以下情况可被 retracted：

1. **S_old 或 S_new 被 retracted**：上游 snapshot 被作废意味着 drift 的基础不复存在
2. **drift 算法的 kernel rev 升降且新 rev 显式声明旧语义失效**：仅当 `05 @vN → @vN+1` 的 `rev_history` 条目中**显式写明** `retroactive_invalidation: true`（含失效理由），触发当前 drift 批量 retracted——需在 `retracted` 事件中引用新 rev 的契约条款与 `retroactive_invalidation` 声明条目。
   - **默认情形**（新 rev 未声明 `retroactive_invalidation`）：旧 drift **保持 published**，不触发作废。此为与 §7.1 脚注一致的守恒条款。
3. **数据损坏**：drift 文件被文件系统损坏或签名不匹配——retracted 后重新运行 drift 算法补一条新 URN 的 drift

**禁止** retracted 的场景：
- 业务层"不喜欢"这条 drift 的内容（drift 是客观差分结果，不是主观意见）
- M6 evolution 认为 drift 不该产出（evolution 不持有 drift 产出决策权 · 见 §6.3 C1）

### 7.4 通胀控制策略

对标 `04 §6.2 snapshot 通胀是最大设计风险`：

- **避免小步升 rev 触发密集 drift**：snapshot 的 rev 升降由 `04 §4.2` 严格约束（"内容变化才升 rev"），drift 密度自然与 snapshot 密度挂钩
- **避免无意义 drift 污染事件流**：通过 `drift_kind=no_change_drift` 场景的**二阶过滤**——消费方可基于 event 的 `counts` 字段在拉取 artifact 之前跳过 no_change_drift
- **归档策略** 留给 M7（本篇不覆盖 · 对齐 kickoff §4 非目标清单）

---

## 8. rev_history 与 M5 最终决议

### 8.1 rev_history

| rev | 发布时间 | 触发来源 | 变更摘要 |
|-----|---------|---------|---------|
| v0.1 | 2026-04-19 02:10 | M4 milestone 收官 · 骨架起稿 | 仅 §0 定位 + §1 五问清单 + §2 大纲占位 + §3 前置契约 + §4 非目标 |
| v0.2 | 2026-04-19 02:40 | `m5_drift_kickoff@v1` published | front-matter upstream 追加 kickoff URN；§5 起稿节奏精确化为引用 kickoff §2 两阶段门控 |
| **v1** | **2026-04-19 13:10** | `m5_drift_kickoff@v1 §2.3` 分支 β-2 触发 · `m4-toolchain-review@v1` 证据 | 骨架升首版 draft：§2/§3/§4/§5/§6/§7 正文全部起稿；锁定 R1–R5 五条硬约束；对齐 TB1–TB4 四条工具链视角建议；与 `04 §5` + `02 §4/§5` + `03 §3` + `01 §2.1/§5` 完成 kernel 锚点闭环 |
| v1（原地追述 · 路径 A 消化） | 2026-04-19 14:10 | `m5-drift-draft-review@v1 §3.1` R17–R20 + §9 Q1–Q5 裁定 | **不升 rev**（按 `01 §10.1` draft 允许原地修订）。落地：R17（§2.5 反向排除 → 正向白名单六字段）· R18（§6.2 删除 `drifting_artifact_urn` alias）· R19（§2.3 `produced_by.event_id` 前缀 `snap-published-*` + §6.2 `drift.detected.event_id` 前缀 `drift-detected-*` 分离）· R20（§7.1 补"默认不回溯作废"脚注 + §7.3 条件 #2 重写为显式 `retroactive_invalidation` flag 触发）· §9 Q1/Q2/Q3/Q4/Q5 五条开放问题标注 review 裁定状态。路径 B（R21–R25）待 `m5_drift_kernel_alignment@v1` proposal 启动处理 |
| **v1.1（draft）** | **2026-04-19 14:45** | `urn:piao:proposal:kernel:m5_drift_kernel_alignment@v1 §4.6 / S5` · 路径 B 跟随升版 | 路径 B（R21–R25）已在 04 @v1.2 / 02 @v1.3 / 03 draft 原地三处消化 · 本次跟随升小版（**仍 draft** · 不 draft → published · 对齐 `01 §10.1` draft 允许内部小升）· 反映 04/02/03 外部升降带来的锚点注释状态变化 · schema 骨架与 R1–R5 五硬约束全部保留不变。主要动作：①front-matter `upstream` 追加 `m5_drift_draft_review@v1` / `m5_drift_kernel_alignment@v1` 两条 · `version_snapshot` 从 `@v1.1` 升至 `@v1.2` · `artifact_model` 从 `@v1.2` 升至 `@v1.3`；②§2.5 末尾"等价替身规则"注释从"R23 待处理（→ proposal）"改为"R23 已落地 · 对接 `02 §5.3.1 lineage 特化注册表 · kind=drift 条目`（02 @v1.3）"；③§2.5 新增"与 `04 §3.2.3 canonical YAML 通用工具契约`的对接"段 · 声明 `SHA_WHITELIST` 六字段是 04 §3.2.3 承诺 3 的首个复用案例（kernel 层通用契约的首次跨篇复用验证）；④§10 前置契约表：`04 §5.1` 引用描述追加 "`modified/sha_changed` 双名（04 @v1.2 起）" · 新增 `04 §3.2.3` 一行（canonical YAML 通用工具实施建议 · 提供 key 正则 + `pick_fields` 范式 + `SHA_WHITELIST` 声明范式 · 本篇 §2.5 为首个复用案例）· `02 §5.3/§5.3.1` 描述从"snapshot 特化"改为"lineage 特化注册表 · 含 kind=drift 条目（02 @v1.3 起）" · 新增 `02 §2.2.4` 一行（派生类型注册 schema · 含 `wordcheck_policy` 字段支持本篇 drift.propagation_record 机器产物自动 exempt）· 升版状态全部刷新（04 @v1.2 / 02 @v1.3）；⑤§9 Q1 裁定补注：从"04 侧落地归 R24 → proposal"改为"R24 已于 `m5_drift_kernel_alignment@v1 §4.3 / S2` consumed（04 @v1.2 · 双名 alias 落地）" · Q5 裁定补注：从"02 侧落地归 R25 → proposal"改为"R25 已于 `m5_drift_kernel_alignment@v1 §4.5 / S3` consumed（02 @v1.3 · `wordcheck_policy` 字段落地）"。**为 §8.2 门控 #2/#3/#4 的 Step 5 工具链验证（`scripts/piao-drift-compute.sh` MVP）留出窗口期** · status 保持 draft · 下一步 @v1.1 draft → @v1.1 published 需满足门控 #2/#3/#4 |
| **v1.1（published）** | **2026-04-19 15:40** | `urn:piao:snapshot:kernel:m5_final_decisions@v1 §7 门控复核表` · M5 milestone 收官封版 | 同 rev 内部 `draft → published` 状态转换（不升 rev · 不触发 supersedes）· `§8.2` 四条门控全部达成：#1 draft-review@v1 published（kernel 锚点 20/20 存在 · commit `596f2ad2`）· #2 `scripts/piao-drift-compute.sh` MVP 产出（555 行 · 4 场景冒烟全通：content_drift / initial_snapshot / no_change_drift / cross-scope 拒绝 · commit `bcc56229`）· #3 R1–R5 五硬约束在 MVP 实施中未被反例证伪（schema / 触发器 / scope / 归因降级 / 双 producer_event_id 全反证通过）· #4 m5-final-decisions@v1 published（决议 1–6 矩阵 + 九 commit 证据链 · commit `b8f877f9`）。主要动作：①front-matter `status: draft → published` · `last_modified_at` 刷新至 15:40 · `upstream` 追加 `urn:piao:snapshot:kernel:m5_final_decisions@v1`；②标题从"首版 draft · 路径 B 跟随升版 @v1.1"改为"首版 @v1.1 published" · 起稿说明段改为"published 定稿说明" · 升版路径追加 `@v1.1 draft → @v1.1 published` 末段 · 列出四条门控达成证据 · 删除"path B 跟随升版补注"冗余段落（已由 v1.1 draft 行承载历史）；③§8.2 四个 `[ ]` 全部标为 `[x]`（附达成证据引用）；④§11 本篇状态行从"draft @v1（首版 draft · 阶段 β 工作流 D 起稿产出 · M5 milestone review 周期启动前冻结）"改为"published @v1.1（M5 milestone 封版 · 阶段 β 路径 B + 阶段 α MVP + final-decisions 门控复核全闭合）"· 下游锚点追加 `m5-final-decisions@v1` 实际产出；⑤`piao-drift-compute.sh` 追加至上游锚点区（作为 §3.2 T3/T4/T5 流程的客观承载者）。**schema / R1–R5 / §2–§7 正文字面保持不变**（封版守恒） |

### 8.2 draft 升 published 的门控条件

本篇 `@v1.1 draft → @v1.1 published` 需同时满足（**四条全达成 · 2026-04-19 15:40**）：

- [x] `_review/m5-drift-draft-review.md @v1 published`（对标 `m4-snapshot-draft-review.md` 三段式 · kernel 锚点 20/20 存在 · 五问 R1–R5 五硬约束证据完备 · 路径 A R17–R20 + 路径 B R21–R25 九条裁定全产出 · commit `596f2ad2`）
- [x] 至少一条**真实 drift artifact**（非 MVP 占位）产出验证本篇 schema 可实施 · 由 `scripts/piao-drift-compute.sh` MVP 承载（555 行 · 阶段 α 端到端四场景冒烟：① content_drift `added=3/removed=2/sha_changed=0/unchanged=2` sha=`2601de6c`（幂等）· ② initial_snapshot 四字段全零 sha=`1126a39f` · ③ no_change_drift `unchanged=4` sha=`da03ff6d` · ④ cross-scope 拒绝退出码 1 + 错误引用 §4.1 R3 · commit `bcc56229`）
- [x] R1–R5 五条硬约束在实施过程中**未被触发反例**（R1 schema 反证：drift artifact 文件生成成功 + canonical YAML 幂等 · R2 触发器反证：唯一触发器 `snapshot.published` 由 `03 §3.3.1 N=2 同 txn` 承载 · R3 scope 反证：跨 scope 场景 ④ 退出码 1 拒绝 · R4 归因降级反证：场景 ① `attribution_mode=sha_only` + `reason="no event journal"` 透明暴露 · R5 双 producer_event_id 反证：四场景产出前缀 `snap-published-*` 字面正确 · SHA_WHITELIST 六字段不变性验证通过）
- [x] `_review/m5-final-decisions.md @v1 published`（本篇 published 决议快照 · 决议 1–6 矩阵 + 九 commit 证据链 · §6 kickoff 生命周期闭合 + §7 05 published 门控复核表 · 对标 `m4-final-decisions.md` 六大结构 · commit `b8f877f9`）

### 8.3 触发升 `@v2 draft` 的条件

- R1–R5 任一条被实施反例证伪
- kickoff §4 五个必答问题被**新增**第六个（kernel 层引入新问题）
- `04` 或 `02` / `03` / `01` 的 kernel 锚点被升版且影响本篇引用

---

## 9. 开放问题（draft 阶段留给 review 解决）

### Q1 · `modified` vs `sha_changed` 字段命名不一致

- `04 §5.1` 算子契约用 `modified`
- 本篇 §2.3 schema / kickoff §2.2 门控用 `sha_changed`
- `m4-toolchain-review @v1 §2.4 T4` 已登记为 04 补注级别建议

**候选方案**：
- A：本篇 @v1 draft 在 body 字段采用 `sha_changed`（当前选择），04 下次补升时向下兼容双名
- B：本篇回退用 `modified` 对齐 04，放弃 kickoff 的 `sha_changed` 命名

**暂定**：方案 A（本篇 draft 保持），由 m5-draft-review 与 04 补注同步决议。

> **裁定 · 2026-04-19 14:10（review-accepted）**：`m5-drift-draft-review@v1 §3.1` 裁定**保持方案 A**——05 body 用 `sha_changed`；04 下次小升时增加 `sha_changed` 作为 `modified` 的 alias（向下兼容双名）。本 Q1 的 04 侧落地归入 **R24** → `m5_drift_kernel_alignment@v1` proposal（路径 B）。05 内部无需再修改。
>
> **已 consumed · 2026-04-19 14:45**：R24 已于 `m5_drift_kernel_alignment@v1 §4.3 / S2` 落地——04 @v1.2 在 §5.1 `snapshot_diff` 字段表追加 `sha_changed` 作为 `modified` 的 alias（两字段值必须同语义 · `snapshot-diff.sh` 同时写入双名 · 向下兼容至少保留两个小版本周期双名输出 · 新消费方应优先用 `sha_changed`）。05 §2.4 对偶表 + §2.5 `SHA_WHITELIST` 第五字段 `sha_changed` 从"本篇单边声明"变为"04 侧已反向对接"。本 Q1 完全关闭。

### Q2 · `attribution_mode=sha_only` 下 `producer_event_id` 字段是否保留

- 本篇 §2.3 schema 定义 sha_only 模式下该字段**可为 null**（保留字段位置）
- 替代方案：sha_only 模式下**移除**该字段（让缺失本身等价于降级标志）

**暂定**：保留 + nullable（对消费方更友好 · 不需分两套 schema）

> **裁定 · 2026-04-19 14:10（review-accepted）**：`m5-drift-draft-review@v1 §3.1` 裁定**保持 draft 方案**——`sha_only` 模式下 `producer_event_id` 保留字段位置但可为 null。消费方通过 `attribution_mode.value` 预判字段是否可信，schema 单一，无需分叉。

### Q3 · drift 的 `produced_by.event_id` 本身用什么 event_id 规约

- 候选 A：`drift-<YYMMDDHHmmss>-<rand6>`（与 `drift.detected` 事件同前缀）
- 候选 B：`snap-published-<ts>-<rand>`（强调 drift 是 snapshot.published 的派生）

**暂定**：候选 A（drift 作为 artifact 身份优先 · 事件是其产物）

> **裁定 · 2026-04-19 14:10（review-resolved → R19）**：`m5-drift-draft-review@v1 §3.1` 否决候选 A/B 之间的二选一，引入**前缀分离方案**——
>
> - drift artifact 的 `produced_by.event_id` 前缀 = `snap-published-<YYMMDDHHmmss>-<rand6>`（该事件本质是"`snapshot.published(drift)` 的 artifact.published 事件"的派生）
> - `drift.detected` 事件的 `event_id` 前缀 = `drift-detected-<YYMMDDHHmmss>-<rand6>`
>
> 理由：两条事件是**同 txn 写入的不同事件**（见 §3.2 T5），共享 `drift-` 裸前缀会让 grep / 工具索引混淆。前缀分离后语义一目了然——"看到 `snap-published-*` 就知道是 artifact.published 事件，看到 `drift-detected-*` 就知道是 drift.detected 事件"。
>
> 本裁定已落地至 §2.3 schema 示例 + §6.2 必填字段表。Q3 关闭。

### Q4 · initial_snapshot 场景下是否产出空 drift artifact

- 本篇 §3.2 步骤 2 规定："drift 不产出——发一条 `drift.detected` 事件且 body 为空 drift artifact"
- 这意味着即便"首次 snapshot"也会产生一个 drift artifact（空三列表）

**替代**：只发 `drift.detected` 事件 · `subject` 指向 S_new 本身 · 不产出 drift artifact

**暂定**：保持本篇 §3.2 做法（产出空 drift artifact · 让 evolution 的消费逻辑一致，不需分叉"有 drift / 无 drift"）

> **裁定 · 2026-04-19 14:10（review-accepted）**：`m5-drift-draft-review@v1 §3.1` 裁定**保持 draft 方案**——`initial_snapshot` 场景也产出空 drift artifact（四字段全零 · `drift_kind=initial_snapshot`）。消费方 M6 evolution 对 drift 的读取逻辑**单一**（永远拉 drift artifact），无需分叉"首次 snapshot 无 artifact / 后续 snapshot 有 artifact"两套代码路径。

### Q5 · drift artifact 是否需要 `wordcheck_exempt`

- 本篇 draft 未涉及，但未来具体 drift 实例（业务数据）是否需要 wordcheck 审查？
- `drift.propagation_record` 内容通常只含 URN + sha256 + event_id，不含自然语言

**暂定**：不默认 exempt · 由 `02 §2.2 派生类型注册`处的 `wordcheck_policy` 字段控制（若 kernel 派生 drift.propagation_record 时声明 `wordcheck_policy: machine_generated`，则自动跳过）

> **裁定 · 2026-04-19 14:10（review-accepted）**：`m5-drift-draft-review@v1 §3.1` 裁定**保持 draft 方案**——drift artifact 不默认 `wordcheck_exempt`；由 02 §2.2 派生类型注册机制的 `wordcheck_policy: machine_generated` 声明自动跳过。本 Q5 的 02 侧落地归入 **R25** → `m5_drift_kernel_alignment@v1` proposal（路径 B）。05 内部无需再修改。
>
> **已 consumed · 2026-04-19 14:45**：R25 已于 `m5_drift_kernel_alignment@v1 §4.5 / S3` 落地——02 @v1.3 新增 §2.2.4 "派生类型注册 schema"（七字段结构 · 第 7 字段 `wordcheck_policy: machine_generated | content_safe_default` 默认后者兜底安全）· adapter / kernel 在下次升版时可为 `drift.propagation_record` 登记 `wordcheck_policy: machine_generated` · 声明后本篇 front-matter 的 `wordcheck_exempt: true` 变为"注册自动继承 · 显式声明可省略但保留不冲突"（幂等）· `kernel-wordcheck.sh` 启动时加载 02 §2.2.4 派生注册表构建 exempt cache。本 Q5 完全关闭。

---

## 10. 前置契约（本篇依赖的上游）

| 上游 | 依赖点 | 状态 |
|------|-------|------|
| `01 §1.1` URN grammar | drift URN 模板（§2.1 / §2.3） | ✅ @v1.2 published |
| `01 §2.1` kind 枚举含 drift | §2.1 kind 字段合法性 | ✅ @v1.2 published |
| `01 §5` event_id 规约 | §6.2 drift.detected event_id 格式（§Q3 候选） | ✅ @v1.2 published |
| `02 §1.1` artifact 五要素 | §2.3 drift artifact schema | ✅ @v1.3 published |
| `02 §2.2.4` 派生类型注册 schema（v1.3 新增） | §Q5 `wordcheck_exempt` 通过 `wordcheck_policy: machine_generated` 自动继承（drift.propagation_record 适用） | ✅ @v1.3 published |
| `02 §4.1/§4.3` provenance 四元组 + 不可伪造 | §5.3 归因算法的反向查询基础 | ✅ @v1.3 published |
| `02 §5.3/§5.3.1` lineage 特化注册表（v1.3 扩为通用 · 含 `kind=drift` 条目） | §2.5 drift 的 lineage 等价替身规则（对偶 · 已双向对接） | ✅ @v1.3 published |
| `02 §6` artifact 生命周期 | §7 drift 状态机 | ✅ @v1.3 published |
| `03 §3.1` L1 事件枚举含 drift.detected | §6.2 事件字段清单 | ✅ @v1 draft |
| `03 §3.1` 双轨原则 | §6.2 subject = drift artifact URN · `evidence` 承载"how"补充信息（R18 · 已删除冗余 alias `drifting_artifact_urn`） | ✅ @v1 draft |
| `03 §3.3.1` 原子写入契约（N 条同 txn · M5 泛化） | §3.2 触发流程 T1–T5 同 txn · drift 两写（N=2）为本契约的已登记实例 | ✅ @v1 draft（M5 S1 泛化） |
| `04 §2.4` 触发判定客观性 | §3.4 drift 触发客观性 · §5.4 反模式拒绝依据 | ✅ @v1.2 published |
| `04 §3.2` snapshot schema | §2.4 drift/snapshot 对偶表 | ✅ @v1.2 published |
| `04 §3.2.1` canonical YAML 规范化（snapshot 特化五步） | §2.5 drift content_sha256 复用（作为 snapshot 特化的对偶实例） | ✅ @v1.2 published |
| `04 §3.2.3` canonical YAML 通用工具实施建议（v1.2 新增） | §2.5 drift content_sha256 是本契约的首个复用案例 · `SHA_WHITELIST` 六字段 + `pick_fields` 正向白名单 + key 正则字面对齐承诺 1/2/3 | ✅ @v1.2 published |
| `04 §3.3` scope_kind 五类封板 | §4.1 drift scope 语义 | ✅ @v1.2 published |
| `04 §5.1` snapshot_diff 算子契约（`modified/sha_changed` 双名 · 04 @v1.2 起） | §2.3 drift body 四集合字段 + §5 归因输入 · 05 body 优先用 `sha_changed` · 04 工具同时输出双名 | ✅ @v1.2 published |
| `04 §5.3` 跨 scope_kind diff 拒绝 | §4.1 硬约束 R3 继承 | ✅ @v1.2 published |
| `04 §6.1` snapshot 体积预算 | §7.2 drift 体积预算参照 | ✅ @v1.2 published |
| `04 §7.1` snapshot 状态机 | §7.1 drift 状态机对齐（无 superseded 态） | ✅ @v1.2 published |
| `m5_drift_kickoff@v1 §4` 必答五问 | §1 问题清单 + §2–§6 章节主线 | ✅ published |
| `m4-toolchain-review@v1 §3` TB1–TB5 建议 | §5.1 R4 / §3.1 R2 / §4.1 R3 / §6.2 R5 的直接证据 | ✅ published（§2.5 T5 key 正则遗留债由 `m5_drift_kernel_alignment@v1 S2` 合并至 04 §3.2.3 consumed） |
| `m5-drift-draft-review@v1 §3.1/§3.2` 路径 A R17–R20 + 路径 B R21–R25 | 路径 A 已于本篇 v1 原地追述（14:10）· 路径 B 已于本篇 v1.1（14:45）跟随升版（03/04/02 三处上游修订由 `m5_drift_kernel_alignment@v1` S1/S2/S3 落地） | ✅ published |
| `m5_drift_kernel_alignment@v1 §4.1–§4.6` | R21/R22/R23/R24/R25 + S5 跟随升版（本篇 v1.1）· 路径 B 五条全部 consumed | ✅ published |

---

## 11. 非目标（M5 不做 · 承接 @v0.2 骨架）

- **snapshot GC / 归档策略**（M7 之后）
- **drift 的可视化层 / dashboard UI**（工具链侧，非 kernel · M5 kickoff §4 非目标一致）
- **evolution 模型本体**（M6 的范畴 · 本篇 §6 只提供接口 schema）
- **drift 批处理 / 优先级调度算法**（M6 evolution 消化策略 · 本篇 §6.4 明确不覆盖）
- **"跨 scope 联合 drift" / "滚动窗口 drift" / "时间切片 drift"**（见 §4.4 拒绝列表）

---

**本篇状态**：published @v1.1（M5 milestone 封版 · 阶段 β 路径 A 原地追述 + 路径 B 跟随升版 + 阶段 α 工具链 MVP 反证 + `m5-final-decisions@v1` 门控复核全闭合 · 2026-04-19 15:40）

**上游锚点**：
- `urn:piao:proposal:kernel:m5_drift_kickoff@v1 published`（本 draft 触发源 · 本 published 后触发 kickoff `status: published → superseded`，supersedes = `m5_final_decisions@v1`）
- `urn:piao:artifact:kernel:m4_toolchain_review@v1 published`（TB1–TB5 强约束输入 · §2.5 T5 key 正则遗留债已由 `m5_drift_kernel_alignment@v1 S2` 合并至 04 §3.2.3 consumed）
- `urn:piao:artifact:kernel:m5_drift_draft_review@v1 published`（§3.1 R17–R20 路径 A 原地裁定 + §3.2 R21–R25 路径 B 外篇裁定 + §1.2 kernel 锚点 20 条 100% 存在校验）
- `urn:piao:proposal:kernel:m5_drift_kernel_alignment@v1 published`（§4.1–§4.6 路径 B 五条修订 S1/S2/S3 + S5 跟随升版落地证据）
- `urn:piao:snapshot:kernel:m5_final_decisions@v1 published`（§8.2 门控复核 + 决议 1–6 矩阵 + 九 commit 证据链 · 本 published 的直接产出复核源）
- `urn:piao:spec:architecture:version_snapshot@v1.2 published`（M4 snapshot 模型 · drift 的直接上游 · 含 §3.2.3 canonical YAML 通用工具 + §5.1 `sha_changed/modified` 双名）
- `urn:piao:spec:architecture:artifact_model@v1.3 published`（artifact 五要素 + §5.3.1 lineage 特化注册表含 kind=drift 条目 + §2.2.4 派生类型注册 schema 支持 `wordcheck_policy: machine_generated`）
- `urn:piao:spec:architecture:layered_architecture@v1 draft`（L1 事件 + §3.3.1 原子写入契约 N 条同 txn · M5 S1 泛化）
- `urn:piao:spec:architecture:identity_model@v1.2 published`（URN + event_id 规约 · 含 `snap-published-*` / `drift-detected-*` 前缀分离）

**工具链承载**：
- `scripts/piao-drift-compute.sh`（555 行 · commit `bcc56229` · 本篇 §2.3 schema + §3.2 T1–T5 流程 + §4.1 R3 scope 拒绝 + §5.1–§5.2 R4 归因降级 + §6.2 R5 双 producer_event_id 的客观承载者 · 四场景冒烟全通 · 反证 R1–R5 五硬约束未被证伪）

**下游锚点**：
- `_review/m5-drift-draft-review.md @v1 published`（本篇 draft → published 的 review 产出 · 门控 #1 承载 · 对标 `m4-snapshot-draft-review.md`）
- `_review/m5-final-decisions.md @v1 published`（M5 milestone 收官快照 · 本篇 published 的终点门控 #4 承载 · 对标 `m4-final-decisions.md` 六大结构）
- M6 evolution 模型将以本篇 §6 的 drift→evolution 接口（双通道 + C1–C4 前置契约）为基础起稿（`m6_evolution_kickoff@v1` 接力）
