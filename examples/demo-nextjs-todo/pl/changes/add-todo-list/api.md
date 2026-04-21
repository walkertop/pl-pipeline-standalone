# API Contract: add-todo-list

> 本 change 不新增对外 HTTP 接口；下述契约是 **Server Actions** 的签名与
> 行为规范。IMPLEMENT 阶段代码必须与本文保持同源。

---

## 数据类型

```ts
// app/todos/lib/data.ts
export interface Todo {
  id: string            // UUID v4
  title: string         // 1..100 chars, trimmed
  completed: boolean
  createdAt: number     // epoch ms
}
```

---

## Server Action: createTodo

### 签名

```ts
// app/todos/_actions/todos.ts ('use server')
type State =
  | { ok: true; todo: Todo }
  | { ok: false; error: string }

export async function createTodo(prev: State, formData: FormData): Promise<State>
```

### 入参

| 字段 | 来源 | 类型 | 约束 |
|---|---|---|---|
| `title` | `formData.get('title')` | string | 1 ≤ len(trim) ≤ 100 |

### 响应

- 成功：`{ ok: true, todo }`
- 失败：`{ ok: false, error: 'title_required' | 'title_too_long' }`

### 副作用

- 写入 `app/todos/lib/data.ts` 的模块级 Map
- 调用 `revalidateTag('todos')`

### 错误码

| code | 语义 | UI 展示 |
|---|---|---|
| `title_required` | title 缺失或 trim 后为空 | `"请输入标题"` |
| `title_too_long` | len > 100 | `"标题不能超过 100 字"` |

---

## Server Action: toggleTodo

### 签名

```ts
export async function toggleTodo(id: string): Promise<void>
```

### 入参

| 字段 | 类型 | 约束 |
|---|---|---|
| `id` | string (UUID) | 必须存在于 Map |

### 响应

无返回值。不存在的 id 静默忽略（demo 简化；生产应 throw）。

### 副作用

- 翻转目标 Todo 的 `completed`
- 调用 `revalidateTag('todos')`

---

## 约定

- 所有 action 文件顶部有 `'use server'` 指令
- action 不 import 浏览器 API
- 从 Client 调用 action 时作为 props / form action 传递；**不在 client 文件里 import**
