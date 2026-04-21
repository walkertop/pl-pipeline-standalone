# 三层架构：piao · pl · adapter

> pl-pipeline 的核心架构决策：把 AI 研发范式拆成**三个彼此独立、契约清晰**的层次。
>
> 这一页讲清楚它们各自是什么、谁依赖谁、什么不会跨层侵蚀。

---

## 0. TL;DR

```
┌────────────────────────────────────────────────────────────────┐
│  Layer 3 · Adapter（场景特定）                                  │
│  ────────────────────────────────────────                     │
│  adapter-nextjs-web / adapter-python-fastapi / ...             │
│  每个 adapter 自带：                                            │
│    • templates/ (spec/plan/taskdag 填充场景示例)                 │
│    • agents/    (场景专家 AI prompts)                          │
│    • skills/    (场景最佳实践)                                  │
│    • rules/     (场景编码规范)                                  │
│    • scripts/   (build/verify/lint 命令)                       │
│    • adapter.yaml (Manifest · 声明上述注入内容)                  │
└────────────────────────┬────────────────────────────────────────┘
                         │ 依赖
                         ▼
┌────────────────────────────────────────────────────────────────┐
│  Layer 2 · pl-core（执行层 DSL · 场景无关）                      │
│  ────────────────────────────────────────                     │
│  6 阶段状态机：SPEC → PLAN → IMPLEMENT → VERIFY → OBSERVE →     │
│                ARCHIVE                                         │
│  7 道门禁：A0 / B1 / C / D / E / F / G                         │
│  7 件产物：spec / plan / taskdag / api / testmatrix / deps /    │
│            .state.md                                           │
│  9 条命令：/pl:proposal ... /pl:archive                        │
│  编排器：scripts/pipeline-orchestrator.sh                      │
└────────────────────────┬────────────────────────────────────────┘
                         │ 依赖
                         ▼
┌────────────────────────────────────────────────────────────────┐
│  Layer 1 · piao-kernel（语义底座 · 不知道有 pipeline）           │
│  ────────────────────────────────────────                     │
│  URN 身份 + Artifact 模型 + 分层事件 + 快照 + 漂移 + 演化 +     │
│  扩展性 七维核心模型                                            │
│  scripts/piao-*.sh : snapshot-produce / snapshot-diff /        │
│                      drift-compute / evolution-scan /          │
│                      kernel-wordcheck                          │
│  assets/piao/schemas/ : urn / event / snapshot                 │
│  assets/piao/docs/    : kernel 宪章七篇 + 封版决议 + 债账本     │
└────────────────────────────────────────────────────────────────┘
```

**三句话讲清谁依赖谁**：
1. **piao-kernel 不知道有 pl-pipeline** —— 它只是一套跨领域可用的语义规范。
2. **pl-core 不知道有具体场景** —— 它只管"流程怎么走"，不关心"写的是 React 还是 FastAPI"。
3. **adapter 不定义流程** —— 它只回答"在这个技术栈下，pl-core 每一步具体该调什么命令、用什么 prompt"。

---

## 1. Layer 1 · piao-kernel（语义底座）

### 1.1 一句话定位

> 一套**契约**，规定"AI 研发系统里的任何东西（artifact / event / task / 决策）长什么样、怎么命名、怎么追溯"。

### 1.2 它定义什么

| 概念 | 回答的问题 | 落地 |
|---|---|---|
| **URN 身份** | 系统里的实体怎么命名？ | `urn:piao:<kind>:<scope>:<name>@<rev>` 格式（`assets/piao/schemas/urn.schema.json`） |
| **Artifact 模型** | 产出物有什么共同契约？ | front-matter 五字段 + content_sha256 |
| **Event Journal** | 事件怎么写、怎么追溯？ | append-only JSONL + L1 10 类事件枚举（`event.schema.json`） |
| **Version Snapshot** | 某一时刻的冻结照片长什么样？ | canonical YAML 五步规范化（`snapshot.schema.json`） |
| **Drift Engine** | 快照之间不一致怎么办？ | added / removed / sha_changed / unchanged 四类 |
| **Evolution Layer** | 错误怎么反哺系统？ | drift → evolution.scanned → 记忆注入 |
| **Extensibility** | 什么能扩、什么不能？ | kernel 7 扩展点 A-G，锁定封板语义 |

### 1.3 它刻意不做什么

- ❌ **不知道场景词**：`kernel/scenario-wordlist.md` 明文禁止 `weex / react / ios / gradle / npm` 等场景词出现在 kernel 文档
- ❌ **不定义流水线阶段**：SPEC/PLAN/... 是 pl 层的事
- ❌ **不关心 IDE**：kernel 不依赖任何 IDE / LLM / MCP
- ❌ **不做分布式**：单机 + JSONL + 本地快照

### 1.4 成熟度

**v0.1 已封版**（2026-04-19）。终态单一事实源：
[`assets/piao/docs/kernel/_review/v0_1-final-decisions.md`](../assets/piao/docs/kernel/_review/v0_1-final-decisions.md)

---

## 2. Layer 2 · pl-core（执行层 DSL）

### 2.1 一句话定位

> 一套**可操作的流水线脚手架**，把"做一次研发变更"拆成 6 个阶段、7 件产物、9 条命令，让 Agent 可以断点恢复。

### 2.2 它定义什么

| 概念 | 约束 | 落地 |
|---|---|---|
| **Change** | 一次研发活动的最小单元 | `pl/changes/<change-id>/` 目录 |
| **Stage** | 6 个顺序阶段 | `SPEC → PLAN → IMPLEMENT → VERIFY → OBSERVE → ARCHIVE` |
| **Gate** | 7 道可机械校验的门禁 | A0 / B1 / C / D / E / F / G |
| **Artifact (7 件)** | change 目录下的标准产物 | `spec.md / plan.md / taskdag.md / api.md / testmatrix.md / deps.md / .state.md` |
| **Command** | 9 条 `/pl:*` slash | `proposal / plan / implement / apply / verify / archive / status / migrate / explore` |
| **Orchestrator** | 自动编排 + 断点恢复 | `scripts/pipeline-orchestrator.sh` |

### 2.3 它向 piao 提供的回报

pl 每次阶段切换（VERIFY / ARCHIVE 末尾）**向 piao kernel-events 写 `artifact.published` 事件**，用 `urn:piao:artifact:pl:...` 命名空间把 pl 产物挂到 piao 身份体系下。这是 pl 成为 piao 的"首个适配器"的证据。

### 2.4 它刻意不做什么

- ❌ **不定义产物里写什么业务内容**（那是 adapter 的事，见 §3）
- ❌ **不绑定任何构建工具**（通过 adapter 注入的 `$PL_BUILD_CHECK_CMD` 调用）
- ❌ **不关心代码是哪种语言**

### 2.5 成熟度

**v1.0 已独立**（2026-04-20）。宿主 KuiklyPolyCity 现有 4 个 change 跑在 pl-core 上。

---

## 3. Layer 3 · Adapter（场景层）

### 3.1 一句话定位

> 一套**可插拔的场景扩展包**，告诉 pl-core "在 React / Python / iOS / ... 这个场景下，每一步具体怎么做"。

### 3.2 Adapter 的构成（全家桶）

每个 adapter 都是一个目录（未来可发 npm 包），包含：

```
adapters/adapter-<name>/
├── adapter.yaml        ← ⭐ Manifest，声明对外提供什么
├── README.md
├── templates/          ← 覆盖 pl-core 的通用模板，填场景示例
│   ├── spec.md
│   ├── plan.md
│   └── taskdag.md
├── agents/             ← 场景专家 AI prompts
│   ├── <name>-architect.md
│   └── <name>-reviewer.md
├── skills/             ← 场景最佳实践
│   ├── <topic>-patterns.md
│   └── ...
├── rules/              ← 场景编码规范
│   ├── <lang>-style.md
│   └── ...
├── scripts/            ← 场景构建 / 验证 / 静态检查命令
│   ├── build.sh
│   ├── verify.sh
│   └── lint.sh
└── docs/case-study.md  ← 一个完整 demo 项目的迁移记录
```

### 3.3 adapter.yaml Manifest 长什么样

```yaml
apiVersion: pl.dev/v1
kind: Adapter
metadata:
  id: nextjs-web
  version: 0.1.0
  compatible_pl: ">=1.0.0 <2.0.0"
  compatible_piao: ">=0.1.0"
  detect:
    - file_exists: "next.config.js"
    - file_exists: "next.config.ts"

provides:
  templates:    { spec: "templates/spec.md", ... }
  agents:       [ { path: "agents/nextjs-architect.md" } ]
  skills:       [ ... ]
  rules:        [ ... ]
  scripts:      { build: "scripts/build.sh", verify: "scripts/verify.sh" }
  build_adapter:
    type: npm
    commands:
      compile_check: { cmd: "npm run typecheck", success_pattern: "Found 0 errors" }

requires:
  tools: [ { name: node, min_version: "18" } ]

piao_emit:
  on_stages: [VERIFY, ARCHIVE]
  urn_namespace: "urn:piao:artifact:pl:nextjs-web"
```

### 3.4 独立仓首批 adapter（MVP）

| adapter | 场景 | 状态 |
|---|---|---|
| `adapter-nextjs-web` | Next.js 前端项目（App Router / RSC / TypeScript） | 🚧 Phase 3 交付 |
| `adapter-python-fastapi` | FastAPI 后端项目（Pydantic v2 / SQLAlchemy async / pytest） | 🚧 Phase 3 交付 |

### 3.5 为什么 weex-to-kuikly **不**进独立仓

宿主 KuiklyPolyCity 里的 Weex→Kuikly 迁移是 pl-pipeline 孕育的**摇篮**，但它作为场景过于特化（腾讯内部 · Kuikly 框架 · Vue 老代码）。独立仓只收录**广义开发者场景**（Next.js / FastAPI）来证明"三层可扩展"，Kuikly 相关的 agents/skills/rules 继续留在宿主项目。

---

## 4. 三层协作的全流程（一次请求的端到端轨迹）

用一个 React 项目"加深色模式"的 change 为例：

```
1. 用户在 CodeBuddy 聊天框：/pl:proposal add-dark-mode
        ↓
2. pl-core 读 pl/config.yaml → 发现 adapter: nextjs-web
        ↓
3. pl-core 加载 adapter-nextjs-web/templates/spec.md → 作为 spec 模板脚手架
   pl-core 加载 agents/nextjs-architect.md → 作为这次 proposal 的专家 prompt
        ↓
4. 用户 + AI 协作生成 pl/changes/add-dark-mode/spec.md
        ↓
5. 每次推进阶段时 (SPEC→PLAN / PLAN→IMPLEMENT / ...):
   pl-core 把 .state.md 的 stage 字段写新值 + 生成 artifact.published 事件
        ↓
6. piao 层：scripts/trace-emit.sh 把上一步的事件写入
   $PL_OUTPUT/piao/kernel-events/2026-04.jsonl (append-only)
        ↓
7. /pl:verify 阶段：
   pl-core 调 adapter-nextjs-web/scripts/verify.sh
     → 里面实际跑 `npm run typecheck && npm run lint && npm test`
     → 结果写回 .state.md 的 Self-Check Results 节
        ↓
8. /pl:archive 阶段：
   pl-core 调 scripts/piao-snapshot-produce.sh 封板本次 change
     → 产出 snapshot artifact (canonical YAML + sha256)
     → 挂到 piao URN 命名空间：urn:piao:snapshot:adapter-nextjs-web:...
     → 写 artifact.published 事件到 kernel-events
        ↓
9. 下次类似 change 时：
   piao 的 evolution layer 读 kernel-events → drift-compute 定位上次教训
   → 把新学到的"React 深色模式踩坑"注入 adapter-nextjs-web/skills/
```

**每一步都是事件**（piao 管），**每个阶段切换点都有快照**（piao 管），**每个错误都是演化输入**（piao 管）；pl-core 只是那个"跑每一步"的编排者；adapter 只是那个"每一步具体怎么做"的扩展包。

---

## 5. 反向追溯的三个承诺

这套三层架构对使用者做了三个可验证的承诺：

### 5.1 "AI 写过的任何代码都能追溯到某个 URN"

因为：pl-core 的 7 件产物都有 URN + sha256（piao 契约），任何一行代码都能通过 `grep "urn:piao:artifact:pl:" git-log` 反查到那次 change。

### 5.2 "换 AI / 换人接手，上下文不会丢"

因为：`.state.md` 是真相源（pl 契约），读它就能知道 change 走到哪、哪些任务完成了、哪些门禁通过了。

### 5.3 "同一套 pl 命令在 React / Python / iOS 项目里体验一致"

因为：pl-core 的 9 条 `/pl:*` 命令是场景无关的，场景差异全被 adapter 吸收。

---

## 6. 反例：什么违反了三层架构

以下情况说明架构被破坏，PR 会被拒：

| 违规示例 | 违反了什么 |
|---|---|
| pl-core 脚本里硬编码 `./gradlew compileDebugKotlinAndroid` | L2 侵蚀到 L3（应由 adapter 注入） |
| piao-kernel 文档出现 "Next.js" 这样的场景词 | L1 侵蚀到 L3（被 `piao-kernel-wordcheck.sh` 拦截） |
| adapter 里重新定义 Stage 为 7 个阶段 | L3 篡改 L2（pl-core 是单一真源） |
| adapter 绕过 pl-core 直接写 JSONL 到 kernel-events | L3 越级调 L1（必须经 L2 发事件） |

---

## 7. 进一步阅读

- **piao 宪章**：[`assets/piao/docs/README.md`](../assets/piao/docs/README.md) · [`kernel/_review/v0_1-final-decisions.md`](../assets/piao/docs/kernel/_review/v0_1-final-decisions.md)
- **pl-core 设计**：[`MIGRATION_CHECKLIST.md`](../MIGRATION_CHECKLIST.md) · [`LAYER_ANALYSIS.md`](./LAYER_ANALYSIS.md)
- **Adapter 规范**（Phase 3 交付）：`assets/adapter-sdk/docs/adapter-authoring-guide.md`
- **工作守则**：[`CONTRIBUTING.md`](../CONTRIBUTING.md)

---

## 最后一行永远是同一句话

> 这个系统的价值不在每个模块多先进，而在它们**共用一套契约**。契约破了，系统就是普通脚手架。
