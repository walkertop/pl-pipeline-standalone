---
id: kotlin-coding-standards
version: 1.0.0
scope: stack-specific
stack: kotlin
category: coding
severity: warning
description: Kotlin 编码规范（命名/类型安全/不可变/协程/集合/函数设计/日志）。覆盖 Kotlin 项目通用场景，不绑定具体 UI 框架。
migrated_from: KuiklyPolyCity@feature/caleb/agentic
sanitization_date: 2026-04-23
---

# Kotlin Coding Standards · 编码规范

> **Rule-ID**: `KT-001`
> **适用范围**: 所有 Kotlin 代码
> **优先级**: P0

---

## 变更日志

| 版本 | 日期 | 变更 |
|------|------|------|
| v1.0.0 | 2026-04-23 | 从源项目脱敏迁入独立仓，去除框架专属日志惯例（console → 抽象 Logger） |

---

## 设计原则

- **静态可检查优先**：优先让违规能被编译器或 detekt 类工具捕获
- **合理默认值**：当规则之间冲突时，以"更安全"为默认
- **与栈级规范协作**：本 rule 定义 Kotlin 通用部分，Android/KMP 特有规则放栈级 adapter

---

## 1. 命名规范

### Rule `KT-001-NAME`: 命名必须自解释

**Rationale**: 良好命名是最有效的文档，减少注释依赖，使代码意图一目了然。

#### 类与接口
- **类名**: PascalCase（如 `UserViewModel`、`PageDataStore`）
- **接口名**: 推荐描述性名称（如 `Card`、`Repository`）；仅当需要与实现区分时使用 `I` 前缀（如 `IPriceData`）
- **文件名**: 与主类名一致（如 `UserViewModel.kt`）

#### 函数与属性
- **函数名**: camelCase 动词开头（如 `loadData`、`shouldShow`）
- **属性名**: camelCase 名词或形容词（如 `displayMode`、`itemCount`）
- **常量**: UPPER_SNAKE_CASE（如 `TAG`、`MAX_RETRY`、`DEFAULT_TIMEOUT_MS`）

#### 特殊约定
- **Change ID**: kebab-case + 动词前缀（如 `add-feature-module`、`refactor-data-layer`）与 `pl/changes/` 目录名对齐

---

## 2. 类型安全

### Rule `KT-001-NULL`: 禁止使用 `!!` 非空断言

**Rationale**: `!!` 将编译期空安全降级为运行期崩溃。使用安全调用链可在编译期捕获空指针风险。

```kotlin
// ✅ 正确：使用安全调用链
val city = person?.address?.city ?: "Unknown"

// ❌ 错误：使用 !! 非空断言
val city = person!!.address!!.city
```

**允许的例外**:
- 单元测试中断言测试前置条件（建议改用 `assertNotNull`）
- 从不可空平台类型（如 `@NotNull` 注解的 Java API）转接时

**验收关联**: 违反此规则会在 Code Review（`ACC-001` P1）中被拦截。

### Rule `KT-001-TYPE`: 公共 API 必须显式声明返回类型

```kotlin
// ✅ 公共 API 显式类型
fun getUsers(): List<User> = repository.loadUsers()

// ❌ 避免暴露 Any 或推断类型
fun getUsers() = repository.loadUsers()  // 内部 OK，公共 API 不 OK
fun getData(): Any = fetchRaw()           // 不要暴露 Any
```

---

## 3. 不可变优先

### Rule `KT-001-IMMUT`: 优先使用 val 和不可变集合

**Rationale**: 不可变数据减少副作用，使代码行为更可预测；并发场景下天然线程安全。

```kotlin
// ✅ 优先使用 val
val count = items.size

// ✅ 公共接口暴露不可变集合
fun getUsers(): List<User>

// ❌ 避免暴露可变集合
fun getUsers(): MutableList<User>
```

---

## 4. 协程规范

### Rule `KT-001-COROUTINE`: 使用结构化并发

**Rationale**: 结构化并发确保协程生命周期与宿主组件绑定，避免泄漏和僵尸任务。

```kotlin
// ✅ 使用结构化协程作用域（按平台/框架选择）
viewModelScope.launch { /* Android ViewModel */ }
CoroutineScope(Dispatchers.Main + job).launch { /* 自定义作用域 */ }

// ❌ 禁止使用 GlobalScope
GlobalScope.launch { /* 生命周期不受控 */ }

// ✅ 协程中使用 Mutex 而非 synchronized
private val mutex = Mutex()
mutex.withLock { /* 并发安全操作 */ }

// ❌ 不要在协程中使用线程锁（会阻塞调度线程）
synchronized(lock) { delay(100) }
```

---

## 5. 函数设计

### Rule `KT-001-FN`: 函数设计遵循简洁、安全、自文档化

**Rationale**: 前置条件检查让调用者第一时间了解约束；具名参数消除参数顺序歧义。

```kotlin
// ✅ 使用前置条件检查
fun setAge(age: Int) {
    require(age > 0) { "Age must be positive, got $age" }
    this.age = age
}

// ✅ 多参数使用具名参数
resizeImage(width = 1024, height = 768, scaleFactor = 1.5)

// ✅ 单表达式函数
fun isAdult(age: Int): Boolean = age >= 18
```

---

## 6. 集合操作

### Rule `KT-001-COLL`: 优先使用函数式集合操作

**Rationale**: 函数式操作链比手写循环更简洁、意图更清晰、更不易出错。

```kotlin
// ✅ 使用函数式操作
val activeUsers = users.filter { it.isActive }.map { it.name }

// ✅ 大数据集使用 Sequence
val result = largeList.asSequence()
    .filter { it > 0 }
    .map { it * 2 }
    .toList()

// ❌ 避免在 forEach 中 return（会退出外层函数）
numbers.forEach { if (it > 5) return }

// ✅ 需要提前结束时使用 firstOrNull / any
numbers.firstOrNull { it > 5 }
```

---

## 7. 日志规范

### Rule `KT-001-LOG`: 关键操作路径必须有日志

**Rationale**: 日志是线上问题排查的**唯一线索**，缺少日志等于"盲飞"。

> **说明**: Kotlin 本身没有内置日志门面，具体 Logger 由栈级 adapter 决定（例：Android 的 `android.util.Log`、Kuikly 的 `console`、JVM 通用的 `slf4j`）。本规范只要求"有日志"，不约束具体实现。

```kotlin
// ✅ 使用项目约定的 Logger 抽象
logger.info("$TAG loadData: start")
logger.error("$TAG loadData: failed", e)

// ✅ 关键操作添加日志
class FeatureModule {
    companion object {
        const val TAG = "FeatureModule"
    }

    suspend fun loadData(): Result<Data> {
        logger.info("$TAG loadData: begin")
        return try {
            val data = api.fetch()
            logger.info("$TAG loadData: ok, ${data.size} items")
            Result.success(data)
        } catch (e: Throwable) {
            logger.error("$TAG loadData: error", e)
            Result.failure(e)
        }
    }
}
```

**必须有日志的路径**:
- 网络请求的入口与出口（成功 / 失败）
- 异常分支（catch 块）
- 用户行为触发点（Module / Service 入口）
- 状态机的关键迁移

**验收关联**: Code Review 检查关键路径日志覆盖率（`ACC-001` P1）。

---

## 8. 违规检测速查

| Rule-ID | 违规类型 | 检测方法 |
|---------|---------|---------|
| `KT-001-NULL` | 使用 `!!` | detekt `UnsafeCallOnNullableType` / 正则 `!!` |
| `KT-001-TYPE` | 公共函数无返回类型 | detekt `NoReturnStatement` + Code Review |
| `KT-001-IMMUT` | 公共 API 暴露 Mutable 集合 | 正则扫描 `fun .*\(\): Mutable` |
| `KT-001-COROUTINE` | 使用 GlobalScope | 正则扫描 `GlobalScope\.(launch|async)` |
| `KT-001-LOG` | 关键操作无日志 | Code Review 检查 Module/Service/ViewModel |

---

## 9. 与其他 rule 的关系

- **通用层** (`assets/pl/rules/`)：定义 pl-pipeline 本体纪律（不含语言）
- **本 rule (栈级)**：Kotlin 语言级规范（本文件）
- **特化栈** (`adapter-android/` / `adapter-kmp-kuikly/`)：UI 框架 / 平台特有规范

---

## Footnote · 脱敏说明

本 rule 从源项目迁入时的变化：
- 去除框架专属的 Logger 命名（原文直接用 `console.info`），改为抽象描述 + 多 Logger 选项
- 去除项目专属的 Module 命名惯例，保留通用的 `TAG + companion object` 模式
- Kotlin Serialization 相关内容分离到独立 rule `kotlinx-serialization.md`（避免单 rule 过重）
- 示例类名通用化（不再出现特定业务词）
