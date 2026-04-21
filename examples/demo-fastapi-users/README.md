# demo-fastapi-users

> 这是 pl-pipeline `adapter-python-fastapi` 的端到端示范工程。
>
> 一切可见产物（模板 / agents / skills / rules / scripts / change 文档 /
> Python 源码）都来自**真实**跑过的 `/pl:proposal → /pl:plan → /pl:implement
> → /pl:verify → /pl:archive` 五阶段。

## 目录结构

```
demo-fastapi-users/
├── .pl-adapter.yaml                     ← adapter-install.sh 注入元数据
├── pyproject.toml                       ← 最小依赖声明
├── pl/
│   ├── config.yaml                      ← 从 assets/pl/config.default.yaml 复制
│   ├── templates/                       ← adapter 注入的 3 件模板
│   └── changes/
│       └── add-users-api/               ← 走完五阶段的真实 change
│           ├── spec.md
│           ├── plan.md
│           ├── taskdag.md
│           ├── api.md
│           └── .state.md                ← 阶段真相源
├── .codebuddy/
│   ├── agents/   ← fastapi-architect / fastapi-reviewer
│   ├── skills/   ← 4 个 skill
│   └── rules/    ← 3 条 rule
├── scripts/      ← build / verify / lint 三件套（adapter 注入）
├── app/
│   ├── main.py
│   ├── deps.py / db.py / settings.py / errors.py
│   ├── models/user.py                   ← SQLAlchemy 2.x ORM
│   ├── schemas/{user.py, common.py}     ← Pydantic v2
│   ├── repositories/user_repo.py
│   ├── services/user_service.py
│   └── api/v1/users.py                  ← FastAPI 路由
└── tests/api/test_users.py              ← httpx 集成测试骨架
```

## 自己跑一遍流水线产物

```bash
PL_HOME="$(pwd)"
rm -rf /tmp/my-fastapi && mkdir -p /tmp/my-fastapi/pl
cp assets/pl/config.default.yaml /tmp/my-fastapi/pl/config.yaml
bash scripts/adapter-install.sh adapters/adapter-python-fastapi /tmp/my-fastapi

# 除 installed_at 时间戳外应与 examples/demo-fastapi-users 一致
diff -r examples/demo-fastapi-users/pl/templates /tmp/my-fastapi/pl/templates
diff -r examples/demo-fastapi-users/.codebuddy   /tmp/my-fastapi/.codebuddy
diff -r examples/demo-fastapi-users/scripts      /tmp/my-fastapi/scripts
```

## 跑 FastAPI 本体

本 demo 不 commit `.venv/` 或 `uv.lock`。要真实起服务：

```bash
cd examples/demo-fastapi-users
uv sync                              # 或 pip install -e .
export PL_BUILD_CHECK_CMD='uv run python -c "import py_compile, pathlib; [py_compile.compile(str(p), doraise=True) for p in pathlib.Path(\"app\").rglob(\"*.py\")]"'

uv run uvicorn app.main:app --reload
# → http://localhost:8000/docs （Swagger UI）
```

快速冒烟：

```bash
curl -s -X POST http://localhost:8000/api/v1/users \
  -H 'content-type: application/json' \
  -d '{"email":"alice@example.com","password":"secret123"}' | jq

curl -s http://localhost:8000/api/v1/users | jq
```

## change：add-users-api 详情

| 字段 | 值 |
|---|---|
| Change ID | `add-users-api` |
| 类型 | API 新增 |
| 资源路径 | `/api/v1/users` + `/auth/*` |
| 方法 | POST register, POST login, GET list, GET detail |
| 五阶段 | ✅ 全完成（见 `.state.md`） |

产物表：

| 阶段 | 产物 |
|---|---|
| SPEC | `pl/changes/add-users-api/spec.md` |
| PLAN | `pl/changes/add-users-api/{plan,taskdag,api}.md` |
| IMPLEMENT | `app/{models,schemas,repositories,services,api/v1}/**.py` |
| VERIFY | `tests/api/test_users.py`（httpx 集成骨架） |
| ARCHIVE | `.state.md` → ARCHIVE，自检 6 项全过 |

## 源码导读

- `app/main.py` — FastAPI app + 异常处理器
- `app/db.py` — 异步引擎 + SessionLocal（默认 aiosqlite，方便本地跑）
- `app/deps.py` — `get_db` / `get_current_user` / `get_user_service`
- `app/models/user.py` — SQLAlchemy 2.x 声明式 + UUID 主键
- `app/schemas/user.py` — Pydantic v2 三件套 `UserCreate/UserRead/UserUpdate`
- `app/services/user_service.py` — 事务边界在此层
- `app/api/v1/users.py` — REST 路由
- `app/errors.py` — 领域异常 + HTTP status 映射

## 为什么没用 Prisma 风格 ORM？

SQLAlchemy 2.x 已提供 `Mapped` / `mapped_column` 声明式 API，类型友好度与 Prisma
相当；加上生态完整（Alembic / asyncpg / SQLite / MySQL），是 FastAPI 官方教程
默认选择。adapter 的 `sqlalchemy-async` skill 文档里有完整模式。
