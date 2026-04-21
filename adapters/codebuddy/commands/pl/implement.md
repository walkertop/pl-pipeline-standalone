---
name: "PL: Implement"
description: "按 taskdag.md 逐任务编码，管理 IMPLEMENT 阶段（pl-pipeline v1）"
argument-hint: "[change-id] [--task <task-id>]"
---

进入 IMPLEMENT 阶段：按 `pl/changes/<id>/taskdag.md` 的依赖顺序逐任务编码，实时勾选 `.state.md` Task Progress，达成 C 门禁（全部任务完成）后建议走 `/pl:verify`。

---

## 输入

- `$ARGUMENTS` = change-id [--task T0X]
- 若省略 change-id：选 `stage=PLAN` 或 `stage=IMPLEMENT` 的 change；多于一个用 AskUserQuestion
- `--task` 指定从某个任务续跑（断点恢复）

---

## 步骤

### 1. 首次进入 IMPLEMENT：关 B1 门禁

若 `.state.md` 的 `stage=PLAN, gate=B1-pending`：

- 复核 B1 判据（TaskDAG 无环 / reuse_rate 非空 / 工时 ≤4h）
- 展示 TaskDAG 概览 + 预估总工时 + 风险清单
- 用 AskUserQuestion 让用户正式批准：`批准开工` / `退回调整 plan`
- 批准后：`.state.md` 写入 `stage=IMPLEMENT, gate=C-inprogress`，记录 `implement_started_at`

### 2. 加载 TaskDAG

- 读 `pl/changes/<id>/taskdag.md`，解析成内部模型：`[{id, name, tier, deps, estimated_hours, status}]`
- 读 `.state.md` 的 Task Progress 节，合并当前 status（pending / in_progress / done / blocked）
- 进行拓扑排序，找出下一个**可开工**任务（所有 dep 的 status=done）

### 3. 选择本次要做的任务

- 若用户指定 `--task T0X`：校验其 deps 是否满足；不满足则报错说明缺哪些前置
- 否则：选**最早的可开工任务**（同 tier 内按 id 顺序）
- 广播："Working on: T0X <name>"

### 4. 读取任务上下文

对每个任务，读以下信息作为编码上下文：

- taskdag.md 中该任务的**产出 / 验收 / 测试锚点**
- plan.md 中相关的架构决策 / 组件复用指引
- api.md 中涉及的接口契约
- spec.md 中相关的 Feature 描述
- deps.md 中对应旧代码定位（若是迁移任务）

若任务涉及 Kuikly DSL / 组件 / Module → 主动调用 **kuikly-ui-framework** skill；涉及迁移规则 → 参考 **migration-rules** / **kotlin-coding-standards** rules。

### 5. 执行编码

**原则**：

- 最小 diff、范围聚焦
- 优先 replace_in_file（已有文件）或 write_to_file（新文件）
- 每写完一个文件立刻读 lints 检查语法错误
- 不写超出任务验收范围的代码

**本阶段允许调用**：

- 其他 skill：kuikly-* / kotlin-code-review / spec-normalizer
- 子 agent：`migration-coder`（大任务委托） / `module模块专家`（特定 Module 迁移）

### 6. 变更感知构建（BUILD-001-AUTO）

在任务结束前，调用：

```bash
./scripts/should-build.sh
```

若返回 `BUILD_NEEDED`：运行 `./scripts/build-all.sh`（或单平台），修复编译错误。

### 7. 标记任务完成

```bash
# 更新 .state.md Task Progress
# - [ ] T0X -> [x] T0X ... (status=done, finished_at=<ISO>)
```

发送 Trace 事件（降级）：

```bash
if [ -x scripts/pl-trace-emit.sh ]; then
  ./scripts/pl-trace-emit.sh \
    --change <id> --stage IMPLEMENT --event task.done \
    --task T0X
fi
```

### 8. 循环或停止

- 若还有可开工任务 → 回到第 3 步
- 若出现 **blocker**（验收不过 / 上下文不清 / 需要决策）：
  - 任务标记 `status=blocked`，在 .state.md 的 Open Questions 节记录原因
  - 停止循环，报告用户，等待指示
- 若全部 done → 评估 C 门禁

### 9. 评估 C 门禁（内部）

C 判据：所有任务 status=done。通过后：

- `.state.md` 写入 `gate=C-passed`
- 建议下一步：`/pl:verify <id>`

### 10. 输出摘要

**阶段性汇报**（每完成 1 个任务）：

```
## Implementing: <id>

✓ T0X: <name>   (Xh actual)
  - Changed: shared/.../page/<page>/data/Xxx.kt (new, 120 lines)
  - Tests:   shared/.../page/<page>/data/XxxTest.kt (new, 6 cases)
  - Lint:    PASS
  - Build:   PASS (needed=true)

Progress: N/M done  (Tier 0: K/L done)
Next: T0Y <name> (deps satisfied)
```

**全部完成**：

```
## IMPLEMENT Complete

**Change:** <id>
**Gate C:** PASSED (all M tasks done)
**Total actual hours:** <X>

**Next:** `/pl:verify <id>` 进入验证阶段
```

**暂停**：

```
## IMPLEMENT Paused

**Task:** T0X <name>
**Reason:** <blocker 详情>
**Status Snapshot:** N/M done, 1 blocked

**Options:**
1. 澄清 X 后继续
2. 拆任务：把 T0X 拆为 T0X.1 / T0X.2
3. 退回 /pl:plan 调整 TaskDAG

等待指示。
```

---

## Guardrails

- **严格按 DAG 顺序执行**，不跳任务
- **每个任务完成立即勾选**，不能等一批做完再一起勾（断电恢复依赖 state）
- **遇 blocker 立刻停**，不得 guess 后续
- **不要**在 IMPLEMENT 阶段修改 spec.md / taskdag.md（除非用户明确要求回 PLAN）
- **不要**跳过 should-build.sh 检查点
- 若任务实际工时 > 预估 1.5 倍，提醒用户是否拆分
- 所有 Kotlin 代码遵循 kotlin-coding-standards rule
- Kuikly DSL 代码遵循 kuikly-ui-framework skill
- 禁止在任务说明外引入无关 feature
