---
urn: urn:piao:artifact:adapter/frontend_migration:charter@v1
artifact_type: spec.charter
kind: artifact
rev: v1
status: published
schema_version: 1.0
created_at: 2026-04-18T22:15:00+08:00
published_at: 2026-04-18T22:30:00+08:00
created_by_event: manual-charter-bootstrap-260418
content_sha256: ""
depends_on:
  - urn:piao:snapshot:kernel:m1_final_decisions@v1
  - urn:piao:artifact:architecture:layered_architecture@v1
  - urn:piao:rule:scenario_wordlist@v1
upstream_kernel_rev: m1_final_decisions@v1
produced_by:
  actor: human:caleb
  task_urn: urn:piao:task:adapter/frontend_migration:charter_bootstrap
  event_id: manual-charter-bootstrap-260418
---

# Frontend Migration Adapter · 00 Charter

> 本文件是 **frontend-migration adapter 的身份宪章**，首次把 kernel 的 7 维契约落到一条真实的业务工作流上。
> 定位：`adapters/README.md` 清单中的第一个正式 adapter 入口。
> 上游：`docs/piao-pipeline/kernel/_review/post-m1-kickoff.md §3` 阶段 1 产出清单。

---

## 0. Charter 的定位

本文件回答五个问题，**每一条都必须显式对应到 kernel 的某一段契约**；回答不上的问题登记到 `_review/adapter-charter-review.md §2`。

1. 这个 adapter **为什么存在**？它要解决什么 kernel 通用契约无法直接表达的业务问题？
2. 它的 **scope 边界** 在哪里？哪些场景归它管、哪些不归？
3. 它声明的 **四个扩展点** 分别占位了什么？
4. 它消费哪些 kernel published 契约？它对 kernel 的**承诺**与**诉求**各是什么？
5. 它的 **退出阶段 1 的验收清单** 是什么？（与 post-m1-kickoff §2.2 门控一一对应）

---

## 1. 身份声明

### 1.1 基本信息

| 项 | 值 |
|----|---|
| adapter 名 | `frontend-migration` |
| URN scope 约定 | `adapter/frontend_migration` 作为 `adapter.*` 工具产出物的 URN scope 前缀（如 `urn:piao:artifact:adapter/frontend_migration:charter@v1`） |
| 业务实体 scope 约定 | 业务单元（被迁移的 UI 单元）直接使用其 unit 名作为 scope，**不加 adapter 前缀**（如 `urn:piao:artifact:prop_confirm:structured_spec@v1`） |
| 上游 kernel rev | `m1_final_decisions@v1`（2026-04-18 快照） |
| 当前 status | `draft`（阶段 1 产出中；门控满足后升 `published`） |

### 1.2 adapter scope 与 unit scope 的两段分工

这是 adapter 与 kernel 之间**最容易出错**的约定，显式锁定：

| 场景 | URN 示例 | scope 写法 | 理由 |
|------|---------|-----------|------|
| adapter 本身的资产（charter / task-types / acceptance 注册表） | `urn:piao:artifact:adapter/frontend_migration:charter@v1` | `adapter/frontend_migration` | 这类资产**随 adapter 升版而升版**，与业务单元无关 |
| 业务单元的产物（某个被迁移单元的 structured_spec / taskdag / code） | `urn:piao:artifact:prop_confirm:structured_spec@v1` | 直接用 unit 名 `prop_confirm` | 按 `kernel/01-identity-model.md §3.1`，业务资产的 scope 段应以 unit 名开头；该资产"属于"unit，不"属于"adapter |
| 跨业务的 adapter 规则（如 frontend-migration 通用 lint 规则） | `urn:piao:rule:frontend_migration_lint@v1` | 无 unit 前缀；rule 名自身已是 adapter 约定 | 按 §3.1，无 unit 前缀的 rule 被识别为"跨项目/跨 unit 通用" |

> **为什么不把所有东西都放在 `adapter/frontend_migration` 下**：kernel §3.3 校验器规则——"位于 `adapters/A/` 下的文件引用了 `adapters/B/` 的 URN → 拒绝"。如果业务资产也挂在 adapter scope 下，未来第二个 adapter 要引用业务单元的产物就会被校验器误拒。业务产物本质属于 unit，不属于某个 adapter。

---

## 2. 业务问题陈述（一句话与三段论）

**一句话**：把存量的 source framework 业务单元（UI 页面 / feature 模块）**可追溯地**重写为当前 host language + declarative UI DSL 的工程产物。

**三段论**：
- **起点**：多个 legacy source 实现的业务单元散落在 `miniApp-js/` 等目录下，缺乏结构化 spec、缺乏迁移过程的事件流、缺乏 drift 检测。
- **终点**：每个被迁移的 unit 产出一份 structured_spec / api_contract / taskdag / code / verify_report，全部带 URN、带 provenance、全部可被 drift 引擎消费。
- **adapter 存在的必要性**：kernel 不含"迁移"概念（kernel 只有通用的 `spec` / `code` / `verification`），把"legacy → target"这一业务过程翻译成一串合法的 kernel 事件与 artifact，**这个翻译层就是 frontend-migration adapter**。

---

## 3. scope 边界：哪些归我管

### 3.1 归 adapter 管的业务场景

| 业务场景 | 典型产物 |
|---------|--------|
| 单个 UI 单元（页面 / feature）从 legacy source 迁到 target DSL | `structured_spec` / `taskdag` / `code.page_ui` / `code.viewmodel` / `verify_report` |
| 迁移过程中的代码规范静态检查 | `report.lint` |
| 迁移完成后的像素/截图比对 | `asset.screenshot` / `report.screenshot_diff` |
| 迁移经验沉淀（error-log 条目 → evolution_source） | `rule.updated` 事件 + `evolution_source` 条目 |

### 3.2 不归 adapter 管（由 kernel 或其他 adapter 处理）

| 不归本 adapter 管 | 实际归属 |
|------------------|---------|
| URN grammar 改动 / kind 枚举扩展 | kernel（`07-extensibility.md §1` 边界 2） |
| L1 事件 schema 的结构性变更 | kernel（`03-layered-architecture.md §3.1`） |
| 后端 API 规范治理 | 未来某个 `backend-api-spec` adapter |
| 设计稿/原型的正向生成 | 不在 piao-pipeline 当前 v0.1 范围内 |

### 3.3 与既有项目资产的对齐

本 adapter **不是凭空新建**——项目中已有以下资产是本 adapter 未来要"吸收/结构化"的原材料，但**在本 charter 中仅做登记，不做承诺**：

- `openspec/**`：现有的变更提案流程
- `scripts/migration-*.sh`：现有的迁移验证/日志分析脚本
- `.codebuddy/skills/*`：现有的迁移相关技能（如 `weex-migration-analyzer`）
- `docs/errors/error-log.md`：现有的迁移错误日志

"如何对齐"放在后续文档（`10-integration-map.md` 或 `evolution-sources.md`），charter 只负责说明"它们存在且属于本 adapter 的责任领域"。

---

## 4. 四个扩展点的占位声明

> 按 `kernel/07-extensibility.md §2` 宪章，adapter **必须**在这四个扩展点上做出显式声明；允许占位，但不允许沉默。

### 4.1 扩展点 A · Task 类型注册

**占位清单**（正式 schema 放在后续的 `task-types.md`）：

| 派生任务类型 | 继承的 kernel 基础类型 | 语义 |
|-------------|----------------------|------|
| `component_migration` | `code_gen` | 迁移单个 UI 组件 |
| `module_migration` | `code_gen` | 迁移一个 feature 模块 |
| `viewmodel_migration` | `code_gen` | 迁移一个 ViewModel |
| `screenshot_compare` | `verification` | 截图基线对比 |
| `static_analyzer_check` | `verification` | 静态检查（绑定 §4.2） |
| `host_build` | `integration` | 目标平台构建产物 |

**不变量承诺**（对应 kernel §2 扩展点 A 的硬约束）：
- 每个 task 的 `type` 字段必须能追溯到上述某条 `base` 类型
- drift / trace / snapshot 只读基础类型共有字段，adapter 派生字段不进入 kernel 机制

### 4.2 扩展点 B · Acceptance Criteria 注册

**占位清单**（正式 YAML 放在后续的 `acceptance-criteria.md`）：

| 验收名 | kernel 基础信号类 | 绑定脚本 | pass 条件 |
|--------|-----------------|---------|----------|
| `frontend_migration_lint` | `static_check` | `scripts/lint.sh` + `scripts/kuikly-migration-lint.sh` | `exit_code == 0` |
| `host_build_apk` | `build_artifact` | `scripts/build-android.sh` | apk 产出且 sha256 可计算 |
| `host_build_bundle` | `build_artifact` | `scripts/build-ios.sh` | bundle 产出且 sha256 可计算 |
| `runtime_trace_check` | `runtime_signal` | `scripts/migration-logcat-analyzer.sh` | 结构化日志通过契约 |
| `screenshot_diff_check` | `runtime_signal` | `scripts/auto-test-runner.sh` | 差异像素率 < 阈值 |

**不变量承诺**：
- 每个 criterion 必属上述三类信号之一
- gate 评估只读 `pass` 字段和 `class`

### 4.3 扩展点 C · Trace 实现

**占位声明**（正式说明放在后续的 `trace-impl.md`）：

- 实现基底：项目已有的 `scripts/trace-emit.sh` + `pipeline-output/trace/*.events.jsonl`
- 接口映射（对应 kernel §2 扩展点 C 的 TraceImpl 接口）：
  - `enterContext(context_carrier)` ← bash `source scripts/trace-emit.sh` 后的函数调用上下文
  - `emit(event_type, payload)` ← `trace_emit` shell 函数
  - `attachToArtifact(artifact_urn)` ← 事件 payload 的 `subject` 字段
- 合规性测试：留待 kernel 提供"合规性测试集 v0.1"后补做（kernel §2 扩展点 C 本就标注"可后补"）

### 4.4 扩展点 D · Evolution Source 注册

**占位清单**（正式注册放在后续的 `evolution-sources.md`）：

| source URN | L1 索引来源 | 触发信号 |
|------------|-----------|---------|
| `urn:piao:evolution_source:frontend_migration:error_log@v1` | 结构化升级后的 `docs/errors/error-log.md` | drift 检测到某 unit 的 `report.verify` 变红 |
| `urn:piao:evolution_source:frontend_migration:component_reuse_log@v1` | 组件复用统计（待新增） | 新 unit 起 taskdag 时自动查询 |

**不变量承诺**：
- 每个 source 实现 `index()` / `detail(entry_id)` / `on_match(trigger_signal)` 接口（kernel §2 扩展点 D）
- source 注册进 kernel 后，kernel 可按触发信号路由到对应 `on_match`

---

## 5. 对 kernel 的承诺 & 对 kernel 的诉求

### 5.1 承诺（本 adapter 必守，违反即本 adapter 工程失败）

1. 不扩展 kernel 的 `kind` 枚举（`01 §2`）
2. 不扩展 L1 事件根命名空间（`07 §1 边界 2`）
3. 不跨 adapter 直接引用（`01 §3.2` / `07 §1 边界 3`）
4. 所有 adapter 产出的 artifact 使用 kernel 已注册 kind（扩展 `artifact_type` 走 §2.1 的 `.` 分层）
5. 所有 L2 事件挂到某条 L1 事件下（`03 §2.3`）
6. 不在本 adapter 目录外出现 adapter 专有概念（`07 §6` 维护规则）

### 5.2 诉求（本 charter 在 kernel 中**找不到现成答案**的地方）

> 此列表即 `_review/adapter-charter-review.md §2` 的实际输入。**不在此处直接抱怨**；诉求的具体条目与优先级在 review 文档里登记。

- [N1] adapter scope 与 unit scope 的分工（本文件 §1.2）— 现有 kernel 文本里隐含但未显式写明
- [N2] `artifact_type: spec.charter` 是否需要在 kernel `02 §2` 的表格里作为合法派生登记？
- [N3] 四扩展点的"占位声明格式"是否有 kernel 规定的最小字段集？

---

## 6. 阶段 1 的退出验收清单

对应 `kernel/_review/post-m1-kickoff.md §2.2` 三条门控：

- [x] 本 charter 显式引用 kernel ≥5 篇章节锚点（实际引用：`00-overview §1` + `01 §1/§2/§3` + `02 §1/§2/§6` + `03 §2/§3` + `07 §1/§2/§6` + `scenario-wordlist §2`，远超门槛；详见 `_review/adapter-charter-review.md §1` 的 15 处锚点清单）
- [x] `./scripts/kernel-wordcheck.sh --file docs/piao-pipeline/adapters/frontend-migration/00-charter.md` 返回 exit 0（实测 2026-04-18 22:25 通过；3 条 WARN 均为 adapter 目录下合法使用）
- [x] `_review/adapter-charter-review.md` 已产出且含三段（锚点列表 15 处 / kernel 中找不到答案的问题 4 条 / 对 kernel 的建议修订 4 条）

**阶段 1 门控状态**：✅ 全部满足，本 charter 从 `draft` 升级为 `published`（2026-04-18 22:30）。

### 6.1 待后续文档补齐的清单

本 charter **不承诺**的产出，留给后续 adapter 文档或 `M1-debt-ledger.md §1.2` 登记：

| 待补项 | 去向 |
|-------|------|
| `task-types.md` 的正式 YAML | 阶段 2 起（分支 2a：作为第 2 份 adapter 文档） |
| `acceptance-criteria.md` 的完整清单 | 同上 |
| `trace-impl.md` 的合规性测试 | 等 kernel 提供"合规性测试集 v0.1" |
| `evolution-sources.md` 的 L1 索引 schema | 需 kernel 先在 M6 定义 EvolutionSource 接口细节 |
| 将 `kernel/02 §7 §10.1` 的 6 条 BAN 迁入本 adapter | 阶段 3（`02-artifact-model.md@v2` 落地时） |

---

## 7. 本 charter 的演进

- **当前 status**：`draft`（阶段 1 执行中）
- **升级到 `published` 的条件**：§6 三条门控全部 ✅
- **升 rev v2 的条件**：
  - §1.2 的 adapter scope 与 unit scope 分工被事实否决
  - §3.1 或 §3.2 的 scope 边界被重新划分
  - 四扩展点中任一出现**实现选型层级**的翻修（不是字段补充）
- **关闭条件**：本 adapter 产出"两份完整文档 + 一个业务单元被成功迁移并走完 verify"后，charter 进入 `superseded`，由第二版 charter 或 adapter 的 README 承接入口职责

---

**本 charter 状态**：published（2026-04-18 22:30，阶段 1 门控全满足）
**上游锚点**：`urn:piao:snapshot:kernel:m1_final_decisions@v1`
**配对 review**：`urn:piao:artifact:adapter/frontend_migration:charter_review@v1`（分支判定结果：**2a**，详见 review §2 小结）
**下游候选**：
- `_review/adapter-charter-review.md`（已产出，阶段 1 门控 3 ✅）
- `task-types.md` / `10-event-mapping.md`（阶段 2 起，按分支 2a 继续积累 kernel 缺口证据）
- 对 `02-artifact-model.md §2` 的派生类型登记请求（`spec.charter` 合法化，见 §5.2 N2 / review R2）
