# TaskDAG: [变更名称]

> **模板版本**: v0.1 (adapter-nextjs-web)
> **执行节拍**: IMPLEMENT 阶段按依赖顺序逐项完成

---

## 任务列表

| ID | 任务 | 类型 | 依赖 | 产物 | 预估 |
|----|-----|------|-----|-----|------|
| T01 | 创建 route segment 骨架（`page.tsx` + `layout.tsx`） | scaffold | - | `app/<route>/page.tsx` | 15m |
| T02 | 定义 TypeScript 类型（Props / API 响应） | types | T01 | `app/<route>/types.ts` | 15m |
| T03 | RSC 数据获取（`fetch` + cache tag） | rsc | T02 | page.tsx 内 `async function Page()` | 30m |
| T04 | 服务端 UI（纯展示 RSC 组件） | ui-server | T03 | `_components/*.tsx` | 1h |
| T05 | 客户端交互组件（`'use client'`） | ui-client | T04 | `_components/Interactive*.tsx` | 1h |
| T06 | Server Action 实现 | action | T03 | `_actions/*.ts` | 45m |
| T07 | 表单绑定 Action + `useFormState` | integration | T05, T06 | Client 组件 | 30m |
| T08 | `loading.tsx` / `error.tsx` 兜底 | resilience | T04 | 同名文件 | 15m |
| T09 | `generateMetadata` 实现 SEO | seo | T03 | page.tsx | 15m |
| T10 | Playwright E2E 测试 | test | T07 | `e2e/<route>.spec.ts` | 45m |
| T11 | Lighthouse 性能达标 | perf | T07 | CI artifact | 30m |

---

## 依赖图

```
T01 ──▶ T02 ──▶ T03 ──▶ T04 ──▶ T05 ──┐
                   │                   ├──▶ T07 ──▶ T10
                   └──▶ T06 ───────────┘
                   │
                   └──▶ T08
                   └──▶ T09
                                            T07 ──▶ T11
```

---

## 执行指引

- 每完成一个任务，在 `.state.md` 更新 `<last_task_done>`
- 若 T03/T06 涉及新 API，先填 `api.md` 再开工
- T10/T11 属于 VERIFY 阶段硬门禁
