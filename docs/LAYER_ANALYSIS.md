# Layer 分析：pl-pipeline 的抽象边界

> **目的**：深入分析 Layer 2（需要抽象的协议）和 Layer 3（需要 Preset 化的项目特定资产），给出具体的接口设计和迁移路径。
>
> **本文是 [`MIGRATION_CHECKLIST.md`](../MIGRATION_CHECKLIST.md) 的补充**，重点回答**"怎么抽象"**，而不是"抽哪些"。
>
> **版本**：v0.1（2026-04-21）

---

## 总览：为什么要分层

pl-pipeline 要成为可复用的开源工具，核心挑战是**"通用"和"具体"的平衡**：
- **过于通用** → 接入需要大量配置，没人愿意用
- **过于具体** → 只能给某一类项目用，失去开源价值

**我们的策略：四层清晰分离**

```
┌─────────────────────────────────────────────────────────┐
│ Layer 0: 引擎（100% 通用）                              │
│   State Machine / Gates / Schemas / Templates           │
│   ← 所有用户完全相同，开箱即用                          │
├─────────────────────────────────────────────────────────┤
│ Layer 1: CLI/UI（98% 通用）                             │
│   Commands / Prompts / Dashboard                        │
│   ← 仅语言/格式差异，通过 i18n 和模板占位符化           │
├─────────────────────────────────────────────────────────┤
│ Layer 2: 适配协议（40% 通用）                           │
│   Build / Trace / VCS / Policy / IDE                    │
│   ← 通过 Adapter Pattern 让每个用户注入自己的实现       │
├─────────────────────────────────────────────────────────┤
│ Layer 3: 项目知识（0% 通用）                            │
│   Rules / Skills / Agents / 业务规则                    │
│   ← 完全分离到 Preset 包，用户按需组合                  │
└─────────────────────────────────────────────────────────┘
```

**核心原则**：
> Layer 0-1 是 pl-pipeline 的"内核"；
> Layer 2 是"驱动层"（像 Linux 的 driver，让内核适配不同硬件）；
> Layer 3 是"应用层"（用户自己的业务、自己的 preset）。

---

# Part 1：Layer 2 抽象协议详解

## 1. Build Adapter 协议

### 1.1 问题定义

当前 `migration-verify.sh` 的第 42 行写死了：
```bash
./gradlew :shared:compileDebugKotlinAndroid
```

这让 pl-pipeline **只能用于 Gradle 项目**。我们要让 Python / Node / Rust / Go / Make 项目都能用。

### 1.2 接口设计

```typescript
// packages/core/src/adapters/build.ts

/**
 * Build Adapter 协议。
 * 每个构建工具（Gradle / npm / Cargo / Go / Make）提供一个实现。
 */
export interface BuildAdapter {
  /** 唯一标识 */
  readonly id: string

  /** 构建工具版本（可选，用于诊断） */
  getToolVersion?(): Promise<string>

  /** 编译检查（不产出产物，只验证能否编译通过） */
  compileCheck(options?: BuildOptions): Promise<BuildResult>

  /** 静态检查（lint） */
  lint?(options?: BuildOptions): Promise<LintResult>

  /** 运行测试 */
  test?(options?: BuildOptions): Promise<TestResult>

  /** 完整构建（产出产物） */
  fullBuild?(options?: BuildOptions): Promise<BuildResult>

  /** 变更感知：检测是否需要触发构建（用于 should-build 逻辑） */
  shouldBuild?(changedFiles: string[]): Promise<boolean>
}

export interface BuildOptions {
  /** 限制作用域（Gradle 的 :shared 模块、npm 的 --workspace） */
  scope?: string
  /** 额外环境变量 */
  env?: Record<string, string>
  /** 超时（秒） */
  timeoutSec?: number
}

export interface BuildResult {
  success: boolean
  durationMs: number
  stdout: string
  stderr: string
  errors: BuildError[]
  warnings: BuildError[]
}

export interface BuildError {
  file?: string
  line?: number
  column?: number
  severity: 'error' | 'warning'
  message: string
  raw: string  // 原始输出行
}
```

### 1.3 内置实现

| ID | 文件 | 示例 config |
|---|---|---|
| `gradle` | `packages/core/src/adapters/build/gradle.ts` | 见下 |
| `npm` | `npm.ts` | `cmd: "npm run build"` |
| `pnpm` | `pnpm.ts` | `cmd: "pnpm build"` |
| `yarn` | `yarn.ts` | `cmd: "yarn build"` |
| `cargo` | `cargo.ts` | `cmd: "cargo check"` |
| `go` | `go.ts` | `cmd: "go build ./..."` |
| `make` | `make.ts` | `cmd: "make check"` |
| `custom` | `custom.ts` | 完全自定义命令 |

### 1.4 用户配置

`pl/adapters/build.yaml`（由 `pl init --smart` 自动生成）：

```yaml
adapter: gradle
config:
  wrapper: "./gradlew"        # 默认 ./gradlew；Windows 下 gradlew.bat
  timeout_sec: 300

commands:
  compile_check:
    task: ":shared:compileDebugKotlinAndroid"
    success_pattern: "BUILD SUCCESSFUL"
    failure_patterns:
      - "^e:"
      - "error:"
      - "^\\* What went wrong"

  lint:
    task: "detekt"

  test:
    task: "test"

  full_build:
    task: "build"

# 变更感知阈值（复刻现有 should-build.sh 的逻辑）
should_build:
  new_files_threshold: 3
  total_files_threshold: 5
  lines_threshold: 200
  include_globs:
    - "src/**/*.kt"
    - "shared/**/*.kt"
  exclude_globs:
    - "**/test/**"
    - "**/*.md"
```

### 1.5 迁移映射

| 现有 Bash 脚本 | 新的 TS 实现 |
|---|---|
| `should-build.sh` | `BuildAdapter.shouldBuild()` |
| `migration-verify.sh` 的编译节 | `BuildAdapter.compileCheck()` |
| `migration-verify.sh` 的 lint 节 | `BuildAdapter.lint()` |
| `build-android.sh` / `build-ios.sh` / `build-all.sh` | 留在宿主项目（业务特定） |

---

## 2. Trace Backend 协议

### 2.1 问题定义

现在 trace 写死为 JSONL 文件：
```bash
# scripts/trace-emit.sh
echo "$json_event" >> pipeline-output/trace/${change}.events.jsonl
```

这对小团队够用，但企业用户可能想：
- 写到 OpenTelemetry Collector
- 写到 DataDog / Grafana Loki
- 通过 Webhook 上报自建系统
- 完全禁用（CI 环境）

### 2.2 接口设计

```typescript
// packages/core/src/adapters/trace.ts

export interface TraceBackend {
  readonly id: string

  /** 发送单个事件（异步） */
  emit(event: TraceEvent): Promise<void>

  /** 批量发送（性能优化） */
  emitBatch?(events: TraceEvent[]): Promise<void>

  /** 查询历史事件（用于 Report 生成） */
  query(filter: TraceFilter): Promise<TraceEvent[]>

  /** 关闭（flush 剩余事件） */
  close(): Promise<void>
}

export interface TraceEvent {
  /** 事件 ID（ULID，时序可排序） */
  id: string

  /** 事件时间戳（毫秒） */
  timestamp: number

  /** 关联的 change */
  changeId: string

  /** 阶段 */
  stage: Stage

  /** 事件类型 */
  type: 'stage_enter' | 'stage_exit' | 'gate_check' | 'task_complete' | 'error' | 'custom'

  /** 事件载荷 */
  payload: Record<string, unknown>

  /** 产生事件的角色（cli / orchestrator / hook / agent） */
  source: string
}

export interface TraceFilter {
  changeId?: string
  stage?: Stage
  type?: TraceEvent['type']
  since?: number
  until?: number
  limit?: number
}
```

### 2.3 内置实现

| ID | 说明 | 配置 |
|---|---|---|
| `jsonl` | 默认，写本地 JSONL 文件 | `output_dir: "pipeline-output/trace"` |
| `otel` | OpenTelemetry Collector | `endpoint: "http://localhost:4318"` |
| `http-webhook` | POST 到外部服务 | `url: "https://your-service.com/pl-events"` |
| `noop` | 禁用 trace（CI 常用） | - |

### 2.4 用户配置

```yaml
# pl/adapters/trace.yaml
backend: jsonl
config:
  output_dir: "pipeline-output/trace"
  file_pattern: "{{change}}.events.jsonl"

# 可配置多后端并行（fanout）
# backends:
#   - id: jsonl
#     output_dir: "pipeline-output/trace"
#   - id: otel
#     endpoint: "http://otel-collector:4318"
#   - id: http-webhook
#     url: "https://monitoring.company.com/events"
```

### 2.5 Report 生成器

独立包 `packages/reporter/`：
- 读取 `TraceEvent[]`（通过 `TraceBackend.query()`）
- 渲染 React 静态页面（Gantt 图 + 时间线 + 详情）
- 输出 `pipeline-output/trace/<change>.report.html`

---

## 3. VCS Adapter 协议

### 3.1 问题定义

pl-pipeline 现在硬编码 git：
```bash
git -c core.hooksPath=/dev/null commit -m "..."
```

虽然 git 覆盖 99% 场景，但：
- 腾讯内部有些团队用 SVN
- Facebook 用 Mercurial
- 最新流行 Jujutsu (jj)
- 还有 GitOps 场景需要自定义

### 3.2 接口设计

```typescript
// packages/core/src/adapters/vcs.ts

export interface VCSAdapter {
  readonly id: string

  /** 提交 */
  commit(message: string, options?: CommitOptions): Promise<CommitResult>

  /** 当前分支 */
  currentBranch(): Promise<string>

  /** 最近 N 次 commit */
  recentCommits(n: number): Promise<Commit[]>

  /** 已修改文件列表（未 add + 已 add） */
  status(): Promise<VCSStatus>

  /** 推送到远端 */
  push?(remote?: string, branch?: string): Promise<void>

  /** 装 hooks（git 的 pre-commit / commit-msg） */
  installHooks?(hooks: HookSpec[]): Promise<void>
}

export interface CommitOptions {
  files?: string[]              // 只提交这些文件
  amend?: boolean               // 修改上一次 commit
  skipHooks?: boolean           // 跳过 hooks（谨慎使用）
  signoff?: boolean             // -s 签名
  coAuthors?: string[]          // Co-authored-by
}

export interface Commit {
  sha: string
  author: string
  email: string
  timestamp: number
  subject: string
  body?: string
}
```

### 3.3 Commit Message 规范

每个 VCSAdapter 自己不管 message 格式。**格式规范**走独立 Policy：

```yaml
# pl/adapters/vcs.yaml
provider: git

commit_policy:
  template: "{{type}}({{scope}}): {{subject}}"
  types: [feat, fix, docs, refactor, test, chore, perf]
  scopes: [core, ui, data, build, ci]
  max_subject_length: 72
  require_body_for: [feat, refactor]
  footer_template: |
    Closes #{{issue}}
    Signed-off-by: {{author}}
```

---

## 4. Quality Policy（黑名单/必需模式）

### 4.1 问题定义

现在黑名单散落在 `taskdag.md` 各个 Task 的"验收"小节：
```markdown
**验收**:
- **不含** `prop` / `quality` / `currentMode` / `pinNo` / `pintuan_*`
- **不含** 任何自建 `class RoleModel`
```

每次 verify 时需要手动 grep。问题：
1. 散落，统一维护困难
2. 无法被工具自动读取
3. 无法被其他项目复用

### 4.2 统一 Policy 文件

```yaml
# pl/policy.yaml

# 全局黑名单（整个项目永远不允许出现）
blacklist:
  - id: no-console-log
    pattern: "console\\.log"
    severity: warning
    reason: "生产代码不应使用 console.log"
    exempt:
      - "**/*.test.ts"
      - "src/debug/**"
    message: "Please use the project logger instead"

# 按变更定制（可从 taskdag.md 自动提取）
change_blacklist:
  prop-confirm-migration:
    - id: no-pintuan
      pattern: "pintuan"
      severity: error
      reason: "拼团 v2.1 已下线"
    - id: no-stamps-payin-cfm
      pattern: "isStampsPayInCFM"
      severity: error
      exempt: ["**/CouponEligibility.kt"]
      reason: "已收敛到 CouponEligibility 决策器"

# 必需模式（特定位置必须出现）
required_patterns:
  - id: data-class-serializable
    pattern: "@Serializable"
    in: "src/**/data/**.kt"
    description: "数据类必须可序列化"

# 门禁检查（各门禁的机械校验项）
gates:
  A0:                           # SPEC → PLAN
    checks:
      - type: artifact_exists
        paths: [spec.md]
      - type: spec_validation
        schema: spec.schema.json

  C:                            # IMPLEMENT 内部门禁
    checks:
      - type: all_tasks_done
      - type: compile
        adapter: build
      - type: blacklist_empty

  D:                            # IMPLEMENT → VERIFY
    checks:
      - type: gate_c_passed
      - type: lint_clean
```

### 4.3 Policy Engine

```typescript
// packages/core/src/policy/engine.ts

export class PolicyEngine {
  constructor(policyPath: string)

  /** 对特定变更跑黑名单检查 */
  async checkBlacklist(changeId: string, projectRoot: string): Promise<PolicyViolation[]>

  /** 跑所有必需模式检查 */
  async checkRequired(projectRoot: string): Promise<PolicyViolation[]>

  /** 检查某个门禁 */
  async checkGate(gate: Gate, context: GateContext): Promise<GateResult>
}
```

---

## 5. IDE Adapter 协议

### 5.1 接口设计

```typescript
// packages/core/src/adapters/ide.ts

export interface IDEAdapter {
  readonly id: string

  readonly capabilities: {
    supportsSlashCommands: boolean
    supportsMCP: boolean
    supportsRules: boolean
    supportsAgents: boolean
  }

  /** 安装：在目标项目生成 IDE 特定的配置文件 */
  install(projectRoot: string, options: InstallOptions): Promise<InstallReport>

  /** 升级：pl-pipeline 版本变更后同步 */
  upgrade(projectRoot: string, from: string, to: string): Promise<void>

  /** 卸载 */
  uninstall(projectRoot: string): Promise<void>
}
```

### 5.2 Adapter 实现对照

| Adapter | 生成文件 | 更新策略 |
|---|---|---|
| `@pl/adapter-codebuddy` | `.codebuddy/commands/pl/*.md` | 覆盖 |
| `@pl/adapter-cursor` | `.cursor/rules/pl-*.mdc` | 覆盖 |
| `@pl/adapter-claude-code` | `.claude/commands/pl/*.md` | 覆盖 |
| `@pl/adapter-codex` | `AGENTS.md`（追加段落） | 增量合并 |
| `@pl/mcp-server` | 无（通过 MCP 协议提供） | - |

### 5.3 为什么 MCP 是优选

**MCP（Model Context Protocol）** 是 Anthropic 推出的标准协议：
- Claude Code / Cursor / CodeBuddy / Cline 等 IDE 都在支持
- 一次开发，所有兼容 IDE 自动受益
- 不用为每个 IDE 维护一份命令模板

**MCP Server 示意**：
```typescript
// packages/mcp-server/src/index.ts

const server = new McpServer({ name: "pl-pipeline" })

server.addTool({
  name: "pl_proposal",
  description: "Create a new change proposal with Spec",
  inputSchema: {
    type: "object",
    properties: {
      changeId: { type: "string" },
      description: { type: "string" }
    },
    required: ["changeId"]
  },
  handler: async (args) => {
    return await plCore.proposal(args.changeId, { description: args.description })
  }
})

server.addResource({
  uri: "pl://changes/",
  name: "Changes",
  description: "All changes in the project"
})
```

---

# Part 2：Layer 3 Preset 化详解

## 6. 为什么要 Preset

Layer 3 资产（rules / skills / agents）有两个特点：
1. **高度项目/栈特定**：kuikly 的 rule 对非 Kuikly 项目毫无价值
2. **但内部仍有通用性**：Kotlin 编码规范对所有 Kotlin 项目通用

**Preset 是解决"部分通用"的工具**：把"某一类项目都需要的资产"打包成独立 npm 包，让用户按需组合。

---

## 7. Preset 的格式规范

### 7.1 Preset 目录结构

```
@pl/preset-kotlin-kmm/                     ← npm 包
├── preset.yaml                            ← 元信息
├── rules/
│   ├── kotlin-coding-standards.md
│   ├── serialization-rules.md
│   └── kmm-architecture.md
├── skills/
│   ├── kotlin-code-review.md
│   └── kotlin-serialization.md
├── agents/
│   └── kotlin-code-reviewer.md
├── templates/                             ← 可选：覆盖默认模板
│   └── spec.md                            ← 替换 pl-core 的 spec.md
├── adapters/
│   └── build.yaml                         ← Gradle 默认配置
├── examples/
│   └── sample-change/                     ← 一个完整的 change 示例
├── package.json
└── README.md
```

### 7.2 `preset.yaml` 规范

```yaml
# schema: https://pl-pipeline.dev/schemas/preset.schema.json
apiVersion: pl-pipeline/v1
kind: Preset

metadata:
  id: kotlin-kmm
  name: "Kotlin Multiplatform"
  version: 1.0.0
  author: "Tencent / @guobin"
  description: "Preset for Kotlin Multiplatform projects"
  category: official           # official / community
  license: Apache-2.0
  homepage: https://github.com/your-org/pl-pipeline-presets
  keywords: [kotlin, kmm, android, ios]

# 技术栈要求
requires:
  languages: [kotlin]
  build_tools: [gradle]
  frameworks:
    any_of: [kotlin-multiplatform, kotlin-native]

# 冲突声明
conflicts_with:
  - android-only
  - ios-swift-ui

# 本 preset 贡献的资产
contributes:
  rules:
    - rules/kotlin-coding-standards.md
    - rules/serialization-rules.md
  skills:
    - skills/kotlin-code-review.md
  agents:
    - agents/kotlin-code-reviewer.md
  templates:
    spec: templates/spec.md      # 可选：覆盖默认 spec.md
  adapters:
    build: adapters/build.yaml
  policy:
    - policies/kotlin-blacklist.yaml

# 默认配置覆盖
config_overrides:
  gates:
    C:
      checks:
        - type: kotlin_binary_compat_check

# 初始化钩子（preset 安装时执行）
install_hooks:
  - type: prompt
    message: "是否需要 Android + iOS 双平台支持？"
    variable: both_platforms
  - type: conditional_copy
    if: "both_platforms"
    from: adapters/build.dual-platform.yaml
    to: pl/adapters/build.yaml
```

### 7.3 Preset Registry

类似 npm registry，用户可以通过 `pl presets` 命令管理：

```bash
pl presets search migration            # 搜索 preset
pl presets add @pl/preset-weex-to-kuikly
pl presets info kotlin-kmm
pl presets upgrade kotlin-kmm
pl presets remove kotlin-kmm
```

**Registry 来源**：
1. **官方**：`@pl/preset-*` npm scope（pl-pipeline 维护）
2. **社区**：任何 npm 包，但需要 `apiVersion: pl-pipeline/v1` 才被识别

---

## 8. Preset 规划路线图

### 8.1 官方 Preset（第一批）

| Preset | 用途 | 来源 |
|---|---|---|
| `@pl/preset-common-core` | 通用 skills（spec-normalizer / finalization-template） | 抽自宿主 |
| `@pl/preset-common-git-flow` | git 提交规范 | 抽自 `git-commit-rules.md` |
| `@pl/preset-common-quality` | 验收标准通用规则 | 抽自 `acceptance-criteria-rules.md` |
| `@pl/preset-common-migration` | 迁移类通用 agent | 抽自 `migration-*.md` |
| `@pl/preset-kotlin-kmm` | Kotlin Multiplatform | 抽自 `kotlin-*.md` |
| `@pl/preset-web-react-nextjs` | React + Next.js | **全新创建**（示范作用） |
| `@pl/preset-python-fastapi` | Python Web | **全新创建** |

### 8.2 社区 Preset（首个示范）

| Preset | 说明 |
|---|---|
| `@community/preset-weex-to-kuikly` | **最重要**：把你的 Weex→Kuikly 迁移经验打包 |
| `@community/preset-vue2-to-vue3` | 社区常见迁移 |
| `@community/preset-legacy-refactor` | 遗留代码重构通用模式 |

### 8.3 使用场景

**场景 1：新项目（Kotlin KMM）**
```bash
pl init --preset kotlin-kmm,common-core,common-git-flow
```

**场景 2：Weex 迁移项目**
```bash
pl init --preset kotlin-kmm,weex-to-kuikly,common-migration,common-git-flow
```

**场景 3：完全自定义**
```bash
pl init --no-preset
# 自己手写 rules/skills
```

---

## 9. Preset 价值飞轮

这是 pl-pipeline 作为开源项目的**最大长期价值**：

```
              ┌──────────────────────────────┐
              │   社区贡献 preset            │
              │   （各自经验沉淀）           │
              └──────────┬───────────────────┘
                         ↓
              ┌──────────────────────────────┐
              │   pl presets search          │
              │   （用户发现合适方案）        │
              └──────────┬───────────────────┘
                         ↓
              ┌──────────────────────────────┐
              │   pl init --preset X         │
              │   （一键采纳）               │
              └──────────┬───────────────────┘
                         ↓
              ┌──────────────────────────────┐
              │   用户基于 preset 改进        │
              │   （再次贡献 v2）            │
              └──────────┬───────────────────┘
                         ↑
                         └──── 循环 ────┘
```

**对比现状**：
- 现在：每个项目各自发明轮子，经验锁在公司内部
- 未来：pl-pipeline 生态内共享最佳实践，后来者直接站在肩膀上

**例子**：你做完 `weex-to-kuikly-migration` 打包成 preset 后，腾讯内部另一个团队要做同样迁移，**省下的时间可能是数周到数月**。

---

## 10. 决策总结

### 10.1 Layer 2 的抽象原则

| 原则 | 含义 |
|---|---|
| **协议先于实现** | 先定义 interface，再写内置实现 |
| **默认合理** | 有默认实现（gradle + jsonl + git），开箱即走 |
| **扩展开放** | 用户可写 `custom` adapter，不等官方支持 |
| **配置可序列化** | 所有配置都能 YAML 化，利于团队共享 |

### 10.2 Layer 3 的 Preset 化原则

| 原则 | 含义 |
|---|---|
| **可组合** | 多个 preset 可叠加（kotlin-kmm + weex-to-kuikly） |
| **可覆盖** | 用户项目里的 rules 永远覆盖 preset（project > preset > default） |
| **显式依赖** | preset 声明 `requires` / `conflicts_with`，避免冲突 |
| **可版本化** | 每个 preset 走 semver，老版本不会突然断 |

### 10.3 抽离工期预估

| 抽象 | 工期 | 优先级 |
|---|---|---|
| Build Adapter | 3 天 | P0 |
| Trace Backend | 3 天 | P1 |
| VCS Adapter | 2 天 | P1 |
| Quality Policy | 3 天 | P0 |
| IDE Adapters（4 个 + MCP） | 5 天 | P0 |
| StateManager TS 重写 | 3 天 | P0 |
| Orchestrator TS 重写 | 5 天 | P0 |
| Detector（技术栈识别） | 4 天 | P1 |
| Preset Engine | 3 天 | P0 |
| Preset 内容迁移（10 个） | 5 天 | P0 |
| **合计** | **36 天（约 7 周）** | - |

---

## 变更日志

| 日期 | 版本 | 作者 | 变更 |
|---|---|---|---|
| 2026-04-21 | v0.1 | AI | 首版 Layer 分析 |
