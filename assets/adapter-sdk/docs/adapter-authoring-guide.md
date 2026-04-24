# Adapter Authoring Guide

> 本文档教你从零写一个 pl-pipeline adapter。目标受众：想把 pl-pipeline 带到
> 新技术栈（Rust / iOS / Django / ...）的贡献者。

---

## 0. 阅读本文之前

确保你已经读过：

1. [`docs/THREE_LAYERS.md`](../../../docs/THREE_LAYERS.md) —— 三层架构总览
2. [`CONTRIBUTING.md`](../../../CONTRIBUTING.md) —— 工作守则 + commit 规范
3. 至少一份现成的 adapter 示例（推荐 `adapters/adapter-nextjs-web/` 或
   `adapters/adapter-python-fastapi/`）

> Adapter 不是"配置文件"，而是一个**自带一套完整研发资产的扩展包**。
> 做一个合格的 adapter，意味着你要把自己在这个技术栈的**最佳实践**以
> agents / skills / rules / templates / scripts 五种载体沉淀下来。

---

## 1. 什么场景需要写一个新 Adapter

满足以下**任一**条件，建议写新 adapter：

- 现有 adapter 都不匹配你的技术栈（例如你用 Rust + Axum + SQLx）
- 现有 adapter 匹配但**示例和场景词不对**（例如把 adapter-nextjs-web 当
  Remix 用可能别扭）
- 你在做一次**迁移类**工作（如 Vue2→Vue3 / jQuery→React），想把踩坑经
  验沉淀成可复用的迁移 adapter

不必写新 adapter 的情况：
- 已有 adapter 90% 契合，只需要加 1-2 条 skill → 直接 PR 到该 adapter 即可
- 项目技术栈是 Next.js + Tailwind → 用 adapter-nextjs-web，Tailwind 相关
  skill 作为 enhancement 贡献回来

---

## 2. Adapter 的最小骨架

```
adapters/adapter-<id>/
├── adapter.yaml          ← Manifest（必须，详见 manifest-reference.md）
├── README.md             ← 用户入口（"什么场景用，怎么用"）
├── templates/            ← 必填至少 spec.md / plan.md / taskdag.md 三件
│   ├── spec.md
│   ├── plan.md
│   └── taskdag.md
├── agents/               ← 必填至少 1 个
│   └── <id>-architect.md
├── skills/               ← 必填至少 1 个
│   └── <topic>-patterns.md
├── rules/                ← 必填至少 1 个
│   └── <lang>-coding-standards.md
├── scripts/              ← 必填 verify.sh；其他可选
│   └── verify.sh
└── docs/
    └── case-study.md     ← 用一个 demo 项目跑一遍完整流程
```

---

## 3. 逐文件实战指引

### 3.1 adapter.yaml

用文本编辑器从 `assets/adapter-sdk/template/adapter.yaml.hbs` 拷贝一份，
填充字段。关键字段：

```yaml
apiVersion: pl.dev/v1
kind: Adapter
metadata:
  id: rust-axum                     # 机器 ID, kebab-case
  name: Rust + Axum 后端项目        # 人类可读
  version: 0.1.0                    # adapter 自己的 semver
  compatible_pl: ">=1.0.0 <2.0.0"   # pl-core 版本约束
  compatible_piao: ">=0.1.0"
  detect:
    - file_exists: "Cargo.toml"
    - cargo_has: "axum"

provides:
  templates:
    spec: "templates/spec.md"
    plan: "templates/plan.md"
    taskdag: "templates/taskdag.md"
  agents:
    - path: "agents/rust-axum-architect.md"
  skills:
    - id: axum-patterns
      path: "skills/axum-patterns.md"
      triggers: ["axum", "tower", "tonic"]
  rules:
    - path: "rules/rust-api-design.md"
      scope: "always"
  scripts:
    verify: "scripts/verify.sh"
    lint:   "scripts/lint.sh"
  build_adapter:
    type: cargo
    commands:
      compile_check:
        cmd: "cargo check"
        success_pattern: "Finished"
        timeout_sec: 300
      test: "cargo test"
      lint: "cargo clippy -- -D warnings"

requires:
  tools:
    - name: cargo
      min_version: "1.70"
      install_hint: "https://rustup.rs"

piao_emit:
  on_stages: [VERIFY, ARCHIVE]
  urn_namespace: "urn:piao:artifact:pl:rust-axum"
```

**字段语义**：[`manifest-reference.md`](./manifest-reference.md) 详述每个字段。

### 3.2 templates/

这里放的是**这个技术栈下，SPEC / PLAN / TASKDAG 应该长什么样**。

- **不是**复制 pl-core 的通用模板然后做微调
- **而是**以 pl-core 的通用模板为骨架，把示例部分换成**这个场景下最典
  型的示例**

例如：
- pl-core 通用 `spec.md` 的"用户入口"字段示例是 `订单列表 → 点击卡片`
- adapter-nextjs-web 的 `spec.md` 可以改为 `/dashboard 页面 → URL hash 进入`
- adapter-python-fastapi 的 `spec.md` 可以改为 `POST /api/v1/users 接口 → 客户端调用`

### 3.3 agents/

AI 专家 prompt。每个 agent 是一个 `.md` 文件，内容是**给 AI 看的指令**。

**推荐最小 agent 集（3 个）**：

1. `<id>-architect.md` —— 技术栈架构师（SPEC / PLAN 阶段使用）
2. `<id>-reviewer.md` —— 代码审查员（IMPLEMENT / VERIFY 阶段使用）
3. `<id>-debugger.md` —— 疑难问题排查专家（VERIFY / OBSERVE 阶段使用）

Agent 文件格式（简化版）：

```markdown
---
agent_id: rust-axum-architect
stages: [SPEC, PLAN]
role: 技术栈架构师
---

# Rust Axum 架构师

你是一位资深的 Rust + Axum 后端架构师。当用户在 pl-pipeline SPEC 或
PLAN 阶段请求帮助时，你应当：

## 思考优先级
1. 借用检查（borrow checker）早期暴露
2. 异步运行时选择（tokio / async-std / smol）
3. Router 模块化切分...

## 典型问题决策树
- 需要分享状态？→ Arc<Mutex<T>> vs State<T> 讨论
- 需要中间件？→ tower::Service 还是 axum::middleware::from_fn？
...

## 禁止行为
- 不要推荐 tokio::spawn 不 await 的 detached 用法，除非 change 明确说
  接受 fire-and-forget
...
```

### 3.4 skills/

技能文件，记录**针对性的最佳实践 + 代码示例**。

每个 skill 应当是**单主题**的、**可独立阅读**的，包含：

1. 何时使用这个 skill（触发条件）
2. 最佳实践要点（bullet points）
3. 可运行的代码示例（至少 1 段）
4. 常见误区 + 解决方案

例子：见 `adapters/adapter-nextjs-web/skills/react-server-components.md`

### 3.5 rules/

编码规范。两种 scope：

- `always`：总是加载（如变量命名、导入顺序等普适规则）
- `on-demand`：按需加载（如"编写 async 函数时"、"使用 SQL 时"）

Rules 和 skills 的区别：
- **Rules** 是**约束**（DON'T / MUST / SHOULD），违反就是代码问题
- **Skills** 是**知识**（HOW-TO），学习和参考用

### 3.6 scripts/

至少写一个 `verify.sh`。最小骨架：

```bash
#!/usr/bin/env bash
set -euo pipefail

# adapter-<id>/scripts/verify.sh
# 职责：在 VERIFY 阶段执行 compile + test + lint 三件套

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${PL_PROJECT:-$PWD}"

echo "▶️ Compile check..."
<compile command e.g. `cargo check`> || { echo "❌ compile failed"; exit 1; }

echo "▶️ Tests..."
<test command e.g. `cargo test`> || { echo "❌ tests failed"; exit 1; }

echo "▶️ Lint..."
<lint command e.g. `cargo clippy -- -D warnings`> || { echo "❌ lint failed"; exit 1; }

echo "✅ verify passed"
```

### 3.7 docs/case-study.md

一份用**真实 demo 项目**跑一次 proposal→archive 的完整故事。写它的价值：

1. 让审阅者确认这个 adapter 真的跑得通
2. 让后续用户一眼看到"用我这个 adapter 时该如何操作"
3. 作为 e2e 回归测试的 baseline

建议结构：

```markdown
# Case Study: <场景名>

## 目标项目
- 技术栈: ...
- 规模: ...
- 演示代码位置: examples/demo-<name>/ （本仓库内）

## Change ID
add-dark-mode / refactor-auth-layer / ...

## 走完全流程的时间线

| 阶段 | 耗时 | 关键观察 |
|---|---|---|
| SPEC | 15 min | ... |
| PLAN | 20 min | ... |
| ...  |  ...   | ... |
```

---

## 4. 开发流程（推荐）

1. **scaffold**：`bash scripts/adapter-create.sh <id>` 生成骨架
2. **fill manifest**：照着 manifest-reference.md 填 adapter.yaml
3. **validate once**：`bash scripts/adapter-validate.sh adapters/adapter-<id>`
4. **write content**：从 agents → skills → rules → templates 顺序写
5. **validate again**：每次修改后都跑 adapter-validate.sh
6. **local demo**：在 `examples/demo-<id>/` 里用 adapter-install 装一次 + 跑通流程
7. **commit with phase tag**：`feat(adapter-<id>): initial implementation`

---

## 5. 提交新 adapter 到独立仓

MVP 阶段（v0.1）由维护者手工评审。建议 PR checklist：

- [ ] adapter-validate.sh 通过
- [ ] 至少 1 个 agent / 1 个 skill / 1 个 rule / 1 个 verify.sh
- [ ] case-study.md 有真实 demo 项目链接（推荐放 examples/）
- [ ] 该技术栈的知名开源项目或成熟框架（不接受"小众私有 DSL"）
- [ ] 通过 `piao-kernel-wordcheck --ci` 扫描（用户项目内的 agent/skill
      可以用场景词；manifest 里**禁止**出现其他 adapter 的场景词）

---

## 6. 反例：什么 adapter 不会被接受

| 反例 | 为什么 |
|---|---|
| 只有 adapter.yaml，没有任何 skills/agents/rules | 不是"全家桶"，等同于只声明没提供 |
| adapter.yaml 里 id="my-team-internal-dsl" | 非通用技术栈 |
| skills 里引用 pl-core 的 skills（`See pl-core/skills/spec-normalizer.md`）但自己一个都不写 | 偷懒，没有沉淀 |
| case-study.md 里写"假设你有一个 React 项目..."但没真实 demo | 无证据 |
| scripts/verify.sh 里硬编码路径（`/Users/xxx/...`） | 违反 pl-pipeline 通用性底线 |

---

## 7. 进阶：如何让 adapter 参与 piao 演化

当 adapter 成熟后，可以在 adapter.yaml 里启用 `piao_emit`：

```yaml
piao_emit:
  on_stages: [VERIFY, ARCHIVE]
  urn_namespace: "urn:piao:artifact:pl:rust-axum"
```

这样 pl-core 在 VERIFY / ARCHIVE 阶段会往 piao 的 kernel-events 写
`artifact.published` 事件。后续这些事件可被 `piao-drift-compute` / 
`piao-evolution-scan` 消费，让你的 adapter 也能"从错误中学习"。

详见 [`docs/THREE_LAYERS.md §5.1`](../../../docs/THREE_LAYERS.md)。

---

## 8. 文档索引

- [`manifest-reference.md`](./manifest-reference.md) — adapter.yaml 字段字典
- [`injection-contract.md`](./injection-contract.md) — adapter 资产注入到宿主项目的规则
- 现成示例：`adapters/adapter-nextjs-web/` / `adapters/adapter-python-fastapi/`
- 脚手架：`bash scripts/adapter-create.sh <id>`
- 校验：`bash scripts/adapter-validate.sh adapters/adapter-<id>`

---

## 最后一句话

> Adapter 是 pl-pipeline 的"场景翻译官"。写好一个 adapter，意味着你把这个
> 技术栈下"**做得住**"的经验沉淀给了后面所有使用者。

---

## 附录 A：v0.1 后更新过的能力

下面是 v0.1 首版之后陆续到位的 adapter 生态基础设施。写 adapter 时可以
直接使用：

### A.1 `scripts/adapter-create.sh` 脚手架

一条命令生成合规骨架，省去手动拷贝现成 adapter 再改的麻烦：

```bash
# 最小骨架（只含 templates 和占位 adapter.yaml）
pl adapter create my-stack

# 完整骨架（含 agents/skills/rules/scripts 占位文件，adapter.yaml 的
# provides 全部启用）
pl adapter create my-stack --full

# 强制覆盖已存在目录
pl adapter create my-stack --full --force

# 自定义输出位置
pl adapter create my-stack --dest /tmp/sandbox
```

自检：脚手架生成后会**自动调用** `adapter-validate.sh` 做一次静态检查。
合法骨架返回 0，你就可以开始填内容了。

### A.2 参考现成样例

当前独立仓内的 2 个 reference adapter 是最好的教材：

| Adapter | 侧重 | 路径 |
|---|---|---|
| `adapter-nextjs-web` | React / Next.js App Router / RSC / TypeScript | `adapters/adapter-nextjs-web/` |
| `adapter-python-fastapi` | FastAPI / Pydantic v2 / SQLAlchemy 2.x async | `adapters/adapter-python-fastapi/` |

每个 adapter 内部都有：
- 完整的 `adapter.yaml`（可直接复制作为起点）
- 2 个 agent（architect + reviewer）
- 4 个 skill
- 3 条 rule
- 3 个 script（build / verify / lint）
- `docs/case-study.md`

### A.3 端到端 demo

两份 demo 位于 `examples/`：

| Demo | Adapter | 文件数 | 可复现步骤 |
|---|---|---|---|
| `examples/demo-nextjs-todo` | `adapter-nextjs-web` | 34 | 见 demo `README.md` |
| `examples/demo-fastapi-users` | `adapter-python-fastapi` | 49 | 见 demo `README.md` |

这些 demo 是**真实**跑过 `/pl:proposal → /pl:archive` 五阶段的产物，
`pl-status.sh` 能识别 `ARCHIVE` 阶段、全任务完成。

**写新 adapter 时，建议在 `examples/demo-<id>-<name>/` 配套提供一个 demo**，
这样审阅和回归都有基线。

---

## 附录 B：CI 集成建议

本仓的 `.github/workflows/ci.yml` 已包含 **adapter matrix 校验** job：

```yaml
adapter-matrix:
  strategy:
    matrix:
      adapter:
        - adapter-nextjs-web
        - adapter-python-fastapi
        # ← 新 adapter 加到这里
  steps:
    - bash scripts/adapter-validate.sh adapters/${{ matrix.adapter }}
    - bash scripts/adapter-install.sh --dry-run adapters/${{ matrix.adapter }} /tmp/ci-host
```

新 adapter 合入时**记得 append 自己到 matrix**，否则不会被 CI 覆盖。

---

## 附录 C：反馈链路

写完 adapter 后的协作流程：

1. **自检**：`adapter-validate.sh` 通过、`adapter-install.sh --dry-run` 预览合理
2. **本地 demo**：在 `examples/demo-<id>-<case>/` 跑完整流水线
3. **PR**：按 `.github/PULL_REQUEST_TEMPLATE.md` 自检清单
4. **讨论**：复杂决策（如新增 manifest 字段）先开 [Discussion](https://github.com/walkertop/pl-pipeline-standalone/discussions)
5. **合入**：维护者 review + squash merge
6. **发版**：若 adapter 自身 semver 升级，附更新 CHANGELOG

出问题？先搜 [FAQ](../../../FAQ.md)，搜不到就开 [Issue](https://github.com/walkertop/pl-pipeline-standalone/issues/new/choose)
选 **📦 New Adapter Proposal** 或 **🐛 Bug Report** 模板。
