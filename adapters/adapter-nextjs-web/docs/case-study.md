# Case Study: 在 demo-nextjs-todo 中接入 pl-pipeline

> 本文用一个**虚构但可执行**的场景展示 adapter-nextjs-web 的端到端用法。

## 场景

在一个空的 Next.js App Router 项目 `demo-nextjs-todo` 中，新增 "Todo 列表
+ 创建 Todo" 功能，走完 `/pl:proposal → /pl:plan → /pl:implement → /pl:verify → /pl:archive`。

## 0. 前置

```bash
npx create-next-app@latest demo-nextjs-todo --ts --app --no-src-dir
cd demo-nextjs-todo

# 准备 pl-core 结构
mkdir -p pl/{changes,templates} .codebuddy/{agents,skills,rules} scripts
cp $PL_ASSETS/pl/config.default.yaml pl/config.yaml

# 安装 adapter
bash $PL_HOME/scripts/adapter-install.sh $PL_HOME/adapters/adapter-nextjs-web .

# 导出 build check
export PL_BUILD_CHECK_CMD="npx tsc --noEmit"
```

## 1. SPEC — `/pl:proposal add-todo-list`

Agent 读 `pl/templates/spec.md`（本 adapter 提供）生成：

```markdown
# StructuredSpec: 添加 Todo 列表

| 字段 | 值 |
|---|---|
| Change ID | add-todo-list |
| 变更类型 | 页面新增 |
| 路由路径 | /app/todos |
| 渲染模式 | RSC + Client island（表单） |

## 功能清单
| ID | 功能 | 优先级 |
| F1 | 展示 Todo 列表 | P0 |
| F2 | 创建 Todo（表单 + Server Action） | P0 |
| F3 | 标记完成 | P1 |
```

## 2. PLAN — `/pl:plan add-todo-list`

`nextjs-architect` agent 介入，给出决策：

```markdown
## 架构决策
- 渲染模式: RSC（列表数据） + Client island（表单）
- 数据源: SQLite + Prisma
- Cache tag: "todos"
- Actions: createTodo, toggleTodo
```

生成 taskdag.md：

```
T01 scaffold route + layout
T02 prisma schema + seed
T03 RSC list (await getTodos)
T04 Client form component
T05 createTodo action + revalidateTag
T06 toggleTodo action
T07 error.tsx / loading.tsx
T08 metadata / SEO
T09 Playwright test
```

## 3. IMPLEMENT — `/pl:implement`

按 T01→T09 逐个实现。关键文件：

```tsx
// app/todos/page.tsx
import { getTodos } from '@/lib/data'
import { CreateForm } from './_components/CreateForm'
import { TodoList } from './_components/TodoList'

export const metadata = { title: 'Todos' }

export default async function TodosPage() {
  const todos = await getTodos()
  return <>
    <h1>Todos</h1>
    <CreateForm />
    <TodoList todos={todos} />
  </>
}
```

```ts
// app/todos/_actions/todos.ts
'use server'
import { revalidateTag } from 'next/cache'
import { z } from 'zod'
import { db } from '@/lib/db'

const CreateSchema = z.object({ title: z.string().min(1).max(100) })

export async function createTodo(prev: any, formData: FormData) {
  const parsed = CreateSchema.safeParse({ title: formData.get('title') })
  if (!parsed.success) return { ok: false, error: 'invalid' }
  await db.todo.create({ data: { title: parsed.data.title } })
  revalidateTag('todos')
  return { ok: true }
}
```

每完成一个任务，pl-core 写 `.state.md`。

## 4. VERIFY — `/pl:verify`

执行 `scripts/adapter-nextjs-web-verify.sh`：

```
━━━ typecheck ━━━
✅ typecheck

━━━ lint ━━━
✅ lint

━━━ unit test ━━━
✅ unit test

✅ verify passed
```

`nextjs-reviewer` agent 对改动做第二轮审查，输出报告。

## 5. ARCHIVE — `/pl:archive`

完成后执行资产沉淀 6 项检查，归档 `pl/changes/add-todo-list/` 到
`pl/changes/archive/2026-04-add-todo-list/`。

## 产出

| 产物 | 路径 |
|------|-----|
| spec.md | `pl/changes/add-todo-list/spec.md` |
| plan.md | `pl/changes/add-todo-list/plan.md` |
| taskdag.md | `pl/changes/add-todo-list/taskdag.md` |
| .state.md | `pl/changes/add-todo-list/.state.md` |
| 代码 | `app/todos/**` |
| 测试 | `e2e/todos.spec.ts` |

## 观察

- **首次安装到首次跑通**: ~5 分钟
- **从 spec 到完成 5 个 P0 任务**: ~2 小时
- **对 pl-core 侵入**: 0（adapter 只覆盖了 templates，agents/skills/rules 只进 .codebuddy/）

## 结语

这就是"场景化 adapter"的价值：在 pl-core 中性的流水线骨架上，adapter 提供
**该场景最佳实践**的模板和知识库，让团队在陌生技术栈上也能保持"做得快且稳"的节奏。
