# Roadmap

> 本文是 pl-pipeline 的**公开**路线图。我们只承诺"方向"和"粗粒度时点"，
> 具体能力可能提前到达或根据社区反馈调整。

---

## 当前版本

- **v1.10.0**（2026-04-24）：`pl detect` / `pl scan` 扫描已有项目给出建议，`pl new --here` 默认改为只读 dry-run（不再硬塞模板）
- **v1.9.x**（2026-04-24）：zero-friction 上手 — `install.sh` 一行装到 `~/.pl-pipeline`，`pl new my-app --stack <stack>` 10 秒起项目
- **v1.8.x**（2026-04-24）：`bin/pl` 统一 CLI 入口收口 34 个 scripts；自吃狗粮（agent/文档/CI 全切到 `pl xxx` 形式）；首批 29 个 CLI 单元测试
- **v1.7.x**（2026-04-24）：**CDC 双向闭环**（consumer-driven contracts）— `adapter.use` trace → `pl-contract-aggregate` 聚合 pact → `pl-contract-verify` 在 adapter PR 上拦 breaking → Dashboard 显示 pact 健康度 + drill-down → `pl-contract-query` 反查谁在用某 capability/skill
- **v1.6.x**（2026-04-24）：观察层"不可被绕过"硬约束 — trace 信封补 `change_id` + span 因果树 + active 时间统计代理 + adapter `provides.capabilities[]` 抽象层
- **v1.5.0**（2026-04-23）：Core Assets Migration · RELEASE 🎉 — 三层资产栈落地，11 资产完成脱敏迁移，新增 adapter-kotlin；0 硬耦合
- **v1.3.2**（2026-04-23）：Dashboard live reload 稳定版（SSE 实时推送 + per-subscriber snapshot 修复）
- **v0.1.0-mvp**（2026-04-21）：独立仓建立 + 三层架构 + 2 个 reference adapter + 2 个端到端 demo

> 📖 v1.5.0 发布说明：[`docs/milestones/2026-04-v1.5.0-release.md`](./docs/milestones/2026-04-v1.5.0-release.md)
> 📖 v1.7.0 CDC 闭环：[`docs/milestones/2026-04-v1.7.0-release.md`](./docs/milestones/2026-04-v1.7.0-release.md)
> 📖 v1.7 立项过程（为何从 Path H 改道 CDC）：[`docs/milestones/v1.7-cdc-emergence.md`](./docs/milestones/v1.7-cdc-emergence.md)
> 🗺 v1.6+ 原始规划（已部分被实际路径取代）：[`docs/milestones/v1.6-next-planning.md`](./docs/milestones/v1.6-next-planning.md)
> 📜 详细变更：[`CHANGELOG.md`](./CHANGELOG.md)

---

## 已完成阶段（2026-04 末）· 观察层从"能看"到"能用"

主线：**工具产出的数据本身开始成为价值载体**。

> ✅ **2026-04-23 v1.5 完成**：核心资产栈从 KuiklyPolyCity 完成迁移。
> ✅ **2026-04-24 v1.6→v1.10 一日完成**：CDC + CLI 收口 + zero-friction 安装 + detect。
> **原始规划**见 [`docs/milestones/v1.6-next-planning.md`](./docs/milestones/v1.6-next-planning.md)，
> **实际改道为何**见 [`docs/milestones/v1.7-cdc-emergence.md`](./docs/milestones/v1.7-cdc-emergence.md)。

| # | 里程碑 | 目标 | 状态 |
|---|--------|------|------|
| A | `v1.3.2` 转正 | dashboard 稳定版 tag | ✅ 已完成（pl-v1.3.2） |
| **v1.5** | **核心资产迁移** | spec-normalizer 等 11 个通用资产脱敏迁到独立仓 + 新 adapter-kotlin | ✅ 已完成（pl-v1.5.0） |
| — | 辩证方法论文档 | 让模糊需求在格式化工具里有容身之地 | ✅ `docs/guides/working-with-fuzzy-intent.md` |
| E' | 干净新需求跑一次完整 observe + dashboard | 产出真实 trace 作为后续分析的数据源 | ✅ 已完成（Pomodoro Timer v0.1） |
| **v1.6** | 观察层硬约束 | trace 信封 + 因果树 + active 时间代理 + adapter capabilities | ✅ 已完成（pl-v1.6.x） |
| **v1.7** | **CDC 双向闭环**（计划外 ⚠️） | adapter.use → aggregate pact → verify 拦 breaking → dashboard drill-down → query 反查 | ✅ 已完成（pl-v1.7.0~1.7.3.1） |
| **v1.8** | 统一 CLI + 自吃狗粮 + 测试 | `bin/pl` 收口 34 个脚本；agent/docs/CI 全切 `pl xxx`；29 个 CLI 单测 | ✅ 已完成（pl-v1.8.0~1.8.4） |
| **v1.9** | zero-friction 上手 | `install.sh` 一行装；`pl new --stack` 10 秒起项目 | ✅ 已完成（pl-v1.9.0~1.9.1） |
| **v1.10** | `pl detect` + `--here` 安全化 | 已有项目接入：先扫描后建议，不再硬塞模板 | ✅ 已完成（pl-v1.10.0） |
| F | 扩充 adapter 生态（android / kmp-kuikly / go） | 证明栈级 adapter 机制可复用 | 🟡 未做 |
| H | retro-miner 真实 trace 挖掘链路（B→C→D） | 闭合"观察-挖掘-反馈"飞轮 | 🟡 未做（被 v1.7 CDC 替代部分动机） |

### 与 v1.6 原始规划的差异

`v1.6-next-planning.md` 推荐序列是 `E' → H (retro-miner) → F (adapter) → G (CLI)`。
实际走的是 `E' → v1.6 观察硬约束 → v1.7 CDC → v1.8 CLI 收口 → v1.9 install → v1.10 detect`。

**对应关系**：
- Path G（CLI）→ 由 v1.8 `bin/pl`（**bash 实现**，符合"零依赖薄壳"非目标）+ v1.9 install.sh + v1.10 detect 完成
- Path H（retro-miner B→C→D）→ **未做**。当时的判断：retro-miner 在没有真实生产 trace 之前，挖出的 pattern 都是工具链自身噪音，**先建立"事实账本"（CDC pact）比"挖掘"更紧迫**。
- Path F（更多 adapter）→ 未做。等 KuiklyPolyCity 真正切到 adapter 模式后再决定 adapter 优先级（避免没真实需求驱动就发明 adapter）。

### E' 已完成 ✅

**场景**：新建 Next.js 番茄时钟 app（Pomodoro Timer v0.1），完整走完 proposal → plan → implement → verify → archive 六步。
**结论**：v1.5.0 核心资产栈通过全链路验证，3/5 目标达成。
**Retro**：[`docs/retros/v1.5-real-run/retro.md`](./docs/retros/v1.5-real-run/retro.md)

---

## v0.2 — 开箱即用 ✅ 已提前于 2026-04-24 通过 v1.8~v1.10 完成

原计划 Q3 2026，实际**用 bash 路线一日推完**（v1.8.0 起）。

| 类别 | 能力 | 状态 |
|---|---|---|
| 安装 | `curl ... \| install.sh` 一键装到 `~/.pl-pipeline` | ✅ v1.9.0 |
| CLI | `bin/pl` 统一入口（**bash 实现**，零 npm/pip 依赖） | ✅ v1.8.0 |
| CLI | `pl new <name> --stack <stack>` 起新项目（含骨架 + adapter + git init） | ✅ v1.9.0 |
| CLI | `pl detect` / `pl scan` 扫描已有项目 + 建议（替代旧的 `pl init --smart`） | ✅ v1.10.0 |
| CLI | `pl new --here --stack <stack>` 在已有项目内 inject pl 骨架 | ✅ v1.9.x |
| CLI | `pl adapter <id>` 装 adapter（替代 `bash scripts/adapter-install.sh ...`） | ✅ v1.8.0 |
| CLI | `pl doctor` 检查 `requires.tools` 依赖 | ✅ v1.8.0 |
| 脚本 | 所有 `bash scripts/*.sh` 保持存在并可用（作为 lower-level 接口） | ✅ |

> **关键决策回顾**：原计划 Path G 写的是"`npm install -g pl-pipeline`"。实际选择**完全
> 用 bash 实现**，理由：
> (1) 不引入 node 依赖，保持"macOS bash 3.2 / Linux 都能跑"的承诺；
> (2) 用户只需 `curl ... | bash` 一行；
> (3) 与既有 `scripts/*.sh` 路径同构，不存在"两套 CLI 语义不一致"的风险。
>
> Node.js 平行实验存放在 [`experiments/cli-nodejs/`](./experiments/cli-nodejs/)，
> **不进入安装链路、不打 pl-vX 风格 tag**（v2.0.0-alpha 教训详见
> [`experiments/README.md`](./experiments/README.md)）。

### v0.2 本体增强（retro-v2 驱动）

首次真实跑 demo 暴露 7 个 bug，**0 个被现有门禁抓到**。
v1 retro 误诊为"让 adapter 多声明字段"；v2 retro 纠正为"**pl/piao 本体缺通用抽象**"
（详见 [`docs/retros/2026-04-demo-first-run-retro-v2.md`](./docs/retros/2026-04-demo-first-run-retro-v2.md)）。

**判断标准**：如果一个能力要所有 adapter 各做一遍，它属于 pl/piao 本体。

#### pl-core 本体（v0.2 必做）

| 能力 | 现状问题 | 新抽象 | 状态 |
|---|---|---|---|
| **E1 可执行契约层** | `gate.criteria` 是散文；`gate.eval` 和 check 结果无闭环；`config.default.yaml` 硬编码 `gradle/ApiSelfCheck` | 引入 `GateDefinition / CheckDefinition` 数据模型，`eval_rule: "all_checks.pass"` 可机器求值；`pl-runner.sh` 统一驱动 | ✅ 已落地 `pl-v1.1.0-alpha` |
| **E2 SMOKE 阶段** | VERIFY 只管静态检查，不真启动；OBSERVE 只管线上观察；中间有缺口 | 把 SMOKE 抬为一等阶段（或 VERIFY 强制子阶段），定义 `smoke.{boot,ready,probe,shutdown}` 事件 | ✅ 已落地 `pl-v1.1.0-alpha` |
| **orchestrator 解耦** | `pipeline-orchestrator.sh` 硬编码 `agent:migration-*`（宿主名字）；`config.default.yaml` 硬编码宿主栈 | adapter 可注入 `stage_actor`；移除所有宿主特定字符串 | ✅ 已落地 `pl-v1.1.0-alpha` |
| **E3 rule-as-code**（v0.3 也可） | rule/skill 只是 AI prompt，不能 CI 跑 | rule frontmatter 声明 `engine + detect`，`pl-rule-scan.sh` 通用引擎消费 | ✅ 已落地 `pl-v1.1.2-alpha` |

#### piao-kernel 本体（v0.2 必做）

| 能力 | 现状问题 | 新抽象 | 状态 |
|---|---|---|---|
| **E4 契约-现实漂移** | 现在的 drift-compute 只比较 URN snapshot 前后差 | 新增 `piao-contract-drift-compute.sh`：declared contract（adapter.yaml.contract）vs actual（宿主实测 lockfile/filetree），产 `kind: ContractDrift` artifact + `piao.contract_drift.detected` 事件进 pl trace（piao↔pl 合流） | ✅ 已落地 `pl-v1.1.1-alpha` |

#### adapter 适配（次要 / 纯消费侧）

v0.2 的 adapter.yaml schema 从 `pl.dev/v1` → `pl.dev/v1.1`，新增字段：
- `build_adapter.smoke.{start_cmd,ready_url,probes}` — E2 消费 ✅
- `contract.expected_files[]` / `contract.peer_versions{}` / `contract.known_bad_combos[]` — E4 消费 ✅
- rule 文件 YAML frontmatter（`id` / `severity` / `scope` / `applies_to` / `detect[]` / `message` / `fix_hint`） + adapter.yaml `rules[].executable: true` — E3 消费 ✅

**注意**：adapter 只是 pl/piao 新抽象的**占位填充方**。能力增长的重心在 pl/piao 本体。

**v0.2 不做的事**：
- ❌ 不重写脚本为 TypeScript；CLI 是脚本的薄 wrapper
- ❌ 不引入后端服务 / telemetry（v0.x 完全离线）

---

## v0.3 — 多 IDE 一等公民（计划 Q4 2026）

目标：**"装 pl-pipeline" = 选一个 IDE，按钮点一下**。

| IDE | 集成形态 | 状态 |
|---|---|---|
| CodeBuddy | `.codebuddy/commands/pl/*.md`（9 个 slash command） | ✅ 已有 |
| Cursor | `.cursor/rules/pl.md` + MCP server | 🎯 目标 |
| Claude Code | `.claude/commands/pl-*.md` + MCP server | 🎯 目标 |
| Codex / AGENTS.md | `AGENTS.md` 片段自动生成 | 🎯 目标 |
| VSCode 原生 | VSCode extension（调度 MCP） | 🔵 可能 |

### MCP 服务器

`pl-pipeline-mcp` 将暴露三组 tool：

1. **状态查询**：`pl_status` / `pl_get_change` / `pl_list_changes`
2. **阶段推进**：`pl_advance` / `pl_check_gate`
3. **产物操作**：`pl_read_artifact` / `pl_write_artifact`

这让**任何支持 MCP 的 IDE** 都能无缝接入，而不需要给每个 IDE 写一遍 command。

---

## v1.0 — 社区 adapter 市场（计划 2027 H1）

目标：**选技术栈像装 brew package 一样直接**。

| 能力 | 说明 |
|---|---|
| Adapter Registry | 官方托管，`pl install-adapter rust-axum` 即可安装 |
| 官方 adapter 数量 | ≥ 10（覆盖主流 Web/后端/移动栈） |
| 社区 adapter | 开放投稿；自动化审查 + 社区投票 |
| Adapter 版本管理 | semver + `pl upgrade-adapter` |
| Adapter 冲突仲裁 | 多 adapter 共存机制（templates 层叠 + skills 命名空间） |

### 候选官方 adapter（按呼声排序）

1. adapter-nextjs-web（✅ 已有）
2. adapter-python-fastapi（✅ 已有）
3. adapter-rust-axum
4. adapter-go-gin
5. adapter-kotlin-kmp（提取自 KuiklyPolyCity 实战沉淀）
6. adapter-ios-swift
7. adapter-vue3-nuxt
8. adapter-django-drf
9. adapter-nodejs-nestjs
10. adapter-swift-vapor

---

## 长期主题（v1.x+）

### Pipeline-as-Code

让 pl-pipeline 的 6 阶段门禁**本身**可通过 adapter 扩展：

- 新增 `X` 门禁（如"设计稿 diff ≤ 5%"）
- 自定义阶段（如"灰度发布"）
- 阶段钩子（pre/post hook）

### 研发"飞轮"沉淀

每个走完 `ARCHIVE` 的 change 自动：
- 归纳新 pattern 进 adapter 对应 skill
- 发现的 rules 违反累加进 `lessons-learned.md`
- 组件复用率达阈值时推荐 "promote to shared"

### 跨仓 change 联动

同一 change 跨多个仓库（前端 + 后端 + 移动端）的**协同状态机**。

### 分布式 Dashboard

支持组织内多项目聚合视图（类 GitHub projects 但内嵌 pl 语义）。

---

## 非目标（永远不做）

- ❌ **不替代 AI IDE**：我们不是 Cursor / Copilot / Codex 的竞争对手，我们是"给它们的操作系统"
- ❌ **不变成 PMP 工具**：Jira / Linear 的职责保留给它们自己
- ❌ **不做商业 SaaS**：核心永远开源免费；未来若有企业付费版也不影响核心演进
- ❌ **不强耦合任何 LLM**：pl-pipeline 对 AI IDE 的需求只是"能读写 markdown 文件"
- ❌ **不重写核心为 Node.js / TypeScript / Python**：bash + python3 stdlib 是承诺。
  任何重写实验只能放 `experiments/`，不进 `install.sh` / `bin/pl` / 不打 `pl-vX` tag
  （v2.0.0-alpha 已被撤销，详见 [`experiments/README.md`](./experiments/README.md)）。

---

## 如何影响路线图

1. 在 [GitHub Issues](https://github.com/walkertop/pl-pipeline-standalone/issues) 发 "v0.2-feature-request" / "v1.0-adapter-wish"
2. 在 [Discussions](https://github.com/walkertop/pl-pipeline-standalone/discussions) 发"用例故事"
3. 写 adapter + PR（真实代码 > 纸面建议）

---

> 路线图每季度会公开 retro + 更新。查看 historical retro：`docs/retros/`（待建）。
