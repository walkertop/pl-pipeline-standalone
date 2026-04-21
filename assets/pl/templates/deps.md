# Dependency Analysis: [Change 名称]

> **模板版本**: v1.0
> **用途**: 在 SPEC 阶段分析旧代码/上游依赖，标记断链点、替代方案
> **输入**: 旧代码（若为迁移类 change）+ 现有基础设施
> **消费者**: PLAN 阶段 agent（拆 TaskDAG）、IMPLEMENT 阶段 agent（执行时对齐）
> **位置**: `pl/changes/<change-id>/deps.md`

---

## 1. 依赖全景

| 维度 | 数量 |
|------|------|
| 旧代码文件 | N |
| 依赖的框架层模块 | N |
| 依赖的通用组件 | N |
| 新增依赖 | N |
| 断链点（不可迁移） | N |

---

## 2. 旧代码清单（迁移类 change）

> 本节仅迁移/重构类 change 填写；从零开发类 change 可整节删除。
> 旧文件路径格式由项目/adapter 定义，示例见对应 `@pl/adapter-*` 的 case-study。

| 旧文件 | 类型 | 新文件 | 状态 |
|--------|------|--------|------|
| `<legacy-source>/path/Xxx.<ext>` | Page | `<new-path>/XxxPage.<ext>` | 🟢 待迁移 |
| `<legacy-source>/path/Yyy.<ext>` | Component | `<new-path>/YyyComp.<ext>` | 🟢 待迁移 |
| `<legacy-source>/utils/zzz.<ext>` | Util | 复用 `<new-path>/CommonUtils.<ext>` | 🟡 替代 |

> **状态定义**:
> - 🟢 待迁移：有 1:1 对应关系
> - 🟡 替代：用现有能力替代
> - 🔴 断链：无法直接迁移，需决策

---

## 3. 基础设施依赖

> 下面的分层命名（框架/通用/业务域/页面私有）是 pl-pipeline 的推荐约定；
> 各 adapter 可在其 `docs/case-study.md` 中给出本技术栈的具体分层映射。

### 3.1 框架层（Foundation）

| 依赖项 | 用途 | 状态 |
|--------|------|------|
| [BasePageClass] | 页面基类 | ✅ 直接用 |
| [HttpClient] | 网络请求 | ✅ 直接用 |
| [EventReporter] | 埋点上报 | ✅ 直接用 |

### 3.2 通用组件层（Shared UI Components）

| 组件 | 用途 | 文件 | 状态 |
|------|------|------|------|
| [NavBar] | 导航栏 | `<shared-comp-path>/NavBar.<ext>` | ✅ 复用 |
| [Button] | 按钮 | `<shared-comp-path>/Button.<ext>` | ✅ 复用 |
| [List] | 列表 | `<shared-comp-path>/List.<ext>` | ✅ 复用 |
| [Loading] | 加载态 | `<shared-comp-path>/Loading.<ext>` | ✅ 复用 |

### 3.3 业务域通用层（Business-Domain Components）

| 组件 | 用途 | 文件 | 状态 |
|------|------|------|------|
| [BizCard] | 业务卡片 | `<biz-path>/BizCard.<ext>` | ✅ 复用 |

### 3.4 页面私有层（Page-local Components）

> 本 change 需要新建的组件：

| 组件 | 用途 | 产出文件 |
|------|------|---------|
| [CustomBanner] | 页面专属 banner | `<page-path>/component/CustomBanner.<ext>` |

---

## 4. 接口依赖

> 详见 `api.md`，此处只列 key 清单。

| API Key | 是否已注册 | 是否有 Schema | 状态 |
|---------|-----------|--------------|------|
| `API_KEY_1` | ✅ | ✅ | 🟢 可用 |
| `API_KEY_2` | ❌ | ❌ | 🔴 断链 |

---

## 5. 断链点（BLOCKING 清单）

> 无法直接迁移的依赖，必须在 SPEC 阶段提出决策。

| 断链点 | 类型 | 阻塞原因 | 替代方案 | 状态 |
|--------|------|---------|---------|------|
| `<legacy-bridge-api>` | JS Bridge / Native API | 新平台无对应能力 | 新增 Module 封装 | 🔴 待决策 |
| `<legacy-feature>` | 能力缺失 | 新框架 API 不同 | 重写相关逻辑 | 🟡 有方案 |

---

## 6. 迁移难度评分

| 维度 | 评分 (1-5) | 说明 |
|------|-----------|------|
| 功能复杂度 | 3 | 中等 |
| 接口复杂度 | 2 | 接口少且 Schema 清晰 |
| 组件复用率 | 4 | 复用率高 |
| 断链点数量 | 2 | 少量 |
| **综合难度** | **2.75** | **🟡 中等** |

---

## 7. 变更记录

| 日期 | 变更 | 原因 |
|------|------|------|
| YYYY-MM-DD | 初始版本 | SPEC 阶段启动 |
