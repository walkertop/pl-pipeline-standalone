# Rule: TypeScript Strict Mode

> **Scope**: always
> **适用**: 本仓库所有 `.ts` / `.tsx` 文件

## 硬性要求

`tsconfig.json` 必须包含：

```json
{
  "compilerOptions": {
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "noImplicitOverride": true,
    "noFallthroughCasesInSwitch": true,
    "forceConsistentCasingInFileNames": true
  }
}
```

## 编码约束

### 1. 禁用 `any`

```tsx
// ❌ 禁止
function fetch(url: any): any { ... }

// ✅ 首选明确类型
function fetch(url: string): Promise<Item[]> { ... }

// ✅ 无法确定时用 unknown + 类型守卫
function parse(data: unknown): Item {
  if (typeof data === 'object' && data !== null && 'id' in data) { ... }
}
```

**例外**：与第三方无类型库交互时，仅在 import 那一刻用 `any`，立刻 narrowing 到领域类型。

### 2. 非空断言慎用

```ts
// ❌ 尽量避免
const user = users.find(u => u.id === id)!

// ✅ 显式处理
const user = users.find(u => u.id === id)
if (!user) throw new Error('user not found')
```

### 3. Props 必须显式

```tsx
// ❌
export function Card(props) { ... }

// ✅
interface CardProps {
  title: string
  description?: string
  onClick: () => void
}
export function Card({ title, description, onClick }: CardProps) { ... }
```

### 4. 可辨识联合（Discriminated Unions）用于状态

```ts
type Result<T> =
  | { ok: true; data: T }
  | { ok: false; error: string }

function handle(r: Result<Item>) {
  if (r.ok) return r.data   // 自动 narrow
  console.error(r.error)
}
```

### 5. 避免 `object` / `Function`

用具体形态：

```ts
// ❌
const config: object = ...

// ✅
interface Config { port: number; host: string }
```

### 6. Enum vs Union

- **首选** 字符串字面量联合：`type Role = 'admin' | 'user' | 'guest'`
- **enum** 仅在需要反向映射 / 值用于运行时序列化时

### 7. Async 必标 Promise

```ts
// ❌ 含糊
async function load() { return fetch(...) }

// ✅
async function load(): Promise<Item[]> { ... }
```

### 8. Server Action 返回类型固定

```ts
type ActionResult<T> =
  | { ok: true; data: T }
  | { ok: false; error: string; fieldErrors?: Record<string, string[]> }

export async function createItem(input: Input): Promise<ActionResult<Item>> { ... }
```

## 格式化

- 2 空格缩进
- 单引号 `'`
- 尾逗号 `all`
- 行宽 `100`

用 `prettier`，配在 `.prettierrc` 里，不额外讨论。

## 引用

- https://www.typescriptlang.org/tsconfig
- https://www.totaltypescript.com/tsconfig-cheat-sheet
