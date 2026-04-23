---
id: kotlinx-serialization
version: 1.0.0
scope: stack-specific
stack: kotlin
category: coding
severity: warning
description: kotlinx.serialization 使用规范（@Serializable / 默认值 / @Contextual / 嵌套对象 / JSON 解析）。
migrated_from: KuiklyPolyCity@feature/caleb/agentic
sanitization_date: 2026-04-23
---

# kotlinx.serialization · 使用规范

> **Rule-ID**: `SER-001`
> **适用范围**: 所有数据模型类（DTO / 持久化 / 跨进程通信）
> **优先级**: P1

---

## 变更日志

| 版本 | 日期 | 变更 |
|------|------|------|
| v1.0.0 | 2026-04-23 | 从源项目脱敏迁入独立仓，去除项目专属字段命名惯例 |

---

## 设计原则

- **向前兼容第一**：API 字段变化是常态，序列化代码必须能优雅处理缺失 / 未知字段
- **跨平台一致**：KMM 项目需考虑 JVM/Native/JS 类型差异
- **显式 > 隐式**：不要依赖默认行为，重要约束都用注解或默认值表达

---

## 1. 基本规范

### Rule `SER-001-BASE`: 所有数据模型必须使用 `@Serializable`

**Rationale**: `@Serializable` 由编译器生成序列化代码，比反射更快、更安全、跨平台兼容。

```kotlin
// ✅ 正确
@Serializable
data class ItemData(
    val id: Int = 0,
    val name: String = ""
)

// ❌ 错误：缺少 @Serializable
data class ItemData(
    val id: Int,
    val name: String
)
```

---

## 2. 默认值要求

### Rule `SER-001-DEFAULT`: 所有字段必须提供默认值

**Rationale**: API 返回的 JSON 可能缺少字段或增加字段。默认值保证**向前兼容**，避免反序列化崩溃。

```kotlin
// ✅ 正确
@Serializable
data class OrderData(
    val type: Int = 0,
    val name: String = "",
    val price: Double = 0.0,
    val isValid: Boolean = false,
    val items: List<SubItem> = emptyList()
)

// ❌ 错误：缺少默认值
@Serializable
data class OrderData(
    val type: Int,         // JSON 缺字段会崩溃
    val name: String       // JSON 缺字段会崩溃
)
```

**验收关联**: 编译期 KSP 可检测部分违规，Code Review 检查剩余（`ACC-001` P1）。

---

## 3. 平台类型处理

### Rule `SER-001-CTX`: 跨平台敏感类型使用 `@Contextual`

**Rationale**: KMM 跨平台环境中，某些类型在 JVM/Native/JS 的序列化行为不同（例如 Int 在 JS 中可能被转为 Double）。`@Contextual` 允许平台特定的序列化器介入。

```kotlin
@Serializable
data class PriceInfo(
    @Contextual val price: Int = 0,       // 跨平台数值字段
    @Contextual val discount: Int = 0,    // 跨平台数值字段
    val unit: String = ""                 // String 不需要 @Contextual
)
```

> 如果不是 KMM 项目（纯 JVM / 纯 Android），此规则可放宽为建议。

---

## 4. 嵌套对象

### Rule `SER-001-NEST`: 嵌套数据类也必须标注 `@Serializable`

**Rationale**: 序列化是递归的，缺少任一层注解会导致编译错误或运行时异常。

```kotlin
// ✅ 嵌套的数据类也需要 @Serializable
@Serializable
data class ApiResponse(
    val code: Int = 0,
    val message: String = "",
    val data: DetailData? = null  // 可空 + 默认 null
)

@Serializable
data class DetailData(
    val id: Int = 0,
    val items: List<SubItem> = emptyList()
)

@Serializable
data class SubItem(
    val title: String = "",
    val count: Int = 0
)
```

---

## 5. JSON 解析

### Rule `SER-001-JSON`: 统一使用 kotlinx.serialization 解析

**Rationale**: 统一解析库避免多种 JSON 库混用导致的行为不一致（例如 Gson 的 null 处理 vs kotlinx 的 null 处理）和维护成本增加。

```kotlin
// ✅ 使用 kotlinx.serialization
import kotlinx.serialization.json.Json
import kotlinx.serialization.decodeFromString

// 推荐的宽松解析配置
val json = Json {
    ignoreUnknownKeys = true          // 忽略 JSON 多出来的字段（向前兼容）
    coerceInputValues = true          // 将 null 转换为默认值（健壮性）
    isLenient = true                  // 允许非严格 JSON（如数字以字符串形式提供）
}

val data = json.decodeFromString<DetailData>(jsonString)

// ❌ 不要使用 Gson 或 org.json 做数据模型解析
```

**验收关联**: `search_content` 扫描 `import com.google.gson` / `import org.json` 引用（`ACC-001` P0）。

---

## 6. 命名与字段映射

### Rule `SER-001-NAMING`: API 字段名与 Kotlin 属性名一致时不用 `@SerialName`

**Rationale**: 冗余注解增加维护成本。仅在 Kotlin 惯例命名（camelCase）与 API 字段命名（snake_case / PascalCase / 匈牙利等）不一致时才需要映射。

```kotlin
// ✅ API 使用 camelCase：不需要 @SerialName
@Serializable
data class User(
    val id: Int = 0,
    val userName: String = "",
    val createdAt: Long = 0
)

// ✅ API 使用 snake_case：用 @SerialName 映射
@Serializable
data class User(
    val id: Int = 0,
    @SerialName("user_name") val userName: String = "",
    @SerialName("created_at") val createdAt: Long = 0
)

// ✅ API 使用匈牙利命名法（前缀标类型）：保持与 API 一致或用 @SerialName 映射
@Serializable
data class ApiData(
    val iId: Int = 0,                     // 保持与 API 一致
    val sName: String = "",
    // 或
    @SerialName("iId") val id: Int = 0,   // 映射为 Kotlin 惯例
    @SerialName("sName") val name: String = ""
)
```

**选择标准**：
- 团队/项目内统一一种风格
- 如果 Kotlin 层有业务逻辑依赖属性名语义，优先 Kotlin 惯例 + `@SerialName` 映射
- 如果模型仅作为 DTO 透传，保持与 API 一致可省注解

---

## 7. 违规检测速查

| Rule-ID | 违规类型 | 检测方法 |
|---------|---------|---------|
| `SER-001-BASE` | data class 缺少 `@Serializable` | detekt 自定义规则扫描 |
| `SER-001-DEFAULT` | 字段缺少默认值 | 正则 + Code Review |
| `SER-001-JSON` | 使用 Gson/org.json | `search_content` 扫描 import 语句 |
| `SER-001-CTX` | KMM 中跨平台类型缺 `@Contextual` | 编译测试 + Code Review |
| `SER-001-NEST` | 嵌套类缺 `@Serializable` | 编译器错误（IDE 提示） |

---

## Footnote · 脱敏说明

本 rule 从源项目迁入时的变化：
- 示例业务名称通用化（`OrderData` / `DetailData` / `ApiResponse` 保留为通用 DTO 示例）
- 命名约定章节去除"特定 API 必须匈牙利命名法"的强约束，改为"选择标准"引导
- 宽松解析配置增加 `isLenient = true`（原文未包含），作为可选推荐
