---
name: pydantic-v2-patterns
triggers: ["pydantic", "basemodel", "validator", "field_validator", "model_config"]
description: Pydantic v2 数据建模、校验、序列化完整参考
---

# Pydantic v2 模式

> Pydantic v2（2023+）与 v1 有重大 API 变化。本文只讲 v2。

## BaseModel 基础

```python
from pydantic import BaseModel, Field, ConfigDict

class User(BaseModel):
    id: int
    name: str = Field(min_length=1, max_length=100)
    email: str
    age: int | None = Field(default=None, ge=0, le=150)

    model_config = ConfigDict(
        str_strip_whitespace=True,
        frozen=True,           # 不可变
    )
```

## 常用 Field 约束

| 类型 | 约束 | 示例 |
|------|-----|------|
| str | `min_length` / `max_length` / `pattern` | `Field(pattern=r"^[a-z]+$")` |
| int / float | `ge` / `gt` / `le` / `lt` | `Field(ge=0, le=100)` |
| list | `min_length` / `max_length` | `Field(max_length=10)` |
| 所有 | `default` / `default_factory` / `description` | `Field(default_factory=list)` |

## 校验器（v2 是 decorator）

### field_validator

```python
from pydantic import field_validator

class User(BaseModel):
    email: str

    @field_validator("email")
    @classmethod
    def validate_email(cls, v: str) -> str:
        if "@" not in v:
            raise ValueError("invalid email")
        return v.lower()
```

### model_validator（多字段联合校验）

```python
from pydantic import model_validator
from typing import Self

class DateRange(BaseModel):
    start: date
    end: date

    @model_validator(mode="after")
    def check_range(self) -> Self:
        if self.start > self.end:
            raise ValueError("start > end")
        return self
```

### mode="before" vs "after"

- `before`: 在类型转换**之前**运行（原始 dict）
- `after`: 类型转换**之后**运行（已是对象）

## 序列化

### model_dump / model_dump_json

```python
u = User(id=1, name="Alice", email="a@b.com")

u.model_dump()                        # dict
u.model_dump(mode="json")             # dict，datetime 转字符串
u.model_dump(exclude={"email"})       # 排除
u.model_dump(include={"id", "name"})  # 包含
u.model_dump(exclude_none=True)       # None 字段省略
u.model_dump(by_alias=True)           # 用 alias

u.model_dump_json()                   # JSON 字符串
```

### 自定义序列化

```python
from pydantic import field_serializer

class User(BaseModel):
    created_at: datetime

    @field_serializer("created_at")
    def serialize_dt(self, v: datetime) -> str:
        return v.isoformat()
```

## 从 ORM / 其他对象创建

```python
class UserRead(BaseModel):
    id: int
    name: str

    model_config = ConfigDict(from_attributes=True)

# SQLAlchemy ORM
sa_user = await db.get(UserModel, 1)
read = UserRead.model_validate(sa_user)
```

## 分层：Create / Update / Read

标准三件套：

```python
class UserBase(BaseModel):
    name: str = Field(min_length=1, max_length=100)
    email: str

class UserCreate(UserBase):
    password: str = Field(min_length=8)

class UserUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=1, max_length=100)
    email: str | None = None

class UserRead(UserBase):
    id: int
    created_at: datetime
    model_config = ConfigDict(from_attributes=True)
```

- `UserBase` 是共享字段
- `UserCreate` 附加创建时字段（如 password）
- `UserUpdate` 全部可选（PATCH 语义）
- `UserRead` 是返回给客户端的安全视图（不含 password）

## 别名

```python
class User(BaseModel):
    user_id: int = Field(alias="userId")         # 输入 userId

    model_config = ConfigDict(
        populate_by_name=True,                   # 允许 user_id 也能传入
    )

User.model_validate({"userId": 1})               # ✅
User(user_id=1)                                  # ✅
```

## Settings（Pydantic Settings v2）

```python
from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    db_url: str
    jwt_secret: str
    log_level: str = "INFO"

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )
```

## 常见坑

### 坑 1: v1 的 `@validator` 不再工作

```python
# ❌ v1 语法
@validator("email")
def check(cls, v): ...

# ✅ v2
@field_validator("email")
@classmethod
def check(cls, v: str) -> str: ...
```

### 坑 2: Config 类改名

```python
# ❌ v1
class User(BaseModel):
    class Config:
        orm_mode = True

# ✅ v2
class User(BaseModel):
    model_config = ConfigDict(from_attributes=True)
```

### 坑 3: `.dict()` / `.json()` 已废弃

用 `.model_dump()` / `.model_dump_json()`。

## 参考

- https://docs.pydantic.dev/latest/
- https://docs.pydantic.dev/latest/migration/
