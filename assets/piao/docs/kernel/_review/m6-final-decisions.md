---
urn: urn:piao:snapshot:kernel:m6_final_decisions@v1
kind: snapshot
artifact_type: snapshot
rev: v1
status: published
published_at: 2026-04-19T21:34:00+08:00
produced_by:
  actor: m6-review-2026-04-19
  task_urn: urn:piao:task:m6:evolution_milestone_closeout
  trigger_event_type: stage.exited
  event_id: milestone-closeout-m6-final-decisions-v1
supersedes: null
upstream:
  - urn:piao:snapshot:kernel:m5_final_decisions@v1
  - urn:piao:spec:architecture:evolution_model@v1.1
  - urn:piao:spec:architecture:drift_propagation@v1.1
  - urn:piao:spec:architecture:version_snapshot@v1.2
  - urn:piao:spec:architecture:artifact_model@v1.4
  - urn:piao:spec:architecture:layered_architecture@v1
  - urn:piao:artifact:kernel:m6_evolution_draft_review@v1
  - urn:piao:artifact:kernel:m5_toolchain_extension_review@v1
  - urn:piao:proposal:kernel:m6_evolution_kernel_alignment@v1
  - urn:piao:proposal:kernel:m6_evolution_kickoff@v1
wordcheck_exempt: true
---

# M6 Final Decisions · Kernel Evolution 决策层模型收敛快照

> 本文档是 **M6 review（2026-04-19）** 的最终决议快照，对标 `M5-final-decisions.md` 范式。
> 定位：作为 `06-evolution-model.md @v1.1 draft → @v1.1 published` 的"发布证书"与后续 `piao-evolution-scan.sh` 工具链 MVP 的唯一契约基线。
> 快照即事实：本文件**一经产出不再修改**；若未来推翻某条决议，新开 `m6_final_decisions@v2` 并在 v1 中标注 `superseded_by`。

---

## 0. 快照覆盖范围

- **受管文档**：
  - `docs/piao-pipeline/kernel/06-evolution-model.md`（本次 milestone 的核心产出 · 待从 @v1.1 draft → @v1.1 published）
  - `docs/piao-pipeline/kernel/03-layered-architecture.md`（因路径 B S1 承接 B1 原地精化 · `evolution.scanned` 语义字段 refresh · draft 原地修订不升 rev）
  - `docs/piao-pipeline/kernel/02-artifact-model.md`（因路径 B S2 承接 B2 升 @v1.3 → @v1.4 · 派生注册表新增 `evolution.scan_result`）
- **受管工具链**（本 milestone 已扩展）：
  - `scripts/piao-drift-compute.sh`（阶段 α 扩展 · `--full-mode` + `--emit-events` 双 flag · 876 行 · bash + python3 · 对标 M5 MVP 的 555 行 · 58% 增量）
- **本 milestone 未实施的工具链**（延至 M6 post-published · 非本快照受管）：
  - `scripts/piao-evolution-scan.sh`（evolution 扫描器 MVP · 本快照 §4 列为升 @v1.1 published 门控反证条件）
- **决议时间窗**：2026-04-19 15:50（`m6_evolution_kickoff@v1` published 起稿）至 2026-04-19 21:05（`m6_evolution_kernel_alignment@v1` S6 收官 + `m6-evolution-draft-review@v1 published`）
- **依据**：
  - `_review/m6-evolution-kickoff.md @v1`（M5→M6 过渡 proposal · supersedes `m5_drift_kickoff@v1` · 附录 A 阶段 α 退出门 β-2 判定）
  - `_review/m5-toolchain-extension-review.md @v1`（阶段 α 工具链扩展退出门 · TB'1–TB'5 工具链视角强约束 · `piao-drift-compute.sh` 双 flag G1–G6 反证）
  - `_review/m6-evolution-draft-review.md @v1`（阶段 β 工作流 E 退出门 · §1 五问回答质量 + §2 Q21–Q26 六条缺口 + §3 路径 A/B 修订 + §4 β-2 分支锁定 + §5 路径 A/B 消化记录）
  - `_review/m6-evolution-kernel-alignment-proposal.md @v1`（路径 B proposal · B1–B2 打包处置 · S0–S6 七步执行序）

---

## 1. 六项最终决议

M6 milestone 要回答 `m6_evolution_kickoff @v1 §4` 锁定的**五个必答问题**（Q6.1–Q6.5）；下表以决议形式正式入档，补第六条为跨篇一致性维护结论。

### 决议 1 — evolution 的身份（Q6.1）：kind=artifact + artifact_type=evolution.scan_result · 双形态并存

**问题**：evolution 是 artifact 吗？若是，`artifact_type` 叫什么？还是仅为 L1 事件？或两者并存？

**决议**：**evolution 采用"artifact + L1 事件"双形态并存**（**R1 硬约束**）· 沿用 `05 §2.2` drift 范式同构四理由（体积预算 / provenance 锚点 / O(1) 扫描 / 生命周期独立）· `artifact_type` 定为 **`evolution.scan_result`** · 通过 `02 §2.2.4` 派生类型注册机制落地（M6 路径 B S2 已登记 · @v1.4 published · commit `7a7bce04`）· 自动继承 `wordcheck_policy: machine_generated` → `wordcheck_exempt: true`。

**关键契约**（**R1 硬约束**）：
- evolution artifact 的 schema 严格对齐 `02 §1.1` 五要素（URN / kind / rev / status / depends_on）
- evolution 不升 rev（`06 §7.1`）—— 单次扫描的客观产物 · 算法 rev 升级由 kernel 本篇承载 · 单条 scan_result 无独立演进需求（同构 `05 §7.1` drift 不升 rev 推理链）
- evolution 状态机仅两态：`published` / `retracted`（`06 §7.1`）—— 与 drift 同构 · 比 snapshot 还简
- L1 事件侧：`evolution.scanned` 为 evolution 扫描配套事件 · 已在 `03 §3.1` 原地精化（M6 路径 B S1 · commit `76bbfff5` · 10 类枚举总数不变 · 仅 subject/语义字段精化）

**工具链侧证据**：TB'5（`01 §2.2 evolution_source` 作输入源 kind 已定稿 · 不参与产出决议 · 双形态设计无需升 01）· M6 阶段 α 工具链扩展零 01 改动。

**正式入档位置**：`06-evolution-model.md §2` 全章 + `02-artifact-model.md §2.2.4 派生类型注册表 @v1.4 新增条目` + `03-layered-architecture.md §3.1 L1 事件表 evolution.scanned 行`。

---

### 决议 2 — evolution 的触发（Q6.2）：唯一触发器 drift.detected + 订阅链三层同构

**问题**：evolution 扫描何时运行？`drift.detected` 后自动？阶段切换批量？周期性？手动？

**决议**：**唯一触发器为 `drift.detected` L1 事件**（**R2 硬约束**）。禁止以 `artifact.published` 作触发器（通道污染 · 过滤责任下推 · 字段缺失 · O(1) 退化 · 分层崩塌——§3.5 四步反证封死）。

**订阅链三层同构**（kernel 层事件流分层契约的**第三次复用** · `06 §3.1`）：
```
snapshot.published ──▶ drift 扫描器 ──▶ drift.detected ──▶ evolution 扫描器 ──▶ evolution.scanned
     （M4 层）              （M5 层）                          （M6 层）
```

**原子流程 E1–E5**（`06 §3.2` · 同 txn 对齐 `03 §3.3.1` N 条通用契约 · N=2+k 是 M5 泛化后 N≥1 的合法子集）：
- E3：按 `06 §5.3` 决策规则计算 scan_result 四字段（`scanned_drifts[]` / `decision_log[]` / `orphan_check?` / `attribution[]`）
- E4：写入 evolution artifact yaml 文件
- E5：原子写入 **`artifact.published(E) + evolution.scanned` 两条 L1 事件**（+ k 条可选副作用事件 · N=2+k 实例）

**非触发点**（`06 §3.5`）：`artifact.published`（非 drift 类）· `snapshot.published` · `task.finished` · `stage.entered/exited` · `evolution.scanned` 自身（禁 evolution-of-evolution · 对齐 `05 §3.3` 禁 drift-of-drift）。

**降级策略**（`06 §3.4` 四场景全覆盖）：
- 读 event-journal 失败 → 本次 `drift.detected` 跳过本次扫描（不改 drift 状态 · 契约 C1）
- 拉 artifact 失败 → 本次扫描降级为纯 L1 观测（含 `decision_log[]` 缺失说明 · 走 §7.3 条件 #3）
- E5 原子写失败 → evolution artifact 同步回滚（不留半成品 · 对齐 `piao-drift-compute.sh --emit-events` G5 反证范式）
- 手动补救 → 走独立 `evolution_retract_batch` proposal（非自动化路径）

**工具链侧证据**：TB'1（`drift.detected` 事件 5 字段足以承载 O(1) 决策 · G3/G4 实测证实 · M5 toolchain-extension-review §3.1）· evolution 订阅链 O(1) 读取能力在 M5 阶段已由 `piao-drift-compute.sh --emit-events` 完整反证。

**正式入档位置**：`06-evolution-model.md §3` 全章 + `03-layered-architecture.md §3.1 evolution.scanned 行` + `§3.3.1 N 条 L1 事件同 txn 原子写入`。

---

### 决议 3 — evolution 的 scope（Q6.3）：完全继承 drift · 三层一致性链

**问题**：evolution 扫描的范围如何选？单条 drift 逐条消化？同 scope_kind/scope_ref 批聚合？跨 scope 联合？

**决议**：**evolution scope 完全继承 drift**（**R3 硬约束**）· 继承链为 `snapshot scope (L0)` → `drift scope (L1)` → `evolution scope (L2)` · 三层字面传递**无需重计算**（`06 §4.2` 三层一致性链）· 直接继承 `05 §4.1 R3` + `04 §5.3` 跨 scope_kind diff 拒绝契约。

**批聚合模式矩阵**（`06 §4.3` · 五模式中仅两种允许）：
| 模式 | 描述 | 判定 |
|------|------|------|
| A | 单条 drift 逐条消化 | ✅ 允许（默认）|
| B | 同 scope_kind + 同 scope_ref 批聚合 | ✅ 允许 |
| C | 同 scope_kind 跨 scope_ref 聚合 | ❌ 拒绝 |
| D | 跨 scope_kind 聚合 | ❌ 拒绝 |
| E | 滚动窗口 / 时间切片 | ❌ 拒绝 |

**拒绝列表五条**（`06 §4.4` · 四类诱惑 + evolution 层新增一条）：
- 跨 scope_kind 联合 —— 拒绝（继承 `05 §4.4`）
- 跨 scope_ref 联合 —— 拒绝（继承 `05 §4.4`）
- 滚动窗口 / 时间切片聚合 —— 拒绝（继承 `05 §4.4`）
- evolution 跨 snapshot 重计算 —— 拒绝（evolution 层新增 · 不得绕过 drift 直接对 snapshot 做二次差分）
- evolution 跨 rev 聚合 —— 拒绝（evolution 层新增 · 算法 rev 升级只对未来扫描生效 · 对齐 A4 决议）

**工具链侧证据**：TB'4（drift scope 完全继承两 snapshot · M5 扩展实施未引入新 scope 维度 · 建议 06 直接规定 scope 继承 · M5 toolchain-extension-review §3.4）· R3 完全兑现 TB'4 建议 · 三层一致性链是 TB'4 的结构化呈现。

**正式入档位置**：`06-evolution-model.md §4` 全章。

---

### 决议 4 — evolution 的决策产物（Q6.4）：纯观测 · scan_result 为独立中间结算单

**问题**：evolution 扫描应该输出什么结构？纯观测？决策产物？混合？

**决议**：**纯观测**（**R4 硬约束** · 方案 4-A）· evolution 扫描器**仅产出 scan_result artifact + evolution.scanned L1 事件** · **不发任何决策类下游事件**（不发 `task.proposed` / 不发 `proposal.generated` / 不发 `doc.upgrade.proposed`）。

**核心权责分层**（与决议 5 组合为"保守组合 4-A + 5-A"）：
```
drift 层（M5）：观测漂移事实
  ↓ drift.detected 事件 O(1)
evolution 层（M6）：观测 drift 的聚合（消化记录 + scope 聚合统计）
  ↓ evolution.scanned 事件 O(1) + scan_result artifact O(N) 双通道
下游层（M7+ adapter / taskdag / 人）：基于 scan_result 自取决策
```

**拒绝方案反证**（`06 §5.1`）：
- **方案 4-B 决策产物**（输出 `task.proposed` 等事件）—— 拒绝 · 理由：evolution 层越俎代庖 · 打破与 drift 的对称分层 · M7 extensibility 的决策地盘被挤占 · kernel 模型数被迫新增决策规则库
- **方案 4-C 混合**（输出 suggestion 字段但不推送）—— 拒绝 · 理由：输出语义与推送动作的耦合裂缝 · 工具链难以一致实现

**评估但不采纳的副作用开关**（`06 §5.2` · 作为路径 A 消化后的补充）：
- `orphan_check` 副作用开关 · **默认关闭** · 仅当显式开启时 evolution 兼任孤儿检测（输出 `orphan_candidates[]`）· 该开关**不发事件** · 仅写入 scan_result body · 符合决议 4 "纯观测" 本质（不产生决策类外向推送）
- `orphan_check.scanned_at` 必须与顶层 `produced_at` 同值（§5.2 A3 约束 · 对齐 §3.3 客观性承诺的字段级落实）

**下游消费模型**（决议 5 接口终点）：
- evolution.scanned 事件承载 L1 读 3 字段（`drift_event_urn` / `scope_urn` / `decision`）
- scan_result artifact 承载 L2 读 11+ 字段（含 `scanned_drifts[]` 详情 + `attribution[]` 完整归因链）
- **任何下游的决策推送都在 evolution 之外发生**（adapter 层 / taskdag 层 / 人工）

**MVP 工具链路径简化收益**：`piao-evolution-scan.sh` 的代码路径**不包含决策引擎** · 不需要规则匹配 / 阈值判断 / 优先级打分 · 估算脚本规模 ~200 行（对标 `piao-drift-compute.sh` MVP 555 行 · 激进组合 4-B + 5-B 估算 ≥600 行）· 1–2 个工作日可落地 · 与 M5 `piao-drift-compute.sh` MVP 节奏对齐。

**工具链侧证据**：TB'2（evolution 扫描器可兼任孤儿检测 · 长期建议 T'1 提取为独立 MVP 留给 M7+ · M5 toolchain-extension-review §3.2）· R4 §5.2 字面兑现 TB'2 副作用开关设计 · 保持"observability 而非 decision"边界。

**正式入档位置**：`06-evolution-model.md §5` 全章 + §5.1 4-A 选择论证 + §5.2 orphan_check schema + §5.3 evolution.scanned 事件语义 + §5.4 G1–G5 产出禁止项。

---

### 决议 5 — evolution → next 接口（Q6.5）：终止于 scan_result · 双层消费 · 不直发 task.proposed

**问题**：evolution 的输出喂给谁？是否产生新的 kernel 层（M8+）？还是完全收敛到 M3 taskdag？evolution 是否终止于"产出 task 建议"即不再向下？

**决议**：**evolution 终止于 scan_result**（**R5 硬约束** · 方案 5-A）· evolution 链路在"写 scan_result artifact + 发 evolution.scanned 事件"处**停止** · **不主动推送任何下游决策事件**。

**双层消费模型**（`06 §6.1` · 对齐 `05 §6.1` drift 双通道范式）：
| 层 | 字段数 | 复杂度 | 消费者 | 语义 |
|----|-------|------|------|------|
| **L1 · 事件流** | 3 字段（`drift_event_urn` / `scope_urn` / `decision`）| O(1) | 下游事件订阅者 | 决策路由 · 快速分派 |
| **L2 · artifact 拉取** | 11+ 字段（含 `scanned_drifts[]` / `decision_log[]` / `attribution[]` / `orphan_check?`）| O(N) | 审计 / 报告 / 手动回溯 | 详情挖掘 · 完整证据链 |

**双 event_id 前缀规约**（`06 §6.2` · 对齐 `05 §6.2` R19 范式）：
- evolution artifact 的 `produced_by.event_id` 前缀 = `drift-triggered-*`（evolution artifact 是 drift.detected 驱动下的 artifact.published 派生）
- `evolution.scanned.event_id` 前缀 = `evolution-scanned-*`
- 两者通过前缀明确区分 · 避免共享裸 `evolution-*` 前缀

**下游接口边界**（`06 §6.6` · M7+ 不预设）：
- evolution **不直发 `task.proposed`** · 下游需要建 task 时由 taskdag 层（M3）或 adapter 层读取 scan_result 自主决策
- evolution **不直发 `proposal.generated`** · 下游需要建 proposal 时由人工或专用脚本读取 scan_result 自主决策
- evolution **不预设 M7/M8 新 kernel 层** · 07-extensibility.md @v1.1 published 已覆盖的扩展点由 M7 独立决策 · evolution 仅作为"决策终点"存在

**消费禁止项 F1–F4**（`06 §6.4` · 与 `05 §6.3` C1–C4 前置契约互为对偶）：
- F1 · 禁止绕过事件流直读 artifact 目录（必须走 evolution.scanned L1 → scan_result L2 双层路径）
- F2 · 禁止反向写入 evolution artifact（不可变契约 · 继承 `05 §6.3 C1`）
- F3 · 禁止自行补归因（必须走 `02 §4` provenance 四元组 + `05 §5.3` 归因三元组 · 继承 `05 §6.3 C3`）
- F4 · 禁止修改 evolution.scanned 事件的 status（对齐 `03 §3.3` append-only · 继承 `05 §6.3 C4`）

**C1–C4 前置契约继承**（`06 §6.5` · 从 `05 §6.3` 字面继承）：
- C1 · 下游不得反向写入 drift artifact（M6 evolution 不破坏 M5 契约）
- C2 · 下游不得自行补 drift 归因（M6 必须走 `05 §5.3` provenance 链）
- C3 · 下游必须走 `02 §5.3.1 kind=drift` 特化查 drift depends_on
- C4 · 下游不得修改 drift 的 status

**工具链侧证据**：TB'3（`3 字段优先 + 11 字段兜底` 双层 · 禁止绕过事件流直读 artifact · M5 toolchain-extension-review §3.3）· R5 直接兑现双层消费模型 · F1 "禁止绕过事件流" 与 `m5_final_decisions §1 决议 5` 双证据锚定。

**正式入档位置**：`06-evolution-model.md §6` 全章。

---

### 决议 6 — 跨篇一致性：路径 A 先 + 路径 B 后 + 06 跟随升版（与 M5 同模式）

**问题**：06 draft 完成后，review 识别到的 Q21–Q26 六条缺口（其中 2 条路径 B）如何与 06 draft→published 协调？

**决议**：**采用"先 A 后 B 再跟随升版"七步执行序**（S0–S6 · 对标 M5 九步序但密度简化 · 因 M6 路径 B 仅 2 条 vs M5 的 5 条），分别在 `m6-evolution-draft-review @v1 §3.3` 与 `m6_evolution_kernel_alignment @v1 §3` 锁定。

**七步执行序**（全部已完成）：

| Step | 动作 | 结果 | 产出 URN / commit |
|------|------|------|-------------------|
| 1 | 路径 A：Q23–Q26 在 06 draft 内原地消化（A1–A4 · 不升 rev） | ✅ | `06 @v1 (draft · 路径 A 消化 · 2026-04-19 19:54)` · commit `e6e18d5f` |
| 2 | 路径 B proposal self-review + published | ✅ | `m6_evolution_kernel_alignment@v1 published` · commit `1c106937` |
| 3 | 路径 B · S1：03 @v1 draft 原地精化（B1 · evolution.scanned 行 subject + 语义字段 refresh） | ✅ | `03 draft 原地修订` · commit `76bbfff5` |
| 4 | 路径 B · S2：02 @v1.3 → @v1.4 published（B2 · 派生注册表新增 evolution.scan_result） | ✅ | `02 @v1.4 published` · commit `7a7bce04` |
| 5 | 反向对接：06 @v1 draft → @v1.1 draft（8 处锚点注释同步 · 仍 draft · 纯状态刷新） | ✅ | `06 @v1.1 draft` · commit `44bf034b` |
| 6 | S5：`m6-evolution-draft-review @v1 §5` 路径 A/B 消化记录追补 + 四段式 review 收官 | ✅ | commit `587e58d1` |
| 7 | S6：`m6_evolution_kernel_alignment@v1` 收官 + `m6-evolution-draft-review @v1 published` + `proposal.implemented` 事件发射 | ✅ | 2026-04-19 21:05 |
| 8 | **本步**：`m6-final-decisions@v1` 产出 + self-review 签收 + 升 published（2026-04-19 21:34）·（升 published 后触发）06 @v1.1 draft → @v1.1 published（待工具链 MVP 反证 · 见 §4） | ✅（本快照 published）| `m6_final_decisions@v1 published` |

**B1–B2 两条修订的最终落地矩阵**：

| 修订 | 源自 | 目标 | 落地 rev | 路径 | commit |
|-----|-----|------|---------|-----|-------|
| A1 | Q23（L1 事件 3 字段上限普适性）| `06 §6.7` 末尾补契约边界澄清段 | draft 内原地 | A | `e6e18d5f` |
| A2 | Q24（`scanned_drifts[]` 字段必填性）| `06 §2.3` schema 必填性列补齐 | draft 内原地 | A | `e6e18d5f` |
| A3 | Q25（`orphan_check.scanned_at` 与 `produced_at` 对齐）| `06 §5.2` orphan_check schema 同值约束补 | draft 内原地 | A | `e6e18d5f` |
| A4 | Q26（retracted 条件 #2 与 kernel rev 升版对接）| `06 §7.3` retracted 条件 #2 末尾脚注补 | draft 内原地 | A | `e6e18d5f` |
| B1 | Q21（`03 §3.1` L1 事件 `evolution.scanned` 语义字段 refresh）| `03 §3.1` L1 事件表 evolution.scanned 行 subject 从"task URN"→"scope URN" + 语义字段从 M4 占位 → 06 实锁四字段（`drift_event_urn, scope_urn, scanned_drifts[], decision_log[]`）| 03 draft 原地（不升 rev）| B | `76bbfff5` |
| B2 | Q22（`02 §2.2.4` 派生注册表补登 `evolution.scan_result`）| `02 §2.2.4` 新增七字段 YAML 登记块（`wordcheck_policy: machine_generated`）| @v1.3 → @v1.4 | B | `7a7bce04` |

**理由**：
1. 路径 A 先消化（Q23–Q26）保证 06 draft 形态稳定 · 路径 B 可由稳定的 06 驱动（与 M5 路径 A 先消化 R17–R20 同模式）
2. 路径 B 完成后 06 仅需反向对接锚点（§2.4 B2/B3 + §2.5 + §8.2 门控 #4 + §9 前置契约表 + §11 下游锚点五处）· 不需要结构性重写
3. `m6-final-decisions@v1` 作为独立 milestone 封板快照 · 与 `m6_evolution_kernel_alignment@v1 published` **分离角色**（proposal 负责契约侧闭环 · final-decisions 负责 milestone 封板 + 工具链 MVP 前置锁定）· 对标 M5 `m5-final-decisions@v1` + `m5_drift_kernel_alignment@v1 published` 分离范式

**密度对比 M5**（验证"M6 站在 M1–M5 五层封板契约之上 · 缺口密度递减"范式）：
| 维度 | M5 | M6 | 密度比 |
|------|-----|-----|-------|
| review 缺口总数 | 14（Q1–Q14）| 6（Q21–Q26）| 43% |
| 路径 B 条数 | 5（R21–R25）| 2（B1–B2）| 40% |
| alignment-proposal 行数 | 379 | 321 | 85% |
| 触及文档数 | 4（04/02/03/05）| 3（02/03/06 跟随）| 75% |

**正式入档位置**：`06-evolution-model.md §8.1 rev_history` + `m6-evolution-draft-review @v1 §5` + `m6_evolution_kernel_alignment @v1 §3` / `§4` / `§6` DoD。

---

## 2. 快照产出清单

| 文件 | 本快照对应的 rev / status |
|------|-------------------------|
| `06-evolution-model.md` | **v1.1 / draft → published**（M6 milestone 核心产出 · 升 published 由承接本快照的下一 commit 执行 · 见 §7 门控复核） |
| `05-drift-propagation.md` | v1.1 / published（本次 M6 未改动 · 沿用 M5 状态） |
| `04-version-snapshot.md` | v1.2 / published（本次 M6 未改动 · 沿用 M5 状态） |
| `03-layered-architecture.md` | v1 / draft（M1 review 周期内 · B1 原地修订 · 按 `01 §10.1` 合规 · 10 类枚举总数不变） |
| `02-artifact-model.md` | **v1.4 / published**（B2 落地 · 派生注册表新增 `evolution.scan_result`） |
| `01-identity-model.md` | v1.2 / published（本次 M6 未改动 · 沿用 M4 状态） |
| `07-extensibility.md` | v1.1 / published（本次 M6 未改动） |
| `scenario-wordlist.md` | v1 / draft（本次 M6 未改动） |

### 2.1 四份 kernel review artifact（本 milestone 周期配套产出）

| 文件 | URN | 状态 |
|------|-----|------|
| `_review/m6-evolution-kickoff.md` | `urn:piao:proposal:kernel:m6_evolution_kickoff@v1` | published（M5→M6 过渡 proposal · supersedes `m5_drift_kickoff@v1` · 本快照产出后进入 `superseded` 状态） |
| `_review/m5-toolchain-extension-review.md` | `urn:piao:artifact:kernel:m5_toolchain_extension_review@v1` | published（阶段 α 退出门 · TB'1–TB'5 工具链视角证据 · M6 复用 M5 产出 · 未独立再产 M6 toolchain-review） |
| `_review/m6-evolution-draft-review.md` | `urn:piao:artifact:kernel:m6_evolution_draft_review@v1` | published（阶段 β 工作流 E 退出门 · 四段式起稿 · §5 路径 A/B 消化记录已追补 · 已于 S6 2026-04-19 21:05 升 published） |
| `_review/m6-evolution-kernel-alignment-proposal.md` | `urn:piao:proposal:kernel:m6_evolution_kernel_alignment@v1` | published（路径 B 打包处置 · B1–B2 已 implemented · 2026-04-19 21:05 `proposal.implemented` 事件发射） |
| `_review/m6-final-decisions.md` | `urn:piao:snapshot:kernel:m6_final_decisions@v1` | **published**（2026-04-19 21:34 · §8 self-review 六项签收通过 · event_id `milestone-closeout-m6-final-decisions-v1`） |

### 2.2 工具链产出（阶段 α 核心 · 本 milestone 已完成）

| 脚本 | 行数 | 实现契约 | commit |
|------|-----|---------|-------|
| `scripts/piao-drift-compute.sh` | 876（+321 vs M5 MVP）| 05 §5.1/§5.2/§5.3（`--full-mode` 归因双模式 + 降级透明暴露）+ 05 §6.1/§6.2（`--emit-events` 原子写入 `artifact.published(D) + drift.detected` 两条 L1 事件 · N=2 同 txn）+ 03 §3.3.1 R22 N 条同 txn 泛化契约（N=2 合法子集）| M5 阶段 α 扩展 · 见 `m5-toolchain-extension-review @v1 §0` |

**阶段 α 退出门 G1–G6 反证证据**（`m5-toolchain-extension-review @v1 §0.1` · 本快照引用不重复）：

| # | 反证 | 契约对接 |
|---|------|---------|
| G1 | `--full-mode` 真实 event-journal 归因链完整 | R4 `attribution_mode=full` + `attribution[]` 非空 |
| G2 | `--full-mode` 缺事件场景降级 `sha_only` + `reason` | R4 降级透明暴露 |
| G3 | `--emit-events` 端到端两条事件原子写入 | R5 双通道（通道 A 事件流）+ R19 双 event_id 前缀分离 |
| G4 | `drift.detected.evidence.{old,new}_snapshot_urn` 字面精确匹配 | 03 §3.1 双轨原则 |
| G5 | 原子回滚反证（事件写入前注入错误 · drift artifact 不留存）| 03 §3.3.1 N=2 原子性 |
| G6 | wordcheck `--ci` 零新增（6 BAN + 5 WARN 全 pre-existing）| 全篇 wordcheck 基线不退 |

### 2.3 工具链产出（阶段 β 本 milestone 未实施 · 延至升 published 前置）

| 脚本 | 状态 | 契约依据 | 预期节奏 |
|------|------|---------|---------|
| `scripts/piao-evolution-scan.sh` | 🚧 **待起稿**（升 @v1.1 published 门控 #2/#3 反证条件）| 06 §2.3（scan_result schema · 含路径 A A2/A3 必填性 + 同值约束）· 06 §3（E1–E5 原子流程）· 06 §4（scope 三层一致性链）· 06 §5（4-A 纯观测决策）· 06 §6（5-A 终止于 scan_result · 双层消费 + 双 event_id 前缀 `drift-triggered-*` / `evolution-scanned-*`）· 06 §7（不升 rev 生命周期）· 03 §3.1 `evolution.scanned` 行实锁 schema（B1 已对接）· 02 §2.2.4 `evolution.scan_result` 派生注册（B2 已对接）· 03 §3.3.1 N=2+k 原子写入 · 02 §4 provenance 四元组 | **1–2 工作日**（对标 M5 `piao-drift-compute.sh` MVP 首版节奏 · 决议 4-A + 5-A 保守组合代码路径简化 · 估算 ~200 行 · 远低于 drift MVP 555 行）|

---

## 3. 引用方式

其他文档引用本快照时使用：

```
见 M6 最终决议快照：
urn:piao:snapshot:kernel:m6_final_decisions@v1
（docs/piao-pipeline/kernel/_review/m6-final-decisions.md）
```

---

## 4. 下一步（`piao-evolution-scan.sh` MVP 前置 + 06 @v1.1 draft → published 门控 + M7 入口）

本快照**不规定** MVP 实施细节，但记录**升 @v1.1 published 的工具链 MVP 反证门控前置清单**（锁定 MVP 的唯一契约依据为本快照 + 06 @v1.1 draft）：

### 4.1 `piao-evolution-scan.sh` MVP 前置清单

**命名空间延续**（沿用 `m5_drift_kickoff §3.1` + `m6_evolution_kickoff §3.1` 双前例）：
- `scripts/piao-evolution-scan.sh`（M6 阶段 β 核心产出 · 尚未起稿）

**必须实现的核心契约**：
- [ ] **输入**：`--drift-event <event_id>` 指定单条 drift.detected 事件 URN（决议 2 唯一触发器）· 或 `--scope <scope_urn>` 指定 scope 批聚合（决议 3 模式 A/B）
- [ ] **输入 snapshot 来源**：从 drift artifact 的 `depends_on` 字段读两张 snapshot URN（`02 §5.3.1 kind=drift` 特化查询 · 对齐 F3 契约）
- [ ] **scope 继承**：直接继承 drift scope · 拒绝跨 scope_kind 与跨 scope_ref 输入（决议 3 R3 · 三层一致性链 L2）
- [ ] **决策规则**：纯观测（决议 4 R4 · 4-A）· 无决策引擎 · 仅产出：
  - `scanned_drifts[]`（消化清单 · A2 字段必填性：`drift_urn`/`decision`/`drift_event_id` 必填 · `driver_event_id` 条件必填 · sha_only drift 时为 null）
  - `decision_log[]`（决策日志 · 可空）
  - `attribution[]`（归因链 · 透传自 drift artifact 归因）
  - `orphan_check?`（副作用开关 · 默认关闭 · `scanned_at == produced_at` 同值约束）
- [ ] **输出 artifact**：`evolution.scan_result` yaml（02 §2.2.4 @v1.4 注册 · `wordcheck_policy: machine_generated` 自动继承 `wordcheck_exempt: true`）
- [ ] **输出事件**（决议 5 R5 · 双通道）：
  - L1 事件流：`evolution.scanned`（3 字段上限：`drift_event_urn` / `scope_urn` / `decision`）
  - L2 artifact 拉取：scan_result body 11+ 字段
- [ ] **双 event_id 前缀**：artifact produced_by = `drift-triggered-*` · evolution.scanned = `evolution-scanned-*`
- [ ] **原子写入**：N=2+k 同 txn（artifact.published(E) + evolution.scanned + k 个副作用事件）· 对齐 03 §3.3.1 M5 泛化契约
- [ ] **降级策略四场景**（决议 2）：读 journal 失败 / 拉 artifact 失败 / E5 原子写失败 / 手动补救
- [ ] **禁止事项 F1–F4 实装反证**（决议 5 · 对偶于 C1–C4）
- [ ] **禁止产出事件 G1–G5 实装反证**（决议 4 · `task.started` / `task.completed` / 非自身 `artifact.published` / `snapshot.published` / `drift.detected` / `retracted.*`）

**冒烟场景**（对标 `piao-drift-compute.sh` SMOKE 1–4 范式）：
- [ ] SMOKE 1：单条 drift.detected → 输出 scan_result + 发 evolution.scanned 事件（基本通路）
- [ ] SMOKE 2：空事件流 / 已消化 drift → 空 scan_result（幂等性）
- [ ] SMOKE 3：跨 scope 输入拒绝（退出码非零 · 错误引用 `06 §4.1 R3` · 三层一致性链反证）
- [ ] SMOKE 4：`--emit-events` 原子写入 N=2 两条 L1 事件（对齐 drift MVP G3/G5 范式 · 覆盖正常路径 + 回滚路径）

### 4.2 06 @v1.1 draft → @v1.1 published 门控（见 §7 复核）

- [x] `_review/m6-evolution-draft-review.md` 产出 + 锚点完整性校验（`m6-evolution-draft-review @v1 published` · 2026-04-19 21:05）
- [ ] 至少一条真实 evolution.scan_result artifact 产出验证 schema 可实施（🚧 待 `piao-evolution-scan.sh` MVP）
- [ ] R1–R5 五条硬约束未被实施反例证伪（🚧 待 MVP 端到端冒烟）
- [x] **本快照 `_review/m6-final-decisions.md` 产出 + 升 published**（2026-04-19 21:34 · §8 self-review 六项签收通过）

### 4.3 本快照后的配套动作清单

- [x] 本快照 self-review 签收 + draft → published（2026-04-19 21:34 · §8 六项全 ✅）
- [x] 发射 `artifact.published` 事件（本快照作为 `kind=snapshot` · evt id 前缀 `milestone-closeout-*` · 具体 id `milestone-closeout-m6-final-decisions-v1` · 本 commit 同批固化 · 2026-04-19 21:54）
- [x] `m6_evolution_kickoff @v1 status: published → superseded`（承接 `superseded_by: urn:piao:snapshot:kernel:m6_final_decisions@v1` · `superseded_at: 2026-04-19T21:34:00+08:00` · 对称 `m5_drift_kickoff @v1 → m5_final_decisions@v1` 范式 · 本 commit 同批固化）
- [x] `M1-debt-ledger @v6 → @v7`（登记 Q21–Q26 六条 consumed + A1–A4 / B1–B2 六条 consumed 证据 · 对标 M5 `@v5 → @v6` 节奏 · 本 commit 同批固化 · §1.5 全新章 + §3 关闭条件 §1.5 行 + 末尾元信息四行 refresh）
- [ ] 启动 `piao-evolution-scan.sh` MVP 实施（阶段 β 核心 · 本快照 §4.1 列表为契约唯一来源）
- [ ] MVP 通过 SMOKE 1–4 后 · 升 06 @v1.1 draft → @v1.1 published（门控复核见 §7）

### 4.4 非目标（M6 post-published 不做）

- evolution GC / 归档策略（M7 之后 · 对齐 `05 §11` / `04 §9` · 见 06 §7.4 H4）
- evolution 的 UI 可视化 / dashboard（工具链侧 · 非 kernel · 对齐 `05 §11` 非目标）
- evolution 与外部系统对接（IDE hook / CI 通知 / IM 推送 · adapter 层范畴）
- evolution 的优先级算法 / 排序策略（工具链侧实施细节 · kernel 只承诺 schema 与接口）
- evolution 跨 scope 联合扫描（`06 §4.3/§4.4` 硬约束拒绝 · 应用层需跨 scope 时用两次单 scope evolution · 本快照决议 3 R3 封板）
- **决策类下游事件发射**（`task.proposed` / `proposal.generated` / `doc.upgrade.proposed` 等 · 本快照决议 4 R4 封板 · 留给 M7 adapter 层）

### 4.5 M7 入口预声明

- M6 封板后 · 按 `m6_evolution_kickoff §2.5` 里程碑地图 · 进入 **M7 Extensibility milestone 收尾决策点**：
  - 若 `07-extensibility.md @v1.1 published` 已充分覆盖 adapter 层需求 → 直接进入 **v0.1 里程碑收官**（kernel 七大模型全部 published · 产出 `v0_1_final_decisions@v1`）
  - 若 M7 需要补升 → 起草 `m7_closeout_kickoff@v1` proposal（对标 `m5_drift_kickoff@v1` / `m6_evolution_kickoff@v1` 范式 · 为 **kernel 层该范式第四代实例**）

---

## 5. M6 milestone 成色自评

- **五问回答**：✅ **充分**（决议 1–5 各对应一个必答问题 · R1–R5 五条硬约束证据完备 · 落位清晰 · 相互不冲突 · 见 `m6-evolution-draft-review @v1 §1.1`——"五问回答全部充分 · 相较 M5 draft-review 更成熟"）
- **kernel 锚点 34 条全部存在**：✅ 已闭环（`m6-evolution-draft-review @v1 §1.2` 34 条逐条校验 · 唯一一条"引用姿势需补锚点"的 Q21（03 §3.1 L1 事件枚举）已通过路径 B S1 B1 原地精化消化完成）
- **跨篇一致性**：✅ 已闭环（决议 6 · A1–A4 路径 A 四条 + B1–B2 路径 B 两条全 consumed · 06/03/02 三篇文档锚点双向可追溯 · 三个前置锚点钩子全部反向对接 · 见 `m6-evolution-draft-review @v1 §5.6`）
- **工具链侧反证**：⚠️ **契约侧完备 · 实施侧待反证**（`piao-drift-compute.sh` 阶段 α 扩展 G1–G6 反证完备 · 但 `piao-evolution-scan.sh` MVP 未产出 · 即 R1–R5 中 R2/R3/R4/R5 的"evolution 侧实装反证"尚未完成 · 本快照 §4.1 已锁定 MVP 前置清单 · 升 06 @v1.1 published 前必须反证 —— 与 M5 快照产出时 `piao-drift-compute.sh` MVP 已完成的节奏略有不同 · 但 M5 是"工具链先行 + 规格跟进"· M6 是"规格先行 + 工具链跟进"· 对应 kickoff §2 T' 优先路径 · 符合预期）
- **配套 review 产出**：✅ 五件套齐备（kickoff / toolchain-extension-review · M5 产出 M6 复用 / draft-review / kernel-alignment-proposal / final-decisions · 与 M5 五件套对齐 · 反映"工具链扩展→规格起稿→规格 review→规格 published→工具链 MVP→终态封冻"双循环闭环）
- **债务登记完整性**：⚠️ `M1-debt-ledger @v6 → @v7` 待同步登记 Q21–Q26 六条 + A1–A4 / B1–B2 六条 consumed 证据（见 §4.3 配套动作 ④ · 不阻塞本快照 draft · 对标 M5 `@v5 → @v6` 范式节奏）
- **wordcheck**：✅ 06 @v1.1 draft + 02 @v1.4 / 03 draft 升版与基线一致（6 BAN + 5 WARN 遗留 · 均在 02 既有条款 · 与 M6 无关 · 见 `m6_evolution_kernel_alignment @v1 §6` DoD 实跑确认）
- **范式复用性**：✅ **kernel 层范式第三代成熟验证**（`post-m1-kickoff → m4_final_decisions` / `m5_drift_kickoff → m5_final_decisions` / `m6_evolution_kickoff → m6_final_decisions` 三代同构 · 双形态 / 双通道 / 三层订阅链 / 拒绝列表 / C1–C4 继承五大范式全部第三次复用 · 缺口密度 43% 递减符合"M6 站在 M1–M5 肩膀上"预期）

---

## 6. `m6_evolution_kickoff @v1` 生命周期闭合

按 `m6_evolution_kickoff @v1 §6` 关闭条件：
- ✅ 工作流 T'（阶段 α · M5 工具链扩展）· `piao-drift-compute.sh --full-mode` + `--emit-events` + `m5-toolchain-extension-review @v1 published`（2026-04-19 17:45 · 附录 A β-2 判定）
- ✅ 工作流 E（阶段 β · M6 Evolution 规格起稿）· `06-evolution-model.md @v1 → @v1.1` draft 首版 + `m6-evolution-draft-review @v1 published` + `m6_evolution_kernel_alignment @v1 published`（2026-04-19 21:05）
- ✅ M6 milestone 收官 · 本快照产出 + 升 published（2026-04-19 21:34 · §8 self-review 六项签收通过）

**状态转换**：`m6_evolution_kickoff @v1 status: published → superseded`（本快照 `urn:piao:snapshot:kernel:m6_final_decisions@v1` 承接 · 与 `m5_drift_kickoff @v1 superseded_by: m5_final_decisions@v1` 对称范式）。

**三代 kickoff 接力链完整**：
```
post-m1-kickoff@v1 published → superseded by m4_final_decisions@v1
  ↓ 接力
m5_drift_kickoff@v1 published → superseded by m5_final_decisions@v1
  ↓ 接力
m6_evolution_kickoff@v1 published → superseded by m6_final_decisions@v1 (本快照)
  ↓ 接力候选
m7_closeout_kickoff@v1 published (若 M7 需补升 · 否则直接 v0.1 milestone 收官)
```

**双向可追溯**：本快照 §2.1 已登记 `m6_evolution_kickoff @v1 → superseded` · `m6_evolution_kickoff @v1` 自身的 status 字段变更由配套 commit 追加（`01 §10.1` published 文档不升 rev 原则 · 仅改 status 合规 · 参考 `m5_drift_kickoff @v1` / `post-m1-kickoff @v1` 双前例）。

---

## 7. `06-evolution-model.md @v1.1 draft → @v1.1 published` 门控复核

按 `06 §8.2` 四门控（`@v1 draft` 阶段全部 `[x]` · 本节复核"升 published"附加条件）：

| 门控 | 当前状态 | 证据 |
|------|---------|-----|
| #1 · `_review/m6-evolution-draft-review.md` 产出 + 锚点完整性校验 | ✅ 达成 | `m6-evolution-draft-review @v1 published` 四段式 · 34 条锚点全部校验通过 · §5 路径 A/B 消化记录追补完整 · commit `4b1e7b9e` / `56d1ddc8` / `f546719b` / `587e58d1` 四段 + S6 批升 |
| #2 · 至少一条真实 `evolution.scan_result` artifact 产出验证 schema 可实施 | ⚠️ **待达成** | `scripts/piao-evolution-scan.sh` MVP 尚未起稿 · 本快照 §4.1 已锁定前置清单 · 对标 M5 `piao-drift-compute.sh` 产出 4 场景冒烟节奏 |
| #3 · R1–R5 五条硬约束未被实施反例证伪 | ⚠️ **待达成** | 契约侧已证（M5 toolchain-extension-review TB'1–TB'5 对 R1–R5 映射矩阵完备 · `m6-evolution-draft-review @v1 §1.3`）· 实施侧待 MVP 反证（SMOKE 1–4 端到端） |
| #4 · `_review/m6-final-decisions.md` 产出 | ✅ **达成**（本快照 published · 2026-04-19 21:34）| 当前文档 · §8 self-review 六项签收通过 · event_id `milestone-closeout-m6-final-decisions-v1` |

**门控 #4 达成的同时 · 门控 #2/#3 仍需工具链 MVP 反证**。这与 M5 `05 @v1.1 draft → @v1.1 published` 同节奏（M5 亦卡在 `piao-drift-compute.sh` MVP 反证处 · MVP 产出后升 published）——但 M6 的顺序是**先 final-decisions 再 MVP 再升 published**（final-decisions 为 MVP 实施的唯一契约依据），与 M5 **先 MVP 再 final-decisions 再升 published** 路径不同。

**顺序差异理由**：
1. M5 阶段 α 工具链（`piao-drift-compute.sh` MVP）可在 `05 @v1 draft` 阶段起稿——因其契约依据是 04/02/03 已 published 的内容
2. M6 `piao-evolution-scan.sh` MVP 必须以 06 @v1.1 draft 的 **final-decisions 冻结态**为契约依据——若 R1–R5 在 MVP 实施过程中被反例证伪而未冻结 · 会出现 "MVP 与 draft 契约漂移" 反模式 · 不符合 kickoff §2 的"先决议后实施"依赖方向
3. 故本快照采取 **"final-decisions published 先行锁定契约 → MVP 依照契约实施 → 门控 #2/#3 反证通过 → 06 @v1.1 published"** 四步路径

**定性结论**：本快照 draft → published 已完成（2026-04-19 21:34）· 门控 #4 达成 · 门控 #2/#3 进入 MVP 实施期。**本快照升版动作由 §8 self-review 六项签收通过 + 本 commit 原地执行（front-matter `status: published` + `published_at: 2026-04-19T21:34:00+08:00` + `event_id: milestone-closeout-m6-final-decisions-v1` · 对标 `m5_drift_kernel_alignment@v1 §8` 六项 self-review 范式）**。06 @v1.1 draft → @v1.1 published 的最终升版则由 MVP 产出完成后的独立 commit 执行 · 不进入本快照管辖范围。

---

## 8. Self-review 签收（升 published 前自检 · 对标 M5 final-decisions + alignment-proposal 双范式）

本快照升 `status: draft → published` 前已完成以下六项 self-review · 逐项签收结论如下（**签收动作已在本 commit 同步完成 · 2026-04-19 21:34**）：

### 8.1 结构完备性

| 章节 | 对标 M5 final-decisions | 本快照状态 |
|-----|----------------------|----------|
| §0 快照覆盖范围 | ✅ 有 | ✅ 齐备 · 受管文档 / 工具链 / 时间窗 / 四件套依据 |
| §1 N 项最终决议 | ✅ 有（M5 为 6 项）| ✅ 齐备 · 六项（Q6.1–Q6.5 五问决议 + 跨篇一致性决议 6） |
| §2 快照产出清单 | ✅ 有（三子节）| ✅ 齐备 · 三子节 §2 / §2.1 / §2.2 / §2.3（M5 仅 §2.1/§2.2 · M6 新增 §2.3 本 milestone 未实施的工具链声明） |
| §3 引用方式 | ✅ 有 | ✅ 齐备 · URN 引用模板 |
| §4 下一步清单 | ✅ 有 | ✅ 齐备 · 五子节（§4.1 MVP 前置清单 / §4.2 06 门控 / §4.3 本快照后配套动作 / §4.4 非目标 / §4.5 M7 入口预声明） |
| §5 milestone 成色自评 | ✅ 有（M5 为 7 项）| ✅ 齐备 · 八项（M6 新增"范式复用性"一项 · 体现第三代复用验证） |
| §6 kickoff 生命周期闭合 | ✅ 有 | ✅ 齐备 · 三代 kickoff 接力链图示完整 |
| §7 N draft → published 门控复核 | ✅ 有 | ✅ 齐备 · 四门控状态矩阵 + M5/M6 顺序差异理由 |
| §8 Self-review 签收（本节）| ✅ 有（M5 final-decisions 隐性 · M5 alignment-proposal 显性）| ✅ 本段 |

**结论**：结构 8 章主节 + 14 子节 · 对标 M5 final-decisions 7 章 · 增 §7 顺序差异段 + §8 self-review 签收段（M6 首次在 final-decisions 中引入 self-review · 参考 `m6_evolution_kernel_alignment @v1 §9` 六项范式）。

### 8.2 锚点准确性

| 锚点类别 | 验证方式 | 签收结论 |
|---------|---------|---------|
| 决议 1–5 与 06 正文对应章节 | §1 各决议末注"正式入档位置"字面引用 06 §2/§3/§4/§5/§6 | ✅ 准确 |
| 决议 6 七步执行序 | §1 决议 6 表格对齐 `m6-evolution-draft-review @v1 §5.2` 路径 B 四步执行表 + `m6_evolution_kernel_alignment @v1 §6` DoD 十项 | ✅ 准确（S1/S2/S3/S4/S5/S6 commit hash 字面对接） |
| §2 快照产出清单 rev 状态 | 与 06 @v1.1 / 02 @v1.4 / 03 draft 当前 front-matter 字面一致 | ✅ 准确（`search_content` 已校验 06 `urn:@v1.1` / `rev: v1.1` / `status: draft` · 02/03 由 proposal §6 DoD 实跑确认） |
| §4.1 MVP 前置清单契约条款 | 逐条对接 06 @v1.1 draft §2.3 / §3 / §4 / §5 / §6 / §7 + 03 §3.1 (B1) + 02 §2.2.4 (B2) + 03 §3.3.1 | ✅ 准确 |
| §7 门控复核 | 对齐 06 §8.2 四门控原文 + M5 同模式对比 | ✅ 准确 |
| TB'1–TB'5 工具链证据 | 每条决议末"工具链侧证据"引用 `m5-toolchain-extension-review @v1 §3.1–§3.5` | ✅ 准确（M5 review published · TB' 编号全部可查） |

**结论**：所有锚点经实读校验 · 无偏差。

### 8.3 体量合理性

| 维度 | M5 final-decisions | M6 final-decisions（本快照）| 评估 |
|-----|-----------------|-------------------------|-----|
| 总行数 | 326 | ~500 | M6 +54% · 原因：新增 §7 M5/M6 顺序差异段 + §8 self-review + §4.1 MVP 前置清单更详（因 M6 MVP 尚未产出 · 需锁定前置契约） |
| 决议条数 | 6 | 6 | 对齐 |
| 升级阶段矩阵行数（决议 6）| 9 步 | 8 步 | 密度 89% · 对应"M6 路径 B 2 条 vs M5 5 条" |
| 快照产出清单工具链行数 | 1 行（MVP 已产）| 2 表（MVP 已扩展 + MVP 待起稿）| M6 多出 §2.3 · 对应"规格先行 + 工具链跟进" |

**结论**：体量合理 · 增量来自"M6 特殊性" —— 顺序差异 + MVP 前置契约锁定 + self-review 引入 · 非范围蔓延。

### 8.4 决议风险闭环

M6 新增决议 4（纯观测）+ 决议 5（终止于 scan_result）属 M6 首创范式 · 未在 M4/M5 有先例 · 专项风险闭环：

| 风险 | 可能性 | 影响 | 缓解 |
|------|-------|-----|------|
| 决议 4 拒绝方案 4-B/4-C 后 · 未来 M7 需要决策产物怎么办？ | 低 | 低 | 本快照 §4.5 M7 入口预声明 + 06 §6.6 明示"不预设 M7/M8 新 kernel 层" · 决策类事件留给 adapter 层或 M7 独立 kernel · evolution 仅作为"决策终点"· 不构成 M7 启动阻塞 |
| 决议 5 方案 5-A 若下游消费者少怎么办？ | 低 | 低 | scan_result 作为"独立中间结算单"存在价值 —— 可被人直接查（debug/审计）· 可被多个下游共享（taskdag / adapter / dashboard）· 按需回溯 · 消费方少不影响产出价值 |
| 本快照 draft → published 与 06 @v1.1 draft → published 顺序颠倒风险 | 低 | 中 | §7 已明示"本快照 published 先行 → MVP 实施 → 06 published"四步路径 · M5/M6 顺序差异理由已在正文锁定 · 避免误读为"M5 同模式顺序" |
| MVP 实施发现 R1–R5 硬约束反例 | 中 | 中 | 06 §8.3 已预声明升 @v2 的三条件 · 若 MVP 实施发现 R 条约反例 · 走 `m6_final_decisions@v2` 新快照（不改本 v1）· 本快照 `supersedes: null` 可被未来新快照覆盖 · 对齐快照即事实原则 |
| `piao-evolution-scan.sh` MVP 实施延期影响 v0.1 收官 | 中 | 低 | 1–2 工作日预估（决议 4-A + 5-A 保守组合简化收益）+ `piao-drift-compute.sh` 扩展为参照蓝本 · 延期风险可控 |

**结论**：五条风险全部闭环 · M6 首创范式（决议 4/5）的后续演进路径已在 06 §8.3 + 本快照 §4.5 预留。

### 8.5 证据层对接

| 证据类型 | 位置 | 状态 |
|---------|-----|-----|
| 上游锚点（10 条 upstream）| front-matter | ✅ 10 条齐全（M5 final-decisions 7 条 · M6 多 3 条为 M6 特有：draft-review + kernel-alignment-proposal + evolution_model@v1.1）|
| review 来源引用 | §1 各决议末注位置 + §2.1 五件套表 + §7 门控复核 | ✅ 多处引用 `m6-evolution-draft-review @v1` / `m5-toolchain-extension-review @v1` |
| M5 同模式对标 | §1 决议 6 密度对比表 + §5 范式复用性 + §7 顺序差异 + §8.3 体量合理性 | ✅ 四处对标 M5 · 均给出数值或定性依据 |
| 决议 4-A + 5-A 保守组合反证链 | §1 决议 4 / 决议 5 末注拒绝方案反证 | ✅ 4-A 反证 4-B/4-C · 5-A 反证 5-B · 反证链完整 |
| wordcheck_exempt 声明 | front-matter line 25 | ✅ `true` · 对标 M5 final-decisions 同模式 |

**结论**：证据层对接完整 · 上下游锚点齐全 · 无断链。

### 8.6 签收结论

- **六项 self-review 结论**：结构完备性 ✅ · 锚点准确性 ✅ · 体量合理性 ✅ · 风险闭环 ✅（含决议 4/5 M6 首创范式专项）· 证据层对接 ✅ · 签收结论 ✅
- **升版决定**：`status: draft → published` · **已执行**（本 commit 原地 · 2026-04-19 21:34 · front-matter `status: published` + `published_at` + `event_id: milestone-closeout-m6-final-decisions-v1`）
- **升 published 后触发序列**（已于 2026-04-19 21:54 本次批量 commit 全部落地 · Phase 1 配套动作三项完整收官）：
  1. ✅ 发射 `artifact.published` 事件（本快照 kind=snapshot · event_id `milestone-closeout-m6-final-decisions-v1` · 对齐 04 §3.2.3 canonical YAML 承诺 · §4.3 配套清单第 2 项复选框已勾选）
  2. ✅ `m6_evolution_kickoff @v1 status: published → superseded`（front-matter 升 superseded + 横幅追加 `superseded_by: urn:piao:snapshot:kernel:m6_final_decisions@v1` + `superseded_at: 2026-04-19T21:34:00+08:00` · 末尾"关闭候选"行改写为"✅ 已兑现" · 对标 `m5_drift_kickoff @v1` 范式同构）
  3. ✅ `M1-debt-ledger @v6 → @v7` · 登记 Q21–Q26 + A1–A4 / B1–B2 consumed（front-matter 升 @v7 + rev_history v7 行 + §1.5 全新章（1.5.1 六条缺口表 + 1.5.2 消化路径矩阵 + 1.5.3 与 §1.2/§1.3/§1.4 关系对照 + 1.5.4 路径执行总结）+ §3 关闭条件追加 §1.5 行 + 末尾元信息四行 refresh）
  4. ⏳ 启动 `piao-evolution-scan.sh` MVP 实施（本快照 §4.1 为唯一契约依据 · Phase 2 · 预计 1-2 工作日 · ~200 行 · 对标 M5 `piao-drift-compute.sh` MVP 节奏）
- **签收人**：`m6-review-2026-04-19`
- **签收时间**：2026-04-19 21:34
- **签收依据**：对标 `m6_evolution_kernel_alignment @v1 §9` 六项 self-review 范式 + M5 final-decisions 隐性签收范式

---

**快照状态**：**published**（2026-04-19 21:34 · M6 review 终点的冻结照片 · 一经产出不再修改 · 如需推翻走 `m6_final_decisions@v2`）

**上游**：
- `urn:piao:snapshot:kernel:m5_final_decisions@v1`（M5 基线 · 决议 1–6 矩阵 + §4 M6 入口检查清单 + drift → evolution 接口锁定点）
- `urn:piao:spec:architecture:evolution_model@v1.1 (draft)`（06 阶段 β 主产出 · 本快照 published 后作为升 @v1.1 published 的发布证书）
- `urn:piao:spec:architecture:drift_propagation@v1.1 (published)`（M5 封版本体 · §6 双通道 + C1–C4 前置契约）
- `urn:piao:spec:architecture:version_snapshot@v1.2 (published)`（M4 封版本体 · §3.2.3 canonical YAML 通用工具）
- `urn:piao:spec:architecture:artifact_model@v1.4 (published)`（M2 封版本体 · B2 @v1.3 → @v1.4 evolution.scan_result 派生注册条目已落地）
- `urn:piao:spec:architecture:layered_architecture@v1 (draft)`（M3 事件分层规格 · §3.1 B1 evolution.scanned 语义字段已原地精化 · §3.3.1 R22 N 条同 txn · drift/evolution 事件 L1 类型依赖）
- `urn:piao:artifact:kernel:m6_evolution_draft_review@v1 (published)`（阶段 β 工作流 E 退出门 · §5 路径 A/B 消化记录完整）
- `urn:piao:artifact:kernel:m5_toolchain_extension_review@v1 (published)`（阶段 α 退出门 · TB'1–TB'5 驱动 R1–R5 成形 · M6 复用 M5 产出）
- `urn:piao:proposal:kernel:m6_evolution_kernel_alignment@v1 (published · implemented)`（路径 B proposal · B1–B2 打包处置 · S0–S6 七步全 DoD · 10/10 勾选）
- `urn:piao:proposal:kernel:m6_evolution_kickoff@v1 (published → superseded by 本快照)`（M6 工作编排）

**下游锚点**：
- 本快照是任何引用 "M6 review 决议" / "evolution 模型最终形态" / "drift → evolution 接口终态" 的文档的正式 URN 目标
- `M1-debt-ledger @v7`（待产出）· 将 Q21–Q26 + A1–A4 / B1–B2 对齐到本快照
- `m6_evolution_kickoff @v1` 将标 `superseded_by: urn:piao:snapshot:kernel:m6_final_decisions@v1`
- `scripts/piao-evolution-scan.sh` MVP（待起稿）· 将以本快照 §4.1 为唯一契约基线实施
- `06-evolution-model.md @v1.1 draft → @v1.1 published`（待 MVP 反证后升版）将以本快照为升版"发布证书"
- M7 Extensibility milestone 收尾决策点（待 06 published 后启动 · 对标三代 kickoff 接力链第四代候选）
- v0.1 milestone 收官（kernel 七大模型全部 published · 产出 `v0_1_final_decisions@v1`）将以本快照 + M1–M5 六份 final-decisions 为六大前置快照
