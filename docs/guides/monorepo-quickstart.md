# Monorepo Quickstart：在多模块新项目中接入 pl-pipeline

> **场景**：从 0 到 1 起一个新仓库，里面同时有
> **前端**（Next.js / React）+ **Python 服务端**（FastAPI / Django / Flask）+ **爬虫**（Scrapy / Playwright / 自研）
> 想让 pl-pipeline 同时管这三个模块，但又不想为爬虫重新写一个 adapter。
>
> **结论**：完全不用新 adapter。
> 三模块各自当独立 `PL_PROJECT`，前两个装现成 adapter，爬虫**复用** Python 通用规则或裸跑 pl-core。

---

## 0. 心智模型：什么是"宿主项目"

pl-pipeline 把任何包含以下结构的目录都当成一个独立"宿主项目"（Project Boundary）：

```
<host-project>/
  pl/
    config.yaml         ← 标记这是一个 pl-managed project
    changes/<id>/...    ← 每条变更的 spec/plan/taskdag/.state.md
  pipeline-output/      ← 该项目的 trace/observation/dashboard 数据
  .pl-adapter.yaml      ← 装了 adapter 才有
```

`PL_PROJECT` 环境变量指向这个目录。**`pl status` / `pl run` / `pl init` / `pl contract verify` 全部基于 `PL_PROJECT`**。

> 关键洞察：**`PL_PROJECT` 不必是 git 仓库根**。它可以是 monorepo 里的子目录。
> 这意味着一个 monorepo 可以同时托管 N 个独立 `PL_PROJECT`，每个走自己的 adapter / change / dashboard。

---

## 1. 推荐目录结构

```
my-saas/                          ← git repo 根
├── README.md
├── .gitignore
│
├── frontend/                     ← PL_PROJECT #1（Next.js）
│   ├── pl/
│   │   ├── config.yaml
│   │   └── changes/
│   ├── .codebuddy/               ← adapter-nextjs-web 注入的 agents/skills/rules
│   ├── .pl-adapter.yaml          ← adapter 安装清单
│   ├── pipeline-output/
│   ├── package.json
│   └── app/...
│
├── api/                          ← PL_PROJECT #2（Python FastAPI）
│   ├── pl/
│   │   ├── config.yaml
│   │   └── changes/
│   ├── .codebuddy/               ← adapter-python-fastapi 注入
│   ├── .pl-adapter.yaml
│   ├── pipeline-output/
│   ├── pyproject.toml
│   └── app/...
│
├── crawler/                      ← PL_PROJECT #3（爬虫，无 adapter）
│   ├── pl/
│   │   ├── config.yaml
│   │   └── adapters/
│   │       └── build.yaml        ← 自定义 build 命令（无完整 adapter）
│   │   └── changes/
│   ├── pipeline-output/
│   ├── pyproject.toml
│   └── crawler/...
│
└── pl-pipeline/                  ← submodule 或外部 clone（任选其一）
    └── ...                       ← 整个 pl-pipeline 工程
```

**为什么 `pl-pipeline/` 和业务模块平级？**
- 它是工具，不是业务代码——独立 clone / submodule / sparse-checkout 都行
- 所有命令都通过 `$PL_HOME/bin/pl` 入口分发，业务仓只放 `pl/` 数据

---

## 2. 一次性准备（30 秒）

### 2.1 安装 pl-pipeline 工具

```bash
curl -fsSL https://raw.githubusercontent.com/walkertop/pl-pipeline-standalone/main/install.sh | bash
source ~/.zshrc           # 或 ~/.bashrc

pl --version              # 验证 CLI 可用
pl doctor                 # 检查 python3 / jq / 依赖
```

> 安装到 `~/.pl-pipeline`，自动写 shell rc。详见 README "30 秒上手"。

### 2.2 一条命令起 monorepo 骨架（推荐）

```bash
cd ~/repos
pl new my-saas --stack monorepo-trio
```

完成后你会得到（已 `git init`、各子模块 adapter 已装、各起首个 change）：

```
my-saas/
├── frontend/    Next.js + adapter-nextjs-web 全套 + add-first-feature change
├── api/         FastAPI + adapter-python-fastapi 全套 + add-first-feature change
└── crawler/     Scrapy 风格 + 自定义 build.yaml + add-first-feature change
```

### 2.2 (alt) 手工法（理解每一步在做什么）

如果你想理解"每一步是什么"，用手工法：

```bash
mkdir -p ~/repos/my-saas/{frontend,api,crawler}
cd ~/repos/my-saas
git init
echo "# my-saas" > README.md

# 三个模块的最小骨架（你后面会用 AI 写真实代码）
mkdir -p frontend/app api/app crawler/spiders
touch frontend/package.json api/pyproject.toml crawler/pyproject.toml
```

后续 §3 描述的内容是手工法的详细步骤；用 `pl new --stack monorepo-trio` 已经全部自动化。

---

## 3. 给三个模块分别装上 pl-pipeline

### 3.1 frontend → adapter-nextjs-web

```bash
cd ~/repos/my-saas/frontend

# 1. 创建 pl/ 骨架
mkdir -p pl/changes pl/adapters
cp $PL_HOME/assets/pl/config.default.yaml pl/config.yaml

# 2. 装 adapter（agents/skills/rules 进 .codebuddy/，build.yaml 自动写好）
export PL_PROJECT="$PWD"
pl adapter install $PL_HOME/adapters/adapter-nextjs-web .

# 3. 验证
ls .codebuddy/{agents,skills,rules} | head
cat .pl-adapter.yaml | head -15

# 4. 第一条 change：试 init + status
pl init add-todo-list --name "添加待办列表页" --domain ui
pl status add-todo-list
```

### 3.2 api → adapter-python-fastapi

```bash
cd ~/repos/my-saas/api

mkdir -p pl/changes pl/adapters
cp $PL_HOME/assets/pl/config.default.yaml pl/config.yaml

export PL_PROJECT="$PWD"
pl adapter install $PL_HOME/adapters/adapter-python-fastapi .

pl init expose-todos-api --name "暴露 /todos REST" --domain api
pl status expose-todos-api
```

### 3.3 crawler → 不装 adapter，裸跑 pl-core

爬虫这种"无 web 路由、无 RSC、用 Scrapy/Playwright"的场景，
**强行套 fastapi/nextjs adapter 反而引入噪音**。pl-pipeline 的设计允许你**只用 pl-core**，
通过 `pl/adapters/build.yaml` 注入自己的构建命令即可。

```bash
cd ~/repos/my-saas/crawler

mkdir -p pl/changes pl/adapters
cp $PL_HOME/assets/pl/config.default.yaml pl/config.yaml

# 自己写 build.yaml（替代 adapter 提供的 build_adapter 段）
cat > pl/adapters/build.yaml <<'YAML'
adapter: custom
commands:
  compile_check:
    cmd: "python -m py_compile $(find crawler -name '*.py' | tr '\n' ' ')"
    success_pattern: "^$"
  lint:
    cmd: "ruff check crawler/"
  test:
    cmd: "pytest -q tests/"
YAML

# 通过环境变量供 should-build / pl run 消费
export PL_PROJECT="$PWD"
export PL_BUILD_CHECK_CMD="python -m py_compile $(find crawler -name '*.py' | tr '\n' ' ')"
export PL_LINT_CMD="ruff check crawler/"
export PL_TEST_CMD="pytest -q tests/"

pl init crawl-product-prices --name "爬取竞品价格" --domain data
pl status crawl-product-prices
```

> **可选增强**：如果你确实想要 Python 通用规则（typing-strict / pytest-async / pydantic-v2），
> 可以**只挑 fastapi adapter 里通用的部分**手动 cp 过来：
> ```bash
> cp $PL_HOME/adapters/adapter-python-fastapi/rules/python-typing-strict.md \
>    crawler/.codebuddy/rules/
> cp $PL_HOME/adapters/adapter-python-fastapi/skills/{pytest-async,pydantic-v2-patterns}.md \
>    crawler/.codebuddy/skills/
> ```
> 这样既享受了 Python 规范，又没拖入 FastAPI 专属 rule。

---

## 4. 日常工作流：在 monorepo 里切模块

每个 shell 会话只服务一个模块，靠 `PL_PROJECT` 区分：

```bash
# 早上做前端
export PL_PROJECT=~/repos/my-saas/frontend
pl status                          # 看 frontend 所有 change
pl run --change add-todo-list --gate D --json

# 下午切到后端
export PL_PROJECT=~/repos/my-saas/api
pl status
pl run --change expose-todos-api --gate D --json

# 晚上爬虫
export PL_PROJECT=~/repos/my-saas/crawler
pl status
pl run --change crawl-product-prices --gate D --json
```

**Tips：用 direnv 自动切换**

每个模块根放一个 `.envrc`：

```bash
# my-saas/frontend/.envrc
export PL_PROJECT="$PWD"
export PATH="$HOME/repos/pl-pipeline-standalone/bin:$PATH"
```

`cd frontend/` 自动激活，再也不会忘 export。

---

## 5. 跨模块协作的 change（关键问题）

**典型场景**："添加用户登录"涉及 frontend 改登录页 + api 加 `/auth/login` + crawler 不变。

pl-pipeline **不强制** 把跨模块需求塞进一个 change。推荐做法：

### 方案 A（推荐）：每个模块各起一个 change，命名上呼应

```
frontend/pl/changes/2026-04-25-add-user-login/    spec.md plan.md taskdag.md .state.md
api/pl/changes/2026-04-25-add-user-login/         spec.md plan.md taskdag.md .state.md
```

- 每个模块独立 gate / smoke / contract verify，互不阻塞
- spec.md 里互相引用对方路径："对应 api 侧 change：`api/pl/changes/2026-04-25-add-user-login/`"
- 用同一个日期前缀，`pl status` 一眼能看出关系

### 方案 B（小改动）：只在主模块起 change，从模块通过 task 引用

例如改动 90% 在 api 侧，frontend 只是改个 fetch URL：
- 在 `api/pl/changes/<id>/` 起 change
- 在 `taskdag.md` 里加一个 task "更新 frontend fetch URL"，让 AI 跨目录改文件即可

### 方案 C（重改）：升级到 cross-project change（v1.9 路线，未实装）

未来路线图里有 `pl link` / cross-project drift verify，但 v1.8.x **不要等**——方案 A 已经够用。

---

## 6. CDC（Consumer-Driven Contracts）在 monorepo 怎么用

CDC 是 v1.7 引入的"adapter 提供 → 消费方真实使用"对账机制。在 monorepo 下：

- **每个模块独立做 CDC**：消费事件写在各自 `pipeline-output/observations/`
- **聚合**：在每个模块单独跑 `pl contract aggregate` + `pl contract verify`
- **dashboard**：每个模块各开一个 `pl dashboard --port <unique>`

```bash
# 在 api/ 下
cd ~/repos/my-saas/api
export PL_PROJECT="$PWD"
pl trace use --change expose-todos-api --kind capability --id rest-router
pl contract aggregate
pl contract verify
pl dashboard --port 8765 --open
```

---

## 7. 把 pl-pipeline 接入团队 CI

最低门槛：**只对每个模块跑各自的 selfcheck**。`.github/workflows/ci.yml` 示例：

```yaml
jobs:
  pl-frontend:
    runs-on: ubuntu-latest
    defaults: { run: { working-directory: frontend } }
    steps:
      - uses: actions/checkout@v4
      - run: |
          git clone --depth=1 -b pl-v1.8.4 https://github.com/walkertop/pl-pipeline-standalone.git ../pl-pipeline
          export PL_HOME="$PWD/../pl-pipeline"
          export PATH="$PL_HOME/bin:$PATH"
          export PL_PROJECT="$PWD"
          pl status --json || true                # 报告状态，不阻塞
          pl contract verify --strict || true     # 严格模式仅警告

  pl-api:        # 同上，working-directory: api
  pl-crawler:    # 同上，working-directory: crawler
```

**进阶**：用 `paths:` filter 让 frontend job 只在 `frontend/**` 改动时跑，省 CI 配额。

---

## 8. 常见问题

### Q1: 一个模块能装两个 adapter 吗？
A: 不能。`adapter-install` 会写 `.pl-adapter.yaml` 唯一记录，第二次会冲突。
如果你的模块技术栈混合（罕见，例如 Next.js + 嵌入式 Python），**拆成两个子目录**，各自独立 `PL_PROJECT`。

### Q2: 我的爬虫用 Scrapy / Playwright / Selenium，build_adapter 怎么写？
A: 都是 `python -m py_compile` + 各自的 `pytest` / `lint` 命令。Scrapy 还可以加 `scrapy check spiders/`：
```yaml
commands:
  test:
    cmd: "scrapy check && pytest -q tests/"
```

### Q3: pipeline-output 要 commit 进 git 吗？
A: **不要**。已经在示例 `.gitignore` 里加了。`pl/changes/` 才是要 commit 的（spec/plan/taskdag/.state 是产物契约）。

### Q4: 每个模块都要 export PL_HOME / PATH 吗？
A: 一次写进 `~/.zshrc` 即可全局生效。direnv 用来管 `PL_PROJECT`。

### Q5: 我想给爬虫也来个完整 adapter，可以贡献回上游吗？
A: 当然可以。先把你的 `pl/adapters/build.yaml` + 任何自定义 rule 沉淀稳了，再用 `pl adapter create my-crawler --full` 起骨架，PR 提到主仓。**但目前主线策略是先扎实现有 3 个 adapter**，社区贡献优先级 > 主线开发。

---

## 9. 完整可跑示例

参见仓库内：

```bash
$PL_HOME/examples/demo-monorepo-trio/
```

这是一个**真实可 cp 走改的 3 模块骨架**，包含：
- `frontend/` 已装 `adapter-nextjs-web` 的 `.pl-adapter.yaml`
- `api/` 已装 `adapter-python-fastapi` 的 `.pl-adapter.yaml`
- `crawler/` 自定义 `pl/adapters/build.yaml`，无 adapter
- 三个模块各有一个 demo change，已经跑过 `pl init` + `pl status`

```bash
cp -r $PL_HOME/examples/demo-monorepo-trio ~/repos/my-saas
cd ~/repos/my-saas/demo-monorepo-trio
# 改三个模块的名字、删掉 demo change，开始干你自己的活
```

---

## 10. 心智清单（贴墙）

- [ ] `PL_HOME` = pl-pipeline clone 路径（写进 shell rc）
- [ ] `PATH` 加 `$PL_HOME/bin`（让 `pl` 可用）
- [ ] 每个模块独立 `PL_PROJECT`（用 direnv 自动切）
- [ ] 每个模块独立 `pl/changes/`（spec/plan/taskdag/.state.md commit 进 git）
- [ ] `pipeline-output/` 加 .gitignore
- [ ] adapter 装了就装一个，不装也行
- [ ] 跨模块 change → 同名 + 同日期前缀，spec.md 互引
- [ ] CI 三个 job 并行，paths filter 省配额

完成以上 8 条，你就拿到了 pl-pipeline 在多模块 monorepo 的完整体验。
