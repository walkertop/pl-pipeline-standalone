---
name: nextjs-data-fetching
triggers: ["fetch", "server action", "revalidate", "cache tag", "use cache"]
description: 数据获取、缓存失效与 Server Actions 完整手册
---

# 数据获取、缓存与 Server Actions

## 一、在 RSC 里 fetch

```tsx
export default async function Page() {
  const data = await fetch('https://api.example.com/items', {
    next: {
      tags: ['items'],         // 用于 revalidateTag('items')
      revalidate: 60,          // 60 秒后过期
    },
  }).then(r => r.json())

  return <ItemList items={data} />
}
```

### 缓存策略枚举

| 写法 | 缓存？ | 失效方式 |
|------|------|---------|
| `fetch(url)` | 默认 | 组件重渲染就重新 fetch（Next 15 起） |
| `fetch(url, { cache: 'force-cache' })` | ✅ 永久 | 手动 revalidateTag/Path |
| `fetch(url, { cache: 'no-store' })` | ❌ | 每次请求都 fetch |
| `fetch(url, { next: { revalidate: N } })` | ✅ N秒 | 到期 / 手动 |
| `fetch(url, { next: { tags: ['a'] } })` | ✅ | `revalidateTag('a')` |

## 二、直接查 DB（不经过 fetch）

```tsx
import { db } from '@/lib/db'
import { unstable_cache } from 'next/cache'

const getItems = unstable_cache(
  async () => await db.item.findMany(),
  ['items-all'],              // cache key
  { tags: ['items'], revalidate: 60 }
)

export default async function Page() {
  const items = await getItems()
  return ...
}
```

## 三、Server Actions

### 基本形态

```ts
// app/_actions/items.ts
'use server'

import { revalidateTag } from 'next/cache'
import { z } from 'zod'
import { db } from '@/lib/db'

const CreateSchema = z.object({
  name: z.string().min(1).max(100),
})

export async function createItem(formData: FormData) {
  const parsed = CreateSchema.safeParse({
    name: formData.get('name'),
  })
  if (!parsed.success) {
    return { ok: false, error: parsed.error.format() }
  }

  await db.item.create({ data: parsed.data })
  revalidateTag('items')      // 让 tag='items' 的缓存失效
  return { ok: true }
}
```

### 绑定到表单

```tsx
// Client 组件
'use client'
import { useFormState, useFormStatus } from 'react-dom'
import { createItem } from '@/app/_actions/items'

export function CreateForm() {
  const [state, formAction] = useFormState(createItem, { ok: null })
  return (
    <form action={formAction}>
      <input name="name" />
      <SubmitButton />
      {state.ok === false && <p>{JSON.stringify(state.error)}</p>}
    </form>
  )
}

function SubmitButton() {
  const { pending } = useFormStatus()
  return <button disabled={pending}>{pending ? 'Saving...' : 'Save'}</button>
}
```

## 四、失效 API 对比

| API | 粒度 | 场景 |
|-----|-----|-----|
| `revalidateTag('x')` | 所有带 tag='x' 的 fetch | 最推荐，细粒度 |
| `revalidatePath('/a/b')` | 某路径下所有缓存 | 路径驱动，粗粒度 |
| `redirect(...)` | 跳转 + 导航 | Action 结束后跳转 |

## 五、Route Handler 里的数据

```ts
// app/api/items/route.ts
export const revalidate = 60        // 路由级缓存控制

export async function GET() {
  const items = await db.item.findMany()
  return Response.json(items)
}
```

## 六、常见陷阱

### ❌ 在 Client 组件里 import 服务端 fetch 函数

```tsx
'use client'
import { getItems } from './server-fetch'  // 打包进客户端会暴露 API
```

**解决**：把它改写成 Server Action（有 `'use server'`），或用 Route Handler + SWR。

### ❌ 忘记 revalidate

Server Action 写了 DB 但没 `revalidateTag`，用户看到的还是旧数据。

### ❌ 无意义的 `cache: 'no-store'`

只在**真正不希望缓存**时才用。随手加上会让全站动态化，构建变慢。

### ❌ 在 RSC 里调用自己的 API Route

```tsx
// ❌ 绕了一圈 HTTP
const data = await fetch(`${process.env.URL}/api/items`)

// ✅ 直接调 DB 或 data layer 函数
const data = await getItems()
```

## 七、性能建议

1. **并行 fetch**：用 `Promise.all([fetch(A), fetch(B)])`，避免瀑布
2. **Streaming**：用 `<Suspense>` 包慢的部分，让快的先渲染
3. **`loading.tsx`**：给 route 级加载状态
4. **Partial Prerendering**（Next 14.1+ 实验）：静态外壳 + 动态洞

## 参考

- https://nextjs.org/docs/app/building-your-application/caching
- https://nextjs.org/docs/app/building-your-application/data-fetching/server-actions-and-mutations
