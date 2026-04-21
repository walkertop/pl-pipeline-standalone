# API Contract: [变更/页面名称]

> **模板版本**: v1.1 (pl-pipeline)
> **用途**: 在 PLAN 阶段锁定 API Schema，作为 Mock 数据和自检的基础
> **来源**: ifBook + ReqConfig.kt
> **消费者**: Coder Agent（数据层开发）、Guardian Agent（Mock 验证）
> **门禁**: 所有 P0 接口必须有完整 Schema 后方可进入 IMPLEMENT 阶段

---

## 总览

| 指标 | 值 |
|------|-----|
| Change ID | `change-id` |
| 页面 ID | `page_id`（如有） |
| 接口总数 | N |
| P0 接口数 | N |
| Schema 已锁定 | N / N |
| Mock 已注册 | N / N |

---

## 接口 1: [接口描述]

### 基本信息

| 字段 | 值 |
|------|-----|
| urlKey | `ReqConfig.URL_KEY_NAME` |
| ifBook UID | `xxx-xxx-xxx` (如已注册) |
| 方法 | POST / GET |
| 优先级 | P0 / P1 / P2 |
| 依赖功能 | F1, F2 (对应 spec 功能清单) |

### 请求参数

| 参数 | 类型 | 必选 | 说明 | 示例值 |
|------|------|------|------|--------|
| param1 | String | ✅ | 描述 | "example" |
| param2 | Int | ❌ | 描述 | 1 |

> **公共参数** (由 Http.smartFetch 自动注入): `iAppId`, `_token`, `sOpenId`, `iAreaId`, `sPlatId`, `iGoodsId` 等

### 响应结构

```json
{
  "ret": 0,
  "msg": "success",
  "data": {
    "field1": "string 类型说明",
    "field2": 123,
    "field3": {
      "nestedField1": "说明",
      "nestedField2": []
    }
  }
}
```

### Kotlin 数据模型映射

```kotlin
@Serializable
data class XxxData(
    @SerialName("field1") val field1: String = "",
    @SerialName("field2") @Contextual val field2: Int = 0,
    @SerialName("field3") val field3: NestedData? = null
)

@Serializable
data class NestedData(
    @SerialName("nestedField1") val nestedField1: String = "",
    @SerialName("nestedField2") val nestedField2: List<String> = emptyList()
)
```

### 字段映射注意事项

| JSON 字段 | Kotlin 类型 | 风险等级 | 注意事项 |
|-----------|------------|---------|---------|
| field2 | Int (@Contextual) | ⚠️ 中 | 后端可能返回 String，需宽松解析 |
| field3 | NestedData? | ⚠️ 中 | 可能为 null，需默认值 |

> **风险等级**:
> - 🟢 低: 类型明确，无歧义
> - ⚠️ 中: 存在类型不一致或 null 可能，已有降级方案
> - 🔴 高: 字段含义不明或 Schema 未确认，需 BLOCKING 处理

### Mock 数据用例

#### Case 1: 正常场景 (`normal`)

```json
{
  "ret": 0,
  "msg": "success",
  "data": {
    "field1": "正常值",
    "field2": 100,
    "field3": { "nestedField1": "正常", "nestedField2": ["item1", "item2"] }
  }
}
```

#### Case 2: 空数据场景 (`empty`)

```json
{ "ret": 0, "msg": "success", "data": {} }
```

#### Case 3: 错误场景 (`error`)

```json
{ "ret": -1, "msg": "请求失败", "data": null }
```

### Mock 注册状态

| Case | ifBook 状态 | ApiSelfCheck 注册 |
|------|------------|-----------------|
| normal | ✅ 已注册 | ✅ 已注册 |
| empty | ✅ 已注册 | ✅ 已注册 |
| error | ✅ 已注册 | ✅ 已注册 |

---

## 接口 2: [接口描述]

> (重复上述结构...)

---

## 接口依赖关系

```
接口1 (主数据)
  ├─→ 接口2 (依赖接口1返回的 id 参数)
  └─→ 接口3 (可与接口1并行)
```

| 接口 | 依赖 | 调用时机 | 是否可并行 |
|------|------|---------|-----------|
| 接口1 | 无 | 页面加载时 | - |
| 接口2 | 接口1 | 接口1 成功后 | ❌ |
| 接口3 | 无 | 页面加载时 | ✅ (与接口1并行) |

---

## 未确认事项

| ID | 接口 | 问题 | 阻塞等级 | 状态 |
|----|------|------|---------|------|
| A1 | 接口2 | 字段 xxx 含义不明 | BLOCKING | 待后端确认 |
| A2 | 接口3 | 是否需要分页 | NON_BLOCKING | 假设不分页 |

---

## Checklist

- [ ] 所有 P0 接口有完整 Schema (请求 + 响应)
- [ ] 所有 P0 接口有 ≥2 个 Mock Case (normal + error)
- [ ] 所有字段映射注意事项已标注
- [ ] 所有 BLOCKING 问题已解决
- [ ] Kotlin 数据模型已定义（至少接口级别）
- [ ] 接口依赖关系已明确
