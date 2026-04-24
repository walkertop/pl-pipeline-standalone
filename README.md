# pl-pipeline

> **让 AI 编码不再是 "vibe coding"，而是可审计、可恢复、可验证的工程过程。**

<p align="center">
  <img alt="version" src="https://img.shields.io/badge/version-v1.9.0-blue">
  <img alt="stage" src="https://img.shields.io/badge/stage-stable-brightgreen">
  <img alt="license" src="https://img.shields.io/badge/license-Apache%202.0-blue">
  <img alt="retro" src="https://img.shields.io/badge/retro--v2-4%2F4%20closed-success">
  <a href="./docs/cli-reference.md"><img alt="docs" src="https://img.shields.io/badge/docs-cli--reference-black"></a>
</p>

---

## 这是什么？

**pl-pipeline** 是一个 **AI-First 研发操作系统**。

它不替你写代码，但它规定了 AI 和人一起写代码时的：

- **做什么顺序**（六阶段状态机 `SPEC → PLAN → IMPLEMENT → VERIFY → OBSERVE → ARCHIVE`）
- **走到哪算过关**（七道可机械校验的门禁 `A0 / B1 / C / D / E / F / G`）
- **产物长什么样**（7 件核心产物 + 3 件可选产物 + 5 份 JSON Schema 校验）
- **出错怎么回溯**（`.state.md` 真相源 + `CORRECTIONS.md` 纠正机制）
- **做完怎么沉淀**（ARCHIVE 阶段自动反哺 Rules/Skills，形成飞轮）

一句话：**Spec 定义"做什么" + Rules 约束"怎么做" + Skills 负责"做得快且稳" + pl-pipeline 保证"做得住且可交接"**。

---

## 为什么需要它？

当你让 AI 帮你写真实项目时，你会发现：

| 痛点 | 传统做法 | pl-pipeline |
|---|---|---|
| 需求模糊，AI 开始瞎猜 | 反复澄清 / 推倒重写 | `pl init <id>` 起一份结构化 Spec 骨架，A0 门禁强制澄清 |
| 任务太大，AI 丢上下文 | 分多次对话，记录分散 | `pl run --change <id> --gate B1` 拆解 TaskDAG，`.state.md` 记录进度 |
| AI 乱改文件或漏改 | 肉眼 diff review | TaskDAG 范围 + 黑名单 grep 自动验收 |
| 换个 AI/人接手，上下文全丢 | 重新讲一遍 | 读 `.state.md` + `spec.md` + `taskdag.md` 无缝续跑 |
| 写到一半发现需求错了 | 边改边乱 | `CORRECTIONS.md` 正式记录偏离 + 证据链 |
| 经验无法复用 | 散落文档 | ARCHIVE 阶段沉淀到 Rules/Skills，下次项目直接继承 |

**这不是"又一个 AI 编码工具"。这是给所有 AI 编码工具的"操作系统"**：
你用什么 AI IDE 都行（Claude Code / Cursor / Codex / CodeBuddy / 任何 MCP 兼容的工具），
pl-pipeline 负责让它们输出的代码**可审计、可恢复、可验证**。

---

## 30 秒上手（v1.9）

**当前稳定版：`pl-v1.9.0`（2026-04-24 · 一键安装 + `pl new`）**。
形态：bash 脚本 + Python 协作库，**零 npm/pip 依赖**，macOS bash 3.2 / Linux 都能跑。

### 第一步：装工具（30 秒）

```bash
# 一键装到 ~/.pl-pipeline 并自动写入 ~/.zshrc / ~/.bashrc
curl -fsSL https://raw.githubusercontent.com/walkertop/pl-pipeline-standalone/main/install.sh | bash

# 或不信任 curl|bash？git clone 后跑 install.sh 一样：
# git clone https://github.com/walkertop/pl-pipeline-standalone ~/.pl-pipeline
# bash ~/.pl-pipeline/install.sh

# 重启 shell 或 source 一下
source ~/.zshrc
pl --version           # 应输出 1.9.x
pl doctor              # 自检 python3 / jq / 路径
```

> 安装器幂等，可重复执行。环境变量见 `install.sh --help` 注释（`PL_INSTALL_PREFIX` / `PL_INSTALL_NO_RC` 等）。

### 第二步：起新项目（10 秒）

```bash
pl new my-app --stack nextjs           # 单 Next.js
pl new my-api --stack fastapi          # 单 FastAPI
pl new my-tool --stack crawler         # 爬虫 (无 adapter, 自带 build.yaml)
pl new my-saas --stack monorepo-trio   # 前端 + Python 服务端 + 爬虫 (一次到位)
pl new my-thing --stack bare           # 任意栈, 仅 pl-core 骨架
```

`pl new` 会自动完成：

- ✅ 建目录 / 拷 `pl/config.yaml`
- ✅ 装上对应 adapter（`.codebuddy/agents` `.codebuddy/skills` `.codebuddy/rules` 全套）
- ✅ `git init`
- ✅ 起首个 change（`pl/changes/add-first-feature/.state.md` 在位）
- ✅ 写好 `.gitignore` 和 `README.md`

### 第三步：开始干活

```bash
cd my-app
export PL_PROJECT="$PWD"               # 或装 direnv 自动管 (推荐)

pl status                              # 看所有 change
pl run --change add-first-feature --gate D --json    # 跑机器门禁
pl smoke --change add-first-feature --json           # 冷启动 + HTTP probe
pl dashboard --open                    # SSE 实时面板
```

> **多模块项目？** 用 `--stack monorepo-trio`，详细见 [`docs/guides/monorepo-quickstart.md`](./docs/guides/monorepo-quickstart.md)。
> **完整 CLI 清单**：`pl help` 或 [`docs/cli-reference.md`](./docs/cli-reference.md)。
> **不喜欢 `pl new`？** 老的"手动 cp config + adapter install"流程 100% 仍可用。

### 四件核心机器门禁（v1.2 起稳定）

| 命令 | 作用 | 对应能力 | 产物 |
|---|---|---|---|
| `pl run --gate D` | 按 check 结果自动派生 gate 通过/阻塞 | **E1** 可执行契约层 | `trace` 事件 `gate.eval` |
| `pl smoke` | boot 应用 → 轮询 ready → HTTP probe → 关停 | **E2** SMOKE 阶段 | `trace` 事件 `smoke.{boot,ready,probe,shutdown}` |
| `pl piao contract-drift` | adapter 声明 vs 宿主实况 diff | **E4** 契约-现实漂移 | `drift/<change>-contract.yaml` |
| `pl rule-scan` | 消费 rule 的 YAML frontmatter 做 CI-grade linter | **E3** rule-as-code | `rule-scan/<change>.yaml` |

事件都合流到 **同一条** `pipeline-output/trace/<change>.events.jsonl`，
dashboard / CI 只需消费一个通道。

### 后续 CDC 闭环（v1.7+）

| 命令 | 作用 |
|---|---|
| `pl trace use --change <id> --kind capability --id <c>` | 写消费事件（事实流） |
| `pl contract aggregate` | 聚合事实流 → 每个 change 的 consumer-pact.yaml |
| `pl contract verify [--strict]` | 对账 satisfied / warn / broken |
| `pl contract query --capability <c>` | 反查谁在用某能力（决策前事实查询） |

dashboard 首页有 pact 角标，详情页可下钻看 violation 源文件路径。

### 不想立刻用新能力？

**完全不用做任何事**。v1.8 对 v1.0 完全向后兼容：
- 不填 `adapter.yaml` 的 `smoke` / `contract` / `provides.capabilities` 段 → 对应 gate 自动 skip
- rule 不加 frontmatter → `pl rule-scan` 返回 "no executable rules"
- 老脚本路径 `bash $PL_HOME/scripts/<x>.sh ...` 全部继续工作

升级路径见 [`MIGRATION.md`](./MIGRATION.md)，每一步都是 opt-in 增量。

### v1.9+ 路线（未承诺）

v1.8 已经把"AI-First R&D 操作系统"的最小可用闭环交付完整：
**6 阶段 + 7 门禁 + 7 产物 + CDC 双向闭环 + 统一 CLI + 可视面板**。

下一步可能方向（按 issue 排优先级，**未承诺时间**）：

- 阶段语义糖：`pl proposal/plan/implement/verify/archive` 包装 `pl init + pl run --gate <X>`
- 多 IDE adapter：`pl init --ide cursor|claude-code|codex` 自动生成各 IDE 的提示词布局
- adapter 生态扩展：Go / Rust / Kotlin
- MCP Server：让任何 MCP 兼容 IDE 直连 pl-pipeline

社区贡献欢迎在本 repo 提 issue / PR 讨论。

---

## 核心特性

### 🎯 六阶段流水线

```
SPEC ──A0──▶ PLAN ──B1──▶ IMPLEMENT ──C/D──▶ VERIFY ──E──▶ OBSERVE ──F/G──▶ ARCHIVE
 定义什么      拆解方案      按图施工          质量把关      稳定运行         沉淀知识
```

每一步都有**明确产物** + **可机械校验的门禁**，不是靠感觉通过。

### 📄 契约化产物

每个变更 `pl/changes/<id>/` 下自动产出：

| 产物 | 阶段 | 说明 |
|---|---|---|
| `spec.md` | SPEC | What & Why |
| `plan.md` | PLAN | How（架构 / 风险 / 里程碑） |
| `taskdag.md` | PLAN | 任务依赖图 |
| `api.md` | PLAN | 接口契约 |
| `testmatrix.md` | PLAN/IMPL | 测试矩阵 |
| `deps.md` | SPEC/PLAN | 依赖分析 |
| `.state.md` | 全阶段 | **阶段真相源**（唯一 Source of Truth） |

### 🧰 已有 Adapter（v1.8 验证可用）

- **Next.js Web** (`adapter-nextjs-web`) — 已在 demo-nextjs-todo 跑通完整 CDC 闭环
- **Python FastAPI** (`adapter-python-fastapi`) — 已在 demo-fastapi-users 跑通完整 CDC 闭环
- **Kotlin Multiplatform** (`adapter-kotlin-kmm`) — 已具备 capabilities，未做大规模 dogfood

**未单列 adapter 的场景怎么办？**（爬虫 / Go / Rust / 任意冷门栈）
直接**裸跑 pl-core**——只要写 `pl/config.yaml` + `pl/adapters/build.yaml` 注入构建命令即可，
所有未声明的 gate 自动 skip，向后 100% 兼容。Python 类项目可手动 cherry-pick fastapi adapter 的通用 rule（`python-typing-strict.md` / `pytest-async.md`）享受规范化收益。

新 adapter 见 [`docs/guides/adapter-authoring.md`](./docs/guides/adapter-authoring.md)，
脚手架命令：`pl adapter create my-stack --full`。

> **多模块 monorepo 接入** → 见 [`docs/guides/monorepo-quickstart.md`](./docs/guides/monorepo-quickstart.md) +
> 可跑示例 [`examples/demo-monorepo-trio/`](./examples/demo-monorepo-trio/)（前端 + Python 服务端 + 爬虫三模块完整骨架）。

### 🔌 多 IDE 接入

v1.8 通过 adapter 的 `rules/` / `agents/` / `skills/` 资产被任何读
`.codebuddy/` / `.cursor/` / `.claude/` / `.codex/` 的 AI IDE 消费。
不需要专门的 MCP server——ARCHIVE 阶段沉淀的资产会被各 IDE 自动加载。

### 🏗️ 构建/测试适配层

pl-pipeline **不绑定任何构建工具**，通过 Adapter 协议适配：

```yaml
# pl/adapters/build.yaml
adapter: gradle           # 或 npm / cargo / go / make / custom
commands:
  compile:
    cmd: "./gradlew :shared:compileDebugKotlinAndroid"
    success_pattern: "BUILD SUCCESSFUL"
```

### 📊 可观测 & 可恢复

- **Trace JSONL**：每一步都结构化记录到 `pipeline-output/trace/<change>.events.jsonl`
- **HTML 报告**：`pl trace report --page <id>` 一键生成可视化报告
- **Dashboard**：Web 面板实时查看所有变更状态（SSE live reload）→ 使用手册：[`docs/dashboard-guide.md`](./docs/dashboard-guide.md)
- **断点续跑**：读 `.state.md` 就能从中断处继续，哪怕换了 AI、换了人

---

## 与其他工具的区别

| 工具 | 定位 | pl-pipeline 的差异 |
|---|---|---|
| **Cursor / Claude Code / Codex** | AI IDE（代码生成） | pl-pipeline 管流程，不管 IDE —— 它们是你的执行器 |
| **spec-kit / OpenSpec** | Spec 管理 | pl-pipeline 有完整的 6 阶段 + 7 门禁 + 可观测 + 可恢复 |
| **Plandex / Aider** | AI 代码助手 | pl-pipeline 聚焦"流程工程"，不是"编程助手" |
| **Jira / Linear** | 项目管理 | pl-pipeline 是**代码层**的可审计流程，产物就是代码仓的一部分 |

**最贴切的类比**：
- 如果 Cursor 是"发动机"，pl-pipeline 就是"变速箱 + ABS + 行车记录仪"。
- 发动机帮你走得快，pl-pipeline 让你走得稳、可追溯、可交接。

---

## 谁应该用它？

- ✅ **你在用 AI 写生产级代码**（不是 demo / 玩具项目）
- ✅ **你的项目需要多人协作或 AI/人协作**（交接成本高）
- ✅ **你的项目涉及大规模重构 / 迁移 / 新特性开发**
- ✅ **你厌倦了"AI 上一轮做了什么我完全想不起来"**

暂时不需要 pl-pipeline 的场景：
- ❌ 一次性脚本 / 50 行以下的小工具
- ❌ 探索性 notebook / 研究型代码

---

## 快速链接

- 📖 [CLI Reference](./docs/cli-reference.md)
- 📖 [Dashboard 使用指南](./docs/dashboard-guide.md)
- 📖 [Adapter 编写指南](./docs/guides/adapter-authoring.md)
- 🏗️ [Monorepo Quickstart](./docs/guides/monorepo-quickstart.md) — 多模块（前端+服务端+爬虫）从 0 到 1 接入
- 📋 [CHANGELOG](./CHANGELOG.md) — 所有版本变更
- 🐛 [Issues](https://github.com/walkertop/pl-pipeline-standalone/issues) — 反馈 / 讨论 / Roadmap

---

## 现状（v1.8.0 · 2026-04-24）

**pl-pipeline 已进入 stable，自吃狗粮中**。

- ✅ 6 阶段 + 7 门禁 + 7 产物契约稳定（v1.0 起）
- ✅ 三层架构（piao-kernel / pl-core / adapters）已就位（v1.5 起）
- ✅ 观测层从"事件流"升级为"契约系统"（v1.6 → v1.7）
- ✅ CDC 双向闭环：trace use → aggregate → verify → query → dashboard 角标 → drill-down（v1.7.0 → v1.7.3）
- ✅ 统一 CLI `pl <subcmd>` 收口 34 个脚本（v1.8.0）
- ✅ CI 全绿，已落地"打 tag 前 CI 必须绿"纪律（v1.7.3.1 教训）
- ✅ 已有 adapter：Next.js / FastAPI / Kotlin KMM（前两个完整 CDC dogfood）
- 🚧 v1.9+ 路线见 [Issues](https://github.com/walkertop/pl-pipeline-standalone/issues)，未承诺时间

### Adapter 全家桶

Adapter 是把"技术栈最佳实践"一键注入宿主项目的载体。每个 adapter 提供：

| 资产 | 作用 |
|---|---|
| **templates** | 覆盖 pl-core 默认的 spec/plan/taskdag，贴合场景字段 |
| **agents** | AI 架构师 / 审查员 prompt（RSC 决策、事务边界、OpenAPI 契约…） |
| **skills** | 技术栈知识库（RSC / Pydantic v2 / SQLAlchemy async…） |
| **rules** | 编码规范与硬性约束（TS 严格、Python 类型、FastAPI 约定…） |
| **scripts** | build / verify / lint 三件套 |
| **build_adapter** | 给 pl-core 的 `$PL_BUILD_CHECK_CMD` 注入正确的构建命令 |

一键安装：

```bash
# 在你的 Next.js 项目根目录
pl adapter install $PL_HOME/adapters/adapter-nextjs-web .
```

新建自己的 adapter：

```bash
pl adapter create my-stack --full
# → adapters/adapter-my-stack/ 骨架就绪，pl adapter validate 自动通过
```

---

## 贡献

我们欢迎以下贡献（按门槛从低到高）：

1. **分享案例**：你的 Spec/Plan/TaskDAG 写得漂亮？提交到 Gallery
2. **贡献 Preset**：把你的技术栈经验打包（`@pl/preset-your-stack`）
3. **改进模板**：`templates/*.md` 可以更好？PR 欢迎
4. **写 Adapter**：为新 IDE / 构建工具 / 可观测后端贡献适配器
5. **核心引擎**：需要先读 [ARCHITECTURE.md](./docs/ARCHITECTURE.md)

详见 [CONTRIBUTING.md](./CONTRIBUTING.md)。

---

## License

[Apache License 2.0](./LICENSE)

---

## 致谢

pl-pipeline 的设计灵感来自：
- [OpenSpec](https://github.com/scottschroder/openspec) —— Spec-driven 开发的早期探索
- [spec-kit](https://github.com/github/spec-kit) —— GitHub 官方的 Spec 工具箱
- [OpenTelemetry](https://opentelemetry.io/) —— 可观测协议设计范式
- [Conventional Commits](https://www.conventionalcommits.org/) —— 可机械解析的约定化契约
- 以及腾讯 `KuiklyPolyCity` 项目在实战中沉淀的工程经验

---

<p align="center">
  <sub>Built with ❤️ by developers tired of losing context.</sub>
</p>
