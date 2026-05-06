# 在新项目中导入和使用 pl-pipeline

这份文档说明如何把 pl-pipeline 接入一个新项目或已有项目，并把它用成一个 AI Coding 控制面。

pl-pipeline 的定位不是替代 Claude Code、Codex、Cursor、CodeBuddy 或其他 IDE。它更像项目里的工程操作层：把需求、计划、任务、执行、验证、修复和证据沉淀成一条可重复的链路。

```text
SPEC -> PLAN -> TASKDAG -> agent run -> gate -> repair -> trace -> archive
```

## 适用场景

适合接入 pl-pipeline 的项目通常有这些特征：

| 场景 | pl-pipeline 提供的价值 |
|---|---|
| 新项目从 0 到 1 | 先生成规范骨架，避免直接进入随意编码 |
| 已有项目要引入 AI Coding | 用 `pl detect` 先扫描，再低侵入接入 |
| 多人或多 Agent 协作 | `.state.md`、`spec.md`、`plan.md`、`taskdag.md` 成为交接上下文 |
| 需要可验证交付 | gate、smoke、CDC、trace 形成证据链 |
| 想接 Codex / Claude 等外部 coding agent | 用 `pl agent run` 统一执行、验证、修复和记录 |

不适合的情况：

- 一次性脚本，没有长期维护价值。
- 完全不需要需求记录、任务拆解或验收证据。
- 项目没有任何可自动化验证手段，且短期也不准备补。

## 核心概念

接入前先理解 5 个对象：

| 对象 | 路径或命令 | 作用 |
|---|---|---|
| 项目配置 | `pl/config.yaml` | 声明项目命名空间、adapter、agent repair 策略等 |
| Change | `pl/changes/<change-id>/` | 一次需求或改动的工作单元 |
| 状态源 | `.state.md` | 当前阶段、gate 状态、任务进度 |
| 任务拆解 | `taskdag.md` | Agent 或人要逐个完成的任务 |
| 证据流 | `pipeline-output/trace/*.events.jsonl` | gate、smoke、agent、contract 等事件 |

推荐把 pl-pipeline 当作项目内的控制面：

```text
开发者 / Agent
  -> 读取 spec / plan / taskdag
  -> 执行具体代码改动
  -> 通过 pl run / pl agent run / pl smoke 验证
  -> 把结果写入 trace
```

## 方式一：创建全新项目

先安装全局 `pl`：

```bash
curl -fsSL https://raw.githubusercontent.com/walkertop/pl-pipeline-standalone/main/install.sh | bash
source ~/.zshrc
pl --version
pl doctor
```

创建项目：

```bash
pl new my-app --stack nextjs
cd my-app
export PL_PROJECT="$PWD"
```

可选 stack：

| Stack | 适合项目 |
|---|---|
| `nextjs` | Next.js Web 应用 |
| `fastapi` | Python FastAPI 服务 |
| `crawler` | 爬虫或数据采集项目 |
| `monorepo-trio` | 前端 + API + 爬虫的多模块项目 |
| `bare` | 任意技术栈，只接入 pl-core |

创建后先跑自检：

```bash
pl status
pl status --self-check
```

然后创建或继续第一个 change：

```bash
pl init add-first-feature --name "Add first feature" --domain core
pl run --change add-first-feature --gate B1
```

## 方式二：导入已有项目

已有项目不要直接强行安装 adapter，先只读扫描：

```bash
cd /path/to/existing-project
pl detect
```

根据扫描结果选择接入方式：

```bash
# 最低侵入：只放 pl 骨架
pl new whatever --here --stack bare

# Next.js 项目
pl new whatever --here --stack nextjs

# FastAPI 项目
pl new whatever --here --stack fastapi
```

`--here` 会尽量保守：

- 保留已有 `.git`。
- 保留已有 `README.md`、源码和配置。
- 已有 `.gitignore` 时只追加 pl 规则。
- 已有 `pl/config.yaml` 时不会重复安装。

导入后建议马上做一次 baseline：

```bash
export PL_PROJECT="$PWD"
pl status --self-check
pl init baseline-adoption --name "Adopt pl-pipeline" --domain infra
```

在 `baseline-adoption/spec.md` 里记录：

- 当前项目技术栈。
- 当前已有测试命令。
- 当前已知风险。
- 本次只接入控制面，不做业务重构。

## 推荐目录结构

接入后的关键目录如下：

```text
your-project/
  pl/
    config.yaml
    changes/
      add-search/
        .state.md
        spec.md
        plan.md
        taskdag.md
  pipeline-output/
    trace/
    agent-runs/
  .codebuddy/              # 如果安装了 adapter，可能出现
  scripts/                 # 推荐放 gate / repair / smoke 脚本
```

建议约定：

- `pl/changes/<id>/spec.md` 写“要解决什么问题”。
- `pl/changes/<id>/plan.md` 写“怎么做”。
- `pl/changes/<id>/taskdag.md` 写“拆成哪些可执行任务”。
- `scripts/verify.sh` 或 adapter 脚本负责机器验证。
- `scripts/repair_*.sh` 负责 agent repair policy。

## 标准工作流

一个 change 推荐按这个顺序跑：

```bash
pl init add-search --name "Add search" --domain product

# 1. 补 spec，明确范围
$EDITOR pl/changes/add-search/spec.md
pl run --change add-search --gate A0

# 2. 补 plan / taskdag
$EDITOR pl/changes/add-search/plan.md
$EDITOR pl/changes/add-search/taskdag.md
pl run --change add-search --gate B1

# 3. 执行实现，可以由人、Codex、Claude 或本地脚本完成
pl agent run \
  --change add-search \
  --task T03 \
  --executor local \
  --cmd "./scripts/agent-implement.sh" \
  --verify-gate D \
  --max-retries 1

# 4. 验证
pl run --change add-search --gate D --json
pl smoke --change add-search --json

# 5. 观察与归档
pl trace tree --change add-search
pl status add-search
```

## 接入 Codex CLI

如果本机有 Codex CLI，可以把 Codex 作为外部 coding agent 接入：

```bash
pl agent run \
  --change add-search \
  --task T03 \
  --executor codex-cli \
  --model codex-local-test \
  --prompt-path prompts/implement.md \
  --input-artifact pl/changes/add-search/spec.md \
  --input-artifact pl/changes/add-search/taskdag.md \
  --output-artifact app/search.py \
  --verify-gate D
```

默认会执行：

```bash
codex exec \
  --cd "$PL_PROJECT" \
  --sandbox workspace-write \
  --ask-for-approval never \
  -m "$MODEL" \
  - < "$PL_PROJECT/$PROMPT_PATH"
```

推荐 prompt 文件里包含：

```text
You are implementing task T03 for this project.

Read:
- pl/changes/add-search/spec.md
- pl/changes/add-search/plan.md
- pl/changes/add-search/taskdag.md

Modify only the files needed for T03.
Run or respect the verification command used by gate D.
Leave unrelated files unchanged.
```

如果要改 Codex 参数：

```bash
pl agent run \
  --change add-search \
  --task T03 \
  --executor codex-cli \
  --codex-sandbox workspace-write \
  --codex-approval never \
  --codex-arg "--json" \
  --prompt-path prompts/implement.md
```

先用内置 fake demo 验证控制面：

```bash
bash examples/demo-agent-codex-cli/run-demo.sh
```

## 配置 repair policy

稳定项目建议把修复策略放进 `pl/config.yaml`：

```yaml
agent:
  repair:
    max_retries: 1
    strategy:
      test_failure: "./scripts/repair_test_failure.sh"
      syntax_error: "./scripts/repair_syntax_error.sh"
      missing_file: "./scripts/repair_missing_file.sh"
      default: "./scripts/repair_default.sh"
```

这样 `pl agent run` 在 gate 失败后会按失败类型选择修复脚本。

repair 脚本会收到关键环境变量：

| Variable | Meaning |
|---|---|
| `PL_CHANGE` | change id |
| `PL_TASK_ID` | task id |
| `PL_RUN_ID` | agent run id |
| `PL_RUN_DIR` | 本次 agent run 目录 |
| `PL_FAILURE_KIND` | 失败分类 |
| `PL_REPAIR_CONTEXT` | 自动生成的 repair context 路径 |

可参考：

```bash
bash examples/demo-agent-loop/run-demo.sh
bash examples/demo-agent-crud-service/run-demo.sh
```

## 验证接入是否成功

新项目接入后至少跑：

```bash
pl status --self-check
pl status
```

如果使用 agent loop，再跑：

```bash
bash examples/demo-agent-loop/run-demo.sh
bash examples/demo-agent-codex-cli/run-demo.sh
```

如果是具体业务项目，建议补一个项目本地验证脚本：

```bash
mkdir -p scripts
$EDITOR scripts/verify.sh
chmod +x scripts/verify.sh
```

然后在 agent run 里绑定 gate：

```bash
pl agent run \
  --change add-search \
  --task T03 \
  --executor local \
  --cmd "./scripts/agent-implement.sh" \
  --verify-gate D \
  --repair-cmd "./scripts/repair_default.sh" \
  --max-retries 1
```

## 最小落地原则

第一次接入不要追求全功能。建议按这 4 步走：

1. 只接入 `pl/config.yaml` 和第一个 change。
2. 先让 `pl status --self-check` 通过。
3. 再把现有测试命令接成 gate 或 `scripts/verify.sh`。
4. 最后再接 `pl agent run`、repair policy、Codex CLI executor。

也就是说，先建立控制面，再扩大自动化范围。

## 常见问题

### `PL_PROJECT` 要不要设置？

建议设置：

```bash
export PL_PROJECT="$PWD"
```

没有设置时，很多命令会以当前目录推断项目根，但在脚本、CI、多模块项目里显式设置更稳。

### 新项目应该选 `bare` 还是具体 stack？

如果技术栈明确，优先选具体 stack。
如果项目结构特殊，先用 `bare`，再手动接 adapter 或自定义脚本。

### Codex CLI executor 是否要求真实 Codex 登录？

真实运行要求本机 Codex CLI 可用。
仓库内 demo 和测试使用 fake `codex`，只验证 PL 控制面协议，不依赖登录态。

### pl-pipeline 会不会覆盖我的文件？

`pl new --here` 设计成保守接入：已有源码、README、package.json、pyproject.toml 等不会被覆盖。已有 `.gitignore` 只追加规则。

### 什么时候使用 `pl agent run`？

当你希望一次 coding agent 执行被纳入控制面时使用。
如果只是手动开发，然后跑 gate，使用 `pl run --change <id> --gate D` 就够。

## 推荐新项目模板

新项目可以从这个骨架开始：

```text
pl/
  config.yaml
  changes/
    add-first-feature/
      .state.md
      spec.md
      plan.md
      taskdag.md
prompts/
  implement.md
scripts/
  verify.sh
  repair_default.sh
```

`prompts/implement.md` 负责约束 agent；`scripts/verify.sh` 负责机器判断；`scripts/repair_default.sh` 负责失败后的最小修复入口。三者配合后，一个新项目就具备了最小的全链路 AI Coding 闭环。
