# .state.md 模板（pl-pipeline）

> 每个 change 的唯一真相源（Single Source of Truth）。
> Pipeline 中各 Agent 通过读写此文件传递状态、记录产物、追踪门禁。
> 位置：`pl/changes/<change-id>/.state.md`

---

## 使用说明

- **创建时机**：`/pl:proposal` 或 `pl-state-generator.sh` 自动创建
- **更新时机**：每个 Agent/脚本完成任务后更新对应章节
- **消费者**：`pl-orchestrator.sh` 读取 `Pipeline State` 决定下一步调度；Dashboard 扫描全局生成状态面板

---

## 模板

```markdown
# <change_id>.state.md
<!-- 生成时间: YYYY-MM-DD HH:mm -->
<!-- 最后更新: YYYY-MM-DD HH:mm by <agent_or_developer> -->
<!-- pl_version: pl@v1.0 -->

## Pipeline State
- stage: <SPEC|PLAN|IMPLEMENT|VERIFY|OBSERVE|ARCHIVE>
- gate_status: <PASSED|BLOCKED|SKIPPED|IN_PROGRESS>
- blocked_reason: "<reason_if_blocked>"
- last_transition: "<FROM> → <TO> at YYYY-MM-DD HH:mm"
- next_gate: <A0|B1|C|D|E|F|G|none>

## Change Meta
- change_id: <change-id>
- change_name: <中文变更名>
- business_domain: <交易|会员|活动|用户|营销|其他|基础设施>
- complexity: <🔴高|🟡中|🟢低>
- spec_ref: pl/changes/<id>/spec.md
- plan_ref: pl/changes/<id>/plan.md
- taskdag_ref: pl/changes/<id>/taskdag.md
- api_ref: pl/changes/<id>/api.md
- testmatrix_ref: pl/changes/<id>/testmatrix.md
- deps_ref: pl/changes/<id>/deps.md

## Artifacts（产物清单）

### 页面入口（迁移类 change 专用）
- page_entry: `<new-path>/<PageName>.<ext>`
- page_ui: `<new-path>/PageUI.<ext>`

### 数据层
- models: [page/<page_id>/data/<PageName>Models.kt]
- modules: [page/<page_id>/data/<PageName>Module.kt]
- data_store: <path_or_N/A>
- viewmodels: <paths_or_N/A>

### 组件层
- new_components: [<新建的组件列表>]
- reused_components: [<复用的通用/业务组件列表>]

### Mock & 测试
- mock_files: [<Mock JSON 文件路径>]
- trace_contract: <TraceContract 路径, 如有>

## Component Reuse（组件复用分析）

| 组件 | 来源层 | 复用方式 | 状态 |
|------|--------|---------|------|
| NavBar | Layer2 通用 | 直接复用 | ✅ |
| DJCLoading | Layer2 通用 | 直接复用 | ✅ |
| <Example>Component | Layer4 新建 | 新建 | ✅ |

- reuse_rate: <复用数>/<总组件数> = <百分比>
- candidates_for_promotion: [<可能抽象为通用组件的候选>]

## Self-Check Results（自检结果）

| 层 | 状态 | 详情 |
|----|------|------|
| 静态检查 (lint) | <✅ PASS / ❌ FAIL / ⏭️ SKIP> | <adapter 提供的 lint 工具结果摘要> |
| 编译 (compile) | <✅ PASS / ❌ FAIL / ⏭️ SKIP> | <$PL_BUILD_CHECK_CMD 结果> |
| 网络层 (network) | <✅ PASS / ⚠️ WARN / ❌ FAIL / ⏭️ SKIP> | <Mock fallback 测试结果> |
| 解析层 (parse) | <✅ PASS / ⚠️ WARN / ❌ FAIL / ⏭️ SKIP> | <宽松解析降级测试结果> |
| 渲染层 (render) | <✅ PASS / ⚠️ WARN / ❌ FAIL / ⏭️ SKIP> | <组件渲染结果> |
| 埋点 (tracking) | <✅ PASS / ⚠️ WARN / ❌ FAIL / ⏭️ SKIP> | <埋点对齐情况> |

## Task Progress（任务进度，同步自 taskdag.md）

| Task ID | 任务名 | 依赖 | 状态 | 完成时间 |
|---------|--------|------|------|---------|
| T01 | 页面骨架 | - | <⬜ TODO / 🔵 IN_PROGRESS / ✅ DONE / ❌ BLOCKED> | - |
| T02 | 数据模型 | - | ⬜ TODO | - |
| T03 | 数据模块 | T02 | ⬜ TODO | - |
| ... | ... | ... | ... | ... |

- total_tasks: N
- done_tasks: 0
- blocked_tasks: 0

## Open Questions（待确认项）

| ID | 问题 | 等级 | 状态 | 结论 |
|----|------|------|------|------|
| Q1 | <问题描述> | <BLOCKING / NON_BLOCKING> | <OPEN / RESOLVED / ASSUMED> | <结论或假设> |

## piao Artifact Registry（piao 对接，VERIFY/ARCHIVE 写入）

| URN | sha256 | stage | timestamp |
|-----|--------|-------|-----------|
| urn:piao:artifact:pl:<change>/spec.md@v1 | <sha256> | VERIFY | YYYY-MM-DD HH:mm |

## History（变更历史）

| 时间 | 操作者 | 阶段变更 | 说明 |
|------|--------|---------|------|
| YYYY-MM-DD HH:mm | Planner | → PLAN | 初始创建 |
```

---

## 字段说明

### Pipeline State

| 字段 | 值域 | 说明 |
|------|------|------|
| `stage` | `SPEC` / `PLAN` / `IMPLEMENT` / `VERIFY` / `OBSERVE` / `ARCHIVE` | 当前所在流水线阶段 |
| `gate_status` | `PASSED` / `BLOCKED` / `SKIPPED` / `IN_PROGRESS` | 当前阶段的门禁状态 |
| `blocked_reason` | 字符串 | 仅 BLOCKED 时填写 |
| `last_transition` | 格式: `FROM → TO at time` | 最近一次阶段转换记录 |
| `next_gate` | `A0 / B1 / C / D / E / F / G / none` | 下一个要过的门禁 |

### Stage 转换规则（详见 `pl/config.yaml` 的 gates 节）

```
SPEC ──[A0]──▶ PLAN ──[B1]──▶ IMPLEMENT ──[C/D]──▶ VERIFY ──[E]──▶ OBSERVE ──[F/G]──▶ ARCHIVE
```

### Self-Check 状态定义

| 状态 | 含义 | Pipeline 行为 |
|------|------|--------------|
| ✅ PASS | 完全通过 | 继续推进 |
| ⚠️ WARN | 通过但有降级 | 继续推进，标记待优化 |
| ❌ FAIL | 未通过 | 阻塞，gate_status → BLOCKED |
| ⏭️ SKIP | 跳过（不适用或条件不满足） | 不影响推进 |

### 谁读谁写

| Agent/脚本 | 读 | 写 |
|-----------|----|----|
| **spec-normalizer / migration-analyzer** | spec.md, plan.md | 创建文件, Pipeline State, Change Meta, Artifacts(初始), Task Progress, Component Reuse |
| **migration-coder** | Task Progress, Component Reuse | Artifacts(更新), Task Progress(标记完成) |
| **module模块专家** | Artifacts | Artifacts(补充 Module 产物) |
| **pl-migration-verify.sh** | - | Self-Check Results |
| **migration-guardian** | Self-Check Results | Pipeline State(推进 stage), Open Questions |
| **knowledge-archiver** | 全部 | History, Component Reuse(候选推广), Pipeline State(→ ARCHIVE), piao Artifact Registry |
| **pl-orchestrator.sh** | Pipeline State, Self-Check Results, Task Progress | Pipeline State (阶段转换), History |
| **开发者** | 全部 | Open Questions(回复), Pipeline State(手动推进) |
