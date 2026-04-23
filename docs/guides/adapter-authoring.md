# adapter-authoring · 如何编写一个 pl-pipeline Adapter

> **适用读者**：想把一个"技术栈的最佳实践"封装成可分发 adapter 的贡献者
> **参考实现**：`adapters/adapter-nextjs-web/`、`adapters/adapter-python-fastapi/`、`adapters/adapter-kotlin/`
> **版本**: v1.5（配合 `assets/pl/` 核心资产栈使用）

---

## 0. Adapter 是什么

pl-pipeline 的三层资产栈：

```
┌─────────────────────────────────────────────┐
│ Project Layer                               │
│   <user-project>/.codebuddy/                │
│   <user-project>/pl/changes/                │
└─────────────────────────────────────────────┘
                  ↑ 覆盖
┌─────────────────────────────────────────────┐
│ Stack Layer (Adapter)           ← 本文主角   │
│   adapters/adapter-<stack>/                 │
│   例：adapter-nextjs-web / adapter-kotlin   │
└─────────────────────────────────────────────┘
                  ↑ 覆盖
┌─────────────────────────────────────────────┐
│ Generic Layer                               │
│   assets/pl/{skills,rules,agents,templates} │
└─────────────────────────────────────────────┘
```

**Adapter 的职责**：把**某一技术栈的最佳实践**（编码规范、构建命令、典型架构决策）打包成 pl-core 可直接消费的产物。

**Adapter 不是**：
- 具体业务代码（那是用户项目的事）
- 通用纪律（那是 `assets/pl/` 的事）
- IDE 插件（那是 `ide-integrations/` 的事）

---

## 1. 三个判断：是否该写 Adapter

### 判断 A：这个最佳实践跨不跨业务？

✅ 应该写 adapter:
- "Next.js App Router 必须用 RSC 做默认渲染"
- "Kotlin 禁用 `!!` 非空断言"
- "FastAPI 请求体必须用 Pydantic 校验"

❌ 不该写 adapter（该在项目级）:
- "我们公司的订单 API 返回必须用特定错误码"
- "所有页面必须在顶部显示 Logo"

### 判断 B：这条规则跨不跨技术栈？

✅ 应该进 `assets/pl/`（通用层）:
- Git commit 规范
- 验收标准（P0/P1/P2 分级）
- 辩证对待模糊需求

✅ 应该进 adapter（栈级）:
- "Kotlin 函数必须显式返回类型"
- "Next.js RSC 禁止直接调用浏览器 API"

### 判断 C：这个 adapter 需不需要粒度更细的子 adapter？

例：**Kotlin 相关**
- adapter-kotlin（通用 Kotlin 规范）← 最基础
- adapter-android（叠加 Android 特性）← 依赖 adapter-kotlin
- adapter-kmp-kuikly（叠加 Kuikly KMP 特性）← 依赖 adapter-kotlin

**优先写基础层**，子栈 adapter 通过 `requires` 字段声明依赖。

---

## 2. 标准目录结构

```
adapters/adapter-<stack>/
├── adapter.yaml                 ← 元数据与清单（必需）
├── README.md                    ← 使用说明（必需）
├── rules/                       ← Rule 文件
│   ├── <rule-id>.md
│   └── ...
├── skills/                      ← Skill 文件
│   ├── <skill-id>/
│   │   └── SKILL.md
│   └── ...
├── agents/                      ← Agent 文件
│   ├── <agent-id>.md
│   └── ...
├── templates/                   ← 场景化模板（spec/plan/taskdag）
│   ├── spec.md
│   ├── plan.md
│   └── taskdag.md
├── scripts/                     ← 构建/验证/lint 脚本
│   ├── build.sh
│   ├── verify.sh
│   └── lint.sh
└── docs/                        ← 栈特有的进阶文档（可选）
```

---

## 3. adapter.yaml 规范

### 3.1 必需字段

```yaml
apiVersion: pl.dev/v1
kind: Adapter

metadata:
  id: <kebab-case>                    # 全局唯一
  name: <人类可读名称>
  description: >
    <一段话描述这个 adapter 解决什么问题、目标项目类型>
  version: <SemVer>                   # 如 0.1.0
  compatible_pl: ">=0.1.0-mvp <1.0.0" # 兼容的 pl-core 版本范围
  license: Apache-2.0
  authors:
    - name: <your-name>
      email: <your-email>
  detect:                             # 自动识别规则（OR 关系）
    - file_exists: "package.json"
    - package_json_has: "next"

provides:                             # 本 adapter 贡献什么
  skills:   [...]
  rules:    [...]
  agents:   [...]
  templates: {...}
  scripts:  {build, verify, lint}
  build_adapter:                      # 构建命令（供 pl-core 读取）
    type: <gradle|npm|pip|cargo|go|custom>
    commands:
      compile_check: {...}
      test: {...}
      full_build: {...}

requires:                             # 依赖
  tools:
    - {name, min_version, install_hint}
  files:
    - <path>

contract:                             # 声明侧契约（给 piao-contract-drift-compute）
  expected_files: [...]
  peer_versions: {...}
  known_bad_combos: [...]             # 已知不兼容组合

piao_emit:                            # 是否发射 piao 事件
  on_stages: [VERIFY, ARCHIVE]
  urn_namespace: "urn:piao:artifact:pl:<stack>"
```

### 3.2 detect 规则语法

| 断言 | 含义 |
|------|------|
| `file_exists: <path>` | 文件存在（相对项目根） |
| `package_json_has: <dep>` | package.json 中有依赖（适用 npm/pnpm/yarn） |
| `file_contains: {path, pattern}` | 文件内容匹配正则 |
| `env_var: <name>` | 特定环境变量已设（少用） |

**多条规则是 OR 关系**。若需 AND 组合，用一条 `file_contains` 包含复合判断。

### 3.3 build_adapter 契约

每个 adapter **必须**提供 `compile_check` 作为 VERIFY 阶段的最小闭环。

```yaml
build_adapter:
  type: <type>
  commands:
    compile_check:                    # VERIFY 快速门禁（30 秒级）
      cmd: "<命令>"
      success_pattern: "<匹配则通过>"
      failure_patterns:               # 多个失败特征（OR）
        - "<pattern1>"
        - "<pattern2>"
      timeout_sec: <秒数>
```

**设计要求**：
- `compile_check` 命令 **不得运行测试**（太慢），只做语法/类型检查
- `failure_patterns` 要足够**特异**（避免误报）
- 优先使用退出码而非文本匹配，文本匹配作为兜底

---

### 3.4 capabilities · 给 consumer 一层抽象（v1.7+）

`provides.capabilities[]` 是 v1.7 双向 CDC 引入的可选段。

**为什么要它**：v1.6 之前，consumer（change）的 pact 只能声明"我用了 skill X / build_command Y"。
但这意味着 consumer 被绑死到 adapter 的内部实现名——adapter 内部把 `nextjs-data-fetching` 改名成
`nextjs-server-actions` 就是 breaking change。

加了 capability 抽象层之后，consumer 可以声明"我需要 `server-action-support`"，
adapter 内部用什么 skill 实现是它自己的事。

#### 语法

```yaml
provides:
  capabilities:
    - id: <kebab-case-id>                # 必填，如 typecheck / server-action-support
      backed_by:                         # 必填，指向真实实现（或 null）
        skill: <skill-id>                # 四选一：skill / rule / build_command / null
        # rule: <rule-id>
        # build_command: <command-id>
      since: <semver>                    # 可选，从哪个 adapter 版本开始支持
      deprecated_in: <semver>            # 可选，从哪个版本起标为废弃（verify 给 warning）
      removed_in: <semver>               # 可选，从哪个版本起移除（verify 报 broken）
      reason: <text>                     # 可选，废弃原因 / 不支持原因
```

#### 三种特殊用法

| 写法 | 语义 |
|---|---|
| `backed_by: { skill: nextjs-data-fetching }` | adapter 用这个 skill 实现该 capability |
| `backed_by: null` + `reason: ...` | **显式声明**"本 adapter 不支持此 capability"。比"不写"更明确，避免 consumer 猜 |
| `deprecated_in: 0.3.0` | 0.3 起 verify 给 warning，consumer 应迁移；`removed_in` 触发后才阻塞 |

#### 命名建议

- 用问题域语言命名（`server-action-support`、`smoke-probe`），不要用实现名（`nextjs-data-fetching-skill`）
- 一个 capability 对应一个 backed_by；如果一个能力需要多个底层资产配合，
  说明它是"复合能力"，应当拆成多个 capability 各自单一职责

#### 何时不写

- 一次性 / 内部实现细节 → 不需要做成 capability
- 还没有任何 consumer 用过 → 等真有 pact 引用了再补
- adapter 还在 0.x 早期实验 → 直接迁移 skill 名也可以接受

---

## 4. rules 写作规范

### 4.1 frontmatter

```yaml
---
id: <kebab-case>                      # 与文件名一致
version: 1.0.0
scope: stack-specific                 # generic | stack-specific | project-specific
stack: <stack-id>                     # scope=stack-specific 时必填
category: coding | verify | review | ...
severity: error | warning | info
description: <一句话描述规则作用>
---
```

### 4.2 正文结构

```markdown
# <Rule 标题> · <人类可读副标题>

> **Rule-ID**: `XXX-001`
> **适用范围**: ...
> **优先级**: P0 | P1 | P2

## 变更日志
| 版本 | 日期 | 变更 |

## 设计原则
<为什么要有这条 rule，它解决什么问题>

## N. 规则正文
### Rule `XXX-001-<SUFFIX>`: <一句话断言>
**Rationale**: <为什么这样规定>
<正例反例代码>
**验收关联**: <与 acceptance-criteria 的 P 档关联>

## 违规检测速查
| Rule-ID | 违规类型 | 检测方法 |

## Footnote · 脱敏说明
<如果是从项目迁入，说明改了什么>
```

### 4.3 硬规则

- ✅ 每条 Rule 都有 `Rationale`（为什么）
- ✅ 正反例对照
- ✅ "违规检测速查"表便于机器扫描
- ❌ 不写"项目内部人才懂"的业务缩写
- ❌ 不引用特定团队的 Wiki/内网链接

---

## 5. skills 写作规范

### 5.1 frontmatter

```yaml
---
id: <kebab-case>
version: 1.0.0
scope: stack-specific
stack: <stack-id>
category: spec | review | planning | finalization | ...
requires:                             # 可选：依赖其他 skill/rule
  - <id>@<version-range>
description: <一句话描述与触发词>
---
```

### 5.2 SKILL.md 结构

```markdown
# <Skill 名> · Skill

> **触发词**：<短语列表>

## 概述
<这个 skill 能做什么>

## 适用范围
<语言版本 / 平台 / 框架等约束>

## 工作流
<步骤 1 → 步骤 2 → 步骤 3 流程图>

## 示例
<至少 2 个正向示例 + 1 个反向示例>

## 输出格式
<结构化输出的模板>

## 与 Rules 的关系
<依赖哪些 rule，遵循哪些 rule>

## Footnote · 脱敏说明（若迁自项目）
```

---

## 6. agents 写作规范

Agent 是**流程编排类**的 prompt，区别于 skill 的"单次任务"：

| 维度 | Skill | Agent |
|------|-------|-------|
| 触发 | 关键词 | 显式调用 |
| 粒度 | 单次任务 | 多轮流程 |
| 状态 | 无状态 | 维护流水线状态 |
| 示例 | `kotlin-code-review` | `pipeline-master` |

写作结构与 skill 类似，但正文侧重**交接协议**：
- 上游来源（哪个阶段触发）
- 下游去向（本阶段完成后交给谁）
- 边界（不做什么）
- 异常路径（卡住时怎么办）

---

## 7. scripts 规范

### 7.1 三件套

所有 adapter **必须**提供：

```
scripts/build.sh    # 完整构建（compile + test + package）
scripts/verify.sh   # 快速验证（VERIFY 阶段用，不含 package）
scripts/lint.sh     # 静态检查（pre-commit 用）
```

### 7.2 脚本约定

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

# 环境变量以 <STACK>_ 为前缀，如 KOTLIN_BUILD_TASK / NEXT_BUILD_ANALYZE
# 可选工具要优雅降级（检测 → 有则跑 → 无则提示）
```

### 7.3 退出码契约

- `0` = 成功
- `1` = 已知失败（编译错误 / 测试失败 / lint 违规）
- `2+` = 环境错误（文件缺失 / 工具未安装）

pl-core 会根据退出码决定是否阻断流水线。

---

## 8. 安装与分发

### 8.1 用户侧安装

```bash
cd /path/to/user-project

# pl 初始化（一次性）
cp $PL_ASSETS/pl/config.default.yaml pl/config.yaml

# 安装 adapter
bash $PL_HOME/scripts/adapter-install.sh \
  $PL_HOME/adapters/adapter-<your-stack> \
  .
```

安装会生成：
```
.pl-adapter.yaml                                ← 注入元数据
.codebuddy/rules/<rule-id>.md                  ← 复制 rules
.codebuddy/skills/<skill-id>/SKILL.md          ← 复制 skills
.codebuddy/agents/<agent-id>.md                ← 复制 agents
scripts/adapter-<stack>-{build,verify,lint}.sh ← 复制 scripts
```

### 8.2 校验

发布前务必通过：

```bash
bash $PL_HOME/scripts/adapter-validate.sh $PL_HOME/adapters/adapter-<your-stack>
```

校验项：
- adapter.yaml 格式合法
- provides 声明的文件都存在
- 每个 rule/skill 有合法 frontmatter
- scripts 有 shebang + `set -euo pipefail`
- README.md 存在且非空

---

## 9. 脱敏检查清单（从项目迁入时必查）

- [ ] `adapter.yaml` metadata.name 不含组织 / 内部项目名
- [ ] `adapter.yaml` homepage 指向公开仓库（不是内网）
- [ ] `adapter.yaml` detect 规则足够宽泛（文件存在 > 特定字符串）
- [ ] README.md 不提及特定业务 / 团队
- [ ] rule/skill 正文 `grep -iE 'company|团队缩写|内部项目名'` 无匹配
- [ ] 示例代码中的变量名 / 类名不含业务词（`OrderData` OK，`JJPaymentService` 不 OK）
- [ ] scripts 的环境变量以通用栈前缀开头（`KOTLIN_*` OK，`COMPANY_X_*` 不 OK）
- [ ] frontmatter `migrated_from` 字段填完整，便于追溯

详见 [`docs/guides/asset-sanitization-guide.md`](./asset-sanitization-guide.md)。

---

## 10. 以 adapter-kotlin 为例走查

### 设计决策
1. **为什么叫 adapter-kotlin 而不是 adapter-android**？
   - Android 和 Kuikly 都用 Kotlin，希望避免每个都拷一份 Kotlin 规范
   - adapter-kotlin 作为基础层，其他栈通过 `requires` 叠加
2. **哪些 rule 放 adapter-kotlin**？
   - 所有纯 Kotlin 语言级规范（命名 / 类型 / 协程 / 集合等）
3. **哪些 rule 不放这里，放 adapter-android / adapter-kmp-kuikly**？
   - Android 特有：Lifecycle / ViewBinding / Compose 渲染
   - Kuikly 特有：Card / Module / PageEntry 模式

### 文件清单
```
adapters/adapter-kotlin/
├── adapter.yaml                                 # gradle 为构建基座
├── README.md                                    # 强调"可与其他栈 adapter 组合"
├── rules/
│   ├── kotlin-coding-standards.md               # 通用 Kotlin 规范
│   └── kotlinx-serialization.md                 # 序列化专项
├── skills/
│   └── kotlin-code-review/SKILL.md              # P0/P1/P2 分级审查
└── scripts/
    ├── build.sh                                 # ./gradlew build
    ├── verify.sh                                # ./gradlew compileKotlin + test
    └── lint.sh                                  # detekt + ktlint（优雅降级）
```

### 可复用模式
- `scripts/lint.sh` 的"工具检测 → 跑 or 跳过"模式可推广到其他 adapter
- `adapter.yaml` 的 `known_bad_combos` 字段强烈建议所有 adapter 声明（配合 piao-contract-drift-compute）
- Footnote "脱敏说明" 节在每个从项目迁入的文件中保留，提升透明度

---

## 11. 常见陷阱

### ❌ 陷阱 1：detect 规则过窄
```yaml
# 错误：只识别特定子版本
detect:
  - file_contains:
      path: package.json
      pattern: '"next": "15\\.'
```
**修**：
```yaml
detect:
  - package_json_has: "next"      # 任何版本都识别
```

### ❌ 陷阱 2：rule 里依赖栈外工具
```markdown
# 错误：在 adapter-kotlin 的 rule 里要求用 eslint（JavaScript 工具）
```
**修**：每个 adapter 的 rules 只依赖本栈工具。

### ❌ 陷阱 3：scripts 硬编码项目路径
```bash
# 错误
cd /Users/alice/projects/my-project
```
**修**：
```bash
cd "$PROJECT_ROOT"               # 由 SCRIPT_DIR 推导
```

### ❌ 陷阱 4：不写 Footnote 脱敏说明
从项目迁入时若不记录"改了什么"，后续维护者无法判断哪些是原创哪些是适配后。

---

## 12. 发布 checklist

当你准备好贡献一个新 adapter 时：

- [ ] adapter.yaml 通过 `adapter-validate.sh`
- [ ] 每个 rule / skill / agent 有 frontmatter + Footnote
- [ ] scripts 三件套齐全且退出码符合契约
- [ ] README.md 的"提供什么"表格与 adapter.yaml provides 一致
- [ ] 在真实项目（示例仓）install 跑通一次
- [ ] 有至少 1 个迁移 retro 文档（`docs/retros/asset-migration/<batch>.md`）
- [ ] CHANGELOG.md 在 v<版本> 节记录新增 adapter
- [ ] 在 `adapters/README.md`（若有）清单中加一行

---

## 附录 A · 与 assets/pl 分层关系速查

| 位置 | 粒度 | 示例 |
|------|------|------|
| `assets/pl/rules/` | 通用纪律 | `git-commit.md`、`acceptance-criteria.md` |
| `assets/pl/skills/` | 通用能力 | `spec-normalizer/`、`finalization-template/` |
| `assets/pl/agents/` | 通用编排 | `pipeline-master.md`、`knowledge-archiver.md` |
| `adapter-<stack>/rules/` | 栈级规范 | `kotlin-coding-standards.md`、`typescript-strict.md` |
| `adapter-<stack>/skills/` | 栈级能力 | `kotlin-code-review/`、`react-server-components` |
| `adapter-<stack>/agents/` | 栈级编排 | `nextjs-architect.md`、`nextjs-reviewer.md` |

**覆盖关系**：项目级 > 栈级 > 通用。三层并存时 pl-core 自动合并并以更具体的层为准。

---

## 附录 B · 参考实现

| Adapter | 特点 |
|---------|------|
| [`adapter-nextjs-web`](../../adapters/adapter-nextjs-web/) | 最完整实现，含 contract + peer_versions + known_bad_combos |
| [`adapter-python-fastapi`](../../adapters/adapter-python-fastapi/) | Python 栈，展示不同构建系统（pip）的配置 |
| [`adapter-kotlin`](../../adapters/adapter-kotlin/) | 栈级基础 adapter（无 UI 框架绑定），可被其他 adapter 组合 |

---

**有问题？** 打开 GitHub Issue 讨论，或读一下 `docs/guides/asset-sanitization-guide.md` 先。
