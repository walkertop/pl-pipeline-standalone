# Retro: First-run demo bugs exposed gaps in the pipeline

> 日期：2026-04-21
> 场景：首次在本地真实启动 `examples/demo-nextjs-todo` 与 `examples/demo-fastapi-users`
> 结论：暴露了 **7 个 bug，0 个被现有门禁提前抓到**。这是 pl-pipeline 自我迭代的第一手材料。

---

## 1. 事件回放

`Phase 4` commit 之后，demo 的一切静态校验都通过了：
- `adapter-validate.sh` 无 errors
- `pl-status.sh` 识别 change 为 `ARCHIVE`，11/12 任务完成
- `pl-status.sh --self-check` 通过
- CI（模拟的 5 个 job）全绿
- py_compile 全量扫 0 语法错误

**然而，`npm install && npm run dev` 和 `uv sync && uv run pytest` 第一次执行，就冒出 7 个问题**。这是典型的"纸面绿，真跑红"——正是 pl-pipeline 的价值被挑战的场景。

---

## 2. Bug 清单与本质分类

| # | Bug 症状 | 本质类别 | 本可发现的最早时机 |
|---|---|---|---|
| B1 | `@types/react-dom@18.3` 里 `useFormState` 只在 `canary.d.ts` | Adapter 对 host peer 版本无约束 | PLAN（架构决策） |
| B2 | `startTransition(() => toggleTodo(id))` 类型不兼容 | 普通 TS 编译错 | IMPLEMENT 每次保存 |
| B3 | `revalidateTag('todos')` 对 module Map 无效 | Next.js 缓存语义误用（知识型） | PLAN 或 VERIFY 的代码审查 |
| B4 | 缺 `app/layout.tsx` / `tsconfig.json` / `next.config.ts` | Adapter 的 `requires.files` 缺项 | adapter-install 后 |
| B5 | Next.js dev HMR 清空模块级 Map | 运行时隐性依赖（非静态可见） | VERIFY 的 smoke run |
| B6 | FastAPI 缺 `python-multipart` | 运行时 import-chain 依赖 | VERIFY 的 startup smoke |
| B7 | `passlib[bcrypt]` 与 bcrypt 5.x 破坏性不兼容 | 下游依赖已知坏 combo | 依赖锁 + 漏洞扫描 |

抓捕代价从低到高：**B2 ≤ B4 ≤ B1 ≤ B6 ≤ B7 ≤ B3 ≤ B5**

---

## 3. 现有门禁覆盖矩阵

| 门禁 / 脚本 | B1 | B2 | B3 | B4 | B5 | B6 | B7 |
|---|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
| A0 (SPEC→PLAN) | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| B1-gate (PLAN→IMPLEMENT) | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| D (IMPLEMENT→VERIFY) | — | ✅ | ❌ | 部分 | ❌ | ❌ | ❌ |
| E (VERIFY→OBSERVE) | ❌ | — | 部分 | ❌ | 理论能 | 理论能 | ❌ |
| G (OBSERVE→ARCHIVE) | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| `adapter-validate.sh` | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| `adapter-install.sh` | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| `should-build.sh` | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| `piao-*` 全套 | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |

**覆盖率：7/70 = 10%。** 全系统抓不到。

---

## 4. 根因分析

### 4.1 D 门禁判据没被 adapter 真正"填充"

`pl/config.yaml` D 门禁写的是自然语言判据，而且**硬编码了宿主栈**（gradle / ApiSelfCheck）。
Adapter 声明的 `build_adapter.commands.{compile_check,lint,test}` 在 `.pl-adapter.yaml`
里完整可见，**但没有脚本消费它**。

```yaml
# adapter-nextjs-web 安装后注入宿主的 .pl-adapter.yaml
build_adapter:
  type: npm
  env:
    PL_BUILD_CHECK_CMD: "npx tsc --noEmit"   # ← 躺尸，没人调
    PL_LINT_CMD: "npx next lint"
    PL_TEST_CMD: "npm test -- --ci --passWithNoTests"
```

### 4.2 没有"运行时 smoke 门禁"

E 门禁说"运行日志正常"，但实际上没有任何脚本**把服务起起来**。
B5 / B6 是启动-时才暴露的问题，这是 smoke 缺位的直接后果。

### 4.3 Adapter `requires.files` / `requires.tools` 没被消费

adapter-install 只把资产**放进去**，不检查宿主**具不具备运行前提**。
ROADMAP 里规划了 `pl doctor` 但尚未实现。B4、B7 属于此类。

### 4.4 知识型规则没变成静态 linter

B3 在 `nextjs-data-fetching.md` skill 里白纸黑字写了：
> revalidateTag 只对 fetch() 数据源生效；module-state 请用 revalidatePath

但**这仅是给 AI 看的提示**。rule / skill 里的规则**没变成可机械扫的 linter**。

---

## 5. 改进方案（按 ROI）

| 优先级 | 方案 | 工作量 | 覆盖 bug | 里程碑 |
|---|---|---|---|---|
| **P0** | `pl-verify.sh` 统一驱动 `build_adapter.commands.*` | 半天 | B2 | v0.2 |
| **P0** | `pl-smoke.sh` + `adapter.build_adapter.smoke` 字段 | 1 天 | B5 / B6 | v0.2 |
| **P1** | `pl-doctor.sh`（前置体检） | 半天 | B4 / B6 / B7 | v0.2 |
| **P1** | `pl-dep-lock.sh`（adapter.peer_versions 交叉验证） | 0.5 天 | B1 / B7 | v0.2 |
| **P2** | `pl-code-scan.sh`（rule frontmatter + ripgrep 规则引擎） | 1.5 天 | B3 + 无数知识型 | v0.3 |
| **P3** | `piao-artifact-verify.sh`（demo 反向漂移校验） | 1 天 | 回归 | v0.3 |

### 5.1 方案 1 / `pl-verify.sh`（提案）

```bash
#!/usr/bin/env bash
# 读宿主 .pl-adapter.yaml，把 PL_BUILD_CHECK_CMD / PL_LINT_CMD / PL_TEST_CMD
# 按 success_pattern / failure_patterns 执行，写 trace 事件
bash $PL_HOME/scripts/pl-verify.sh [--phase compile|lint|test|smoke|all]
```

**消费者**：pipeline-orchestrator 在 D 门禁自动调用；CI workflow 作为 demo-smoke job。

### 5.2 方案 2 / `pl-smoke.sh` + manifest 扩展

adapter.yaml 新增 `build_adapter.smoke` 段：

```yaml
provides:
  build_adapter:
    smoke:
      start_cmd: "npm run dev -- --port $SMOKE_PORT"
      ready_url: "http://127.0.0.1:$SMOKE_PORT/"
      ready_timeout_sec: 30
      probes:
        - { method: GET,  url: "/todos",       expect_status: 200, expect_body_regex: "<h1>Todos</h1>" }
        - { method: POST, url: "/api/health",  expect_status: 200 }
```

E 门禁从"人眼看日志"变成"脚本打 10 发请求"。

### 5.3 方案 3 / `pl-doctor.sh`

```bash
bash $PL_HOME/scripts/pl-doctor.sh
# 依次检查：
#   1. requires.tools 全部 command -v OK
#   2. tool min_version 真实满足
#   3. requires.files 在 $PL_PROJECT 存在
#   4. .pl-adapter.yaml source_sha256 vs 真实 adapter.yaml（漂移）
#   5. assets/adapter-sdk/known-bad-combos.yaml 里的坏组合
```

### 5.4 方案 4 / `pl-code-scan.sh`（最重型）

让 rule 文件支持 frontmatter 里声明可执行检测：

```markdown
---
id: nextjs-revalidate-for-non-fetch
severity: warn
detect:
  must_all:
    - file_glob: "**/_actions/**/*.ts"
    - file_contains: "'use server'"
    - file_contains: "revalidateTag"
  must_none:
    - file_contains: "fetch("
---
```

`pl-code-scan.sh` 收齐所有 rule 的 detect，生成 ripgrep 调用，扫代码给告警。
**把 rule 从"AI 提示"升级为"CI linter"**，是本轮分析最有战略意义的改进。

---

## 6. 反思：为什么我们的 demo 看起来"通过了"

Phase 4 的 demo 是**在 adapter-install 之后手工填充产物**得到的。问题是：
- `pl-status.sh --self-check` 只看 `.state.md` 字段合规性，不跑代码
- `adapter-validate.sh` 只管 adapter manifest 自身，不管宿主项目跑不跑得起来
- CI 5 个 job 没一个真起服务

这本质上是 **pl-pipeline v0.1 只覆盖了"文档契约层"**，尚未触及**"可执行契约层"**。
这是 v0.2 的核心跃迁方向。

---

## 7. 作为里程碑的意义

这次 retro 证明了 pl-pipeline 自身的"飞轮"机制——

> **做完需求 → 真实跑验证 → 暴露流水线漏洞 → 沉淀为下一轮的增强**

本 retro 已作为 v0.2 门禁增强的输入列入 `ROADMAP.md`。

追踪 issue：待创建 `[v0.2] Gate enhancement based on first-run demo retro`。
