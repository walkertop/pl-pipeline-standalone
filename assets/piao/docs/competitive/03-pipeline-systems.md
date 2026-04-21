---
urn: urn:piao:kernel:spec:competitive/pipeline_systems@v1
kind: spec
rev: v1
status: draft
category: competitive-research
---

# 工业 Pipeline 系统对标：Argo / Temporal / Airflow / GitHub Actions

> 这一类产品是"**任务编排 + 可观测性 + 失败恢复**"三位一体的工业基础设施。
> 它们有十年以上的工程沉淀，piao-pipeline 的编排层**应该大量站在它们肩膀上**，而不是自己重造。

---

## 1. 代表产品

| 项目 | 类别 | 核心模式 |
|------|------|---------|
| **Apache Airflow** | Workflow as DAG | Python DAG + Scheduler + Executor 分离 |
| **Argo Workflows** | K8s native workflow | YAML DAG + container-based step + artifact 传递 |
| **Temporal** | Durable execution | Workflow = 可重放的函数 + Activity = 副作用 |
| **GitHub Actions** | CI/CD workflow | YAML + event trigger + marketplace 复用 |
| **Dagster** | Data pipeline | Asset-based (不是 task-based!) + 类型系统 |
| **Prefect** | Python-first | Flow as code + observability first |
| **Jenkins pipeline** | Classic CI | Groovy DSL + 插件生态 |

## 2. 它们解决了什么问题

**核心问题**：如何让**多步骤、长时间、可能失败**的任务链条**可靠执行 + 可观测 + 可恢复**。

**关键难题**：
- 步骤之间的依赖关系（DAG）
- 步骤失败后的重试/跳过/人工介入
- 步骤执行的**中间状态持久化**（进程崩溃后能恢复）
- 执行轨迹的**可视化**（方便人排查）
- 步骤产物的**artifact 传递**

→ piao-pipeline 已经有一个 `pipeline-orchestrator.sh`，但它基本停留在 "bash + 状态文件" 阶段。本篇的目标是**判断我们到底要走多远**。

## 3. 架构模式提取

### 3.1 Airflow / Argo 的模式：**声明式 DAG + Executor 分离**

两者都有一个相同的分层：
- **DAG definition**：纯声明式（Airflow 用 Python，Argo 用 YAML）
- **Scheduler**：解析 DAG，决定哪个步骤现在可以跑
- **Executor**：实际执行步骤（本地进程 / K8s pod / remote worker）

**关键洞察**：**把"任务是什么"和"任务怎么跑"彻底解耦**。这样：
- 一个 DAG 可以在 dev 用 LocalExecutor，在 prod 用 K8sExecutor
- 换底层不需要改 DAG

→ **对 piao-pipeline 的启发**：
  - 我们的 `taskdag.md` 当前混合了"任务是什么"（声明）和"谁执行"（agent 名字）
  - **应该解耦**：taskdag 只声明 task 的 `kind` 和 `acceptance_criteria`，具体由哪个 agent/脚本执行应该在 adapter 层配置
  - 这是 M1 第七篇扩展点设计的自然延伸

### 3.2 Argo 的模式：**Artifact 在 step 间传递是第一等公民**

Argo 的 YAML 里每个 step 显式声明 `inputs.artifacts` 和 `outputs.artifacts`，artifact 通过 S3/MinIO 传递。

**关键洞察**：Argo 把"step 之间传什么"提升到和"step 做什么"同等的位置。这让**整个 DAG 的数据流是 typed and traceable**的。

→ **对 piao-pipeline 的启发**：
  - **完美对应**我们 M1 的 `02-artifact-model.md` + lineage 设计
  - 每个 task 的 `produces:` 和 `consumes:` 字段（见 `openspec/templates/page-state.md` 的 task 块）应该升级为**强制声明 URN 列表**
  - 这样 taskdag 本身就是一个 artifact lineage 图的**上层投影**

### 3.3 Temporal 的模式：**Durable Execution = 代码即状态机**

Temporal 最独到的设计：**workflow 函数是确定性的 + 可重放的**。所有副作用（API 调用 / 数据库写 / IO）必须通过 Activity，Activity 的结果被持久化。

当 worker 进程崩溃重启，workflow 可以**从 event history 重新执行到当前状态**——因为确定性部分不会产生不同结果，副作用部分有历史记录可用。

**关键洞察**：**把"能重试的"和"不能重试的"在代码层面强制区分**。

→ **对 piao-pipeline 的启发**：
  - 我们的 task 也有这个区分：**可重跑的 task**（静态检查、lint）vs **有副作用的 task**（构建、git commit、发布）
  - **改进**：task_type 应该带一个 `replayable: bool` 元信息（或 `side_effect_kind: enum`），kernel 契约强制它
  - 这对 M5 的 quality_gate 设计很重要——重试策略要基于它

### 3.4 GitHub Actions 的模式：**Marketplace + uses 语法**

GitHub Actions 成功的关键不是技术，是**生态**——marketplace 上的可复用 action。`uses: actions/checkout@v4` 一行就复用了别人的工作流片段。

**关键洞察**：**可复用性的门槛必须低到"一行引用"**，否则生态起不来。

→ **对 piao-pipeline 的启发**：
  - 我们目前的 `.codebuddy/skills/` 已经有类似设计（每个 skill 一个目录 + SKILL.md）
  - 但调用方式还是 "AI 自己 load"，没有形式化的 `uses:` 语法
  - **改进**：taskdag 的 task 定义里应该支持 `skill: <urn>` 字段，kernel 强制该 URN 存在且满足 skill 契约
  - 长期看，这是 piao-pipeline 能发展出"跨项目复用"的基础

### 3.5 Dagster 的模式：**Asset-based (不是 task-based!)**

Dagster 的最大创新：**DAG 的节点不是"任务"，而是"产物"**。你声明"这个 parquet 文件由这个 sql 产生"，Dagster 自动推导执行顺序。

**关键洞察**：任务是手段，产物才是目的。**以产物为中心编排**比"以任务为中心"更符合数据工程的本质。

→ **对 piao-pipeline 的啓發**：
  - 这和我们的 artifact-centric 设计**高度一致**
  - 我们的 taskdag 本质上是 "生产某 artifact 的计划"，不是 "执行某任务的计划"
  - **进一步强化**：在 `03-layered-architecture.md` 明确写清楚 "piao-pipeline 是 artifact-centric，不是 task-centric"
  - 这是我们对 Airflow 一派的超越（Airflow 是 task-centric，Dagster 和我们是 asset/artifact-centric）

## 4. 对 piao-pipeline 的启发（正反两面）

### 4.1 正向启发 ✅

1. **Artifact 传递是第一等公民**（Argo / Dagster）—— 已在 M1 落地
2. **task 声明与执行分离**（Airflow）—— 要在 M3/M4 强化
3. **可重放 vs 有副作用的任务要在契约层区分**（Temporal）—— M5 要写
4. **复用门槛必须低到一行引用**（GitHub Actions）—— M6 或 adapter 层面做
5. **asset-based vs task-based**（Dagster）—— piao-pipeline 站 Dagster 这一队

### 4.2 反向启发 ⚠️

1. **不要学 Airflow 的重量级 scheduler**：我们没有"定时触发 / 跨日历调度"的需求，用轻量 orchestrator.sh 就够
2. **不要学 Temporal 的确定性重放**：代价巨大（需要 sandbox + 禁用不确定 API），而我们的 pipeline 本身已经是人工触发 + 可人工介入，不需要这么硬核
3. **不要学 GitHub Actions 的 YAML 即代码**：YAML 表达复杂逻辑非常痛苦，我们应该把 taskdag 保持在 markdown + 少量 yaml front-matter 的程度
4. **不要学 Jenkins 的插件生态**：插件生态带来版本地狱和安全风险，我们的 skill 应该是 in-repo 的（至少 v0.1）

## 5. 风险 / 反例

**反例 1：YAML 死亡陷阱**。
Argo / GitHub Actions 的 YAML 在复杂场景下会变成"配置即编程语言"，缺少类型和 IDE 支持，维护地狱。
**对策**：piao-pipeline 的 taskdag 保持**markdown + 结构化 section**，不追求纯 YAML 表达。复杂逻辑写 shell/python 脚本并作为 artifact 引用。

**反例 2：scheduler 单点故障**。
Airflow 的 scheduler 一旦挂，所有 DAG 都停。
**对策**：piao-pipeline 的 orchestrator 是**无状态的** shell 脚本，状态全在 `.state.md` + event log。重启即从 state 恢复，无 scheduler 依赖。

**反例 3：过度工业化**。
把 Temporal 的全套搬进一个几万行代码的项目，维护成本 > 收益。
**对策**：v0.1 只吸收**理念**（确定性 / artifact / 重放），不引入任何重型运行时。编排继续用 bash + jq + 文件。

**反例 4：Asset-centric 走过头**。
Dagster 推到极致会变成"一切都是 asset"，导致 task 层消失，中间过程不可见。
**对策**：piao-pipeline 保留 task 作为**执行单位**，但 DAG 的依赖**通过 artifact 推导**。两层都要有。

## 6. 不采纳清单

| 对标做法 | 不采纳原因 |
|---------|-----------|
| **中心化 scheduler 服务** (Airflow) | 过重，shell orchestrator 够 |
| **纯 YAML DSL** (Argo / GitHub Actions) | 复杂场景维护差 |
| **确定性重放 sandbox** (Temporal) | 代价 >> 收益 |
| **Marketplace 模式** (GitHub Actions) | v0.1 先做 in-repo skill 复用 |
| **Python DAG 定义** (Airflow / Prefect) | 引入 Python 运行时依赖，保持 shell + md |

---

**本篇结论**：工业 pipeline 系统给 piao-pipeline 的最大贡献是**"artifact-centric"**（Dagster）+ **"声明执行分离"**（Argo）。
它们的其余部分（scheduler / YAML / marketplace / sandbox）我们都**只学理念不抄实现**。

→ synthesis 中会把这一篇浓缩为"**1 条核心站队（asset-centric）+ 1 条节制原则（不过度工业化）**"。
