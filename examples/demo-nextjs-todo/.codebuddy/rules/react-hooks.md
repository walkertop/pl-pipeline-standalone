---
id: react-hooks
version: 1.0.0
frontmatter_added_by: backfill-v1.3
---

# Rule: React Hooks 使用规范

> **Scope**: on-demand（涉及 hooks 时加载）

## 核心规则（来自 React 官方）

1. **只在顶层调用**：不能在循环 / 条件 / 嵌套函数里调用 hook
2. **只在 React 函数里调用**：函数组件或自定义 hook 内
3. **自定义 hook 以 `use` 开头**

## `useState`

```tsx
// ✅ 简单状态
const [count, setCount] = useState(0)

// ✅ 对象 / 数组：用函数更新保证基于最新值
setItems(prev => [...prev, newItem])

// ❌ 把派生数据塞进 state
const [fullName, setFullName] = useState(first + ' ' + last)
// ✅ 用派生
const fullName = first + ' ' + last
```

## `useEffect`

**默认不要用**，90% 的 effect 都能用以下替代：

- 用户交互 → 事件处理
- 数据获取 → RSC / Server Action / SWR
- 订阅外部系统 → `useSyncExternalStore`
- 派生值 → 直接计算

只在**同步外部系统**时用：

```tsx
useEffect(() => {
  const id = setInterval(() => tick(), 1000)
  return () => clearInterval(id)
}, [])
```

### 依赖数组

- 所有引用的组件内变量都必须在依赖里
- 不能"骗"lint（`// eslint-disable-next-line`）—— 99% 是代码组织问题
- 对象 / 数组依赖用 `useMemo` 稳定化

## `useCallback` / `useMemo`

**默认不要用**。只在：

1. 传给 `React.memo` 组件做 props
2. 作为其他 hook 的依赖
3. 计算真的昂贵（> 1ms）

才考虑。过度用反而变慢（依赖比较也有开销）。

## `useContext`

- 别拿来做全局状态总线（会导致过度 re-render）
- 只放**真正稀疏变化**的数据（主题、国际化、当前用户）

## 自定义 hook

```tsx
// ✅ 组合内置 hooks
function useDebounce<T>(value: T, delay: number): T {
  const [debounced, setDebounced] = useState(value)
  useEffect(() => {
    const id = setTimeout(() => setDebounced(value), delay)
    return () => clearTimeout(id)
  }, [value, delay])
  return debounced
}
```

命名规约：
- `useX()`  描述提供的能力（`useUser`, `useDebounce`）
- 不以 `use` 开头的函数不能内部调 hook

## 常见坑

### 坑 1: 闭包过期

```tsx
// ❌ 定时器里 count 永远是创建时的值
useEffect(() => {
  setInterval(() => console.log(count), 1000)
}, [])

// ✅
useEffect(() => {
  const id = setInterval(() => console.log(count), 1000)
  return () => clearInterval(id)
}, [count])
```

### 坑 2: effect 连锁

```tsx
// ❌
useEffect(() => setFiltered(filter(items, q)), [items, q])

// ✅ 直接派生
const filtered = filter(items, q)
```

### 坑 3: `useMemo` 改变引用

```tsx
// ❌ 每次 render 都是新对象，下游 memo 全部失效
const options = { foo: 1 }

// ✅
const options = useMemo(() => ({ foo: 1 }), [])
```

## 参考

- https://react.dev/reference/react
- https://react.dev/learn/you-might-not-need-an-effect
