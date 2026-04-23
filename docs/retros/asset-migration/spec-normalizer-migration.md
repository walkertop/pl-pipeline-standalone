# Migration · spec-normalizer skill

**资产**: `spec-normalizer` skill
**源**: `KuiklyPolyCity/.codebuddy/skills/spec-normalizer@feature/caleb/agentic`
**目标**: `pl-pipeline-standalone/assets/pl/skills/spec-normalizer/` @ v1.0.0
**迁移时间**: 2026-04-23
**执行 milestone**: v1.5 D2（样本迁移）

---

## 摘要

| 指标 | Before | After |
|------|--------|-------|
| 硬耦合点数（kuikly/weex/DJC*/openspec 路径等）| **19** | **1**（合法：frontmatter `migrated_from` 字段）|
| 示例数量 | 2（都是 Kuikly 业务：order-detail / prop-detail） | 2（两个不同领域：电商 + 博客）|
| 文件结构 | `SKILL.md` + `examples/{order,prop}-detail-spec.md` | `SKILL.md` + `examples/{ecommerce-order,blog-system}-spec.md` |
| 提及的其他 skill | `weex-migration-analyzer` / `kuikly-ui-framework` / `kuikly-third-party` | 抽象为"栈级 migration-analyzer skill（若存在）"等 |

---

## 脱敏动作清单

### 1. Frontmatter 规范化
| Before | After |
|--------|-------|
| `name: spec-normalizer` | `id: spec-normalizer` |
| `description: ...` | 保留但去掉 "Planner Agent (B1 节点)" 等项目黑话 |
| — | 新增 `version: 1.0.0 / scope: generic / category: spec / migrated_from / sanitization_date` |

### 2. 硬脱敏（项目/业务特定词）

| Before（原文）| After（改写）|
|---|---|
| "旧版 Weex 代码" → 多处 | "legacy 代码" / "legacy 迁移场景" |
| `Weex/src/xxx.vue` | `<legacy-src>/<entry>` |
| `shared/src/commonMain/kotlin/com/tencent/kuiklypolycity/utils/http/ReqConfig.kt` | "项目接口常量 / 路由文件（项目常见位置：`<src>/api/`、`<src>/config/routes.*`）" |
| `openspec/templates/structured-spec.md` | `pl/templates/spec.md` |
| `openspec/changes/<change-id>/structured-spec.md` | `pl/changes/<change-id>/spec.md` |
| 组件表里 `DJCList<T>` / `DJCButton` / `DJCLoading` / `DJCActionSheet` | 删除整张"DJC 业务组件"表，改为抽象段："语义匹配的关键词表由栈级 adapter 提供" |
| Layer 2/3 组件注册表里的 `NavBar / SimpleBanner / GameSelector` 等具体组件 | 抽象为通用语义词（navbar / list / modal）+ 明确标注"不钦定组件目录" |

### 3. 软脱敏（skill 引用）

| Before | After |
|---|---|
| "调 `weex-migration-analyzer` Skill" | "调栈级 `migration-analyzer` skill（若存在）" |
| "`kuikly-ui-framework` Skill" | "栈级 `component-library` skill（若存在）" |
| "`kuikly-third-party` Skill" | 合并到 component-library 的说明里 |
| "ifBook MCP" | "接口目录 MCP / 工具（若项目接入）" |

### 4. 结构增强（借此机会改良）

- 新增"辩证使用提示"小节，链向 `working-with-fuzzy-intent.md`
- Step 5（不确定性分级）加一段注释："不要一次性穷举 L4，随对话降级"
- Step 3 章节表把 UI 结构、埋点、状态机标为"可选章节"（以前硬要求），因为 CLI / 后端场景用不上
- 产物路径说明从 `openspec/changes/<id>/...` 改为 `pl/changes/<id>/...`

### 5. Example 全换

**删掉**：
- `examples/order-detail-spec.md` — 满是 DJC* 组件、Kuikly 类型、`Weex/src/order_detail.vue` 引用
- `examples/prop-detail-spec.md` — 同上，含"道具详情"等业务词

**新建**：
- `examples/ecommerce-order-spec.md` — 电商订单详情（保留 9 章节结构，换成通用业务）
- `examples/blog-system-spec.md` — 博客文章编辑器（刻意选完全不同领域，证明通用性）

---

## 保留的"合理业务引用"

唯一一处命中：

```yaml
migrated_from: KuiklyPolyCity@feature/caleb/agentic
```

**保留理由**：脱敏指南 Step 1 明确要求"记录来源，便于追溯"。这属于**元数据**而非内容耦合，审查员读 frontmatter 时能立刻知道这份资产的血缘。

---

## KuiklyPolyCity 侧的 override 计划（D4 阶段）

原 `KuiklyPolyCity/.codebuddy/skills/spec-normalizer/SKILL.md` 将被改写为：

```yaml
---
id: spec-normalizer
version: 1.0.0
scope: project-specific
extends: pl-pipeline@assets/pl/skills/spec-normalizer@1.0.0
project: KuiklyPolyCity
---
# spec-normalizer (KuiklyPolyCity override)

本 override 继承通用版的 9 章节流程 + L1~L4 分级，追加以下 Kuikly 迁移特化：

## Kuikly 场景扩展

### 专用上下文
- `Weex/src/xxx.vue` → 标准 legacy 入口
- `shared/src/commonMain/kotlin/com/tencent/kuiklypolycity/utils/http/ReqConfig.kt` → 接口常量
- DJC* 业务组件注册表（见下）

### DJC 业务组件语义词表
| 组件 | 语义 |
| DJCList<T> | 列表 / 数据列表 |
| DJCButton | 业务按钮 |
| ...（原版内容保留） ...

### 专用 skill 联动
- A0 输入阶段调 weex-migration-analyzer skill
- A1 对齐阶段调 kuikly-ui-framework / kuikly-third-party

### 专用示例
examples/
  order-detail-spec.md  ← 原版迁入，保留
  prop-detail-spec.md   ← 原版迁入，保留
```

这样做到：
- 通用能力住独立仓，所有用户受益
- Kuikly 特化住宿主仓，不污染独立仓
- 新通用能力更新时，Kuikly override 只需要追加特化，不用重写

---

## 验证

### Before 扫描报告
见 [`spec-normalizer-coupling-scan-before.txt`](./spec-normalizer-coupling-scan-before.txt)

- SKILL.md: 11 匹配
- order-detail-spec.md: 4 匹配
- prop-detail-spec.md: 4 匹配
- **总计 19 匹配**

### After 扫描报告
见 [`spec-normalizer-coupling-scan-after.txt`](./spec-normalizer-coupling-scan-after.txt)

- SKILL.md: 1 匹配（合法：frontmatter `migrated_from`）
- ecommerce-order-spec.md: 0
- blog-system-spec.md: 0
- **有效耦合 0 项** ✅

### Checklist

- [x] coupling-scan-before.txt 已生成
- [x] coupling-scan-after.txt 已生成，0 实质耦合
- [x] Frontmatter 齐全（id / version / scope / category / migrated_from）
- [x] 2 个不同域的示例（电商 + 博客）
- [ ] 原项目 override 就位（**待 D4 阶段**，本 PR 范围外）
- [x] Before/After 对比文档（本文件）已写

---

## 后续（v1.5 D3+）

本样本完成后，剩余 6 个必做资产：
- finalization-template skill
- piao-pipeline-discipline rule
- acceptance-criteria rule
- build-verification rule
- pipeline-master agent
- knowledge-archiver agent

按同样流程批量迁移。
