# pl CLI Reference (v1.12.0+)

> 单入口 `pl <subcmd>` 取代散落的 `bash $PL_HOME/scripts/*.sh`。
> dispatcher 0 业务逻辑，**所有 flag 透传给底层脚本**，老路径 100% 向后兼容。

## 安装 / 启用

**推荐姿势（v1.9.0 起，零手工 export）**：

```bash
curl -fsSL https://raw.githubusercontent.com/walkertop/pl-pipeline-standalone/main/install.sh | bash
source ~/.zshrc            # 或 ~/.bashrc
pl --version               # → pl-pipeline ≥ 1.10.0
pl doctor                  # 自检 python3 / jq / yq / 路径
```

**手动姿势（继续可用，CI 友好）**：

```bash
export PL_HOME="/path/to/pl-pipeline-standalone"
export PATH="$PL_HOME/bin:$PATH"
pl --version
pl doctor
```

> `pl` 命令必须能找到正确的 `$PL_HOME`，dispatcher 默认从 `bin/` 上溯一级。
> 多版本并存（项目锁版本）见 [README §多版本并存](../README.md#多版本并存进阶)。

---

## 子命令总览（与底层脚本的映射）

### 元命令

| 子命令 | 底层 | 说明 |
|---|---|---|
| `pl --version` / `pl version` | — | 打印 pl-pipeline 版本 + `$PL_HOME` |
| `pl env` | `_env.sh::pl_env_dump` | 打印所有 `PL_*` 环境变量 |
| `pl doctor` | dispatcher 内置 | 自检 PATH / python3 / jq / yq / `$PL_HOME` |
| `pl help [<sub>]` | — | 主帮助 / 透传子命令 `--help` |

### 项目启动（v1.9 / v1.10）

| 子命令 | 底层 | 说明 |
|---|---|---|
| `pl detect` / `pl scan` | `pl-detect.sh` | **只读**扫描当前目录，识别栈 + 给接入建议（不写文件） |
| `pl new <name> --stack <s>` | `pl-new-project.sh` | 起新项目骨架（stack: `nextjs` / `fastapi` / `crawler` / `monorepo-trio` / `bare`） |
| `pl new <name> --here [--stack <s>]` | `pl-new-project.sh` | 在已有项目原地接入；不带 `--stack` 时默认 `pl detect` dry-run |

### 核心命令

| 子命令 | 底层 | 说明 |
|---|---|---|
| `pl init <change-id> [...]` | `pl-state-init.sh` | 创建 change 骨架（`.state.md` + 初始 `workflow.start` 事件） |
| `pl status [<change-id>]` | `pl-status.sh` | 状态总览 / 单 change 详情 / `--json` / `--self-check` |
| `pl run --change <id> --gate <g>` | `pl-runner.sh` | 统一 gate / check 执行器，`--dry-run` / `--json` |
| `pl agent run --change <id> --cmd <cmd>` | `pl-agent-run.sh` | Agent 执行闭环：命令 → gate → failure kind → repair policy/context → retry → trace |
| `pl phase <change-id> <action> ...` | `pl-phase.sh` | 手动推进阶段，自动写 trace + 更新 `.state.md` |
| `pl orchestrator --page <id>` | `pipeline-orchestrator.sh` | Agentic workflow 全流程编排 |
| `pl smoke --change <id>` | `pl-smoke.sh` | 端到端冒烟（boot → ready → probe → shutdown） |
| `pl dashboard [--open] [--port N]` | `pl-dashboard.sh` | 启动可视化面板（live SSE） |
| `pl dashboard refresh` | `pl-dashboard-refresh.sh` | 仅刷新 dashboard 数据，不起 server |

### 观测 / trace

| 子命令 | 底层 | 说明 |
|---|---|---|
| `pl observe --change <id>` | `pl-observe.sh` | fs watcher，发 `artifact.*` 事件 |
| `pl observe check --change <id>` | `pl-observe-check.sh` | quality_score / 缺口统计 |
| `pl trace use --change <id> --kind <k> --id <a>` | `trace-adapter-use.sh` | 记录 adapter 能力消费（CDC 事件源） |
| `pl trace tree --change <id>` | `pl-trace-tree.sh` | 事件树可视化 |
| `pl trace report --page <id> [--open]` | `trace-report.sh` | 生成 HTML 报告 |
| `pl active-time --change <id>` | `pl-active-time.sh` | 事件密度估算 active vs wall_clock |

### 契约 (CDC, v1.7+)

| 子命令 | 底层 | 说明 |
|---|---|---|
| `pl contract aggregate [--change <id>]` | `pl-contract-aggregate.sh` | 聚合 `adapter.use` 事件 → `consumer-pact.yaml` + `registry.yaml` |
| `pl contract verify [--change <id>] [--strict] [--json]` | `pl-contract-verify.sh` | 对账：satisfied / warn / broken |
| `pl contract query <flags>` | `pl-contract-query.sh` | 反查：谁在用某 capability/skill/rule/build_command |

### Adapter

| 子命令 | 底层 | 说明 |
|---|---|---|
| `pl adapter create <id> [--full]` | `adapter-create.sh` | 脚手架新 adapter |
| `pl adapter validate <dir>` | `adapter-validate.sh` | 校验 `adapter.yaml` 与目录结构 |
| `pl adapter install <adapter-dir> <project-dir>` | `adapter-install.sh` | 安装 adapter 到当前项目 |

### piao 系列（快照 / 内核演进）

| 子命令 | 底层 | 说明 |
|---|---|---|
| `pl piao snapshot-produce` | `piao-snapshot-produce.sh` | 抓取代码快照 |
| `pl piao snapshot-diff` | `piao-snapshot-diff.sh` | 比较快照差异 |
| `pl piao drift-compute --change <id>` | `piao-drift-compute.sh` | 计算漂移指标 |
| `pl piao contract-drift --change <id>` | `piao-contract-drift-compute.sh` | 契约-现实漂移指标 |
| `pl piao evolution-scan` | `piao-evolution-scan.sh` | 内核演进扫描 |
| `pl piao kernel-wordcheck` | `piao-kernel-wordcheck.sh` | 内核词表校验 |

### 工程辅助

| 子命令 | 底层 | 说明 |
|---|---|---|
| `pl retro-mine --sources ...` | `pl-retro-miner.sh` | 离线 trace 挖掘 → 候选规则 markdown |
| `pl rule-scan --change <id>` | `pl-rule-scan.sh` | rule-as-code 扫描 |
| `pl migrate-legacy` | `pl-migrate-legacy.sh` | 旧版结构迁移 |
| `pl should-build` | `should-build.sh` | 变更感知自动构建触发判断 |
| `pl setup-hooks` | `setup-hooks.sh` | 安装 git hooks |
| `pl log-error <type> <file> ...` | `log-error.sh` | 快速记录错误条目 |

---

## 设计约定

### 1. 透传一切

dispatcher 不解析 flag，子命令的所有参数原样转交底层脚本。
所以 `pl run --change foo --gate D --dry-run` 与 `bash $PL_HOME/scripts/pl-runner.sh --change foo --gate D --dry-run` **完全等价**。

### 2. 命名空间 vs 顶层映射

为避免顶层"56 个 flat 子命令"，按业务域归口：

- `pl contract <verb>`  ← 所有 CDC 相关
- `pl trace <verb>`     ← 所有 trace 写/读/报告
- `pl adapter <verb>`   ← adapter 生命周期
- `pl piao <verb>`      ← 快照 / 内核演进
- `pl dashboard [refresh]` ← dashboard 主/辅
- `pl observe [check]`     ← observer fs vs 校验
- `pl agent run`           ← agent/executor 执行闭环

其余直接 1:1 顶层暴露（`pl init / status / run / smoke / phase / ...`）。

### 3. 退出码语义

| 码 | 含义 |
|---|---|
| `0` | 子命令成功 |
| `1` | 子命令业务失败（透传） |
| `2` | dispatcher 报错（未知子命令 / 缺 verb）或子命令参数错误（透传） |
| `127` | 内部错误：底层脚本文件丢失 |

### 4. 不造伪命令

历史 README 写过 `pl proposal` / `pl plan` / `pl report` 等命令，**这些在 v1.8 之前**根本不存在，
v1.8 dispatcher 也**不会**为它们造伪入口（避免再次自我欺骗）。
现实映射：

| 文档中的旧词 | v1.8 真实做法 |
|---|---|
| `pl proposal <id>` | `pl init <id>` + 编辑 `spec.md` + `pl run --gate A0` |
| `pl plan <id>` | `pl run --change <id> --gate B1` |
| `pl implement <id>` | `pl run --change <id> --gate D` |
| `pl verify <id>` | `pl run --change <id> --gate E` + `pl smoke --change <id>` |
| `pl archive <id>` | `pl run --change <id> --gate G` + `pl retro-mine` |
| `pl report` | `pl trace report --page <id>` |

未来 v2.0 可能为这些"阶段语义糖"提供真入口；目前不做。

### 5. 与老脚本路径并存

仍可继续 `bash $PL_HOME/scripts/<x>.sh ...`。
CI、agent prompt、第三方文档无须立刻迁移。
新写的文档 / agent 推荐用 `pl <subcmd>` 形式（更短、更稳定的 API 表面）。

---

## 常见食谱

```bash
# 0) 全新项目从零到第一个 change（v1.9+）
pl new my-app --stack nextjs
cd my-app
export PL_PROJECT="$PWD"

# 0') 已有项目先 detect 再决定（v1.10+）
cd /your/existing/project
pl detect                                      # 只读扫描
pl new whatever --here --stack bare            # 拍板后再装

# 起一个 change 并跑到 IMPLEMENT 验收
pl init add-search --name "增加搜索" --domain ux
pl run --change add-search --gate B1
pl run --change add-search --gate D --json | jq

# CDC：聚合 + 对账 + 反查
pl contract aggregate
pl contract verify --strict
pl contract query --capability auth.session.read

# 看看 adapter 有谁在用
pl contract query --adapter adapter-nextjs-web --kind capability

# Agent execution loop MVP：执行、验收、失败后给 repair 命令上下文
pl agent run \
  --change add-search \
  --task T03 \
  --executor local \
  --provider openai \
  --model codex-local-test \
  --input-artifact pl/changes/add-search/taskdag.md \
  --output-artifact app/search.py \
  --cmd "./scripts/agent-implement.sh" \
  --verify-gate D \
  --repair-cmd "./scripts/agent-repair.sh" \
  --max-retries 1

# 或在 pl/config.yaml 写 agent.repair.strategy，让 pl 按 failure_kind 自动选 repair
bash examples/demo-agent-crud-service/run-demo.sh

# 一键 dashboard
pl dashboard --open --port 8889

# adapter 全流程
pl adapter create my-stack --full
pl adapter validate adapters/adapter-my-stack
pl adapter install adapters/adapter-my-stack /path/to/project

# 自检环境
pl doctor
pl env
```
