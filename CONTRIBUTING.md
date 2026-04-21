# 贡献指南 / Contributing

> 欢迎为 pl-pipeline 贡献。本文件是**我们内部 AI 协作和未来社区协作共用的工作守则**。

---

## 目录

- [零、三层架构速览](#零三层架构速览)
- [一、目录与命名空间约定](#一目录与命名空间约定)
- [二、Git 协作规范](#二git-协作规范)
- [三、编码守则](#三编码守则)
- [四、如何贡献一个 Adapter](#四如何贡献一个-adapter)
- [五、本地验证 Checklist](#五本地验证-checklist)

---

## 零、三层架构速览

pl-pipeline 是一个 **三层可扩展的 AI 研发范式**：

```
┌──── Layer 3 · Adapter（场景特定）─────────────┐
│  adapter-nextjs-web / adapter-python-fastapi   │
│  adapter-xxx …  （带 templates/agents/skills/  │
│                   rules/scripts/ 全家桶）       │
└───────────────────┬────────────────────────────┘
                    │ 依赖
┌──── Layer 2 · pl-core（执行层 DSL · 场景无关）─┐
│  6 阶段 + 7 门禁 + 7 产物 + 9 命令 + 编排器     │
└───────────────────┬────────────────────────────┘
                    │ 依赖
┌──── Layer 1 · piao-kernel（语义底座）──────────┐
│  URN / Artifact / Event / Snapshot / Drift /   │
│  Evolution / Extensibility（场景无关）         │
└────────────────────────────────────────────────┘
```

**三层协作契约**：
- **piao-kernel 不知道有 pl-pipeline**（它是纯语义规范）
- **pl-core 不知道有具体场景**（它调用 adapter 注入的命令，自己只管流程）
- **adapter 不定义 pipeline 阶段**（它只填充"在某个场景下这一步具体怎么做"）

详见 [docs/THREE_LAYERS.md](docs/THREE_LAYERS.md)。

---

## 一、目录与命名空间约定

### 顶层目录

```
pl-pipeline-standalone/
├── assets/
│   ├── piao/         ← Layer 1 资产（schemas / docs / wordlist）
│   ├── pl/           ← Layer 2 资产（schemas / templates / config）
│   └── adapter-sdk/  ← adapter 作者工具包（manifest schema / template）
├── scripts/
│   ├── _env.sh       ← ⭐ 路径解析（所有脚本第一行 source）
│   ├── piao-*.sh     ← Layer 1 工具
│   ├── pl-*.sh       ← Layer 2 工具
│   └── adapter-*.sh  ← adapter 管理（validate / install / create）
├── adapters/         ← Layer 3 · 场景 adapter（技术栈特定）
│   ├── adapter-nextjs-web/
│   └── adapter-python-fastapi/
├── ide-integrations/ ← IDE 集成（CodeBuddy / Cursor / Claude Code / ...）
│   └── codebuddy/
├── examples/         ← 端到端 demo 项目
├── docs/             ← 文档
└── pipeline-output/  ← 运行时产物目录（空，.gitkeep）
```

### 脚本命名规则（强约束）

| 前缀 | 含义 | 例 |
|---|---|---|
| `piao-*` | 属于 piao-kernel 层 | `piao-snapshot-produce.sh` |
| `pl-*` | 属于 pl-core 层 | `pl-status.sh` |
| `adapter-*` | adapter 管理工具 | `adapter-install.sh` |
| `_env.sh` | 环境解析（唯一下划线前缀） | `_env.sh` |

**脚本头三行必须是**：
```bash
#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/_env.sh"
set -euo pipefail
```

---

## 二、Git 协作规范

### 2.1 Commit Message 格式（Conventional Commits + 固定 scope）

```
<type>(<scope>): <subject in english, imperative, lowercase, no period>

<body 中文说明为什么改 + 改了什么，bullet point>

<footer>
```

### 2.2 允许的 type（7 种）

| type | 含义 |
|---|---|
| `feat` | 新功能（新脚本 / 新 adapter / 新产物类型） |
| `fix` | bug 修复 |
| `docs` | 纯文档变更（README / docs/*） |
| `refactor` | 重构（不改行为） |
| `chore` | 构建 / 配置 / 杂项 |
| `test` | 测试 / 验证 |
| `build` | 构建系统 / 依赖变更 |

### 2.3 允许的 scope（固定白名单，共 12 个）

| scope | 覆盖范围 |
|---|---|
| `piao` | `scripts/piao-*.sh`、`assets/piao/**` |
| `pl-core` | `scripts/pl-*.sh`、`assets/pl/{schemas,config,dashboard}/**` |
| `pl-template` | `assets/pl/templates/**` |
| `pl-schema` | `assets/{pl,piao}/schemas/**`（schema 专项变更） |
| `adapter-sdk` | `assets/adapter-sdk/**`、`scripts/adapter-*.sh` |
| `adapter-nextjs` | `adapters/adapter-nextjs-web/**` |
| `adapter-fastapi` | `adapters/adapter-python-fastapi/**` |
| `ide-codebuddy` | `ide-integrations/codebuddy/**` |
| `example-nextjs` | `examples/demo-nextjs-todo/**` |
| `example-fastapi` | `examples/demo-fastapi-users/**` |
| `docs` | `docs/**`（根目录 md 走 `repo`） |
| `repo` | `README.md` / `LICENSE` / `.gitignore` / `VERSION` / `MVP_STATUS.md` / `MIGRATION_CHECKLIST.md` / `CONTRIBUTING.md` |

### 2.4 Subject 规则

- 英文小写开头、祈使句（`add` 不是 `added` / `adds`）
- ≤ 72 字符、无句末标点
- 不以 issue id 开头

### 2.5 Footer

固定两行模板，按需挑选：

```
Phase: <Pnn-nn>          # 对应 todos 里的 phase id，可选
Co-Authored-By: walker <bin5211bin@gmail.com>
```

- Author（`git config user.name / user.email`）保留真人身份 `calebguo <bin5211bin@gmail.com>`
- `Co-Authored-By` 用 `walker` 作为别名（GitHub 合作者渲染）
- AI 辅助的提交不额外署名 AI（通过 Phase id 可追溯）

### 2.6 完整示例

```
feat(piao): migrate 5 kernel scripts to standalone with _env.sh

从宿主 KuiklyPolyCity 抽离 piao-pipeline kernel 工具脚本，为三层
架构 (piao/pl/adapter) 补齐 piao 语义层。

- add scripts/piao-snapshot-produce.sh
- add scripts/piao-snapshot-diff.sh
- add scripts/piao-drift-compute.sh
- add scripts/piao-evolution-scan.sh
- add scripts/piao-kernel-wordcheck.sh (renamed from kernel-wordcheck.sh)
- all scripts sourced via _env.sh for $PL_HOME / $PL_PROJECT resolution
- output redirected to $PL_OUTPUT/piao/

Phase: P1-2
Co-Authored-By: walker <bin5211bin@gmail.com>
```

### 2.7 禁止行为

- ❌ `git commit --amend`（除非用户明确要求）
- ❌ `git push --force`（除非用户明确要求）
- ❌ `--no-verify` / 任何跳过 hook 的手段
- ❌ 一个 commit 混多个 scope（拆开提交）
- ❌ 中文 subject（保持 git log 可国际扫读）

### 2.8 分支策略（MVP 阶段）

- 主干开发：仅 `main` 分支
- 每个 Phase 开工前不开新分支，完成后打 annotated tag：
  - `phase/P1-complete` / `phase/P2-complete` / ...
- v0.2 社区化后引入 PR 流程（届时更新本文件）

### 2.9 AI 协作下的自动提交约定

本仓库在 v0.1 MVP 阶段主要由 AI 辅助编写。AI 执行时：
- **每完成一个 todo item 自动提交一次**（无需用户预览）
- 只在**极度不确定**（如要删除大量已有文件、要改动项目根结构）时才主动询问
- 提交均按上述 §2.1–§2.7 规则生成
- 所有提交 Author 为 `calebguo <bin5211bin@gmail.com>`，Co-Authored-By 为 `walker`

---

## 三、编码守则

### Bash 脚本

- 必须 `set -euo pipefail`
- 第一行 shebang 固定为 `#!/usr/bin/env bash`
- 第二行必须 `source "$(dirname "${BASH_SOURCE[0]}")/_env.sh"`
- 不允许硬编码 `/Users/...` 或 `KuiklyPolyCity` 等宿主路径
- 不允许写死 `./gradlew` / `npm` / `pytest` 等构建命令（由 adapter 注入）
- 颜色输出用 `RED/GREEN/YELLOW/BLUE/NC`，函数用 `log_info / log_success / log_warn / log_error`

### Markdown

- 中文 + 半角标点 + 链接用相对路径
- 代码块必须带语言标签（```bash / ```yaml / ```markdown）
- 章节结构用 `#` 一级、`##` 二级、`###` 三级，不用跳级

### YAML / JSON Schema

- schema 文件用 `$schema: "https://json-schema.org/draft/2020-12/schema"`
- adapter.yaml 必须能被 `scripts/adapter-validate.sh` 通过

---

## 四、如何贡献一个 Adapter

详见 [assets/adapter-sdk/docs/adapter-authoring-guide.md](assets/adapter-sdk/docs/adapter-authoring-guide.md)（开发中）。

最小 adapter 骨架：

```bash
bash scripts/adapter-create.sh my-adapter
# → adapters/adapter-my-adapter/ 会自动生成以下骨架：
#   adapter.yaml
#   README.md
#   templates/{spec,plan,taskdag}.md
#   agents/
#   skills/
#   rules/
#   scripts/{build,verify,lint}.sh
#   docs/case-study.md
```

然后逐项填充、用 `bash scripts/adapter-validate.sh adapters/adapter-my-adapter` 校验。

---

## 五、本地验证 Checklist

在 `git commit` 之前，AI/贡献者应确保：

- [ ] 所有改动的 bash 脚本通过 `bash -n <script>` 语法检查
- [ ] 新增的 schema 文件可被 `ajv-cli` 或等价工具加载
- [ ] 新增 adapter 通过 `bash scripts/adapter-validate.sh adapters/adapter-xxx`
- [ ] 相关的 `README.md` / `MVP_STATUS.md` 已同步更新
- [ ] 没有误入的 `/Users/...` 绝对路径

---

## 最后一行永远是同一句话

> 这个项目的价值不在每个模块多先进，而在它们**共用一套契约**。契约破了，系统就是普通脚手架。
