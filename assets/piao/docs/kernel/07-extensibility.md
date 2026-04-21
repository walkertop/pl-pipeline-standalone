# kernel · 07 Extensibility（kernel / adapter 边界宪章）

> 本文档是 piao-pipeline 的**宪法**。定义哪些是 kernel 封死的、哪些是 adapter 可扩展的，以及跨层通信的接口。
> **定稿在 M1 阶段产出，是为了防止后续所有文档游走在"首个 adapter 专属 vs 通用"的模糊地带。**

---

## 0. 立场（从一个被我否决的选项说起）

我在 M0 阶段曾提出两种解读：
- **解读 A**：piao-pipeline 是"通用框架"，首个落地 adapter 只是第一个实例
- **解读 B**：piao-pipeline 当前聚焦首个落地 adapter，但关键接口点**留口子**

你选择了 **B**。本文档就是对"留哪些口子"的**精确定义**。

**核心原则**：
> **过早抽象是万恶之源**。只做"应该抽象的"，不做"可能抽象的"。
> **kernel 层每加一个接口，必须有"两个或以上 adapter 将因此受益"的具体推演**；否则直接砍掉。

---

## 1. kernel / adapter 五条硬边界

### 边界 1 — **kernel 不得含场景词**

kernel 层（docs / 代码 / schema）**全部文本**中不得出现以下词汇：

```
kuikly / weex / vue / compose / detekt / logcat / android / ios / kotlin /
screenshot / miniapp / page / page_id（业务单元一律用 unit / unit_id）
```

违反时的判定：
- 如果 kernel 文档必须举例，用 `<placeholder>` 或抽象描述替代
- 如果 kernel 代码需要调用某个具体工具，**必须经 adapter 接口**

### 边界 2 — **adapter 不得扩展 kernel 的基础枚举**

| 属于 kernel（封死，adapter 不能加） | adapter 可扩展（通过层级 / 派生） |
|------|------|
| `kind` 枚举（见 `01-identity-model.md` §2） | `artifact_type` 子类型（见 `02-artifact-model.md` §2） |
| `event_type` 根命名空间（`pipeline/taskdag/task/trace/evo/drift/gate`） | 子命名空间（如 `task.component_migration.started`） |
| `Pipeline Stage` 六阶段（SPEC/PLAN/IMPLEMENT/VERIFY/OBSERVE/ARCHIVE） | 阶段内部的子步骤 |
| URN grammar（含固定 `urn:piao:` 前缀与段序） | `<scope>` 内部的命名/分组方式 |

### 边界 3 — **adapter 不得跨 adapter 直接引用**

见 `01-identity-model.md` §3.2，这里不再重复。

**跨 adapter 需要共享能力时，唯一的路径是"升 kernel"**：
```
1. 在两个 adapter 中都出现类似需求
2. 抽象成 kernel 概念（写 kernel 文档）
3. 两个 adapter 各自改为调用 kernel
```

### 边界 4 — **kernel 必须通过接口（protocol）消费 adapter**

kernel 代码永远不直接 import adapter 模块，而是通过"注册表 + 协议"访问 adapter 能力：

```
kernel 定义接口 → adapter 注册实现 → kernel 按注册表查找
```

具体四个注册点见 §2。

### 边界 5 — **kernel 升版必须对所有 adapter 兼容**

- 升 minor 版（如 kernel-0.1 → 0.2）：必须向后兼容，adapter 不需要改
- 升 major 版（如 kernel-0.x → 1.0）：可以破坏兼容，但必须同时升级首个参考实现 adapter 作为验证基准

---

## 2. kernel 留给 adapter 的**四个正式扩展点**

这是本架构最关键的承诺——**只有这四个口子**，不会暗中再加。

### 扩展点 A — Task 类型注册表

**kernel 定义**（见下表），**adapter 通过"继承"扩展具体类型**：

| kernel 基础任务类型 | 语义 |
|------|------|
| `file_op` | 创建 / 删除 / 移动文件 |
| `code_gen` | 生成代码内容 |
| `verification` | 执行一次验证操作 |
| `integration` | 与外部系统交互（构建、部署、截图等） |

首个落地 adapter 的任务类型注册（例，具体场景词仅作示意，正式注册内容见 `adapters/<name>/task-types.yaml`）：

```yaml
# adapters/kuikly/task-types.yaml
task_types:
  component_migration:
    base: code_gen
    description: "迁移单个 source framework 组件到目标 DSL"
  module_migration:
    base: code_gen
  viewmodel_migration:
    base: code_gen
  screenshot_compare:
    base: verification
  apk_build:
    base: integration
```

**kernel 侧**只保证以下不变量：
- 每个 task 必须有 `type` 字段，该字段值必须能追溯到一个 kernel 基础类型
- drift / trace / snapshot 等 kernel 机制只操作基础类型上的共有字段

### 扩展点 B — Acceptance Criteria 注册表

**kernel 定义三类验收信号**：

| 基础信号类 | 语义 | 通用产出字段 |
|------|------|------|
| `static_check` | 静态代码检查 | `pass: bool, findings: list` |
| `build_artifact` | 构建产物验证 | `pass: bool, artifact_urn: str` |
| `runtime_signal` | 运行时可观测信号 | `pass: bool, trace_contract_urn: str` |

**adapter 注册具体实现**（名字 + 执行脚本 + 判定函数）：

```yaml
# adapters/<name>/acceptance.yaml
criteria:
  static_analyzer_check:
    class: static_check
    exec: scripts/lint.sh
    pass_condition: "exit_code == 0"
  host_build:
    class: build_artifact
    exec: <adapter 自定义构建命令>
    emits_artifact: code
  runtime_trace_check:
    class: runtime_signal
    exec: <adapter 自定义运行时日志分析脚本>
    emits: trace_contract
```

**kernel 侧**只保证以下不变量：
- 每个 criterion 必须属于三类信号之一
- gate 评估时只读 `pass` 字段和 `class`

### 扩展点 C — Trace 实现

**kernel 定义接口**（概念级，不是代码）：

```
interface TraceImpl {
  fun enterContext(context_carrier): Scope
  fun emit(event_type, payload): void
  fun attachToArtifact(artifact_urn): void
}
```

**kernel 侧只关心**：
- 所有 emit 出来的事件都符合 `03-event-model.md` 的 schema
- 事件 subject 字段是合法 URN

**adapter 自由选择实现手段**：
- 本仓库首个 adapter：基于宿主语言的协程上下文 + UI DSL 渲染槽
- 服务端（假想）：基于 OpenTelemetry context
- 前端 Web（假想）：基于 AsyncLocalStorage / Zone.js

**接入方式**：adapter 在 `adapters/<name>/trace-impl.md` 中声明自己的实现机制，并保证通过 kernel 提供的"合规性测试集"（v0.1 可后补）。

### 扩展点 D — Evolution Source 注册表

**kernel 定义**：什么是一个 evolution source？

> **Evolution Source** = 任何能持续产出"触发 proposal 候选"的事件源。

**kernel 侧要求每个 source 必须实现的接口**：

```
interface EvolutionSource {
  val urn: URN                    # 这个 source 自身的 URN
  fun index(): List<SourceEntry>  # L1 索引（轻量，可全量加载）
  fun detail(entry_id): Markdown  # L2 正文（按需加载）
  fun on_match(trigger_signal)    # 触发钩子：被命中时回调
}
```

**首个落地 adapter 注册的 source**（v0.1，示意）：
- `error_log`：已有的 `docs/errors/error-log.md` 被结构化升级后作为 source（详见对应 adapter 的 `04-evolution-sources.md`）
- 未来候选：`component_reuse_log`（组件复用统计）、`drift_log`（drift 事件集）

**kernel 侧只关心**：
- source 注册后，kernel 能从它拉取 L1 索引
- kernel 按触发信号路由到哪个 source 的 on_match

### 2.5 扩展点占位声明建议格式（v1.1 新增）

> **新增来源**：`urn:piao:proposal:kernel:m2_kernel_minor_upgrade@v1` § 动作 6（R4 / Q3）
> **性质**：**非强制模板**——adapter 启动期写"占位声明"时的参考；不进入校验器。正式注册（`task-types.md` / `acceptance.yaml` 等）使用 §2.1-§2.4 各自的完整 schema。

#### 2.5.1 何时使用占位声明

adapter 的 `00-charter.md` 阶段通常无法一次性给出四个扩展点的完整注册内容——这个阶段的目的是**宣告"我将在哪个扩展点做扩展"而不是"我的扩展具体是什么"**。占位声明就是这个中间态。

#### 2.5.2 最小字段集

占位声明**推荐**字段（adapter 可超集，但不应少于这四个）：

| 字段 | 必需 | 语义 |
|-----|------|-----|
| `name` | ✅ | adapter 内派生名；遵循命名风格约定（扩展点 A 用 snake_case；扩展点 B 的类名按 `01 §4.4`；扩展点 C/D 的接口实现名按 adapter 自治） |
| `extends` / `class` / `base` | ✅ | 引用的 kernel 基础类型；对扩展点 A 填 `base`，对扩展点 B 填 `class`，对扩展点 C 填 `interface_version`，对扩展点 D 填 `source_kind` |
| `status` | ✅ | `placeholder` / `draft` / `published`；起始阶段填 `placeholder` |
| `intent` | ✅ | 一句话说明为什么需要该扩展；帮助 kernel 评审扩展的必要性（对应 §4 四问的第一问） |

#### 2.5.3 扩展点 A 占位示例

```yaml
task_types_placeholder:
  - name: component_migration
    base: code_gen
    status: placeholder
    intent: "将单个 legacy UI 组件迁移为目标 DSL 组件"
  - name: screenshot_compare
    base: verification
    status: placeholder
    intent: "对比新旧页面截图确认迁移视觉一致性"
```

#### 2.5.4 扩展点 B 占位示例

```yaml
acceptance_placeholder:
  - name: static_analyzer_check
    class: static_check
    status: placeholder
    intent: "静态代码分析作为迁移代码的入门门禁"
```

#### 2.5.5 扩展点 C/D 占位示例

扩展点 C（Trace 实现）：
```yaml
trace_impl_placeholder:
  name: <adapter>_trace
  interface_version: v1
  status: placeholder
  intent: "在 adapter 的宿主运行时实现 TraceImpl"
```

扩展点 D（Evolution Source）：
```yaml
evolution_sources_placeholder:
  - name: error_log
    source_kind: log
    status: placeholder
    intent: "将 adapter 运行期的错误日志作为演化候选源"
```

#### 2.5.6 从 `placeholder` → `published` 的升级检查点

当 adapter 把某个扩展点从 `placeholder` 升到 `draft` 或 `published` 时，应跑 §2.6 对应扩展点的合规性自验证 checklist。

### 2.6 扩展点合规性自验证 checklist v0.1（v1.1 新增）

> **新增来源**：`urn:piao:proposal:kernel:m2_kernel_minor_upgrade@v1` § 动作 7（R7 / Q7）
> **性质**：**可机械化判定的断言集**——每条都能被 shell 或 python 脚本自动化判定，不是"人肉 review"。
> **版本**：v0.1——本次小升提供的起步版本；adapter 使用后反馈的不实用条目将在 `07@v1.2` 修订。

#### 2.6.1 扩展点 A · Task 类型注册表

对 adapter 的 `task-types.md` / `task-types.yaml` 断言：

- **A.1**：类型总表中每行的 `base` / `extends` 字段值**必须**属于 kernel 四个基础类型之一（`file_op` / `code_gen` / `verification` / `integration`）
- **A.2**：每个派生类型的"必需字段"集合**必须**是 kernel 基础类型共有字段的**真超集**（至少包含 `type`、`task_urn` 或等价字段）
- **A.3**：每个派生类型的 `emits` 字段（若有）指向的 `artifact_type` **必须**在 `02 §2` 类型表或 §2.1.1 `artifact.*` 派生示范中可查；查不到则 adapter 必须在自己的派生清单（见 `02 §2.2.3`）中声明
- **A.4**：所有 task `type` 的命名**应**遵循 `01 §4.4` 的 snake_case 约定（非强制，但 audit 告警）

**断言实现草案**（伪代码，脚本化实现留 v0.2）：

```bash
# 断言 A.1
for type in $(yq '.task_types[].base' adapters/*/task-types.yaml); do
  grep -q "^| \`$type\` |" kernel/07-extensibility.md || error "A.1 violation: $type"
done
```

#### 2.6.2 扩展点 B · Acceptance Criteria 注册表

对 adapter 的 `acceptance.yaml` / `acceptance-criteria.md` 断言：

- **B.1**：每个 criterion 的 `class` 字段值**必须**属于 kernel 三类基础信号之一（`static_check` / `build_artifact` / `runtime_signal`）
- **B.2**：每个 criterion 的 `exec` 字段**必须**指向一个可执行的脚本路径或命令；缺省或空值 → 违规
- **B.3**：每个 criterion 必须有**可被 gate 评估的 `pass` 字段定义**（通过 `pass_condition` 或函数返回值）
- **B.4**：`emits_artifact` 字段（若有）的类型**必须**在 `02 §2` 类型表中可查

#### 2.6.3 扩展点 C · Trace 实现

对 adapter 的 `trace-impl.md` 断言：

- **C.1**：adapter 声明实现了三个接口方法（`enterContext` / `emit` / `attachToArtifact`）；缺任一 → 违规
- **C.2**：adapter 发出的事件 body 的 `subject` 字段**必须**是合法 URN（通过 `01 §6 validate_identity` 校验）
- **C.3**：adapter 发出的事件 `event_type` **必须**归属于 kernel 定义的 7 个域前缀之一（见 `01 §5`）
- **C.4**：adapter 的"合规性测试集" hook 存在（即使测试内容为空，hook 本身必须声明——供未来 kernel 下发测试时可接入）

#### 2.6.4 扩展点 D · Evolution Source 注册表

对 adapter 的 `evolution-sources.md` 断言：

- **D.1**：每个 source 有自己的 URN（形如 `urn:piao:evolution_source:<scope>:<name>@<rev>`），且 `kind=evolution_source`（见 `01 §2.2` 扩展 kind）
- **D.2**：source 声明了三个必需方法（`index()` / `detail(entry_id)` / `on_match(trigger_signal)`）
- **D.3**：source 的 `index()` 返回类型是 `List<SourceEntry>`（具体 schema 留 adapter 自治，但必须是轻量可全量加载的）
- **D.4**：source 的 `on_match` 被触发时的下游 artifact 类型（通常是 `proposal` / `proposal.<subtype>`）**必须**是合法 `artifact_type`

#### 2.6.5 checklist 的反馈回路

使用本 checklist 的 adapter 在发现**某断言不实用 / 不可机械化 / 与 kernel 硬约束不匹配**时，应：
1. 在 adapter 的 `_review/` 下新增一条评审记录（文件名 `extensibility-checklist-v0.1-feedback.md`）
2. 将反馈作为 evolution source 被 kernel 消费
3. kernel 按累计反馈在 `07@v1.2` 或更高版本修订本 checklist

---

## 3. 哪些 adapter **不能改**（即使很想）

| 你可能想改 | 为什么不许 |
|------|------|
| URN grammar（加个段） | 破坏 identity 全局唯一性保证 |
| event_id 格式 | 破坏事件排序 |
| Pipeline 六阶段 | 破坏阶段通用语义，drift 引擎的时间模型会失效 |
| Drift 传播算法 | 这是 kernel 的"物理定律" |
| Version Snapshot 结构 | 快照跨 adapter 可比性失去 |
| Evolution 提案的审批机制（git hook + review） | 变动可能让 `.codebuddy/` 失控 |

---

## 4. "留口子"与"过度设计"的判断基准

**新加一个扩展点前，必须通过以下四问：**

1. **双场景压测**：除了已有的首个 adapter 外，至少还有一个具体场景（前端 / 服务端 / 新一版 source framework）也会用到这个口子。能不能具体说出两例？
2. **kernel 纯度**：这个口子是否可以在 kernel 内部自举完成，不必让 adapter 染指？
3. **测试成本**：引入这个口子后，kernel 的单测成本是否可控？
4. **回退成本**：如果 v0.2 发现它不成立，能否 deprecate？

**四问有一个答不上来，扩展点不加。**

---

## 5. 伪扩展点（**不加**的记录）

**这些看起来像扩展点，但在 v0.1 明确不做**，记录在此防止未来反复讨论：

| 看似合理的"口子" | 为什么不做 |
|------|------|
| 多 LLM 路由 / 模型切换协议 | kernel 不该关心模型；Agent 层的事 |
| 自定义 Orchestrator 流 | 当前 orchestrator 是脚本，单实现即可 |
| 自定义 Rule/Skill 存储后端 | 文件系统已足够；抽象带来的复杂度 ≫ 收益 |
| 自定义 event storage backend（如 SQLite / Kafka） | JSONL 在单机项目足够，换 backend 的 ROI 为零 |
| 自定义 snapshot 序列化格式 | JSON 封死，防止 YAML/TOML/二进制内耗 |
| 自定义 URN resolver | 一切都通过 manifest，不需要插件化 |

---

## 6. 文档与代码的目录反映

本宪章不只是"承诺"，而是**目录结构本身**的体现：

```
docs/piao-pipeline/
├── kernel/               ← 领域无关、跨业务可复用的契约与原理都在这
│   └── *.md              ← 任何 md 里不得出现 §1 边界 1 的场景词
├── adapters/
│   └── <adapter_name>/   ← adapter 的所有内容严格圈在自己的目录
│       ├── task-types.yaml         ← 扩展点 A 的注册
│       ├── acceptance.yaml         ← 扩展点 B 的注册
│       ├── trace-impl.md           ← 扩展点 C 的实现说明
│       ├── 04-evolution-sources.md ← 扩展点 D 的 source 注册
│       └── storage-policy.md       ← 可选：覆盖 kernel 默认存储位置
└── competitive/
```

**维护规则**：
- kernel 目录的文档有**敏感词检查脚本**（在 git hook 或 CI 中跑），出现场景词自动拒 commit（v0.2 做）
- adapters/ 下每加一个 adapter 要建独立目录；**目录外不得出现该 adapter 的专有概念**

---

## 7. 未来的 "kernel 演化" 自我约束

以下情况**kernel 才会考虑新增扩展点**：

1. 出现第二个 adapter（非首个参考实现）正式立项
2. 或首个 adapter 内部出现"同一概念的两个 variant 实现"（暗示该概念应该被 kernel 抽象）
3. 或某个演化提案反复指向"现在的 kernel 限制导致 xxx 不可解"——并通过 §4 四问

**kernel 的任何新增扩展点**，必须在本文档中追加章节（并升本文档的 rev）。

---

## 8. 小结（这一段记住就够）

> kernel 管**契约**和**物理定律**。
> adapter 管**场景特化**。
> 两者之间**只有四个正式口子**（Task 类型 / Acceptance / Trace / Evolution Source）。
> 其他任何"想加的扩展"一律先问 §4 四问。

以及最直白的一句话：
> **kernel 文档里出现具体的 adapter 名（如 `kuikly`）这三个字母，就说明某篇文档写坏了——这一句是本宪章的元引用豁免。**

---

## 9. 已决事项与开放问题

### 9.1 已决（M1 review，2026-04-18）

1. **场景词检测：v0.1 只做白名单字典，CI 检查延后到 v0.2** ✅
   - **v0.1 交付物**：在 `docs/piao-pipeline/kernel/` 下放一份 `scenario-wordlist.md`，列出**禁止出现在 kernel 文档中的场景词**。初版词表：
     - **强禁用**（出现即违规）：`kuikly`、`weex`、`vue`、`compose`、`kotlin`、`swift`、`android`、`ios`、`gradle`、`detekt`、`tapd`、`logcat`
     - **受限使用**（只允许出现在 §3 的"已识别扩展点"或"示例"段落，且需用 `adapter.<name>:` 前缀引用）：`page_id`、`card`、`viewmodel`
   - **v0.1 不做**：CI 强制检查、git pre-commit hook 拦截。
   - **v0.2 做**：`scripts/kernel-wordcheck.sh` + git hook，commit 被拒时返回具体行号和词。
   - 理由：v0.1 的 kernel 文档还在高频迭代，强制 hook 会拖慢写作；但先**建立白名单**能让后续新增文档时有一个明确锚点，避免二次清洗。

### 9.2 仍然开放

1. **kernel 的代码层还没开始写**，目前所有规则都是"文档契约"。v0.1 是否引入一个 `piao-kernel/` 代码目录放协议接口定义？倾向：**v0.2 再做**，v0.1 先保证文档和 adapter 配置都按契约走。
2. **跨 adapter 的 evolution 提案**（例如某个宿主语言的编码规范可能同时用于多个 adapter）要怎么"升 kernel"？倾向：走一个**lightweight RFC**（在 evolution proposal 里加 `promote_to_kernel: true` 字段，经特别 review），留到 `06-evolution-layer.md` 定义。

---

**本篇结论**：这是 piao-pipeline 最重要的**约束契约**。之后写任何文档、任何代码、任何脚本时，只要脑子里能反射出"这件事该在 kernel 还是 adapter"，本架构就稳住了一半。

---

## 10. rev_history

| rev | 发布时间 | 触发来源 | 变更摘要 |
|-----|---------|---------|---------|
| v1 | M1 阶段定稿（2026-04-18） | `urn:piao:snapshot:kernel:m1_final_decisions@v1` | 首版定稿；§1 五条硬边界 + §2 四正式扩展点 + §4 "四问"准入标准 |
| **v1.1** | **2026-04-18 23:30** | `urn:piao:proposal:kernel:m2_kernel_minor_upgrade@v1` | 新增 §2.5 扩展点占位声明建议格式（R4）；新增 §2.6 扩展点合规性自验证 checklist v0.1（R7）。**纯补充性小升**，§1 硬边界与 §2.1-§2.4 四扩展点 schema 不变，现有 adapter 不受影响 |
