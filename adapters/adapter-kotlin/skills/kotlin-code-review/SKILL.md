---
id: kotlin-code-review
version: 1.0.0
scope: stack-specific
stack: kotlin
category: review
requires:
  - kotlin-coding-standards@>=1.0.0
description: 基于 Kotlin 官方规范 + 业界最佳实践的代码审查 skill。按 P0/P1/P2 三档输出结构化报告。
migrated_from: KuiklyPolyCity@feature/caleb/agentic
sanitization_date: 2026-04-23
---

# Kotlin Code Review · Skill

> **触发词**：`kotlin 代码审查` / `审查 kotlin 代码` / `kotlin code review` / `review kotlin code`

## 概述

本 skill 提供基于 Kotlin 通用规范（`rules/kotlin-coding-standards.md`）+ 业界最佳实践的代码审查能力。
审查结果按 **P0（严重）/ P1（重要）/ P2（建议）** 三档输出结构化报告，便于团队按优先级修复。

## 适用范围

- **语言**：Kotlin 1.8+
- **平台无关**：JVM / Android / Multiplatform / Native 均适用
- **与项目框架解耦**：UI 框架 / 业务逻辑的特殊审查要求应由项目级 skill 补充

## 审查维度

### 10 个标准维度

| # | 维度 | 关注点 |
|---|------|--------|
| 1 | 变量使用 | val/var 选择、作用域、`lateinit` / `by lazy` 权衡 |
| 2 | 类型安全 | 空安全、平台类型、`!!` 禁用、类型别名 |
| 3 | 类与对象 | 主构造函数、默认参数、密封类、属性 vs 行为 |
| 4 | 数据类 | 不可变性、`copy()` 浅复制风险、解构作用域 |
| 5 | 集合操作 | 不可变集合、函数式链、`Sequence` 的选择时机 |
| 6 | 函数设计 | `require`/`check` 契约、具名参数、`inline`/`reified` |
| 7 | 泛型 | 类型擦除、装箱、型变（in/out） |
| 8 | 协程 | 结构化并发、`GlobalScope` 禁用、`Mutex` vs `synchronized` |
| 9 | 元编程 | 反射成本、KSP > KAPT、类引用唯一性 |
| 10 | 最佳实践 | 条件表达式、字符串模板、安全转换 `as?` 等 |

## 审查工作流

```
1. 读取代码上下文
   ├─ 文件职责与项目位置
   ├─ 业务逻辑与技术架构
   └─ 相关依赖与调用关系
         ↓
2. 按优先级扫描
   ├─ P0：可能导致 crash / 内存泄漏 / 数据不一致
   ├─ P1：违反核心规范 / 影响性能或可维护性
   └─ P2：代码风格 / 可读性改进
         ↓
3. 生成结构化报告
   ├─ 指出具体位置（行号）
   ├─ 说明违反的 Rule-ID
   ├─ 提供正例代码
   └─ 解释 Rationale
```

## 审查示例（10 个维度精选）

### 1. 变量使用

```kotlin
// ❌ 反例
var count = 0                // 不变 → 应该 val
class Manager {
    var result = 0           // 作用域过大，应为局部
}

// ✅ 正例
val count = 0
class Manager {
    fun calculate(): Int {
        val result = 0
        return result
    }
}
```

### 2. 类型安全（严禁 `!!`）

```kotlin
// ❌ 反例
val city = person!!.address!!.city
fun getData(): Any = fetchRaw()

// ✅ 正例
val city = person?.address?.city ?: "Unknown"
fun getData(): List<String> = fetchRaw().toList()
```

### 3. 类与对象

```kotlin
// ❌ 反例：属性有副作用
class User {
    val temperature: Double
        get() = fetchFromAPI()    // 属性应代表状态
}

// ✅ 正例
class User {
    fun fetchTemperature(): Double = fetchFromAPI()
}
```

### 4. 数据类

```kotlin
// ❌ 反例
data class User(
    var name: String,                        // 可变
    val tags: MutableList<String>,           // 可变集合
    val onLogin: () -> Unit                  // 函数类型
)

// ✅ 正例
data class User(
    val name: String,
    val tags: List<String>
)
```

### 5. 集合操作

```kotlin
// ❌ 反例
fun getUsers(): MutableList<User>            // 暴露可变集合
numbers.forEach { if (it > 5) return }       // 在 forEach 中 return 会退出外层

// ✅ 正例
fun getUsers(): List<User>
numbers.firstOrNull { it > 5 }
```

### 6. 函数设计

```kotlin
// ❌ 反例
fun setAge(age: Int) { this.age = age }      // 缺前置条件
resizeImage(1024, 768, 1.5)                  // 参数含义不明

// ✅ 正例
fun setAge(age: Int) {
    require(age > 0) { "Age must be positive" }
    this.age = age
}
resizeImage(width = 1024, height = 768, scaleFactor = 1.5)
```

### 7. 泛型

```kotlin
// ❌ 反例：类型擦除导致编译错误
fun <T> isInstanceOf(value: Any): Boolean = value is T

// ✅ 正例
inline fun <reified T> isInstanceOf(value: Any): Boolean = value is T
```

### 8. 协程

```kotlin
// ❌ 反例
GlobalScope.launch { }                       // 生命周期不受控
synchronized(lock) { delay(100) }            // 协程中使用线程锁

// ✅ 正例
viewModelScope.launch { }
mutex.withLock { /* ... */ }
```

### 9. 元编程

```kotlin
// ❌ 反例
synchronized(Worker::class) { }              // KClass 实例可能不唯一
val kClass = Class.forName(name).kotlin      // 启动时用 Kotlin 反射（慢）

// ✅ 正例
synchronized(this) { }
val jClass = Class.forName(name)             // 热路径用 Java 反射
```

### 10. 最佳实践精选

- 优先不可变数据
- 用默认参数替代重载
- `typealias` 简化复杂类型
- 条件表达式 > 多分支 if
- 高阶函数 > 循环
- 安全转换用 `as?`
- 字符串模板 > 拼接
- 返回 `Flow` 不声明 `suspend`
- 链式集合操作考虑 `asSequence()`

## 输出格式

```markdown
# Kotlin 代码审查报告

**文件**：`<文件路径>`
**审查时间**：<ISO 8601>
**总体评估**：优秀 / 良好 / 需改进

---

## 严重问题 (P0)

### [严重] <简短标题>
- **位置**：第 X 行
- **问题**：<具体描述>
- **违反 Rule**：`KT-001-NULL` / `SER-001-DEFAULT` / ...
- **风险**：<可能后果>
- **建议**：

\`\`\`kotlin
// 改进后的代码
\`\`\`

---

## 重要问题 (P1)
<同格式>

---

## 建议 (P2)
<同格式>

---

## 正面反馈
- ✅ [好的实践] <标题> · 第 X 行 · 原因

---

## 总结
- 优点: <要点列表>
- 改进领域: <要点列表>
- 优先级建议: <综合建议>
```

## 使用示例

### 示例 1：审查单个文件

```
用户：kotlin 代码审查 UserManager.kt

助手：
[读取文件] → [扫描 10 个维度] → [生成结构化报告]
```

### 示例 2：审查特定维度

```
用户：检查这个文件的协程使用是否规范

助手：
[只扫描协程维度 + 关联维度 3（类与对象）和 8（协程）的检查项]
```

### 示例 3：审查代码片段

```
用户：帮我 review 这段代码：
\`\`\`kotlin
fun getData() = GlobalScope.launch {
    val result = api.fetch()!!
    return result
}
\`\`\`

助手：
P0:
- KT-001-COROUTINE: 使用了 GlobalScope（生命周期不受控）
- KT-001-NULL: 使用了 !!（潜在 NPE）
P1:
- KT-001-TYPE: 公共函数返回 Job，但语义上期待 T
- KT-001-FN: lambda 中 return 不合法（return@launch 或用 suspend fun）
```

## 注意事项

1. **上下文优先**：始终结合代码的业务场景和项目架构进行审查
2. **平衡取舍**：某些规范在特定场景下可能需要权衡（性能 vs 可读性）
3. **渐进改进**：对于大型遗留代码，建议分优先级逐步改进
4. **团队共识**：审查建议应与团队实际规范（项目级 rule）保持一致
5. **工具辅助**：配合 detekt / ktlint 等静态分析工具使用效果更佳

## 与 Rules 的关系

本 skill 以下列 rule 为权威依据：

- `adapters/adapter-kotlin/rules/kotlin-coding-standards.md` · Kotlin 通用规范（主要）
- `adapters/adapter-kotlin/rules/kotlinx-serialization.md` · 序列化规范（数据类审查时）
- `assets/pl/rules/acceptance-criteria.md` · 验收标准（P0/P1/P2 分级框架）

## Footnote · 脱敏说明

本 skill 从源项目迁入时的变化：
- 去除"基于腾讯规范"表述，改为"基于 Kotlin 官方规范 + 业界最佳实践"
- 12 个 references/*.md 暂未迁入（源项目中这些文件内容已被 SKILL.md 覆盖，且是对 Kotlin 官方文档的复述，保留许可存疑）
- 审查输出格式保留原有三档结构，emoji 为可选（遵循 pl 的"除非用户要求否则不用 emoji"原则时可去除）
