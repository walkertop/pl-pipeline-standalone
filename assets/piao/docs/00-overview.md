# piao-pipeline · 00 Overview

> 一页纸心智模型。读完这一页，应当能在脑子里"跑"完整个系统一遍。

---

## 0. 定位（What is it?）

**piao-pipeline** 是一个 **"状态即事实、演化即一等公民"** 的 AI 辅助研发流水线架构。

它解决一个具体问题：
> **当 Agent 的任何一步出错，整条流水线能感知、定位、传播、修复，并把教训沉淀回系统本身。**

它不是：
- 不是 Workflow 引擎的皮肤（不是 Airflow / Temporal 的复刻）
- 不是 Agent Framework（不规定 Agent 怎么思考）
- 不是 Build System（但借鉴了 DAG、缓存失效、增量构建的思想）

它是：
- 一套 **契约（事件 schema / 身份模型 / Artifact 模型）**
- 一套 **可观测语义（trace / drift / version snapshot）**
- 一套 **演化机制（proposal / evolution event / lazy-load memory）**
- 一个 **前端迁移场景（本仓库首个 adapter）的参考实现**，用来压测契约是否成立

---

## 1. 核心公式

```
Identity × Artifact × Layering × Event × Snapshot × Drift × Evolution × Extensibility = piao-pipeline
```

| 维度 | 回答什么问题 | 所在文档 | 状态 |
|------|------|------|------|
| **Identity** | 系统里的实体怎么命名、怎么索引、怎么关联？ | `kernel/01-identity-model.md` | ✅ M1 定稿（@v1.3 · M7 微升） |
| **Artifact** | 系统生产的"东西"是什么？有什么契约？ | `kernel/02-artifact-model.md` | ✅ M2 定稿（@v1.4） |
| **Layering × Event** | 系统分几层？层间靠什么流动？事件长什么样？ | `kernel/03-layered-architecture.md` | 🚧 draft 持有（未阻塞 · v0.2 候选升版） |
| **Snapshot** | 某一时刻系统的"冻结照片"长什么样？ | `kernel/04-version-snapshot.md` | ✅ M4 定稿（@v1.2） |
| **Drift** | 照片之间不一致时，影响怎么传播、怎么止血？ | `kernel/05-drift-propagation.md` | ✅ M5 定稿（@v1.1） |
| **Evolution** | 经验和错误怎么反哺系统本身？ | `kernel/06-evolution-model.md` | ✅ M6 定稿（@v1.1） |
| **Extensibility** | 哪些是 kernel 通用的，哪些可被场景扩展？ | `kernel/07-extensibility.md` | ✅ M1/M7 定稿（@v1.1 · M7 反向审查通过） |

> **章节 03 的命名变化**（2026-04-18 M3 收尾）：早期 `00-overview` 曾把第 3 章标题写作 `Event Model`，但 M3 落地时论证"层间通信和事件契约必须同一篇定义才能自洽"（见 `03-layered-architecture.md §0`），故将分层模型与事件模型合并为同一章 `03-layered-architecture`，本表已同步。

---

## 2. 一页纸架构图

```
                        ┌───────────────────────────────────┐
                        │           piao-pipeline           │
                        │                                   │
     ┌──────────────────┤   KERNEL (场景无关，跨项目通用)    ├──────────────────┐
     │                  │                                   │                  │
     │                  │  ┌─────────────────────────────┐  │                  │
     │                  │  │ Identity Model              │  │                  │
     │                  │  │  · URN 命名空间             │  │                  │
     │                  │  │  · 全局唯一 ID              │  │                  │
     │                  │  └─────────────────────────────┘  │                  │
     │                  │  ┌─────────────────────────────┐  │                  │
     │                  │  │ Artifact Model              │  │                  │
     │                  │  │  · Artifact 契约            │  │                  │
     │                  │  │  · 内容寻址 + 元数据         │  │                  │
     │                  │  └─────────────────────────────┘  │                  │
     │                  │  ┌─────────────────────────────┐  │                  │
     │                  │  │ Event Journal (append-only) │  │                  │
     │                  │  │  · event_id: 域-时戳-hash   │  │                  │
     │                  │  │  · JSONL，按 unit 分片       │  │                  │
     │                  │  └─────────────────────────────┘  │                  │
     │                  │  ┌─────────────────────────────┐  │                  │
     │                  │  │ Version Snapshot            │  │                  │
     │                  │  │  · 阶段切换点打快照          │  │                  │
     │                  │  └─────────────────────────────┘  │                  │
     │                  │  ┌─────────────────────────────┐  │                  │
     │                  │  │ Drift Engine                │  │                  │
     │                  │  │  · 快照差异 → 影响范围       │  │                  │
     │                  │  │  · 失效传播与止血            │  │                  │
     │                  │  └─────────────────────────────┘  │                  │
     │                  │  ┌─────────────────────────────┐  │                  │
     │                  │  │ Evolution Layer (lazy-load) │  │                  │
     │                  │  │  · L1 索引（轻）+ L2 正文（按需）│                │
     │                  │  │  · 按触发频次加权            │  │                  │
     │                  │  │  · source 可扩展             │  │                  │
     │                  │  └─────────────────────────────┘  │                  │
     │                  │                                   │                  │
     │                  └─────────────┬─────────────────────┘                  │
     │                                │                                        │
     │      实现接口                  │ adapter 接入点                           │
     │                                ▼                                        │
     │        ┌─────────────────────────────────────────────┐                  │
     │        │  ADAPTER: <前端迁移> (第一个落地场景)          │                 │
     │        │                                             │                  │
     │        │  · TaskType 扩展: component/module/viewmodel │                  │
     │        │  · Acceptance Criteria: static+build+runtime │                  │
     │        │  · Trace 实现: 基于协程上下文 + UI DSL slot    │                  │
     │        │  · Evolution Source: error_log 结构化化       │                 │
     │        └─────────────────────────────────────────────┘                  │
     │                                                                          │
     └──────────────────────────────────────────────────────────────────────────┘

                        ┌───────────────────────────────────┐
                        │ COMPETITIVE（对标，不是依赖）      │
                        │  Airflow / Temporal / Dagster /    │
                        │  LangGraph / SpecKit / Bazel ...   │
                        └───────────────────────────────────┘
```

---

## 3. 一次请求怎么跑（端到端叙事）

以本仓库前端迁移 adapter 下的 `prop_confirm` 业务单元迁移为例（kernel 层仅需理解事件流；具体场景词见 `adapters/<name>/`）：

```
1. 用户：/opsx propose "迁移 prop_confirm 业务单元"
        ↓
2. Orchestrator 写入 event: pipeline.stage_entered { stage: SPEC }
        ↓
3. spec 分析器产出 StructuredSpec.md
        → artifact 注册: urn:piao:artifact:spec:prop_confirm@v1
        → event: taskdag.planned (初稿)
        ↓
4. 进入 PLAN，产出 TaskDAG.md
        → artifact: urn:piao:artifact:taskdag:prop_confirm@v1
        → snapshot 冻结: 本次 PLAN 快照
        ↓
5. IMPLEMENT: code 生成器逐任务执行
        → 每个任务写入 task.started / task.finished 事件
        → 中途生成器写错代码 → verify 阶段失败
        → drift engine 定位: 错误源在 T-07
        → evolution 触发: 命中 error_log#001 (某个已沉淀的 API 迁移错误模式)
          → 直接把修复方案注入 code 生成器上下文（lazy-load L2）
        → code 生成器修复 → 重跑 T-07
        ↓
6. VERIFY: 执行 static_check / build_artifact / runtime_signal 三类验收
        → 所有事件写入 events.jsonl
        ↓
7. OBSERVE: guardian 读 runtime 日志源
        ↓
8. ARCHIVE: knowledge-archiver 检查可沉淀项
        → 如发现新错误模式 → 写入 evolution 提案
        → 经 git hook 强制 review 后合入
        ↓
9. 下一次迁移业务单元时，evolution 的 L1 索引自动含这条新经验
```

关键：**每一步都是事件；每个阶段切换点都有快照；每个错误都是演化输入。**

---

## 4. 设计底线（不可违背的六条）

1. **事件不可变**：写入后只能追加勘误事件，不能改历史
2. **身份全局唯一**：所有 artifact / task / event 都是 URN，禁止裸字符串关联
3. **变更必有原因**：`.codebuddy/` 下资产变更强制经 evolution 事件记录原因
4. **kernel 不知道场景**：kernel 层不得出现具体的 adapter 名、宿主语言、目标平台、构建/分析工具名等场景词（完整禁用词表见 `kernel/scenario-wordlist.md`，由 `scripts/kernel-wordcheck.sh` 自动检查）
5. **Lazy > Greedy**：记忆系统默认不加载正文，只加载极简索引
6. **Artifact-centric, not task-centric**：系统围绕"产出了什么、它的身份/版本/血缘是什么"组织，而不是围绕"有哪些 task 在跑"。task 只是"artifact 的生产事件"。

> **对第 6 条的说明**（M2 对标研究后追加，2026-04-18）：
> 这条是整个架构的哲学根基，不是实现细节。它来自对 Dagster / Argo 的对标：task-centric 的 pipeline 在 Agent 场景下会退化为"看了一堆 task 执行日志却不知道产出在哪、版本漂没漂"；artifact-centric 让系统有一个**持久化的、可被 drift / evolution 子系统读写的一等公民**。所有 task / event / rule 都围绕 artifact 旋转。`02-artifact-model.md §4` 和 `03-layered-architecture.md` 已把这条哲学翻译成具体契约。

---

## 5. 不做什么（明确的 NO）

| 不做 | 为什么 |
|------|------|
| 不做 DSL / IR | 提升复杂度，现阶段 Markdown + JSONL 足够 |
| 不做 UI 编辑器 | Dashboard 够用，别做第二个 IDE |
| 不做 LLM Router | 不在 kernel 关心点 |
| 不做分布式部署 | 单机/单仓，JSONL + 本地快照 |
| 不做 MCP-style 全量加载 | Lazy-load 是核心哲学 |

---

## 6. 版本目标

| 版本 | 目标 | 验证场景 | 状态 |
|------|------|------|------|
| **v0.1** | kernel 七大模型（见 §1）全部定稿 + 通用契约矩阵（CONV-01/CONV-01.1 + 三例外）完备 | kernel 宪章自洽 + 四代 kickoff 接力链闭合 | ✅ **已封版**（见 `kernel/_review/v0_1-final-decisions.md @v1` · 2026-04-19） |
| **v0.2** | 首个 adapter 接入（`prop_confirm` 端到端跑通）+ 03 升版 published + drift 传播 + evolution 的 lazy-load 完整化 | 5+ 业务单元迁移，3+ 条错误自动命中 | 🚧 待启动（触发需首个 adapter 需求） |
| **v0.3** | 新增第二个 adapter（如服务端或另一类 source framework）压测 kernel | 至少一个 kernel 接口因多 adapter 需求被调整 | 📌 规划中 |

---

## 7. 阅读顺序建议

```
此文档（00-overview）
 ├─ 想快速判断能否用 → 看 §3 端到端叙事 + §6 版本目标
 ├─ 想做贡献/扩展   → 看 kernel/07-extensibility.md 再回到各 kernel 文档
 └─ 想做对标研究    → 去 competitive/ 目录
```

---

**最后一行永远是同一句话**：
> 这个系统的价值不在每个模块多先进，而在它们**共用一套契约**。契约破了，系统就是普通脚手架。
