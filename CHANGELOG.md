# Changelog

本项目的所有显著变更都会记录在此。

格式遵循 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/)，
版本号遵循 [语义化版本](https://semver.org/lang/zh-CN/)。

---

> 📍 **2026-04-23 阶段性回顾**：v1.3.x 观察层系列已在两天内完成
> （v1.3.0-alpha → v1.4.0-alpha → v1.3.2-alpha → v1.3.2-alpha.2）。
> 总结文档 + 下一阶段规划见 [`docs/milestones/2026-04-v1.3.x-summary.md`](./docs/milestones/2026-04-v1.3.x-summary.md)。
>
> 🔴 **2026-04-23 识别出关键缺口**：`assets/pl/` 下无 skills / rules / agents，
> 通用能力物理上住在 KuiklyPolyCity。新用户执行 `/pl:*` 命令会发现命令是空壳。
> 已立 v1.5 milestone 处理：[`docs/milestones/v1.5-migrate-core-assets.md`](./docs/milestones/v1.5-migrate-core-assets.md)。
>
> 📖 同时新增辩证方法论文档：[`docs/guides/working-with-fuzzy-intent.md`](./docs/guides/working-with-fuzzy-intent.md)
> —— 教用户怎么用格式化工具而不被它框死。

---

## [1.5.0-alpha] — 2026-04-23 · Core Assets Migration · D1+D2

v1.5 第一阶段：**核心资产基础设施 + 样本迁移**。
完成后 pl-pipeline-standalone 不再"有流程无脑"。

### ✨ Added

- **通用资产目录骨架**
  - `assets/pl/skills/` + README（含分层说明：通用 < 栈级 < 项目级）
  - `assets/pl/rules/` + README（含 frontmatter 规范）
  - `assets/pl/agents/` + README
  - 三层加载优先级：项目 > 栈 > 通用

- **脱敏指南**：[`docs/guides/asset-sanitization-guide.md`](./docs/guides/asset-sanitization-guide.md)
  - 硬脱敏 / 软脱敏规则
  - Frontmatter 强制字段（id / version / scope / category / migrated_from）
  - 5 步迁移工作流 + PR Review Checklist
  - 3 种常见错误

- **样本资产：`spec-normalizer@1.0.0`**
  - 从 KuiklyPolyCity 迁入并脱敏
  - **硬耦合点 19 → 0**（仅保留合法的 `migrated_from` 追溯字段）
  - 2 个不同域示例（电商订单 / 博客编辑器）
  - 改良：标注可选章节、新增辩证使用提示、提及 working-with-fuzzy-intent

### 📋 迁移证据
- `docs/retros/asset-migration/spec-normalizer-coupling-scan-before.txt`
- `docs/retros/asset-migration/spec-normalizer-coupling-scan-after.txt`
- `docs/retros/asset-migration/spec-normalizer-migration.md`（Before/After 详细对比 + override 计划）

### 🔜 v1.5 后续阶段

- D3: 批量迁移 M2~M7（finalization-template / 3 个 rules / 2 个 agents）
- D4: KuiklyPolyCity 侧改为 override 并回测
- D5: 写 `adapter-authoring.md` + `v1.4-to-v1.5.md` 升级文档
- D6: 打正式版 tag `pl-v1.5.0`

---

## [1.3.2] — 2026-04-23 · Dashboard Live Reload（正式版）

本版本是 `1.3.2-alpha` → `1.3.2-alpha.2` 两次打磨后的**稳定版**。
包含了原 alpha 的全部能力 + 一个严重 bug 修复 + 完整用户文档。

- **完整能力**：自写 SSE server + `EventSource` 客户端 + 增量 render + 自动重连 + 静默降级（详见 [1.3.2-alpha] 段）
- **关键修复**：per-subscriber snapshot（详见 [1.3.2-alpha.2] 段）
- **用户文档**：[`docs/dashboard-guide.md`](./docs/dashboard-guide.md)（30 秒上手 / 4 种启动姿势 / 5 条 FAQ）
- **辩证方法论**：[`docs/guides/working-with-fuzzy-intent.md`](./docs/guides/working-with-fuzzy-intent.md)

从 alpha 升级：**无 API 变更**，只需 `git pull` 重启 `pl-dashboard.sh`。

---

## [1.3.2-alpha.2] — 2026-04-23 · snapshot-lost 修复 + 用户文档

### 🐛 Fixed

- **snapshot 丢失 bug（严重）**：v1.3.2-alpha 里 `tail_jsonl_watcher` 的 snapshot 由共享 watcher 线程广播给当前所有订阅者，变量 `snapshot_sent` 是 watcher 级别而非订阅者级别。第二个及以后的订阅者都收不到初始全量，导致 Dashboard 多开浏览器 tab 时部分 tab 只显示空壳。
  - 修复：Broadcaster 引入 `snapshot_fn` 字段，`subscribe()` 时对**每个新订阅者**独立生成并发送当前全量 snapshot；watcher 只负责后续 `append / reset / missing`。
  - 影响面：所有 change 详情页和 index 首页的 live 订阅。
  - 复现命令：连跑两次 `curl -N /_events/stream?change=<id>`；修复前第二次只见 `hello`，修复后每次都能收到完整 snapshot。

- **ConnectionResetError 噪音**：浏览器切页/关 tab 时大量 "Connection reset by peer" traceback 污染 server log，掩盖真实错误。
  - 修复：重载 `ThreadingHTTPServer.handle_error`，对 `ConnectionResetError / BrokenPipeError` 静音；设 `PL_DASHBOARD_VERBOSE=1` 可恢复。

- **index_watcher 启动多推一条相同 updated**：`last_sig=None` 导致首次循环必然 publish；snapshot 职责移出后应初始化为当前 sig。
  - 修复：新增 `_compute_index_sig()`，watcher 启动时即以当前状态初始化。

### 📝 Docs

- 新增用户使用文档：[`docs/dashboard-guide.md`](./docs/dashboard-guide.md)
  - 30 秒上手 / 三种启动姿势 / 视图详解 / live badge 四态 / 降级策略 / 常见问题 5 条
  - 引用 `docs/retros/evidence-2026-04-v1.3.2/change-live.png` 作为效果示例

### 🧪 验证

- 两个连续订阅者均收到完整 snapshot
- 浏览器切页时 server log 干净
- E2E 手测：3 个 change 的卡片 / change 详情页 info-cards / timeline 均正确渲染

---

**主题：Dashboard 从静态快照升级为实时推送。**

v1.3.0-alpha 提供了可视化基础设施（observe 层 + dashboard 双视图），
但观察者每次必须手动刷新页面才能看到新事件。本版完成实时推送，让"观察"真正具备可观性。

### ✨ Added

- **SSE 长连接服务端**（`scripts/_lib/dashboard-server.py`）
  - 零第三方依赖（仅 Python stdlib：`http.server` + `threading` + `queue`）
  - `GET /_events/stream?change=<id>` — 单 change events.jsonl tail，推送 `snapshot / append / reset / missing` 事件
  - `GET /_events/index` — trace 目录整体变化（新 change 出现 / 现有 change 有更新）
  - `HEAD /_events/ping` — 前端能力探测端点
  - 多订阅者共享单个 watcher 线程；最后一个订阅者离开时 watcher 自动停止
  - 15s 心跳（`: keepalive\n\n`）防中间件断连
  - 支持 jsonl rotate / truncate（发 `reset` 事件让客户端重订阅）

- **SSE 客户端库**（`dashboard/assets/live.js`）
  - `probeLiveReload()` — HEAD 探测，2s 超时
  - `subscribeChange(changeId, handlers)` — 订阅单 change 流
  - `subscribeIndex(handlers)` — 订阅目录流
  - `EventSource` 指数退避自动重连（1s → 15s，上限）
  - `mountStatusBadge()` — 头部状态徽章工厂

- **前端 Live Reload 集成**
  - `change.html`：收到 `snapshot` 渲染全量，`append` 增量 prepend（1.2s 闪烁高亮），同步刷新 info cards 和 stage pipeline
  - `index.html`：收到 `updated` 按 change_id 粒度增量 upsert / remove 卡片
  - 顶部 Live 徽章四态：`● live` / `◐ connecting` / `✕ reconnect` / `○ static`

- **降级路径**
  - `pl-dashboard.sh --static-only` 回退到 `python3 -m http.server`（v1.3.0 原行为）
  - 前端 probe 失败自动退回一次性静态加载模式，徽章显示 `○ static`

### 🎨 UI

- 新事件行进场动画：`@keyframes event-flash`（1.2s accent 色背景渐隐）
- Live 徽章脉动：`@keyframes live-pulse`（on 状态 1.8s 周期，connecting 0.9s）
- 新增 `.live-badge` 4 种状态样式

### 🔧 Changed

- `scripts/pl-dashboard.sh` 默认走新 server（live-reload 模式），新增 `--static-only` 参数
- live-reload 模式下 `/trace/*` 路由由 server 直接处理（不再强依赖 symlink；symlink 仍保留用于 static-only 兼容）

### 📐 架构备注

选 SSE 而非 WebSocket：
- WebSocket 需要额外库 + 握手复杂度
- SSE 单向推送已满足"服务端→浏览器"的事件流场景
- 浏览器 `EventSource` 原生支持自动重连，客户端代码极简

选自写 `BaseHTTPRequestHandler` 而非 `python3 -m http.server`：
- stdlib `http.server` 不支持长连接端点
- 自写 server 仍保持零第三方依赖原则

### 🧪 E2E 验证

- `pl-dashboard.sh` 启动 → curl `/_events/stream` 看到 `hello / snapshot / append` 推送
- Playwright 打开 index.html → 追加事件后卡片自动刷新任务计数 + 事件数
- Playwright 打开 change.html → 追加事件后 timeline 实时多出新行
- `--static-only` 模式下前端 probe 失败，徽章显示 `○ static`，功能降级到 v1.3.0

证据快照：`docs/retros/evidence-2026-04-v1.3.2/change-live.png`

---

## [1.3.0-alpha] — 2026-04-22 · Observe 层 MVP

**主题：从"事件已发生"到"事件可被看见"。**

### ✨ Added

- **事件信封 schema v1.3**（`assets/pl/schemas/event-v1.3.schema.json`）
  - 8 字段规范：`ts / trace_id / change_id / phase / actor / event / data / parent_trace_id?`
  - actor 三类：`agent:<id>@<ver>` / `rule:<id>@<ver>` / `skill:<id>@<ver>`

- **零依赖 fs watcher**（`scripts/_lib/observe-fs.py`）
  - Python stdlib 轮询（0.5s 间隔）
  - 21 个资产（rule / skill）批量补 frontmatter `id + version`（`scripts/_lib/backfill-frontmatter.py`）

- **业务语义规则引擎**（`scripts/_lib/observe-apply-rules.py`）
  - 5 条默认规则（`assets/pl/observe-rules.default.yaml`）：taskdag row added / taskdag task done / state stage transition / rule asset promoted / skill asset promoted
  - 规则把 `artifact.modified` 类底层事件聚合为 `plan.task.added / task.done / state.transition / asset.promoted` 业务事件
  - 去重 key 含 captures，避免一次大修改被当成一条

- **Dashboard MVP 双视图**（`dashboard/`）
  - index.html：change 列表（卡片、stage、gate、tasks、violation）
  - change.html：单 change timeline + 3 维过滤 + payload 展开
  - 纯静态 HTML + CSS + ES modules，无构建
  - dark/light 主题切换（localStorage 持久化）

### 🧪 实测

- 48 events，Playwright 验证 index / change / filter / payload expand 全通过

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
