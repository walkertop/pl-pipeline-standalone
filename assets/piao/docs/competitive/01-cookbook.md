---
urn: urn:piao:kernel:spec:competitive/cookbook@v1
kind: spec
rev: v1
status: draft
category: competitive-research
---

# Cookbook 型工程对标：LeRobot / Kawasaki / nanoGPT

> 这一类产品的本质共性：**用一个仓库同时承载"可运行的参考实现 + 清晰的演化路径 + 可复用的模块"**。
> 它们不是"框架"，也不是"产品"，而是一种**工程形态**——介于脚手架和教程之间，带有强烈的作者意志。

---

## 1. 代表产品

| 项目 | 领域 | 规模 | 核心卖点 |
|------|------|------|---------|
| **LeRobot** (HuggingFace) | 机器人学习 | 中型库 + 数据集 + 训练 recipe | 把 RL / IL policy 做成"训练-采样-评估"三件套 cookbook |
| **Kawasaki Robotics SDK cookbook** | 工业机器人 | 大型企业代码 + 大量示例 | 每种机型/工位给一个"可跑通的最小路径" |
| **nanoGPT** (Karpathy) | LLM 训练 | 单仓 ~500 行核心 | 极简实现 + 明确的扩展点 + 公开训练日志 |
| **llm.c** (Karpathy) | LLM 推理/训练 | 单仓 C 实现 | 同上，更极致 |
| **llama-recipes** (Meta) | LLM fine-tune | 多 recipe 仓 | 每个 recipe 一个独立目录，可独立跑 |

## 2. 它们解决了什么问题

共同痛点是：**框架文档永远说不清楚"我到底怎么用它做成 X"**。

Cookbook 型工程回答的是**端到端路径**：
- 从一个可运行的 baseline 起步
- 提供明确的"改什么可以得到什么"
- 把经验（hyperparam、数据清洗、异常处理）**嵌入代码注释而非独立文档**
- 作者承诺：**你 clone 下来就能跑**

这和 piao-pipeline 想做的事情有 80% 的同构——我们也想让"一个迁移需求从接到手到归档"是一条**可跑通的路径**，而不是"先读 20 篇文档"。

## 3. 架构模式提取

### 3.1 LeRobot 的模式：**Dataset × Policy × Env 三元分层**

LeRobot 把所有"机器人学习"问题拆成三个正交维度：
- **Dataset**：统一格式的 episode 数据（含 observation + action + reward）
- **Policy**：输入 obs 输出 action 的模型
- **Env**：模拟器/真机适配层

任何新实验 = 挑一个 dataset + 挑一个 policy + 挑一个 env，三者独立演进。

→ **对 piao-pipeline 的启发**：我们当前把 spec / task / artifact / trace / evolution 分了 5 层是对的，但可以再思考有没有**正交组合**的机会。比如 `(task_type) × (acceptance_criteria) × (trace_impl)` 是否应该像 LeRobot 的三元组一样可以**任意组合**？
→ 这条放进 synthesis 的启发清单。

### 3.2 nanoGPT 的模式：**Single-file baseline + 显式扩展点**

nanoGPT 的 `model.py` 是完整自包含的 ~300 行。它成功的关键不是"代码短"，而是：
- 读者能在**一坐姿**内读完整条执行路径
- 扩展点是**显式标注的**（"如果你想换 activation，改这里"）
- 所有优化（flash attention / compile / ddp）都作为**可选分支**存在，默认关闭

→ **对 piao-pipeline 的启发**：kernel 文档要追求"一坐姿读完"。我 M1 的四篇每篇都 200-400 行，已经到临界点。后续 10 篇每篇都要自问："读者能否在一坐姿里把这一篇读完并上手？"
→ **写作原则**：如果某个扩展点太复杂，先不写进 kernel，放 adapter 或后续 v0.2。

### 3.3 Kawasaki cookbook 的模式：**Recipe = 路径 × 机型 × 工位**

Kawasaki 的工业 SDK 有个鲜明做法：**不写通用文档，写 recipe**。
- 每个 recipe 对应一个**具体业务场景**（"焊接 + 6 轴机型 + 流水线 A"）
- Recipe 内部引用的是**通用的底层 API**，但 recipe 本身是场景化的
- 一个 recipe 就是一个可完整执行的工程模板

→ **对 piao-pipeline 的启发**：这和我们"kernel + adapter"边界是**同一个模式**！
→ Kawasaki 的通用 API 对应我们的 kernel，recipe 对应我们的 adapter。
→ **但我们比 Kawasaki 多一步**：我们还要求 kernel 本身自我演化（通过 evolution_source → promote_to_kernel），这是 cookbook 型工程**没做到的**事。这是 piao-pipeline 的差异化。

## 4. 对 piao-pipeline 的启发（正反两面）

### 4.1 正向启发 ✅

1. **"可跑通"优先于"概念完备"**：M1 的 kernel 文档应该尽快配上一个**可跑通的最小 adapter 示例**（比如把现有一个已迁移完的页面，用 piao 的视角重标注一遍），让读者立刻看到"装上就能跑"。
2. **经验嵌入代码而非独立文档**：artifact 的 `.artifact.yaml` 里可以有一个 `notes:` 字段，承载"为什么这个模块拆成三个 sub"之类的经验，而不是写在外部文档。这解决了"经验和代码分家"的老问题。
3. **Single-file baseline 心态**：每个扩展点的最简实现应该能塞进一个文件。

### 4.2 反向启发 ⚠️

1. **cookbook 型工程没有"演化"概念**：它们假设作者是唯一的演化者，社区只贡献新 recipe。piao-pipeline 要做的"跨项目共享 + 双向演化"它们都没碰。**不能照搬它们的"单一作者意志"模型**。
2. **cookbook 型工程靠"人的品味"维持一致性**：Karpathy 能做 nanoGPT 是因为 Karpathy。piao-pipeline 不能假设永远有一个品味稳定的架构师。**我们需要用"契约"代替"品味"**——这就是 M1 第七篇 `07-extensibility.md` 做的事。
3. **cookbook 不处理回归**：nanoGPT 的旧 commit 挂了就挂了。piao-pipeline 必须处理"历史 artifact 的 drift 检查"，这是工业级 vs 教学级的分水岭。

## 5. 风险 / 反例

**反例 1：过度 cookbook 化会导致"每个场景自成一体"**。
如果每个 adapter 都像 Kawasaki recipe 一样高度独立，kernel 的价值会被虚化——最后退化为 "几个 adapter 各玩各的"。
**对策**：kernel 必须通过 Artifact / Trace / Evolution 三个契约把 adapter 强制"绑在一起"。这是我 M1 第七篇已经写进去的宪法。

**反例 2：Recipe 数量爆炸**。
Kawasaki 内部 recipe 库据说有数百个，互相之间有大量 80% 相似但 20% 不同的复制。
**对策**：piao-pipeline 的 `evolution_source → promote_to_kernel` 机制就是为了让"高频出现的 recipe 模式"能被提炼进 kernel，避免 recipe 增生。

**反例 3：Karpathy 写 nanoGPT 那种"单文件之美"在企业项目里会被 PR review 破坏**。
团队中总会有人提 "加个 config 吧"、"这里抽个类吧"，最终单文件变成 20 个文件。
**对策**：在 adapter 层允许这种扩张，但 kernel 层**必须**保持"一坐姿可读"。这需要写一条硬规则（kernel 文档 / 代码单文件不超过 500 行，超过即拆分或降级）。

## 6. 不采纳清单（明确我们**不跟**什么）

| 对标做法 | 不采纳原因 |
|---------|-----------|
| **Monorepo 所有 recipe 同级目录** (Kawasaki 风) | 与我们的 kernel/adapter 分层冲突，recipe 只属于 adapter |
| **所有优化都作为可选分支存在** (nanoGPT 风) | 适合教学仓，不适合生产。piao-pipeline 的 quality_gate 不是可选项 |
| **"作者意志"维持一致性** (cookbook 通病) | 我们改用"契约 + CI 检查" |
| **经验全部嵌入代码注释** | 部分嵌入可以（`.artifact.yaml` 的 `notes:`），但**反例级经验**必须走 `error-log.md` / evolution_source 链路，沉淀为 kernel 级规则 |

---

**本篇结论**：cookbook 型工程给我们的最大礼物是**"可跑通 > 概念完备"**的工程哲学。但它们的"单一作者意志 + 无演化 + 无回归"三个短板，正是 piao-pipeline 必须补齐的。

→ 在 synthesis（`00-synthesis.md`）中会把这一篇的启发**浓缩为 1 条矩阵**。
