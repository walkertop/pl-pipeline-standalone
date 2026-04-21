---
name: "PL: Proposal"
description: "创建新 change，启动 SPEC 阶段（pl-pipeline v1）"
argument-hint: "[change-id | 需求描述]"
---

在 `pl/changes/<change-id>/` 下创建一个新 change 骨架，并生成 SPEC 阶段首批产物：`spec.md` + `.state.md`。

> **pl-pipeline 契约**：本命令操作的是 `pl/` 命名空间，不依赖 openspec CLI。详见 `docs/pl-pipeline/README.md`。

---

## 输入

`$ARGUMENTS` 可以是：

- **kebab-case change-id**（如 `migrate-order-detail-page`）：直接用它作为目录名
- **自然语言需求描述**（如 "把订单详情页从 Weex 迁成 Kuikly"）：提炼为 change-id
- **省略**：用 **AskUserQuestion tool** 追问 "What change do you want to work on?"

⚠️ 不要在没有理解用户意图的情况下继续。

---

## 步骤

### 1. 规范化 change-id

- 从 `$ARGUMENTS` 提取或生成 kebab-case 名（限 [a-z0-9-]，长度 ≤ 50）
- 广播："Using change: `<id>`（覆盖方式：`/pl:proposal <other-id>`）"
- 若 `pl/changes/<id>/` 已存在：
  - 用 AskUserQuestion 二选一：`继续补齐 spec` / `用另一个 id`

### 2. 创建目录骨架

```bash
mkdir -p pl/changes/<id>
```

### 3. 读取模板并生成骨架文件

从 `pl/templates/` 读取并写入 `pl/changes/<id>/`：

| 模板 | 目标文件 | 本阶段处理 |
|---|---|---|
| `spec.md` | `pl/changes/<id>/spec.md` | **必须**填充 Background / Goals / Non-Goals / Feature List（其他节留占位） |
| `state.md` | `pl/changes/<id>/.state.md` | **必须**填充：`stage=SPEC`, `gate=A0-pending`, 创建时间，artifacts 清单 |
| `deps.md` | `pl/changes/<id>/deps.md` | 可选：若用户提到旧代码路径则初始化 |

其他模板（`plan.md / taskdag.md / api.md / testmatrix.md`）留到 PLAN 阶段生成。

### 4. 采集 SPEC 最小信息

通过对话（必要时 AskUserQuestion）收集：

- **Background**（1-3 句背景 / 痛点）
- **Goals**（3-5 条主目标）
- **Non-Goals**（明确不做什么）
- **Feature List**（若是迁移场景，列出页面承载的核心功能模块）
- **Data Dependencies**（接口 / 模块依赖的初步清单，可留 TODO 待 PLAN 阶段展开）

若用户提供的是旧代码路径（如 `miniApp-js/src/views/xxx.vue`），应主动 read_file 扫描关键信号（methods / data / computed / `this.$request`），辅助填充 Feature List。

### 5. 写入 `.state.md`

必须包含以下字段（结构见 `pl/schemas/state.schema.json`）：

```markdown
# <change-id> · Pipeline State

- **stage**: SPEC
- **gate**: A0-pending
- **version**: pl@v1.0
- **created_at**: <ISO 8601>
- **updated_at**: <ISO 8601>

## Artifacts
- [x] spec.md （已创建骨架）
- [ ] plan.md
- [ ] taskdag.md
- [ ] api.md
- [ ] testmatrix.md
- [ ] deps.md （若已初始化则勾选）

## Task Progress
（本阶段为空，PLAN 阶段生成）

## Open Questions
（列出当前识别到的 BLOCKING 问题，关门禁 A0 时必须清零）

## Next Action
→ 补齐 spec.md 剩余节，关 A0 门禁，执行 `/pl:plan`
```

### 6. 尝试发送 Trace 事件（可选，降级友好）

```bash
if [ -x scripts/pl-trace-emit.sh ]; then
  ./scripts/pl-trace-emit.sh \
    --change <id> --stage SPEC --event artifact.created \
    --artifact spec.md,.state.md
fi
```

脚本不存在时静默跳过，不阻塞流程。

### 7. 输出摘要

```
## Proposal Created

**Change:** <id>
**Location:** pl/changes/<id>/
**Stage:** SPEC (gate A0 pending)

**Artifacts:**
- spec.md  （骨架已填：Background/Goals/Non-Goals/Feature List）
- .state.md （SPEC 阶段初始状态）
- deps.md  （若相关）

**Open Questions:** <N> 条待澄清

**Next Steps:**
- 若 Feature List 和 Data Dependencies 已明确 → `/pl:plan` 进入 PLAN 阶段
- 若仍有不清楚 → `/pl:explore <id>` 继续讨论
- 查看整体进度 → `/pl:status`
```

---

## Guardrails

- **不要**依赖任何 `openspec` CLI 命令（老版已废弃）
- **不要**直接写 `openspec/changes/<id>/`；本命令只操作 `pl/changes/<id>/`
- **不要**在 Open Questions 为空时就把 `gate` 写成 `A0-passed`，这是 `/pl:plan` 的职责
- **必须**用 `pl/templates/*.md` 作为结构基准，避免自由发挥
- 若用户明确说"顺便把 plan/taskdag 也生成"→ 提醒其改用 `/pl:migrate`
- 对含 Background/Goals 等节已完全就绪的老项目（从 openspec 迁过来），应主动识别并只补 `.state.md`，不要覆盖已有内容
