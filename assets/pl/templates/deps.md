# Dependency Analysis: [Change 名称]

> **模板版本**: v1.0
> **用途**: 在 SPEC 阶段分析旧代码/上游依赖，标记断链点、替代方案
> **输入**: 旧代码（Weex/老 Kotlin）+ 现有基础设施（Layer1/Layer2）
> **消费者**: `migration-analyzer`（拆 TaskDAG）、`migration-coder`（执行时对齐）
> **位置**: `pl/changes/<change-id>/deps.md`

---

## 1. 依赖全景

| 维度 | 数量 |
|------|------|
| 旧代码文件 | N |
| 依赖的 Layer1 模块 | N |
| 依赖的 Layer2 组件 | N |
| 新增依赖 | N |
| 断链点（不可迁移） | N |

---

## 2. 旧代码清单（迁移类 change）

| 旧文件 | 类型 | 新文件 | 状态 |
|--------|------|--------|------|
| `Weex/src/xxx.vue` | Page | `page/<page_id>/<PageName>.kt` | 🟢 待迁移 |
| `Weex/src/components/Yyy.vue` | Component | `page/<page_id>/component/Yyy.kt` | 🟢 待迁移 |
| `Weex/src/utils/zzz.js` | Util | 复用 `Layer2/CommonUtils.kt` | 🟡 替代 |

> **状态定义**:
> - 🟢 待迁移：有 1:1 对应关系
> - 🟡 替代：用现有能力替代
> - 🔴 断链：无法直接迁移，需决策

---

## 3. 基础设施依赖

### 3.1 Layer1（框架层）

| 依赖项 | 用途 | 状态 |
|--------|------|------|
| BasePager | 页面基类 | ✅ 直接用 |
| Http.smartFetch | 网络请求 | ✅ 直接用 |
| EventModule | 埋点上报 | ✅ 直接用 |

### 3.2 Layer2（通用组件层）

| 组件 | 用途 | 文件 | 状态 |
|------|------|------|------|
| NavBar | 导航栏 | `component/common/NavBar.kt` | ✅ 复用 |
| DJCButton | 按钮 | `component/common/DJCButton.kt` | ✅ 复用 |
| DJCList | 列表 | `component/common/DJCList.kt` | ✅ 复用 |
| DJCLoading | 加载态 | `component/common/DJCLoading.kt` | ✅ 复用 |

### 3.3 Layer3（业务域通用层）

| 组件 | 用途 | 文件 | 状态 |
|------|------|------|------|
| PropCard | 道具卡片 | `component/biz/prop/PropCard.kt` | ✅ 复用 |

### 3.4 Layer4（页面私有层）

> 本 change 需要新建的组件：

| 组件 | 用途 | 产出文件 |
|------|------|---------|
| CustomXxxBanner | 页面专属 banner | `page/<page_id>/component/CustomXxxBanner.kt` |

---

## 4. 接口依赖

> 详见 `api.md`，此处只列 urlKey 清单。

| urlKey | 是否已注册 ReqConfig | 是否有 ifBook Schema | 状态 |
|--------|---------------------|---------------------|------|
| `URL_KEY_1` | ✅ | ✅ | 🟢 可用 |
| `URL_KEY_2` | ❌ | ❌ | 🔴 断链 |

---

## 5. 断链点（BLOCKING 清单）

> 无法直接迁移的依赖，必须在 SPEC 阶段提出决策。

| 断链点 | 类型 | 阻塞原因 | 替代方案 | 状态 |
|--------|------|---------|---------|------|
| `oldJsBridge.xxx` | JS Bridge | Kuikly 无此 bridge | 新增 Module 封装 | 🔴 待决策 |
| `Weex 内置动画` | 能力缺失 | Kuikly 动画 API 不同 | 重写动画逻辑 | 🟡 有方案 |

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
