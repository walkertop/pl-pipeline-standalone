# Case Study: 在 demo-fastapi-users 中接入 pl-pipeline

> 用一个虚构的用户管理服务端项目，展示 adapter-python-fastapi 端到端用法。

## 场景

在空 FastAPI 项目 `demo-fastapi-users` 中新增 "用户注册 / 登录 / 列表 / 详情"
四个 REST 端点，走完 `/pl:proposal → /pl:plan → /pl:implement → /pl:verify → /pl:archive`。

## 0. 前置

```bash
# 创建项目
mkdir demo-fastapi-users && cd demo-fastapi-users
uv init
uv add fastapi "pydantic>=2" "sqlalchemy>=2" asyncpg "pydantic-settings" "alembic" "uvicorn[standard]"
uv add --dev pytest pytest-asyncio httpx pytest-cov ruff mypy

# 空的 app 目录
mkdir -p app/{api/v1,schemas,models,services,repositories} tests/{api,services}
touch app/__init__.py app/main.py

# 准备 pl 结构
mkdir -p pl/{changes,templates} .codebuddy/{agents,skills,rules} scripts
cp $PL_ASSETS/pl/config.default.yaml pl/config.yaml

# 装 adapter
bash $PL_HOME/scripts/adapter-install.sh \
  $PL_HOME/adapters/adapter-python-fastapi \
  .
```

## 1. SPEC — `/pl:proposal add-users-api`

Agent 读本 adapter 提供的 `spec.md` 模板，生成：

```markdown
# StructuredSpec: 用户管理 API

| Change ID | add-users-api |
| 资源路径 | /api/v1/users, /auth |
| HTTP 方法 | POST /auth/register, POST /auth/token,
             GET /users, GET /users/{id} |

## 端点清单
| E1 | POST /auth/register | 注册 | P0 |
| E2 | POST /auth/token    | 登录 | P0 |
| E3 | GET  /users         | 列表 | P0 |
| E4 | GET  /users/{id}    | 详情 | P1 |
```

## 2. PLAN — `/pl:plan add-users-api`

`fastapi-architect` 介入：

```markdown
## 架构决策
1. 路由分组：/api/v1/users, /auth
2. 依赖链：get_settings → get_db → get_current_user
3. 数据分层：
   - models/user.py      (SQLAlchemy)
   - schemas/user.py     (UserCreate/UserRead/UserUpdate)
   - schemas/auth.py     (LoginRequest, TokenResponse)
4. 事务：UserService.register
5. 认证：JWT (python-jose), bcrypt 密码哈希
```

生成 taskdag：

```
T01 User 模型 + migration
T02 UserSchema 三件套
T03 UserRepository
T04 password hash + jwt 工具
T05 UserService.register / authenticate
T06 /auth 路由
T07 /users 路由
T08 httpx 集成测试
T09 OpenAPI 快照
T10 mypy + ruff 通过
```

## 3. IMPLEMENT — `/pl:implement`

逐任务完成。关键片段：

```python
# app/models/user.py
class User(Base):
    __tablename__ = "users"
    id: Mapped[UUID] = mapped_column(primary_key=True, default=uuid4)
    email: Mapped[str] = mapped_column(String(255), unique=True)
    password_hash: Mapped[str]
    created_at: Mapped[datetime] = mapped_column(server_default=func.now())
```

```python
# app/schemas/user.py
class UserBase(BaseModel):
    email: EmailStr

class UserCreate(UserBase):
    password: str = Field(min_length=8)

class UserRead(UserBase):
    id: UUID
    created_at: datetime
    model_config = ConfigDict(from_attributes=True)
```

```python
# app/services/user_service.py
class UserService:
    def __init__(self, repo: UserRepo): self.repo = repo

    async def register(self, session: AsyncSession, data: UserCreate) -> User:
        async with session.begin():
            if await self.repo.get_by_email(session, data.email):
                raise ConflictError("email already registered")
            user = User(email=data.email, password_hash=hash_password(data.password))
            session.add(user)
            await session.flush()
            return user
```

```python
# app/api/v1/users.py
@router.get("", response_model=Paginated[UserRead])
async def list_users(
    p: Pagination = Depends(),
    _auth: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> Paginated[UserRead]:
    items, total = await user_service.list(db, p)
    return Paginated(items=items, page=p.page, size=p.size, total=total)
```

每完成一个任务，pl-core 更新 `.state.md` 的 `<last_task_done>`。

## 4. VERIFY — `/pl:verify`

执行 `scripts/adapter-python-fastapi-verify.sh`：

```
━━━ ruff ━━━
All checks passed!
✅ ruff

━━━ mypy ━━━
Success: no issues found in 17 source files
✅ mypy

━━━ pytest ━━━
tests/api/test_auth.py .......                          [ 40%]
tests/api/test_users.py .............                   [100%]
19 passed in 2.4s
✅ pytest

✅ verify passed
```

`fastapi-reviewer` agent 做第二轮审查，给出 2 处 non-blocking 建议（加索引、
加 rate limit）。

## 5. ARCHIVE — `/pl:archive`

完成 6 项资产沉淀检查，归档到 `pl/changes/archive/2026-04-add-users-api/`。

## 产出

| 产物 | 路径 |
|------|-----|
| 代码 | `app/models,schemas,services,repositories,api/v1/` |
| 迁移 | `alembic/versions/<hash>_create_users.py` |
| 测试 | `tests/api/test_{auth,users}.py` |
| OpenAPI | `tests/snapshots/openapi.json` |
| change 文档 | `pl/changes/add-users-api/{spec,plan,taskdag,api}.md` |

## 观察

- **首次安装到首次跑通 uvicorn**：~8 分钟
- **从 spec 到通过所有测试**：~3 小时
- **对 pl-core 侵入**：0；所有 Python 特定决策都在 adapter 内

## 结语

Adapter 通过**模板场景化 + agents 专家化 + skills 知识化 + rules 约束化**
的四重注入，让 pl-pipeline 这个通用流水线在陌生技术栈上依然保持"做得快且稳"。
