---
name: "PL: Plan"
description: "从 spec.md 拆分 TaskDAG，过 A0 门禁进入 PLAN→IMPLEMENT（pl-pipeline v1）"
argument-hint: "[change-id]"
---

从 `pl/changes/<id>/spec.md` 出发，生成 PLAN 阶段的三件产物：`plan.md` / `taskdag.md` / `api.md`（可选 `testmatrix.md` 骨架）；闭合 A0 门禁，将 `.state.md` 推进到 `stage=PLAN, gate=B1-pending`。

---

## 输入

`$ARGUMENTS` = change-id。若省略：

1. 列出 `pl/changes/*` 中 `stage ∈ {SPEC, PLAN}` 的 change
2. 用 AskUserQuestion 让用户选（**不要猜**）

广播："Using change: `<id>`（覆盖方式：`/pl:plan <other>`）"。

---

## 步骤

### 1. 加载当前状态

读取：

- `pl/changes/<id>/.state.md`：解析 stage / gate / open_questions
- `pl/changes/<id>/spec.md`：解析 Goals / Feature List / Data Dependencies / Non-Goals
- `pl/changes/<id>/deps.md`（若存在）：旧代码依赖分析
- `pl/config.yaml`（全局 gates 判据）

### 2. 评估 A0 门禁

A0 判据（来自 `pl/config.yaml`）：

- [ ] **功能清单完整**：spec.md 的 Feature List 无 TODO / 空占位
- [ ] **Open Questions 清零**：`.state.md` 的 Open Questions 节无 BLOCKING 级条目
- [ ] **接口依赖明确**：spec.md 的 Data Dependencies 已列出具体接口/模块

**若 A0 未通过**：

- 列出未通过项
- 用 AskUserQuestion 让用户选：`补齐后继续` / `退回 /pl:explore`
- 本次不推进 stage

**若 A0 通过**：写入 `.state.md`：`gate=A0-passed`，继续。

### 3. 生成 plan.md（PLAN 阶段产物）

基于模板 `pl/templates/plan.md`，读取 spec.md 后**推导**填充：

- **架构决策**（基于项目 Card / MVVM 规则 + kuikly-ui-framework skill）
- **风险评估**（接口变化风险、UI 还原风险、性能风险、兼容性风险）
- **里程碑**（基于 Feature List 粗排 Tier）
- **组件复用分析**（扫描 `shared/.../page/*/component/` 找可复用组件，填 `reuse_rate` 预估）

必要时调用 `migration-analyzer` 子 agent 做深度依赖分析（若旧代码较复杂）。

### 4. 生成 taskdag.md（PLAN 阶段产物）

基于模板 `pl/templates/taskdag.md`，按 Tier 拆分：

- **Tier 0**：数据模型、配置常量、独立纯函数
- **Tier 1**：领域服务、Repository
- **Tier 2**：ViewModel、组件
- **Tier 3**：页面组装、支付等跨模块链路
- **Tier 4+**：打磨、埋点、回归

**每个任务必须包含**：

- `id`（T01 / T02 / ...）
- `name`
- `tier`
- `estimated_hours`（必须 ≤ 4h，超过则拆分）
- `deps`（前置任务 id 列表，DAG 校验：不能有环）
- `产出文件`（绝对路径或 `shared/.../*`）
- `验收` / `测试锚点`

**DAG 合法性校验**：

- 无环（拓扑排序应能完成）
- 所有 dep 都指向已声明任务

### 5. 生成 api.md（PLAN 阶段产物）

基于模板 `pl/templates/api.md`，为 spec.md 的 Data Dependencies 中每个接口写：

- 请求方法 / 路径 / 入参 / 出参（引用 `shared/.../utils/ReqConfig.kt` 现有 const 或新增声明）
- 错误码 → 降级策略
- Mock 降级示例

### 6. （可选）生成 testmatrix.md 骨架

若 spec.md 的 Feature List 明确，建议直接按 skills/kuikly-test-generator 风格写出关键用例骨架；否则留到 IMPLEMENT 阶段 T01~T07 过程中增量生成。

### 7. 评估 B1 门禁

B1 判据：

- [ ] **TaskDAG 生成且无环**（第 4 步已验证）
- [ ] **组件复用分析完成**（plan.md 的 reuse_rate 非空）
- [ ] **工时预估合理**（每个任务 ≤ 4h）

若全通过：`.state.md` 写入 `stage=PLAN, gate=B1-pending`（真正关 B1 发生在 `/pl:implement` 第一任务开工前，由用户批准触发）。

若未全通过：列出未通过项，不推进 stage，指导用户补齐。

### 8. 更新 `.state.md`

```markdown
- **stage**: PLAN          ← 已切换
- **gate**: B1-pending
- **updated_at**: <ISO>

## Artifacts
- [x] spec.md
- [x] plan.md
- [x] taskdag.md
- [x] api.md
- [ ] testmatrix.md  （可选，推荐尽早）
- [ ] deps.md

## Task Progress
（共 N 个任务，按 TaskDAG 生成，全部 status=pending）

## Next Action
→ `/pl:implement <id>` 开始编码
```

### 9. Trace 事件（降级友好）

```bash
if [ -x scripts/pl-trace-emit.sh ]; then
  ./scripts/pl-trace-emit.sh \
    --change <id> --stage PLAN --event plan.generated \
    --gate A0-passed --artifacts plan.md,taskdag.md,api.md
fi
```

### 10. 输出摘要

```
## PLAN Generated

**Change:** <id>
**Stage:** SPEC → PLAN (gate A0 closed, B1 pending)

**Artifacts:**
- plan.md       架构 / 风险 / 里程碑 / 组件复用（reuse_rate=<N>%）
- taskdag.md    <N> 个任务 / <M> 人天 / Tier0-<K>
- api.md        <I> 个接口

**TaskDAG Preview (Tier0):**
- T01 ... (Xh)
- T02 ... (Xh)
- ...

**Risks Identified:**
- ...

**Next Steps:**
→ 用户确认 TaskDAG 合理后执行 `/pl:implement <id>`
→ 或用 `/pl:explore <id>` 讨论某个风险 / 决策
```

---

## Guardrails

- **必须**先评估 A0 门禁，不通过不推进
- **必须**做 DAG 无环校验（不能有 T01→T02→T01）
- **必须**每任务工时 ≤ 4h；超过要强制拆分（跟 pl/config.yaml B1 判据对齐）
- **不要**生成超过 30 个任务的 TaskDAG（>30 说明粒度过细，应聚合）
- **不要**在 `.state.md` 直接写 `gate=B1-passed`，真正闭合由 implement 命令触发
- 对有 openspec 遗产的项目：能复用 `openspec/changes/<id>/TaskDAG.md` 的就复用，在 plan.md 中注明来源
- 调用 migration-analyzer subagent 前先尝试自行解析；只有依赖链复杂度 ≥ 3 层时才委托
