---
urn: urn:piao:proposal:kernel:m6_evolution_kickoff@v1
kind: proposal
rev: v1
status: superseded
superseded_by: urn:piao:snapshot:kernel:m6_final_decisions@v1
superseded_at: 2026-04-19T21:34:00+08:00
produced_by: m5-milestone-closeout-2026-04-19
published_at: 2026-04-19T15:50:00+08:00
upstream:
  - urn:piao:snapshot:kernel:m5_final_decisions@v1
  - urn:piao:spec:architecture:drift_propagation@v1.1
  - urn:piao:spec:architecture:version_snapshot@v1.2
  - urn:piao:spec:architecture:artifact_model@v1.3
  - urn:piao:spec:architecture:layered_architecture@v1
  - urn:piao:evolution_source:kernel:m1_debt_ledger@v6
supersedes: urn:piao:proposal:kernel:m5_drift_kickoff@v1
wordcheck_exempt: true
---

> **⚠️ 本 proposal 已 superseded（2026-04-19 21:34）**
>
> **承接快照**：`urn:piao:snapshot:kernel:m6_final_decisions@v1`（见 `_review/m6-final-decisions.md`）
>
> **关闭原因**：本 proposal 的两条工作流关闭条件全达成——
> 1. ✅ 工作流 T'（阶段 α · M5 工具链扩展）· `piao-drift-compute.sh --full-mode/--event-journal-dir/--emit-events` 扩展 + N=2 原子写入已落地（见本文档附录 A 阶段 α 退出点）
> 2. ✅ 工作流 E（阶段 β · M6 Evolution 规格起稿）· `06-evolution-model.md @v1.1 draft`（由 `m6_evolution_kernel_alignment@v1` S4 commit `44bf034b` 驱动）· §8.2 门控 #1/#4 已达成 · #2/#3 待 MVP 反证
> 3. ✅ `_review/m6-evolution-draft-review.md @v1 published`（34 条锚点全量校验 · Q21–Q26 六条缺口登记 · β-2 判定）
> 4. ✅ `_review/m6-evolution-kernel-alignment-proposal.md @v1 published + implemented`（§6 DoD 10/10 · S0–S6 七步全落地）
> 5. ✅ `_review/m6-final-decisions.md @v1 published`（M6 milestone 终态快照 · 六项决议矩阵 · 决议 4-A 纯观测 + 5-A 终止于 scan_result · §8 self-review 六项签收通过）
>
> **保留本正文不修改**作为历史追溯锚点；如需查询 M6 milestone 最终形态，请直接引用 `m6_final_decisions@v1`。本 proposal 的承接点是"milestone 收官快照"（而非下一 kickoff proposal）· 与 `m5_drift_kickoff @v1 superseded_by: m5_final_decisions@v1` / `post-m1-kickoff @v1 superseded_by: m4_final_decisions@v1` 范式同构（三代 kickoff 生命周期闭合范式 3/3）。

# M6 Evolution Kickoff · M5 milestone 收官后的 evolution 层起稿工作编排

> 本文档是 **M5 milestone 收官后的工作编排 proposal**（2026-04-19 15:50），承接 `m5_drift_kickoff@v1 (superseded)` 的角色——由 M5 milestone 推进到 M6 milestone 起稿阶段。
>
> **定位**：`kind: proposal`（不是 snapshot · 因为计划可能被 evolution 早期工具链证据调整 · 沿用 `post-m1-kickoff` / `m5_drift_kickoff` 双前例范式）。
>
> **消费方式**：进入任一工作项前，把对应段落转为 `task.*` L1 事件并关联回本 proposal 的 URN。
>
> **阅读路径**：先读 `m5-final-decisions.md`（已决议的约束 · 决议 1–6 + §4 M6 入口检查清单 + §1 决议 5 drift→evolution 接口锁定点）→ 再读 `05-drift-propagation.md @v1.1 published`（M5 封版本体 · §6 双通道 + C1–C4 前置契约）→ 再读 `M1-debt-ledger.md @v6`（已知遗留）→ 最后读本文档（下一步去哪）。

---

## 0. 当前位置总览

按 `00-overview.md §1 核心公式` 的 7 维进度（M5 收官时刻 · 2026-04-19 15:40）：

| 维度 | 状态 | 下一步触发条件 |
|------|------|---------------|
| Identity（M1） | ✅ @v1.2 published | 稳定；新 kind 走 `01 §2.4 append-only` |
| Artifact（M2） | ✅ @v1.3 published（带 6 条 BAN 遗留 + Q4 WARN） | 阶段 3 `02@v2` 清理 §1.1 六条 BAN + §1.2 Q4 |
| Layering × Event（M3） | 🔄 @v1 draft（§3.3.1 R22 已泛化为 N 条同 txn） | M1 review 周期内持续原地修订；draft→published 待 M6 draft 稳定后合并推进 |
| Snapshot（M4） | ✅ @v1.2 published（R21 + R24 落地） | 无未决项；`piao-snapshot-produce.sh` + `piao-snapshot-diff.sh` 已落地 |
| **Drift（M5）** | ✅ **@v1.1 published**（2026-04-19 15:40 收官） | 无未决项；本 proposal 为其下游延伸 |
| **Evolution（M6）** | 🚧 **本 proposal 的核心推进目标** | 见 §2 执行顺序 |
| Extensibility（M7） | ✅ @v1.1 published | 稳定 |

**结论**：kernel 侧的**下一个 milestone 是 M6 Evolution 模型**，但**必须先解决工具链底座的 M5 扩展缺口**——`piao-drift-compute.sh` 当前仅落地 MVP（`attribution_mode=sha_only` 占位 + 不原子写 L1 事件），而 M6 evolution 扫描器需要**真实 `drift.detected` 事件流**作为 O(1) 决策输入（`m5_final_decisions §1` 决议 5 + `05 §6.1` 事件流通道 A）。这是 M6 起稿的硬门控。

---

## 1. 工作流总览

本 proposal 管理两条工作流：

- **工作流 T' · M5 工具链扩展**（详见 §3）—— 阶段 α 执行主体（当前冻结前置）
- **工作流 E · M6 Evolution 模型起稿**（详见 §4）—— 阶段 β 执行主体，依赖工作流 T' 输出

执行顺序锁定为"**T' 先行、E 跟进**"，详见 §2。这与 `m5_drift_kickoff @v1` 的"**T 先行、D 跟进**"范式同构，进一步延续 `post-m1-kickoff @v1` 的"**B 先行、A 跟进**"根范式（真实证据驱动规格起草）——三代 kickoff proposal 完成"同构范式横向验证 3/3"。

---

## 2. 执行顺序：方案 T' 优先（两阶段门控）

> 本节是 `status: published` 锁定的**唯一路径**。曾评估过的 E 优先 / 并行 两个选项及其淘汰理由见本节末。

### 2.1 核心判断

**背景事实**：

1. M5 milestone 已完成 kernel 侧 drift schema 封板（`05 @v1.1 published` · R1–R5 五硬约束 + 决议 1–6 终态）· 但**工具链侧**的 `piao-drift-compute.sh` **仅落地 MVP**（`m5_final_decisions §4` 明确列出两个 `[ ]` 未勾选项 · 即 `--full-mode` 与 `--emit-events`）。
2. M6 evolution 层的核心决策依赖**真实 `drift.detected` L1 事件流**——`05 §6.1` 明确 evolution 引擎的"O(1) 调度扫描"依赖**通道 A 事件流**，若无事件原子写入（`--emit-events` 未落地），evolution 只能走"拉 artifact 全量扫"退化路径（O(N·K)），与 `m5_final_decisions §1` 决议 5 R5 硬约束设计意图相悖。
3. M6 归因层依赖 drift artifact 的 `attribution_mode=full`（`05 §5.1` + `m5_final_decisions §1` 决议 4）——若 `--full-mode` 未落地，evolution 无法区分"真·无归因"与"占位·未实施"，会出现"纸面归因链"级反模式（同 M5 评估"D 优先脱离 diff 运行证据"被淘汰的原因同构）。
4. M6 evolution 规格起稿将同时受 C1–C4 前置契约约束（`05 §6.3`）· 但 C1–C4 是**行为契约**（不得反向写 · 不得自补归因 · 必须走 provenance · append-only），其落地**必须有真实 event-journal 存在**作为验证基底。

**依赖方向判断**：工具链 T' 是规格 E 的**事实生成器**，规格 E 是工具链 T' 的**正确性约束**。两者互为上下游，但**触发顺序锁定为 T'→E**：

- T' 可先以 `05 @v1.1 published` + `m5_final_decisions@v1` 决议 4/5 为唯一规格依据落地扩展（无需等待 E）
- E 若脱离 T' 扩展证据起草，`06 §X evolution 扫描算法` / `06 §X drift→evolution 事件流消费契约` 都会沦为"推理层语义"——与 M5 评估"D 优先脱离 diff 运行证据"的反模式同构

### 2.2 阶段 α（立即）· 工作流 T' 最小扩展闭环

**目标**：在 `piao-drift-compute.sh` MVP 基础上，落地 M6 前置所需的**两条扩展 flag**，把 `05 §6.1/§6.2` 双通道 + `§5` 归因双模式走一遍真实的可执行路径。

**产出**：

1. `scripts/piao-drift-compute.sh --full-mode` 扩展
   - **触发条件**：`--event-journal-dir <path>` 参数指定目录存在且可读
   - 逻辑：读 drift 的两张输入 snapshot · 按 `05 §5.3` 归因算法 O(N·K) 链条反查 event-journal 中 `producer_event_id` 对应的事件 · 写入 drift artifact body `attribution[]` 列表
   - **契约承诺**：与 MVP 的 `sha_only` 模式输出 schema 一致 · 仅 `attribution_mode.value` + `attribution[]` 两处差异（`05 §5.1` + 决议 4 硬约束）
   - **降级保持透明**：任一 `producer_event_id` 反查失败立即整体降级 `sha_only` + `reason="event-journal missing event_id=<id>"`（`05 §5.2` 禁止隐式降级 + 部分归因）

2. `scripts/piao-drift-compute.sh --emit-events` 扩展
   - **触发条件**：`--emit-events` flag 显式声明
   - 逻辑：在写 drift artifact yaml 文件之后、退出之前，**原子写入两条 L1 事件**——
     - `artifact.published(D)` · event_id 前缀 `snap-published-*`（对齐 R19 + 决议 5）
     - `drift.detected` · event_id 前缀 `drift-detected-*`（对齐 R19 + 决议 5 · 11 必填字段全量填充 · 见 `05 §6.2`）
   - **契约承诺**：两条事件同 txn 写入（对齐 `03 §3.3.1 N=2 实例` + `m5_final_decisions §1` 决议 2 T5 · N=2 是泛化后 N≥1 的合法子集）· 事件写入失败则 drift artifact 同步回滚（不留"写了 artifact 但没发事件"的半成品）

**门控（全部满足方可退出阶段 α）**：

- [ ] `--full-mode` 在真实 event-journal 目录下运行产出的 drift artifact 的 `attribution_mode.value=full` + `attribution[]` 列表非空 + 归因链逐条可追溯到 L1 事件 event_id（**归因双模式反证**）
- [ ] `--full-mode` 在缺事件的退化场景下自动降级 `sha_only` + `reason="event-journal missing event_id=<id>"`（**降级透明暴露反证** · 对齐 R4）
- [ ] `--emit-events` 端到端写入两条 L1 事件到 event-journal · event_id 前缀正确分离（`snap-published-*` / `drift-detected-*`）· 11 必填字段全部写入（`05 §6.2`）· **原子性反证**：人为在事件写入前注入错误，drift artifact 不得留存
- [ ] `drift.detected` 事件的 `evidence.{old_snapshot_urn, new_snapshot_urn}` 字段字面精确匹配（**双轨原则反证** · `03 §3.1` + `05 §6.2`）
- [ ] 产出 `_review/m5-toolchain-extension-review.md`（对标 `m4-toolchain-review.md @v1` 三段式），记录三件事：
  1. 扩展实施中发现的 `05 §5/§6` 契约**操作歧义**（若有）
  2. 扩展实施中发现的 `03 §3.3.1 N=2 同 txn 契约`**边界用例缺失**（若有）
  3. 对 M6 evolution 层 §X 扫描算法 / §X drift 消化契约的**工具链视角建议**（规格起草的输入 · 对标 `m4-toolchain-review §3 TB1–TB5`）
- [ ] 手动跑 `./scripts/kernel-wordcheck.sh` 确认 scripts/ 目录不纳入词表（命名不引入新违规）

### 2.3 阶段 β（阶段 α 完成后）· 消化工具链证据 → 决定 M6 draft 起稿

根据 `_review/m5-toolchain-extension-review.md` 中「工具链视角发现」条目数分支：

**分支 β-1：发现 ≥ 3 条 kernel 契约歧义 / 边界缺失**

- 先把所有歧义登记进 `M1-debt-ledger.md §1.5`（新开 v7 升版 · 对标 §1.2/§1.3/§1.4 范式）
- **不立刻起 M6 draft**，优先做 `05 @v1.1 → @v1.2` 或 `03 draft → @v1.1 draft` 的补充性小升（类似 M5 路径 A 的原地消化）
- 补升完成后再进入分支 β-2

**分支 β-2：发现 ≤ 2 条且均为小歧义**

- 说明 M5 契约健壮度够
- **开启工作流 E**：起草 `06-evolution-model.md` 的正式 draft（当前**无骨架**，从 @v0.1 骨架 → @v1 draft）
- 起草路径对标 M4 / M5：先 draft → 再 draft-review（配对 `_review/m6-evolution-draft-review.md`）→ 再 milestone 收官（`_review/m6-final-decisions.md`）

### 2.4 被淘汰的方案（决策溯源）

| 方案 | 淘汰理由 |
|------|---------|
| **E 优先（先 M6 draft）** | M6 §X 扫描算法 / §X 消化契约脱离实际 `drift.detected` 事件流运行证据，会沦为"纸面语义"——与 M5 评估"D 优先"被淘汰的原因同构。更严重的是：`--full-mode` 未落地时 `attribution_mode=full` 的下游消费路径根本没有真实证据可验证，evolution 的"O(1) 快速决策 + O(N) 拉详情"两段路径会同时沦为推演 |
| **并行（同日启动 T' + E）** | 两条工作流共享 `05` 契约且需要双向反馈（T' 发现歧义 → E 修 05 引用；E 起草疑问 → T' 提供证据），并行会产生 05 锚点争用；单人工作流并行 = 频繁上下文切换，质量下降（本条理由三代 kickoff proposal 完全同构，不再展开） |

### 2.5 与 `m5_drift_kickoff @v1` / `post-m1-kickoff @v1` 的同构关系

| 维度 | post-m1-kickoff @v1 | m5_drift_kickoff @v1 | m6_evolution_kickoff @v1（本 proposal） |
|------|---------------------|----------------------|-----------------------------------------|
| 触发时刻 | M1 milestone 收官（2026-04-18 22:10） | M4 milestone 收官（2026-04-19 02:10） | **M5 milestone 收官（2026-04-19 15:40）** |
| 先行工作流 | 工作流 B（adapter 落地 · 证据驱动） | 工作流 T（M4 工具链落地 · 证据驱动） | **工作流 T'（M5 工具链扩展 · 证据驱动）** |
| 跟进工作流 | 工作流 A（M4 Snapshot 规格） | 工作流 D（M5 Drift 规格） | **工作流 E（M6 Evolution 规格）** |
| 执行顺序理由 | "规格脱离真实证据会推翻重来" | 同上 | **同上** |
| 阶段 α 产出物 | 首个 adapter charter + review | `piao-snapshot-produce.sh` + `piao-snapshot-diff.sh` + `m4-toolchain-review` | **`piao-drift-compute.sh --full-mode` + `--emit-events` + `m5-toolchain-extension-review`** |
| 阶段 β 主产出 | `04-version-snapshot.md @v1 draft` | `05-drift-propagation.md @v1 draft` | **`06-evolution-model.md @v1 draft`** |
| 承接快照 | `m4_final_decisions@v1` | `m5_final_decisions@v1` | **`m6_final_decisions@v1`**（待产出） |
| 接力 proposal | `m5_drift_kickoff@v1` | `m6_evolution_kickoff@v1`（本 proposal） | **`m7_extensibility_closeout_kickoff@v1`**（待产出 · 若 M7 需要 · 否则直接 v0.1 milestone 收官） |

**策略连贯性**：本 proposal 延续 `post-m1-kickoff` → `m5_drift_kickoff` 的"真实证据驱动规格起草"范式，避免走回"脱离实施证据起草规格"的反模式。**这是 kernel 层该范式的第三代实例**，反证该范式跨三个独立 milestone 稳定适用。

---

## 3. 工作流 T'（阶段 α 执行主体）· M5 工具链扩展

### 3.1 命名空间延续

沿用 `m5_drift_kickoff @v1 §3.1` 确立的 `piao-` 前缀规约：

- `scripts/piao-drift-compute.sh`（M5 MVP · 本 proposal 扩展对象）
- `scripts/piao-drift-compute.sh --full-mode`（本 proposal 阶段 α 扩展 · 不新增脚本文件）
- `scripts/piao-drift-compute.sh --emit-events`（本 proposal 阶段 α 扩展 · 不新增脚本文件）
- 未来 `scripts/piao-evolution-scan.sh`（M6 draft 产出时登记 · 本 proposal 不包含）

### 3.2 产出物

1. `scripts/piao-drift-compute.sh` 扩展（阶段 α 核心产出）· 同一文件内加 flag 分支
   - `--full-mode` + `--event-journal-dir <path>` 组合
   - `--emit-events` 单独 flag
   - 现有 MVP 行为在未指定 flag 时保持向后兼容（默认 `sha_only` + 不发事件）
2. `docs/piao-pipeline/kernel/_review/m5-toolchain-extension-review.md`（阶段 α 退出门）

**不做**（阶段 α 非目标）：
- evolution 扫描算法本体（M6 规格 · 工作流 E 范畴）
- `piao-evolution-scan.sh` 脚本起草（M6 阶段 α 后置 · 本 proposal 未来下游）
- event-journal 本身的存储结构（`03 §3` 范畴 · 已 published · 不改动）
- drift artifact GC（M7 之后）

### 3.3 依赖已定契约

- `05 §5 归因双模式`（full / sha_only · 降级透明暴露 · R4 硬约束）
- `05 §5.3 归因算法 O(N·K) 三步链条`
- `05 §6.1 双通道设计`（事件流 O(1) + artifact 拉取 O(N)）
- `05 §6.2 drift.detected 事件 11 必填字段`（含 R19 双 event_id 前缀 · 决议 5）
- `03 §3.3.1 N 条 L1 事件同 txn 原子写入`（R22 · drift.detected + artifact.published 双事件是 N=2 合法子集）
- `04 §3.2.3 canonical YAML 通用工具契约`（若扩展触及 sha 计算一致性 · R21）
- `02 §5.3.1 lineage 特化注册表 · kind=drift 条目`（R23 · drift artifact 的 provenance 查询路径）

### 3.4 review 文档的强制格式（m5-toolchain-extension-review.md）

对标 `m4-toolchain-review @v1` 三段式（由 `m5_drift_kickoff §3.4` 确立 · 由 `post-m1-kickoff §3.3` 首次提出）：

```markdown
## 1. 引用的 kernel 锚点
- `kernel/05-drift-propagation.md §X.Y` — 用于 [目的]
- `kernel/03-layered-architecture.md §X.Y` — 用于 [目的]
- ...

## 2. 扩展实施中发现的 kernel 契约歧义/缺失
- [T1] [具体描述] — [触发场景]
- ...

## 3. 对 M6 evolution 规格起草的工具链视角建议
- [TB1] [建议条目] — [Q6.X 对应]
- ...
```

这一强约束与 `m4-toolchain-review.md` / `m5-drift-draft-review.md` 对等，建立 **M6 起稿前的最后一道证据门**。

---

## 4. 工作流 E（阶段 β 分支 β-2 触发）· M6 Evolution 规格起稿

**产出物**：`docs/piao-pipeline/kernel/06-evolution-model.md`（@v0.1 骨架 → @v1 首版 draft）

> **注意**：与 M5 不同，M6 kernel 主文档 `06-evolution-model.md` **当前尚无骨架**（M5 起稿前 `05 @v0.1` 骨架由 M1 review 遗留；M6 无对应遗留）· 故阶段 β 首步需先写 `@v0.1` 骨架再升 `@v1` 首版 draft · 两步合并视为同一里程碑动作。

**依赖已定契约**：
- 本 proposal 工作流 T' 的产出（`piao-drift-compute.sh --full-mode` + `--emit-events` + `m5-toolchain-extension-review.md`）
- `05 §6 drift → evolution 接口`（双通道 + C1–C4 前置契约 · 决议 5 硬约束）
- `05 §2.3 drift artifact schema` + `§3.5 drift_kind 三枚举`（evolution 消化对象的静态结构）
- `05 §5 归因双模式`（evolution 归因链的上游数据形态）
- `04 §5 snapshot_diff 算子`（evolution 与 drift 的底层差分能力）
- `02 §4 provenance 四元组` + `02 §5.3.1 lineage 特化注册表 · kind=drift`（evolution 查询 drift depends_on 的入口）
- `03 §3.1 L1 十类事件封板` + `03 §3.3.1 N 条同 txn`（evolution 产出 `evolution.scanned` 事件 + 可能伴生 `task.started` 等事件的原子性依据）
- `01 §2.1 kind 枚举`（`evolution` 是否为新 kind · 或复用 `artifact` · 见 Q6.1）

**必须回答的五个问题**（M6 验收必要条件，对标 `m5_drift_kickoff §4` 的 Q5.1–Q5.5 五问）：

1. **evolution 的身份（Q6.1）**：evolution 是 artifact 吗？`artifact_type` 候选 `evolution.scan_result`？还是 L1 事件（仅 `evolution.scanned`）？还是两者并存（参考 drift 双形态）？
2. **evolution 的触发（Q6.2）**：evolution 扫描何时运行？`drift.detected` 后自动？阶段切换批量？周期性？手动？——类比 M5 决议 2 的"唯一触发器"设计思路，但 evolution 的输入是**事件流 + 条件**而非"一个点事件"
3. **evolution 的 scope（Q6.3）**：evolution 扫描的范围如何选？单条 drift 逐条消化？同 scope_kind/scope_ref 批聚合？跨 scope 联合？——M5 决议 3 对 drift 拒绝跨 scope；M6 是否继承该约束？
4. **evolution 的决策产物（Q6.4）**：evolution 扫描应该输出什么结构？候选包括：
   - 纯观测产物（`evolution.scanned` 事件仅记录"看了哪些 drift"）
   - 决策产物（输出 `task.proposed` / `proposal.generated` 等下游事件）
   - 混合（观测 + 可选决策）
5. **evolution → next 接口（Q6.5）**：evolution 的输出喂给谁？是否产生新的 kernel 层（M8+）？还是完全收敛到 M3 taskdag？evolution 是否终止于"产出 task 建议"即不再向下？

**非目标**（M6 不做）：
- evolution 的**优先级算法**细节实现（M6 只承诺 schema 与接口 · 实际排序由工具链侧）
- evolution 的 UI 可视化（工具链侧 · 非 kernel）
- evolution 与外部系统对接（如 IDE hook / CI 通知 · adapter 层范畴）
- drift 消化的**批处理策略**本体（`05 §6.4` 已明确留给 M6 但不必在 M6 首版 draft 一次定完 · 可留 Q6.x 续论）

**启动前置**：阶段 α 的分支判定结果为 **β-2**（工具链发现 ≤ 2 条小歧义）。若为 **β-1**，本工作流继续冻结直至 `05 @v1.1 → @v1.2` 或 `03 draft → @v1.1 draft` 补升完成。

---

## 5. 里程碑地图（参考节奏）

```
2026-04-19 15:40 ┤ M5 milestone 收官（05 @v1.1 published + m5_final_decisions@v1）
                 │   ├── m5_drift_kickoff @v1 → superseded（by m5_final_decisions@v1）
                 │   ├── M1-debt-ledger @v5 → @v6（Q15-Q20 + R17-R25 consumed）
                 │   └── 06-evolution-model.md 尚未起稿（@v0.1 骨架待阶段 β 产出）
                 │
2026-04-19 15:50 ┤ 本 proposal @v1 published（当前位置）
                 │
2026-04-2x       ┤ 阶段 α 完成：piao-drift-compute.sh --full-mode + --emit-events
                 │                + m5-toolchain-extension-review.md
                 │   └── 四项端到端验证通过（full 归因 + 降级 + 原子事件 + evidence 双轨）
                 │
2026-04-2x       ┤ 阶段 β 分支判定
                 │   ├── 若 β-1：`05 @v1.1 → @v1.2` 补升 + M1-debt-ledger @v6 → @v7
                 │   └── 若 β-2：启动工作流 E（先写 06 @v0.1 骨架 → @v1 draft）
                 │
2026-05-xx       ┤ M6 draft → draft-review → milestone 收官
                 │   └── m6_final_decisions@v1 + m6-evolution-draft-review.md
                 │
2026-05-xx       ┤ M7 Extensibility milestone 收尾决策点
                 │   ├── 若 M7 @v1.1 已充分覆盖：直接进入 v0.1 里程碑收官
                 │   └── 若 M7 需要补升：起草 m7_closeout_kickoff@v1 proposal
                 │
2026-xx-xx       ┤ v0.1 里程碑（kernel 七大模型全部 published）
```

**注意**：上述日期为**参考节奏**，不是硬性承诺。实际调度以 `task.*` 事件的 `planned_at` 字段为准。

---

## 6. 本 proposal 的演进

- **当前 status**：`published`（2026-04-19 15:50 · `produced_by: m5-milestone-closeout-2026-04-19`）
- **锁定范围**：§2 执行顺序（方案 T' 优先两阶段）是 published 的硬约束；§3–§5 为执行细则，细节调整不构成 rev 升降
- **触发 rev v2 的条件**：
  - §2 执行顺序被事实证据否决（如阶段 α 发现 `05 §5/§6` 契约根本无法被脚本实现 · 或 `03 §3.3.1 N=2` 实装不可行）
  - 工作流 T' / E 的**目标**被重新定义（不仅是产出物清单变动）
- **消费事件**：每启动一个工作项发一条 `task.started`，关联 `parent_proposal: urn:piao:proposal:kernel:m6_evolution_kickoff@v1`
- **关闭条件**：工作流 T' 产出双扩展 + `m5-toolchain-extension-review.md` published + 工作流 E 首版 draft 落地 + M6 milestone 收官 → `status: published → superseded`（由 `m6_final_decisions@v1` 承接 · 与 `post-m1-kickoff → m4_final_decisions` / `m5_drift_kickoff → m5_final_decisions` 对称范式）

---

## 7. 与 `m5_drift_kickoff @v1` 的接力关系

本 proposal **显式 supersedes** `m5_drift_kickoff @v1`：

- front-matter `supersedes: urn:piao:proposal:kernel:m5_drift_kickoff@v1`
- 角色接力：
  - `post-m1-kickoff @v1` 处理 "M1→M4 过渡"
  - `m5_drift_kickoff @v1` 处理 "M4→M5 过渡"
  - 本 proposal 处理 "**M5→M6 过渡**"
- 不改动 `m5_drift_kickoff @v1` 的 `superseded_by` 指向（仍为 `m5_final_decisions@v1`，因其承接点是 milestone 收官快照而非下一 kickoff；这与本 proposal 的 supersedes 语义是**不同的双向锚点**——承接快照 vs 承接 proposal）
- **双向可追溯**：`m5_drift_kickoff @v1` §10.2 末尾已预声明"下一 kickoff proposal · `m6_evolution_kickoff@v1`（待产出）"；本 proposal published 后该预声明完成实证（不需要再追改 m5_drift_kickoff · 其 superseded 状态已封存）

---

## 8. 对 `M1-debt-ledger` 的影响

- **§1.1 六条 BAN**：仍延期至阶段 3 `02@v2` 清理，不受本 proposal 影响
- **§1.2 Q4**：同上（与 §1.1 合并）
- **§1.3 Q8-Q14**：已全部 consumed（@v5），本 proposal 不重复处置
- **§1.4 Q15-Q20 + R17-R25**：已全部 consumed（@v6），本 proposal 不重复处置
- **§1.5 待新建**：若阶段 α 发现 `05 §5/§6` 契约歧义 · 或 `03 §3.3.1 N=2` 实装缺失，将在本 proposal 工作流 T' 退出时触发 `@v6 → @v7` 升版，§1.5 登记新条目（登记 + consume 同轮，对标 @v4→@v5 + @v5→@v6 范式）

---

## 9. 本 proposal 的配套动作清单

本 proposal published 时同步完成的动作：

- [x] front-matter `supersedes: m5_drift_kickoff@v1` 已声明
- [x] `m5_drift_kickoff @v1` 已处于 superseded 状态（由 `m5_final_decisions@v1` 承接 · 本 proposal 的 supersedes 是 kickoff 角色传递而非 superseded_by 指向变更）
- [ ] **不做**：`m5_final_decisions @v1 §4 下一步清单` 勾选最后两项（`m6_evolution_kickoff@v1` 产出 ✅ + `piao-drift-compute.sh --full-mode/--emit-events` 扩展 🚧）——final-decisions 是快照即事实（`01 §14`），产出后不修改。改为在本 proposal §7 以追述方式闭合即可
- [ ] **不做**：起草 `06-evolution-model.md @v0.1` 骨架——阶段 β 才执行（本 proposal published 时尚未进入阶段 β · 骨架与首版 draft 合并视为一步）

---

**本 proposal 状态**：published（2026-04-19 15:50 · `produced_by: m5-milestone-closeout-2026-04-19`）
**上游锚点**：
- `urn:piao:snapshot:kernel:m5_final_decisions@v1`（M5 收官快照 + 本 proposal 触发源 · 决议 1–6 矩阵 + §4 M6 入口检查清单）
- `urn:piao:spec:architecture:drift_propagation@v1.1 published`（M5 封版本体 · §6 双通道 + C1–C4 前置契约 + R1–R5 五硬约束）
- `urn:piao:spec:architecture:version_snapshot@v1.2 published`（M4 封版本体 · R21/R24 落地 · §3.2.3 canonical YAML 通用工具）
- `urn:piao:spec:architecture:artifact_model@v1.3 published`（M2 封版本体 · R23/R25 落地 · §5.3.1 lineage 特化注册表 kind=drift）
- `urn:piao:spec:architecture:layered_architecture@v1 draft`（M3 事件分层规格 · §3.3.1 R22 已泛化 N 条同 txn · drift/evolution 事件 L1 类型依赖）
- `urn:piao:evolution_source:kernel:m1_debt_ledger@v6`（债务账本当前状态 · §1.4 Q15-Q20 + R17-R25 全 consumed）
**supersedes**：`urn:piao:proposal:kernel:m5_drift_kickoff@v1`（接力 M4→M5 过渡 proposal 的 kickoff 角色）
**下游候选**：
- `scripts/piao-drift-compute.sh --full-mode` 扩展（阶段 α 产出）
- `scripts/piao-drift-compute.sh --emit-events` 扩展（阶段 α 产出）
- `_review/m5-toolchain-extension-review.md`（阶段 α 退出门）
- `06-evolution-model.md @v0.1 骨架 + @v1 draft`（阶段 β 主产出 · 分支 β-2 触发）
- `M1-debt-ledger @v7`（若阶段 α 触发 · 分支 β-1）
- `_review/m6-evolution-draft-review.md`（M6 draft review 周期产出）
- `_review/m6-final-decisions.md`（M6 milestone 收官快照，本 proposal 关闭承接点）

---

## 附录 A · 阶段 α 退出点（append-only · 不升 rev）

**追补时刻**：2026-04-19 17:45 · `produced_by: m5-toolchain-extension-review-published`

**退出门复核**（按 §2.2）：

| 门控项 | 状态 | 证据链接 |
|-------|------|---------|
| `--full-mode` + `--event-journal-dir` 扩展 | ✅ | `scripts/piao-drift-compute.sh` 876 行 · 向后兼容 |
| `--emit-events` 扩展 + N=2 原子性 | ✅ | 同上 · `rollback_txn` 覆盖正常执行路径 |
| G1 full 归因链反证 | ✅ | `_review/m5-toolchain-extension-review.md §0.1 G1` |
| G2 降级透明暴露反证 | ✅ | 同上 · §0.1 G2 |
| G3 端到端两条事件原子写入 | ✅ | 同上 · §0.1 G3 + `bash -x` 日志 |
| G4 evidence 双轨字面匹配 | ✅ | 同上 · §0.1 G4 |
| G5 原子回滚反证 | ✅ | 同上 · §0.1 G5（bash -x 完整链路 · exit 4） |
| G6 wordcheck 零新增 | ✅ | 同上 · §0.1 G6（6 BAN + 5 WARN 与基线一致） |
| `_review/m5-toolchain-extension-review.md` produced | ✅ | `@v1 published` |

**分支判定结论**：**β-2**（05 契约本次扩展**零新增歧义** · 4 条发现（T'1–T'4）全部归属 03 工具链或补注级别 · 不触发 β-1）

**下一步进入阶段 β**：按 §2.3 分支 β-2 的执行序 · 启动工作流 E 起稿 `06-evolution-model.md @v0.1 骨架 → @v1 draft`

**追补形式说明**：本附录为 `status: published` 文档的 append-only 追述段落 · 不修改正文任何字节 · 不升 rev（对齐 `01 §14` 快照即事实原则 + `post-m1-kickoff @v1` / `m5_drift_kickoff @v1` 附录范式）。
**关闭候选**：`urn:piao:snapshot:kernel:m6_final_decisions@v1` · ✅ **已兑现**（2026-04-19 21:34 · 本 proposal `status: published → superseded` · `superseded_by` 绑定该快照 URN）
