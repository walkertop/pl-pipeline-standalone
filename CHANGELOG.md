# Changelog

本项目的所有显著变更都会记录在此。

格式遵循 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/)，
版本号遵循 [语义化版本](https://semver.org/lang/zh-CN/)。

---

## [1.2.0] — 2026-04-22 · retro-v2 收官版

**主题：pl/piao 从"文档契约层"彻底升级为"可执行契约层"。**

本版本合并了 `pl-v1.1.0-alpha` / `pl-v1.1.1-alpha` / `pl-v1.1.2-alpha`
三个 alpha tag 的所有能力，作为 retro-v2 四剂药完全闭环后的首个正式版。

### 🎯 核心叙事

retro-v1 时代，pl 的门禁是散文式的口头承诺，导致 2026-04 首次跑 demo 时 **7 个 bug**
全部从纸面绿门禁溜过。retro-v2 把根因归到 pl / piao 本体缺 4 个通用抽象（E1 / E2 / E3 / E4），
本版完成 4/4 落地：retro-v2 的原始 7 个 bug 现在 **7/7 都有机器检测路径**。

### ✨ Added — pl-core 本体

- **E1 可执行契约层**（`pl-runner.sh` + `GateDefinition / CheckDefinition` 数据模型）
  - 新增 `assets/pl/schemas/gate.schema.json`
  - `config.default.yaml` v1.0 → v1.1：定义 `checks[]` 池 + `gate.eval` 机器可求值规则
  - 移除配置里的 `gradle` / `ApiSelfCheck` 等宿主硬编码
  - 新增 `scripts/pl-runner.sh`：解析 `gate → checks` 引用 → 按 `.pl-adapter.yaml` 载 env → 跑 check → 按 `eval` 派生 gate 结果
- **E2 SMOKE 阶段**（`pl-smoke.sh` + `adapter.smoke` 声明）
  - `ORDERED_STAGES` 新增 🔥 SMOKE（位于 VERIFY 和 OBSERVE 之间）
  - `adapter-manifest.schema.json` 新增 `build_adapter.smoke.{start_cmd,ready_url,probes[]}`
  - 新增 `scripts/pl-smoke.sh`：boot 应用 → 轮询 ready_url → 逐 probe HTTP 断言 → 关停整个进程树
  - SMOKE opt-out 也发 `smoke.skip` + `gate.eval:skipped` 事件（不静默）
- **E3 rule-as-code 引擎**（`pl-rule-scan.sh` + rule frontmatter）
  - rule 文件顶部可声明 YAML frontmatter：
    `id / severity / scope / applies_to.glob / detect[].{kind,pattern} / message / fix_hint`
  - 支持 3 种 `detect.kind`：`file_contains` / `file_not_contains` / `line_contains`
  - 新增 `scripts/pl-rule-scan.sh` + 4 个 `scripts/_lib/*.py` 协作库
  - 没有 frontmatter 的 rule 仍是纯文档（完全向后兼容）
- **orchestrator 解耦**
  - `pipeline-orchestrator.sh` 的 `stage_actor()` 移除 `agent:migration-*` 硬编码
  - 改为 `${STAGE}_ACTOR` 环境变量可被 adapter 注入

### ✨ Added — piao-kernel 本体

- **E4 契约-现实漂移**（`piao-contract-drift-compute.sh`）
  - 与原 `piao-drift-compute.sh`（snapshot→snapshot 时序差分）正交共存
  - 新 drift 维度：**declared contract**（adapter.yaml.contract）vs **actual state**（宿主实测 lockfile/filetree）
  - 三类 diff 条目：`missing_file` / `peer_version_violation` / `bad_combo_hit`
  - 产物：`pipeline-output/drift/<change>-contract.yaml`（`apiVersion: piao.dev/v1, kind: ContractDrift`）
  - `adapter-manifest.schema.json` 新增 `properties.contract` 完整字段
  - **piao ↔ pl trace 首次合流**：`piao.contract_drift.detected` 直接落 pl 的 `events.jsonl`

### ✨ Added — adapter 消费侧

- `adapters/adapter-nextjs-web/adapter.yaml`：
  - 新增 `build_adapter.smoke`（SMOKE opt-out，dev server 特殊性）
  - 新增 `contract.expected_files`（tsconfig.json / app/layout.tsx / ...）
  - 新增 `contract.peer_versions.npm`（next>=15 / react>=19 / @types/*>=19 / ...）
  - 新增 `contract.known_bad_combos`（`types-react-dom-18-with-useFormState`）
  - 新增 `rules/nextjs-revalidate-for-non-fetch.md`（可执行，对应 retro-v2 B3）
- `adapters/adapter-python-fastapi/adapter.yaml`：
  - 新增 `build_adapter.smoke`（uvicorn boot + 3 probe：happy / duplicate / unauthorized）
  - 新增 `contract.expected_files`（pyproject.toml / app/main.py / ...）
  - 新增 `contract.peer_versions.python`（fastapi>=0.110 / bcrypt>=4,<5 / python-multipart / ...）
  - 新增 `contract.known_bad_combos`（`passlib-vs-bcrypt-5`）
  - 新增 `rules/fastapi-no-sync-blocking-in-async.md`（可执行）
  - 新增 `rules/fastapi-depends-pass-callable.md`（可执行）

### 🧪 Changed

- `adapter-manifest.schema.json`：apiVersion `pl.dev/v1` → `pl.dev/v1.1`
  新增 `build_adapter.smoke` + `contract` 两个顶级字段（均 optional，向后兼容）
- `pl/config.default.yaml`：v1.0 → v1.1
  - 新增 `checks` 池（定义可复用检查器）
  - 每条 gate 增加 `eval` 字段（机器可求值规则，如 `all_checks.pass`）
  - 移除所有宿主特定字符串
- rule 文件 frontmatter 是**新能力**，不破坏现有纯文档 rule

### 📚 Docs

- 新增 `docs/retros/2026-04-demo-first-run-retro-v1.md`（故意保留作为"误诊归档示例"）
- 新增 `docs/retros/2026-04-demo-first-run-retro-v2.md`（正确归因 + 4 剂药设计）
- 新增 `docs/retros/evidence-2026-04/`：
  - `demo-fastapi-users.events.jsonl`（15 events，四通道合流）
  - `demo-fastapi-users-contract-drift.yaml`（E4 artifact）
  - `demo-fastapi-users-rule-scan.yaml`（E3 artifact）
  - `demo-nextjs-todo.events.jsonl`（8 events，SMOKE opt-out）
  - 配套 contract-drift.yaml + rule-scan.yaml
  - 完整 README：反证实验 + 四通道合流示意
- 更新 `ROADMAP.md`：v0.2 本体增强表 E1/E2/E3/E4 全部 ✅
- 新增 `MIGRATION.md`：v1.0 → v1.2 升级指南

### 🔬 反证实验（最有说服力的证据）

retro-v2 的 7 个原始 bug，现在每个都有机器检测路径：

| bug | 类型 | 检测路径 |
|---|---|---|
| B1 | React 18.3 × `@types/react-dom` canary 缺失 | **E4** `known_bad_combos.types-react-dom-18-with-useFormState` |
| B2 | TypeScript 编译错 | **E1** `compile_check` |
| B3 | `revalidateTag` 对 module-state 数据源无效 | **E3** `nextjs-revalidate-for-non-fetch` |
| B4 | 缺 `tsconfig.json` / 根 `app/layout.tsx` | **E4** `expected_files` |
| B5 | HMR 清空 module state | **E2** SMOKE 两次 POST + GET 对比 |
| B6 | 缺 `python-multipart` | **E4** `peer_versions` / **E2** SMOKE boot 报错 |
| B7 | `passlib × bcrypt 5.x` 坏 combo | **E4** `known_bad_combos.passlib-vs-bcrypt-5` |

- pre-retro：0/7 被机器抓住
- post-retro：7/7 被机器抓住

### 🔧 Fixed（实施过程的踩坑修复）

- **macOS bash 3.2** 对 `$(cmd <<'HEREDOC' ... HEREDOC)` 多 `)` heredoc 的解析 bug：
  所有复杂 Python 代码迁移到独立 `scripts/_lib/*.py` 文件，bash 脚本只做薄编排
- **`PL_HOME` 被父目录污染**：`piao-contract-drift-compute.sh` 加纠偏逻辑
- **YAML 简易解析器**：支持 flow-style list (`["a","b"]`)、带引号 key (`"@types/react": ...`)、
  双引号 value 里的转义（`"pat\\("` 解析为 `pat\(`）
- **glob → regex 转换**：`**/` 正确等价于"零或多个路径段"（原 `fnmatch.translate` 译法要求至少一段，导致 `app/**/_actions/**/*.ts` 命中不了 `app/todos/_actions/todos.ts`）
- **semver 空格/逗号兼容**：`">=18.0.0 <19.0.0"`（npm 风格）等价于 `">=18.0.0,<19.0.0"`（pip 风格）

### 🏁 统计

- 新增脚本：`pl-runner.sh` / `pl-smoke.sh` / `pl-rule-scan.sh` / `piao-contract-drift-compute.sh`（4 个主脚本 + 10+ 个 `_lib/*.py` 协作库）
- 新增 schema：`gate.schema.json` + `adapter-manifest.schema.json` 扩展
- 单元级 orchestrator / pl-core / piao-kernel 三层触达
- 首次实现 piao ↔ pl **同一条 events.jsonl**

---

## [pl-v1.1.2-alpha] — 2026-04-22

**仅 E3 rule-as-code 落地**；其余变更见 [1.2.0]。

### Added
- `scripts/pl-rule-scan.sh` + `_lib/{parse-rule-frontmatter,collect-rule-files,match-rule,summarize-rules}.py`
- adapter-nextjs-web/rules/nextjs-revalidate-for-non-fetch.md
- adapter-python-fastapi/rules/fastapi-no-sync-blocking-in-async.md
- adapter-python-fastapi/rules/fastapi-depends-pass-callable.md
- trace 事件 `pl.rule_scan.completed`
- 四通道合流：`IMPLEMENT.gate.eval` + `SMOKE.*` + `OBSERVE.piao.contract_drift` + `OBSERVE.pl.rule_scan`

### Fixed
- YAML frontmatter 双引号值的转义处理
- glob `**/` 零或多路径段语义

---

## [pl-v1.1.1-alpha] — 2026-04-21（晚间）

**仅 E4 契约-现实漂移 落地**；其余变更见 [1.2.0]。

### Added
- `scripts/piao-contract-drift-compute.sh`（主 orchestrator）
- `scripts/_lib/{parse-contract,collect-exists,collect-npm,collect-python,diff-contract,summarize-drift}.py`
- `adapter-manifest.schema.json` 新增 `properties.contract`
- 两个 adapter 的 `contract` 段
- trace 事件 `piao.contract_drift.detected`（piao ↔ pl 首次合流）

### Fixed
- bash 3.2 嵌套 heredoc 解析策略：拆到 `_lib/*.py`
- PL_HOME 父目录污染纠偏
- `@types/react` 带引号 key 解析
- semver `>=18.0.0 <19.0.0` 空格分隔支持

---

## [pl-v1.1.0-alpha] — 2026-04-21（下午）

**E1 + E2 + orchestrator 解耦**；其余变更见 [1.2.0]。

### Added
- `assets/pl/schemas/gate.schema.json`（GateDefinition / CheckDefinition 数据模型）
- `scripts/pl-runner.sh`（E1 可执行契约层）
- `scripts/pl-smoke.sh`（E2 SMOKE 阶段）
- `adapter-manifest.schema.json` 新增 `build_adapter.smoke`
- `ORDERED_STAGES` 新增 SMOKE

### Changed
- `pl/config.default.yaml`：v1.0 → v1.1（checks 池 + gate.eval）
- 移除 `pipeline-orchestrator.sh` 的 `migration-*` 硬编码
- adapter-manifest.schema.json：apiVersion `pl.dev/v1` → `pl.dev/v1.1`

---

## [1.0.0] — 2026-04-20（历史快照）

> **注意**：v1.0 是"门禁是散文" 时代的最后一个版本。
> 建议所有用户**直接跳到 v1.2.0**，不要在 v1.0 基础上积累项目代码。

### Added（那时已完成的）
- 6 阶段 × 7 门禁状态机（SPEC → PLAN → IMPLEMENT → VERIFY → OBSERVE → ARCHIVE）
- 7 件核心产物（spec.md / plan.md / taskdag.md / api.md / testmatrix.md / deps.md / .state.md）
- `pl-status.sh` / `pl-dashboard-refresh.sh` / `pl-migrate-legacy.sh`
- adapter 协议 v1（requires / piao_emit / build_adapter / rules / skills / agents）
- 两个官方 adapter：`adapter-nextjs-web` / `adapter-python-fastapi`
- 两个端到端 demo：`demo-nextjs-todo` / `demo-fastapi-users`

### Known Issues（v1.0 的主要限制，在 v1.2.0 解决）
- gate 判据是散文 → **v1.2 E1 解决**
- VERIFY 不启动应用（只跑静态检查）→ **v1.2 E2 解决**
- rule 只是 AI prompt 不能 CI 跑 → **v1.2 E3 解决**
- 无法发现"宿主依赖不符合 adapter 期望"类 bug → **v1.2 E4 解决**

---

## Unreleased

### Planned for v1.3
- KuiklyPolyCity 宿主级迁移验证（跑 pl-runner/pl-smoke/contract-drift/rule-scan 四件套）
- 更多 adapter（kotlin-kmm / rust-cargo / go-modules）
- `pl-runner` MVP 级联测试：一条命令跑完整 5 门禁

### Planned for v2.0
- TypeScript CLI 重写（`packages/cli` + `packages/core`）
- `pl init --smart`：技术栈扫描 + Preset 推荐
- MCP Server 适配所有 MCP 兼容 IDE
- 文档站（pl-pipeline.dev）

---

[1.2.0]: https://github.com/walkertop/pl-pipeline-standalone/releases/tag/pl-v1.2.0
[pl-v1.1.2-alpha]: https://github.com/walkertop/pl-pipeline-standalone/releases/tag/pl-v1.1.2-alpha
[pl-v1.1.1-alpha]: https://github.com/walkertop/pl-pipeline-standalone/releases/tag/pl-v1.1.1-alpha
[pl-v1.1.0-alpha]: https://github.com/walkertop/pl-pipeline-standalone/releases/tag/pl-v1.1.0-alpha
[1.0.0]: https://github.com/walkertop/pl-pipeline-standalone/releases/tag/v1.0.0
[Unreleased]: https://github.com/walkertop/pl-pipeline-standalone/compare/pl-v1.2.0...HEAD
