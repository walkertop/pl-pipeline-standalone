# demo-nextjs-todo

> 这是 pl-pipeline `adapter-nextjs-web` 的端到端示范工程。
>
> 你看到的一切都是**真实跑过** `/pl:proposal → /pl:plan → /pl:implement →
> /pl:verify → /pl:archive` 五阶段留下的产物——包括 adapter 注入的模板、
> AI agents 写出来的 spec/plan/taskdag、按 TaskDAG 产出的 Next.js 源码。

## 这个目录里有什么

```
demo-nextjs-todo/
├── .pl-adapter.yaml                 ← adapter-install.sh 生成的注入元数据
├── package.json                     ← 最小依赖声明（未 npm install，见下）
├── pl/
│   ├── config.yaml                  ← 从 assets/pl/config.default.yaml 复制
│   ├── templates/                   ← adapter 注入的 3 件模板（spec/plan/taskdag）
│   └── changes/
│       └── add-todo-list/           ← 走完五阶段的真实 change
│           ├── spec.md
│           ├── plan.md
│           ├── taskdag.md
│           ├── api.md
│           └── .state.md            ← 阶段真相源
├── .codebuddy/
│   ├── agents/   ← adapter 注入的 nextjs-architect / nextjs-reviewer
│   ├── skills/   ← adapter 注入的 4 个 skill
│   └── rules/    ← adapter 注入的 3 条 rule
├── scripts/      ← adapter 注入的 build / verify / lint 三件套
├── app/
│   └── todos/    ← IMPLEMENT 阶段按 taskdag.md 产出的 Next.js 源码
└── tests/        ← e2e 测试占位
```

## 如何自己跑一遍

前提：在独立仓根目录，你已有 `adapters/adapter-nextjs-web/`。

```bash
# 从零复刻本 demo 的注入过程
PL_HOME="$(pwd)"
mkdir -p /tmp/my-demo/pl
cp assets/pl/config.default.yaml /tmp/my-demo/pl/config.yaml
bash scripts/adapter-install.sh adapters/adapter-nextjs-web /tmp/my-demo

# diff 一下，除了 installed_at 时间戳外应该完全一致
diff -r examples/demo-nextjs-todo/pl/templates /tmp/my-demo/pl/templates
diff -r examples/demo-nextjs-todo/.codebuddy   /tmp/my-demo/.codebuddy
diff -r examples/demo-nextjs-todo/scripts      /tmp/my-demo/scripts
```

## 跑真实 Next.js 应用

本 demo 不 commit `node_modules/` 和 `package-lock.json`，想实际启动：

```bash
cd examples/demo-nextjs-todo
npm install
export PL_BUILD_CHECK_CMD="npx tsc --noEmit"
npm run dev
# → http://localhost:3000/todos
```

## change：add-todo-list 详情

| 字段 | 值 |
|---|---|
| Change ID | `add-todo-list` |
| 类型 | 页面新增 |
| 路由 | `/todos` |
| 渲染模式 | RSC（列表） + Client island（表单） |
| 五阶段是否全完成 | ✅（见 `.state.md`） |
| 涉及文件 | `app/todos/**`（4 个），`tests/**`（1 个） |

产物表：

| 阶段 | 产物 | 行数 |
|---|---|---|
| SPEC | `pl/changes/add-todo-list/spec.md` | ~80 |
| PLAN | `pl/changes/add-todo-list/plan.md` + `taskdag.md` + `api.md` | ~150 |
| IMPLEMENT | `app/todos/{page.tsx,layout.tsx,_components/*,_actions/*}` | ~130 |
| VERIFY | `tests/todos.spec.ts` + scripts/adapter-nextjs-web-verify.sh 运行记录 | ~50 |
| ARCHIVE | `.state.md` 设为 archived，六项资产沉淀检查均过 | — |

## 源码导读

- `app/todos/page.tsx` — RSC 入口，直接 `await getTodos()`
- `app/todos/_components/CreateForm.tsx` — `'use client'` 表单，绑定 Server Action
- `app/todos/_components/TodoList.tsx` — RSC 展示
- `app/todos/_actions/todos.ts` — `createTodo` / `toggleTodo` Server Actions
- `app/todos/lib/data.ts` — 数据访问层（demo 用内存 Map 模拟 DB）

## 这个 demo 有什么价值

1. **可复现**：上面的 diff 命令是真的，本 demo 的 adapter 产物与最新
   `adapter-install.sh` 输出一致（除时间戳）
2. **教学**：第一次用 `adapter-nextjs-web` 的人可以直接读这里的 spec/plan/taskdag
3. **回归基线**：未来 adapter 升级版本，要保证 demo diff 依然最小
