# TaskDAG: [变更/页面名称]

> **模板版本**: v1.1 (pl-pipeline)
> **用途**: 将 spec + api-contract 转化为可执行的任务 DAG
> **输入**: `pl/changes/<id>/spec.md` + `api.md` + `ARCHITECTURE_SNAPSHOT.md`
> **消费者**: Coder Agent（按顺序实现）、Module Expert（辅助 Module 迁移）
> **生成者**: Planner Agent (PLAN 阶段)

---

## 元信息

| 字段 | 值 |
|------|-----|
| Change ID | `change-id` |
| 页面 ID | `page_id`（如有） |
| 总任务数 | N |
| 可并行任务组数 | N |
| 预估总工时 (串行) | Xh |
| 预估总工时 (最大并行) | Xh |
| 组件复用率 | X/Y = Z% |
| 阻塞项 | N 个 |

---

## 依赖关系图 (DAG)

> 节点格式: `T{N}: 任务名 [复用/新建标注]`

```
T1: 页面骨架 ──────────────────────┐
T2: 数据模型 ──→ T3: 数据模块 ──────┤
                                    ├──→ T5: 组件A [复用 DJCList]
                                    ├──→ T6: 组件B [新建]
                                    ├──→ T7: 组件C [复用 DJCButton]
                                    └──→ T8: 组件D [新建, ⚠️阻塞]
T4: 埋点方案 (可独立)
```

### 并行度分析

| 阶段 | 可并行任务 | 门禁 |
|------|-----------|------|
| 阶段1 | T1 ‖ T2 ‖ T4 | 无前置依赖 |
| 阶段2 | T3 | 依赖 T2 |
| 阶段3 | T5 ‖ T6 ‖ T7 ‖ T8 | 依赖 T1 + T3 |
| 阶段4 | 集成测试 | 所有任务完成 |

---

## 任务清单

### T1: 页面骨架 `[无依赖]` `[预估: 0.5h]`

**目标**: 创建页面入口文件和基础生命周期

**产出文件**:
- `page/{page_id}/{PageName}.kt` — BasePager 子类

**实现要点**:
1. 继承 `BasePager`
2. 添加 `@Page("{page_id}")` 注解
3. 解析页面参数: `param1`, `param2`, ...
4. 在 `created()` 中调用数据加载
5. 基础布局: Loading / 内容 / 错误状态

**复用组件**:
| 组件 | 来源 | 用途 |
|------|------|------|
| NavBar | `component.common.NavBar` | 导航栏 |
| DJCLoading | `component.common.DJCLoading` | 加载状态 |

**门禁**:
- [ ] 页面可编译
- [ ] 路由注册正确 (Config.kt)
- [ ] 参数解析正确

---

### T2: 数据模型 `[无依赖]` `[预估: 1h]`

**目标**: 基于 API Contract 定义 Kotlin 数据模型

**产出文件**:
- `page/{page_id}/data/{PageName}Models.kt` — @Serializable 数据类

**实现要点**:
1. 为每个接口响应创建 `@Serializable data class`
2. 字段类型参照 API Contract 的映射注意事项
3. 高风险字段使用 `@Contextual` 注解
4. 所有字段提供默认值
5. 嵌套结构独立定义

**门禁**:
- [ ] 所有 data class 可编译
- [ ] 所有字段有默认值
- [ ] 高风险字段标注 @Contextual

---

### T3: 数据模块 `[依赖: T2]` `[预估: 2h]`

**目标**: 实现数据加载逻辑

**产出文件**:
- `page/{page_id}/data/{PageName}Module.kt`
- `page/{page_id}/data/{PageName}DataStore.kt`

**实现要点**:
1. 为每个接口创建 `suspend fun fetchXxx()` 方法
2. 使用 `Http.smartFetch` 或 `ApiService.request`
3. 请求结果更新到 DataStore 的 `observable` 属性
4. 错误处理: 网络失败 → Toast + 错误状态
5. 自检: `ApiSelfCheck.Mode.LIVE_WITH_FALLBACK` (如已接入)

**门禁**:
- [ ] 所有 suspend 函数可编译
- [ ] DataStore 的 observable 属性类型正确
- [ ] 错误处理覆盖: 网络异常、业务异常、解析异常

---

### T4: 埋点方案 `[无依赖]` `[预估: 0.5h]`

**目标**: 定义页面埋点，对齐旧版参考实现（若为迁移类 change）

**埋点映射** (对齐旧版):
| 事件 | 旧版 eventId | 新版实现位置 | 对应 F# |
|------|-------------|------------|---------|
| 页面曝光 | xxx | appear() | - |
| 按钮点击 | yyy | onClick | F4 |

---

### T5: [组件名称] `[依赖: T1, T3]` `[预估: Xh]`

**目标**: [组件功能描述]

**产出文件**:
- `page/{page_id}/component/{ComponentName}.kt`

**复用/新建**:
| 组件 | 来源 | 用法 |
|------|------|------|
| DJCList | `component.common.DJCList` | 用于渲染列表 |

**门禁**:
- [ ] 组件可编译
- [ ] 数据绑定正确
- [ ] 交互功能正常

---

> (后续任务重复 T5 结构...)

---

## 集成验收 (Integration Gate)

### 编译验收
- [ ] 编译通过: `$PL_BUILD_CHECK_CMD`（由 adapter 注入，如 `npm run build` / `./gradlew ...` / `uv run pytest`）
- [ ] 无编译警告（或警告已确认为安全）

### 功能验收
- [ ] P0 功能全部实现 (F1 ~ Fn)
- [ ] 所有状态机路径验证
- [ ] 页面跳转入口可正常进入

### 自检验收 (如已接入)
- [ ] 网络层: Mock 降级正常
- [ ] 解析层: 宽松解析降级正常
- [ ] UI 层: 空状态/错误状态展示正确

### 静态检查
- [ ] adapter 提供的 lint 脚本通过（如 `./scripts/lint.sh` 或 `npm run lint`）
- [ ] adapter 提供的迁移检查脚本通过（若为迁移类 change）

---

## 风险与缓解

| 风险 | 影响 | 缓解措施 |
|------|------|---------|
| 接口字段不一致 | 解析失败 | @Contextual + 宽松解析 + Mock 降级 |
| 组件复用不匹配 | 多出工时 | Planner 提前检查 ARCHITECTURE_SNAPSHOT |
| 阻塞问题未解决 | 任务暂缓 | 人机确认协议，2 工作日超时策略 |

---

## 变更记录

| 日期 | 变更 | 原因 |
|------|------|------|
| YYYY-MM-DD | 初始版本 | PLAN 任务拆解完成 |
