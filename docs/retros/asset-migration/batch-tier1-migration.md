# Tier 1 资产迁移 Retro

> **日期**: 2026-04-23
> **里程碑**: v1.5 (核心资产迁移) · Tier 1
> **批次**: 4 个资产（1 通用 rule + 3 栈级）+ 新建 adapter-kotlin

## 1. 迁移范围

| # | 源文件 | 目标 | 分层 | 状态 |
|---|--------|------|------|------|
| 1 | `.codebuddy/rules/git-commit-rules.md` | `assets/pl/rules/git-commit.md` | generic | ✅ |
| 2 | `.codebuddy/rules/kotlin-coding-standards.md` | `adapters/adapter-kotlin/rules/kotlin-coding-standards.md` | stack:kotlin | ✅ |
| 3 | `.codebuddy/rules/serialization-rules.md` | `adapters/adapter-kotlin/rules/kotlinx-serialization.md` | stack:kotlin | ✅ |
| 4 | `.codebuddy/skills/kotlin-code-review/SKILL.md` | `adapters/adapter-kotlin/skills/kotlin-code-review/SKILL.md` | stack:kotlin | ✅ |

**附加产物**:
- 新建 `adapters/adapter-kotlin/` 骨架（adapter.yaml + README.md + 3 scripts）

## 2. 分层决策

### 为什么 git-commit 是通用（generic）
- Conventional Commits 是语言 / 框架无关的业界标准
- 分支命名约定（feature/fix/refactor）在所有 git 项目中适用
- Scope 枚举本就是"动态扩展"风格，无需绑定特定栈

### 为什么 kotlin-* 都归为栈级（stack:kotlin）
- `kotlin-coding-standards`：直接引用 `!!` / `by lazy` / `inline reified` 等 Kotlin 语法
- `kotlinx-serialization`：API 完全 Kotlin 生态专属
- `kotlin-code-review`：十大审查维度全部围绕 Kotlin 语言特性

### 为什么新建 adapter-kotlin 而不是放入 adapter-android / adapter-kmp-kuikly
- **避免栈级碎片化**：Android 和 Kuikly 都用 Kotlin，若每个 adapter 都重复"Kotlin 编码规范"会造成 N 份拷贝
- **依赖关系清晰**：adapter-android / adapter-kmp-kuikly 未来可声明 `requires: [adapter-kotlin@>=1.0.0]` 叠加
- **纯 JVM Kotlin 项目也能用**：不强制绑定 UI 框架

## 3. 脱敏操作清单

| 位置 | 改动 |
|------|------|
| git-commit: `chore(gradle): update Kuikly dependency` | → `chore(deps): bump framework to v2.3` |
| git-commit: `Closes: openspec/changes/add-blindbox-feature` | → `Closes: pl/changes/add-oauth2-login` |
| git-commit: 整个"迁移记录"章节（源项目专属） | 改为通用的"变更记录关联"章节 |
| git-commit: Scope 表 | 通用化为"业务域 / 技术层 / 工程化 / UI"四大模式 |
| kotlin-std: `console.info` Kuikly 专属 Logger | 抽象为"项目约定的 Logger 抽象"，举 slf4j/android.util.Log/console 三例 |
| kotlin-std: `MODULE_NAME` 框架惯例 | 保留通用的 `TAG + companion object` 模式 |
| kotlin-std: 重复的序列化示例 | 移至 kotlinx-serialization.md，保持单一职责 |
| serialization: "匈牙利命名法 强约束" | 改为"命名与字段映射选择标准" |
| code-review: "基于腾讯 Kotlin 代码规范" | 改为"基于 Kotlin 官方规范 + 业界最佳实践" |
| code-review: `references/*.md` 12 个文件 | **暂未迁**（内容是对 Kotlin 官方文档复述，许可存疑；SKILL.md 自包含已足够） |

## 4. 扫描结果对比

**迁移前** (coupling-scan-before.txt):
- 硬耦合: 3 处 (`Kuikly dependency` / `console 对象（Kuikly 标准）` / `基于腾讯 Kotlin 代码规范`)
- 软耦合: 5 处（openspec 路径 / MIGRATION_LOG / MODULE_NAME / 匈牙利命名法强约束 / kotlin-standard 内部文件引用）

**迁移后** (coupling-scan-after.txt):
- 真实耦合: **0 处**
- 合法 frontmatter `migrated_from`: 4 处（追溯用途，非耦合）
- Footnote 节说明脱敏变化: 4 处（透明化）

## 5. adapter-kotlin 设计决策

### build_adapter 配置

```yaml
build_adapter:
  type: gradle
  commands:
    compile_check: ./gradlew compileKotlin --quiet     # VERIFY 快速门禁
    lint:          ./gradlew detekt --continue
    test:          ./gradlew test --continue
    full_build:    ./gradlew build --continue         # SMOKE / ARCHIVE
```

- `compile_check` 只跑 compileKotlin（不含 test），30 秒级反馈
- `full_build` 跑完整 build（含 test + package），适用于 SMOKE 阶段
- 失败模式 `e: .*: .*` 对应 Kotlin 编译错误格式 `e: File.kt:12: error: ...`

### scripts 分层
- `build.sh` - 完整构建（compile + test + build）
- `verify.sh` - 快速验证（compile + test，不含 package）
- `lint.sh` - 静态检查（detekt + ktlint，可选）

所有脚本**优雅降级**：lint 工具未配置时输出提示，不报错终止。

## 6. 关键决策记录

### 决策 1：kotlin-code-review 的 references/*.md 是否迁移
- **问题**: 源项目有 12 个参考文件（variable.md / type.md / coroutines.md 等），内容是对 Kotlin 官方文档的复述
- **权衡**: 迁 → 扩大 skill 体积但提高离线可读性；不迁 → 更简洁但失去部分上下文
- **决策**: 不迁。SKILL.md 自包含十大维度的正反例已足够，细节交给 Kotlin 官方文档（避免许可风险）
- **回退路径**: 如未来需要，可作为 `kotlin-official-docs-mirror` skill 单独迁入并标注 upstream

### 决策 2：serialization 是否合并到 kotlin-coding-standards
- **问题**: 源项目中 kotlin-coding-standards 已包含简要序列化示例
- **权衡**: 合并 → 单一入口；分离 → 职责清晰，可独立加载
- **决策**: 分离。kotlinx.serialization 是独立子生态（有自己的版本迭代/特性），frontmatter 的 `scope: on-demand` 允许项目按需加载

### 决策 3：git-commit 是否加入自动化 hook 脚本
- **问题**: 源项目有 `scripts/setup-hooks.sh` 安装 commit-msg 检查
- **决策**: 本次**不迁** hook 脚本，只迁 rule 文档。原因：
  1. hook 安装是项目级操作，应由用户自行决定
  2. 不同项目用不同 hook 框架（husky / pre-commit / lefthook / git-hooks 原生），不一刀切
  3. 可在未来 v1.6 的 `adapter-common` 中提供"hook 安装模板"可选工具

## 7. 验证

- [x] frontmatter 完整（id / version / scope / category / migrated_from / sanitization_date）
- [x] 所有硬耦合词扫描 = 0
- [x] `assets/pl/rules/README.md` 清单更新
- [x] `assets/pl/skills/README.md` 清单更新（指向 adapter-kotlin）
- [x] `adapters/adapter-kotlin/adapter.yaml` 通过形式审查（仿照 adapter-nextjs-web 结构）
- [ ] `adapter-validate.sh adapter-kotlin` 脚本实跑（D5 任务合并验证）
- [ ] 真实 Kotlin 项目 install 测试（D5 任务）

## 8. 下一步

1. D5: 写 adapter-authoring 指南（以 adapter-kotlin 为范例）
2. D5: 写 v1.4 → v1.5 升级文档
3. 合并成 tag `pl-v1.5.0-rc.1`

## 9. 经验沉淀（喂给 v1.6+）

1. **分层判断三问法**（可进 docs/guides/asset-layering.md）:
   - 这条规则在非此语言/非此框架的项目里还成立吗？Yes → generic / No → stack-specific
   - 这条规则在同语言不同 UI 框架（如 Android vs Kuikly）里都一样吗？Yes → stack-common / No → 更细一层
   - 这条规则的示例代码有没有出现特定业务词？有 → 先去除再判断

2. **adapter 骨架脱敏清单**（可进 adapter-authoring.md）:
   - [ ] adapter.yaml metadata.name 不含组织/项目专属词
   - [ ] adapter.yaml detect 规则足够宽泛（文件存在 > 特定字符串匹配）
   - [ ] README.md "提供什么"表格数量与 adapter.yaml provides 节一致
   - [ ] scripts/*.sh 的 "NEXT_*" / "KOTLIN_*" 等环境变量名不与其他 adapter 冲突

3. **"零硬耦合"≠"零追溯"**：frontmatter 的 `migrated_from` 是合法的追溯信息，不应从脱敏统计中算作耦合点。脱敏扫描工具未来应支持"白名单 frontmatter 字段"。
