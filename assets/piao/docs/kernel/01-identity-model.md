# kernel · 01 Identity Model

> 系统里的实体**怎么命名、怎么索引、怎么关联**。
> 这是整个架构的**根契约**——身份模型不统一，后续所有文档都是沙上建塔。

---

## 0. 为什么第一篇写身份模型

在我研究过的所有"出过大事"的研发系统里（Airflow 的 DAG 实例 ID、Temporal 的 workflow ID、Bazel 的 target label、K8s 的资源标识），**身份模型崩了是最不可逆的债**——事件、artifact、快照、演化全都挂在"身份"上。身份变一次，历史事件指向漂移，drift 系统直接失灵。

因此 piao-pipeline 的第一条硬规则：

> **所有可被事件引用的实体，都必须有一个全局唯一、可解析、可排序、人类可读的身份。**

---

## 1. 顶层决策

### 1.1 采用 URN-like 格式

格式定义：

```
urn:piao:<kind>:<scope>:<name>[@<rev>]
```

| 段 | 作用 | 约束 | 示例 |
|----|------|------|------|
| `urn:piao` | 固定前缀 | 永不变更，便于 grep 和反向兼容；若未来需多领域命名空间，见 §11 未来扩展 | `urn:piao` |
| `<kind>` | 实体种类 | 枚举，见 §2 | `artifact`, `task`, `unit` |
| `<scope>` | 归属层级 | 可多段，`/` 分隔；通常以业务单元（unit）为第一段 | `prop_confirm`, `prop_confirm/dag` |
| `<name>` | 名字 | 小写 + `_`，禁止空格 | `structured_spec` |
| `@<rev>` | 修订号（可选） | `v<整数>` 或 `v<整数>.<整数>`，不出现即指"最新" | `@v1`, `@v1.2` |

> **关于 `urn:piao:` 前缀为何保留**：曾评估过"`piao:<kind>:...`" 和"裸 `<kind>:...`"两种精简方案。结论是**继续保留完整 URN 前缀**——
> - `urn:` 符合 RFC 8141，让身份字符串在代码、文档、日志里**视觉上一眼可辨**（不会和 yaml key / 路径 / 配置值混淆）
> - `piao:` 预留命名空间，未来若一条事件流里混入外部 URN（如 `urn:w3c:...`、`urn:uuid:...`）不会重名
> - 唯一代价是多 9 字符，但换来"全局 grep `urn:piao:` 一次找齐所有身份引用"的能力，在身份密集的事件流中回本极快

**完整示例：**
```
urn:piao:artifact:prop_confirm:structured_spec@v1
urn:piao:event_journal:prop_confirm:main
urn:piao:task:prop_confirm/dag:t_07
urn:piao:snapshot:prop_confirm:plan_entered@v2
```

> **关于 realm**：本版 URN **不引入 `realm` 段**。piao-pipeline v0.1 服务于单一领域，"kernel / adapter" 的边界通过 §7 存储布局和 §2 kind 的语义层面表达即可，URN 层无需显式编码。如果未来要支持多领域，见 §11。

### 1.2 为什么选 URN 而不是路径 / UUID / hash

| 候选 | 优点 | 为什么不选 |
|------|------|------|
| 文件路径（如 `openspec/changes/x/y.md`） | 直观 | 换目录就失效；跨 artifact 类型无法统一 |
| 纯 UUID | 全局唯一 | 完全不可读；不包含分类信息；人肉排查灾难 |
| 内容哈希（如 `sha256:...`） | 自验证 | 不适合身份——同一逻辑实体的不同版本会是不同 hash |
| 路径+UUID 组合 | 折衷 | 没有明确语义，不可机器 parse |
| **URN（本方案）** | 可读、可 parse、可查询、可版本化、跨 kind 统一 | 需要显式约束命名，初期成本 |

---

## 2. Kind 枚举

kind 分两组：**核心 kind**（piao-pipeline 运行时必需）和 **扩展 kind**（为常见业务语义预留，可选使用）。

### 2.1 核心 kind（kernel 强制识别）

| kind | 含义 | 是否版本化 | 典型 scope 示例 |
|------|------|------|------|
| `artifact` | 生产出的文档/代码/配置等"文件级产物" | ✅ 必须 | `prop_confirm:structured_spec` |
| `task` | TaskDAG 中的一个节点 | ❌ 不版本化，但有状态 | `prop_confirm/dag:t_07` |
| `taskdag` | 一组 task 的有向无环图 | ✅ 必须 | `prop_confirm:main` |
| `unit` | 一个工作单元（所有业务场景的通用抽象——可以是一个页面、一个 API、一个模块、一次需求） | ❌ | `prop_confirm`, `user_login_api` |
| `stage` | Pipeline 的一个阶段 | ❌ 只有时间点 | `prop_confirm:plan` |
| `event_journal` | 事件流本身（每个 unit 一条） | ❌ append-only | `prop_confirm:main` |
| `snapshot` | 某一时刻的冻结照片 | ✅ | `prop_confirm:plan_entered` |
| `drift` | 一次漂移记录 | ❌ | `prop_confirm:t_07_to_t_09` |
| `proposal` | 演化提案（待审批） | ✅ | `rule_update/2026_04_18_a3f2` |
| `rule` | 已生效的规则 | ✅ | `kotlin_coding_standards` |
| `skill` | 已生效的技能 | ✅ | `spec_normalizer` |

### 2.2 扩展 kind（可选语义，不用也不违规）

| kind | 含义 | 版本化 | 使用场景 |
|------|------|------|------|
| `evolution_source` | 演化事件的输入源（如 error_log 条目、用户反馈） | ✅ | 有自演化需求的项目 |

> **关于 `page` kind 的合并**：早期版本曾预留 `page` kind 用于前端/客户端迁移类场景（凸显"UI 页面"属性）。M1 review 时评估后认为：
> - `page` 本质是业务场景词，属于 kernel 宪章（`07-extensibility.md §1`）明文禁止的词汇族
> - 语义上它与 `unit` 完全重叠，保留双 kind 只会制造"选哪个"的噪音
> - **现已合并到 `unit`**。业务侧若需表达"这是一个 UI 页面"的语义，应在 artifact front-matter 或 scope 命名里体现（如 `urn:piao:unit:prop_confirm` + front-matter `domain: ui_page`），而不是占用 kind 枚举槽位。
> - 业务代码里的 `page_id` 字段仍可保留（它只是 URN 的 `<name>` 段在项目内的别名），不受此次合并影响。
>
> **关于已废弃的 kind**：早期版本曾预留过 `event` kind 用于归档引用，现已**删除**——事件身份统一使用 §5 的短格式 event_id，不需要 URN 表达。

### 2.3 约束

- `task` / `stage` / `unit` / `drift` / `event_journal` 等**不带 `@rev`** 的 kind，其"变化"通过事件表达而不是 URN 升版
- `artifact` / `taskdag` / `snapshot` / `proposal` / `rule` / `skill` / `evolution_source` 等**必须带 `@rev`**，每次有语义变更都要升版

### 2.4 kind 枚举变更史

> 本节记录 kind 枚举**曾经发生过的增删变更**，便于后续引用与溯源。新增/删除 kind 必须走 kernel rev 升降流程（见 `07-extensibility.md §1 边界 2`）。

| 时点 | 变更 | 原因 | 决议出处 |
|------|------|------|---------|
| M1 初稿 | 预留 `page` kind（凸显"UI 页面"语义） | 承接前端迁移场景诉求 | — |
| M1 review（2026-04-18） | **删除 `page` kind**，合并到 `unit` | `page` 属于场景词，kernel 宪章禁用；语义与 `unit` 重叠 | `_review/M1-final-decisions.md §1 决议 2` |
| M1 review（2026-04-18） | **删除 `event` kind** | 事件身份使用 §5 的短格式 event_id，不需要 URN 表达 | `_review/M1-final-decisions.md §1（附带决议）` |

**未来变更的登记要求**：
- 新增 kind：必须在本表补一行，并在 `07-extensibility.md §1 边界 2` 同步
- 删除/合并 kind：必须在本表补一行，并给出所有既有 URN 的迁移方案
- **本表本身是 append-only**——纠正登记错误应追加新行，而不是改写历史行

---

## 3. 命名空间隔离（无 realm 版）

v0.1 不在 URN 层编码领域归属，但仍然需要"**哪些是 kernel 通用的、哪些是业务专属的**"这个区分——靠以下两个间接机制：

### 3.1 通过 scope 段表达业务归属

所有业务专属的实体，其 `<scope>` 必须以一个**业务单元标识**开头（典型是 unit 的名字）：

```
urn:piao:artifact:prop_confirm:structured_spec@v1      ← prop_confirm 这个 unit 的产物
urn:piao:rule:kotlin_coding_standards@v1               ← 没有 unit 前缀 → 跨项目通用规则
urn:piao:rule:vue_to_kuikly_syntax@v1                  ← 没有 unit 前缀 → 该项目通用规则
```

"是否跨项目通用"通过**是否有 unit 前缀**识别，而不是通过 realm 段。

### 3.2 通过存储位置表达 kernel/adapter 边界

见 §7 存储布局——kernel 通用资产放 `docs/piao-pipeline/kernel/`，业务资产放 `docs/piao-pipeline/adapters/<name>/` 或项目根目录。**路径本身就是边界**，不需要 URN 再编码一次。

### 3.3 校验器如何识别越界

§6 的身份校验器通过**读写方上下文 + 存储路径**判断"调用方是否有权引用这个 URN"：

- 位于 `kernel/` 路径下的文件引用了**某个特定 unit 的 URN** → 警告（kernel 不应依赖业务实体）
- 位于 `adapters/A/` 下的文件引用了 `adapters/B/` 的 URN → 拒绝（跨 adapter 耦合）

这套机制不如"URN 里直接写 realm"干净，但足够用，且不让每个读 URN 的人付出额外的概念成本。

### 3.4 adapter 自身资产 scope 约定（v1.1 新增）

> **新增来源**：`urn:piao:proposal:kernel:m2_kernel_minor_upgrade@v1` § 动作 1（R1 / Q1）
> **目的**：明确"adapter 自身的资产（charter / task-types / acceptance / trace-impl / evolution-sources 等注册文件）" 与 "adapter 处理的业务单元产物" 两类 scope 的分工。此前 §3.1 只正面回答了后者，留下前者的隐含空缺。

#### 3.4.1 两类资产的 scope 分工

| 资产类别 | scope 格式 | 示例 |
|---------|-----------|------|
| **adapter 自身资产**（adapter 目录下、描述 adapter 自身契约的文件） | `adapter/<adapter_name>`（下划线分隔内部字符） | `urn:piao:artifact:adapter/frontend_migration:charter@v1`<br>`urn:piao:artifact:adapter/frontend_migration:task_types@v1`<br>`urn:piao:artifact:adapter/frontend_migration:acceptance_criteria@v1` |
| **adapter 处理的业务单元产物**（被 adapter 处理的某个具体 unit 在流水线中产出的文件） | unit 名直接作为 scope，**不加 `adapter/` 前缀** | `urn:piao:artifact:prop_confirm:structured_spec@v1`<br>`urn:piao:artifact:customize_lucky_draw:code.page_ui@v1` |

**关键理解**：
- adapter 自身资产的"归属域"是**adapter 本身**——它不属于任何一个 unit，而是**所有 unit 共享**的 adapter 级契约
- 业务单元产物的"归属域"是**具体 unit**——换一个 unit 会产出同名但不同 URN 的独立文件

#### 3.4.2 §3.3 校验器对本节的延伸规则

- 位于 `adapters/<name>/` 目录下的文件，其 URN scope **必须**以 `adapter/<name>` **或** 某个合法的 unit 名开头；**两者都不是 → 拒绝**
- 位于 `adapters/<name>/` 目录下的文件其 URN scope 为 `adapter/<other_name>`（错拼 adapter 名） → 拒绝
- `adapter/<name>` 的 scope 出现在 `kernel/` 目录下的文件中 → 警告（kernel 不应依赖具体 adapter 的资产）

#### 3.4.3 新增 adapter 最小 Checklist（scope 自检）

新增一个 adapter 时，其首份 artifact（通常是 `00-charter.md`）的 URN 自检：

- [ ] scope 形如 `adapter/<adapter_name>`（小写 + 下划线）
- [ ] `<adapter_name>` 与目录名 `adapters/<name>/` 严格一致
- [ ] 同一 adapter 目录下**其他**非 charter 文件的 URN scope 保持与 charter 一致

本小节仅**显式化**此前隐含的约定，**不引入新的 schema 变更**。

---

## 4. 版本与修订（rev）

### 4.1 rev 的语义

- **整数版本 `@v<N>`**：语义破坏性变更（schema 变更、字段含义变更）
- **点分版本 `@v<N>.<M>`**：兼容性补丁（字段补充、描述修订）
- **不写 rev**：等价于"最新有效版本"——**仅在交互/日志中使用，不得用于事件和快照**

### 4.2 rev 的创建规则

| 操作 | 是否升 rev |
|------|------|
| 修错别字、修措辞 | ❌ 不升 |
| 补充示例、补充说明 | ✅ 升次版 `v1.1` |
| 字段重命名、类型变更、枚举增删 | ✅ 升主版 `v2` |
| 删除某个字段 | ✅ 升主版 `v2` |

### 4.3 rev 的历史可达性

**任何曾经发布过的 rev，对应的 URN 必须永久可解析。**
实现方式见 §7 存储布局——URN → 物理位置的映射通过一个 manifest 文件维护。

### 4.4 命名风格约定（非强制，v1.1 新增）

> **新增来源**：`urn:piao:proposal:kernel:m2_kernel_minor_upgrade@v1` § 动作 2（R6 / Q6）
> **性质**：**约定优于强制**——本节是建议，不是校验器硬约束。

kernel 已出现两个并存的命名风格，为消除歧义明示如下：

| 命名对象 | 推荐风格 | 示例 | 出处参考 |
|---------|--------|------|---------|
| task `type` 字段的值 | **snake_case** | `component_migration`, `screenshot_compare` | `07-extensibility.md §2 扩展点 A` 基础类型示例 |
| URN 的 `<name>` 段 | **snake_case**（见 §1.1 表格） | `structured_spec`, `t_07` | 本文件 §1.1 |
| URN 的 `<scope>` 段内部 | **snake_case**（允许单段含 `/` 分隔多级，但每段内部仍 snake_case） | `adapter/frontend_migration`, `prop_confirm/dag` | 本文件 §1.1 / §3.4 |

**artifact 的 `artifact_type` 字段**使用不同风格（dot.lowercase + 各段 snake_case），见 `02-artifact-model.md §2.1`——**两种风格并存是刻意的**：`type` 字段本身是单段标识符（snake_case 即足），`artifact_type` 需要表达"基础类型.派生"的两级关系（dot 作为层级分隔符）。

**如何处理历史不一致**：
- 新增任何 URN / task type 优先遵循本节；
- 历史已发布的 URN（含短格式 event_id 等）**不因本节而 deprecate**；
- 本节若发现与后续章节冲突，以后续章节为准并回来修订本节——**升 `v1.2` 小版本**即可。

---

## 5. event_id（事件的身份）

事件的身份**不使用 URN**，而是使用短格式：

```
{域}[-{concern}]-{YYMMDDHHmmss}-{6位hash}
```

| 段 | 规则 |
|----|------|
| 域 | 见下表，7 选 1（不按 kind 也不按 realm 分，按**事件类型族**分） |
| concern（可选） | 见 §5.1.1，仅当事件需要表达"业务关切"维度时附加；可选值由 kernel 预定义，adapter 不得扩展（*v1.3 新增*） |
| 时间戳 | **UTC** 的 `YYMMDDHHmmss`（12 位十进制，人肉可读） |
| hash | 6 位 16 进制（0-9a-f），推荐由 sha1(event_body 规范化后) 取前 6 位 |

**段数约定**（*v1.3 新增*）：

- 三段式（`{域}-{时间戳}-{hash}`）：仅域 · 用于大多数通用 L1 事件（如 `task-*`、`pipe-*`、`gate-*`）
- 四段式（`{域}-{concern}-{时间戳}-{hash}`）：域 + concern · 用于需要区分业务关切的 L1 事件（如 `drift-triggered-*`、`evo-scanned-*`、`task-published-*`）

| 域前缀 | 对应 event_type 命名空间 |
|--------|------|
| `pipe` | `pipeline.*` |
| `tdag` | `taskdag.*` |
| `task` | `task.*`, `artifact.*`（artifact 事件归入 task 域，因为它们总在某个 task 执行过程中产生） |
| `trace` | `trace.*`, `verify.*` 等执行细粒度事件 |
| `evo` | `evolution.*`（*v1.3 补注*：字面上承认 `evolution` 为 `evo` 的展开别名 · 仅历史兼容 · 新事件规范写 `evo-`；详见 §5.3.1）|
| `drift` | `drift.*` |
| `gate` | `gate.*`, `stage.*` |

**示例：**
```
task-260418115700-a3f2b1              ← 2026-04-18 UTC 11:57 的 task 事件（三段式）
evo-260418141530-d7e1a5               ← 2026-04-18 UTC 14:15 的 evolution 事件（三段式）
drift-triggered-260418121000-abc123   ← drift 域 × triggered concern 事件（四段式 · v1.3）
evo-scanned-260418130000-def456       ← evo 域 × scanned concern 事件（四段式 · v1.3）
task-published-260420001000-789abc    ← task 域 × published concern 事件（四段式 · v1.3 · artifact 发布类事件规范写法）
```

### 5.1 为什么不用 UTC 毫秒 base36

权衡过三种方案：

| 方案 | 优点 | 缺点 |
|------|------|------|
| `YYMMDDHHmmss`（当前选择，UTC 秒级） | 人肉可读；grep 时间范围直接用字符串比较；同时区一致 | 秒级精度，高并发靠 6 位 hash 区分 |
| UTC 毫秒 base36（如 `lygqjn80`） | 毫秒精度、字典序即时间序、字符短 | 不可视读，调试时必须解码 |
| ULID | 业界标准、时序友好 | 不含域信息；长达 26 字符 |

**选择 UTC 秒级可读格式**的理由：piao-pipeline 的事件不是高并发线上协议，**工程师日常调试 / IM 贴 id 问人 / grep 时间范围**的体验远比"毫秒精度防撞"重要。同秒内撞车的概率 = `2^-24 per event`（6 位 hex hash），在 append-only 单写者模型下可忽略。

### 5.1.1 concern 预定义表（*v1.3 新增*）

event_id 前缀可附加一个 concern 段（四段式）· 表达 `{域 × 业务关切}` 双维度。**concern 维度由 kernel 封闭预定义 · adapter 不得新增**（同 §5.1 七域封闭原则一致 · 不冲击 `07-extensibility.md @v1.1 §1 边界 2`）。

| 域 | 允许的 concern | 语义 | 示例 | 状态 |
|----|--------------|-----|------|------|
| `task` | `published` | artifact 资产发布事件（归入 task 域 · 因 artifact 生成总在某个 task 执行中）| `task-published-260420001000-abc123` | 活用（M7 后）|
| `task` | `consumed` | artifact 资产消费事件 | - | 预留 |
| `drift` | `triggered` | drift 被源数据触发 | `drift-triggered-260418121000-abc123` | 活用 |
| `drift` | `detected` | drift 被探测 | - | 预留 |
| `drift` | `resolved` | drift 被处理后解决 | - | 预留 |
| `evo` | `scanned` | evolution source 扫描事件 | `evo-scanned-260418130000-def456` | 活用 |
| `evo` | `proposed` | evolution source 浮现 proposal 候选 | - | 预留 |
| `evo` | `consumed` | evolution source 被决议消费 | - | 预留 |

**concern 维度的扩展路径**（为未来 milestone 明确）：

- **kernel 侧新增 concern**：通过 m8+ milestone 决议 + 本章表扩展 + 01 rev 升版
- **adapter 侧新增 concern**：**不允许** · 走"升 kernel"路径（同 §5.1 七域扩展路径一致）

**适用规则**：

- 单条事件的 event_id 前缀要么用三段式（仅域）· 要么用四段式（域 + 上表合法 concern）· 不得自由组合其他 concern 字面
- 三段式与四段式在同一 journal 内共存 · 语义独立 · 不强制统一
- 工具侧查询时 · 按 domain + concern 二维索引（`task × *` 包含所有 `task-*` 和 `task-*-*`）

### 5.2 碰撞处理

- **检测**：`event-journal-append` 写入前用 manifest 索引做碰撞查重
- **处理**：检测到碰撞则**立即抛错，要求调用方重新生成事件**（如在正文加 nonce）
- **绝对禁止**：自动递增后缀（破坏 id 可重现性）

### 5.3 事件如何关联 URN（subject 双轨契约）

每条事件 body 都必须有 `subject` 字段，指向该事件的**主语实体**（一个合法 URN）：

```yaml
event_id: task-260418115700-a3f2b1
event_type: artifact.published
subject: urn:piao:artifact:prop_confirm:structured_spec@v1   # ← 强制
# 按 event_type 附加的语义字段（与 subject 同一 URN 的别名，工具校验一致性）
artifact_urn: urn:piao:artifact:prop_confirm:structured_spec@v1
sha256: "abc123..."
producer_task_urn: urn:piao:task:prop_confirm/dag:t_07
```

**双轨原则**：
- **`subject`** 是所有 L1 事件的**统一索引入口**（"按 URN 反查所有相关事件" 只查一个字段）
- **语义字段**（`artifact_urn` / `task_urn` / `stage_urn` / ...）按 event_type 各自命名，**必须等于 subject**（工具校验）
- 这样兼顾统一查询和字段可读性

### 5.3.1 历史事件兼容条款（*v1.3 新增*）

v1.3 之前已落盘的 L1 事件（见 `urn:piao:journal:kernel:kernel_events@2026-04` + `urn:piao:journal:kernel:mvp_smoke_events@2026-04` 等 journal）· 若其 `event_id` 字面不符合 §5 + §5.1 + §5.1.1 的规范写法 · **在 v1.3 后仍保持原字面有效** · 不追溯回改。

#### 历史兼容清单（截至 2026-04-20 00:50）

| 历史字面 | 所属域 × concern（新表归类）| 规范写法 | 历史事件数 | 处置 |
|---------|---------------------------|----------|-----------|------|
| `evolution-scanned-*` | `evo × scanned` | `evo-scanned-*` | 2 条 | ✅ 豁免（字面兼容 · 不追改）|
| `artifact-published-*` | `task × published`（artifact 作为 task 域子类）| `task-published-*` | 1 条 | ✅ 豁免（字面兼容 · 不追改）|

#### 规则

1. 历史事件只按"实质归类"进入查询索引 —— 工具侧按 `{domain, concern}` 二维索引查询 · 不按字面前缀硬匹配
2. 未来新事件**必须**按 §5 + §5.1.1 规范写法 · 不得再使用豁免字面
3. 若 v1.4+ 有新历史兼容需求 · 通过 rev 升版扩展本表
4. 工具若严格按旧规格（三段式）做正则扫描 · 可能漏掉四段式事件 —— 新工具需按 §5.1.1 二维索引设计 · 见 `CONV-01.1`（`M1-debt-ledger @v10 §1.6.2`）

#### 与 CONV-01.1 的关系

**CONV-01.1**（由 `urn:piao:artifact:kernel:m7_prefix_taxonomy_decision@v1` 建立 · 登记在 `M1-debt-ledger @v10 §1.6.2`）约束**未来**所有 L1 事件的 event_id 前缀必须在本章合法表内。历史事件通过本章豁免兼容。两者分工：

- CONV-01.1 管未来事件的**合法性**
- §5.3.1 管历史事件的**兼容性**

---

## 6. 身份校验器（kernel 必提供）

kernel 必须提供一个**可被脚本调用的校验器**：

```
validate_identity(urn: str) → (ok: bool, reason: str)
```

校验内容：
1. **格式正确**（与 §1.1 grammar 匹配）
2. **kind 合法**（在 §2 枚举内，core 或 extended）
3. **scope 深度合规**（不超过 4 层）
4. **命名空间隔离**（根据调用方路径上下文，检查是否越界引用；见 §3.3）
5. **rev 格式**（若有）符合 §4.1

**实施位置：**
- 脚本层：`scripts/identity-validate.sh <urn> [--caller-path <path>]` 供 trace-emit 调用
- Agent 层：写事件前强制先 validate；失败直接拒绝写入

---

## 7. 存储布局（URN → 物理位置）

### 7.1 核心原则

**身份是逻辑的，存储是物理的。** 两者通过一个 manifest 文件解耦：

```
pipeline-output/
  identity-manifest.jsonl      # 每行一条 URN → 物理路径映射（append-only）
```

manifest 单条记录 schema：

```json
{
  "urn": "urn:piao:artifact:prop_confirm:structured_spec@v1",
  "path": "openspec/changes/migrate-prop-confirm/spec.md",
  "content_sha256": "xxxxxxxx",
  "created_at": "2026-04-18T13:57:00+08:00",
  "event_id": "task-260418055700-a3f2b1"
}
```

### 7.2 默认存储约定

**不强制**按这个目录放，但建议默认如下：

| kind | 默认位置 |
|------|------|
| `artifact` | `openspec/changes/<change_id>/` 下（沿用现有 OpenSpec 目录） |
| `taskdag` | `openspec/changes/<change_id>/taskdag.md` |
| `event_journal` | `pipeline-output/trace/<unit>.events.jsonl` |
| `snapshot`（按 scope_kind 细分，**v1.2 扩充**） | 见下方子表 |
| `rule` | `.codebuddy/rules/<rule_name>.md` |
| `skill` | `.codebuddy/skills/<skill_name>/` |
| `proposal` | `pipeline-output/evolution/proposals/<proposal_id>.md` |

**snapshot 按 `scope_kind` 细分的默认位置**（v1.2 新增，对齐 `04-version-snapshot.md §3.3` 的 scope_kind 五类封板）：

| scope_kind | 默认位置 | 说明 |
|----------|---------|------|
| `unit` | `pipeline-output/snapshots/<unit>/<snapshot_name>.json` | 原 v1.1 默认路径，保留 |
| `stage` | `pipeline-output/snapshots/stages/<stage_name>/<snapshot_name>.json` | 跨 unit 的 stage 级 snapshot |
| `taskdag` | `pipeline-output/snapshots/taskdags/<taskdag_name>/<snapshot_name>.json` | taskdag 完整执行完的冻结（触发依赖 `03 §3.1` 的 `stage.*` 事件可选字段 `related_taskdag_urn`） |
| `adapter` | `pipeline-output/snapshots/adapters/<adapter_name>/<snapshot_name>.json` | adapter 自治边界的冻结 |
| `kernel` | `docs/piao-pipeline/kernel/_review/<snapshot_name>.md`（或同目录的专用子目录） | kernel 自身决策快照；现状放 `_review/`（如 `M1-final-decisions.md`），未来**可选**迁到 `docs/piao-pipeline/kernel/_snapshots/` 但不强制 |

> **可自定义位置**：项目/业务可通过 `storage-policy.md` 覆盖默认位置，**但必须向 manifest 注册**（建立 URN → 路径映射）。

---

## 8. 约束与反模式

### 8.1 强制

- **所有事件 body 的 `subject` 字段必须是合法 URN**（见 §6 校验）
- **所有快照必须引用 URN，而不是路径**
- **所有 rule / skill / proposal 的交叉引用必须用 URN，不许写 markdown 相对链接**（或者同时写两者，URN 是权威源）

### 8.2 禁止

| 反模式 | 为什么禁 |
|------|------|
| 在 URN 里塞空格、大写字母、非 ASCII | parser 复杂化，跨平台坑 |
| URN 中段长度不限（允许任意层级 scope） | 必须限制深度≤4 层，避免失控 |
| 把 `unit_id` / `page_id` 等业务侧短标识和 URN 混用作键 | 必须始终用完整 URN；短标识只能作为 URN 的 `<scope>`/`<name>` 段来源 |
| 在 `docs/piao-pipeline/kernel/` 下引用某个具体业务 unit 的 URN | 破坏 kernel 通用性（见 §3.3） |

### 8.3 常见错误示例（反例）

```
❌ urn:piao::artifact:prop_confirm                # kind 为空
❌ urn:piao:Artifact:...                          # kind 有大写
❌ prop_confirm.spec.md                           # 不是 URN
❌ urn:piao:artifact:a/b/c/d/e:name               # scope 超过 4 层
❌ urn:piao:kernel:artifact:...                   # 不再支持 realm 段（v0.1 已移除）
✅ urn:piao:artifact:prop_confirm/data:models@v1
```

---

## 9. 迁移路径（从当前项目切过来）

项目现状（取自 `.state.md` 和 `openspec/` 目录）：

| 当前写法 | URN 翻译 |
|------|------|
| `page_id: prop_confirm` | `urn:piao:unit:prop_confirm`（业务代码里的 `page_id` 字段保留为 scope/name 别名，不影响 URN） |
| `dag_ref: openspec/.../taskdag.md` | `urn:piao:taskdag:prop_confirm:main@v1` |
| `.state.md` 里的 `T-07` | `urn:piao:task:prop_confirm/dag:t_07` |
| `error-log.md` 里的 `错误 #001` | `urn:piao:evolution_source:error_log/001@v1` |
| `.codebuddy/rules/kotlin-coding-standards.md` | `urn:piao:rule:kotlin_coding_standards@v1` |

> 迁移不要求一次到位——v0.1 只要求**新写入的事件/快照使用 URN**。历史产物通过 manifest 的一次性回填处理（归档阶段）。

---

## 10. 已决事项与开放问题

### 10.1 已决（M1 review，2026-04-18）

1. **rev 禁止回退发布** ✅
   - 任何 artifact/spec/rule 一旦发出 `v2`，即使发现 `v2` 有问题，也**不允许**撤回到 `v1.3` 或重发 `v2`。
   - 修正方式：**只能新发 `v3` 来修正 `v2`**，并在 `v3` 的 front-matter 的 `supersedes` 字段中显式指向 `v2`。
   - 理由：lineage 和 provenance 的不可变性是 trace / drift / evolution 三个子系统能互相信任的底层假设。允许回退等于允许改写历史。
   - 实施：`scripts/artifact-validate.sh` 会检查 manifest，发现 `rev` 序列非单调递增即拒绝 commit。

   **⚠️ 前提澄清（2026-04-18 追加）**：
   > **本规则仅作用于 "published" 状态的 artifact；"draft" / review 阶段的 artifact 允许原地修改，不触发 rev 升降。**
   >
   > - **published 的判定**：artifact 被 `piao.manifest.jsonl` 收录，且对应的 `artifact.published` L1 事件已写入 event journal。
   > - **draft 的判定**：artifact 文件已存在但**尚未进入 manifest**（例如文档仍在章节级 review、尚未通过 M 阶段门控）。
   > - **状态转换**：draft → published 是**单向**的；一旦 published，后续修改必须经 rev 升降。
   > - **本次 M1 review 期间**：`kernel/` 下所有 v1 文档均处于 draft 状态（整个 M1 通过 review 后才统一 publish 为 v1），因此 M1 review 周期内的原地修改合法。
   > - **实施**：`artifact-validate.sh` 的单调性检查**只对 published artifact 生效**；draft artifact 由文件级 git diff 自治。

### 10.2 仍然开放

1. **manifest 分片策略**：目前按整仓一个 jsonl，规模大时要不要按 unit 分片？倾向 v0.2 再定。
2. **跨仓库身份** 如果未来多仓协作，`urn:piao` 之下要不要加一个 `org` 或 `repo` 层？倾向：**v0.1 不做**，留待有具体需求时引入。

---

## 11. 未来扩展（留白）

本版 URN 格式 **`urn:piao:<kind>:<scope>:<name>[@<rev>]`** 是故意简化的，只服务单一领域。

**预留扩展点**：

| 扩展场景 | 届时的升级方式 |
|---------|--------------|
| **多领域隔离**（例如同一套 piao-pipeline 同时服务前端迁移 + 后端 API 规范两个不相关的领域） | 在 `urn:piao` 后插入一段 `<realm>`，做一次 URN schema v2 升级；届时 kernel 校验器和 manifest 都做一次性迁移 |
| **多仓协作** | 在 `urn:piao` 后插入 `<org>/<repo>`，同样走 schema 升级路径 |
| **跨租户 SaaS 化** | 考虑引入 `<tenant>` 段 |

**设计原则**：**不为假想的未来过早抽象**。真要扩展时做一次破坏性升级，代价可控（这是研发工具链，不是线上协议，没有向后兼容包袱）。

---

**本篇结论**：身份模型是整个 piao-pipeline 的**坐标系**。本篇定稿之前，后续所有 kernel 文档都不应该引入新的命名方式。如果后续发现某 kind 不够用，回来修这份文档，**并升本篇的 rev**。

---

## 12. rev_history

| rev | 发布时间 | 触发来源 | 变更摘要 |
|-----|---------|---------|---------|
| v1 | M1 阶段定稿（2026-04-18） | `urn:piao:snapshot:kernel:m1_final_decisions@v1` | 首版定稿；§2 kind 删除 `page` 和 `event`，合并 `page → unit` |
| **v1.1** | **2026-04-18 23:20** | `urn:piao:proposal:kernel:m2_kernel_minor_upgrade@v1` | 新增 §3.4 adapter 自身资产 scope 约定（R1）；新增 §4.4 命名风格约定（R6 前半）。**纯补充性小升**，schema 不变，现有 URN 不受影响 |
| **v1.2** | **2026-04-19 01:30** | `urn:piao:proposal:kernel:m4_snapshot_kernel_alignment@v1` | §7.2 默认存储约定扩充：`snapshot` 行扩为按 `scope_kind` 五类（unit/stage/taskdag/adapter/kernel）细分的子表（R14，源自 M4 review Q12）。**纯补充性小升**，原 `<unit>` 路径保留为 scope_kind=unit 的默认，其余四类追加；`storage-policy.md` 的覆盖原则（§7.2 末尾）未动 |
| **v1.3** | **2026-04-20 00:50** | `urn:piao:artifact:kernel:m7_prefix_taxonomy_decision@v1`（Q29 裁定 · 选定 B'-1） | §5 表头部扩展为 `{域}[-{concern}]-{时间戳}-{hash}` 可选四段式；§5 示例新增三条四段式示例；§5 `evo` 行补注承认 `evolution` 为展开别名；新增 §5.1.1 concern 预定义表（kernel 封闭 · adapter 不得扩展 · 初始 7 对合法组合：task×published/consumed · drift×triggered/detected/resolved · evo×scanned/proposed/consumed）；新增 §5.3.1 历史事件兼容条款（豁免 2 条 `evolution-scanned-*` + 1 条 `artifact-published-*` 历史字面）+ 与 CONV-01.1 分工说明。**纯补充性小升** · schema 向后兼容（三段式事件仍完全合法）· 现有 URN 不受影响；对应 CONV-01.1 契约登记在 `M1-debt-ledger @v10 §1.6.2` |
