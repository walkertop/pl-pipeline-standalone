# Asset Sanitization Guide

> **适用**：把一个项目里的 skill / rule / agent 迁到 `pl-pipeline-standalone` 作为通用资产时。
> **受众**：做资产迁移的人（现在是我 / AI）+ 未来审稿人（PR review）。

**口号**：一个 skill 如果只能帮 A 项目，它就不是 pl 资产；一个 skill 如果能帮任何项目，它才值得进 `assets/pl/`。

---

## 脱敏的两类目标

| 类别 | 说明 | 例子 |
|------|------|------|
| **硬脱敏** | 必须全部去掉，一个都不能留 | 公司内部代号、内网域名、具体员工 ID、内部系统 |
| **软脱敏** | 抽象化 / 参数化，保留示例结构 | 具体技术栈名、具体路径、具体业务术语 |

---

## 硬脱敏规则（MUST）

扫描整个 skill/rule/agent 内容（包括 examples/ 子目录），以下内容**必须**完全清除：

### 1. 特定项目名
- ❌ `KuiklyPolyCity` / `道聚城` / `djc` / `polycity`
- ❌ 任何内部项目代号（比如 `piao-v0.1`、`retro-v2` 这类仓内代号可留，但 `proj-abc123` 这类业务代号去掉）
- ✅ 用 `<your-project>` / `<app>` 占位

### 2. 内部基础设施
- ❌ `TAPD` / `工蜂` / 内部 CI 名称（除非是 adapter 级资产）
- ❌ `*.oa.com` / `git.code.tencent.com` / 内部 domain
- ✅ 用 `<your-issue-tracker>` / `<your-git-host>` 占位

### 3. 具体员工 / 团队
- ❌ `@zhangsan` / `负责人 guobin` / 团队具体称呼
- ✅ 用 `<owner>` / `<team>` / "负责人"

### 4. 真实路径
- ❌ `shared/src/commonMain/kotlin/com/tencent/kuiklypolycity/...`
- ❌ `/Users/guobin/Developer/...`
- ✅ 用 `<module>/src/<path>/...` / `<your-src-root>/...`

---

## 软脱敏规则（SHOULD）

### 1. 不钦定技术栈（最常见的耦合）

| ❌ 原文 | ✅ 改写 |
|--------|--------|
| "用 Kotlin Flow 做响应式" | "用你技术栈对应的响应式原语（Kotlin Flow / RxJava / JS Observable / ...）" |
| "Weex 组件迁移到 Kuikly" | "legacy 组件迁移到目标框架" + 脚注 "例如 Weex→Kuikly, Vue 2→Vue 3 等" |
| "MVVM + Card 架构" | "分层架构（UI 层 + ViewModel 层 + 数据层）" |

**例外**：如果这个 skill 本来就是 **adapter 级**，钦定栈是正确的，**那它不该住 `assets/pl/`**，应该住 `adapters/adapter-<stack>/skills/`。

### 2. 示例不能只给一种

一条规则只有一个 Kotlin 示例 → 不够；至少给：
- 一个后端示例（Python / Java / Go / ...）
- 一个前端示例（React / Vue / Kotlin Compose / ...）
- 或者一个 CLI 示例

### 3. 业务词汇抽象

| ❌ 具体业务 | ✅ 抽象 |
|----------|--------|
| "道具详情页" | "detail page for entity listing" |
| "订单确认流程" | "multi-step confirmation flow" |
| "扫 ISBN 录入图书" | "扫码/手录入数据的 capture UI" |

### 4. 保留结构化 examples 子目录

脱敏**不是删例子**。保留 `examples/` 子目录，放 1~2 个**脱掉业务特征但保留结构的场景**：
```
spec-normalizer/
├── SKILL.md                           ← 纯通用，抽象
└── examples/
    ├── ecommerce-order-spec.md        ← 电商订单（脱敏后的典型例子）
    └── blog-system-spec.md            ← 博客系统（换一个域领域）
```

---

## Frontmatter 强制要求

脱敏后的资产必须在顶部有：

```yaml
---
id: <same-as-dir-name>                  # 必需
version: 1.0.0                          # 从 1.0.0 开始（新资产），原项目版本号重置
scope: generic                          # generic | stack-specific | project-specific
category: <spec|plan|impl|verify|archive|meta>
migrated_from: KuiklyPolyCity@<commit>  # 记录来源，便于追溯
sanitization_date: 2026-04-23
---
```

---

## 迁移工作流（标准操作步骤）

### Step 1 — 扫描耦合点
```bash
grep -n -E "kuikly|Kuikly|weex|Weex|KuiklyPolyCity|polycity|道聚城|djc|tencent\.com|oa\.com" \
  <source-file> | head -30
```

把结果输出到 `docs/retros/asset-migration/<asset-id>-coupling-scan-before.txt`，作为**前置证据**。

### Step 2 — 写 Before/After 对比文档
在 `docs/retros/asset-migration/<asset-id>-migration.md` 里：
- 原版路径 + 大小
- 脱敏动作清单（哪句话改成了什么）
- 脱敏后残留的"合理业务引用"（如果必要），并说明为什么合理

### Step 3 — 改写
创建 `assets/pl/{skills,rules,agents}/<asset-id>/` 目录，写脱敏版内容。

### Step 4 — 验证
```bash
# 脱敏后再扫一次
grep -n -E "kuikly|Kuikly|weex|Weex|KuiklyPolyCity|polycity|道聚城|djc" \
  assets/pl/skills/<asset-id>/SKILL.md assets/pl/skills/<asset-id>/examples/*.md 2>/dev/null

# 预期：0 命中
```

把结果输出到 `docs/retros/asset-migration/<asset-id>-coupling-scan-after.txt` 作为**后置证据**。

### Step 5 — 项目侧改为 override
在原项目（比如 KuiklyPolyCity）里，原资产改写为 **引用 + 扩展**：

```yaml
---
id: spec-normalizer
version: 1.0.0
scope: project-specific
extends: spec-normalizer@1.0.0        # 从 assets/pl/ 继承
kuikly_examples: examples-kuikly/*.md  # 本项目加的特化示例
---
# spec-normalizer (KuiklyPolyCity override)

本 override 继承 `pl-pipeline-standalone/assets/pl/skills/spec-normalizer@1.0.0`
的通用能力，附加以下 Kuikly 迁移场景特化：

## Kuikly 场景扩展
（本项目特有的 Weex→Kuikly 迁移注意事项）
```

---

## Review Checklist（PR 合入前）

迁移 PR 必须附带以下检查清单，全部勾选才能合：

- [ ] `coupling-scan-before.txt` 已生成且提交
- [ ] `coupling-scan-after.txt` 已生成，**0 硬脱敏命中**
- [ ] Frontmatter 齐全（id / version / scope / category / migrated_from）
- [ ] 至少 2 个不同域的示例（examples/*.md）
- [ ] 原项目的 override 版已就位，且本地测试一次 AI 能正常触发
- [ ] `docs/retros/asset-migration/<asset-id>-migration.md` 的 Before/After 对比已写

---

## 常见错误

### 错误 1：把"脱敏"做成了"删内容"
去掉所有示例留下一堆抽象词 → skill 变空洞，新用户看了不知道怎么用。
**正确做法**：**换**示例，不是**删**示例。

### 错误 2：一脱敏就丢失原有智慧
原版里有"2026-04 kuikly 迁移踩的坑：XXX 会导致 YYY" → 脱敏去掉了踩坑历史。
**正确做法**：把踩坑沉淀为**通用规则**（"legacy→modern 迁移时，YYY 类问题常见于状态管理错位"）+ 在项目 override 里保留具体 Kuikly 版本。

### 错误 3：scope 写错
把只有 Kotlin 项目能用的东西写 `scope: generic` → 污染独立仓。
**正确做法**：如果跨栈用不了，就放 `adapters/adapter-kotlin/`，并标 `scope: stack-specific`。

---

## 相关文档

- [`working-with-fuzzy-intent.md`](./working-with-fuzzy-intent.md) — 辩证方法论（为什么要脱敏、脱敏边界在哪）
- [`../milestones/v1.5-migrate-core-assets.md`](../milestones/v1.5-migrate-core-assets.md) — v1.5 整体计划
- [`../../assets/pl/skills/README.md`](../../assets/pl/skills/README.md) — skills 目录说明
