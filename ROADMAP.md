# Roadmap

> 本文是 pl-pipeline 的**公开**路线图。我们只承诺"方向"和"粗粒度时点"，
> 具体能力可能提前到达或根据社区反馈调整。

---

## 当前版本

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

### v0.2 门禁增强（based on 2026-04-21 retro）

首次真实跑 demo 暴露了 7 个 bug，**0 个被现有门禁抓到**（详见
[`docs/retros/2026-04-demo-first-run-retro.md`](./docs/retros/2026-04-demo-first-run-retro.md)）。
v0.2 重点是把 pl-pipeline 从"文档契约层"升级到"可执行契约层"：

| 优先级 | 脚本 | 作用 | 抓的 bug 类型 |
|---|---|---|---|
| **P0** | `pl-verify.sh` | 统一驱动 adapter 的 `build_adapter.commands.{compile,lint,test}` | 普通编译 / lint / 单元测试类 |
| **P0** | `pl-smoke.sh` + 扩展 `adapter.smoke` 字段 | 真启服务 + 打 probes | 运行时才暴露的依赖 / HMR 状态丢失 |
| **P1** | `pl-doctor.sh` | 读 `requires.{tools,files}` + 坏 combo 数据库 | 缺文件 / 缺 peer / 已知坏依赖 |
| **P1** | `pl-dep-lock.sh` + 扩展 `adapter.peer_versions` | 宿主 lockfile ↔ adapter 期望版本交叉验证 | 版本不兼容 |
| **P2** | `pl-code-scan.sh` + 规则 frontmatter detect 块 | rule 从 AI 提示 → CI 可执行 linter | 知识型违规 |
| **P3** | `piao-artifact-verify.sh` | demo 反向漂移校验 | 回归保护 |

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
