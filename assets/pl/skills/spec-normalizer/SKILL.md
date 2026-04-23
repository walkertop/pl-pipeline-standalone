---
id: spec-normalizer
version: 1.0.0
scope: generic
category: spec
description: 需求标准化 Skill。将多形态需求输入（PRD/截图/文字/legacy代码/IM记录）转化为结构化 spec.md，同时可生成 API Contract 和 TaskDAG 初稿。触发词：需求标准化、生成 spec、normalize spec、规格书
migrated_from: KuiklyPolyCity@feature/caleb/agentic
sanitization_date: 2026-04-23
---

# Spec Normalizer · 需求标准化

## 概述

本 skill 是 pl-pipeline **SPEC 阶段**（门禁 A0）的实现，对应"需求工程师"角色。

**核心职责**：把多形态的需求输入（PRD / 设计稿截图 / 口头描述 / 旧代码 / IM 聊天记录）转化为结构化的 `spec.md`，为下游 planner 提供确定性输入。

**核心原则**：**输入质量决定输出质量。** 一个好的 PLAN 需要 3 个前置同时满足：
1. **需求清晰** — 本 skill 输出的 `spec.md`
2. **架构已知** — 项目的 `ARCHITECTURE_SNAPSHOT.md`（活文档，可为空）
3. **接口已锁定** — `api.md`（可在 B1 阶段由 planner 补齐）

---

## 核心能力

1. **多形态输入解析** —— 接受 PRD / 截图 / 文字 / 旧代码 / IM 记录，提取功能需求
2. **结构化 spec 生成** —— 输出标准化的 9 章节规格书
3. **组件/模块复用分析** —— 对照架构快照识别可复用单元，标注 "复用 vs 新建"
4. **接口契约前置**（可选）—— 当项目有接口目录/MCP 时拉取/验证 Schema
5. **不确定性分级 L1~L4** —— 见下文，区分 "自己推 / 标假设 / 列选项 / 暂停问"
6. **门禁自检** —— 输出是否满足 A0 → B1 过门条件

---

## 标准化工作流

### Step 1 · 收集需求输入

接受以下**任意组合**输入：

| 输入类型 | 获取方式 | 提取内容 |
|---------|---------|---------|
| PRD 文档 | 用户提供文件/链接 | 功能清单、优先级、验收标准 |
| 设计稿 / 截图 | 用户提供图片 | UI 结构、组件划分、交互说明 |
| 文字需求 | 用户直接描述 | 核心功能、业务场景 |
| 旧代码（legacy 迁移场景）| 分析 `<legacy-src>/<entry>` | 功能参照、接口列表、组件对应 |
| IM 聊天记录 | 用户粘贴 | 需求意图、约束条件 |
| 口头转述 | 用户概述 | 关键功能点 |

**关键动作**：
1. 用户提到 legacy 旧代码 → 调栈级 migration-analyzer skill（如存在）做依赖分析
2. 用户提供截图 → 解析 UI 区域划分，标注组件候选
3. 输入不够覆盖 9 章节 → 标记缺失项，进 Step 5 生成 `open_questions`

### Step 2 · 读取项目上下文

按优先级读取（**能读到哪些算哪些，不强求**）：

1. **`ARCHITECTURE_SNAPSHOT.md`**（项目根）
   - 可复用组件注册表 → 用于 Screen Map 的"复用 vs 新建"
   - 页面/路由注册表 → 确认命名规范
   - 模块注册表 → 可用的基础能力
2. **项目 spec 模板**（通常 `pl/templates/spec.md`）
3. **接口常量 / 路由文件**（项目常见位置：`<src>/api/`、`<src>/config/routes.*`）
4. **已有 `.state.md`**（`pl/changes/<change-id>/.state.md`）—— 检查是否是增量

**若项目没有 SNAPSHOT**：跳过组件复用分析章节，在产物里标 `architecture_snapshot: MISSING`，planner 阶段再补。

### Step 3 · 生成 spec.md（9 标准章节）

按 `pl/templates/spec.md` 输出：

| # | 章节 | 内容 | 质量标准 |
|---|------|------|---------|
| 1 | 基本信息 | id、业务域、入口、复杂度 | 所有字段非空 |
| 2 | 功能清单（R1/R2...）| 每个功能有 ID + 优先级（P0/P1/P2）+ 验收标准 | 至少 1 个 P0 |
| 3 | UI 结构（Screen Map）| ASCII 线框图 + 组件标注（可选章节：CLI/服务端类场景跳过）| 每区对应功能 ID |
| 4 | 数据依赖 | 接口列表 / DB Schema / 外部服务 | P0 项有明确 contract |
| 5 | 状态机（可选）| 多状态场景的状态图 | 覆盖所有显示/运行态 |
| 6 | 跳转 / 调用关系 | 入口 + 出口 + 参数 | 至少列出主入口 |
| 7 | 埋点 / 可观测（可选） | PV / 核心事件 / 日志 | 至少有 PV 或主事件 |
| 8 | Open Questions | BLOCKING / NON_BLOCKING 分类 | 每项有阻塞等级 |
| 9 | 验收基线 | 功能 + UI + 数据 + 性能 checklist | checkbox 格式 |

**组件标注规则**（Screen Map 中使用）：
```
标注                             含义
──────────────────────────────────────────────
← 复用: <ComponentName>          SNAPSHOT 中存在，直接复用
← 复用+适配: <ComponentName>     存在但需要 props/泛型调整
← 新建: <ComponentName>          SNAPSHOT 无匹配，需要新建
← 待定: [描述]                   不确定如何实现 → Open Question
```

### Step 4 · 生成配套文档（可选）

| 文档 | 触发条件 | 模板 |
|------|---------|------|
| `api.md` | 接口数 ≥ 2 或有复杂 Schema | `pl/templates/api.md` |
| `taskdag.md`（初稿）| 用户要求 "完整规划" | `pl/templates/taskdag.md` |
| `confirmation-request.md` | 有 BLOCKING 问题 | `pl/templates/confirmation-request.md`（可选） |

**接口目录集成**（可选，仅当项目接入接口管理 MCP/工具时）：
```
1. 按关键词搜接口 → 拿到候选列表
2. 获取接口 Schema
3. 拉取已有 Mock 用例（若有）
4. 无结果 → "需确认"登记到 Open Questions
```

### Step 5 · 不确定性分级 L1~L4

**这是本 skill 的核心决策协议**，不要跳过。

| 等级 | 定义 | Agent 行为 | 判断方法 |
|------|------|-----------|---------|
| **L1 确定** | 文档/代码中有明确答案 | 直接决策，不问人 | 查 SNAPSHOT / 现有代码 / 标准规范 |
| **L2 推断** | 可从上下文合理推断 | 标注假设，继续推进 | 有类似页面参照 / 默认值 |
| **L3 模糊** | 多种合理解释 | **列出选项、推荐一个**、标记待确认 | 业务逻辑不明 / 多方案 |
| **L4 未知** | 完全没信息 | **暂停，生成 confirmation-request** | 新接口 / 新概念 / 无参照 |

**规则**：
- L1 / L2：在 spec 的相关字段中**标注依据**（"assumes ..."），不阻塞
- L3：登记到第 8 章 `NON_BLOCKING`，按推荐选项推进；阶段过门仍可通过
- L4：登记到第 8 章 `BLOCKING`，同时生成 `confirmation-request.md`；**A0 软通过但提醒**

> 📖 这一节的**辩证态度**详见 [`docs/guides/working-with-fuzzy-intent.md`](../../../../docs/guides/working-with-fuzzy-intent.md)。
> 不要把 L1~L4 做成一次性穷举，而是**随对话推进逐层降级**。

### Step 6 · 门禁自检

输出前自动执行：

| 检查项 | 通过条件 | 阻塞等级 |
|--------|---------|---------|
| 功能清单完整 | 每个功能有 ID + 优先级 + 验收标准 | BLOCKING |
| UI 结构清晰（若适用） | Screen Map 能对应到功能清单 | BLOCKING |
| 数据依赖明确 | 每个 P0 功能标注依赖的接口/数据 | BLOCKING |
| 组件标注完成（若适用） | Screen Map 每区标注了复用/新建 | WARNING |
| Open Questions 已登记 | 所有不确定事项在第 8 章登记 | WARNING |
| BLOCKING 问题已解决 | 所有 BLOCKING 问题有结论（A0 硬通过入口）| BLOCKING |

**门禁结果**：
- ✅ 全部通过 → 输出完整 spec，可进 B1（硬通过）
- ⚠️ 有 WARNING 或 BLOCKING 项带推荐选项 → 输出 spec + `confirmation-request.md`，**A0 软通过**（Dashboard 亮黄，不阻塞 PLAN）
- ❌ 核心 BLOCKING 未解决（功能清单缺失 / 无 P0） → **暂停**，等用户补充

---

## 输出产物

### 主产物：`pl/changes/<change-id>/spec.md`

遵守 `pl/templates/spec.md`。

### 可选产物

| 文件 | 路径 | 条件 |
|------|------|------|
| `api.md` | `pl/changes/<change-id>/api.md` | 接口数 ≥ 2 |
| `confirmation-request.md` | `pl/changes/<change-id>/confirmation-request.md` | 有 BLOCKING 问题 |
| `taskdag.md`（初稿） | `pl/changes/<change-id>/taskdag.md` | 用户要求完整规划 |
| `deps.md` | `pl/changes/<change-id>/deps.md` | legacy 迁移场景 |

---

## 组件复用分析（A1 对齐，可选）

当项目有 `ARCHITECTURE_SNAPSHOT.md` 时：

```
对每个 UI 区域：
  1. 提取功能语义（如 "navbar" / "list" / "modal"）
  2. 查 SNAPSHOT 组件注册表
     ├─ 完全匹配 → 标 "复用: <Component>"
     ├─ 部分匹配 → 标 "复用+适配: <Component>" + 列差异
     └─ 无匹配  → 标 "新建: <Component>"
  3. 统计复用率 = 复用数 / 总组件数
     └─ 复用率 < 30% → 警告：是否遗漏了可复用组件？
```

**不要钦定组件目录**。项目可能是：
- Web：React / Vue / Svelte 组件库
- Mobile：Kotlin Compose / Swift UI / React Native
- CLI：subcommand / plugin 体系
- Backend：service module / middleware

语义匹配的"关键词表"由栈级 adapter 提供（`adapters/adapter-<stack>/skills/component-semantics.md`）。

---

## 与其他 Skill / Agent 的联动

| 阶段 | 联动对象 | 触发条件 | 数据流 |
|------|---------|---------|--------|
| A0 输入 | 栈级 `migration-analyzer` skill（若存在） | 用户提到 legacy 旧代码 | 依赖分析 → 功能参照 |
| A1 对齐 | 栈级 `component-library` skill（若存在） | 组件匹配时 | 确认组件 API |
| A2 契约 | 接口目录 MCP / 工具（若项目接入） | 需要 API Schema 时 | 拉 Schema 和 Mock |
| B1 输出 | `planner` agent | spec 完成后 | 作为 taskdag 生成输入 |
| B1 输出 | `.state.md` 文件 | spec 完成后 | 更新阶段 SPEC → PLAN |

---

## 使用示例

> 完整的示例 spec 见 [`examples/`](./examples/) 目录：
> - [`ecommerce-order-spec.md`](./examples/ecommerce-order-spec.md) — 电商订单场景
> - [`blog-system-spec.md`](./examples/blog-system-spec.md) — 博客系统场景

### 示例 1 · 从文字描述生成 spec

```
用户：帮我生成「图书借阅记录」页面的 spec

助手：
  1. 读 ARCHITECTURE_SNAPSHOT.md（如存在）了解项目结构
  2. 搜 legacy 代码 / 现有相似页面
  3. 扫描项目接口常量文件
  4. 生成 spec.md（9 章节完整输出）
  5. 标注可复用组件（NavBar / List / Loading 等）
  6. 标注 Open Questions（L3/L4 项目）
```

### 示例 2 · 从截图 + PRD 生成 spec

```
用户：这是新页面的设计稿和 PRD，帮我标准化需求
     [附带截图和 PRD]

助手：
  1. 解析截图 → 识别 UI 区域和组件
  2. 解析 PRD → 提取功能清单和优先级
  3. 对照 SNAPSHOT → 标注复用/新建
  4. 通过接口工具验证 API → 生成 api.md
  5. 输出 spec.md + api.md
  6. 如有 BLOCKING 问题 → 生成 confirmation-request.md
```

### 示例 3 · legacy 迁移生成 spec

```
用户：我要迁移 <legacy-src>/order-detail 页面

助手：
  1. 调栈级 migration-analyzer 分析 legacy 源码依赖
  2. 从旧代码提取功能清单（imports/methods/state）
  3. 从旧代码提取接口列表
  4. 对照 SNAPSHOT → 匹配可复用组件
  5. 生成 spec.md（迁移版，附 deps.md 说明旧→新映射）
  6. 标注差异项：哪些功能重设计
```

### 示例 4 · 增量更新已有 spec

```
用户：order-detail 的 spec 需要加「售后」功能

助手：
  1. 读现有 spec.md
  2. 在功能清单追加新 R-ID
  3. 更新 Screen Map（新 UI 区域）
  4. 更新数据依赖（新接口）
  5. 更新 Open Questions（若有）
  6. 重新执行门禁自检
  7. 写 trace 事件 spec.revision { delta: ... }
```

---

## 快速开始命令

```
# 标准流程
"帮我为 <change-id> 生成 spec"

# legacy 迁移
"帮我分析 <legacy-path>，生成迁移 spec"

# 带 API 契约
"帮我为 <change-id> 生成 spec 和 API 契约"

# 完整规划（spec + api + taskdag 初稿）
"帮我为 <change-id> 做完整规划"

# 门禁检查
"检查 pl/changes/<change-id>/spec.md 是否通过 A0 门禁"
```

---

## 辩证使用提示

本 skill 写的是**标准流程**，但真实使用时要辩证：

- **不要一次性穷举所有 L4 问题问用户**—— 那是 assumption dump 反模式
- **只问阻塞下一步的 3 个关键问题**，其他标 `(TBD)` 放 `open_questions`
- **spec 是对话不是命令** —— 允许 3~10 轮往返凝结
- **SPEC 可被 PLAN / IMPLEMENT 反向修订** —— 写 `spec.revision` 事件

详见 [`docs/guides/working-with-fuzzy-intent.md`](../../../../docs/guides/working-with-fuzzy-intent.md)。
