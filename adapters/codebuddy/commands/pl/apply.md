---
name: "PL: Apply"
description: "实施已批准的 change（按 taskdag.md 逐任务完成），/pl:implement 的别名 / 轻量入口"
argument-hint: "[change-id]"
---

`/pl:apply` 是 **`/pl:implement` 的轻量封装**，专用于"change 已经在 IMPLEMENT 阶段、只想继续跑剩余任务"的场景。它不会重新走 B1 门禁对话，直接从 `.state.md` 断点恢复。

> 若 change 还在 PLAN 阶段（gate=B1-pending），请改用 `/pl:implement`（首次开工需要用户批准 B1 门禁）。

---

## 输入

`$ARGUMENTS` = change-id；省略时选 `stage=IMPLEMENT, gate ∈ {C-inprogress, C-blocked}` 的 change。

---

## 步骤

### 1. 前置校验

读 `pl/changes/<id>/.state.md`：

- 若 `stage ≠ IMPLEMENT`：
  - stage=SPEC → 报错，建议 `/pl:proposal` 补齐再 `/pl:plan`
  - stage=PLAN → 报错，建议先执行 `/pl:implement` 走 B1 门禁
  - stage ∈ {VERIFY, OBSERVE, ARCHIVE} → 报错，提示已过实现阶段
- 若 `gate = C-passed`：提示"所有任务已完成"，建议 `/pl:verify`
- 其他情况继续

### 2. 从 `.state.md` Task Progress 定位续跑点

- 拓扑排序所有 pending / blocked 任务
- 找下一个可开工任务（同 `/pl:implement` 第 2-3 步）
- 展示续跑概览：

```
## Resume Implementation

**Change:** <id>
**Progress:** 4/7 done, 1 blocked (T05)

**Next task to work on:** T06 CouponRepository (Tier 1, 3h)

Continue? [y/N]
```

### 3. 循环执行剩余任务

逻辑与 `/pl:implement` 第 4-8 步完全一致：

- 读上下文
- 编码
- should-build → build
- lint-fix
- 勾选 Task Progress
- Trace 事件
- 下一任务

### 4. 任务全完成后

- 评估 C 门禁（内部）
- `.state.md` 写 `gate=C-passed`
- 提示 `/pl:verify <id>`

### 5. 输出

与 `/pl:implement` 一致，但头部标注 `(resumed)`：

```
## Apply (Resumed)

**Change:** <id>
**Session:** Completed T06, T07 (2 tasks this session)
**Overall:** 6/7 done, 1 blocked

✓ T06: CouponRepository (3h actual)
✓ T07: GiveBean/CFMember/PropCheck Services (1h actual)

**Next:** T05 blocker 仍待澄清；或跳过 T05 后执行 `/pl:verify`
```

---

## Guardrails

- 本命令是 `/pl:implement` 的子集，**不处理 B1 门禁**
- stage=IMPLEMENT 时才能跑；其他阶段友好报错指引
- 不允许主动修改 taskdag.md；如需拆任务请回 `/pl:plan`
- 遇 blocker 行为与 `/pl:implement` 相同：停并报告
- 遵循所有 IMPLEMENT 阶段 guardrails（DAG 顺序 / 即时勾选 / 不跳 build 检查）
