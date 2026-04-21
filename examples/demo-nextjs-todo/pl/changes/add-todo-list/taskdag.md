# TaskDAG: 添加 Todo 列表

> 由 `/pl:plan` 基于 `plan.md` 生成。IMPLEMENT 阶段按依赖顺序执行。
> **本文件最后真实状态：11/11 任务完成**。

---

## 任务列表

| ID | 任务 | 类型 | 依赖 | 产物 | 状态 |
|----|-----|------|-----|-----|------|
| T01 | 创建 route segment 骨架（page.tsx + layout.tsx） | scaffold | - | `app/todos/{page,layout}.tsx` | ✅ DONE |
| T02 | 定义 `Todo` 类型 + data.ts helpers | types | T01 | `app/todos/lib/data.ts` | ✅ DONE |
| T03 | RSC `<TodoList>` 渲染列表 | rsc | T02 | `app/todos/_components/TodoList.tsx` | ✅ DONE |
| T04 | Server Action `createTodo` + Zod 校验 | action | T02 | `app/todos/_actions/todos.ts` | ✅ DONE |
| T05 | Client `<CreateForm>` + useFormState 绑定 | ui-client | T04 | `app/todos/_components/CreateForm.tsx` | ✅ DONE |
| T06 | Server Action `toggleTodo` | action | T02 | `app/todos/_actions/todos.ts` | ✅ DONE |
| T07 | Client `<TodoItem>` + checkbox | ui-client | T06, T03 | `app/todos/_components/TodoItem.tsx` | ✅ DONE |
| T08 | `loading.tsx` / `error.tsx` 兜底 | resilience | T03 | 同名文件 | ✅ DONE |
| T09 | `generateMetadata` / SEO | seo | T03 | `app/todos/page.tsx` | ✅ DONE |
| T10 | 基础 e2e 测试骨架 | test | T05, T07 | `tests/todos.spec.ts` | ✅ DONE |
| T11 | 通过 `scripts/adapter-nextjs-web-verify.sh` | verify | T01-T10 | verify 报告 | ✅ DONE |

---

## 依赖图

```
T01 ──▶ T02 ──▶ T03 ──▶ T08
                  │        │
                  ├──▶ T09 │
                  └──▶ T07 │
                     ↑     │
         T04 ──▶ T05 │     │
          └──▶ T06 ──┘     │
                           ▼
                     T10 ──▶ T11
```

---

## 执行节拍

- 每完成一个 T，编辑 `.state.md` 的 `<last_task_done>`（见真相源）
- `scripts/adapter-nextjs-web-verify.sh` 作为 T11 的判据，实质是 `tsc --noEmit && next lint && (npm test || skip)`

---

## 与 API Contract 的联动

`api.md` 声明了 `createTodo` / `toggleTodo` 两个 Server Action 的出入参。
T04/T06 实施时以 `api.md` 为准，保持契约同源。
