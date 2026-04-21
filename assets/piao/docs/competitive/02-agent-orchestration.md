---
urn: urn:piao:kernel:spec:competitive/agent_orchestration@v1
kind: spec
rev: v1
status: draft
category: competitive-research
---

# Agent 编排框架对标：opencode / jj / Aider / Plan-and-Solve

> 这一类产品的本质共性：**把 LLM agent 当成一个可编程的状态机来驱动**，而不是当成"聊天窗口"。
> 它们的核心价值不在 prompt，而在**状态管理 + 工具契约 + 可审计轨迹**。

---

## 1. 代表产品

| 项目 | 类别 | 核心模式 |
|------|------|---------|
| **opencode** (SST) | TUI agent 工具 | Session-based + provider-agnostic + 可持久化会话 |
| **jj** (Jujutsu) | VCS 的 agent 友好重设计 | 不可变 operation log + 可回溯的分支图 |
| **Aider** | Command-line coding agent | Git 集成 + Repo-map + edit-and-commit 闭环 |
| **Plan-and-Solve / ReAct** | 学术界 prompt 模式 | 显式两阶段：plan → act，每阶段独立 LLM call |
| **CAMEL / AutoGen / CrewAI** | Multi-agent 框架 | 角色分工 + message passing + 终止条件 |
| **OpenAI Swarm / Smolagents** | 轻量单文件 agent | 函数式 hand-off，极简状态 |

## 2. 它们解决了什么问题

**问题**：LLM 天生是无状态的单轮文本生成器，但软件工程需要**多轮、可验证、可回滚**的执行。

**共同解法**：
- 把"任务"显式建模为状态机（不是聊天历史）
- 把"工具调用"显式建模为带 schema 的契约（不是自由文本）
- 把"执行轨迹"显式建模为可持久化的 event log（不是内存里的 messages 数组）

→ 这**完全对应** piao-pipeline 的 trace_event 模型。只是我们把 agent 执行本身也当成 artifact 来管理。

## 3. 架构模式提取

### 3.1 opencode 的模式：**Session = 持久化 event stream + resumable**

opencode 的每个 session 在磁盘上是**一个目录**，包含：
- `session.json`：元数据（id / title / cwd / provider）
- `events.jsonl`：append-only 事件流（user_message / tool_call / tool_result / ai_message）
- `snapshots/`：每次 tool_call 前后的文件快照
- `permissions.json`：用户对该 session 授权的工具子集

**关键洞察**：它把"整个 agent 交互"视为一条可重放的流。这和 piao-pipeline 的 trace_event 同构，只是 opencode 的粒度是"聊天消息"，我们是"pipeline 阶段事件"。

→ **直接借鉴**：piao-pipeline 的 agent 执行事件应该复用 opencode 的事件结构（tool_call / tool_result / ai_message），而不是自己发明一套。具体细节到 M3 (event 模型) 再定。

→ **不采纳**：opencode 的 "permissions per session" 机制——piao-pipeline 的权限应该是 **per artifact kind** 的（比如 agent 可以读 spec，但不能改 acceptance），而不是 per session。

### 3.2 jj 的模式：**Operation Log = 元级不可变历史**

jj 对 git 做的最深刻的重设计：**所有仓库操作（包括撤销、变基、合并）本身也是被记录的事件**。`jj op log` 能看到你做过的每一次操作，`jj op restore` 能回到任意操作之前的状态。

这意味着 jj 有**两层历史**：
- L1：代码历史（commit graph，等价于 git）
- L2：操作历史（你怎么构造出这个 commit graph 的，是 git 没有的）

**对 piao-pipeline 的震撼性启发**：
→ 我们的 trace_event 其实也应该是**两层**的：
  - L1：artifact 本身的变更历史（谁在何时产出了 v2）
  - L2：**产出 v2 的过程本身**（跑了哪几个 task / 哪几次 agent 调用 / 哪几次重试）
→ 当前 M1 的设计里 L1 和 L2 混在一起了（provenance 只记录"producer_event"，没展开为一串）。
→ **M3 必须分清**这两层，并在 event 模型里把它们关联但不合并。

### 3.3 Aider 的模式：**Repo-map 是第一等公民**

Aider 在启动时会扫描整个仓库，用 tree-sitter 提取符号表，构造一个"仓库地图"喂给 LLM。每次 agent 决策时，`repo-map` 作为上下文前缀注入。

**关键洞察**：LLM 不是在"看代码"，而是在"看地图 + 一小片代码"。地图的质量直接决定 agent 的决策质量。

→ **对 piao-pipeline 的启发**：
  - 我们当前已有 `ARCHITECTURE_SNAPSHOT.md`，这是我们的 "repo-map"
  - 但它是**手动/半自动生成**的，且没进入 artifact 体系
  - **改进**：把 ARCHITECTURE_SNAPSHOT.md 升格为 `kind: snapshot` 的 kernel artifact，每次 pipeline 推进时强制重算，并在 trace_event 里引用它作为 agent 的输入上下文
  - 这对应 M5 (quality_gate + snapshot) 的一个设计要点

### 3.4 Plan-and-Solve 的模式：**先整体规划再逐步执行**

学术界 2023 年后的一个共识：让 LLM 先生成一个"plan"（结构化 steps），然后每个 step 独立执行并 self-verify。vs "one-shot chain-of-thought" 有显著提升。

→ **对 piao-pipeline 的启发**：
  - 这完全对应我们的 `spec → taskdag → task execution` 两阶段
  - 我们已经在做对的事，只是还没把它说透
  - **改进**：在 `03-layered-architecture.md` 明确 "plan/act 分离" 作为架构原则，禁止在 execute 阶段修改 taskdag（改 plan 必须回到 plan 阶段，产生新 rev）

### 3.5 Multi-agent 框架（AutoGen / CrewAI / Swarm）

这些框架让多个 LLM agent 分工（planner / coder / reviewer / ...）并通过 message passing 协作。

→ **对 piao-pipeline 的启发**：
  - 我们项目的 `.codebuddy/agents/` 已经天然是 multi-agent 设计
  - 但**不能照搬 AutoGen 的 message passing 模式**——它本质是内存态通信，无法审计
  - **我们的 multi-agent 通信应该走 trace_event**，即 agent A 的输出落到 artifact，agent B 从 artifact 读取，所有"协作"都有 URN 痕迹
  - 这比 AutoGen 的 message passing 更重但更工业级

## 4. 对 piao-pipeline 的启发（正反两面）

### 4.1 正向启发 ✅

1. **opencode 的 session 目录结构**可以直接借鉴给我们的 `pipeline-output/runs/<run_id>/`
2. **jj 的操作历史 L2** 提示我们 trace_event 要分两层（artifact 层 + execution 层）
3. **Aider 的 repo-map**提示我们 snapshot 要升格为 first-class artifact
4. **Plan-and-Solve** 验证了我们 spec→taskdag→execute 的两阶段分离是正确的
5. **multi-agent 通过 artifact 通信**（而不是 in-memory message）是 piao-pipeline 的差异化

### 4.2 反向启发 ⚠️

1. **opencode / Aider 没有"需求"概念**：它们以任务为最小单位，每个任务是一次性的。piao-pipeline 要管理"需求→多个任务→归档"的完整链路，比它们重一个量级。
2. **Multi-agent 框架过度乐观**：学术 demo 里的 "planner + coder + reviewer" 三角协作，在真实场景经常变成"三个 agent 互相甩锅"。piao-pipeline 不要追求 agent 间的复杂协作，而应该追求**"单一 agent + 清晰 artifact 契约"**，把协作责任交给 artifact 的 lineage 图。
3. **jj 的 operation log 非常重，落地代价高**：我们要借鉴理念而不是实现方式。piao-pipeline 可以用 JSONL 事件流达到 80% 的 jj 能力，不需要自研 VCS。

## 5. 风险 / 反例

**反例 1：agent 框架追求"自主性"**。
LangChain / AutoGen 早期的宣传都是 "let the agent decide"。实践下来，自主性越强越难调试。
**对策**：piao-pipeline 的 agent 应该是**高度受限**的——kernel 契约决定了 agent 可以做什么、不能做什么。自由度只在 adapter 里放开。

**反例 2：event log 爆炸**。
jj 的 operation log 在一个活跃仓库里一周就 5000+ 条。piao-pipeline 的 trace_event 如果每个 task 产 10 个事件，一个页面迁移就 ~100 事件，10 个页面就 1000 事件。
**对策**：事件**按 page 分片存储**（已在 M1 约定：`pipeline-output/trace/{page}.events.jsonl`），并在 M4 定义 snapshot 机制——历史事件可被 snapshot 压缩后归档。

**反例 3：agent 工具调用的"tool hallucination"**。
LLM 经常调用不存在的工具或传错参数。opencode / Aider 靠 JSON schema 校验拦截，但 schema 本身如果错了就拦不住。
**对策**：piao-pipeline 的 agent 工具契约必须是**可验证的 artifact**（`kind: rule` 的 tool-contract），每次 agent 调用前由 kernel 校验，而不是靠 adapter 自己实现。

## 6. 不采纳清单

| 对标做法 | 不采纳原因 |
|---------|-----------|
| **AutoGen 的 in-memory message passing** | 无法审计，不符合 piao-pipeline "一切走 artifact" 原则 |
| **自研 VCS (jj 风)** | 代价过高，用 JSONL event 够了 |
| **agent 高度自主** (LangChain 早期风) | 与我们"kernel 契约约束"哲学冲突 |
| **permissions per session** (opencode 风) | 我们改用 per artifact kind |
| **每个 agent 一份 repo-map** | 应该全局单 snapshot，所有 agent 共享 |

---

**本篇结论**：agent 编排框架给 piao-pipeline 的最大贡献是**"把 agent 当状态机"**这个思维转变。
- opencode 教我们 session 目录结构
- jj 教我们两层事件历史
- Aider 教我们 snapshot 是第一等公民
- Plan-and-Solve 验证了我们的两阶段分离
- Multi-agent 框架**给了我们反面教材**——不要追求 agent 间协作，要追求 artifact 契约

→ synthesis 中会把这一篇浓缩为"**2 条正向启发 + 1 条反向警告**"。
