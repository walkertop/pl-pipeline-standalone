# Adapter Manifest Reference

> `adapter.yaml` 每个字段的权威定义。本文是 `adapter-manifest.schema.json`
> 的人类可读版本，两者互为事实源——任何字段变动需同时更新。

---

## 顶层结构

| 字段 | 类型 | 必填 | 说明 |
|---|---|---|---|
| `apiVersion` | string | ✅ | 固定值 `pl.dev/v1` |
| `kind` | string | ✅ | 固定值 `Adapter` |
| `metadata` | object | ✅ | 见 §1 |
| `provides` | object | ✅ | 见 §2 |
| `requires` | object | ❌ | 见 §3 |
| `piao_emit` | object | ❌ | 见 §4 |

---

## §1 metadata

### 1.1 基本字段

| 字段 | 类型 | 必填 | 说明 | 示例 |
|---|---|---|---|---|
| `id` | string | ✅ | 机器 ID，kebab-case，匹配 `^[a-z][a-z0-9-]*$` | `nextjs-web` / `python-fastapi` |
| `name` | string | ❌ | 人类可读名称 | `Next.js Web Project` |
| `description` | string | ❌ | 一段话简介 | `Next.js App Router + RSC + TS` |
| `version` | string | ✅ | adapter 自己的 semver（独立于 pl-core 版本） | `0.1.0` |
| `compatible_pl` | string | ✅ | pl-core 兼容范围（semver range） | `>=1.0.0 <2.0.0` |
| `compatible_piao` | string | ❌ | piao-kernel 兼容范围；省略即不依赖 piao | `>=0.1.0` |
| `authors` | array | ❌ | 作者/维护者列表 | 见 §1.2 |
| `license` | string | ❌ | SPDX ID，默认 `Apache-2.0` | `MIT` |
| `homepage` | string | ❌ | 主页 URL | |

### 1.2 authors 结构

```yaml
authors:
  - name: walker
    email: bin5211bin@gmail.com
    url: https://github.com/walkertop
```

### 1.3 detect 规则

用于 `pl init --smart` 自动推荐 adapter。规则是 **OR 关系**（任一命中即匹配）。

支持的规则类型：

| 类型 | 字段 | 说明 | 示例 |
|---|---|---|---|
| 文件存在 | `file_exists: <glob>` | 相对宿主项目根 | `next.config.js` |
| package.json 依赖 | `package_json_has: <key>` | 查 dependencies/devDependencies | `next` |
| pyproject.toml 依赖 | `pyproject_has: <key>` | 查 project.dependencies 或 poetry 节 | `fastapi` |
| Gradle 依赖 | `gradle_has: <pattern>` | 查 build.gradle(.kts) 文本匹配 | `kotlin-multiplatform` |
| Cargo 依赖 | `cargo_has: <crate>` | 查 Cargo.toml dependencies 节 | `axum` |
| go.mod 依赖 | `go_mod_has: <module>` | 查 go.mod | `github.com/gin-gonic/gin` |

**示例**：

```yaml
metadata:
  detect:
    - file_exists: "next.config.js"
    - file_exists: "next.config.ts"
    - package_json_has: "next"
```

---

## §2 provides

adapter 向宿主项目**注入**的资产。这是 adapter 作为"全家桶"的核心节。

### 2.1 templates

覆盖 pl-core 的 7 件标准产物模板。**键名必须匹配 pl-core**。

| 键 | 说明 | 是否建议覆盖 |
|---|---|---|
| `spec` | SPEC 阶段产物模板 | ✅ 强烈建议 |
| `plan` | PLAN 阶段产物模板 | ✅ 强烈建议 |
| `taskdag` | 任务 DAG 模板 | ✅ 强烈建议 |
| `api` | API 契约模板 | 🟡 视场景 |
| `testmatrix` | 测试矩阵模板 | 🟡 视场景 |
| `deps` | 依赖分析模板 | 🟡 视场景（迁移类 change 建议覆盖） |
| `state` | .state.md 真相源模板 | ❌ 不建议覆盖（属于 pl-core 契约） |
| `confirmation` | 确认提示模板 | ❌ 不建议覆盖 |

值是**相对 adapter 根目录**的路径：

```yaml
provides:
  templates:
    spec: "templates/spec.md"
    plan: "templates/plan.md"
    taskdag: "templates/taskdag.md"
```

### 2.2 agents

AI agent prompt 文件。

```yaml
provides:
  agents:
    - path: "agents/nextjs-architect.md"
      id: nextjs-architect                # 可选，默认 = filename stem
      ide_support: [codebuddy, cursor]    # 可选，默认所有 IDE
      description: "Next.js App Router 架构师"
```

`ide_support` 枚举：`codebuddy` / `cursor` / `claude-code` / `codex`

### 2.3 skills

技能文件。

```yaml
provides:
  skills:
    - id: react-server-components
      path: "skills/react-server-components.md"
      triggers: ["rsc", "server component", "use server"]
      description: "React Server Components 使用指南"
```

`triggers` 用于 IDE adapter 的 skill 自动推荐。

### 2.4 rules

编码规范。

```yaml
provides:
  rules:
    - id: typescript-strict
      path: "rules/typescript-strict.md"
      scope: always                       # always | on-demand
      description: "TypeScript 严格模式要求"
```

`scope` 语义：

| 值 | 含义 |
|---|---|
| `always` | 每次 AI 对话都加载（如"命名规范"/"导入顺序") |
| `on-demand` | 用户或 agent 显式请求时加载（如"用到 SQL 时"） |

### 2.5 scripts

adapter 提供的 shell 脚本。

```yaml
provides:
  scripts:
    build:  "scripts/build.sh"
    verify: "scripts/verify.sh"
    lint:   "scripts/lint.sh"
    deploy: "scripts/deploy.sh"
    # 自定义脚本（任意 key 名）：
    migrate-db: "scripts/migrate-db.sh"
```

四个**标准键**（`build` / `verify` / `lint` / `deploy`）会被 pl-core 相关
命令调用。自定义脚本在宿主中命名为 `adapter-<id>-<key>.sh`。

### 2.6 build_adapter

定义 adapter 向宿主注入的**构建命令**。这是 pl-core 的 `$PL_BUILD_CHECK_CMD`
和未来 BuildAdapter 协议的填充源。

```yaml
provides:
  build_adapter:
    type: npm                    # 枚举: npm|pnpm|yarn|gradle|maven|cargo|
                                 #       go|uv|pip|poetry|make|xcodebuild|custom
    commands:
      compile_check:
        cmd: "npm run typecheck"
        success_pattern: "Found 0 errors"
        timeout_sec: 180
      lint: "npm run lint"       # 简写形式
      test: "npm test -- --ci"
      full_build:
        cmd: "npm run build"
        timeout_sec: 600
```

**command 两种写法**：

- **简写**（string）：整串都是命令
  ```yaml
  lint: "npm run lint"
  ```
- **完整**（object）：带成功/失败模式、超时、工作目录
  ```yaml
  compile_check:
    cmd: "npm run typecheck"
    success_pattern: "Found 0 errors"
    failure_patterns: ["error TS[0-9]+"]
    timeout_sec: 180
    working_dir: "."
  ```

---

## §3 requires

宿主项目环境需要满足的条件。`pl doctor` 命令会检查。

```yaml
requires:
  tools:
    - name: node
      min_version: "18"
      install_hint: "brew install node 或 nvm install 18"
    - name: npm
      min_version: "9"
  files:
    - package.json
    - tsconfig.json
```

| 字段 | 类型 | 说明 |
|---|---|---|
| `tools[].name` | string | 命令名（用 `command -v` 检测） |
| `tools[].min_version` | string | 最低 semver |
| `tools[].install_hint` | string | 人类可读安装提示 |
| `files[]` | string | 项目根下必须存在的文件/目录 |

---

## §4 piao_emit

配置 adapter 向 piao kernel-events 写 L1 事件。**省略则 adapter 不参与 piao 追溯**。

```yaml
piao_emit:
  on_stages: [VERIFY, ARCHIVE]
  urn_namespace: "urn:piao:artifact:pl:nextjs-web"
```

| 字段 | 类型 | 说明 |
|---|---|---|
| `on_stages[]` | array | 在哪些 pl-core 阶段切换时发事件。枚举：SPEC/PLAN/IMPLEMENT/VERIFY/OBSERVE/ARCHIVE |
| `urn_namespace` | string | URN 前缀。必须匹配 `^urn:piao:<kind>:pl:<id>$` 格式 |

**推荐默认值**：
- `on_stages: [VERIFY, ARCHIVE]`（其他阶段事件数量太大，`VERIFY` / `ARCHIVE`
  才是真正"封板"时点）
- `urn_namespace: "urn:piao:artifact:pl:<adapter-id>"`

---

## §5 完整最小可用样例

```yaml
# adapters/adapter-rust-axum/adapter.yaml
apiVersion: pl.dev/v1
kind: Adapter

metadata:
  id: rust-axum
  name: Rust + Axum 后端项目
  description: Rust + Axum + Tokio + SQLx 后端研发流水线
  version: 0.1.0
  compatible_pl: ">=1.0.0 <2.0.0"
  license: Apache-2.0
  authors:
    - name: walker
      email: bin5211bin@gmail.com
  detect:
    - file_exists: "Cargo.toml"
    - cargo_has: "axum"

provides:
  templates:
    spec: "templates/spec.md"
    plan: "templates/plan.md"
    taskdag: "templates/taskdag.md"
  agents:
    - path: "agents/rust-axum-architect.md"
      description: "Rust+Axum 后端架构师"
    - path: "agents/rust-api-reviewer.md"
  skills:
    - id: axum-patterns
      path: "skills/axum-patterns.md"
      triggers: ["axum", "handler", "extractor"]
    - id: sqlx-async
      path: "skills/sqlx-async.md"
      triggers: ["sqlx", "query_as", "transaction"]
  rules:
    - path: "rules/rust-api-design.md"
      scope: always
    - path: "rules/rust-error-handling.md"
      scope: always
  scripts:
    build:  "scripts/build.sh"
    verify: "scripts/verify.sh"
    lint:   "scripts/lint.sh"
  build_adapter:
    type: cargo
    commands:
      compile_check:
        cmd: "cargo check"
        success_pattern: "Finished"
        timeout_sec: 300
      test: "cargo test"
      lint: "cargo clippy -- -D warnings"
      full_build:
        cmd: "cargo build --release"
        timeout_sec: 900

requires:
  tools:
    - name: cargo
      min_version: "1.70"
      install_hint: "https://rustup.rs"
    - name: rustc
      min_version: "1.70"

piao_emit:
  on_stages: [VERIFY, ARCHIVE]
  urn_namespace: "urn:piao:artifact:pl:rust-axum"
```

---

## §6 校验

任何改动 adapter.yaml 后都应执行：

```bash
bash scripts/adapter-validate.sh adapters/adapter-<id>
```

该脚本做三件事：
1. JSON Schema 语法校验（按 `adapter-manifest.schema.json`）
2. `provides.*.path` 引用的文件真实存在
3. `requires.files` 在占位配置下合理（adapter 包内自检，不检查目标项目）

---

## §7 版本演进

| apiVersion | 发布 | 关键变化 |
|---|---|---|
| `pl.dev/v1` | 2026-04-21 | 首版定义 |

未来新版本会通过 `apiVersion: pl.dev/v2` 表达，v1 adapter 保持兼容。
