# adapter-kotlin

> pl-pipeline 的 Kotlin 通用项目适配器。把"Kotlin 编码规范"与"gradle 构建"注入为
> pl-core 可直接消费的 rules / skills / scripts，让你在新 Kotlin 项目里接入
> `/pl:proposal → /pl:plan → /pl:implement → /pl:verify → /pl:archive`。

## 适用场景

- **Kotlin 项目通用底座**：JVM / Multiplatform / Android / Native
- **不绑定 UI 框架**：可与 adapter-android、adapter-kmp-kuikly 等栈级适配器组合
- **以 Gradle 为构建系统**（Maven 也可运行，但构建命令需覆写 `build_adapter`）

## 一键安装

```bash
cd /path/to/my-kotlin-project

# 初始化 pl（若还没做过）
cp $PL_ASSETS/pl/config.default.yaml pl/config.yaml
mkdir -p .codebuddy/{agents,skills,rules} scripts pl/changes

# 安装本 adapter（需先 export PATH="$PL_HOME/bin:$PATH" 启用 pl CLI）
pl adapter install \
  $PL_HOME/adapters/adapter-kotlin \
  .
```

完成后：

```
.pl-adapter.yaml                          ← 记录注入元数据
.codebuddy/rules/kotlin-coding-standards.md
.codebuddy/rules/kotlinx-serialization.md
.codebuddy/skills/kotlin-code-review/SKILL.md
scripts/adapter-kotlin-{build,verify,lint}.sh
```

## 提供什么

| 资产类 | 数量 | 亮点 |
|---|---|---|
| Skills | 1 | kotlin-code-review：P0/P1/P2 三档分级审查 |
| Rules | 2 | kotlin-coding-standards / kotlinx-serialization |
| Scripts | 3 | build / verify / lint（基于 gradle） |
| BuildAdapter | 1 | `./gradlew compileKotlin` 作为 `compile_check` |

## 与其他 adapter 组合

```yaml
# 在项目 .pl-adapter.yaml 中声明多个 adapter
adapters:
  - adapter-kotlin           # 基础：Kotlin 编码规范
  - adapter-android          # 叠加：Android 特定 rules
  # 或
  - adapter-kmp-kuikly       # 叠加：Kuikly KMP 特定 rules
```

栈级规则覆盖顺序：**项目 > 特化栈（android/kuikly） > 通用栈（kotlin） > pl 通用**。

## 校验

```bash
pl adapter validate $PL_HOME/adapters/adapter-kotlin
```

## 来源

本 adapter 的 rules / skill 从 KuiklyPolyCity 项目脱敏迁入（v1.5，2026-04）。
迁移记录：`docs/retros/asset-migration/batch-tier1-migration.md`。
