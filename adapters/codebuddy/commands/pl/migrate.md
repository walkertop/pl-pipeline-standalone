---
name: "PL: Migrate"
description: "一键全流程编排：proposal → plan → implement → verify → archive（pl-pipeline v1）"
argument-hint: "[change-id | 需求描述]"
---

**全自动编排器入口**：根据 `pl/changes/<id>/.state.md` 断点恢复，自动驱动 SPEC → PLAN → IMPLEMENT → VERIFY → (观察窗) → ARCHIVE 6 阶段流转，每个门禁停下来征求用户确认，通过后继续下一阶段。

---

## 输入

`$ARGUMENTS`：

- kebab-case change-id（已存在）→ 从当前 stage 续跑
- 自然语言需求描述 / 新 change-id → 从 SPEC 起步，先触发 `/pl:proposal`
- 省略：列出所有 change，让用户选

---

## 步骤

### 0. 入口调度

```bash
# 若编排器脚本可用，优先把控制权交给它（非阻塞模式，仍由 Agent 主导）
if [ -x scripts/pl-orchestrator.sh ]; then
  ./scripts/pl-orchestrator.sh --change <id> --status  # 仅读状态做展示
fi
```

Agent 读 `.state.md` 判定当前 stage + gate，按下表分发：

| 当前 stage / gate | 下一步动作 |
|---|---|
| 不存在 / 新 change | 走 `/pl:proposal` 流程（第 1 步） |
| SPEC (gate A0-pending) | 补齐 spec.md → 评 A0 → 进入 PLAN |
| PLAN (gate B1-pending) | 生成 plan/taskdag/api → 评 B1 |
| IMPLEMENT (gate C-inprogress) | 续跑任务 → 评 C |
| IMPLEMENT (gate C-passed) | → 进入 VERIFY |
| VERIFY (gate D/E pending) | 跑 self-check → 评 D → 评 E |
| VERIFY (gate E-passed) | 提示进入 OBSERVE，等待 N 天窗口 |
| OBSERVE (gate G-ready) | → 进入 ARCHIVE |
| ARCHIVED | 提示已归档，可查询 `pl/archive/` |

### 1. 在每个阶段转换处征求确认

**门禁评估后**，展示判据结果 + 用 AskUserQuestion：

```
## Gate B1 Evaluation

- TaskDAG generated (no cycles): ✓
- Component reuse analysis:      ✓ (42% reuse rate)
- Estimated hours per task:      ✓ (max 3.5h)

All criteria met. Proceed to IMPLEMENT?
[1] 批准开工
[2] 先查看 taskdag.md 详情
[3] 退回调整 plan
```

**从不自动跨门禁推进**。这是 migrate 与 explore 的核心差异：migrate 是 orchestration，不是 auto-pilot。

### 2. 阶段实现：委托给单阶段命令

每个阶段调用对应的 `/pl:*` 命令**同进程**执行其逻辑（读同一命令文件的 prompt，然后执行），而不是真正启动新 agent。次序：

1. `/pl:proposal`（仅 new change）
2. `/pl:plan`
3. `/pl:implement`（循环所有任务；期间每 N 个任务后打点询问是否继续）
4. `/pl:verify`
5. **观察窗**：展示 `verified_at`，等用户确认"观察期通过"后才进入 ARCHIVE
6. `/pl:archive`

### 3. 断点保存

每个阶段结束（或用户中断）时：

- 确保 `.state.md` 被更新（stage / gate / updated_at）
- Trace 事件已发（若脚本可用）
- 输出"下次可通过 `/pl:migrate <id>` 续跑"

### 4. 整体输出（每阶段末尾）

```
## Migrate Progress — <id>

✓ SPEC        (gate A0 passed @ 2026-04-20 14:32)
✓ PLAN        (gate B1 passed @ 2026-04-20 15:10)
▶ IMPLEMENT   (4/16 tasks done, gate C in progress)
  ─────────────────────────────────────
  ...continuing with T04 PriceCalculator
```

最终归档：

```
## Migration Complete — <id>

Stages: ✓ SPEC → ✓ PLAN → ✓ IMPLEMENT → ✓ VERIFY → ✓ OBSERVE → ✓ ARCHIVED
Total duration: X days
Archive: pl/archive/YYYY-MM-DD-<id>/

**Knowledge Harvested:**
- Skills updated: +2
- Rules updated:  +1
- error-log:      +4 entries

**Next cycle:** 下一次 `/pl:migrate` 将复用这些沉淀。
```

---

## Guardrails

- **门禁处必停**：每次 A0/B1/C/D/E/G 评估后必须 AskUserQuestion，不能一路闷头跑到底
- **不绕过子命令**：逻辑应复用 `/pl:proposal | plan | implement | verify | archive` 的 prompt，不允许把业务逻辑复制粘贴到本文件
- **观察窗**（VERIFY → ARCHIVE）必须人工确认，不能按"时间到自动归档"
- 若中途出现 blocker：立刻停，更新 .state.md，告诉用户 `/pl:explore <id>` 或手动解决
- 断电恢复场景：Agent 必须以 `.state.md` 为真相源，忽略对话历史中的"上次做到哪一步"口头声明
- 单次 migrate 会话超过 10 轮 Agent 交互：建议保存进度后让用户新开对话续跑，避免 context 爆

---

## 与单阶段命令的关系

```
/pl:migrate          = orchestrator
  ├─► /pl:proposal   (SPEC)
  ├─► /pl:plan       (PLAN, gate A0→B1)
  ├─► /pl:implement  (IMPLEMENT, gate B1→C)
  ├─► /pl:verify     (VERIFY, gate D→E)
  └─► /pl:archive    (ARCHIVE, gate G)
```

单阶段命令仍可独立使用；`/pl:migrate` 只是打包了"从当前 stage 持续推进到 ARCHIVE"的流程。
