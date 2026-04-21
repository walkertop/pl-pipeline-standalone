# MVP 状态与路线图

> 最后更新：2026-04-21（Phase 4 完成）

---

## 一眼看清版本现状

| 层 | 状态 | 里程碑 |
|---|---|---|
| **piao-kernel** (L1 语义底座) | ✅ 独立可用 | `phase/P1-complete` |
| **pl-core** (L2 执行层) | ✅ 独立可用 | `phase/P2-complete` |
| **adapter ecosystem** (L3 场景) | ✅ 首批 2 个 adapter + 脚手架就位 | `phase/P3-complete` |
| **examples / docs** | ✅ 端到端样例 + 文档补齐 | `phase/P4-complete` |
| npm 打包（`npx pl init` 愿景） | 🚧 v0.2 规划中 | — |
| 多 IDE 一等公民（cursor/claude-code/codex） | 🚧 v0.2 规划中 | — |
| 社区 adapter 市场 | 🚧 v1.0 | — |

---

## 三层架构现状

```
┌─────────────────────────────────────────────────────────────┐
│  L3  Adapters（场景适配 = 全家桶）                          │
│  ┌────────────────────┐  ┌────────────────────┐  ┌───────┐  │
│  │ adapter-nextjs-web │  │adapter-python-     │  │ 你可以 │  │
│  │     v0.1.0 ✅       │  │     fastapi v0.1.0 │  │ 用     │  │
│  │ 18 文件 / 1866 行  │  │ 18 文件 / 2250 行  │  │ adapter-│  │
│  │                    │  │                    │  │create  │  │
│  │ demo: demo-nextjs- │  │ demo: demo-fastapi-│  │ .sh 新建│  │
│  │   todo 端到端 ✅    │  │   users 端到端 ✅   │  │        │  │
│  └────────────────────┘  └────────────────────┘  └───────┘  │
└───────────┬──────────────────────┬──────────────────────────┘
            │  provides 契约:       │
            │   templates / agents / skills / rules / scripts /
            │   build_adapter / piao_emit
            ▼                      ▼
┌─────────────────────────────────────────────────────────────┐
│  L2  pl-core（执行层 DSL）                                  │
│  - 6 阶段状态机：SPEC→PLAN→IMPLEMENT→VERIFY→OBSERVE→ARCHIVE │
│  - 7 门禁：A0 / B1 / C / D / E / F / G                      │
│  - 7 件产物 + 5 件 JSON Schema                              │
│  - 13 个独立脚本（pl-status / dashboard / orchestrator...） │
│  - 9 个 IDE slash command (ide-integrations/codebuddy/)     │
└───────────┬─────────────────────────────────────────────────┘
            │  optional piao_emit（默认关闭）：
            │   artifact.published → kernel-events
            ▼
┌─────────────────────────────────────────────────────────────┐
│  L1  piao-kernel（语义底座，可选）                          │
│  - URN / 事件 / 快照 3 份 JSON Schema                       │
│  - kernel-wordcheck / snapshot-produce / snapshot-diff /    │
│    drift-compute / evolution-scan 共 5 个脚本               │
│  - 47 个 kernel 文档                                        │
└─────────────────────────────────────────────────────────────┘
```

---

## 验收证据（Phase 1 ~ Phase 4）

### Phase 1 — piao-kernel 独立化
- ✅ 5 份 kernel 脚本（wordcheck / snapshot-produce / snapshot-diff / drift-compute / evolution-scan）均可对**任意宿主**运行
- ✅ 3 份 JSON Schema（urn / event / snapshot）校验宿主真实 26 条 kernel-events（25/26 合规，已定位唯一不合规项）
- ✅ 47 个 kernel 文档完整迁移

### Phase 2 — pl-core 解耦
- ✅ `_env.sh` 提供 `PL_HOME/PL_PROJECT/PL_ASSETS/PL_CHANGES/PL_OUTPUT` 路径解析
- ✅ 8 件 pl 产物模板业务词全部清洗（piao-kernel-wordcheck 零告警）
- ✅ `config.default.yaml` 的 `upstream_protocol.enabled=false`，pl-core 可完全独立运行
- ✅ 宿主 KuiklyPolyCity 仍使用本仓脚本：`pl-status.sh / pl-dashboard-refresh.sh / pl-migrate-legacy.sh` 三工具全通过

### Phase 3 — adapter 生态
- ✅ `adapter-manifest.schema.json`（draft/2020-12）+ 3 份规范文档
- ✅ `adapter-validate.sh` / `adapter-install.sh`（injection-contract v1）
- ✅ **adapter-nextjs-web v0.1.0**：18 文件，真实安装 15 文件落位 100% 正确
- ✅ **adapter-python-fastapi v0.1.0**：18 文件，同上
- ✅ `adapter-create.sh`：`--minimal` / `--full` / `--force` / `--dest` 8 条路径全过，`--full` 自动通过 adapter-validate

### Phase 4 — examples + 文档
- ✅ **demo-nextjs-todo**（34 文件，2582 行）：adapter-install 注入 → 5 件 change 产物填写 → Next.js 源码 → pl-status 识别 `ARCHIVE 11/11`
- ✅ **demo-fastapi-users**（49 文件，3524 行）：同上，pl-status 识别 `ARCHIVE 12/12`，`py_compile` 全量扫描 0 语法错误
- ✅ `MVP_STATUS.md` 重写反映三层架构（本文件）
- ✅ `ROADMAP.md` / `FAQ.md` 入库
- ✅ `.github/` PR / Issue / workflow 模板入库
- ✅ adapter-sdk `authoring-guide.md` 补充 "v0.1 后的增量"

---

## 仓库结构速览（Phase 4 末）

```
pl-pipeline-standalone/
├── LICENSE / NOTICE / README.md / CHANGELOG.md / VERSION
├── CONTRIBUTING.md / CODE_OF_CONDUCT.md / SECURITY.md
├── ROADMAP.md / FAQ.md / MVP_STATUS.md
│
├── .github/
│   ├── ISSUE_TEMPLATE/{bug_report,feature_request,new_adapter}.md
│   ├── PULL_REQUEST_TEMPLATE.md
│   └── workflows/ci.yml (校验脚本自检 + adapter-validate 矩阵)
│
├── adapters/
│   ├── adapter-nextjs-web/         ← 18 文件
│   └── adapter-python-fastapi/     ← 18 文件
│
├── assets/
│   ├── piao/{schemas,docs}/
│   ├── pl/{schemas,templates,dashboard}/config.default.yaml
│   └── adapter-sdk/{schemas,docs}/
│
├── scripts/ (18 个)
│   ├── _env.sh
│   ├── piao-{kernel-wordcheck,snapshot-produce,snapshot-diff,
│   │         drift-compute,evolution-scan}.sh
│   ├── pl-{status,dashboard-refresh,migrate-legacy}.sh
│   ├── trace-{emit,report}.sh / should-build.sh /
│   │   setup-hooks.sh / pipeline-orchestrator.sh
│   └── adapter-{validate,install,create}.sh
│
├── ide-integrations/codebuddy/commands/pl/ (9 个 slash command)
│
├── examples/
│   ├── demo-nextjs-todo/           ← 34 文件端到端样例
│   └── demo-fastapi-users/         ← 49 文件端到端样例
│
└── docs/
    ├── THREE_LAYERS.md
    ├── piao-scripts-dependency.md
    └── LAYER_ANALYSIS.md
```

---

## 接入方式（v0.1-mvp，现在就能用）

### 方式 1：直接调用

```bash
export PL_HOME="/path/to/pl-pipeline-standalone"
cd your-project

# 初始化 pl 结构
mkdir -p pl/{changes,templates} .codebuddy/{agents,skills,rules} scripts
cp $PL_HOME/assets/pl/config.default.yaml pl/config.yaml

# 按技术栈装 adapter（Next.js 为例）
bash $PL_HOME/scripts/adapter-install.sh $PL_HOME/adapters/adapter-nextjs-web .

# 导出 adapter 注入的构建命令
export PL_BUILD_CHECK_CMD="npx tsc --noEmit"

# 查状态
bash $PL_HOME/scripts/pl-status.sh
```

### 方式 2：alias

```bash
# ~/.zshrc
export PL_HOME="/path/to/pl-pipeline-standalone"
alias pl-status="bash $PL_HOME/scripts/pl-status.sh"
alias pl-install-adapter="bash $PL_HOME/scripts/adapter-install.sh"
alias pl-create-adapter="bash $PL_HOME/scripts/adapter-create.sh"
```

### 方式 3：新技术栈

```bash
# 5 分钟创建你自己的 adapter 骨架
bash $PL_HOME/scripts/adapter-create.sh rust-axum --full
# → adapters/adapter-rust-axum/ 骨架就绪
# 按 authoring-guide.md 填内容
```

---

## 下一步（v0.2 规划）

详见 [`ROADMAP.md`](./ROADMAP.md)。关键里程碑：

- **v0.2（Q2）**：`npx pl-pipeline init --smart` 自动侦测技术栈并推荐 adapter
- **v0.3（Q3）**：MCP 适配器 + cursor / claude-code / codex 一等公民
- **v1.0（Q4）**：社区 adapter 市场，官方 10+ adapter

---

## 验收结论

> **pl-pipeline standalone 在 Phase 4 达到 "公开可用 alpha" 门槛**。

1. ✅ 三层架构完整（piao-kernel / pl-core / adapters）
2. ✅ 两个可工作 reference adapter，均带端到端 demo
3. ✅ 脚手架 `adapter-create.sh` 覆盖所有构造路径
4. ✅ 文档：README / CONTRIBUTING / ROADMAP / FAQ / MVP_STATUS / authoring-guide / manifest-reference / injection-contract
5. ✅ 18 commit + 4 phase tag（P1 / P2 / P3 / P4）
6. ✅ 宿主 KuiklyPolyCity 依然可用本仓脚本，不需要任何修改

**可以 `git init` 公开仓库 + 发 announcement 了**。
