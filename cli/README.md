# pl — pl-pipeline CLI

> 零依赖 · 薄壳封装 · 在任何终端可用（VS Code / Claude Code / iTerm / Warp）

## 安装

```bash
# 方式一：全局 link（开发期）
cd pl-pipeline-standalone/cli
npm link

# 方式二：全局安装（发布后）
npm install -g pl-pipeline
```

验证：

```bash
pl --help
```

---

## 命令速查

| 命令 | 说明 | 对应脚本 |
|------|------|---------|
| `pl init` | 初始化 pl 骨架 | 内置 JS |
| `pl init --adapter <id>` | 初始化 + 装 adapter | 内置 + `adapter-install.sh` |
| `pl adapter <id>` | 安装 adapter | `adapter-install.sh` |
| `pl new <change-id>` | 创建 change | `pl-state-init.sh` |
| `pl start <PHASE>` | 开始阶段 | `pl-phase.sh` |
| `pl end <PHASE> [result]` | 结束阶段 | `pl-phase.sh` |
| `pl gate <GATE> <result>` | 门禁评估 | `pl-phase.sh` |
| `pl task <start\|end> <ID>` | 任务开始/结束 | `pl-phase.sh` |
| `pl check <name> <result>` | 检查项 | `pl-phase.sh` |
| `pl artifact <create\|update> <path>` | 产物记录 | `pl-phase.sh` |
| `pl done` | 完成 workflow | `pl-phase.sh` |
| `pl verify [change-id]` | 观测完整性检查 | `pl-observe-check.sh` |
| `pl status [change-id]` | trace 摘要 | `pl-phase.sh status` |
| `pl dashboard [--port N]` | 启动 Dashboard | `pl-dashboard.sh` |

---

## 完整使用示例

### 1. 新项目从零开始

```bash
mkdir my-app && cd my-app
npm init -y
# ... 创建你的项目

# 初始化 pl + 安装 adapter
pl init --adapter nextjs-web
```

### 2. 创建 change 并走流水线

```bash
# 创建 change（自动生成 .state.md + 初始 trace）
pl new add-login --name "用户登录" --domain "auth"

# ─── SPEC 阶段 ─────────────────────────────────
# 写 spec.md ...
pl artifact create spec.md
pl gate A0 pass
pl end SPEC

# ─── PLAN 阶段 ─────────────────────────────────
pl start PLAN
# 写 taskdag.md ...
pl artifact create taskdag.md
pl gate B1 pass
pl end PLAN

# ─── IMPLEMENT 阶段 ────────────────────────────
pl start IMPLEMENT
pl task start T01
# 编码 ...
pl artifact create src/auth/login.ts
pl task end T01
pl task start T02
# 编码 ...
pl task end T02
pl gate D pass
pl end IMPLEMENT

# ─── VERIFY 阶段 ───────────────────────────────
pl start VERIFY
pl check tsc pass
pl check eslint pass
pl check build pass
pl verify              # 观测完整性检查
pl check observe pass
pl gate E pass
pl end VERIFY

# ─── ARCHIVE ───────────────────────────────────
pl done

# ─── 查看结果 ──────────────────────────────────
pl status
pl dashboard --port 8777
```

### 3. 查看帮助

```bash
pl --help
```

---

## 设计原则

1. **薄壳**：CLI 不重写任何逻辑，只调用现有 bash 脚本
2. **零依赖**：纯 Node.js stdlib，无 `commander` / `yargs` / `chalk`
3. **自动识别 change**：`start/end/gate/task/check/artifact/done` 自动找到当前活跃 change（最新的非 ARCHIVE 状态）
4. **PL_HOME 自动推导**：从 CLI 安装路径反推，用户无需 `export`
5. **终端兼容**：无交互式操作，所有命令都是单次执行，适合脚本和 CI

---

## 目录结构

```
cli/
├── package.json       ← name: "pl-pipeline", bin: { pl: "./bin/pl.js" }
├── bin/
│   └── pl.js          ← 入口：解析子命令，分发到 lib/
└── lib/
    ├── utils.js       ← 公共工具（getPLHome / runScript / findActiveChange）
    ├── init.js        ← pl init
    ├── adapter.js     ← pl adapter
    ├── new.js         ← pl new
    ├── phase.js       ← pl start/end/gate/task/check/artifact/done
    ├── verify.js      ← pl verify
    ├── status.js      ← pl status
    └── dashboard.js   ← pl dashboard
```

---

## 与 bash 脚本的关系

CLI 是 bash 脚本的**友好入口**，不是替代品。底层脚本仍然可以直接调用：

```bash
# 这两个等价：
pl new my-feature
bash $PL_HOME/scripts/pl-state-init.sh my-feature

# 这两个等价：
pl start SPEC
bash $PL_HOME/scripts/pl-phase.sh my-feature start SPEC
```

CLI 的额外价值：
- 不用记 `$PL_HOME` 路径
- 不用手动指定 `change-id`（自动识别活跃 change）
- 命令更短（`pl start SPEC` vs `bash $PL_HOME/scripts/pl-phase.sh my-feature start SPEC`）
