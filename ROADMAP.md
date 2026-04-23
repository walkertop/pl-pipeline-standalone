# Roadmap

> 本文是 pl-pipeline 的**公开**路线图。我们只承诺"方向"和"粗粒度时点"，
> 具体能力可能提前到达或根据社区反馈调整。

---

## 当前版本

- **v1.3.2-alpha**（2026-04-23）：Dashboard live reload（SSE 实时推送 + 自动重连 + 静态降级）
- **v1.4.0-alpha**（2026-04-22）：retro-miner 四类离线 pattern 挖掘（频次/共现/反模式/异常）
- **v1.3.0-alpha**（2026-04-22）：Observe 层 MVP（event v1.3 schema + fs watcher + 规则引擎 + Dashboard 双视图）
- **v1.2.0**（2026-04-22）：retro-v2 收官版（E1~E4 闭环，4/4 通用抽象落地）
- **v0.1.0-mvp**（2026-04-21）：独立仓建立 + 三层架构 + 2 个 reference adapter + 2 个端到端 demo

---

## v0.2 — 开箱即用（计划 Q3 2026）

目标：**让"装 pl-pipeline"这件事 30 秒内完成**，不再需要手写路径 / export 变量。

| 类别 | 能力 | 状态 |
|---|---|---|
| 打包 | `npm install -g pl-pipeline` 全局 CLI | 📝 设计中 |
| CLI | `pl init` 在任意项目根下创建 `pl/` + `.codebuddy/` 骨架 | 📝 |
| CLI | `pl init --smart` 扫描 `package.json`/`pyproject.toml`/`Cargo.toml` 自动推荐 adapter | 📝 |
| CLI | `pl install-adapter <id>` 替代当前 `bash scripts/adapter-install.sh ...` | 📝 |
| CLI | `pl doctor` 检查 `requires.tools` 依赖是否齐全 | 📝 |
| 脚本 | 所有 `bash scripts/*.sh` 保持存在并可用（作为 lower-level 接口） | ✅ |

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

---

## 如何影响路线图

1. 在 [GitHub Issues](https://github.com/walkertop/pl-pipeline-standalone/issues) 发 "v0.2-feature-request" / "v1.0-adapter-wish"
2. 在 [Discussions](https://github.com/walkertop/pl-pipeline-standalone/discussions) 发"用例故事"
3. 写 adapter + PR（真实代码 > 纸面建议）

---

> 路线图每季度会公开 retro + 更新。查看 historical retro：`docs/retros/`（待建）。
