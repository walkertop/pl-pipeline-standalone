---
urn: urn:piao:spec:architecture:version_snapshot@v1
kind: spec
rev: v1.2
status: published
supersedes: null
produced_by: urn:piao:task:m5:version_snapshot_published
produced_at: 2026-04-18T23:55:00+08:00
published_at: 2026-04-19T14:35:00+08:00
upstream:
  - urn:piao:snapshot:kernel:m1_final_decisions@v1
  - urn:piao:snapshot:kernel:m4_final_decisions@v1
  - urn:piao:artifact:kernel:m4_snapshot_draft_review@v1
  - urn:piao:proposal:kernel:m4_snapshot_kernel_alignment@v1
  - urn:piao:artifact:kernel:m4_toolchain_review@v1
  - urn:piao:artifact:kernel:m5_drift_draft_review@v1
  - urn:piao:proposal:kernel:m5_drift_kernel_alignment@v1
  - urn:piao:spec:architecture:layered_architecture@v1
  - urn:piao:proposal:kernel:post_m1_kickoff@v1
---

# kernel · 04 Version Snapshot Model

> 系统**在某一刻的事实是什么**——不是"此刻 journal 里有哪些事件"（那是 L1 的活流），也不是"此刻 manifest 指向的文件内容"（那是可继续漂移的当下），而是**被冻结并赋予 URN 的一个静态截面**，下游任何模型（drift / evolution / audit）都以此为唯一真相源做差分。
>
> M1（身份）回答"实体叫什么"，M2（artifact）回答"实体长什么样"，M3（事件分层）回答"实体之间怎么流动"。
> **M4 回答：怎么把一段流动的历史，封冻成一张可被 O(1) 对比的照片。**

---

## 0. 定位

本篇回答 `_review/post-m1-kickoff.md §4` 锁定的**四个必答问题**：

1. **何时打快照**：什么事件触发产出一个 snapshot？是否只有阶段边界，还是允许手动触发？
2. **快照装什么**：是 L1 event 指针（轻）还是完整 artifact 集合（重）？如何折中？
3. **快照如何寻址**：`urn:piao:snapshot:<scope>:<name>@v<rev>` 的 scope 语义——按 unit？按 stage？按 taskdag 实例？按 adapter？按 kernel？
4. **快照与 drift 的接口**：drift engine 读两个 snapshot 时，如何**在 O(1) 内识别变化的 artifact 集合**？

**本篇不回答**（留给下游 M 阶段）：
- drift 传播算法本身（M5 `05-drift-propagation.md`）
- snapshot 的 GC / 冷归档策略（M7 之后）
- snapshot 的可视化 diff 渲染（工具链层）

**设计铁律**：

> **snapshot 只做"冻结"，不做"推断"**。任何下游需要的计算（差分、传播、补偿）都基于 snapshot 做，snapshot 本身不承载计算逻辑。

---

## 1. snapshot 的本质

### 1.1 一句话定义

> **snapshot = 一个 URN 身份 + 一个有序 artifact URN 集合 + 产生此 snapshot 的事件标识。**

三要素缺一不可：

| 要素 | 作用 | 对应契约 |
|-----|------|---------|
| **自身 URN** | snapshot 是 artifact（有 `kind: snapshot`）；可被事件引用、可被后续 snapshot 在 supersedes 链中指向 | `01 §1.1` + `01 §2.1` |
| **冻结范围** | 本 snapshot 覆盖的 artifact URN 列表 + 各自的 `sha256`（双轨：URN 标身份，sha256 标当时的内容指纹） | `02 §3.2` |
| **产生事件** | 由哪条 L1 事件触发本 snapshot 的产出（`stage.entered` / `stage.exited` / 手动触发的 `task.finished`） | `03 §3.1` + `03 §3.2` |

**为什么不是"指向 journal 某个 offset"**：
- event journal 是 **append-only 的流水**，`offset` 只在单一物理 journal 实例中有意义；跨机器、跨仓库（未来多仓协作）时无效
- 而 **URN 集合 + sha256 双轨**是**与物理存储无关**的事实锚点，谁都可以按 URN 重新解析、按 sha256 重新校验

### 1.2 snapshot 不是什么

为避免常见误用：

| 误解 | 纠正 |
|-----|-----|
| "snapshot 是 journal 的 checkpoint" | **不是**。snapshot 覆盖的是**artifact 状态**，不是事件流位置；事件流位置靠 event_id 单调性本身自证 |
| "snapshot 可以被修改" | **不能**。一旦产出，`status: published` 即永久冻结；要修正只能新发 `@v<N+1>` 并在新 snapshot 的 front-matter `supersedes` 指向旧版（规则同 `01 §10.1` published 契约） |
| "snapshot 是 backup" | **不是**。snapshot 不复制 artifact 内容，只记录 URN + sha256；若某 artifact 物理文件丢失，snapshot 本身无法恢复它（需要靠 VCS / 冷备） |
| "每次 task 结束都要打 snapshot" | **否**。task 粒度远细于 snapshot 应有粒度（见 §2 触发条件） |

---

## 2. 四问之一 · 何时打快照

### 2.1 触发条件的分层

snapshot 的触发条件**分三层**，按严格度从高到低：

| 层 | 触发源 | 是否强制 | 语义 |
|----|-------|--------|-----|
| **L1 · 阶段边界** | `stage.entered` / `stage.exited` 事件 | ✅ 强制 | 每次 pipeline 阶段切换必须打 snapshot（见 `03 §3.1` 该两类事件携带 `entry_snapshot_urn` / `exit_snapshot_urn` 字段——快照 URN 是事件 schema 的一部分） |
| **L2 · 里程碑** | `kind=snapshot` 的 artifact 由 kernel 工具主动产出（非阶段切换时） | ⚠️ 按需 | 用于锁定"本次迭代的决议"（如 `urn:piao:snapshot:kernel:m1_final_decisions@v1`）；不产出不违规，但一旦产出即受 `published` 契约约束 |
| **L3 · 手动触发** | 由 adapter / 人肉通过 `task.finished` L1 事件携带 `requested_snapshot: true` 字段显式请求 | ⚠️ 自治 | adapter 自己的 audit / 调试需要，kernel 不干涉 |

**核心约束**：

- **L1 阶段边界是唯一强制触发点**。这保证了 pipeline 的**每次阶段切换都有可追溯的"前后状态"**，drift 引擎（M5）依此做阶段维度的漂移检测。
- **L2 / L3 的触发不得破坏 L1 的时序完整性**——即 L2 / L3 产出的 snapshot 不能在同一 stage 内覆盖 L1 snapshot 的 URN。

### 2.2 阶段边界 snapshot 的产出契约

每次 `stage.entered` / `stage.exited` 事件被写入时，**同一 task 必须同时产出一个 snapshot artifact**：

```
写入顺序（同一 atomic 操作）：
  1. 产出 snapshot artifact（按 §3 的 schema）→ 写入 manifest
  2. 写入 stage.entered / stage.exited L1 事件，其 entry_snapshot_urn / exit_snapshot_urn 字段指向步骤 1 的 URN
  3. 写入 artifact.published L1 事件标记 snapshot 本身发布
```

**原子性要求**：步骤 1–3 要么全部成功要么全部回滚。实施由 `event-journal-append`（M4 工具链）保证——对应的 kernel 承诺见 `03 §3.3.1 原子写入契约`（承诺 1 · 多事件同 txn 语义；承诺 2 · `artifact-validate.sh --check-orphan` 孤儿扫描接口）。

**stage 事件语义字段的绑定规则**（v1.1 新增 · R13 反向对接）：当本节的产出契约命中 `frozen_scope.scope_kind = taskdag`（见 §3.3）时，步骤 2 写入的 `stage.entered` / `stage.exited` 事件的可选字段 `related_taskdag_urn`（见 `03 §3.1/§3.2`）**必须填写且等于** `frozen_scope.scope_ref`。理由：scope_kind=taskdag 的 snapshot 触发本身依赖 taskdag 的生命周期事件，若该字段缺失则无法通过 `event-journal-query` 将 stage 事件与目标 taskdag 精确关联（会退化为全量扫描 L2 task.* 事件，成本不可接受）。其余 scope_kind（unit / stage / adapter / kernel）不对该字段作强制约束，调用方可按需填写或留空。

**`event_id` 预留契约**（对齐 `02 §4.3` provenance 填充机制；v1.1 由 `02 §4.3.1` 显式点名反向对接，见 `urn:piao:proposal:kernel:m4_snapshot_kernel_alignment@v1 §4.4` / review R16）：步骤 1 的 snapshot front-matter 字段 `produced_by.event_id` 需引用步骤 3 才写入的 `artifact.published` 事件——这是"先有鸡后有蛋"的典型，规定走 `02 §4.3` / `02 §4.3.1` 的**预留 id**流程：
- 工具在进入原子操作前先生成 event_id（格式 `<prefix>-YYMMDDHHmmss-<rand6>`，见 `01 §1.1`）
- 将该 id 预写入 snapshot front-matter 的 `produced_by.event_id`（步骤 1）
- 再按该预留 id 写入步骤 2、3 的 L1 事件
- 若原子操作任一步失败，整批 id 作废（snapshot 进入"孤儿"状态，见下）

snapshot 产出不发明新的 id 分配机制——完全复用 `02 §4.3` 已有契约。

**容错**：若步骤 2 或 3 失败，步骤 1 产出的 snapshot artifact 即"孤儿"——不应被任何事件引用。孤儿的识别路径统一走 `03 §3.3.1 承诺 2`：调用 `artifact-validate.sh --check-orphan` 扫描 `pipeline-output/` 下所有 artifact 与 L1 事件存在性，列出孤儿供人工或自动化补偿。具体补偿路径（回收 / 补写 published 事件 / 升 rev 重发）留 M5 drift 层定义。

### 2.3 非触发点（明确不打 snapshot）

为防止 snapshot 通胀（M4 最大设计风险之一），以下时机**不打** snapshot：

| 时机 | 理由 |
|-----|-----|
| 每次 `task.started` / `task.finished` | task 粒度远细于 snapshot 应有粒度；artifact 的增量状态靠 L1 artifact 事件追踪即可 |
| 每次 artifact 升 rev（`artifact.superseded`）| rev 升降本身就是强的状态变化信号，不需要再打 snapshot 冗余记录 |
| 每次 `evolution.scanned` | evolution 是 L2 关心的范畴，不触发 snapshot 级的状态冻结 |
| 每次 `drift.detected` | drift 是 snapshot 的**消费者**，不是触发源；让 drift 触发 snapshot 会构成循环依赖 |

### 2.4 触发判定的客观性

snapshot 的触发 **100% 基于 L1 事件存在性**，不依赖任何业务层信号。这与 `03 §6.2` 的归档三条件同源——**客观可查、工具可验、不需要业务层诚信**。

---

## 3. 四问之二 · 快照装什么

### 3.1 三种方案权衡

| 方案 | 装什么 | 优点 | 缺点 |
|-----|-------|------|-----|
| **A · 纯 event 指针** | 只装 `last_event_id` + 各 artifact_urn 的最新 event_id | 极轻；几十字节 | drift 查询时必须回放 journal 才能知道当时的 artifact 状态，O(N 事件数) |
| **B · 完整 artifact 内容** | 装每个 artifact 的完整内容 | drift 完全自给自足 | 一次 snapshot 数 MB–数百 MB，短迭代内迅速通胀 |
| **C · URN 集合 + sha256 双轨**（本篇选择） | 装 `artifact_urn` + `content_sha256` 的有序列表 + stage 元数据 | drift 可在 O(1) 内识别"哪些 artifact sha256 变了"；单 snapshot 约 KB 级 | 需要依赖 manifest + 物理文件仍然可解析（即 artifact 文件不得被物理删除） |

**选择 C 的决定性理由**：

- piao-pipeline 的 artifact **不删除只升 rev**（见 `02 §6`）——C 方案依赖的"物理文件可解析"这个前提**已被既有契约兜底**
- B 方案的"完全自给自足"是伪需求——drift 并不需要 artifact 的**内容**，只需要**"变没变"**（变了由后续 drift 算法按 URN 去解析最新内容）
- C 方案的 snapshot 体积控制在 KB 级，允许高频打快照也不会把仓库撑爆

### 3.2 snapshot 的 front-matter 与 body schema

**front-matter**（复用 `02 §1.1` 五要素 + snapshot 特化字段）：

```yaml
---
urn: urn:piao:snapshot:<scope>:<name>@v<rev>
kind: snapshot
artifact_type: snapshot          # 对齐 02 §2.1 kind→artifact_type 映射；允许更细化为 snapshot.<subtype>（如 snapshot.stage_entered），subtype 由 adapter 自治，但必须以 "snapshot." 为前缀
rev: v1
status: published                # snapshot 不存在 draft 阶段（产出即 published）
supersedes: null | urn:piao:snapshot:...@v<rev-1>
schema_version: 1.0              # 本篇 §3 schema 的版本
produced_by:
  actor: <actor URN>
  task_urn: urn:piao:task:...
  event_id: <L1 事件 id，形如 task-YYMMDDHHmmss-xxxxxx>
  trigger_event_type: stage.entered | stage.exited | task.finished   # 触发源，见 §2.1
produced_at: <ISO8601>
frozen_scope:                    # 本 snapshot 覆盖的 scope 语义声明
  scope_kind: unit | stage | taskdag | adapter | kernel   # 见 §4
  scope_ref: <URN，指向被 snapshot 的单元>
content_sha256: ""               # 由 artifact-validate.sh 填入
---
```

**body**：一张有序 artifact 冻结表，每行一个 artifact 的 URN + sha256：

```yaml
frozen_artifacts:                # ← 必须按 artifact_urn 字典序排列，保证 sha256 稳定
  - artifact_urn: urn:piao:artifact:<unit>:structured_spec@v1
    content_sha256: "abc123..."
    producer_event_id: task-260418055700-a3f2b1    # artifact 当时的最新产出事件
    producer_task_urn: urn:piao:task:<unit>/dag:t_03
    artifact_type: spec.structured                 # 冗余记录，便于 drift 按类型聚类
  - artifact_urn: urn:piao:artifact:<unit>:taskdag@v1
    content_sha256: "def456..."
    producer_event_id: task-260418060000-b4e2c2
    producer_task_urn: urn:piao:task:<unit>/dag:t_04
    artifact_type: plan.taskdag
  # ... 按字典序依次
```

**排序约束**（关键）：
- `frozen_artifacts` **必须**按 `artifact_urn` 字典序排序
- 原因：snapshot 自身的 `content_sha256` 由该 body 的规范化字节流计算，不排序会导致同样内容的 snapshot 产出不同 sha（破坏 §5 的 drift 接口）

#### 3.2.1 `content_sha256` 的规范化规则

snapshot 的 `content_sha256` 不是对整个 markdown 文件取哈希，而是对**被规范化后的 body 字节流**取哈希。这是 §5 `snapshot_diff` 算子"同样内容必得同样 sha"可重复性的前提。

**规范化输入**：仅 `frozen_artifacts` 列表（front-matter 不参与；正文散文亦不参与）。

**规范化步骤**（执行方：`artifact-validate.sh --snapshot`）：

1. 解析 markdown 中的 `frozen_artifacts:` YAML 块为纯数据结构
2. 对每个条目，保留且仅保留以下五个 key（多余 key 丢弃，缺失必填 key 报错）：
   - `artifact_urn`（必填）
   - `content_sha256`（必填，小写 hex）
   - `producer_event_id`（必填）
   - `producer_task_urn`（必填）
   - `artifact_type`（必填，冗余记录，允许 `02 §2.1` 映射表中的任意合法值）
3. 条目按 `artifact_urn` 字典序排序（UTF-8 字节序，`01 §4.4` snake_case 天然稳定）
4. 输出 canonical YAML：
   - key 顺序固定按上述 1→5
   - 字符串一律双引号包裹
   - 数值无前导零
   - 每行结尾 `\n`，文件末尾**恰好一个** `\n`
   - 无注释、无空行、无 tab（统一两空格缩进）
5. 对 canonical YAML 的 UTF-8 字节流执行 `SHA-256`，小写 hex 输出

**契约**：两个 snapshot 若 `frozen_artifacts` 的规范化结果逐字节相同，则 `content_sha256` 必相同。front-matter 中 `produced_at` / `event_id` 等随产出变动的字段**不影响** sha——这保证"同一 scope_ref 下两次实质无变化的冻结可以被 dedup 识别"。

**实施位置**：本规则由 `scripts/artifact-validate.sh --snapshot` 在写入 `content_sha256` 字段前执行（尚未实现，由 M4 工具链落地）；kernel 只承诺契约，不承诺实现。

#### 3.2.2 为何 snapshot 不需要 `depends_on`

常规 artifact 的 front-matter 带 `depends_on` 字段（见 `02 §5.1`）表达 lineage——"我产出时依赖这些上游 artifact"。但 snapshot **不使用** `depends_on`，理由：

| 角度 | 常规 artifact | snapshot |
|-----|------------|---------|
| `depends_on` 语义 | lineage：产出时依赖的上游 | — |
| `frozen_artifacts` 语义 | — | 冻结：被我囊括的全集 |
| 两者关系 | 不重叠 | **snapshot 的 `frozen_artifacts` 天然承载 lineage 角色**（被冻结的即被依赖的） |

若在 snapshot 上同时维护 `depends_on` 与 `frozen_artifacts`，两者内容在绝大多数情形下完全重叠——**冗余会引入不一致的风险**（工具升级时漏改其中一份即导致 lineage 错乱）。

因此 kernel 规定：

- **snapshot 的 front-matter 不写 `depends_on`**（若写了，`artifact-validate.sh` 报 warning 并忽略）
- **lineage 查询器（见 `02 §5.3`）遇到 `kind: snapshot` 的 artifact 时，特化地将 `frozen_artifacts` 中每一条的 `artifact_urn` 作为 `depends_on` 的等价替身返回**

该特化在 `02 §5.3.1`（v1.2 新增，由 `urn:piao:proposal:kernel:m4_snapshot_kernel_alignment@v1 §4.5` 落地，对应 review R15）已显式点名并配发工具实施方要求——**本锚点已由 02 @v1.2 反向对接完毕**，04 与 02 在该特化上形成双向可追溯。本篇 §3.2.2 保留接口声明职责，供调用方就近查阅。

#### 3.2.3 canonical YAML 通用工具实施建议（v1.2 新增）

**合并来源**：本小节同时落地两条路径 A 遗留债——`m5-drift-draft-review.md @v1 §3.2 R21`（drift content_sha256 实施建议）与 `m4-toolchain-review @v1 §2.5 T5`（snapshot front-matter key 正则）。合并入此的动机：04 snapshot + 05 drift 两套 canonical YAML 实施路径应统一，避免工具链两套实现漂移。

**适用范围**：本小节的承诺适用于**所有**基于 canonical YAML 计算 `content_sha256` 的派生 artifact 类型（当前已知：`kind=snapshot` 的 frozen_artifacts · `kind=drift` 的 propagation_record · 未来 M6 evolution 可能引入的机器产物）。§3.2.1 是"snapshot 专用的五步规范化"，本 §3.2.3 是"通用工具契约"，两者不冲突——§3.2.1 可视为本 §3.2.3 在 snapshot 场景下的特化实例。

**承诺 1 · key 正则**：参与 canonical YAML 规范化的 front-matter key 必须匹配正则 `^[a-z_][a-z_0-9]*$`（小写字母或下划线开头 · 后续字符限于小写字母/下划线/数字）。不匹配该正则的 key 一律视为"非规范化 key"——**不参与** `content_sha256` 计算（即便同名出现在 front-matter 中亦被跳过）。

- **适用范围澄清**：本正则仅约束**参与规范化的 front-matter key**。kernel 文档（如 01/02）若无 YAML front-matter · 不在本正则的适用范围
- **S0 预检已确认**：现有 kernel front-matter（03/04/05 + `_review/` 13 个 artifact）全部采用 snake_case · 本正则落地零破坏（见 `m5_drift_kernel_alignment@v1 §3 S0` 预检结果）

**承诺 2 · 正向白名单 `pick_fields`**：工具实施采用**正向白名单**而非反向黑名单——

```
canonical_yaml( pick_fields( front_matter, KEY_ORDER ) )
```

- `KEY_ORDER` 为**按派生类型声明的**正向字段清单（类型特定 · 通过 `SHA_WHITELIST` 声明范式注册 · 见承诺 3）
- `pick_fields` 只保留在 `KEY_ORDER` 中显式列出的 key · 未列出的 key 一律丢弃（fail-safe 默认 · 新增无关字段不触发 sha 变动）
- 该模式确保"实施方忘记声明排除字段"不会泄露未规范化数据进 sha 计算
- 对 snapshot 场景：`KEY_ORDER = [artifact_urn, content_sha256, producer_event_id, producer_task_urn, artifact_type]`（即 §3.2.1 步骤 2 的五字段）· §3.2.1 是本承诺的 snapshot 特化实例

**承诺 3 · `SHA_WHITELIST` 声明范式**：复用本工具链的派生 artifact 类型应通过 `SHA_WHITELIST` 声明各自的字段白名单清单——

```yaml
# 派生类型（在 02 §2.2 派生类型注册表中声明）
artifact_type: drift.propagation_record
sha_whitelist:            # v1.2 起 02 §2.2 派生注册 schema 的可选扩展字段
  - field_1
  - field_2
  # ...
```

- `SHA_WHITELIST` 的宿主：优先落在 `02 §2.2` 派生类型注册的 schema 中（作为该类型的固有属性 · 所有该类型的实体共享同一清单）
- 调用方（`scripts/artifact-validate.sh --snapshot` / 未来的 `scripts/piao-drift-compute.sh` 等）在执行规范化前从派生注册表查 `SHA_WHITELIST` · 再喂给 `pick_fields`
- 04 snapshot 的 `KEY_ORDER` 是 `SHA_WHITELIST` 的特例——可视为 snapshot 类型的 `SHA_WHITELIST` 已于 v1.1 固化在 §3.2.1 步骤 2

**复用锚点**：

- **首个复用案例**：`05-drift-propagation.md @v1 §2.5` 正是本小节的首个复用案例 —— drift 的 content_sha256 按本承诺 1/2/3 实施。05 的 `SHA_WHITELIST` 在其 §2.5 声明（六字段正向白名单）· 本小节提供 kernel 层的契约锚点
- **M6 evolution 未来产物**：future evolution kind 若引入机器产出（如 `evolution.gap_report`）· 其 content_sha256 应沿用本小节 + 在 02 §2.2 声明自己的 `SHA_WHITELIST`
- **反向可回引**：05 §10 前置契约表新增 `04 §3.2.3` 一行（由 `m5_drift_kernel_alignment@v1 §4.6 / S5` 同步落地）

**kernel 不承诺的部分**（留工具链层决定）：

- 具体哈希算法实现（sha256 库版本 / 批处理 vs 流式）· 各语言绑定（bash / python / kotlin）
- canonical YAML 工具的性能优化（pool / 缓存）
- `SHA_WHITELIST` 的运维与审计（注册表版本管理 / 变更审批流程）—— 这些由 02 §2.2 派生注册表的通用 schema 管理机制覆盖

### 3.3 frozen_scope 的 scope_kind 枚举

`frozen_scope.scope_kind` 值域**封板**（不可扩展，同 `03 §3.1` L1 事件封板原则）：

| scope_kind | 含义 | scope_ref 指向 | 典型触发 |
|-----------|------|--------------|---------|
| `unit` | 一个业务单元在某一时刻的所有 artifact | `urn:piao:unit:<name>` | `stage.entered` / `stage.exited` 阶段事件（单元级 pipeline） |
| `stage` | 一个 pipeline 阶段的所有 artifact（跨多个 unit，如全局 VERIFY 阶段） | `urn:piao:stage:<stage_name>` | 全局阶段事件 |
| `taskdag` | 一个 taskdag 实例执行过程的所有 artifact | `urn:piao:taskdag:<unit>:<dag_name>@<rev>` | taskdag 完整执行完（所有终止 task 都有 `task.finished` / `task.failed`）；触发依赖 `03 §3.1/§3.2` `stage.*` 事件的可选字段 `related_taskdag_urn`（v1.1 新增规则：本 scope_kind 下该字段必填，见 §2.2） |
| `adapter` | 某个 adapter 自身资产（charter / task-types 等）在某一时刻的冻结 | `urn:piao:artifact:adapter/<name>:...`（集合，隐式） | adapter 小版本发布节点 |
| `kernel` | kernel 文档集在某一时刻的决议冻结 | `urn:piao:artifact:kernel:...`（集合，隐式） | M 阶段定稿节点（如 `m1_final_decisions@v1`） |

**为什么要把 scope_kind 封板**：
- drift 引擎需要按 scope_kind 分类选择比较策略——若任意 adapter 能新增 scope_kind，drift 引擎就得做场景适配，违反 `07 §1` 的 kernel 纯度原则
- scope_kind 封板后，adapter 仍可通过 `scope_ref` 的 URN scope 段表达业务语义，表达力不减

### 3.4 一个**具体的最小 snapshot 示例**

```yaml
---
urn: urn:piao:snapshot:prop_confirm:plan_entered@v1
kind: snapshot
artifact_type: snapshot
rev: v1
status: published
supersedes: null
schema_version: 1.0
produced_by:
  actor: agent:pipeline-orchestrator
  task_urn: urn:piao:task:prop_confirm/dag:t_stage_plan_entered
  event_id: gate-260418140000-abc001
  trigger_event_type: stage.entered
produced_at: 2026-04-18T14:00:00+08:00
frozen_scope:
  scope_kind: unit
  scope_ref: urn:piao:unit:prop_confirm
content_sha256: "<由校验器写入>"
---

# snapshot · prop_confirm · plan_entered

frozen_artifacts:
  - artifact_urn: urn:piao:artifact:prop_confirm:prd@v1
    content_sha256: "1a2b3c..."
    producer_event_id: task-260418055500-a3f2b1
    producer_task_urn: urn:piao:task:prop_confirm/dag:t_01
    artifact_type: spec
  - artifact_urn: urn:piao:artifact:prop_confirm:structured_spec@v1
    content_sha256: "4d5e6f..."
    producer_event_id: task-260418055700-b4e2c2
    producer_task_urn: urn:piao:task:prop_confirm/dag:t_03
    artifact_type: spec.structured
```

该 snapshot **体积 < 1 KB**，按 §5 可被 O(1) diff。

---

## 4. 四问之三 · 快照如何寻址

### 4.1 URN 语义

snapshot 的 URN 严格遵循 `01 §1.1` grammar：

```
urn:piao:snapshot:<scope>:<name>@v<rev>
```

**`<scope>` 段的选用规则**（与 §3.3 `scope_kind` 一一对应）：

| scope_kind | `<scope>` 段 | `<name>` 段 | 完整示例 |
|-----------|------------|-----------|---------|
| `unit` | 业务单元名 | 触发事件语义名 | `urn:piao:snapshot:prop_confirm:plan_entered@v1` |
| `stage` | 阶段名（属 kernel 封板的六阶段） | 阶段事件语义名 | `urn:piao:snapshot:verify:global_verify_done@v1` |
| `taskdag` | `<unit>:<dag_name>` 两段 | taskdag 终止语义名 | `urn:piao:snapshot:prop_confirm/dag:main_done@v1` |
| `adapter` | `adapter/<adapter_name>`（见 `01 §3.4`）| adapter 自治命名 | `urn:piao:snapshot:adapter/frontend_migration:charter_v1_frozen@v1` |
| `kernel` | `kernel` | kernel 定稿语义名 | `urn:piao:snapshot:kernel:m1_final_decisions@v1` |

### 4.2 `@<rev>` 的升降规则

- **首次产出某个语义的 snapshot**（即 `<scope>:<name>` 前无发布）→ `@v1`
- **同 `<scope>:<name>` 再次冻结**（即同一触发点再次发生，如 prop_confirm 走完一次完整 pipeline 后重新进入 plan 阶段）→ 升为 `@v2`，旧版通过 `supersedes: urn:piao:snapshot:...@v1` 指向
- **snapshot 不做次版**（如 `@v1.1`）：snapshot 只有"相同触发语义的第 N 次冻结"，无"补丁式小升"语义

### 4.3 命名风格

- `<scope>` 和 `<name>` 遵循 `01 §4.4` snake_case 约定
- `<name>` 建议使用**动词过去分词**（表示"发生后冻结"）：`plan_entered` / `main_done` / `verify_passed` / `final_decisions`
- **禁止**在 `<name>` 中出现时间戳（时间信息由 `produced_at` 承载，URN 不冗余）

### 4.4 反模式

| 反模式 | 为什么错 |
|-------|--------|
| `urn:piao:snapshot::global@v1`（scope 为空） | 违反 `01 §1.1` grammar |
| `urn:piao:snapshot:prop_confirm:20260418140000@v1` | 时间戳不是语义，违反 §4.3 |
| `urn:piao:snapshot:adapter/frontend_migration/charter:frozen@v1`（scope 过深） | 超过 `01 §2.1` scope ≤ 4 层（理论可以但强烈不建议），adapter 自身资产建议拍扁到 `adapter/<name>` 单段 |
| 同一 `<scope>:<name>` 产出多个 `@v1`（非 supersedes 关系） | 破坏 URN 唯一性；manifest 冲突 |

---

## 5. 四问之四 · 快照与 drift 的接口

### 5.1 kernel 承诺的 snapshot diff 算子

kernel 必须提供（`scripts/snapshot-diff.sh`，M4 工具链实现）：

```
snapshot_diff(old_urn: URN, new_urn: URN) → DiffReport {
  added: List<artifact_urn>                # 只在 new 中存在
  removed: List<artifact_urn>              # 只在 old 中存在
  modified: List<{
    artifact_urn,
    old_sha256, new_sha256,
    old_producer_event_id, new_producer_event_id
  }>                                       # URN 相同但 sha256 不同
  unchanged_count: int                     # URN + sha256 都相同的数量（省略明细节省体积）
}
```

**v1.2 新增 · `sha_changed` 作为 `modified` 的 alias**（`m5_drift_kernel_alignment@v1 §4.3 R24` 落地）：

- snapshot_diff 输出在 v1.2 起新增 `sha_changed` 字段作为 `modified` 的 alias（**两字段类型 / 语义 / 列表内容完全一致 · 值必须同步**）
- 新实施的 04 消费方（含 `05-drift-propagation.md @v1.1 §2.4` 对偶表 / 未来 M6 evolution 的 drift 消费）**应优先使用 `sha_changed`**；`modified` 保留为向下兼容 alias
- 工具输出层面：`snapshot-diff.sh` 的 JSON 输出**同时**写入 `modified` 和 `sha_changed` 两字段（值相同 · 非 xor 二选一）· 消费方任选读一个即可
- 向下兼容承诺：v1.2 起**至少保留两个小版本周期**（v1.2 + v1.3）同时输出双名；v1.4 起允许工具层面只输出 `sha_changed`（但本 §5.1 字段表仍保留 `modified` 文档条目供查阅 · 字段名不会从 kernel 契约中删除）
- 字段类型 / 必填性 / 列表内容 / 排序规则**全部继承** `modified` 原定义 · v1.2 除"新增 alias"外**无其它语义变化**

**复杂度契约**：

| 步骤 | 复杂度 | 依据 |
|-----|------|------|
| 读取两个 snapshot 的 `frozen_artifacts` | O(N₁ + N₂) I/O，N 为 artifact 数 | 单文件 KB 级 |
| 求 added / removed / modified | O(N₁ + N₂) 比较 | **因 §3.2 强制字典序**，单趟归并扫描即可 |
| **总体** | **O(N) 且常数极小** | 满足 post-m1-kickoff §4 的"O(1) 识别"承诺（按实际数据量计算，KB 级扫描在毫秒级） |

> **关于"O(1)"的严格表述**：post-m1-kickoff §4 要求"O(1) 内识别哪些 artifact URN 变了"。严格地，按任意规模的 artifact 集合不可能 O(1)，本篇契约是**"与 journal 规模无关、仅与被冻结的 artifact 数 N 线性相关的单趟扫描，且 N 在单 snapshot 内受体积预算约束（见 §6）"**。这是 post-m1-kickoff §4 口语表达的精确化，不构成语义偏移。

### 5.2 drift 引擎的消费姿势

M5 drift 引擎基于 snapshot diff 做上游漂移检测：

```
输入：old_snapshot_urn, new_snapshot_urn（两者 frozen_scope.scope_kind 必须相同，scope_ref 必须一致）
输出：一组 drift_candidate 事件（每个 modified artifact 一条）
    → 每条 drift_candidate 附带 "上游 artifact 的 sha 变了，请重新评估下游"
```

**kernel 只承诺 `snapshot_diff` 算子**；drift 引擎基于它做传播算法（见 M5）。**snapshot 本身不执行 drift**。

### 5.3 跨 scope_kind 的 snapshot diff

**不支持**。两个 snapshot 若 `scope_kind` 或 `scope_ref` 不同，`snapshot_diff` 应**直接抛错**而不是返回空 diff。

**理由**：
- 两个不同 unit 的 snapshot 可能有重叠的 artifact URN 前缀——若 diff 跨 scope，会误报"added/removed"
- 跨 scope_kind 的对比需求应通过**各自的 diff 结果聚合**在应用层解决，不污染 kernel 原子算子

---

## 6. snapshot 体积与通胀控制

### 6.1 单 snapshot 体积预算

| 项 | 预期值 | 上限 |
|----|------|-----|
| `frozen_artifacts` 条数 | 几十～几百 | < 10,000 |
| 单 snapshot 文件大小 | < 10 KB | < 1 MB |
| 每个 scope_ref 下 snapshot 总数（生命周期内） | 10–200 | < 10,000 |

**超预算时的处置**（M7 之后定义）：
- 若单 snapshot 条数爆炸 → 说明 `frozen_scope.scope_kind` 选得太粗，应当拆分
- 若某 scope_ref 下 snapshot 历史暴涨 → 冷归档旧 snapshot（保留 URN 可解析，物理文件移至 `archive-fs/`）

### 6.2 snapshot 通胀是最大设计风险

**M4 不做 GC**（留给 M7）意味着 v0.1 阶段 snapshot 只增不减。为避免短期内打爆仓库，本篇提供硬约束：

- **§2.3 非触发点**严格执行（不给"每次 task 都打 snapshot"留口子）
- **§5.3 跨 scope_kind diff 不支持**（消除"凑合用"的动机）
- **§3.2 sha256 + URN 双轨**让单 snapshot 保持 KB 级

---

## 7. snapshot 的生命周期

### 7.1 状态机（仅两态）

```
        产出（原子性：见 §2.2）
           │
           ▼
       published
           │
           │  同 <scope>:<name> 再次冻结时产出 @v<N+1>
           ▼
       published @v<N+1>   （旧版仍 published，不变 retracted）
```

与 `02 §6` 的 artifact 生命周期不同：
- snapshot **不存在 draft 状态**（产出即 published）——snapshot 的"草稿"概念毫无意义（快照即事实，起草不起草都是一张照片）
- snapshot **不使用 `artifact.retracted`**——快照不作废，只被新快照 `supersede`
- snapshot 的 `supersedes` 语义是"顺序关系"，不是"替代"：旧 snapshot 仍是"当时的事实"，永久有效

### 7.2 与 `artifact.published` 事件的关系

snapshot 产出时写入的 `artifact.published` 事件（见 §2.2 步骤 3）与常规 artifact 的 `artifact.published` 事件 schema **完全一致**（见 `03 §3.1`）：

- `subject = <本 snapshot URN>`
- `artifact_urn = <本 snapshot URN>`
- `sha256 = <本 snapshot 的 content_sha256>`
- `producer_task_urn = <产出本 snapshot 的 task URN>`

**无需新增事件类型**——这是 kernel 纯度（`07 §2`）与 M3 L1 封板（`03 §3.1`）的共同要求。

### 7.3 snapshot 作为其他 artifact 的 `supersedes` 锚点

snapshot 是常见的"前置决议"引用目标——其他 artifact 的 `supersedes` / `depends_on` 可以指向某个 snapshot URN 表示"本 artifact 建立在该决议快照之上"。

示例（**本篇自身的 front-matter**）：

```yaml
upstream:
  - urn:piao:snapshot:kernel:m1_final_decisions@v1   # M1 决议快照
  - ...
```

---

## 8. 验收标准

本篇通过 review 的必要条件：

1. ✅ §2 回答了四问之一——三层触发分层清晰，L1 阶段边界为唯一强制
2. ✅ §3 回答了四问之二——C 方案（URN + sha256 双轨）锁定，body schema 完整可实施
3. ✅ §4 回答了四问之三——URN 寻址与 scope_kind 封板，五类覆盖穷举
4. ✅ §5 回答了四问之四——`snapshot_diff` 算子契约 + O(N) 线性扫描承诺
5. ✅ §3.3 的 scope_kind 枚举与 `03 §3.1` L1 事件 schema 协调（`stage.entered/exited` 事件的 `entry_snapshot_urn` 指向的 snapshot `frozen_scope.scope_kind` 应为 `stage` 或 `unit`）
6. ✅ §7 生命周期与 `02 §6` artifact 生命周期一致且特化（snapshot 无 draft、无 retracted）
7. ✅ 本篇**不含场景词**（scenario-wordlist v1 受管控词）

---

## 9. 已决事项与开放问题

### 9.1 已决（M4 draft 首版定稿节点）

1. **snapshot body 采用 URN + sha256 双轨方案（§3.1 C 方案）** ✅
2. **`scope_kind` 枚举封板五类**（unit / stage / taskdag / adapter / kernel）✅
3. **snapshot 不存在 draft 状态**（产出即 published）✅
4. **snapshot 不使用 `artifact.retracted`**（靠 supersedes 升 rev）✅
5. **复用既有 L1 事件类型**（`artifact.published` / `stage.entered` / `stage.exited`），不新增 event_type ✅
6. **`snapshot_diff` 为 kernel 承诺的唯一 snapshot 算子**（M4 工具链实现）✅
7. **snapshot front-matter 显式带 `artifact_type: snapshot`**（对齐 `02 §2.1` kind→artifact_type 映射）✅（路径 A · R8 · 2026-04-19 消化）
8. **`content_sha256` 规范化规则锚定在 §3.2.1**（仅对 frozen_artifacts 做 canonical YAML 后 SHA-256）✅（路径 A · R9 · 2026-04-19 消化）
9. **snapshot 不写 `depends_on`，由 lineage 查询器特化 frozen_artifacts 为等价替身**（§3.2.2）✅（路径 A · R10 · 2026-04-19 消化）
10. **`event_id` 预留契约**显式引用 `02 §4.3` provenance 填充流程（§2.2）✅（路径 A · R11 · 2026-04-19 消化）

### 9.2 仍然开放

1. **snapshot 的物理存储默认位置**：`01 §7.2` 已建议 `pipeline-output/snapshots/<unit>/<name>.json`，但对 `scope_kind=kernel` / `scope_kind=adapter` 类 snapshot 的默认路径未定。倾向：**v0.2 再定**；v0.1 所有 snapshot 物理位置由 manifest 显式注册
2. **snapshot 的 `supersedes` 链深度上限**：是否限制同一 `<scope>:<name>` 的 rev 数上限？倾向：**v0.1 不限**；若单条超过 100 触发 warn
3. **snapshot GC 策略**：冷归档的触发条件 / 目标路径。倾向：**M7 之后定义**，本篇不承诺
4. **snapshot 的 adapter 级 diff 钩子**：是否允许 adapter 注册自己的 `snapshot_diff_ext`（扩展字段级 diff）？倾向：**v0.2 评估**，若两个 adapter 都有需求再升 kernel（路径 B，见 `02 §2.2`）
5. **L1 "里程碑" snapshot（§2.1 L2 行）的治理**：谁有权产出？是否只允许 kernel / pipeline-orchestrator / adapter charter 升版这几种来源？倾向：**M5 drift 视角一起定义**

### 9.3 前置契约（本篇依赖的上游决策）

- **身份**：`01 §1.1` URN grammar、`01 §2.1` `snapshot` kind 版本化、`01 §3.4` adapter 资产 scope、`01 §4.4` 命名风格
- **Artifact**：`02 §1.1` 五要素 front-matter、`02 §3.2` sha256 + URN 双轨、`02 §6` 生命周期（snapshot 作为 artifact 的特化）
- **分层/事件**：`03 §3.1` L1 10 类事件封板（`stage.entered/exited` 已携带 snapshot 字段）、`03 §3.2` L1 通用骨架、`03 §3.3` append-only 硬约束
- **Extensibility**：`07 §1` 边界 2（adapter 不得扩展 kernel 枚举，故 `scope_kind` 封板）、`07 §2` 四扩展点（snapshot 不增设新扩展点）

---

## 10. rev_history

| rev | 发布时间 | 触发来源 | 变更摘要 |
|-----|---------|---------|---------|
| v1（draft） | 2026-04-18 23:55 | `urn:piao:proposal:kernel:post_m1_kickoff@v1` · 分支 2b 工作流 A 启动 | 首版 draft；定义 snapshot 三要素（§1）、三层触发（§2）、URN + sha256 双轨 body（§3）、scope_kind 五类封板（§3.3 / §4）、snapshot_diff 算子契约（§5）、通胀控制（§6）、生命周期状态机（§7） |
| v1（draft · 路径 A 原地消化） | 2026-04-19 01:00 | `urn:piao:artifact:kernel:m4_snapshot_draft_review@v1 §3.1` | draft 阶段原地修订（按 `01 §10.1` 不升 rev）：R8（§3.2 加 `artifact_type: snapshot` + §3.4 示例同步）· R9（新增 §3.2.1 `content_sha256` 规范化规则）· R10（新增 §3.2.2 为何不写 `depends_on`，声明 lineage 查询器特化接口）· R11（§2.2 补 `event_id` 预留契约，引用 `02 §4.3`）。四条均消化，draft 可与路径 B proposal 并行推进 |
| **v1.1（draft）** | **2026-04-19 02:00** | `urn:piao:artifact:kernel:m4_snapshot_draft_review@v1 §4.3 Step 3` · 路径 B 完成后反向对接 | 路径 B 完成后的跨篇一致性维护升版（**仍 draft**，反映 03/01/02 三篇外部升降给本篇带来的锚点状态变化与 schema 微调）：①§2.2 产出契约的原子性引用从"`03 §3.3` 脚注"改为"`03 §3.3.1` 两条具名承诺"；②§2.2 新增"stage 事件语义字段的绑定规则"段，规定 `frozen_scope.scope_kind=taskdag` 时 `stage.*` 事件的 `related_taskdag_urn` 字段**必填且等于 scope_ref**（R13 反向对接）；③§2.2 容错段的孤儿识别路径统一走 `03 §3.3.1 --check-orphan`；④§2.2 `event_id` 预留契约段追认 `02 §4.3.1` 已显式点名反向对接；⑤§3.2.2 锚点注释从"待 02 对接"改为"已由 02 @v1.2 反向对接"；⑥§3.3 scope_kind=taskdag 行的"典型触发"列补充对 `related_taskdag_urn` 的引用。**纯补充性小升**，schema 骨架不变，已产出的 snapshot 实例（若有）不受影响；draft 状态保持，Step 4 将走 draft → published 标准流程 |
| **v1.1（published）** | **2026-04-19 02:10** | `urn:piao:artifact:kernel:m4_snapshot_draft_review@v1 §4.3 Step 4` · M4 milestone 收官 | **draft → published**，无内容改动（按 `01 §10.1` published 态契约，本次发布使用 draft 末态字节完全一致的内容）。同步动作：①`produced_by` 从 `m4:version_snapshot_draft` 改为 `m4:version_snapshot_published`、新增 `published_at: 2026-04-19T02:10:00+08:00`；②`upstream` 追加 `m4_final_decisions@v1` / `m4_snapshot_draft_review@v1` / `m4_snapshot_kernel_alignment@v1` 三条 M4 周期配套产出；③篇尾状态行从 "draft @v1.1" 改为 "published @v1.1（M4 milestone 完成）"。本次 published 对应 L1 事件三连：`stage.exited(stage=M4_draft_review)` + `artifact.published(snapshot:kernel:m4_final_decisions@v1)` + `artifact.published(spec:architecture:version_snapshot@v1.1)`（按 §2.2 原子契约）。**自此 04 正式作为 kernel 已发布规格，供 adapter / M5 drift 层引用** |
| **v1.2（published）** | **2026-04-19 14:35** | `urn:piao:proposal:kernel:m5_drift_kernel_alignment@v1 §4.2 / §4.3` · M5 路径 B 落地 | **小升 @v1.1 → @v1.2**（纯补充 · 零 schema 删减 · 零字段类型变更 · 零语义反转）：①新增 §3.2.3 "canonical YAML 通用工具实施建议"（合并落地两条路径 A 遗留债：m5-drift-draft-review §3.2 R21 drift content_sha256 实施 + m4-toolchain-review §2.5 T5 snapshot front-matter key 正则 · 三条承诺：key 正则 `^[a-z_][a-z_0-9]*$` + 正向白名单 `pick_fields` + `SHA_WHITELIST` 声明范式 · §3.2.1 自动成为本契约的 snapshot 特化实例）；②§5.1 `snapshot_diff` 字段表追加 `sha_changed` 作为 `modified` 的 alias（R24 · 两字段值必须同语义 · 新消费方应优先用 `sha_changed` · 向下兼容承诺至少保留两个小版本周期双名输出）；③front-matter `produced_by` 更新为 `m5:version_snapshot_published` · `upstream` 追加三条 M5 周期配套（`m4_toolchain_review@v1` / `m5_drift_draft_review@v1` / `m5_drift_kernel_alignment@v1`）· `published_at` 更新至 `2026-04-19T14:35:00+08:00`。**对 v1.1 已产出实例零冲击**（v1.1 的 snapshot 在本次升版前已按旧算法计算 content_sha256 · 本次不触发重算 · 与 §7.1 "published snapshot 不可变" 硬约束对齐）。本次 published 对应 L1 事件两连：`artifact.published(spec:architecture:version_snapshot@v1.2)` + `stage.transited(stage=m5_path_b_step2)`（按 §2.2 原子契约 · N=2） |

---

**本篇状态**：**published @v1.2**（2026-04-19 14:35 · M5 路径 B Step 2 落地；由 `urn:piao:proposal:kernel:m5_drift_kernel_alignment@v1 §4.2/§4.3` 驱动 @v1.1 → @v1.2 小升；对应 L1 事件两连见 §10 rev_history 最末行）
**上游**：M1 三件套（`01@v1.2`, `02@v1.3`, `03@v1 draft`, `07@v1.1`） + `post_m1_kickoff@v1`（M4 触发源 · 本 milestone 收官时同步标 superseded） + `m4_final_decisions@v1`（M4 收官快照） + M4 review 三件套（draft_review / kernel_alignment_proposal / final_decisions） + M5 review 二件套（`m5_drift_draft_review@v1` / `m5_drift_kernel_alignment@v1`） + `m4_toolchain_review@v1`（T5 key 正则遗留债由本 @v1.2 §3.2.3 合并 consumed）
**配对 review**：`urn:piao:artifact:kernel:m4_snapshot_draft_review@v1`（§6 路径 B 完成记录 + 本次 published 追述在 review 层完成闭环）
**下游锚点**：
- M5 drift 传播算法将基于 §5 `snapshot_diff` 算子
- M4 工具链将实现 `scripts/snapshot-diff.sh` 与 `scripts/snapshot-produce.sh`
- 首个 adapter 的 acceptance-criteria / trace-impl 撰写时将依赖本篇 §3.3 scope_kind 为自己的 snapshot 选位
- `M1-debt-ledger @v5` 将以本 @v1.1 published 为证据关闭 Q8–Q14 七条缺口
