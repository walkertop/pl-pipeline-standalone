---
id: python-typing-strict
version: 1.0.0
frontmatter_added_by: backfill-v1.3
---

# Rule: Python 类型注解强制

> **Scope**: always
> **适用**: 本仓库所有 `*.py`（除 `tests/` 下的 fixture helper 外）

## 硬性要求

1. 函数签名**必须**有类型注解：参数 + 返回值
2. 模块级常量必须有类型注解（`X: Final[int] = 1`）
3. 不允许隐式 `Any`

## `pyproject.toml` 配置

```toml
[tool.mypy]
python_version = "3.11"
strict = true
warn_return_any = true
warn_unused_ignores = true
disallow_any_generics = true
disallow_untyped_decorators = true
no_implicit_optional = true

[tool.ruff]
line-length = 100
target-version = "py311"

[tool.ruff.lint]
select = ["E", "F", "W", "I", "UP", "B", "SIM", "ASYNC", "RUF"]
```

## 编码约束

### 1. 用现代类型语法（3.10+）

```python
# ❌ 老
from typing import List, Optional, Union
def f(items: List[int]) -> Optional[str]: ...

# ✅ 新
def f(items: list[int]) -> str | None: ...
```

### 2. 禁用 `Any`（例外需注释说明）

```python
from typing import Any

# ❌
def handle(data: Any): ...

# ✅
from typing import Mapping
def handle(data: Mapping[str, object]): ...   # 或具体 TypedDict
```

### 3. Generic 要明确参数

```python
# ❌
def first(xs): return xs[0]

# ✅
from typing import TypeVar
T = TypeVar("T")
def first(xs: list[T]) -> T: return xs[0]
```

### 4. Optional 显式

```python
# ❌（没开 no_implicit_optional 时也算错）
def f(x: int = None): ...

# ✅
def f(x: int | None = None): ...
```

### 5. async 函数返回 `Coroutine[...]` 或直接写真实返回类型

```python
# ✅ 只写真实返回，编译器知道是 coroutine
async def load() -> list[Item]: ...

# await 之后得 list[Item]
items = await load()
```

### 6. 数据类优先 Pydantic / dataclass

避免用裸 dict / tuple 表达领域对象。

```python
# ❌
def get_user() -> dict:
    return {"id": 1, "name": "a"}

# ✅
@dataclass
class User:
    id: int
    name: str

def get_user() -> User: ...
```

### 7. Callable 标签完整

```python
# ❌
callback: Callable

# ✅
callback: Callable[[int, str], bool]
```

### 8. TypedDict vs dict

当字段结构固定时用 `TypedDict`：

```python
from typing import TypedDict

class ItemPayload(TypedDict):
    name: str
    description: str | None
```

## 命名规范

- `snake_case` 变量/函数
- `PascalCase` 类
- `UPPER_SNAKE_CASE` 常量
- `_private` 单下划线表示"约定私有"
- `__dunder__` 仅 Python 保留

## 禁忌

- ❌ `from x import *`
- ❌ 可变默认参数：`def f(x: list = []):`（用 `None` 再 `x or []`）
- ❌ `try: ... except:`（至少写 `except Exception`）
- ❌ 把副作用塞进 property / `__init__`（除了基本字段赋值）
- ❌ 循环依赖（走接口 / 前向引用 `"Foo"`）

## 参考

- https://docs.python.org/3/library/typing.html
- https://mypy.readthedocs.io/
- https://typing.readthedocs.io/
