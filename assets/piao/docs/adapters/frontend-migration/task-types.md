---
urn: urn:piao:artifact:adapter/frontend_migration:task_types@v1
artifact_type: spec.task_types
kind: artifact
rev: v1
status: published
schema_version: 1.0
created_at: 2026-04-18T22:55:00+08:00
published_at: 2026-04-18T23:10:00+08:00
created_by_event: manual-task-types-260418
content_sha256: ""
depends_on:
  - urn:piao:artifact:adapter/frontend_migration:charter@v1
  - urn:piao:snapshot:kernel:m1_final_decisions@v1
upstream_kernel_rev: m1_final_decisions@v1
extends:
  kernel_extension_point: A
  kernel_anchor: "kernel/07-extensibility.md §2 扩展点 A"
produced_by:
  actor: human:caleb
  task_urn: urn:piao:task:adapter/frontend_migration:task_types_bootstrap
  event_id: manual-task-types-260418
---

# Frontend Migration Adapter · Task 类型正式注册

> 本文件是 **kernel 扩展点 A（Task 类型注册表）** 对 `frontend-migration` adapter 的正式落地。
> 定位：charter §4.1 占位清单的**完整展开 + 正式 schema**。
> 上游：`adapters/frontend-migration/00-charter.md §4.1` + `kernel/07-extensibility.md §2 扩展点 A`。

---

## 0. 本文件的边界

- **做什么**：为每个派生 task 类型给出 ① 与 kernel 基础类型的继承关系 ② 必需字段 schema ③ 典型 provenance 模式 ④ 挂接的 L1 事件枚举。
- **不做什么**：
  - 不定义具体 task 实例（实例化由 taskdag 在 IMPLEMENT 阶段产出）
  - 不定义 acceptance criteria（归 `acceptance-criteria.md`，对应扩展点 B）
  - 不承诺 task 与 artifact 的生产关系拓扑（归 `10-artifact-map.md`）

---

## 1. 类型总表

按 kernel `07 §2 扩展点 A` 的四个基础类型分组：

| 派生 task 类型 | 继承的 kernel 基础类型 | 场景 | 本文件 §章节 |
|--------------|----------------------|------|------------|
| `component_migration` | `code_gen` | 单个 UI 组件（最小渲染单元）从 legacy source → target DSL | §2.1 |
| `module_migration` | `code_gen` | 一个 feature 模块（多组件聚合）完整迁移 | §2.2 |
| `viewmodel_migration` | `code_gen` | 一个 ViewModel 从 legacy → target 架构 | §2.3 |
| `unit_bootstrap` | `file_op` | 新建一个迁移目标 unit 的目录骨架 | §2.4 |
| `static_analyzer_check` | `verification` | 静态代码检查（lint + 自定义规则） | §2.5 |
| `screenshot_compare` | `verification` | 截图基线对比 | §2.6 |
| `host_build` | `integration` | 目标平台构建产物（依赖宿主平台） | §2.7 |

**总计 7 类**，覆盖 kernel 四个基础类型中的三个（`file_op` / `code_gen` / `verification` / `integration`）。`file_op` 与 `integration` 各一、`code_gen` 与 `verification` 各三。

---

## 2. 类型详述

每类的规范遵循统一模版：

```
### §2.x <type_name>

- 基础类型：<kernel_base_type>
- 一句话：<语义>
- 必需字段（adapter 侧）：<字段列表>
- 典型 provenance：<produced_by / consumes / emits 模式>
- 关联 L1 事件：<事件枚举锚点>
- 不变量回顾：<对 kernel §2 扩展点 A 不变量承诺的具体映射>
```

### 2.1 `component_migration`

- **基础类型**：`code_gen`
- **一句话**：把 legacy source framework 的一个原子 UI 组件重写为 target host-DSL 的对应组件，输入是 legacy 源文件 + structured_spec，输出是 `code.component` artifact。
- **必需字段**：
  - `unit_urn`：所属业务单元的 unit URN（如 `urn:piao:unit:prop_confirm`）
  - `component_name`：组件逻辑名（unit 内唯一，kebab-case）
  - `source_fingerprint`：legacy 源文件集合的 sha256 聚合指纹（用于 drift 检测）
  - `target_dsl`：目标 DSL 名（本 adapter v0.1 写 `declarative_ui_dsl`，具体实现名不出现在 task 层）
- **典型 provenance**：
  - `consumes`：`spec.structured`（unit 级）+ 1 条或多条 legacy 源文件路径（非 URN 资源，以 path 记录）
  - `emits`：`code.component`（一条或多条）+ 若干 L2 事件（挂 `task.started` / `task.completed`）
- **关联 L1 事件**：`task.started` / `task.progress` / `task.completed` / `task.failed`（`kernel/03-layered-architecture.md §3.1`）
- **不变量回顾**：
  - `type="component_migration"` 可追溯到 `base="code_gen"` ✅
  - kernel drift 只读 `type` / `status` / `unit_urn` 三个共有字段 ✅
  - adapter 派生字段（`component_name` / `source_fingerprint` / `target_dsl`）不进入 kernel 机制 ✅

### 2.2 `module_migration`

- **基础类型**：`code_gen`
- **一句话**：把一个 feature 模块（由 N 个 `component_migration` 聚合，N≥2）作为一个语义整体迁移。
- **必需字段**：
  - `unit_urn`：所属 unit URN
  - `module_name`：feature 模块名（unit 内唯一）
  - `child_component_tasks`：所依赖的 `component_migration` task 列表（**空列表非法**——若只有一个 component，直接使用 §2.1 即可）
- **典型 provenance**：
  - `consumes`：`spec.structured` + 各 child component 的 `code.component` artifacts
  - `emits`：`code.module`（一条）
- **关联 L1 事件**：同 §2.1；**额外**：`taskdag.edge_added` 当 `child_component_tasks` 变化时（由 TaskDAG 层自动发射）
- **不变量回顾**：
  - 同 §2.1；
  - 强调**不得扩展 `kind` 枚举**（`07 §1 边界 2`）——`module_migration` 不是新 kind，只是 `task` kind 的一个 `type` 派生。

### 2.3 `viewmodel_migration`

- **基础类型**：`code_gen`
- **一句话**：把 legacy 的 ViewModel（或等价的状态容器）迁到 target 架构的 ViewModel。
- **必需字段**：
  - `unit_urn`
  - `viewmodel_name`
  - `state_flow_schema`：ViewModel 暴露的状态流结构（简化 JSON Schema）——本字段是 adapter 派生，kernel 不读
- **典型 provenance**：
  - `consumes`：`spec.structured` + legacy 源文件（path）
  - `emits`：`code.viewmodel`
- **关联 L1 事件**：同 §2.1
- **不变量回顾**：同 §2.1

### 2.4 `unit_bootstrap`

- **基础类型**：`file_op`
- **一句话**：为一个新的迁移目标 unit 创建目录骨架与初始占位文件，不生成任何业务代码。
- **必需字段**：
  - `unit_name`：unit 名（将作为 URN 的 `<name>` 段）
  - `target_root_path`：目录写入路径（adapter 侧记录，kernel 不读）
  - `scaffold_template`：骨架模板标识（本 adapter v0.1 只支持 `default`）
- **典型 provenance**：
  - `consumes`：`proposal`（决定要迁哪个 unit）
  - `emits`：一次 `artifact` URN 分配（`spec.scaffold_report` 记录本次 bootstrap 的产出文件列表）
- **关联 L1 事件**：`task.started` / `task.completed`（没有 progress，因为是原子操作）
- **不变量回顾**：
  - `type="unit_bootstrap"` → `base="file_op"` ✅
  - 本类型**不触发 drift**（drift 不关心 file_op），但会触发一次 taskdag 的 L1 事件

### 2.5 `static_analyzer_check`

- **基础类型**：`verification`
- **一句话**：运行静态分析工具链（通用 lint + 本 adapter 自定义迁移规则）校验一个 unit 或 unit 的某个子模块。
- **必需字段**：
  - `target_urn`：被校验对象的 URN（通常是 `code.component` / `code.module` / `code.viewmodel`）
  - `analyzer_set`：分析器集合标识（绑定到 `acceptance-criteria.md` 的具体 criterion，预留给扩展点 B 填）
- **典型 provenance**：
  - `consumes`：target artifact
  - `emits`：`report.lint`
- **关联 L1 事件**：`task.started` / `task.completed` / `task.failed`；若检查出问题 → L2 事件 `finding.emitted`（挂本 task）
- **不变量回顾**：
  - `type` → `base="verification"` ✅
  - 产出 artifact 的 `pass` 字段是 kernel gate 评估的唯一入口，adapter 不得跳过

### 2.6 `screenshot_compare`

- **基础类型**：`verification`
- **一句话**：对一个 unit 的目标 DSL 实现做截图并与 legacy 基线比对，产出差异像素率。
- **必需字段**：
  - `unit_urn`
  - `baseline_asset_urn`：基线截图 artifact URN（`asset.screenshot`）
  - `pixel_diff_threshold`：阈值（adapter 默认 0.02，可 task 级覆盖）
- **典型 provenance**：
  - `consumes`：`asset.screenshot`（baseline） + 运行时截图（新产出）
  - `emits`：`report.screenshot_diff`
- **关联 L1 事件**：同 §2.5
- **不变量回顾**：同 §2.5

### 2.7 `host_build`

- **基础类型**：`integration`
- **一句话**：调用宿主平台构建链生成可执行产物（如二进制包 / 构建 bundle），用于真机运行前提。
- **必需字段**：
  - `target_platform`：`host_native` / `host_bundle` / `host_hybrid` 三选一（adapter 派生命名，**刻意不用具体平台名**以保持 adapter 文件本身的可读性与 kernel 场景词约束的对齐）
  - `output_path_hint`：输出路径提示（adapter 记录，非 URN）
- **典型 provenance**：
  - `consumes`：若干 `code.*` artifact（该 unit 的所有代码产物）
  - `emits`：`artifact.build_output`（新派生类型，见 §4 N1）
- **关联 L1 事件**：`task.started` / `task.progress`（长时任务，每分钟一次 heartbeat） / `task.completed` / `task.failed`
- **不变量回顾**：
  - `type` → `base="integration"` ✅
  - kernel drift / snapshot 不进入 host_build 产出的内部（kernel 只看 URN 与 pass 字段）

---

## 3. 类型之间的拓扑约束

虽然 kernel 扩展点 A 本身**不关心**派生类型之间的拓扑，但 adapter 可以在自己层面做约束（kernel §2 明确允许 "`adapter` 派生字段不进入 kernel 机制"）：

### 3.1 允许的上游关系（adapter 层校验，非 kernel 强制）

```
unit_bootstrap  ──▶  component_migration
                 └▶  viewmodel_migration

component_migration ──▶  module_migration（若 child_count ≥ 2）

code.{component,module,viewmodel}
                    ──▶  static_analyzer_check
                    ──▶  screenshot_compare（仅对产出可见 UI 的类型）
                    ──▶  host_build（聚合）
```

### 3.2 禁止关系

- `screenshot_compare` **不得** 以 `static_analyzer_check` 为上游（二者都是 `verification`，是横向关系而非纵向）
- 任何 `verification` 类 task **不得** 作为 `code_gen` 类 task 的上游（"先验证再生成"在迁移场景中没有合法含义）

### 3.3 拓扑违规的处理

由本 adapter 的 TaskDAG 加载器在 IMPLEMENT 阶段发 L2 事件 `adapter.topology_violation`（挂 `taskdag.loaded` L1 事件），**不升级到 kernel 层**——因为 kernel §2 明确"adapter 派生字段不进入 kernel 机制"。

---

## 4. 写作过程中发现的新 kernel 压测点

> 本节是本文档作为"阶段 2 分支 2a 第 2 份 adapter 文档"的**核心职责**——继续压测 kernel 的边界，把 charter 没撞到的问题逼出来。

### [N1] `artifact.build_output` 是否属于 kernel `02 §2` 的合法派生？

- **触发**：写 §2.7 `host_build` 的 `emits` 字段时。
- **现状**：kernel `02 §2` 派生示例只列出了 `spec.structured` / `spec.api_contract` / `code.component` / `code.module` / `code.viewmodel` / `report.verify` 等，**没有 `build_output` 的派生示范**。
- **临时裁决**：沿用 `artifact_type: artifact.build_output`，即 kind 直接作为前缀——**这与 `02 §2.1` "kind 与 artifact_type 映射"的现有表述不冲突，但也不是示例中明确涵盖的路径**。
- **处置去向**：登记到 `_review/task-types-review.md §2`，作为阶段 2 的第 5 条 kernel 缺口（继承 charter-review Q2 的子问题）。

### [N2] `code.*` 派生类型的 kebab_case vs snake_case 未统一

- **触发**：写 §2.1/2.2/2.3 的 `emits` 字段与 charter §4.1 的 `component_migration` 对照时。
- **现状**：charter §4.1 表格写 `component_migration`（snake_case），而 kernel `02 §2` 示例示范用的是 `code.component`（dot.lowercase）。**派生名的命名风格 kernel 未硬约束**。
- **临时裁决**：
  - `task type` 名统一用 `snake_case`（本文件所用）
  - `artifact_type` 名统一用 `snake_case` 在 dot 分隔符之后（即 `code.component_migration_output` 若需要复合）
- **严重性**：**低**，但会影响未来多 adapter 的一致性。登记为 R5 候选。

### [N3] 扩展点 A 的"合规性测试集"在 kernel 中未定义

- **触发**：写 §1 类型总表时想做自测——发现 kernel `07 §2 扩展点 A` 只列了硬约束（`type` 字段可追溯 / kernel 只读共有字段），**没给出 adapter 如何自验证"我这份 task-types 合规"的最小测试脚本或 checklist**。
- **临时裁决**：本文件末尾 §6 给出一份自验证清单（**非 kernel 强制**，只是 adapter 内部的自律）。
- **严重性**：**中**，随着 adapter 数量增加会成为阻塞。登记为 R6 候选。

---

## 5. 本文件对 kernel 的承诺（`extends` 契约）

与 charter §5.1 承诺 1 / 4 一致，再具体到本扩展点：

1. 所有派生 task 类型在 `base` 列指向且仅指向 kernel 四个基础类型之一（见 §2 全表）
2. 不在本文件出现 `kind: task` 之外的新 kind（§3.3 违规处理的 `adapter.topology_violation` 是 L2 事件，不是 kind）
3. 所有派生 task 的**必需字段**中包含至少一个 kernel 可识别的锚点字段（`unit_urn` / `target_urn` / `consumes` URN 等），**保证 drift / trace / snapshot 能够作用在这些 task 上**——这是 charter §5.1 承诺 5 的具体化

---

## 6. 本 adapter 对自己的合规自验证清单

> 这是回应 §4 [N3] 的 adapter 内部自律。待 kernel 提供正式测试集后废弃本节。

- [x] `type` 列的所有值在 `base` 列都有合法对应
- [x] 每类的"必需字段"集合对 kernel 基础类型的共有字段形成**真超集**（不能是子集或等集）
- [x] 本文件的 front-matter `extends.kernel_anchor` 字段指向的 kernel 锚点真实存在（实测 `07 §2 扩展点 A` 在 kernel rev `m1_final_decisions@v1` 中）
- [x] §3.1 与 §3.2 的拓扑规则可以翻译为一个 DAG 合法性断言（adapter 加载 taskdag 时可执行）
- [x] 本文件跑 `kernel-wordcheck.sh --file` 返回 exit 0（实测 2026-04-18 23:00 通过；4 条 WARN 均为 `viewmodel` / `migration` 在 adapter 目录的合法使用）

---

## 7. 本文件的演进

- **当前 status**：`published`（2026-04-18 23:10，阶段 2 分支 2a 第 2 份 adapter 文档完成）
- **升级到 `published` 的条件**（已满足）：
  - [x] 配对产出 `_review/task-types-review.md`（强制三段式）
  - [x] `kernel-wordcheck.sh --file` 通过（4 条 WARN 均为 adapter 目录内合法使用）
  - [x] 本文件 §4 的 [N1]–[N3] 已写入 review §2 / §3（分别对应 Q5 / Q6 / Q7 + R5 / R6 / R7）
- **升 rev v2 的条件**：
  - 类型总表（§1）新增/删除任何一行
  - 任一类型的"必需字段"变化（字段新增算 v1.1 小升；字段删除算 v2 大升）
  - kernel 升级（如 `07` 扩展点 A 的硬约束变化）触发本文件 reconcile

---

**本文件状态**：published（2026-04-18 23:10）
**上游锚点**：`urn:piao:artifact:adapter/frontend_migration:charter@v1` + `kernel/07-extensibility.md §2 扩展点 A`
**配对 review**：`urn:piao:artifact:adapter/frontend_migration:task_types_review@v1`（**路径 A 推荐**：收敛 + kernel 小升）
**下游候选**：
- `M1-debt-ledger` rev v2→v3（追加 Q5-Q7）
- kernel 三文档小升 proposal（处理 R1-R7 的合并计划）
- `acceptance-criteria.md`（若选择路径 B 再写一份 adapter 文档）
