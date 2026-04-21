---
urn: urn:piao:kernel:spec:competitive/synthesis@v1
kind: spec
rev: v1
status: draft
category: competitive-research
---

# 对标研究合成：矩阵 + 回到 piao-pipeline 的 5 条启示

> 这是 M2 的收束篇。把前 5 篇压成一张**对标矩阵**，再从 piao-pipeline 的视角抽出 **5 条硬性启示**和 **3 条硬性警告**。
> 读完本篇就能合上 M2，不用再翻前面五篇的细节。

---

## 1. 对标矩阵

### 1.1 按"维度 × 对标类别"交叉表

| 维度 \ 对标 | Cookbook<br>(LeRobot/nanoGPT) | Agent<br>(opencode/jj/Aider) | Pipeline<br>(Argo/Temporal/Dagster) | Flywheel<br>(Cursor/Skills/RAG) | Evolution<br>(OpenSpec/ADR/KEP) |
|-----|------|------|------|------|------|
| **身份/命名** | 无正式 ID | session-id 强 | URN/URI 强 | rule id 弱 | change-id 中 |
| **artifact 概念** | 弱（代码就是产物） | session 目录 | artifact-first (Argo/Dagster) ★ | skill/rule 是 artifact | proposal 是 artifact |
| **事件/Trace** | 无 | 事件流 first (opencode) ★ | workflow run 事件 | 无（除 Letta） | 状态变迁事件 |
| **演化** | 作者意志 | 无 | 无 | Mem0/Letta 自动抽取 | 完整状态机 (KEP) ★ |
| **可复用性** | 高（recipe） | 低 | marketplace (Actions) | skill 分层 ★ | RFC 签入 |
| **agent 友好** | 中 | 高 ★ | 中 | 高 | 中 |
| **规模化** | 差（不处理回归） | 中 | 强 ★ | 中 | 强 |
| **学习曲线** | 低 ★ | 中 | 高 | 中 | 中 |

★ = 该类别中对 piao-pipeline 最值得学的项

### 1.2 按"piao-pipeline 章节 × 主要贡献来源"

| piao-pipeline 章节 | 主要贡献来源 | 次要贡献来源 |
|---|---|---|
| `01-identity-model.md` (URN) | Argo 的 artifact path / Docker image ref | KEP 的分层 ID |
| `02-artifact-model.md` | Dagster asset + Argo input/output artifact | OpenSpec 目录结构 |
| `03-layered-architecture.md` (M3) | Plan-and-Solve 两阶段 | Airflow scheduler/executor 分离 |
| `04-event-model.md` (M3) | opencode events.jsonl + jj operation log | Temporal event history |
| `05-quality-gate.md` (M5) | Temporal replayable/side-effect 区分 | ADR status 字段 |
| `06-evolution-layer.md` (M6) | OpenSpec 骨架 + ADR 字段 + KEP 状态机 + Mem0 多源抽取 | OpenRewrite（未来 v0.2） |
| `07-extensibility.md` | Kawasaki recipe vs 通用 API | Dagster asset/job 分离 |
| `rule/skill 契约` (M7) | Cursor glob 触发 + Claude progressive disclosure | Continue 的反面教材 |

## 2. piao-pipeline 的 5 条硬性启示

### 启示 1：**piao-pipeline 是 artifact-centric，不是 task-centric**
- 站队 **Dagster + Argo**，明确反对 Airflow 的 task-first 视角
- 所有 kernel 文档、所有脚本、所有 agent 都要在心智上执行这个反转
- **具体动作**：`03-layered-architecture.md`（M3）的第一段就声明此立场
- **测试**：任何 design 会议上，"我们在设计一个 task" 这种说法应被纠正为 "我们在设计一个 artifact，task 是产出它的路径"

### 启示 2：**事件历史必须分两层：artifact 层 + execution 层**
- 来自 jj operation log 的洞察
- 当前 M1 的 provenance 只有一个 producer_event，不够
- **具体动作**：M3 的 event 模型必须有两类事件：
  - **L1 事件**：artifact 的 rev 升降（coarse-grained，上线/归档可见）
  - **L2 事件**：产出 artifact 的过程（fine-grained，agent 调用、task 执行、重试）
- 两层必须有明确的关联字段（`l1_event_id` 在 L2 事件里引用）

### 启示 3：**Rule 必须有显式触发条件**
- 来自 Cursor glob + Continue 反面教材
- 当前 `.codebuddy/rules/*.md` 靠 description 给 agent 自己选，不够稳
- **具体动作**：M7 (rule 契约) 定义 rule 的 `applies_to:` 字段
  - 语法：`urn_pattern: urn:piao:adapter.kuikly:artifact:*/component/*`
  - 或：`glob: ["**/*.kt", "shared/**/page/**"]`
  - 或：`event_pattern: task_completed:card_migrated:*`
- kernel 在对应事件/文件出现时自动注入该 rule

### 启示 4：**evolution_source 种类必须扩展，但必须有证据链**
- 来自 Mem0 / Letta + ADR + 对"全自动抽取幻觉"的警惕
- 当前项目只有 error_log 一种来源
- **具体动作**：M6 的 evolution_source kind 至少包含：
  - `error_log`：已有
  - `insight`：从 trace 事件里通过脚本/人工发现的模式（必须 `evidence: [trace_event_urn...]`）
  - `outage`：生产事故复盘（必须 `evidence: [outage_report_urn]`）
  - `review_note`：代码审查中的反复提醒（必须 `evidence: [review_event_urn...]`）
- 每种都走同一个 `proposed → accepted → promoted` 状态机

### 启示 5：**复用的门槛必须是"一行引用"**
- 来自 GitHub Actions `uses:` + Claude Skills 对 `SKILL.md` 的 top-level 引用
- 当前 skill 调用还是"AI 自己 load"，不形式化
- **具体动作**：task 定义里支持：
  ```yaml
  - task_id: T-07
    uses: urn:piao:adapter.kuikly:skill:kuikly_debugger@v1
    inputs: {...}
  ```
- kernel 校验：该 URN 存在 + 满足 skill 契约 + inputs 匹配 skill 的声明
- 这让"跨项目共享 skill"在长期成为可能（M8+）

## 3. piao-pipeline 的 3 条硬性警告

### 警告 1：**不要追求"agent 自主性"**
- 来自 LangChain / AutoGen / Cursor 各自的教训
- agent 给的自由度越大，失败模式越多，debug 越难
- **piao-pipeline 反过来走**：agent 在 kernel 契约的**强约束**下工作，自由度只在 adapter 放开
- **拒绝**：让 agent 自己决定"我该调用哪个 skill / 我该读哪个 rule"——必须靠触发条件自动注入

### 警告 2：**不要在 v0.1 引入任何"智能检索"**
- 来自 RAG 的十年教训
- 向量检索、embedding 召回、语义搜索都**暂时不做**
- 全部依赖**结构化触发**（URN / glob / event pattern）
- 什么时候做？等 artifact 数量 >1000 且触发规则明显不够用时（大约 v0.3 以后）

### 警告 3：**不要过度工业化**
- 来自 Temporal / Airflow / Jenkins 的反面
- piao-pipeline v0.1 是**文档契约 + bash 脚本 + event JSONL**
- 明确**不做**：
  - scheduler 服务（orchestrator.sh 够）
  - 确定性重放沙箱
  - YAML-as-code DSL
  - plugin marketplace
  - 向量数据库
- 底线：**所有 kernel 组件一个 Makefile / 几个 shell 脚本能跑起来**

## 4. 对标成败一览：前人的坑，我们不踩

| 失败案例 | 表现 | piao-pipeline 的预防 |
|---|---|---|
| Cursor rules 膨胀 | 几十个 rule，一半过期 | rule lifecycle + drift 检查提示"从未被引用" |
| OpenSpec archive 被遗忘 | changes/ 堆积 | orchestrator 自动生成 pending_archive 事件 |
| AutoGen agent 甩锅 | 多 agent 协作变扯皮 | 用 artifact 契约替代 message passing |
| RAG top-k 噪声污染 | 检索不精准 | 只用结构化触发，禁用向量检索 v0.1 |
| KEP 僵尸提案 | provisional 永不推进 | last_activity_at 超时自动 withdraw |
| Karpathy nanoGPT 在企业走样 | 单文件之美被破坏 | kernel 层强制 500 行上限 |
| Airflow scheduler 单点 | 挂了全停 | 无中心 scheduler，state 在文件 |
| Mem0 记错的 fact | 错误结论污染后续 | evolution 必须有证据链 URN |

## 5. 对 M3+ 的输入清单

M2 结束，给后续每一篇留下**具体设计输入**：

| 后续文档 | 来自 M2 的硬性设计要求 |
|---|---|
| `M3-03-layered-architecture.md` | ① artifact-centric 站队 ② plan/act 两阶段分离 ③ L1/L2 事件分层 |
| `M3-04-event-model.md` | ① 借鉴 opencode session 结构 ② L1/L2 事件 schema ③ event_id 7 个域前缀 |
| `M4-05-trace-impl.md` (kuikly) | ① JSONL append-only ② 按 page 分片 ③ MigrationLogger 接入 |
| `M5-quality-gate.md` | ① replayable/side-effect 区分 ② acceptance 采用 ADR 5 字段 |
| `M6-evolution-layer.md` | ① OpenSpec 骨架 ② 3 状态机 ③ 多源 evolution_source + 证据链 ④ OpenRewrite 作为 v0.2 future work 记录 |
| `M7-rule-skill-contract.md` | ① Rule 的 applies_to 字段 ② progressive disclosure 统一 ③ uses: URN 一行引用 |
| `M8-manifest-drift.md` | ① append-only manifest ② drift 检查"从未引用" + "rev 非单调" |

## 6. 一句话定位

如果 M1 回答的是 **"piao-pipeline 是什么"**，那么 M2 回答的是 **"piao-pipeline 和世界其他工具是什么关系"**。

一句话总结关系：

> **piao-pipeline = 工业 pipeline 的 artifact-centric 骨架 (Argo/Dagster) + agent 编排的事件流 (opencode/jj) + 知识飞轮的结构化触发 (Cursor/Skills) + 演化治理的状态机 (OpenSpec/KEP)，在 kernel 契约下被约束组合起来。**

**明确不是**：
- 不是聊天 agent（不追求自主性）
- 不是 RAG 系统（不追求智能检索）
- 不是 workflow 平台（不自建 scheduler）
- 不是代码自动演化工具（v0.1 不做 AST 重写）

---

**本篇结论**：M2 到此收束。M3 开始进入 kernel 的剩余章节（layered architecture + event model），所有设计都要回到本篇的 5 条启示和 3 条警告做对齐。

**下一步**：M3 开写前我会再停一下，让你确认 M2 的 5 条启示你是否全部买单——因为它们直接决定 M3 的设计基调。
