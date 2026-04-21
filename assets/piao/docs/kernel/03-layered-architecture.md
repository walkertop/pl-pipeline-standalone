---
urn: urn:piao:spec:architecture:layered_architecture@v1
kind: spec
rev: v1
status: draft
supersedes: null
produced_by: urn:piao:task:m3:layered_architecture_draft
produced_at: 2026-04-18T17:30:00+08:00
---

# kernel · 03 Layered Architecture & Event Model

> 系统**分几层**、**层间怎么通信**、**事件长什么样**、**事件怎么活怎么死**。
> 这是 kernel 的心脏——M1（身份）定义"实体叫什么"，M2（artifact）定义"实体长什么样"，M3 定义"实体之间通过什么流动"。

---

## 0. 定位

本篇回答四个彼此咬合的问题：

1. piao-pipeline 在**运行时**分几层？每层职责边界在哪？
2. 层间通信的唯一载体——**事件**——怎么分层、分几层、每层写什么？
3. 事件 id 怎么起？append-only 怎么保证？
4. 当事件数量爆炸时，什么事件可以归档？归档的**客观判定规则**是什么？

**本篇不回答**（留给后续 M 阶段）：
- adapter 开发规范（M4）
- 具体场景的事件 schema 扩展字段（M7 之后，adapter 自定义）
- 存储引擎选型（M4 工具链层）

**设计铁律**：
> **kernel 只定义 L1 事件的完整 schema；L2 事件只定义骨架字段，adapter 可扩展。**

---

## 1. 运行时分层

### 1.1 四层模型

```
┌─────────────────────────────────────────────────────────────┐
│ L_Surface · 人/Agent 界面                                    │
│   dashboard, CLI, IDE 聊天框, trace-report.html             │
│   — 只读视图，不写事件                                         │
├─────────────────────────────────────────────────────────────┤
│ L_Adapter · 场景适配层（可多个并存）                           │
│   每个业务场景（如前端框架迁移、后端 API 规范治理）一个 adapter│
│   — 把 kernel 契约翻译成具体业务工作流；写 L1/L2 事件          │
├─────────────────────────────────────────────────────────────┤
│ L_Kernel · 契约与核心服务                                     │
│   identity, artifact-model, event-journal, drift, evolution │
│   — 提供服务与契约，不处理任何业务场景                          │
├─────────────────────────────────────────────────────────────┤
│ L_Storage · 存储与归档                                        │
│   artifact-fs, event-journal-fs, manifest-index, archive-fs │
│   — 只负责持久化与索引，不理解内容语义                          │
└─────────────────────────────────────────────────────────────┘
```

> **关于 "Adapter" 这个层名**：这里是**运行时分层**的概念，指"把 kernel 契约翻译成具体业务流程的一层代码/配置"，不是 M1 §3 里那个已删除的 URN realm 段。一个项目通常只有一个 adapter 模块（如本仓库首个落地的前端迁移 adapter），多 adapter 是未来可能的扩展点（见 M1 §11）。

### 1.2 层间通信的三条铁律

1. **向上只读**：下层不主动推数据给上层；上层通过订阅 / 查询获取下层状态。
2. **向下只写事件**：上层要改下层状态，**唯一路径**是"写一条事件，等事件被应用"。**禁止直接改 artifact 文件、禁止跨层调用写 API**。
3. **kernel 对 adapter 匿名**：kernel 提供的服务（event-journal、drift、evolution）**不知道调用方是哪个 adapter**，只按 URN 语义处理。

> **为什么**：这是整个架构可维护性的根基。adapter 可以被随意增删替换；kernel 一旦提供了"adapter 专属接口"，耦合立刻回归，分层等同作废。

### 1.3 L_Surface 不可以写事件的原因

dashboard、CLI 这类"人面对面"的层如果能直接写事件，人肉就可以绕过 adapter 的校验逻辑制造"孤儿事件"。**人类的所有操作必须由 adapter 代写**（adapter 负责把"用户点了一下按钮"翻译成一条合法事件），这是 audit trail 能成立的前提。

---

## 2. 事件分层：L1 / L2

### 2.1 为什么一定要分层

在 M2 `02-artifact-model.md §4.4` 的占位说明里已经锚定了这条。这里给出完整论证：

**不分层的后果**（Dagster、Airflow 早期都踩过）：
- 所有事件混在一个 journal 里，数据量 1 年翻 3 次
- "重要事件"（artifact 发布）和"噪音事件"（step log）没有优先级差异，drift 系统扫一次要遍历全量，慢且不稳
- 事件 schema 一改就要全量迁移，因为没有分层，不知道哪些是"稳定契约"哪些是"可演化日志"

**分层后的收益**：
- **L1 稳定**：可以承诺"L1 schema 10 年不变"，drift / evolution / artifact 追溯系统敢基于它构建
- **L2 可演化**：adapter 可以自由增删字段、可归档、可替换格式——反正 L1 是兜底真相源

### 2.2 两层的职责分界

| 维度 | L1 · Artifact 事件 | L2 · Execution 事件 |
|------|-------------------|---------------------|
| **语义** | "产出物发生了什么" | "actor 在做什么" |
| **数量级** | 一个 task 产 1–5 条 | 一个 task 产 10–500 条 |
| **schema 稳定性** | kernel 定死，跨项目通用 | kernel 只定骨架，adapter 扩展 |
| **生命周期** | **永久保留** | 满足归档条件后可归档 |
| **读者** | drift / evolution / audit / manifest 校验 | dashboard / trace / debug |
| **写者** | kernel 工具 + adapter（受约束） | adapter（自由） |
| **典型事件** | `artifact.published` / `task.finished` / `evolution.scanned` | `task.started` / `task.step_log` / `verify.lint_failed` |

### 2.3 两层的关联

L2 事件必须声明它所属的 task：

```
L2.parent_task_urn → 某个 task URN（该 task 由 L1 的 task.started / task.finished 事件持有）
```

通过这条链，任何 L1 task 事件都可以反查它下面的所有 L2。反过来不行——**L1 事件不记录 L2 列表**（否则 L1 就会随 L2 一起膨胀）。

---

## 3. L1 事件：kernel 完整 schema

### 3.1 L1 事件类型枚举（v1 封板）

kernel 定义以下 L1 事件类型，**业务层不可新增 L1 类型**（新增需走 kernel rev 升降）：

| 类型 | 触发时机 | subject 指向 | 语义字段（与 subject 同步，工具校验一致） |
|------|---------|-------------|-----------------------------------|
| `artifact.published` | artifact 从 draft → published | artifact URN | `artifact_urn`, `rev`, `sha256`, `producer_task_urn` |
| `artifact.superseded` | 新 rev 发布，旧 rev 被取代 | **新** artifact URN | `new_artifact_urn`, `old_artifact_urn`, `rev`, `sha256`, `producer_task_urn` |
| `artifact.retracted` | artifact 被作废（极罕见） | artifact URN | `artifact_urn`, `reason`, `retraction_spec_urn` |
| `task.started` | task 开始执行 | task URN | `task_urn`, `adapter`, `actor` |
| `task.finished` | task 成功完成 | task URN | `task_urn`, `produced_artifact_urns` |
| `task.failed` | task 失败终止 | task URN | `task_urn`, `failure_reason`, `l2_range` |
| `stage.entered` | pipeline 进入新阶段 | stage URN | `stage_urn`, `entry_snapshot_urn`, `[related_taskdag_urn?]` |
| `stage.exited` | pipeline 离开阶段 | stage URN | `stage_urn`, `exit_snapshot_urn`, `exit_reason`, `[related_taskdag_urn?]` |
| `evolution.scanned` | evolution 子系统完成对某 drift 事件的扫描（字段精化由 `m6_evolution_kernel_alignment@v1` S1 落地 · v1 draft 原地修订 · 不升 rev · 详见 `06-evolution-model.md §2.3`） | drift 事件 URN（被扫描的 `drift.detected` 事件） | `drift_event_urn`, `scope_urn`, `scanned_drifts[]`, `decision_log[]`（字段细节见 `06-evolution-model.md §2.3 / §5.3`） |
| `drift.detected` | drift 子系统发现 lineage/contract 漂移 | 发生漂移的 artifact URN | `drifting_artifact_urn`, `drift_kind`, `evidence[]` |

**双轨原则**（见 M1 §5.3）：
- **所有 L1 事件必填 `subject`**（统一索引入口）
- **语义字段**（`artifact_urn` / `task_urn` / `stage_urn` / `new_artifact_urn` / `drift_event_urn` / `drifting_artifact_urn`）与 `subject` **必须指向同一 URN**，由工具校验（`drift_event_urn` 由 `m6_evolution_kernel_alignment@v1` S1 纳入 · 替代 M4 时期占位的 `target_task_urn`）

**禁止扩展**：上述 10 类覆盖 piao-pipeline 所有 L1 语义。如果某个场景"感觉"需要新类型，请先看能否用 L2 事件 + 合适的 visibility 表达，或者用 `task.failed` 的 `failure_reason` 扩展。**实在不够用** → 提 kernel rev 升降。

> **注记**（`m6_evolution_kernel_alignment@v1` S1）：上表 `evolution.scanned` 的字段在 draft 阶段经历过一次**语义字段精化**（`target_task_urn, extracted_memory_ids[]` → `drift_event_urn, scope_urn, scanned_drifts[], decision_log[]`）· **L1 事件类型数量保持 10 类不变 · 非扩展**。这一精化不构成 "L1 事件枚举扩展" · 因此 draft 阶段可原地修订（见 `01 §10.1` · M5 先例参见 `05-drift-propagation.md §3.2 T5` drift 两写落地）· 后续若确有新增 L1 类型需求仍须走 kernel rev 升降（参见 `06-evolution-model.md §6.7 A1` 的 L1 事件配额上限约束）。

### 3.2 L1 事件通用骨架

所有 L1 事件必须满足：

```yaml
event_id: <域>-<YYMMDDHHmmss>-<6位hash>     # 见 §4 和 M1 §5
event_type: <枚举，见 §3.1>
event_layer: L1                            # 强制字段
emitted_at: <ISO8601 with timezone>
emitted_by: <actor URN>
subject: <URN>                             # 强制；事件主语实体，统一索引入口（见 M1 §5.3）
                                           # ↑ 以上 6 字段所有 L1 事件必填

# 以下字段按 event_type 不同而不同，每类的必填字段见 §3.1 表格
# 语义字段必须与 subject 指向同一 URN（工具校验）
```

**可选字段约定**（R13 引入）：

| 字段名 | 出现在哪些事件 | 语义 | 校验规则 |
|-------|-------------|-----|---------|
| `related_taskdag_urn` | `stage.entered` / `stage.exited` | 该 stage 转换与某个 taskdag 的执行生命周期绑定（典型：一个 stage 对应一个 taskdag 的完整跑完） | 若填写，字段值必须是合法 URN 且 kind=taskdag；kernel 不校验 taskdag 与 stage 的业务绑定关系（业务层 adapter 自行约束） |

**`related_taskdag_urn` 的下游消费者**：`04-version-snapshot.md §3.3 scope_kind=taskdag` 的 snapshot 触发依赖该字段——M4 工具链从 `stage.entered` / `stage.exited` 事件读取 `related_taskdag_urn` 并据此产出 taskdag 级 snapshot（对应 review Q9 推荐方案 c）。若未填写该字段，scope_kind=taskdag 的 snapshot 不会被自动触发（业务层可改走 L2 执行事件 + 自定义调度来补位，但不走 kernel 契约）。

### 3.3 L1 append-only 的硬约束

- **写入后永不修改，永不删除**
- **归档不适用**：L1 事件即使距今 10 年也必须在线可查（可以冷存储，但不能丢）
- **"撤回"靠补偿事件**：发现 `artifact.published` 写错了，**不是**改那条事件，而是追加一条 `artifact.retracted` 引用它
- **工具实施**：`event-journal-append` 是唯一写入入口，拒绝任何 "update" / "delete" 调用

### 3.3.1 原子写入契约（R12 引入 · v1 draft 2026-04-19 由 `m5_drift_kernel_alignment@v1` S1 泛化）

**背景**：`04-version-snapshot.md §2.2` 的 snapshot 产出需要"写 snapshot artifact + 写 stage 事件 + 写 artifact.published 事件"三步原子；`05-drift-propagation.md §3.2 T5` 的 drift 产出需要"写 drift artifact + 写 `drift.detected` 事件"两步原子；普通 artifact 的"发布"同样涉及"写 artifact 文件 + 写 `artifact.published` 事件 + 更新 manifest"的多步原子语义。这类场景需要 kernel 在 §3.3 硬约束之下，补齐**N 条 L1 事件同批次写入**的原子性承诺。

**承诺 1 · N 条同 txn 语义**（v1 draft 修订 · 2026-04-19 · `m5_drift_kernel_alignment@v1` S1 · 路径 B R22）：

- `event-journal-append` 工具提供**"N 条 L1 事件同 txn"** 语义（N ≥ 1）：调用方可在一次调用中声明需同批次写入的 N 条 L1 事件
- kernel 对调用方的承诺：**要么 N 条全部成功落库并被后续读取可见；要么 N 条全部不生效**（对调用方呈现为原子）
- 事件间**无固定 type 约束**，调用方可按场景组合任意已登记的 L1 事件类型（§3.1 封板的 10 类枚举）
- v0.1 实现允许为"顺序写 + 失败回滚"（对 crash 场景通过 §3.3.1 承诺 2 的孤儿扫描兜底），不强制底层存储引擎的事务能力；N 越大回滚窗口越长，v0.1 对此不做上限承诺

**当前已知 N 值实例**（仅为描述当前已落地场景，**不构成 type 白名单约束**，未来新场景不需要修改本节）：

- **N=3 · snapshot 产出**：`artifact.published(snapshot)` + `stage.exited` / `stage.entered` + `artifact.published(其他 artifact)` —— 由 `04-version-snapshot.md §2.2` 触发
- **N=2 · drift 产出**：`artifact.published(drift)` + `drift.detected` —— 由 `05-drift-propagation.md §3.2 T5` 触发
- **N=1 · 普通 artifact 发布**：`artifact.published(任意 kind)` —— 退化为单事件 append，仍走 txn 语义（保持接口统一）
- **未来 M6 evolution 可能引入的 N≥4 组合**：届时不需修改本节，只需在派生文档（如 `06-evolution.md`）中声明各自的 N 值实例

**承诺 2 · 孤儿 artifact 的识别**：

- 若 txn 中途失败（crash 或手动中断），已写入的 artifact 文件可能尚未有对应的 `artifact.published` 事件
- 这种"写入但无 published 事件"的 artifact 即**孤儿**——不应被任何下游消费
- kernel 提供 `artifact-validate.sh --check-orphan` 接口：扫描 `pipeline-output/` 下所有 artifact，比对 manifest 与 L1 事件存在性，列出所有孤儿供人工或自动化补偿

**kernel 不承诺的部分**（留 M4 工具链 / M5 drift 层处理）：

- 孤儿 artifact 的补偿路径（回收 / 补写 published 事件 / 升 rev 重发）
- `--check-orphan` 的调用时机（commit 前 hook / CI 定时 / 手动触发）
- 底层存储引擎是否升级到真正事务（v0.2+ 可选）

**与 §3.3 append-only 的关系**：承诺 1 的"失败回滚"**只作用于未完成 commit 的 txn**；一旦 txn 提交成功，所有已写入的 L1 事件立刻进入 §3.3 的 append-only 保护范围，**不可撤回**。

---

## 4. 事件 ID 规则

### 4.1 格式（单一真源：M1 §5）

**事件 id 的完整定义见 M1 §5**。本节只复述关键点，以便本篇自包含：

```
<域>-<UTC的YYMMDDHHmmss>-<6位hash>
```

| 段 | 规则 |
|----|------|
| `<域>` | 7 选 1 固定枚举：`pipe` / `tdag` / `task` / `trace` / `evo` / `drift` / `gate` |
| `<UTC的YYMMDDHHmmss>` | UTC 时间的 12 位十进制表示（人肉可读） |
| `<6位hash>` | sha1(event_body 规范化后) 取前 6 位 hex |

**示例**：
```
task-260418115700-a3f2b1          ← 2026-04-18 UTC 11:57 的 task 事件
evo-260418141530-d7e1a5           ← 2026-04-18 UTC 14:15 的 evolution 事件
```

### 4.2 域如何映射到 event_type

| 域前缀 | 对应 event_type 命名空间（含 §3.1 的 L1 + L2 扩展） |
|--------|------|
| `pipe` | `pipeline.*` |
| `tdag` | `taskdag.*` |
| `task` | `task.*`, `artifact.*` |
| `trace` | `trace.*`, `verify.*` 等 L2 执行细粒度 |
| `evo` | `evolution.*` |
| `drift` | `drift.*` |
| `gate` | `gate.*`, `stage.*` |

### 4.3 碰撞处理

同 M1 §5.2：manifest 索引查重 → 撞了抛错让调用方重新生成，**禁止自动递增后缀**。

同秒内 6 位 hash 撞车概率 ≈ `2^-24`，单写者 append-only 场景下可忽略。

---

## 5. L2 事件：骨架 + adapter 扩展

### 5.1 L2 通用骨架

```yaml
event_id: <域>-<YYMMDDHHmmss>-<6位hash>    # 格式同 §4（UTC，6 位 hash）
event_type: <自定义，建议动词结构：task.step_log / verify.lint_failed>
event_layer: L2                            # 强制字段
emitted_at: <ISO8601>
emitted_by: <actor URN>
subject: <URN>                             # 强制；L2 的 subject 通常等于 parent_task_urn
parent_task_urn: <L2 必填；指向它所属的 task URN>
visibility: "mainline" | "detail"          # 可选；未填视为 "detail"
payload: <object; schema 由业务层自定>       # 扩展区
```

**强制字段**：`event_id`, `event_type`, `event_layer`, `emitted_at`, `emitted_by`, `subject`, `parent_task_urn`

**业务层可扩展**：`payload` 对象内任意字段；`event_type` 命名空间（建议 `<verb>.<object>`）

> **L2 的 subject 为什么也必填**：保持和 L1 一致的"按 URN 反查所有事件"能力。典型地 L2 的 subject = parent_task_urn，但如果某条 L2 明显是讲某个 artifact 的（例如 `verify.lint_failed` 讲某个具体文件），subject 可以指向 artifact URN，parent_task_urn 仍记录归属 task。

### 5.2 visibility 字段的语义

- **`mainline`**：dashboard 主线视图默认加载
- **`detail`**：展开 task 详情时才加载

**adapter 自愿原则**（你拍板过的 C2）：
- adapter **可以**打 `visibility`，不强制
- 未打标记的 L2 事件**默认 `detail`**（保守起见，不打扰主线视图）
- kernel **不提供**"主线事件类型白名单"这种集中配置——由 adapter 在自己的事件写入逻辑里自行决定

### 5.3 L2 的 append-only 与可归档

- **写入后不修改**（和 L1 一致）
- **允许归档**，见 §6 归档规则
- **归档 ≠ 删除**：归档只是把事件从热 journal 搬到 `archive-fs`，内容仍完整可读
- **禁止 compact**（你拍板过的决策）：不允许把多条 L2 合并成一条"摘要事件"

---

## 6. L2 事件归档规则

> **术语消歧**：本节讲的"归档"是**L2 事件归档**（从热 journal 搬到冷存储），与 M2 §6 的 artifact 生命周期无关——**artifact 没有 "archived" 状态**，过期的 artifact 走 `artifact.superseded` 或 `artifact.retracted`。

### 6.1 归档三条件

**一条 L2 事件可被归档，当且仅当它所属的 task 满足以下所有条件：**

1. **任务已终结**：存在 `task.finished` 或 `task.failed` L1 事件
2. **产物已固化**：该 task 产出的所有 artifact 都已 `artifact.published`（或被 `artifact.retracted`；不存在还挂在 draft 的产物）[^published-atomicity]
3. **经验已萃取**：存在针对该 task 的 `evolution.scanned` L1 事件

[^published-atomicity]: 本条仅查 `artifact.published` L1 事件存在性，依赖 `event-journal-append` 工具保证"事件写入"和"manifest 更新"的原子性（见 M4 工具链）。从 M1 §10.1 的定义看，published 的严格判定是 "manifest 收录 AND L1 事件写入"，但由于原子性保证，在归档器层面只查事件即可。

### 6.2 为什么三个条件都必须客观可查

| 条件 | 客观性来源 | 出错的代价 |
|------|----------|-----------|
| 1. 任务已终结 | 直接查 L1 `task.finished`/`task.failed` | 误判 → 归档了进行中 task 的 L2 → 当前 task 看不到自己的日志 |
| 2. 产物已固化 | 查 task 的 `produced_artifact_urns` 列表 + 每个 artifact 的 status | 误判 → artifact 还在 draft 就把 L2 归档 → 下次 draft → published 的 rev 升降找不到过程日志 |
| 3. 经验已萃取 | 查 `evolution.scanned` L1 事件 | 误判 → L2 归档了但经验没抽 → 永久丢失该 task 的经验学习机会 |

**关键设计**：三个条件全部是 **L1 事件的存在性查询**，不需要读 L2 原始数据，归档器性能极好。

### 6.3 evolution.scanned 的自由度

拍板确认过的 C3 方案（字段语义由 `m6_evolution_kernel_alignment@v1` S1 精化 · 以下措辞同步更新）：
- evolution 子系统**异步扫描**，不阻塞归档以外的任何链路
- 扫描产出 `evolution.scanned` L1 事件，字段 `scanned_drifts[]` **允许为空**（即"我扫过了，没发现值得纳入 scope 的 drift"）· `decision_log[]` 记录扫描过程的推理链（可空）
- **evolution 不保证每次产出 scope 变更，只保证"扫过"这件事本身被记录**（详见 `06-evolution-model.md §2.3 / §5.3`）

### 6.4 归档后的读端契约

- dashboard / trace-report 查询 L2 时，**看不到归档区别**：归档事件仍按 event_id 可查，只是响应慢一些
- evolution / drift **不读归档区**：这两个子系统的逻辑应该完全基于 L1，不依赖 L2 原始数据
- 归档的 L2 事件仍可被 audit 工具扫出，用于事后合规追溯

---

## 7. 分层加载视图（dashboard 契约）

### 7.1 两级视图

| 视图 | 加载的事件 | 用途 |
|------|----------|------|
| **主线视图**（默认） | 所有 L1 事件 + `visibility=mainline` 的 L2 事件 | 看 pipeline 整体走到哪、卡在哪 |
| **任务详情视图**（展开某 task） | 该 task 的所有 L2 事件（含 `visibility=detail`） | 深度排查单个 task 的执行细节 |

### 7.2 为什么视图不是 kernel 强制

dashboard 是 L_Surface 层的只读视图，**kernel 不规定"必须有几个视图"**。这里的 §7 只是给 adapter / dashboard 实现者一个**推荐模型**，避免每个 dashboard 各搞一套。

### 7.3 动态加载

> "展开 task 详情时才加载该 task 的 detail 事件" —— 这是**读端的查询策略**，不是 kernel 契约。kernel 只承诺"event-journal 支持按 `parent_task_urn` 索引查询"，具体什么时候查由 dashboard 决定。

---

## 8. 设计决策清单

### 8.1 已拍板（本篇固化）

| # | 决策 | 选择 | 理由 |
|---|------|------|------|
| 1 | 运行时分几层 | 4 层（Surface/Adapter/Kernel/Storage） | 业界验证过的模式，足够支撑迁移 + 演化场景 |
| 2 | 事件分几层 | 2 层（L1/L2） | 1 层会退化为数据沼泽，3 层过度设计 |
| 3 | L1 可扩展吗 | **不可**（10 类封板） | L1 是跨项目契约，扩展等同破坏契约 |
| 4 | L2 可扩展吗 | **骨架固定，payload 自由** | 留给业务层足够的灵活度 |
| 5 | 事件 id 格式 | `<域>-<UTC的YYMMDDHHmmss>-<6位hash>` | 人肉可读 + 时序友好 + grep 友好；UTC 保证跨机器一致（见 M1 §5） |
| 6 | 事件 subject 是否强制 | ✅ 强制（L1/L2 都要） | 统一索引入口；与按类型命名的语义字段"双轨"共存（见 M1 §5.3） |
| 7 | L2 可 compact 吗 | ❌ 禁止 | 保持 L1 语义纯粹，L2 不制造次级真相源 |
| 8 | L2 归档条件 | 三条件全 L1 客观可查 | 不引入主观字段，不依赖业务层诚信 |
| 9 | evolution 必须产出经验吗 | ❌ 允许空扫描 | 否则 evolution 会被迫"凑经验"污染知识库 |
| 10 | visibility 字段是否强制 | ❌ 业务层自愿 | 降低写入负担，默认 detail 安全保守 |
| 11 | L2 视图加载策略 | kernel 不管，推荐分层动态 | 视图属 Surface 层职责 |

### 8.2 Open Questions（留给 M4+）

| # | 议题 | 当前默认 | 何时必须决定 |
|---|------|---------|-------------|
| O1 | event-journal 的物理存储格式（JSONL / SQLite / 其他） | JSONL 扁平文件 | M4 工具链 |
| O2 | `event-journal-append` 的并发写入策略（单写者 / 多写者） | 单写者锁 | M4 工具链 |
| O3 | 归档区的物理位置（同仓库 / 外部 object store） | 同仓库 `archive-fs/` 子目录 | M4 工具链 |
| O4 | evolution 的扫描触发时机（task 完成即扫 / 定时批量扫） | 业务层自选 | M5 drift/evolution |
| O5 | L1 事件的 mass-query 索引（按 artifact_urn / 按 stage） | 在线扫 manifest，未建二级索引 | 观察到性能瓶颈时 |
| O6 | 事件 id 中 timestamp 的生成时钟（emitter 本地 UTC / journal 接收时 UTC） | 倾向 emitter UTC + 时钟漂移警告 | M4 工具链 |

### 8.3 前置契约（本篇依赖的上游决策）

- **身份模型**：`01-identity-model.md §1.1`（URN 格式，无 realm）、`§2`（kind 枚举）、`§5`（event_id 格式 + subject 双轨）、`§10.1`（published/draft 两态）
- **Artifact 模型**：`02-artifact-model.md §1.1`（front-matter 五字段）、`§4`（provenance 四元组，producer_event_id + producer_task_urn 双字段）、`§6`（artifact 生命周期对齐 L1 10 类事件）

> **关于 kind 枚举的变更**：分层模型**不**引入独立的 kind 枚举——所有 L1 事件 subject 字段引用的 kind 以 `01-identity-model.md §2.1` 为**单一真源**；kind 增删历史见 `01 §2.4 kind 枚举变更史`。本篇 §3.1 的 L1 事件类型与 kind 无一一对应关系（事件类型独立于 kind 演进，详见 §3.1 注释段）。

> **M1 期的两次 kind 删除对分层的影响**（记账，不修订本篇）：
> - 删除 `page` kind（合并到 `unit`）：影响 §3.1 中 `unit.*` 事件的 subject；现所有 UI 业务单元统一引用 `urn:piao:unit:...`
> - 删除 `event` kind：不影响分层，事件对象以 `event_id` 为一等公民，kind 维度的指代本来就多余
>
> 具体决议见 `_review/M1-final-decisions.md §1 决议 2`。

---

## 9. 验收标准

本篇通过 review 的必要条件：

1. ✅ 四层模型能完整回答"adapter 崩了 kernel 还能不能跑"（能，kernel 不依赖任何具体 adapter）
2. ✅ L1 10 类事件覆盖 prop_confirm 场景的所有关键节点（SPEC→PLAN→IMPLEMENT→VERIFY→ARCHIVE 每阶段至少对应一种 L1 事件）
3. ✅ 归档三条件不涉及任何 adapter 私有信息，纯靠 L1 事件存在性判定
4. ✅ 事件 id 在并发 ms 级碰撞场景下有明确处理流程（§4.3）
5. ✅ M4 工具链层拿着本篇可以直接开 `event-journal-append` / `archive-runner` 的实现

---

**本篇状态**：draft（M1 review 周期内，参见 `01-identity-model.md §10.1` 的 published/draft 契约，可原地修订）

**上游**：`01-identity-model.md@v1`, `02-artifact-model.md@v1`
**下游锚点**：M4 将基于本篇的 §3 L1 枚举、§5 L2 骨架、§6 归档规则实现 event-journal 工具链

---

## 10. rev_history

| rev | 发布时间 | 触发来源 | 变更摘要 |
|-----|---------|---------|---------|
| v1（draft） | 2026-04-18 17:30 | `urn:piao:task:m3:layered_architecture_draft` | 首版 draft；四层运行时模型（§1）、L1/L2 事件分层（§2）、L1 10 类枚举封板（§3.1）、事件 ID 规则（§4）、L2 骨架 + adapter 扩展（§5）、L2 归档三条件客观性（§6）、分层加载视图契约（§7）、设计决策清单（§8）、验收标准（§9） |
| v1（draft · 路径 B 原地修订） | 2026-04-19 01:30 | `urn:piao:proposal:kernel:m4_snapshot_kernel_alignment@v1 §4.1/§4.2` | draft 阶段原地修订（按 `01 §10.1` 不升 rev）：R12（新增 §3.3.1 原子写入契约：多事件同 txn 语义 + `--check-orphan` 接口声明）· R13（§3.1 `stage.entered/exited` 加可选 `related_taskdag_urn` 字段 + §3.2 骨架后补可选字段约定表）。两条均消化，作为 `04-version-snapshot.md` scope_kind=taskdag 触发与原子性承诺的 kernel 锚点 |
| v1（draft · 路径 B 原地修订 · M5） | 2026-04-19 14:30 | `urn:piao:proposal:kernel:m5_drift_kernel_alignment@v1 §4.1` | draft 阶段原地修订（按 `01 §10.1` 不升 rev）：R22（§3.3.1 承诺 1 从"多事件同 txn"列举式表述泛化为"N 条 L1 事件同 txn · N≥1 · 事件间无 type 约束 · 当前已知 N=3 snapshot 三写 / N=2 drift 两写 / N=1 普通 artifact 发布 · 列举不构成 type 白名单约束"）· 为 05-drift-propagation §3.2 T5 的 drift 两写场景提供 kernel 锚点 · 对未来 M6 evolution 的 N≥4 组合向上兼容（无需改 03） |
| v1（draft · 路径 B 原地修订 · M6） | 2026-04-19 20:30 | `urn:piao:proposal:kernel:m6_evolution_kernel_alignment@v1 §4.1 · S1` | draft 阶段原地修订（按 `01 §10.1` 不升 rev）：B1（§3.1 `evolution.scanned` 行语义字段精化 · `target_task_urn, extracted_memory_ids[]` → `drift_event_urn, scope_urn, scanned_drifts[], decision_log[]` · subject 从"task URN（被扫描的 task）"精化为"drift 事件 URN（被扫描的 `drift.detected` 事件）" · 对齐 `06-evolution-model.md §2.3 / §5.3` 实锁 schema）· §3.2 双轨原则语义字段枚举同步替换（`target_task_urn` → `drift_event_urn`）· §3.1 末段"禁止扩展"条后补注（`L1 类型数量保持 10 类不变 · 非枚举扩展 · 仅字段精化 · 对标 M5 05 §3.2 T5 drift 两写先例 · 后续新 L1 类型仍须走 kernel rev 升降 · 对接 06 §6.7 A1 L1 配额上限约束`）· §6.3 `evolution.scanned 的自由度` 章节连带修订（`extracted_memory_ids[] 允许为空` → `scanned_drifts[] 允许为空 · decision_log[] 记录扫描推理链`· 语义从"扫过但无经验"精化为"扫过但无 scope 变更"· 与 §3.1 表行字段对齐）。L1 事件类型枚举总数不变（仍为 10 类） |
