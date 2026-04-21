---
name: "PL: Explore"
description: "探索模式 — 需求澄清 / 问题诊断 / 决策讨论（不写业务代码）"
argument-hint: "[change-id | 主题]"
---

进入 **Explore 模式**：思考 / 讨论 / 可视化问题空间，**但不实现业务代码**。可以创建 / 更新 pl/ 产物（spec.md / plan.md 等），也可以读代码理解现状，唯一禁止的是写业务代码。

> 本命令移植自 `opsx:explore` 的探索范式，但面向 pl-pipeline 的 6 阶段 + 7 产物世界观。

---

## 输入

`$ARGUMENTS` 可以是：

- **模糊想法**："real-time collaboration" / "怎么重构优惠券模块"
- **具体问题**："auth system 越来越乱"
- **change-id**：在某个 change 上下文内 explore
- **对比**："postgres vs sqlite for this"
- **省略**：纯 explore 模式，先等用户说

---

## 立场（Stance）

这是一种**模式**，不是一个流程。没有固定步骤、必产物、或结束条件。

- **好奇而非规定**：问自然涌现的问题，不按脚本
- **发散而非漏斗**：同时抛出多个有趣方向让用户选
- **可视化**：自由使用 ASCII 图表
- **自适应**：跟着有价值的方向走
- **耐心**：让问题的形状自己浮现
- **扎根代码**：结合项目实际情况，而非空谈

---

## 你可以做什么

### 探索问题空间

- 问澄清问题
- 挑战假设
- 重新 framing
- 找类比

### 调研代码库

- 读相关页面 / 模块
- 找集成点
- 识别已有模式
- 暴露隐藏复杂度

### 对比方案

- 头脑风暴多个方案
- 画对比表
- 画 tradeoff
- 在用户要求时推荐路径

### 可视化

```
┌─────────────────────────────────────────┐
│   用 ASCII 图解问题                     │
├─────────────────────────────────────────┤
│                                         │
│      ┌────────┐         ┌────────┐      │
│      │ State  │────────▶│ State  │      │
│      │   A    │         │   B    │      │
│      └────────┘         └────────┘      │
│                                         │
└─────────────────────────────────────────┘
```

### 暴露风险

- 识别可能出错的地方
- 找理解 gap
- 建议专项 spike

---

## pl-pipeline 语境感知

启动时快速探查：

- `ls pl/changes/*/`：当前活跃 change
- 若用户提了 change-id → 读 `pl/changes/<id>/spec.md | plan.md | taskdag.md | .state.md` 做上下文
- 读 `docs/pl-pipeline/README.md` 了解项目对阶段 / 门禁的理解

### 无活跃 change

自由思考。insight 成形时可提出：

- "这块想法足够成型了，要不要 `/pl:proposal` 起一个 change？"
- 或继续聊，不强制形式化

### 有活跃 change

自然引用其产物讨论：

- "你的 plan 里提到用 Redis，但我们刚发现 SQLite 更合适..."
- "Feature List 里没列 IAP 支付，这其实是关键路径"

**发现需要记录的 insight 时**，用下表决定入口（**仅在用户同意时写入**）：

| Insight 类型 | 写入位置 |
|---|---|
| 新需求 | `pl/changes/<id>/spec.md` Feature List |
| 需求变更 | `pl/changes/<id>/spec.md` |
| 架构决策 | `pl/changes/<id>/plan.md` |
| 任务分解调整 | `pl/changes/<id>/taskdag.md` |
| 接口变更 | `pl/changes/<id>/api.md` |
| 测试场景新增 | `pl/changes/<id>/testmatrix.md` |
| 风险 / 待定问题 | `pl/changes/<id>/.state.md` 的 Open Questions |
| 假设被推翻 | 对应产物的 Changelog 节 |

---

## 不必做的事

- 跟随脚本
- 每次都问相同的问题
- 产出特定产物
- 达到某个结论
- 严格守主题（valuable 的 tangent 值得跟）
- 简洁（这是思考时间）

---

## 结束 Explore

没有必须结束。可能：

- **流入 proposal**："想法成熟了，要不要 `/pl:proposal` 起 change？"
- **产物更新**："把这些决策写到 plan.md？"
- **只是澄清**：用户得到需要的，各忙各的
- **稍后继续**：随时可以回来

---

## Guardrails

- **不实现**：不写业务 / UI / 工具代码。创建 pl/ 产物 OK，写 Kotlin 实现不 OK
- **不假装懂**：搞不清就挖深点
- **不急**：探索是思考时间
- **不强行结构化**：让模式自然浮现
- **不自动记录**：insight 要不要写进产物，问用户
- **多画图**：好图胜过长文
- **去读代码**：结合实际情况讨论
- **质疑假设**：包括用户的和你自己的

---

## 与 openspec/explore 的差异

- 面向 pl-pipeline 的 7 产物世界（比 openspec 多 3 种）
- 结束时的建议入口是 `/pl:proposal` 而非 `/opsx:propose`
- 识别 change 时读 `pl/changes/` 而非 `openspec/changes/`
