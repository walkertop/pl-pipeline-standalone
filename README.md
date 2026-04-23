# pl-pipeline

> **让 AI 编码不再是 "vibe coding"，而是可审计、可恢复、可验证的工程过程。**

<p align="center">
  <img alt="version" src="https://img.shields.io/badge/version-v1.2.0-blue">
  <img alt="stage" src="https://img.shields.io/badge/stage-stable-brightgreen">
  <img alt="license" src="https://img.shields.io/badge/license-Apache%202.0-blue">
  <img alt="retro" src="https://img.shields.io/badge/retro--v2-4%2F4%20closed-success">
  <a href="https://pl-pipeline.dev"><img alt="docs" src="https://img.shields.io/badge/docs-pl--pipeline.dev-black"></a>
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
| 需求模糊，AI 开始瞎猜 | 反复澄清 / 推倒重写 | `pl proposal` 结构化 Spec，A0 门禁强制澄清 |
| 任务太大，AI 丢上下文 | 分多次对话，记录分散 | `pl plan` 生成 TaskDAG，`.state.md` 记录进度 |
| AI 乱改文件或漏改 | 肉眼 diff review | TaskDAG 范围 + 黑名单 grep 自动验收 |
| 换个 AI/人接手，上下文全丢 | 重新讲一遍 | 读 `.state.md` + `spec.md` + `taskdag.md` 无缝续跑 |
| 写到一半发现需求错了 | 边改边乱 | `CORRECTIONS.md` 正式记录偏离 + 证据链 |
| 经验无法复用 | 散落文档 | ARCHIVE 阶段沉淀到 Rules/Skills，下次项目直接继承 |

**这不是"又一个 AI 编码工具"。这是给所有 AI 编码工具的"操作系统"**：
你用什么 AI IDE 都行（Claude Code / Cursor / Codex / CodeBuddy / 任何 MCP 兼容的工具），
pl-pipeline 负责让它们输出的代码**可审计、可恢复、可验证**。

---

## 30 秒上手（v1.2）

**当前稳定版：`pl-v1.2.0`（2026-04-22 · retro-v2 收官版）**。
形态：bash 脚本 + Python 协作库，无需 npm install，macOS bash 3.2 / Linux 都能跑。

```bash
# 1. 拉本仓库并锁版本
git clone https://github.com/walkertop/pl-pipeline-standalone
cd pl-pipeline-standalone
git checkout pl-v1.2.0
export PL_HOME="$PWD"

# 2. 接入一个已有项目（任何技术栈）
cd /path/to/your-project
bash $PL_HOME/scripts/adapter-install.sh $PL_HOME/adapters/adapter-nextjs-web .
#    ↑ 把 adapter 的 rules / agents / skills 拷到 .codebuddy/，写 .pl-adapter.yaml

# 3. 创建第一个变更
export PL_PROJECT="$PWD"
mkdir -p pl/changes/add-user-login
echo "# Spec: add user login" > pl/changes/add-user-login/spec.md
echo 'stage: SPEC' > pl/changes/add-user-login/.state.md

# 4. 跑状态 + 机器门禁（D = IMPLEMENT 验收门）
bash $PL_HOME/scripts/pl-status.sh --change add-user-login
bash $PL_HOME/scripts/pl-runner.sh --change add-user-login --gate D --json

# 5. 冒烟（真启动应用 + HTTP probe）
bash $PL_HOME/scripts/pl-smoke.sh --change add-user-login --json

# 6. 合规扫描（契约漂移 + rule-as-code）
bash $PL_HOME/scripts/piao-contract-drift-compute.sh --change add-user-login --json
bash $PL_HOME/scripts/pl-rule-scan.sh --change add-user-login --json

# 7. 看完整合流 trace（4 条通道在同一个 jsonl 里）
cat pipeline-output/trace/add-user-login.events.jsonl | jq -c '{phase, event}'
```

### 四件新工具（v1.2 核心能力）

| 脚本 | 作用 | 对应能力 | 产物 |
|---|---|---|---|
| `pl-runner.sh` | 按 check 结果自动派生 gate 通过/阻塞 | **E1** 可执行契约层 | `trace` 事件 `gate.eval` |
| `pl-smoke.sh` | boot 应用 → 轮询 ready → HTTP probe → 关停 | **E2** SMOKE 阶段 | `trace` 事件 `smoke.{boot,ready,probe,shutdown}` |
| `piao-contract-drift-compute.sh` | adapter 声明 vs 宿主实况 diff | **E4** 契约-现实漂移 | `drift/<change>-contract.yaml` |
| `pl-rule-scan.sh` | 消费 rule 的 YAML frontmatter 做 CI-grade linter | **E3** rule-as-code | `rule-scan/<change>.yaml` |

这 4 个脚本的事件都合流到 **同一条** `pipeline-output/trace/<change>.events.jsonl`，
piao ↔ pl 首次端到端合流，dashboard / CI 只需消费一个通道。

### 不想立刻用新能力？

**完全不用做任何事**。v1.2 对 v1.0 完全向后兼容：
- 不填 adapter.yaml 的 `smoke` / `contract` 段 → E2 / E4 自动 skip
- rule 不加 frontmatter → `pl-rule-scan.sh` 返回 "no executable rules"
- 原有 `pl-status.sh` / `pl-dashboard-refresh.sh` 入口和行为不变

从 v1.0 升级到 v1.2 见 [`MIGRATION.md`](./MIGRATION.md)，三步走，每一步都是 opt-in 增量。

### v2.0 愿景（未来体验）

```bash
npx pl-pipeline init --smart     # 自动扫描技术栈并推荐 adapter
pl proposal add-user-login       # 结构化 spec
pl plan add-user-login           # 自动拆 TaskDAG
pl implement add-user-login      # AI 按 DAG 编码
pl verify add-user-login         # 跑所有 5 道门禁
pl archive add-user-login        # 沉淀到 Rules/Skills
```

v2.0 是 TypeScript CLI + MCP Server 重写，v1.x 的 schema / 产物 / 门禁语义会保持兼容。
**现在用 v1.2 完全不浪费**。

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

### 🧠 Smart Init（零配置接入）

> 🚧 **v2.0 规划**（未实现）。当前 v1.2 手动接入见上面"30 秒上手"。

```bash
npx pl-pipeline init --smart   # v2.0 愿景命令

🔍 Scanning your project...
  ✓ Detected language: Kotlin (Multiplatform)
  ✓ Detected build tool: Gradle
  ✓ Detected test framework: JUnit

📦 Recommended preset: @pl/preset-kotlin-kmm
  Will install:
    • rules/kotlin-coding-standards.md
    • skills/kotlin-serialization.md
    • adapters/gradle.yaml

? Apply recommended preset? (Y/n)
```

支持的 Preset 技术栈（v1.2 已有 adapter）：
- **Next.js Web** (`adapter-nextjs-web`) ✅
- **Python FastAPI** (`adapter-python-fastapi`) ✅
- Kotlin KMM / Rust Cargo / Go Modules — v1.3+ 规划
- 社区贡献的迁移专用包如 `weex-to-kuikly` / `vue2-to-vue3` — v1.3+ 规划

### 🔌 多 IDE 适配（MCP First）

> 🚧 **v2.0 规划**（未实现）。当前 v1.2 通过 adapter 的 `rules/` / `agents/` / `skills/` 目录被任何读 `.codebuddy/` / `.cursor/` / `.claude/` 的 IDE 消费。

```bash
pl init --ide mcp          # v2.0 愿景：通过 MCP 协议适配所有兼容 IDE
pl init --ide cursor       # v2.0 愿景：生成 .cursor/rules/
pl init --ide claude-code  # v2.0 愿景：生成 .claude/commands/
pl init --ide codebuddy    # v2.0 愿景：生成 .codebuddy/commands/
pl init --ide codex        # v2.0 愿景：生成 AGENTS.md 片段
```

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
- **HTML 报告**：`pl report` 一键生成可视化报告
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

- 📖 [文档站](https://pl-pipeline.dev)
- 🎮 [在线 Playground](https://pl-pipeline.dev/playground)
- 🖼 [案例 Gallery](https://pl-pipeline.dev/gallery)
- 💬 [Discord 社区](https://discord.gg/pl-pipeline)
- 🐦 [Twitter / X](https://twitter.com/pl_pipeline)
- 📋 [Roadmap](https://github.com/your-org/pl-pipeline/projects)

---

## 现状

**pl-pipeline 目前处于 alpha 阶段**。

- ✅ 核心引擎已验证：在 Kotlin Multiplatform 大型迁移项目中完成 11/16 任务（4831 行代码、0 回归、全程可追溯）
- ✅ 6 阶段 + 7 门禁 + 7 产物契约稳定
- ✅ **三层架构已就位**（piao-kernel / pl-core / adapters）
- ✅ **首批 adapter 开放**（`adapter-nextjs-web` / `adapter-python-fastapi`）
- ✅ **adapter 脚手架可用**（`scripts/adapter-create.sh`）
- 🚧 多 IDE Adapter 正在开发
- 🚧 社区贡献的 adapter 生态建设中
- 🚧 文档站和 Playground 建设中

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
bash $PL_HOME/scripts/adapter-install.sh $PL_HOME/adapters/adapter-nextjs-web .
```

新建自己的 adapter：

```bash
bash $PL_HOME/scripts/adapter-create.sh my-stack --full
# → adapters/adapter-my-stack/ 骨架就绪，adapter-validate 自动通过
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
