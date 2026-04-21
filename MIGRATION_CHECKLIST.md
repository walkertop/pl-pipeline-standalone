# pl-pipeline 抽离清单（Migration Checklist）

> **目的**：把 pl-pipeline 从 `daojuROOT/KuiklyPolyCity` 宿主项目中抽离为独立的开源项目。
>
> **本文是抽离蓝图**，列出每个资产的：来源位置、抽离难度、目标位置、需要的改造、验收标准。
>
> **版本**：v0.1（2026-04-21）

---

## 总览

| 维度 | 数据 |
|---|---|
| 宿主项目 | `/Users/guobin/Developer/djc1/daojuROOT/KuiklyPolyCity` |
| 目标独立项目 | `/Users/guobin/Developer/djc1/pl-pipeline-standalone` |
| 资产总量 | **33 个核心文件 / ~8000 行**（含 scripts/templates/schemas/commands/docs） |
| 硬编码污染度 | **~20%**（主要在 commands/pl/*.md 和 docs 中的示例） |
| 预计工期 | **6 周全职**（按阶段 1～6 拆分） |

### 抽离难度分级

- 🟢 **零改动直接拷贝**（Layer 0）：schemas / config.yaml / 核心 scripts
- 🟡 **少量占位符化**（Layer 1）：templates / commands prompt
- 🟠 **需要抽象层**（Layer 2）：build hooks / trace backend / VCS hooks
- 🔴 **需要 Preset 化**（Layer 3）：rules / skills / agents（完全项目特定）

---

## 目录

1. [Layer 0：零耦合核心资产](#layer-0)
2. [Layer 1：几乎通用（需少量占位符化）](#layer-1)
3. [Layer 2：需要抽象协议](#layer-2)
4. [Layer 3：项目特定（需要转成 Preset）](#layer-3)
5. [新增：独立项目需要的新资产](#new-assets)
6. [执行顺序（6 周 Roadmap）](#roadmap)
7. [验收标准](#acceptance)

---

<a id="layer-0"></a>
## 一、Layer 0：零耦合核心资产（🟢 直接拷贝）

这些文件 **0 硬编码项目路径**，拷贝过来即可用，**总量 ~1500 行**。

### 1.1 JSON Schemas（5 份）

| 源文件 | 目标位置 | 行数 | 改造 |
|---|---|---|---|
| `pl/schemas/state.schema.json` | `packages/core/assets/schemas/state.schema.json` | - | 无 |
| `pl/schemas/spec.schema.json` | `packages/core/assets/schemas/spec.schema.json` | - | 无 |
| `pl/schemas/plan.schema.json` | `packages/core/assets/schemas/plan.schema.json` | - | 无 |
| `pl/schemas/taskdag.schema.json` | `packages/core/assets/schemas/taskdag.schema.json` | - | 无 |
| `pl/schemas/pl-status-v1.schema.json` | `packages/core/assets/schemas/pl-status-v1.schema.json` | - | 无 |

**验证**：Schema 必须通过 `ajv` 或 `zod` 校验任意合规 `.state.md` / `spec.md` 等产物。

---

### 1.2 核心 Config（1 份）

| 源文件 | 目标位置 | 行数 | 改造 |
|---|---|---|---|
| `pl/config.yaml` | `packages/core/assets/config.default.yaml` | ~200 | 删除"项目自治"等中文描述中的项目名 |

**改造点**（第 2 行）：
```yaml
# 原
# pl-pipeline Config
# 项目自治研发流水线配置文件

# 改为
# pl-pipeline Default Configuration
# Reference: https://pl-pipeline.dev/docs/config
```

---

### 1.3 核心 Scripts（3 个 pl-* 命名空间下）

这 3 个脚本已验证 **0 项目路径硬编码**（`grep -E "KuiklyPolyCity|daojuROOT|shared/src|kuiklypolycity"` 无命中）。

| 源文件 | 行数 | 目标 | 改造 |
|---|---|---|---|
| `scripts/pl-status.sh` | 468 | `packages/cli/src/commands/status.ts`（**TS 重写**） | 改为 TS 以获得更好跨平台 + 类型安全 |
| `scripts/pl-dashboard-refresh.sh` | 594 | `packages/cli/src/commands/dashboard.ts`（**TS 重写**） | 同上 |
| `scripts/pl-migrate-legacy.sh` | 291 | `packages/cli/src/commands/migrate-legacy.ts` | 仅用于从 openspec 遗产迁移，可延后 |

**为什么要 TS 重写**（不直接拷贝 bash）：
1. 跨平台（Windows 原生支持）
2. 与 Node.js 生态原生契合（MCP / IDE plugin 都是 Node）
3. 类型安全 + 易测试
4. 保留 bash 版作为 `legacy/`（过渡期内可用）

**TS 重写投入**：~5 天（约 3 个脚本 × 1.5 天/脚本，含 CLI 参数解析 + 单元测试）

---

<a id="layer-1"></a>
## 二、Layer 1：几乎通用（🟡 少量占位符化）

### 2.1 产物模板（7 件 + 1 确认件）

| 源文件 | 目标 | 行数 | 硬编码程度 | 改造 |
|---|---|---|---|---|
| `pl/templates/spec.md` | `packages/core/assets/templates/spec.md` | 168 | 低 | 把"Weex/Kuikly"示例抽到 `{{preset.examples}}` |
| `pl/templates/plan.md` | `packages/core/assets/templates/plan.md` | 110 | 低 | 同上 |
| `pl/templates/taskdag.md` | `packages/core/assets/templates/taskdag.md` | 194 | 低 | 同上 |
| `pl/templates/api.md` | `packages/core/assets/templates/api.md` | 167 | 低 | 同上 |
| `pl/templates/deps.md` | `packages/core/assets/templates/deps.md` | 111 | 低 | 同上 |
| `pl/templates/testmatrix.md` | `packages/core/assets/templates/testmatrix.md` | 91 | 低 | 同上 |
| `pl/templates/state.md` | `packages/core/assets/templates/state.md` | 158 | 低 | 同上 |
| `pl/templates/confirmation.md` | `packages/core/assets/templates/confirmation.md` | 67 | 低 | 同上 |

**改造示例**（`spec.md`）：

```diff
  ## 业务背景

- 本次变更用于将 Weex 老页面迁移至 Kuikly 框架。
- 详见 daojuROOT/Weex/src/xxx.vue。
+ {{#if preset.examples}}
+   {{preset.examples.spec_business_context}}
+ {{else}}
+   [请描述：这次变更为什么要做、业务价值是什么]
+ {{/if}}
```

**工期**：1 天（8 个模板 × 1 小时清洗）

---

### 2.2 IDE Command Prompts（9 条）

这些是 CodeBuddy 特定的 slash command，需要**Adapter 化**。

| 源文件 | 行数 | 目标 | 改造 |
|---|---|---|---|
| `.codebuddy/commands/pl/proposal.md` | 138 | `packages/adapter-codebuddy/templates/proposal.md` | 保留 codebuddy 特定的 frontmatter + `$ARGUMENTS` |
| `.codebuddy/commands/pl/plan.md` | 177 | `packages/adapter-codebuddy/templates/plan.md` | 同上 |
| `.codebuddy/commands/pl/implement.md` | 168 | `packages/adapter-codebuddy/templates/implement.md` | 清洗 Kuikly/Weex 示例 |
| `.codebuddy/commands/pl/verify.md` | 146 | `packages/adapter-codebuddy/templates/verify.md` | 同上 |
| `.codebuddy/commands/pl/archive.md` | 165 | `packages/adapter-codebuddy/templates/archive.md` | 同上 |
| `.codebuddy/commands/pl/status.md` | 137 | `packages/adapter-codebuddy/templates/status.md` | 同上 |
| `.codebuddy/commands/pl/apply.md` | 92 | `packages/adapter-codebuddy/templates/apply.md` | 同上 |
| `.codebuddy/commands/pl/explore.md` | 160 | `packages/adapter-codebuddy/templates/explore.md` | 同上 |
| `.codebuddy/commands/pl/migrate.md` | 137 | `packages/adapter-codebuddy/templates/migrate.md` | 同上 |

**同步产出**（为其他 IDE）：
- `packages/adapter-cursor/templates/pl-*.mdc`（Cursor Rules 格式）
- `packages/adapter-claude-code/templates/pl/*.md`
- `packages/adapter-codex/agents-snippet.md`（只追加 AGENTS.md 片段）
- `packages/mcp-server/src/tools/*.ts`（MCP 工具定义）

**工期**：5 天（每个 adapter 1 天）

---

### 2.3 文档

| 源文件 | 行数 | 目标 | 改造 |
|---|---|---|---|
| `docs/pl-pipeline/README.md` | 320 | `apps/docs/docs/concepts.md` | 作为文档站"核心概念"章节基础 |
| (无) | - | `apps/docs/docs/*` 全新 | 按 Docusaurus 结构重组，新增 Getting Started / Presets / API |

---

<a id="layer-2"></a>
## 三、Layer 2：需要抽象协议（🟠 重构为 Adapter）

这是最重要也最有价值的部分。现在这些脚本与 Gradle / JSONL / git 强耦合，需要抽成**可插拔 Adapter**。

### 3.1 Build 验证（Gradle 硬编码）

**现状**：
- `scripts/should-build.sh`（287 行）：硬编码"变更数 ≥ 阈值 → 触发 build"
- `scripts/migration-verify.sh`（640 行）：硬编码 `./gradlew :shared:compileDebugKotlinAndroid`

**抽象方案**：定义 **Build Adapter 协议**

```typescript
// packages/core/src/adapters/build.ts
export interface BuildAdapter {
  id: string                                          // "gradle" / "npm" / "cargo" / "custom"
  compileCheck(options?: CompileOptions): Promise<BuildResult>
  lint(options?: LintOptions): Promise<LintResult>
  test(options?: TestOptions): Promise<TestResult>
  fullBuild?(): Promise<BuildResult>
}

export interface BuildResult {
  success: boolean
  durationMs: number
  stdout: string
  stderr: string
  errors: BuildError[]
}
```

**用户配置**（`pl/adapters/build.yaml`）：
```yaml
adapter: gradle
commands:
  compile_check:
    cmd: "./gradlew :shared:compileDebugKotlinAndroid"
    success_pattern: "BUILD SUCCESSFUL"
    failure_patterns: ["^e:", "error:"]
    timeout_sec: 300
  lint:
    cmd: "./gradlew detekt"
  test:
    cmd: "./gradlew test"
```

**内置 Adapter 实现**（在 `packages/core/src/adapters/`）：
- `gradle.ts` / `npm.ts` / `pnpm.ts` / `cargo.ts` / `go.ts` / `make.ts` / `custom.ts`

**工期**：3 天

---

### 3.2 Trace 可观测（JSONL 硬编码）

**现状**：
- `scripts/trace-emit.sh`（227 行）：写 JSONL 文件
- `scripts/trace-report.sh`（540 行）：生成 HTML 报告

**抽象方案**：**Trace Backend Adapter**

```typescript
export interface TraceBackend {
  id: string                                          // "jsonl" / "otel" / "datadog" / "noop"
  emit(event: TraceEvent): Promise<void>
  query(filter: TraceFilter): Promise<TraceEvent[]>
}
```

**内置**：
- `jsonl.ts`（默认）
- `otel.ts`（OpenTelemetry Collector）
- `noop.ts`（禁用 trace）
- `http-webhook.ts`（POST 到外部服务）

**HTML 报告生成器**：独立 `packages/reporter/` 包，读 `TraceEvent[]` 渲染 React 组件为静态 HTML。

**工期**：3 天

---

### 3.3 VCS Hooks（git 硬编码）

**现状**：
- `scripts/setup-hooks.sh`：装 git pre-commit / commit-msg hooks
- 多处脚本硬编码 `git -c core.hooksPath=/dev/null commit`

**抽象方案**：**VCS Adapter**

```typescript
export interface VCSAdapter {
  id: string
  commit(message: string, options?: CommitOptions): Promise<CommitResult>
  currentBranch(): Promise<string>
  recentCommits(n: number): Promise<Commit[]>
  installHooks?(hooks: HookSpec[]): Promise<void>
}
```

**内置**：`git.ts`（覆盖 99% 场景），未来可扩展 `hg.ts` / `jj.ts`。

**commit message 模板**：用户项目自配（不进默认值）：
```yaml
# pl/adapters/vcs.yaml
commit:
  template: "{{type}}({{scope}}): {{subject}}"   # conventional commits
  scopes: ["core", "ui", "data", "build"]
  types: ["feat", "fix", "docs", "refactor", "test", "chore"]
```

**工期**：2 天

---

### 3.4 Quality Policy（散落的黑名单）

**现状**：黑名单散落在 `taskdag.md` 各个 Task 的"验收"节（如"不含 pintuan / isStampsPayInCFM"）。

**抽象方案**：**Quality Policy** 统一到 `pl/policy.yaml`

```yaml
# pl/policy.yaml
blacklist:
  global:                              # 整个项目都不允许出现
    - pattern: "console.log"
      severity: warning
      exempt: ["src/debug/**"]
    - pattern: "TODO\\(no-ticket\\)"
      severity: error
  by_change:                           # 单次变更定制（从 taskdag 提取）
    prop-confirm-migration:
      - pattern: "pintuan"
        reason: "拼团已下线"
        severity: error

required_patterns:
  - pattern: "@Serializable"
    in: "src/**/data/**.kt"
    description: "数据类必须可序列化"

acceptance_gates:
  C:
    checks:
      - type: compile
        must_pass: true
      - type: blacklist
        must_be_empty: true
```

**Policy Engine**：`packages/core/src/policy/` 读 policy.yaml，跑验收检查。

**工期**：3 天

---

### 3.5 状态管理（`.state.md` 读写）

**现状**：`scripts/state-generator.sh`（717 行）是 bash 生成 `.state.md`。

**抽象方案**：TS 重写为 `StateManager` class

```typescript
export class StateManager {
  read(changeId: string): Promise<ChangeState>
  write(changeId: string, state: Partial<ChangeState>): Promise<void>
  transition(changeId: string, to: Stage): Promise<void>
  addHistoryEvent(changeId: string, event: HistoryEvent): Promise<void>
  validate(changeId: string): Promise<ValidationResult>
}
```

基于 `state.schema.json` 做强校验。

**工期**：3 天

---

### 3.6 Pipeline Orchestrator

**现状**：`scripts/pipeline-orchestrator.sh`（600 行）编排 `SPEC → PLAN → IMPLEMENT → VERIFY → OBSERVE → ARCHIVE`。

**抽象方案**：TS 重写为 `Orchestrator` class + 事件驱动

```typescript
export class Orchestrator {
  async run(changeId: string, opts?: OrchestratorOptions): Promise<void>
  async only(changeId: string, stage: Stage): Promise<void>
  async status(changeId: string): Promise<StageStatus>
  on(event: OrchestratorEvent, handler: Handler): this
}
```

支持 **插件钩子**（让宿主项目注入逻辑）：
```typescript
orchestrator.on("pre_verify", async (ctx) => {
  // 宿主项目可以在这里追加自定义检查
})
```

**工期**：5 天（含事件系统 + 插件加载器）

---

<a id="layer-3"></a>
## 四、Layer 3：项目特定（🔴 转成 Preset）

这些是 **KuiklyPolyCity 强耦合的资产**，不能进 pl-pipeline 核心，需要打包为 **Preset**。

### 4.1 Rules（10 个）

| 文件 | 通用性 | 目的地 |
|---|---|---|
| `.codebuddy/rules/git-commit-rules.md` | 🟢 完全通用 | `packages/presets-official/common-git-flow/rules/` |
| `.codebuddy/rules/acceptance-criteria-rules.md` | 🟢 通用 | `packages/presets-official/common-quality/rules/` |
| `.codebuddy/rules/build-verification-rules.md` | 🟡 半通用（含 Gradle 示例） | 抽象到 `packages/presets-official/common-build/rules/` |
| `.codebuddy/rules/kotlin-coding-standards.md` | 🟡 Kotlin 项目通用 | `packages/presets-official/kotlin-kmm/rules/` |
| `.codebuddy/rules/serialization-rules.md` | 🟡 Kotlin 特定 | `packages/presets-official/kotlin-kmm/rules/` |
| `.codebuddy/rules/mvvm-architecture-rules.md` | 🟠 项目特定（含 Card 架构） | `packages/presets-community/kuikly-mvvm/rules/` |
| `.codebuddy/rules/migration-rules.md` | 🔴 Weex→Kuikly 特定 | `packages/presets-community/weex-to-kuikly/rules/` |
| `.codebuddy/rules/vue-to-kuikly-syntax.md` | 🔴 同上 | 同上 |
| `.codebuddy/rules/vue-to-kuikly-component.md` | 🔴 同上 | 同上 |
| `.codebuddy/rules/piao-pipeline-discipline.md` | 🔴 项目历史遗留 | **留在宿主**，不迁移 |

**Preset 清单**：
- `@pl/preset-common-git-flow`（官方）
- `@pl/preset-common-quality`（官方）
- `@pl/preset-kotlin-kmm`（官方）
- `@pl/preset-weex-to-kuikly`（社区，**首个案例 Preset**）

---

### 4.2 Skills（16 个）

| Skill | 通用性 | 目的地 |
|---|---|---|
| `spec-normalizer` | 🟢 通用 | `packages/presets-official/common-core/skills/` |
| `finalization-template` | 🟢 通用 | 同上 |
| `continuous-learning` | 🟢 通用 | 同上 |
| `kotlin-code-review` | 🟡 Kotlin | `@pl/preset-kotlin-kmm` |
| `kuikly-ui-framework` | 🔴 Kuikly 特定 | `@pl/preset-community-kuikly` |
| `kuikly-debugger` | 🔴 同上 | 同上 |
| `kuikly-performance-analyzer` | 🔴 同上 | 同上 |
| `kuikly-test-generator` | 🔴 同上 | 同上 |
| `kuikly-third-party` | 🔴 同上 | 同上 |
| `auto-ui-test` | 🟠 Kuikly 特定但概念通用 | 同上 |
| `build-and-deploy` | 🔴 Kuikly 特定 | 同上 |
| `migration-doc-generator` | 🟠 迁移类通用 | `@pl/preset-common-migration` |
| `weex-migration-analyzer` | 🔴 Weex 特定 | `@pl/preset-weex-to-kuikly` |
| `openspec-apply-change` / `openspec-archive-change` / `openspec-explore` / `openspec-propose` | 🔴 legacy | **删除**（已被 pl-pipeline 取代） |

---

### 4.3 Agents（8 个）

| Agent | 通用性 | 目的地 |
|---|---|---|
| `pipeline-master.md` | 🟡 核心编排（但含迁移语义） | 抽象后进 `packages/core/assets/agents/` |
| `migration-analyzer.md` | 🟠 迁移类通用 | `@pl/preset-common-migration` |
| `migration-coder.md` | 🟠 同上 | 同上 |
| `migration-guardian.md` | 🟠 同上 | 同上 |
| `knowledge-archiver.md` | 🟢 通用 | `packages/core/assets/agents/` |
| `module模块专家.md` | 🔴 Kuikly 特定 | `@pl/preset-community-kuikly` |
| `Kuikly 迁移专家.md` | 🔴 同上 | `@pl/preset-weex-to-kuikly` |
| `Kuikly 迁移架构师及代码依赖分析专家.md` | 🔴 同上 | 同上 |

---

### 4.4 Dashboard（Web UI）

| 源 | 目的地 | 改造 |
|---|---|---|
| `pipeline-output/dashboard/index.html` | `apps/dashboard/`（独立 Next.js 应用） | 数据源从"写死 JSON"改为"读 pl CLI 输出" |

**设计**：
- 命令行一条：`pl dashboard --serve` 启动本地 Web 查看面板
- 或：`pl dashboard --export html` 生成静态 HTML
- 用 React + Vite + Tailwind 重写（原版是手写 HTML，不可维护）

**工期**：5 天（从零写起，含设计）

---

### 4.5 遗留资产（不迁移，留在宿主）

这些是宿主项目的**业务实例**，与 pl-pipeline 无关：

- `pl/changes/` 下所有 change 实例（4 个）
- `pipeline-output/trace/*.jsonl`（运行时产物）
- `pipeline-output/ui-test/`（UI 测试产物）
- `openspec/` 遗产（legacy）
- `.codebuddy/commands/opsx/`（legacy，opsx@1.3 老用户参考）
- `ARCHITECTURE_SNAPSHOT.md` / `CLAUDE.md` / `CODEBUDDY.md`（宿主项目的项目级文档）

**宿主项目只需保留**：
```
KuiklyPolyCity/
├── pl/
│   ├── config.yaml           ← 继承 pl-pipeline 默认 + 项目覆盖
│   └── changes/              ← 项目所有变更实例
├── .codebuddy/
│   ├── rules/                ← 项目特定规则（由 Preset 初始化填充 + 自定义补充）
│   ├── skills/               ← 同上
│   └── agents/               ← 同上
├── .pl-version               ← 锁定 pl CLI 版本
└── ...业务代码
```

---

<a id="new-assets"></a>
## 五、新增：独立项目需要的新资产

这些是 **宿主项目里没有，但独立项目必须有** 的资产。

### 5.1 顶层文档

| 文件 | 目的 | 工期 |
|---|---|---|
| `README.md` | 产品定位 + 30 秒上手 | ✅ 已完成 |
| `CONTRIBUTING.md` | 贡献指南（分级：分享案例 / Preset / Adapter / 核心） | 1 天 |
| `CODE_OF_CONDUCT.md` | 社区行为准则（Contributor Covenant 标准） | 0.5 天 |
| `SECURITY.md` | 安全漏洞上报 | 0.5 天 |
| `CHANGELOG.md` | 由 changesets 自动维护 | - |
| `LICENSE` | Apache 2.0 | - |
| `ARCHITECTURE.md` | 内部架构说明（给贡献者） | 2 天 |

### 5.2 Monorepo 基础设施

| 文件 | 目的 | 工期 |
|---|---|---|
| `package.json` | 根 package + workspaces 声明 | - |
| `pnpm-workspace.yaml` | pnpm workspaces | - |
| `turbo.json` | Turborepo 任务编排 | 0.5 天 |
| `.changeset/config.json` | changesets 配置 | - |
| `tsconfig.base.json` | 共享 TS 配置 | - |
| `.eslintrc.js` + `.prettierrc` | 代码风格 | - |

### 5.3 CI/CD

| 文件 | 目的 | 工期 |
|---|---|---|
| `.github/workflows/ci.yaml` | PR 测试（lint + test + build） | 0.5 天 |
| `.github/workflows/release.yaml` | 发版（changesets → npm） | 0.5 天 |
| `.github/workflows/docs-deploy.yaml` | 文档站自动部署 | 0.5 天 |
| `.github/ISSUE_TEMPLATE/*.yaml` | Bug / Feature / Preset 模板 | 0.5 天 |
| `.github/PULL_REQUEST_TEMPLATE.md` | PR 模板 | 0.5 天 |

### 5.4 Playground（在线试用）

| 组件 | 目的 | 工期 |
|---|---|---|
| `apps/playground/` | 基于 StackBlitz WebContainer 的在线 pl-pipeline 环境 | 5 天 |

### 5.5 Detector（技术栈智能识别）

这是 **Smart Init** 的核心，完全新增：

```
packages/detector/src/
├── detectors/
│   ├── kotlin-kmm.ts            ← 识别 build.gradle.kts + kotlin-multiplatform plugin
│   ├── nodejs-react.ts          ← 识别 package.json 中的 react
│   ├── nodejs-nextjs.ts         ← 识别 next.config.js
│   ├── python-fastapi.ts
│   ├── rust-cargo.ts
│   ├── go-modules.ts
│   └── ...
├── ProjectProfile.ts
└── PresetRecommender.ts
```

**工期**：4 天（含 10 个主流技术栈）

### 5.6 Preset Engine

```
packages/core/src/presets/
├── PresetLoader.ts              ← 加载 @pl/preset-* npm 包
├── PresetValidator.ts           ← 校验 preset.yaml 合法性
└── PresetInstaller.ts           ← 把 preset 内容复制/合并到用户项目
```

**工期**：3 天

---

<a id="roadmap"></a>
## 六、执行顺序（6 周 Roadmap）

### Week 1：骨架 + Layer 0

- [x] 创建独立目录 `/Users/guobin/Developer/djc1/pl-pipeline-standalone/`
- [x] README.md 草稿
- [x] MIGRATION_CHECKLIST.md（本文件）
- [ ] Monorepo 初始化（pnpm + turbo）
- [ ] 拷贝 Layer 0 资产（schemas + config + templates）
- [ ] `packages/core` 包骨架

**验收**：`pnpm install && pnpm build` 通过；schemas 能在 Node 中加载。

---

### Week 2：Core TS 重写

- [ ] TS 重写 `StateManager`
- [ ] TS 重写 `pl-status` → `packages/cli/src/commands/status.ts`
- [ ] TS 重写 `pl-dashboard-refresh`
- [ ] 单元测试 70% 覆盖

**验收**：`pl status` 在独立目录运行，能正确读 **宿主项目** 的 `pl/changes/` 输出状态。

---

### Week 3：Layer 2 抽象

- [ ] BuildAdapter 协议 + 5 个内置实现
- [ ] TraceBackend 协议 + 2 个内置实现
- [ ] VCSAdapter 协议 + git 实现
- [ ] QualityPolicy 引擎

**验收**：宿主项目切到新 CLI 跑一轮 `pl verify prop-confirm-migration`，编译检查 + 黑名单 + commit 日志全流程通过。

---

### Week 4：Smart Init + Presets

- [ ] StackDetector（10 个技术栈识别器）
- [ ] Preset Loader + Validator + Installer
- [ ] 官方 Preset：`common-core` / `common-git-flow` / `common-quality` / `kotlin-kmm`
- [ ] 社区 Preset：`weex-to-kuikly`（**用作首个 case study**）
- [ ] `pl init --smart` 交互式命令（@clack/prompts）

**验收**：在一个全新空 Kotlin KMM 项目里，`pl init --smart` 能自动配置好，然后执行完整的 `pl proposal → archive` 流程。

---

### Week 5：IDE Adapters + MCP

- [ ] `@pl/mcp-server`（MCP 协议适配，第一优先级）
- [ ] `@pl/adapter-codebuddy`
- [ ] `@pl/adapter-cursor`
- [ ] `@pl/adapter-claude-code`
- [ ] `@pl/adapter-codex`

**验收**：在同一个项目下切换 4 种 IDE，`pl proposal` 都能正常触发。

---

### Week 6：文档站 + 发布

- [ ] `apps/docs`（Docusaurus / Mintlify）
- [ ] Landing page + 30 秒 Demo 录制
- [ ] Playground
- [ ] 首版 v0.1.0 发布到 npm
- [ ] Homebrew tap
- [ ] Show HN / Twitter 宣发

**验收**：陌生开发者能在 10 分钟内从 pl-pipeline.dev 首页到成功执行第一个 `pl proposal`。

---

<a id="acceptance"></a>
## 七、验收标准（独立化完成定义）

独立化完成后，必须同时满足以下 5 条：

### 标准 1：宿主项目零污染
- 独立仓库 `pl-pipeline/` 中 **0 处** `grep KuiklyPolyCity | daojuROOT | Weex | Kuikly`（可以在示例/preset 中出现，但不能在核心代码）

### 标准 2：宿主项目能无损接入
- 宿主 KuiklyPolyCity 删除 `pl/schemas/` / `pl/templates/` / `scripts/pl-*.sh` / `.codebuddy/commands/pl/` 后，执行 `npx pl-pipeline init --existing` 能复原全部功能，且 `pl status prop-confirm-migration` 输出与删除前一致。

### 标准 3：全新项目 10 分钟接入
- 找一个完全无关的新项目（如一个 React Todo List），`pnpm create next-app → pl init --smart → pl proposal add-dark-mode` 全流程 < 10 分钟走通。

### 标准 4：多 IDE 切换无缝
- 在同一个项目里，切换 Cursor / Claude Code / CodeBuddy 三种 IDE，`pl status` / `pl proposal` 的效果一致。

### 标准 5：文档站闭环
- pl-pipeline.dev 首页 → Getting Started → Install → 第一个 proposal，每一步都有**可点开的 Playground**，不跳出即可完成。

---

## 附录 A：关键命令速查（独立后）

```bash
# 安装
npm install -g pl-pipeline
# 或
brew install pl-pipeline

# 接入现有项目
pl init --smart                              # 自动扫描 + 推荐 preset
pl init --preset kotlin-kmm --ide mcp        # 指定 preset 和 IDE

# 核心流程
pl proposal <change-id>
pl plan <change-id>
pl implement <change-id>
pl verify <change-id>
pl archive <change-id>

# 辅助
pl status                                     # 全局状态
pl status <change-id>                         # 单 change 状态
pl doctor                                     # 项目健康检查
pl dashboard --serve                          # 启动 Web Dashboard

# Preset 管理
pl presets list                               # 列出已安装 preset
pl presets add @pl/preset-weex-to-kuikly      # 添加 preset
pl presets info kotlin-kmm                    # 查看 preset 详情

# 多 IDE 切换
pl ide install cursor
pl ide install claude-code
pl ide list
```

---

## 附录 B：宿主项目最终形态（独立化完成后）

```
KuiklyPolyCity/
├── .pl-version                 ← "1.0.3"（锁定 pl CLI 版本）
├── pl/
│   ├── config.yaml             ← 继承 pl-pipeline 默认 + 项目覆盖（~50 行）
│   └── changes/                ← 项目所有变更（保留）
├── .codebuddy/
│   ├── rules/                  ← 由 preset 初始化 + 项目补充
│   ├── skills/                 ← 同上
│   ├── agents/                 ← 同上
│   └── commands/pl/            ← 由 `pl ide install codebuddy` 生成（可 gitignore）
├── scripts/                    ← 清空所有 pl-*.sh 和辅助脚本
└── ... 业务代码不变
```

**删除的文件**（独立后不再需要，宿主瘦身 ~6000 行）：
- `pl/schemas/*`（由 CLI 提供）
- `pl/templates/*`（由 CLI 提供）
- `scripts/pl-*.sh`（由 CLI 替代）
- `scripts/pipeline-orchestrator.sh` / `migration-verify.sh` / `trace-*.sh` / `state-generator.sh` / `should-build.sh`
- `docs/pl-pipeline/README.md`（迁到文档站）
- `pipeline-output/dashboard/index.html`（由 `pl dashboard` 提供）
- `.codebuddy/commands/pl/*`（由 adapter 生成）

---

## 变更日志

| 日期 | 版本 | 作者 | 变更 |
|---|---|---|---|
| 2026-04-21 | v0.1 | AI | 首版抽离清单 |
