---
id: nextjs-revalidate-for-non-fetch
severity: warn
scope: always
applies_to:
  glob:
    - "app/**/_actions/**/*.ts"
    - "app/**/_actions/**/*.tsx"
  exclude_glob:
    - "**/node_modules/**"
    - "**/.next/**"
detect:
  - kind: file_contains
    pattern: "'use server'"
  - kind: file_contains
    pattern: "revalidateTag\\("
  - kind: file_not_contains
    pattern: "fetch\\("
message: |
  revalidateTag() 只对 fetch() 拉取的数据源生效。如果你的数据源是 module-level
  Map / DB / globalThis / ORM 等非 fetch 调用，revalidateTag 不会触发 RSC 重渲染，
  UI 不会更新（retro-v2 B3 的真实 bug）。
fix_hint: 改用 revalidatePath('/your/path') 或保留 fetch + cache tag 的经典范式
version: 1.0.0
---

# Rule: `revalidateTag` 仅用于 fetch 数据源

## 背景

Next.js App Router 的数据缓存分两类：

1. **fetch 缓存** — `fetch(url, { next: { tags: ['todos'] } })`
2. **React `cache()` 函数缓存** — 仅服务端生命周期

`revalidateTag('todos')` **只作用于第 1 类**。如果你的 Server Action 里写的是：

```ts
'use server'
import { createTodoRecord } from '../lib/data' // module-level Map

export async function createTodo(formData: FormData) {
  await createTodoRecord(formData.get('title'))
  revalidateTag('todos')   // ← 完全无效！数据源不是 fetch
}
```

看起来调用成功、log 也打了 `POST /todos 200`，但 UI 不会刷新。

## 修复

```ts
'use server'
import { revalidatePath } from 'next/cache'   // ← 改这里

export async function createTodo(formData: FormData) {
  await createTodoRecord(formData.get('title'))
  revalidatePath('/todos')   // 告诉 Next：这条路径的 RSC tree 要重渲染
}
```

## 本规则的检测算法

以下三个条件**同时**满足才告警：

- 文件路径匹配 `app/**/_actions/**/*.ts{,x}`
- 文件内含 `'use server'`
- 文件内含 `revalidateTag(`
- 文件内**不含** `fetch(`（排除真用 fetch 的场景）

由 `pl-rule-scan.sh` 自动执行，命中即写 `pl.rule_scan.completed` trace 事件。

## 参考

- [Next.js Caching docs](https://nextjs.org/docs/app/building-your-application/caching)
- retro-v2 B3 · 2026-04
