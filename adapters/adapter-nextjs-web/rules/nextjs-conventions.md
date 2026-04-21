# Rule: Next.js Conventions

> **Scope**: always
> **适用**: 本仓库所有 `app/**` 路由

## 文件命名

| 文件 | 用途 | 强制 |
|------|-----|-----|
| `page.tsx` | 路由入口 | ✅ |
| `layout.tsx` | 嵌套布局 | - |
| `loading.tsx` | Suspense fallback | - |
| `error.tsx` | 错误边界（`'use client'`） | - |
| `not-found.tsx` | 404 | - |
| `_components/` | **路由私有**组件（下划线前缀不会成为路由） | 推荐 |
| `_actions/` | **路由私有** Server Actions | 推荐 |

## Server / Client 边界

1. **默认 RSC**：不加 `'use client'`
2. **下沉 Client**：`'use client'` 放在叶子节点，不放在 layout/page 顶层
3. **组合优先于继承**：
   ```tsx
   // ✅ Client 包 Server
   <ClientModal>
     <ServerContent />
   </ClientModal>
   ```

## 数据获取

### RSC 里用 `async` 组件

```tsx
export default async function Page() {
  const data = await fetchData()
  return <Render data={data} />
}
```

### 不要在 Client 组件里直连 DB

走 Server Action 或 Route Handler。

### Cache tag 命名

- kebab-case
- 与领域对象对齐：`items`, `users`, `orders-recent`
- 参数化时用冒号：`item:${id}`, `user:${id}:sessions`

### 失效必须显式

```ts
'use server'
export async function action(...) {
  await db.insert(...)
  revalidateTag('items')          // ← 必写
  // 或 revalidatePath('/items')
}
```

## Metadata

每个可对外访问的 `page.tsx` 都应有：

```tsx
export const metadata = {
  title: '...',
  description: '...',
}
// 或 export async function generateMetadata() { ... }
```

## 导入顺序

```tsx
// 1. 外部
import { useState } from 'react'
import { redirect } from 'next/navigation'

// 2. 别名（绝对）
import { db } from '@/lib/db'
import { Button } from '@/components/ui/button'

// 3. 相对
import { SubForm } from './_components/SubForm'
```

## 环境变量

- 服务端：`process.env.FOO`（任何时候都可访问）
- 客户端：必须加前缀 `NEXT_PUBLIC_FOO`
- 变更 env 后重启 dev server

## 禁忌

- ❌ 在 Client 组件 import 服务端模块（Next 会编译失败或把它发到浏览器）
- ❌ 在 RSC 使用 hooks（`useState` 等）
- ❌ 在 Server Action 文件省略 `'use server'`
- ❌ `export const dynamic = 'force-dynamic'` 滥用（会让全路由每次请求都渲染）
- ❌ 把 `layout.tsx` 标成 `'use client'`（丢掉整棵树的 SSR 优势）
