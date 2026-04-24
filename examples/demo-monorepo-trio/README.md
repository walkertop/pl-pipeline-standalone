# demo-monorepo-trio

> **三模块 monorepo 接入 pl-pipeline 的可跑骨架。**
> 配套指南：[`docs/guides/monorepo-quickstart.md`](../../docs/guides/monorepo-quickstart.md)

这是一个**几乎为空**但**结构完整**的 demo 仓库，目的是让你 `cp -r` 走改名后立刻拿到：

- `frontend/`  ← Next.js 模块，已装 `adapter-nextjs-web`
- `api/`       ← FastAPI 模块，已装 `adapter-python-fastapi`
- `crawler/`   ← Scrapy 风格爬虫，**不装 adapter**，用自定义 build.yaml
- 每个模块有 1 条 demo change（`add-demo-feature`），已经跑过 `pl init` + `pl status`

## 为什么爬虫不装 adapter？

- pl-pipeline 截至 v1.8.x **暂不计划新增 adapter 生态**（包括 crawler/Go/Rust）
- 爬虫场景 fastapi adapter 的 rules（RSC/路由/HTTP error）大多无关，硬塞反生噪音
- pl-core 本就支持"裸跑"——只要 `pl/config.yaml` + `pl/adapters/build.yaml` 在位，所有 gate 该 skip 的 skip，该跑的跑

## 快速试用

```bash
export PL_HOME=/path/to/pl-pipeline-standalone   # 你 clone 的位置
export PATH="$PL_HOME/bin:$PATH"

# 试 frontend
cd frontend
export PL_PROJECT="$PWD"
pl status                            # 看到 add-demo-feature 在 SPEC 阶段
pl --version

# 试 api
cd ../api
export PL_PROJECT="$PWD"
pl status

# 试 crawler（无 adapter，纯 pl-core）
cd ../crawler
export PL_PROJECT="$PWD"
export PL_BUILD_CHECK_CMD="python -m py_compile spiders/*.py"
pl status
```

> **注意**：`.pl-adapter.yaml` 里的 `installed_files` 列表是 demo 占位（路径都是真实存在的，但内容是空 stub）。
> 真实使用时，请删掉本目录的 `frontend/` `api/` `crawler/` 内的代码 stub（`app/`、`spiders/` 下的 `.py`/`.ts`），
> 并执行一次完整 `pl adapter install` 把 adapter 真实资产注入。

## 目录速览

```
demo-monorepo-trio/
├── README.md                       ← 你正在看
├── frontend/
│   ├── pl/
│   │   ├── config.yaml
│   │   └── changes/add-demo-feature/
│   ├── .pl-adapter.yaml            ← adapter-nextjs-web 安装清单（demo 占位）
│   ├── package.json
│   └── app/page.tsx
├── api/
│   ├── pl/
│   │   ├── config.yaml
│   │   └── changes/add-demo-feature/
│   ├── .pl-adapter.yaml            ← adapter-python-fastapi 安装清单（demo 占位）
│   ├── pyproject.toml
│   └── app/main.py
└── crawler/
    ├── pl/
    │   ├── config.yaml
    │   ├── adapters/build.yaml     ← 自定义 build 命令（无 adapter）
    │   └── changes/add-demo-feature/
    ├── pyproject.toml
    └── spiders/example.py
```

## 复用步骤

```bash
cp -r $PL_HOME/examples/demo-monorepo-trio ~/repos/my-saas
cd ~/repos/my-saas

# 删掉所有 demo change
rm -rf frontend/pl/changes/add-demo-feature
rm -rf api/pl/changes/add-demo-feature
rm -rf crawler/pl/changes/add-demo-feature

# 删掉占位 .pl-adapter.yaml（你要重新 install）
rm frontend/.pl-adapter.yaml api/.pl-adapter.yaml

# 真实 install（参考 monorepo-quickstart.md §3）
cd frontend && PL_PROJECT="$PWD" pl adapter install $PL_HOME/adapters/adapter-nextjs-web .
cd ../api    && PL_PROJECT="$PWD" pl adapter install $PL_HOME/adapters/adapter-python-fastapi .
# crawler 不动（已有自定义 build.yaml）

# 起你自己的第一条 change
cd ../api && PL_PROJECT="$PWD" pl init my-first-feature --name "我的第一个特性" --domain api
```

完工。
