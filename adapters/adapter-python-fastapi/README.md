# adapter-python-fastapi

> pl-pipeline 的 Python FastAPI 后端适配器。覆盖 **Python 3.11+ / FastAPI /
> Pydantic v2 / SQLAlchemy 2.x / pytest** 的标准技术栈，把场景知识以 templates
> / agents / skills / rules / scripts 的形式一键注入到宿主项目。

## 适用场景

- FastAPI **0.100+**（Pydantic v2 已成熟）
- Python **3.11+**（完整 `Self` / `TypeAlias` / `Annotated` 支持）
- 用 **uv** 或 **poetry** 管理依赖（本 adapter 默认 uv；改 poetry 只需覆盖 build_adapter）
- 异步 SQLAlchemy + asyncpg / aiomysql

## 一键安装

```bash
cd /path/to/my-fastapi-project

# pl 结构
mkdir -p pl/{changes,templates} .codebuddy/{agents,skills,rules} scripts
cp $PL_ASSETS/pl/config.default.yaml pl/config.yaml

# 装 adapter
bash $PL_HOME/scripts/adapter-install.sh \
  $PL_HOME/adapters/adapter-python-fastapi \
  .

# 导出构建命令（或从 .pl-adapter.yaml 读）
export PL_BUILD_CHECK_CMD='uv run python -c "import py_compile, pathlib; [py_compile.compile(str(p), doraise=True) for p in pathlib.Path(\"app\").rglob(\"*.py\")]"'
```

安装完会得到：

```
.pl-adapter.yaml
pl/templates/{spec,plan,taskdag}.md
.codebuddy/agents/fastapi-{architect,reviewer}.md
.codebuddy/skills/{fastapi-dependency-injection,pydantic-v2-patterns,
                   sqlalchemy-async,pytest-async}.md
.codebuddy/rules/{python-typing-strict,fastapi-conventions,api-error-handling}.md
scripts/adapter-python-fastapi-{build,verify,lint}.sh
```

## 提供什么

| 资产类 | 数量 | 亮点 |
|---|---|---|
| Templates | 3 | spec/plan/taskdag 针对 REST API 场景 |
| Agents | 2 | 架构师（依赖注入/事务决策）+ 审查员（OpenAPI 契约视角） |
| Skills | 4 | Depends / Pydantic v2 / SQLAlchemy async / pytest async |
| Rules | 3 | Python 类型注解 / FastAPI 约定 / 错误处理 |
| Scripts | 3 | build / verify / lint 三件套 |
| BuildAdapter | 1 | `$PL_BUILD_CHECK_CMD = py_compile ...` |

## 校验

```bash
bash $PL_HOME/scripts/adapter-validate.sh $PL_HOME/adapters/adapter-python-fastapi
```

## 案例

见 `docs/case-study.md`（demo-fastapi-users 端到端示范）。

## 版本

| 版本 | 日期 | 变化 |
|---|---|---|
| 0.1.0 | 2026-04-21 | 首版 |
