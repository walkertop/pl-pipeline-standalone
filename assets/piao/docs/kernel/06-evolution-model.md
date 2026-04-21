---
urn: urn:piao:spec:architecture:evolution_model@v1.1
kind: spec
rev: v1.1
status: published
supersedes: null
produced_by: m6-evolution-kickoff-stage-beta-2026-04-19
produced_at: 2026-04-19T18:20:00+08:00
last_modified_at: 2026-04-19T22:40:00+08:00
upstream:
  - urn:piao:proposal:kernel:m6_evolution_kickoff@v1
  - urn:piao:artifact:kernel:m5_toolchain_extension_review@v1
  - urn:piao:snapshot:kernel:m5_final_decisions@v1
  - urn:piao:spec:architecture:drift_propagation@v1.1
  - urn:piao:spec:architecture:version_snapshot@v1.2
  - urn:piao:spec:architecture:artifact_model@v1.4
  - urn:piao:spec:architecture:layered_architecture@v1
  - urn:piao:spec:architecture:identity_model@v1.2
  - urn:piao:proposal:kernel:m6_evolution_kernel_alignment@v1
  - urn:piao:snapshot:kernel:m6_final_decisions@v1
  - urn:piao:artifact:kernel:m6_mvp_smoke_report@v1
wordcheck_exempt: true
---

# kernel · 06 Evolution Model（M6 · @v1.1 published · MVP 反证收官 · R1–R5 全锁定 + 路径 A 三处 MVP 实装范围补注）

> **@v1.1 published 定稿说明**（2026-04-19 22:40）
>
> 本篇由 `m6_evolution_kickoff@v1 §2.3` 阶段 β-2 触发，经 M6 milestone review 周期（@v0.1 骨架 → @v0.2 三节硬核 → @v1 draft 首版 → @v1 draft 路径 A 消化 → @v1.1 draft 路径 B 跟随升版 → **@v1.1 published 定稿**）后封为 published。**本次升 published 由 §8.2 门控 #4 工具链反证达成驱动**——`scripts/piao-evolution-scan.sh @v0.1` MVP 首版产出（~430 行 · 对标 M5 `piao-drift-compute.sh` 节奏）· SMOKE 1–4 四场景冒烟全通（基本通路 / 幂等性 / 跨 scope 拒绝 / 原子回滚）· R1–R5 五硬约束在 MVP 实施中**未被触发反例**（证据详见 `_review/m6-mvp-smoke-report.md @v1 §3 反证矩阵`）。
>
> **升版全路径**：`@v0.1 骨架`（占位 · 18:20）→ `@v0.2 三节硬核`（§2/§3/§6 · 18:40 · commit `74820f3c`）→ `@v1 draft 首版`（§4/§5/§7 展开 · R1–R5 全锁定 · 19:10）→ `@v1 draft 路径 A 消化`（A1-A4 字面约束补齐 · 不升 rev · 19:54）→ `@v1.1 draft 路径 B 跟随升版`（20:50 · 外篇 02 @v1.4 + 03 @v1 对接完成）→ `@v1.1 draft MVP 实装范围补注`（22:30 · 路径 A 小补注三处 · 不升 rev · 依据 `m6-mvp-smoke-report @v1 §4`）→ **`@v1.1 published`（定稿 · 22:40 · MVP 反证达成）**。@v0.1/@v0.2 阶段的骨架被无缝替换（骨架本身是 draft · 不是 published 快照 · 无 supersedes 关系）· v1 → v1.1 内部小升同样无 supersedes（按 `01 §10.1` draft 契约）· `@v1.1 draft → @v1.1 published` 无 supersedes（同 rev 内部状态转换 · 不升 rev）· 对标 M5 `05 @v1.1 draft → @v1.1 published` 同构范式。
>
> **升 published 四门控达成证据**（见 §8.2 完整复核表）：
> - **门控 #1 · R1–R5 五问硬约束锁定**：✅ @v0.2 锁定 R1/R2/R5 + @v1 锁定 R3/R4（`§0.1` 5/5 标"✅ 锁定"）
> - **门控 #2 · TB' 映射矩阵完整**：✅ R1→TB'5 · R2→TB'1 · R3→TB'4 · R4→TB'2 · R5→TB'3 全覆盖（§11 末尾矩阵）
> - **门控 #3 · 生命周期锚点闭环**：✅ 六处锚点闭环声明（§2.5/§3.6/§4.6/§5.6/§6.7/§7.6）· 外篇对接完成（02 @v1.4 published + 03 @v1 draft 原地精化）
> - **门控 #4 · 工具链 MVP 反证**：✅ 2026-04-19 22:30 **新达成**（`scripts/piao-evolution-scan.sh @v0.1` 首版 · 对标 M5 `piao-drift-compute.sh` 节奏 · SMOKE 1–4 冒烟全通 · R1–R5 反证矩阵见 `_review/m6-mvp-smoke-report @v1 §3`）
>
> **本 rev MVP 实装范围锁定**（对齐 `m6_final_decisions@v1 §1` 决议 4-A / 5-A 硬约束 · 2026-04-19 22:30 路径 A 三处原地精化补注 · 不升 rev）：
> - `§2.3` decision 枚举 + decisions[] schema：MVP @v0.1 仅实装 `pass_through` 单态 · `decisions[]` 恒为空数组（R4 4-A 纯观测）· `pull_detail` / `dispatch` schema 保留仅作 future-proof
> - `§5.1` 产出模式矩阵：MVP @v0.1 仅实装 **M1 · 纯观测** · M2/M3 schema 保留 · 未实装（5-A 终止于 scan_result · 本 rev 工具链无下游事件发射代码路径）
> - `§6.2` L1 决策三态：MVP @v0.1 仅实装 `pass_through` · `pull_detail` / `dispatch` 为 schema 预留
>
> 上述三处补注已就地以 blockquote / 注释块形态落位于 §2.3 / §5.1 / §6.2 原段下方 · 字面引用 `m6_final_decisions@v1 §1 决议 4-A + 5-A` 作为锚点 · 不删改 draft 原有枚举与语义 · 符合 `01 §10.1` draft 原地修订契约。未来 kickoff 决议若放开 4-A / 5-A · 扩实装 M2/M3 仅需工具链补代码路径 · 本篇 schema 无需升 rev（ABI 稳定）。

> **@v1 draft 首版说明**（2026-04-19 19:10 · 保留作为 rev_history 承接段 · 当前段已由 @v1.1 published 定稿说明承接）
>
> 本 rev 在 `@v0.2 三节硬核正文`（commit `74820f3c` 已固化 · R1/R2/R5 锁定）基础上，**一次性展开 §4/§5/§7 三节**，完成首版 draft 全貌：
> - **§4 Q6.3 scope**：R3 锁定（三层 scope 一致性链 `snapshot → drift → evolution` · 批聚合模式 A/B 允许 · C/D/E 拒绝 · 拒绝列表五条 · 客观性守恒）· 依据 TB'4 + `05 §4.1/§4.2` + `04 §3.3/§5.3`
> - **§5 Q6.4 决策产物**：R4 锁定（**混合模型候选 C** · 观测基础层恒定 + 决策扩展层按需 · `--orphan-check` 副作用开关 · 决策事件枚举 + 禁止产出事件 · G1-G5 产出禁止项）· 依据 TB'2 + `m5-toolchain-extension-review §2 T'1` 长期建议
> - **§7 生命周期**：R1 双形态驱动的**双轨生命周期**锁定（轨 A artifact 两态 `draft → published → retracted` · 轨 B L1 事件 append-only · 体积预算六项 + 通胀控制 H1-H4 + 与 drift/snapshot 级联比表）· 依据 `05 §7.1/§7.2/§7.3/§7.4` + `04 §6.1/§6.2/§7.1` + `02 §6` + `03 §3.3`
> - **§8.2 门控复核**：四条 `[ ]` → `[x]` 全达成 · 附 commit / 锚点 / TB' 引用 / 锚点闭环声明证据
>
> **@v1 证据层闭合结论**：TB'1/TB'2/TB'3/TB'4/TB'5 五条工具链视角强约束 + `05 §6/§7` + `04 §3.3/§5.3/§6/§7` + `02 §6` + `03 §3.3` 共同支撑 R1–R5 五硬约束**全部锁定** · 六处锚点闭环声明（§2.5 / §3.6 / §4.6 / §5.6 / §6.7 / §7.6）· 共 42+ 处 TB' 引用 · 无遗漏锚点 · 无硬约束间已知冲突。
>
> **@v0.2 → @v1 变更摘要**：
> 1. §4 R3 scope 继承正文起稿（约 80 行 · 六子节 4.1–4.6 · 从"占位"升为"硬约束"）
> 2. §5 R4 决策产物正文起稿（约 110 行 · 六子节 5.1–5.6 · 从"占位"升为"硬约束"）
> 3. §7 双轨生命周期正文起稿（约 75 行 · 六子节 7.1–7.6 · 从"占位"升为"硬约束"）
> 4. §0.1 设计取舍表 R3/R4 标记从"占位"改为"已锁定"（R1/R2/R5 沿用 @v0.2 锁定）
> 5. §1 必答问题清单 Q6.3/Q6.4 答复摘要从"待展开"改为实际一句话摘要
> 6. §8.1 rev_history 新增 v1 行（触发来源 / 变更摘要 / 达成证据）
> 7. §8.2 四条门控 `[ ]` → `[x]` 并附达成证据
> 8. §11 本篇状态行从"@v0.2 三节硬核正文已起稿"改为"@v1 draft · R1–R5 全锁定"· 下游锚点补齐 `02 @v1.4 draft` + `03 @v1 draft → @v1.1` 依赖
> 9. front-matter `urn` / `rev` 从 `v0.2` 升至 `v1` · `last_modified_at` 刷新至 19:10
>
> **阅读路径**（不变）：
> 1. 先读 `m6_evolution_kickoff@v1 §2 + §4`
> 2. 再读 `_review/m5-toolchain-extension-review.md @v1 §3`
> 3. 再读 `05-drift-propagation.md @v1.1 §6`
> 4. 再读 `05 §2/§3/§5`
> 5. 最后读本篇 §0–§11

---

## 0. 定位

M1（身份）回答"实体叫什么"，M2（artifact）回答"实体长什么样"，M3（事件分层）回答"实体之间怎么流动"，M4（snapshot）回答"怎么把流动封冻成 O(N) 可对比的照片"，M5（drift）回答"两张照片之间的差如何被解释、归因、传播"。

**M6 回答：被归因解释后的差分，如何被扫描、决策、转化为系统下一步动作。**

evolution 不是"drift 的高级消费"——`05 §6 drift → evolution 接口`已经给出双通道 + C1–C4 前置契约（**通道 A** 事件流 O(1) 快速决策 / **通道 B** artifact 拉取 O(N) 详情归因）。evolution 是**在接口之上**的**决策层**：

- **扫描**：`drift.detected` 事件流进来，哪些需要 evolution 引擎介入？哪些直接忽略？
- **决策**：被介入的 drift，应该产出什么下游动作？（新 `task.*` 建议？新 `proposal`？纯观测？）
- **收敛**：evolution 产出的决策喂给谁？（M3 taskdag？人工 review？或触发再一次 snapshot？）

### 0.1 设计取舍总览（@v1 · R1/R2/R3/R4/R5 全部锁定）

| # | 设计决策 | 来源 | 对应 Q6.x | 状态 |
|---|---------|------|---------|------|
| **R1** | evolution 的身份**双形态并存**：artifact 形态（`kind=artifact` + `artifact_type=evolution.scan_result`）+ L1 事件形态（`evolution.scanned`）· 同 txn 原子写入 · 对标 drift 范式 | `05 §2` drift 双形态同构反证 + TB'5（`01 §2.2` `evolution_source` 作输入源 kind 定稿 · 不参与产出决议） | Q6.1 | ✅ @v0.2 锁定（见 §2） |
| **R2** | evolution 扫描器的**唯一触发器**是 `drift.detected` L1 事件（通道 A 事件流 · 不订阅 `artifact.published` / `snapshot.published` / 时间驱动） | `_review/m5-toolchain-extension-review@v1 §3.1 TB'1` · 三层订阅链同构 `snapshot.published→drift / drift.detected→evolution` | Q6.2 | ✅ @v0.2 锁定（见 §3） |
| **R3** | evolution artifact 的 scope **完全继承**被扫 drift 的 `scope_kind + scope_ref` · 三层 scope 一致性链（snapshot → drift → evolution）· 禁止跨 scope 聚合 · 允许同 scope 批聚合 | `_review/m5-toolchain-extension-review@v1 §3.4 TB'4` + `05 §4.1/§4.2` + `04 §3.3/§5.3` | Q6.3 | ✅ @v1 锁定（见 §4） |
| **R4** | evolution 的决策产物为**观测 + 可选决策混合模型**（候选 C）· 观测基础层恒定产出 + 决策扩展层按需产出 · `--orphan-check` 副作用开关（默认关闭）· 下游事件仅 `task.proposed` / `proposal.generated` · 禁止直写 taskdag | `_review/m5-toolchain-extension-review@v1 §3.2 TB'2` + `m5-toolchain-extension-review §2 T'1` 长期建议 | Q6.4 | ✅ @v1 锁定（见 §5） |
| **R5** | evolution 消费 drift 的接口契约：**双层消费模型**（L1 读 3 字段 O(1) + L2 读 11+ 字段 O(N) · 四条禁止项 F1-F4 · C1-C4 前置契约全继承 · 下游事件类型仅限 `task.proposed` / `proposal.generated` / `observation_only`） | `_review/m5-toolchain-extension-review@v1 §3.3 TB'3` + `05 §6.1/6.2/6.3` + `m5_final_decisions §1 决议 5` | Q6.5 | ✅ @v0.2 锁定（见 §6） |

> **@v1 证据层闭合结论**：TB'1/TB'2/TB'3/TB'4/TB'5 五条工具链视角强约束 + `05 §6` + `04 §3.3/§5.3` + `02 §6` + `03 §3.3` 共同支撑 R1–R5 五条硬约束**全部锁定** · 证据链完整 · 无遗漏锚点。

---

## 1. M6 必答问题清单（对标 kickoff §4）

| # | 问题 | 本篇答复章节 | 工具链视角强约束（来自 `m5-toolchain-extension-review@v1 §3`） | 答复摘要 |
|---|------|-----------|--------------------------------------------------------------|---------|
| **Q6.1** | evolution 的身份（是否 artifact？artifact_type 怎么写？是否复用 `evolution_source` kind？） | §2 ✅ | TB'5 · `evolution_source` 已在 `01 §2.2` 定稿（作输入源 kind · 不参与产出决议） | **双形态并存** · artifact(`kind=artifact` + `artifact_type=evolution.scan_result`) + L1 事件(`evolution.scanned`) · 同 txn 原子写入 · 对标 drift 范式 |
| **Q6.2** | evolution 的触发（何时运行？事件流 vs 周期 vs 手动？） | §3 ✅ | TB'1 · **唯一触发器 = `drift.detected` L1 事件**（通道 A）· 不订阅 `artifact.published` | **唯一触发器 `drift.detected`** · E1–E5 原子流程 · 禁止时间驱动/越级订阅 · 客观性承诺 + 降级策略完备 |
| **Q6.3** | evolution 的 scope（扫描范围如何选？单条 / 批 / 跨 scope？） | §4 ✅ | TB'4 · **继承** drift 的 `scope_kind + scope_ref`（三层一致性链） | **scope 完全继承** drift · 三层一致性链（snapshot → drift → evolution）· 允许同 scope 批聚合（模式 A/B）· 拒绝跨 scope（模式 C/D/E 五条）|
| **Q6.4** | evolution 的决策产物（纯观测 / 决策 / 混合三选一） | §5 ✅ | TB'2 · 扫描器可兼任孤儿检测（副作用开关 `--orphan-check`） | **混合模型（候选 C）** · 观测基础层恒定 + 决策扩展层按需 · `--orphan-check` 默认关闭 · 下游仅 `task.proposed` / `proposal.generated` · 禁止直写 taskdag |
| **Q6.5** | evolution → next 接口（O(1) 决策层的 schema · 喂给谁） | §6 ✅ | TB'3 · **3 字段优先 + 11 字段兜底**双层 · 禁止绕过事件流直读 artifact | **双层消费模型** · L1 O(1) 读 3 字段 + L2 O(N) 读 11+ 字段 · F1-F4 四禁止项 · C1-C4 前置契约全继承 · 下游仅 `task.proposed`/`proposal.generated`/`observation_only` |

---

## 2. evolution 的身份与 artifact 形态（回答 Q6.1）

### 2.1 核心决议 · 双形态并存

**硬约束 R1**：evolution 的一次扫描运行同时产出**两形态**：

1. **artifact 形态**：`urn:piao:artifact:<scope>:evolution/<name>@<rev>` · `artifact_type = evolution.scan_result` · 承载本次扫描的完整决策数据（被扫 drift 清单 · 快速决策结果 · 详情拉取记录 · 产出的下游事件引用）
2. **L1 事件形态**：`evolution.scanned` · 承载扫描的元信息（何时扫 · 谁扫 · 扫了几条 drift · 做了什么决策）· 作为下游 O(1) 消费入口

**双形态同 txn 原子写入**（`03 §3.3.1 N 条同 txn` 的 N=2 合法子集 · 与 drift 的 `artifact.published + drift.detected` 范式同构）。

### 2.2 为什么必须双形态 · 范式同构反证

对标 `05 §2 drift artifact` 的双形态决议——drift 选择双形态的理由在 evolution 侧**完全复现**：

| 理由（drift 侧 `05 §2.2`） | evolution 侧对应 | 反证强度 |
|-----------------------|------------|-------|
| 决策数据体积可能超事件流预算（> 5 KB） | evolution 单次扫描可能涉及 N 条 drift 的决策记录 · 同样 > 5 KB | ✅ 同构 |
| 需要 artifact URN 作为 provenance 锚点被下游 task/proposal 引用 | evolution 产出的 `task.proposed` / `proposal.generated` 需要 `produced_by.artifact_urn` 回指到扫描产物 | ✅ 同构 |
| 需要 L1 事件做 O(1) 扫描（"有没有新 drift"） | 更上游的决策器（如 M3 taskdag 调度器）需要 O(1) 判定"有没有新 evolution 决策待消费" | ✅ 同构 |
| artifact 生命周期（draft/published/retracted）独立于事件流 append-only | 同理 · evolution artifact 可被 retracted（数据损坏场景）而事件流仍 append-only | ✅ 同构 |

**结论**：drift 范式（`05`）已 published 证实该设计健壮 · evolution 直接继承。

### 2.3 身份 schema

**artifact 形态**（`artifact_type = evolution.scan_result`）：

```yaml
# front-matter
urn: urn:piao:artifact:<scope>:evolution/<name>@<rev>
kind: artifact                          # 01 §2.1 核心 kind · 不新增 kind
artifact_type: evolution.scan_result    # 02 §2.2 派生类型注册（@v1 draft 需同步补登 02 注册表）
rev: v<N>
status: draft | published | retracted   # 02 §6 三态生命周期（不含 superseded · 对齐 05 §7.1 drift 范式）
produced_by:
  task_urn: urn:piao:task:<scope>:evolution_scan
  event_id: evolution-scanned-<YYMMDDHHmmss>-<rand6>
wordcheck_policy: exempt                # 02 §2.2.4 · 机器产物自动 exempt（对齐 05 drift）

# body
scan_base:                              # 扫描输入锚点
  event_journal_range:                  # 本次扫描消费的事件流窗口
    from_event_id: ...
    to_event_id: ...
  scope_kind: unit|proposal|stage|snapshot|artifact
  scope_ref: <字面值 · 继承被扫 drift 的 scope · 见 §4>
scanned_drifts:                         # 被扫描的 drift 事件清单
  # 字段必填性说明（[A2 · Q24 回应]）：
  #   - drift_urn           : 必填 · drift 身份锚点（`05 §2.3`）
  #   - decision            : 必填 · 本次扫描对该 drift 的决策三态（见 §6）
  #   - drift_event_id      : 必填 · `drift.detected` 事件 id（与 drift_urn 绑定 · `05 §6.2` L1 必填字段）
  #   - driver_event_id     : 条件必填 · 当 drift 为 `attribution_mode=detailed` 时必填（承继 `05 §5.3` 归因三元组的 driver 维度）
  #                           · 当 drift 为 `attribution_mode=sha_only` 时为 null（`05 §2.3` 已声明此时无 driver 归因）
  - drift_event_id: drift-detected-...
    drift_urn: urn:piao:drift:...
    decision: pass_through | pull_detail | dispatch  # 快速决策层三态（见 §6）
    driver_event_id: <event_id 或 null>              # 条件必填 · 见上方字段必填性说明
decisions:                              # 产出的下游动作（若有）
  - decision_type: task_proposed | proposal_generated | observation_only
    event_id: ...
    target_urn: ...
# [MVP @v0.1 实装范围补注 · 来自 m6-mvp-smoke-report @v1 §4.1 · 2026-04-19 22:30]
# 依据 `m6_final_decisions@v1 §1 决议 4-A (纯观测) + 5-A (终止于 scan_result)`：
#   · `scanned_drifts[].decision` 在 MVP @v0.1 范围内恒为 `pass_through` 单态
#     —— `pull_detail` / `dispatch` 为 schema 预留扩展点（M7+ 若开启 B/C 候选产物模式再启用 · 本 rev 未实装）
#   · `decisions[]` 数组在 4-A+5-A 组合下恒为 `[]` 空数组（由 MVP 实施侧硬编码保证）
#     —— schema 保留字段定义仅用于 future-proof（兼容 §5.1 M2/M3 未来开放时的 ABI 稳定）
#   · 实施侧反证已在 `_review/m6-mvp-smoke-report @v1 §3 反证矩阵` + SMOKE 1-2 两条真实 artifact 中登记
orphan_check:                           # 副作用开关产物（TB'2 · §5.2 锁定）
  enabled: false | true
  orphans: []                           # 仅 enabled=true 时填充
```

**L1 事件形态**（`evolution.scanned`）：

| 字段 | 类型 | 语义 | 必填 |
|------|------|-----|------|
| `event_id` | `evolution-scanned-<YYMMDDHHmmss>-<rand6>` | `01 §5` 事件 id 规约 · 前缀与 drift（`drift-detected-*`）、snapshot（`snap-published-*`）分离 | ✅ |
| `event_type` | `evolution.scanned` | `03 §3.1` L1 枚举新增（属 kernel 升版 · 见 §8.2 门控） | ✅ |
| `event_layer` | `L1` | `03 §3.2` 通用骨架 | ✅ |
| `emitted_at` | ISO8601 UTC | `03 §4.1`（T'3 修复后的 UTC 统一口径） | ✅ |
| `emitted_by` | actor URN | `03 §3.2` | ✅ |
| `subject` | evolution artifact URN | `03 §3.1` 双轨原则 · 事件主语 = artifact 本身 | ✅ |
| `evidence` | `{event_journal_range, scanned_drift_count, decision_count}` | `03 §3.1` 语义字段 · O(1) 消费的最小 "how" 信息 | ✅ |
| `scope_kind` + `scope_ref` | 字面值 | 继承 scanned_drifts 共同 scope（见 §4） | ✅ |

### 2.4 关键边界锁定

| # | 边界 | 约束 | 上游锚点 |
|---|------|-----|--------|
| B1 | **不新增核心 kind** | evolution artifact 复用 `kind=artifact` + `artifact_type=evolution.scan_result` · `01 §2.1` 无需升版 | `01 §2.1` 核心 kind 枚举 / TB'5 |
| B2 | **新增 L1 事件类型需升 03** | `evolution.scanned` 纳入 `03 §3.1` L1 十类事件（升为十一类）· 属 kernel 升版 · 见 §8.2 门控 #4 · **已对接**（`03 @v1 draft` 原地精化 · 2026-04-19 20:30 · commit `76bbfff5` · 由 `m6_evolution_kernel_alignment@v1 S1 B1` 驱动 · subject + 语义字段按 `06 §2.3 / §5.3` 实锁 schema refresh · 03 整体 10 类枚举不变 · draft 内原地修订不升 rev） | `03 §3.1` + `m6_evolution_kickoff §4` Q6.1 |
| B3 | **artifact_type 注册走 02 派生类型表** | `evolution.scan_result` 在 `02 §2.2.4` 派生类型注册表补一行 · 含 `wordcheck_policy: machine_generated` 字段 · **已对接**（`02 @v1.3 → @v1.4 published` · 2026-04-19 20:45 · commit `7a7bce04` · 由 `m6_evolution_kernel_alignment@v1 S2 B2` 驱动 · 七字段齐全 · 对齐 `drift.propagation_record` 模式 · 承诺段沿用 v1.3 已入册七字段 schema 字面不动） | `02 §2.2.4`（@v1.4 已补登该条目 · 2026-04-19 20:45 published） |
| B4 | **`evolution_source` 不参与本决议** | `01 §2.2` 扩展 kind `evolution_source` 语义是"演化**输入源**"（如 error_log 条目），**与 evolution scan 产出无关**——TB'5 原文"定稿"指 kind 枚举已含该项，不论证产出形态 | `01 §2.2` line 87 + TB'5 精确解读 |
| B5 | **生命周期两态** | artifact 形态走 `draft → published → retracted` · 不引入 superseded（对齐 `05 §7.1` drift 范式 · 理由：扫描结果是客观产物 · 升 rev = 扫描算法升版而非单次扫描升版） | `05 §7.1` + `02 §6` |

### 2.5 锚点闭环声明（@v1 draft 门控 #4）

- `01 §2.1` 核心 kind `artifact` · 本节 §2.3 front-matter `kind: artifact` 复用 · ✅ 无升版依赖
- `02 §2.2.4` 派生类型注册表 · 本节 §2.4 B3 要求补登 `evolution.scan_result` · ✅ **已对接**（`02 @v1.4 published` · 2026-04-19 20:45 · 由 `m6_evolution_kernel_alignment@v1 S2` 驱动）
- `03 §3.1` L1 事件枚举 · 本节 §2.4 B2 要求扩容至十一类 · ✅ **已对接**（`03 @v1 draft` 原地精化 · 2026-04-19 20:30 · 由 `m6_evolution_kernel_alignment@v1 S1` 驱动 · 10 类总数不变 · 仅 `evolution.scanned` 行 subject + 语义字段按实锁 schema refresh）
- `05 §2` drift 双形态范式 · 本节 §2.2 反证表直接继承 · ✅ 无升版依赖

---

## 3. evolution 的触发与产出契约（回答 Q6.2）

### 3.1 核心决议 · 唯一触发器

**硬约束 R2**：evolution 扫描器的**唯一触发器**是 `drift.detected` L1 事件（通道 A）· **禁止**订阅以下任何来源：

- ❌ `artifact.published`（违反事件订阅链层级 · 见 §3.5 反证）
- ❌ `snapshot.published`（drift 引擎自身的触发源 · evolution 订阅它等于跨层越级）
- ❌ 时间驱动（如 cron · 违反 `04 §2.4` 客观性原则 · 见 §3.4）
- ❌ 手动触发为唯一入口（可作为**运维补救**模式但**不是契约触发器** · 见 §3.4 降级策略）

**订阅链精确表述**（三层事件订阅一致性）：

```
snapshot.published ──▶ drift 引擎  ──▶  drift.detected ──▶ evolution 引擎
                                                          │
                                                          └──▶ evolution.scanned
```

这与 `m4-toolchain-review §3 TB2` 的"drift 订阅 `snapshot.published` 而非 `artifact.published`"范式**同构** · 是 kernel 层该范式的**第三次复用**（snapshot→drift→evolution 三级订阅链）。

### 3.2 原子流程 E1–E5

对标 `05 §3.2 T1–T5` 的 drift 原子流程范式，evolution 扫描一次运行产出 **E1–E5 五步原子序**：

| 步 | 动作 | 输入 | 输出 | 原子性依据 |
|----|------|-----|------|----------|
| **E1** | 订阅 `drift.detected` 事件（单条或批） | event-journal 窗口 | 本次扫描要处理的 drift 事件清单 | 读 event-journal · 只读操作 · 无原子性要求 |
| **E2** | 对每条 drift 读 5 字段（`subject` + `counts` + `attribution_mode` + `evidence.{old/new}_snapshot_urn`） | E1 清单 | 通道 A 快速决策结果（`pass_through` / `pull_detail` / `dispatch`） | O(1) 事件读 · 见 §6.2 |
| **E3** | 仅对 `decision=pull_detail` 的 drift 拉取 artifact body | E2 决策结果 + drift artifact 目录 | `attribution[]` 11+ 字段展开结果 | O(N) · N = pull_detail 条目数 · 见 §6.3 |
| **E4** | 根据 E2/E3 结果产出下游动作（`task.proposed` / `proposal.generated` / 仅观测） | E2 + E3 汇总 | 下游事件数组（可为空） | 见 §5 决策产物形态 |
| **E5** | 原子写入 evolution artifact + `evolution.scanned` 事件 +（可选）E4 下游事件 | E1–E4 全量产出 | `N=1+1+k` 条 L1 事件 + 1 条 artifact 同 txn | `03 §3.3.1` N 条同 txn（k = E4 下游事件数量） |

**E5 原子性精确表述**：

```
txn_begin
  ├── write evolution.scan_result artifact (draft)
  ├── append artifact.published event
  ├── append evolution.scanned event
  ├── append task.proposed × m 事件（若 E4 产出）
  └── append proposal.generated × n 事件（若 E4 产出）
txn_commit          # 全 OK · artifact 状态 draft → published
txn_rollback_on_any_failure  # 对齐 05 MVP 实装的 rollback_txn · 见 T'4 补注
```

**N = 2 + k** 边界（k ≥ 0）· 该 N 值在 `03 §3.3.1` 承诺 1 的 "N 条同 txn · 由扩展工具链承诺 N ≥ 2" 中合法。

### 3.3 客观性承诺

对齐 `04 §2.4 触发判定客观性` + `05 §3.4 drift 客观性`：

- 给定同一 event-journal 状态 + 同一 drift artifact 目录 + 同一 evolution 扫描算法 rev，evolution 必产出**字节级相同**的 scan_result artifact + 相同的 `evolution.scanned` 事件字段（除 `event_id` 随机段与 `emitted_at` 时间戳外）
- **核心排除**：不得以"当前时刻"/"运行者身份"/"环境变量"作为决策输入——这些都是非客观因素
- 副作用开关 `--orphan-check`（§5.2）打开时，orphan 清单的客观性要求相同（给定同一目录状态产出相同 orphan 列表）

### 3.4 降级策略

evolution 扫描器失败场景的行为锁定：

| 场景 | 行为 | 契约依据 |
|------|-----|--------|
| E1 读 event-journal 失败 | 整个扫描退出码非零 · **不回滚 drift** · drift 仍 published（drift 是 evolution 的上游事实 · 与 evolution 成功与否无关） | drift `05 §3.3` 已 append-only · 无回滚通道 |
| E3 拉 drift artifact 失败（文件丢失 / 签名不匹配） | 本次扫描对该条 drift 的 decision 降级为 `dispatch` 失败记录 · 写入 `scanned_drifts[].decision_failure_reason` · 其他 drift 正常处理 | `05 §2` drift artifact 生命周期 · retracted 场景兜底 |
| E5 原子写入失败 | 完整 rollback（全部 N 条事件 + artifact 删除）· exit 非零 | `03 §3.3.1` 承诺 1（rollback_txn 实装）· `m5-toolchain-extension-review §2 T'4` 多进程并发补注已覆盖此场景 |
| 手动补救（扫描器长期未运行 · 事件流积压） | 手动运行 `piao-evolution-scan.sh --catch-up <from_event_id>` · 本质仍是 E1–E5 原子序 · 只是 E1 窗口变大 | §3.1 "手动不是契约触发器"但可作运维入口 |

**禁止**：evolution 不得因自身失败反向修改 drift artifact 状态（违反 `05 §6.3 C1 不得反向写`）· 不得尝试"重新触发 drift 计算"（违反 §3.1 订阅链层级）。

### 3.5 反证：为什么不能订阅 `artifact.published`

**反证逻辑**：

1. `artifact.published` 每个 artifact 产出都会发（包括 rule/skill/proposal/snapshot/drift 等）· evolution 只关心 drift 子集
2. 若 evolution 订阅 `artifact.published`，每条事件都需要过滤 `artifact_type == "drift.propagation_record"` · **把过滤责任推给消费方**
3. `drift.detected` 是 drift 引擎已经为 evolution 准备好的"精选事件流" · 含完整 5 字段供 O(1) 决策（TB'1 实测证实）
4. 若绕过 `drift.detected` 直接订阅 `artifact.published`，会丢失 `counts` / `attribution_mode` 两个字段（这些是 drift 引擎在 E2 计算完归因后才知道的值），**强迫 evolution 拉 artifact 获取** · O(1) 决策退化为 O(N) 拉取

**结论**：TB'1 锁定的"evolution 只订阅 `drift.detected`"**不是实施偏好** · 而是事件流分层契约的硬性推论（`03 §3.1` 双轨原则 + `05 §6.1` 双通道设计的必然推导）。

### 3.6 锚点闭环声明

- `05 §6.1` 双通道设计 · 通道 A 事件流是本节 R2 的直接依据 · ✅ 无升版依赖
- `05 §6.2` `drift.detected` 11 必填字段 · 本节 §3.2 E2 读 5 字段是该 11 字段的子集 · ✅ 无升版依赖
- `03 §3.1` L1 十类事件 · 本节 §3.2 E5 的 N ≥ 2 在 `03 §3.3.1` 承诺 1 合法 · ✅ 依赖 N 条 txn 契约
- `03 §3.3.1` N 条同 txn · 本节 §3.2 E5 为 `N=2+k` 合法子集（M5 MVP 已实装 rollback_txn 反证）· ✅ 无升版依赖
- `04 §2.4` 触发判定客观性 · 本节 §3.3 客观性承诺直接继承 · ✅ 无升版依赖
- `m5-toolchain-extension-review §2 T'4` 多进程并发补注 · 本节 §3.4 降级策略覆盖该场景 · ✅ 补注已登记

---

## 4. evolution 的 scope 语义（回答 Q6.3）

### 4.1 核心决议 · scope 继承硬约束

**硬约束 R3**：evolution artifact 的 `scope` 字段**完全继承**被扫 drift 的 `scope_kind + scope_ref` · **不引入 evolution 自身的 scope 维度**：

```
E.scope.scope_kind = D.scope.scope_kind  （= S_new.frozen_scope.scope_kind = S_old.frozen_scope.scope_kind）
E.scope.scope_ref  = D.scope.scope_ref   （= S_new.frozen_scope.scope_ref  = S_old.frozen_scope.scope_ref）
```

**依据**：`m5-toolchain-extension-review@v1 §3.4 TB'4` 原文——
> drift artifact 的 scope 完全继承两 snapshot 的 scope_kind + scope_ref（扩展实施沿用 M5 封板契约 · 未引入新 scope 维度）。
> `06 §X scope 定义` 直接规定"evolution 扫描器的 scope 继承 drift.detected 事件的 subject drift artifact 的 scope" · 不引入 evolution 自身的 scope 维度。

**URN 寻址效应**：`E.scope = D.scope = S.scope` 使 evolution artifact 在 `01 §3` URN 寻址层与其被扫 drift、底层 snapshot 同属一个 scope 命名空间——便于 `lineage_query` 的 scope 聚合查询（"给我这个 scope 下所有 evolution 决策"）· 范式同构 `05 §4.2` drift scope 继承 snapshot。

### 4.2 三层 scope 一致性链

| 层 | 契约 | 字段 | 锚点 |
|----|-----|------|-----|
| **L0** snapshot | `04 §5.3` 跨 scope_kind 的 snapshot diff 直接抛错 | `S.frozen_scope.{scope_kind, scope_ref}` | `04 §3.3/§5.3` @v1.2 published |
| **L1** drift | R3 硬约束：`S_old.scope == S_new.scope` · drift scope 继承两 snapshot | `D.scope.{scope_kind, scope_ref}` | `05 §4.1/§4.2` @v1.1 published |
| **L2** evolution | 本节 R3：`E.scope == D.scope`（被扫 drift 的 scope） | `E.scope.{scope_kind, scope_ref}` | 本节 · TB'4 锚点 |

**一致性闭环**：从 snapshot 产出到 evolution 决策，scope 字段在三层间**字面传递**无需重计算——这是 `04 §2.4` 客观性原则在 scope 维度的连续性保证（同 scope 下的决策路径在 scope_kind/scope_ref 层面完全可追溯）。

**反证**：若 evolution 引入独立的 `scope_kind` 维度（例：`evolution_decision`），则：
1. `01 §2.1` kind 枚举需升版新增 scope_kind（违反 TB'4 "未引入新 scope 维度"）
2. `lineage_query` 需额外支持 "evolution → drift → snapshot" 跨 scope_kind 查询（违反三层一致性）
3. `04 §5.3` 跨 scope_kind 抛错契约需放宽 · 污染 kernel 原子算子（违反 `05 §4.4` 变体拒绝理由）

### 4.3 批聚合策略决议

**决议**：evolution 的一次扫描运行**允许**聚合同 scope_kind + scope_ref 的多条 `drift.detected` 事件（称为"scope 内批聚合"），但**禁止**跨 scope 聚合（继承 M5 决议 3 对 drift 的禁止）。

| 聚合模式 | 是否允许 | 理由 |
|---------|--------|-----|
| **A · 逐条消化**（1 scan = 1 drift）| ✅ 允许 | 最简单实现 · 与 drift 1:1 对应 · 典型单元测试路径 |
| **B · 同 scope 批聚合**（1 scan = N drifts · 同 scope_kind + 同 scope_ref）| ✅ 允许 | 提高决策带宽 · 便于跨 drift 关联分析（例：同一 scope 下连续三次 drift 反映同一 task 的迭代轨迹）· E1 事件窗口自然包含多条 drift |
| **C · 跨 scope_kind 联合**（1 scan = N drifts · 跨 unit/proposal 等）| ❌ 拒绝 | 污染 kernel 原子算子 · 违反三层一致性链 · 应在应用层用两次单 scope evolution 聚合 |
| **D · 跨 scope_ref 同 scope_kind 聚合**（1 scan = N drifts · 同 unit kind · 跨 unit_A/unit_B）| ❌ 拒绝 | scope_ref 是 scope 的主键 · 跨 scope_ref 等价于跨 scope（TB'4 "scope = {scope_kind, scope_ref}" 二元组完整语义） |
| **E · 滚动窗口聚合**（按时间切片）| ❌ 拒绝 | 时间不是 scope 维度 · 违反 `04 §2.4` 客观性（evolution 必须由事件驱动不是时间驱动）· 对齐 `05 §4.4` |

**批聚合的 artifact 影响**：

- 若选模式 B：`scanned_drifts[]` 数组含多条 drift · 其 `scope_kind + scope_ref` **必须全部相同**（E5 原子写入前校验 · 不同则退出码非零）
- `E.scope` 取该批共同 scope（全部 drift 的公共 scope_kind + scope_ref）
- `event_journal_range` 取该批覆盖的最早 `from_event_id` 到最晚 `to_event_id`

**实施侧建议**（非 kernel 硬约束 · 给工具链参考）：
- MVP 阶段优先实现模式 A（`piao-evolution-scan.sh --single <drift_event_id>`）· 覆盖率 > 90% 场景
- 模式 B 作为 M7+ 扩展（`--batch` 窗口聚合）· 当前 M6 kernel 仅承诺 schema 兼容

### 4.4 scope 拒绝列表（对标 05 §4.4）

| # | 变体 | 拒绝理由 |
|---|-----|--------|
| 1 | **跨 scope 联合 evolution**（例：对比不同 unit 的 drift） | 污染 kernel 原子算子 · 违反三层一致性链 L2 层 · 应在应用层用两次单 scope evolution 聚合（直接继承 `05 §4.4` 跨 scope drift 的拒绝理由） |
| 2 | **滚动窗口 evolution**（例：对最近 N 条 drift 做聚合决策） | 违反 `04 §2.4` 客观性原则（evolution 必须由事件驱动不是时间驱动）· 对齐 `05 §4.4` 时间切片 drift 拒绝 |
| 3 | **evolution of evolution**（对两个 evolution artifact 做 evolution） | evolution 本身的 scope_kind 归属其输入 drift 的 scope_kind（不是新 scope_kind 类）· 无对偶递归语义 · 若未来需要，升 kernel rev 而非本篇 · 范式同构 `05 §4.4` drift of drift 拒绝 |
| 4 | **evolution 跨 snapshot 重计算**（跳过 drift 层直接扫两份 snapshot） | 违反 §3.1 R2 唯一触发器契约（`drift.detected` 是 evolution 的唯一入口）· 跳过 drift 等于 evolution 自己实现归因算法 · 与 `05` 单一真源冲突 |
| 5 | **evolution 跨 rev 聚合**（对同 scope 下多个 rev 的 drift 做 evolution）| scope 继承以 scope_kind + scope_ref 为键 · rev 不是 scope 维度 · rev 差异应在 drift 层通过 `drift_kind` 枚举承载（`05 §3.5`）而非 evolution 层跨 rev 聚合 |

### 4.5 边界情况与客观性守恒

**B1 · initial_snapshot drift 的 evolution 行为**：
- 当被扫 drift 的 `drift_kind = initial_snapshot`（首份 snapshot · 无 S_old · `05 §3.5`），evolution 仍正常扫描 · scope 继承该 drift 的 scope（= S_new.scope）
- 该场景下 `attribution[]` 通常为空 · L1 决策大概率 `pass_through`（无归因可消费）· 但 scope 继承规则不变

**B2 · no_change_drift 的 evolution 行为**：
- 当 `drift_kind = no_change_drift`（`counts.added + removed + sha_changed == 0` · `05 §3.5`），evolution 的 L1 决策默认 `pass_through`（§6.2 决策规则）
- scope 仍按 R3 继承（不因"无变化"而跳过 scope 写入 · scan_result artifact 仍记录该 drift 被扫描过）

**B3 · 客观性守恒**：
- 给定同一 drift artifact（字节不变）· evolution 的 scope 推导必产出**字面相同**的 `scope_kind + scope_ref`——不存在依赖运行时环境的 scope 解析（对齐 §3.3 客观性承诺）
- `scope_kind` 五枚举（`unit` / `proposal` / `stage` / `snapshot` / `artifact`）在 `04 §3.3` 已封板 · evolution 不新增枚举值

### 4.6 锚点闭环声明

- `04 §3.3` scope_kind 五类封板 · 本节 R3 scope_kind 继承底层 · ✅ 无升版依赖
- `04 §5.3` 跨 scope_kind 抛错 · 本节 §4.2 L0 层依据 · ✅ 无升版依赖
- `05 §4.1/§4.2` drift R3 + scope 继承 · 本节 §4.1 R3 直接继承（三层链 L1 层）· ✅ 无升版依赖
- `05 §4.4` drift 拒绝列表 · 本节 §4.4 范式同构扩展五条 · ✅ 无升版依赖
- `m5-toolchain-extension-review@v1 §3.4 TB'4` · 本节 §4.1 R3 字面引用 · ✅ 证据充分
- `01 §2.1` kind 枚举 · 本节 §4.2 反证（evolution 不新增 scope_kind）· ✅ 无升版依赖

---

## 5. evolution 的决策产物（回答 Q6.4）

### 5.1 核心决议 · 混合产物形态（C 候选）

**硬约束 R4**：evolution 的一次扫描**产出形态为"观测 + 可选决策"的混合模型**（kickoff §4 Q6.4 候选 C）——

1. **观测基础层**（**恒定产出** · 不可关闭）：每次扫描必产出 `evolution.scan_result` artifact + `evolution.scanned` L1 事件 · 记录"本次扫了哪些 drift · L1/L2 决策结果 · orphan_check 扫描结果（若开启）"
2. **决策扩展层**（**按需产出** · 由 §6.2 L1 决策三态 `pass_through` / `pull_detail` / `dispatch` + §6.3 L2 归因消费结果驱动）：
   - `task.proposed` L1 事件（当 L1 或 L2 决策为"需新 task 处理该 drift"）
   - `proposal.generated` L1 事件（极罕见 · 当 L2 归因揭示 kernel 契约需修订）
   - **observation_only**（非事件类型 · 仅 body 字段值 · 当决策为"仅观测不决策"）

**产出模式矩阵**：

| 模式 | 观测基础层 | 决策扩展层 | 典型场景 |
|------|----------|----------|--------|
| **M1 · 纯观测** | scan_result + scanned 事件 | 无下游事件 | 批 drift 全部 `pass_through`（典型：批量 no_change_drift 扫描）|
| **M2 · 纯决策** | scan_result + scanned 事件（含 decisions[] 数组） | k 条 task.proposed / proposal.generated | L1 `dispatch` 或 L2 归因后需新 task |
| **M3 · 混合** | scan_result + scanned 事件 + 混合 decisions[] | 部分 drift 产出下游 · 部分仅观测 | 典型真实批扫描场景（多条 drift · 部分需 dispatch · 部分仅 pass_through）|

**反例拒绝**：
- **A · 纯观测独占**（kickoff §4 Q6.4 候选 A）：拒绝 · 若 evolution 永远不产出下游 `task.proposed` / `proposal.generated`，则 drift → task 的决策链断裂 · 违反 `05 §6.3 C3` "M6 消化 drift 后若产生新的 task / proposal，必须通过 provenance 链关联"的隐含前提
- **B · 纯决策独占**（候选 B · 无观测基础）：拒绝 · 若 evolution 仅在有 `dispatch` 时产出 artifact，则"扫过但决定不行动"的 drift 在事件流中无痕迹 · 失去决策可审计性

> **[MVP @v0.1 实装范围补注 · 来自 m6-mvp-smoke-report @v1 §4.2 · 2026-04-19 22:30]**
>
> 本表 M1/M2/M3 为 `06 @v1.1 draft` 锁定的**产物模式 schema 全集**，依据 `m6_final_decisions@v1 §1 决议 4-A (纯观测) + 5-A (终止于 scan_result)` 锁定的 MVP 边界：
>
> - **M1 · 纯观测** —— ✅ **MVP @v0.1 实装**（`scripts/piao-evolution-scan.sh @v0.1` 唯一产物模式 · 所有 drift 恒 `pass_through` · `decisions[]` 恒空）
> - **M2 · 纯决策** —— ⏸ **schema 保留 · MVP 未实装**（5-A 终止于 scan_result 的决议下 · 本 rev 工具链无下游事件发射代码路径）
> - **M3 · 混合** —— ⏸ **schema 保留 · MVP 未实装**（同 M2 · 需由未来 kickoff 决议放开 4-A / 5-A 后实装）
>
> **实施侧反证证据**：`_review/m6-mvp-smoke-report @v1 §3 R4/R5 反证矩阵` + SMOKE 1（含 pass_through decision）+ SMOKE 2（no_change_drift 亦恒 pass_through）两条真实 artifact 的 `decisions: []` 字面空数组。M2/M3 schema 兼容性确保 future-proof：未来放开时无需再升 schema rev · 仅工具链补实装即可。

**依据**：`m5-toolchain-extension-review@v1 §3.2 TB'2` 原文——
> evolution 扫描器本就需要扫 event-journal 做通道 A 决策 + 可选扫 artifact 目录做通道 B 拉详情——两次扫描的并集 = 孤儿检测所需的全部输入。
> `06 §X 扫描算法` 可把"孤儿检测"作为副作用开关（`--orphan-check` flag）· 默认关闭 · 主动开启时额外输出 orphan 清单。

**TB'2 在 R4 中的定位**：TB'2 明示 evolution 扫描器的 I/O 代价（扫 event-journal + 可选扫 artifact 目录）本就内含孤儿检测能力——这意味着"观测基础层"的成本已经付出，**不产出观测基础层是对已付成本的浪费**。R4 选择 C 候选（混合模型）是对该成本的最大化利用。

### 5.2 副作用开关 · orphan_check

**机制**：evolution 扫描器接受 `--orphan-check` 开关（工具链侧 · kernel 仅承诺 schema）——

| 状态 | artifact body `orphan_check.enabled` | 行为 | 默认 |
|------|-------------------------------------|-----|-----|
| **关闭**（默认） | `false` | 不扫 artifact 目录 · `orphan_check.orphans[]` 为空数组 | ✅ 默认关闭 |
| **开启** | `true` | E3 步骤（§3.2）额外扫描 artifact 目录 · 产出 orphan 清单 | ⏳ 按需开启 |

**orphan 清单 schema**：

```yaml
orphan_check:
  enabled: true | false
  scanned_at: <ISO8601>                # 扫描执行时间（enabled=true 时必填）
  orphans:                             # enabled=true 时填充 · enabled=false 时为空数组
    - orphan_kind: event_without_artifact | artifact_without_event
      reference: <URN 或 event_id>      # 孤儿的身份标识
      reason: <字面描述>                 # 例："artifact file missing" / "no artifact.published event found"
      detected_in_scope: <scope 约束>   # 仅扫描本 evolution 的 scope 范围内（不跨 scope 扩查）
```

**[A3 · Q25 回应] `orphan_check.scanned_at` 与顶层 `produced_at` 对齐约束**：
- `orphan_check.scanned_at` 与本 evolution artifact front-matter 的 `produced_at` **必须同值** · 同一次扫描的两个字段**不得分叉**
- 这是 §3.3 客观性承诺（"本次扫描的时点可复现"）在 orphan_check 字段上的具体化落实 · 确保 orphan_check 产物与 artifact 产出同事务
- 工具链实现约束：`scripts/piao-evolution-scan.sh` 在生成 artifact 时 · 必须对 `produced_at` 和 `orphan_check.scanned_at` 使用**同一时间戳变量** · 不允许分别取值
- 违反本约束的 artifact 视为**事实损坏** · 由消费方按 §7.3 条件 #3 走 retracted 路径
- 本条约束兑现 `m6_evolution_draft_review §2 Q25` 路径 A 处置要求 · 属字面约束补齐 · 不升 rev

**两类 orphan 语义**（TB'2 字面）：

| # | kind | 定义 | 典型原因 |
|---|------|-----|--------|
| 1 | `event_without_artifact` | `artifact.published` 事件存在但对应 artifact 文件丢失 | 文件被误删 / 仓库同步丢失 / retracted 后残留事件 |
| 2 | `artifact_without_event` | artifact 文件存在但无对应 `artifact.published` 事件 | 手写 artifact 未走事件流 / 事件流损坏 / 事件流裁剪过头 |

**TB'2 复用论证**（不单独起 `piao-artifact-validate.sh`）：

| 资源消耗 | 独立 artifact-validate | evolution 扫描器兼任 |
|---------|---------------------|-------------------|
| 扫 event-journal | 1 次（独立扫） | 0 次新增（evolution 本就扫 · E1 步骤） |
| 扫 artifact 目录 | 1 次（独立扫） | 0 次新增（evolution L2 拉取 drift artifact 本就要打开目录 · E3 步骤） |
| 工具链维护成本 | 2 个脚本 | 1 个脚本 + 1 个 flag |
| 客观性承诺 | 需独立证明 | 继承 evolution §3.3 客观性承诺 |

**TB'2 结论直接继承**：复用 evolution 扫描器 · 不起独立工具 · M7 若需提取为独立 MVP 再做（对齐 `m5-toolchain-extension-review §2 T'1 "长期：evolution（M6）扫描器自身可兼任孤儿检测副作用"`）。

### 5.3 决策事件类型枚举

evolution 的决策扩展层可产出的下游 L1 事件（与 §6.6 完全对齐 · 此节聚焦**产出规则**而非**接口契约**）：

| 事件类型 | 产出规则 | `03 §3.1` 归属 | 升版影响 |
|---------|--------|--------------|--------|
| `evolution.scanned` | 每次扫描**必产出** · 观测基础层的事件载体 | L1 事件（新增 · 十类 → 十一类） | **依赖 03 小升**（见 §8.2 门控 #4）|
| `task.proposed` | L1 `dispatch` 或 L2 归因结果为"需新 task"时产出 | L1 事件（已在十类） | ✅ 无升版依赖 |
| `proposal.generated` | L2 归因揭示"kernel 契约需修订"时产出（极罕见） | L1 事件（已在十类） | ✅ 无升版依赖 |

**禁止产出的事件类型**（硬约束）：

| 禁产出事件 | 禁止理由 | 违反契约 |
|----------|--------|--------|
| `task.started` / `task.completed` | 任务生命周期归 task 执行器职责 · evolution 仅"建议"不"执行" | `03 §3.1` L1 事件职责边界 |
| `artifact.published`（除 evolution 自身 scan_result 外） | evolution 不是 artifact 的产出源 · 跨层越权 | §2.3 artifact 产出锁定 + §3.2 E5 原子写入约束 |
| `snapshot.published` | snapshot 产出由 M4 snapshot 引擎独占 · evolution 不得跨层产出 | `04 §2` snapshot 产出契约 |
| `drift.detected` | drift 产出由 M5 drift 引擎独占（订阅 snapshot.published）· evolution 订阅 drift.detected 是下游 · 产出 drift.detected 等于反向写 | `05 §3` drift 触发契约 + §6.4 F3 禁止反向写 |
| `retracted.*` | retracted 事件归 artifact 所有者 · evolution 不持有他人 artifact 的 retract 决策权 | `02 §6` 生命周期 + `05 §7.3` drift retracted 唯一合法场景 |

**关键不变式**：evolution 的下游产出 **∩** 禁产出集合 = ∅ · 这是三层一致性链（snapshot/drift/evolution）在事件产出层的反证闭合。

### 5.4 禁止项（R4 的禁止侧 · 对接 §6.4 F-series）

本节禁止项为**产出行为**禁止 · 与 §6.4 F1-F4（**消费行为**禁止）并列：

| # | 禁止行为 | 违反后果 | 契约依据 |
|---|---------|--------|--------|
| **G1** | 禁止 evolution 直接写 taskdag（跳过 `task.proposed` 事件流） | 违反 `03 §3.1` 双轨原则 · taskdag 是 `task.proposed` 的下游消费者 · evolution 直写 taskdag 等于绕过事件流单一真源 | `03 §3.1` + `m5-toolchain-extension-review §3.2 TB'2` 复用论证 |
| **G2** | 禁止产出**未进入 §5.3 枚举**的 L1 事件类型 | 破坏事件流分层（`03 §3.1` 十类/十一类封闭）· 下游消费者无法预期新事件类型 | `03 §3.1` L1 事件十类/十一类枚举 |
| **G3** | 禁止 orphan_check 关闭时在 `orphan_check.orphans[]` 填入非空数组 | 违反客观性（§3.3）· 同一扫描输入必产出字面相同的 artifact | §5.2 orphan_check schema 约束 + §3.3 客观性 |
| **G4** | 禁止 evolution 在 decisions[] 为空时省略 `decisions` 字段（必须输出空数组） | schema 稳定性 · 下游消费者以"字段必存在"为前提解析 | §2.3 artifact schema 字段必填性 |
| **G5** | 禁止 evolution 以"当前时刻"判定是否降级 orphan_check（orphan_check 是用户显式开关 · 非运行时自动判定）| 违反 §3.3 客观性"不得以当前时刻作为决策输入" | §3.3 客观性承诺 |

### 5.5 边界情况

**B1 · 空 drift 窗口**：
- 若 E1 订阅的 event-journal 窗口内无 `drift.detected` 事件（例：扫描器刚启动 / catch-up 窗口为空），evolution 仍必产出 scan_result + scanned 事件（空 scanned_drifts[] + 空 decisions[]）· **不允许**"空窗口跳过产出"——这是观测可审计性的硬性要求（能证明"扫描器运行过 · 确认无事件"）

**B2 · 全 pass_through 批次**：
- 若批中所有 drift 的 L1 决策均为 `pass_through`（例：批量 no_change_drift），decisions[] 为空数组 · scanned_drifts[] 含全部条目（决策标记为 `pass_through`）· 等价于 §5.1 M1 纯观测模式

**B3 · orphan_check 发现 orphan 的决策处置**：
- 发现 orphan 后，evolution **仅记录不决策**（`orphan_check.orphans[]` 填充 · 但不额外产出 `task.proposed`）
- 理由：orphan 是数据完整性问题 · 需要人工审阅决定修复策略（删 orphan artifact / 补 artifact.published 事件 / retracted）· evolution 不持有该决策权
- orphan 的修复决策由 M7+ 人工流程承载 · 本 M6 仅承诺发现与记录

**B4 · 混合模式下的事件顺序**（E5 原子写入）：
- 单 txn 内事件顺序：`artifact.published(scan_result) → evolution.scanned → task.proposed × m → proposal.generated × n`
- 保证跨事件一致性：下游消费者若读到 `task.proposed`，必然能在同 txn（或事件流上游）读到对应的 `evolution.scanned`（通过 `produced_by.event_id` 反查）

### 5.6 锚点闭环声明

- `m5-toolchain-extension-review@v1 §3.2 TB'2` · 本节 §5.1/§5.2 字面引用复用论证 · ✅ 证据充分
- `03 §3.1` L1 事件枚举 · 本节 §5.3 产出规则 + §5.4 G2 · **依赖 03 下次小升**（`evolution.scanned` 新增）· 见 §2.4 B2 锚点
- `03 §3.3.1` N 条同 txn · 本节 §5.5 B4 事件顺序保证 · ✅ 无升版依赖
- `05 §6.3 C3` provenance 链 · 本节 §5.1 "纯观测独占拒绝"反证依据 · ✅ 无升版依赖
- `m5-toolchain-extension-review §2 T'1` 长期建议 · 本节 §5.2 复用论证字面继承 · ✅ 证据充分
- `04 §2` snapshot 产出契约 / `05 §3` drift 触发契约 · 本节 §5.3 禁止产出事件的反证依据 · ✅ 无升版依赖
- `02 §6` 生命周期 · 本节 §5.3 禁产出 `retracted.*` 的依据 · ✅ 无升版依赖

---

## 6. evolution → next 接口（回答 Q6.5）

### 6.1 双层消费模型（硬约束 R5）

**硬约束 R5**：evolution 消费 drift 走**双层分层消费**契约——

| 层 | 通道 | 读取目标 | 字段数 | 复杂度 | 触发条件 |
|----|------|---------|-------|-------|--------|
| **L1 · 快速决策层** | 通道 A（事件流）| `drift.detected` L1 事件的 **3 字段** | 3 | O(1) 每事件 | 所有 `drift.detected` 事件必读（§3.2 E2）|
| **L2 · 详情拉取层** | 通道 B（artifact 拉取）| drift artifact body 的 `attribution[]` **11+ 字段** | 11+ | O(N) 每条 drift | 仅当 L1 裁定 `decision=pull_detail` 时触发（§3.2 E3）|

**架构意图**：95%+ 的 drift（典型 `no_change_drift` + 微小 `content_drift`）可以在 L1 层直接决策不拉取详情 · 只对需要归因链展开的大 drift 触发 L2 · 把 O(N) 成本分摊到决策价值最高的少数条目。

### 6.2 L1 快速决策层 · 3 字段表

evolution 扫描器在 §3.2 E2 步骤仅读取 `drift.detected` 事件以下 3 字段做 L1 决策：

| # | 字段 | 来源 | 决策语义 |
|---|------|-----|--------|
| 1 | `subject` | `drift.detected.subject` = drift artifact URN | 标识"是哪条 drift 需要决策"· 作为 L2 拉取的 artifact URN（若触发） |
| 2 | `counts` | `drift.detected.counts = {added, removed, sha_changed, unchanged}` | 决策"这条 drift 值不值得拉详情"· 典型规则：`added + removed + sha_changed == 0` → `pass_through`（零内容变化 · no_change_drift 场景）/ `added + removed + sha_changed > threshold` → `pull_detail` / 其他 → `dispatch` |
| 3 | `attribution_mode` | `drift.detected.attribution_mode = full \| sha_only` | 决策"L2 拉取后能否做归因消费"· `sha_only` 模式下即使 L2 拉取也无 `driver_event` 可消费 → L1 可直接降级为 `pass_through`（避免无效拉取） |

**L1 决策三态**（落地到 evolution artifact body `scanned_drifts[].decision`）：

| 决策 | 语义 | 后续动作 |
|------|-----|--------|
| `pass_through` | 本 drift 无需 evolution 行为 · 仅记录"看过" | 不触发 L2 · 不产出下游事件 · scan_result 仅记录该条 drift 被扫描过 |
| `pull_detail` | 需要归因详情才能决策 | 触发 §3.2 E3 拉取 drift artifact body · 进入 L2 |
| `dispatch` | L1 字段足以直接决策（如"值得产新 task"）· 不需归因详情 | 跳过 L2 · 直接进入 §3.2 E4 产出下游事件 |

**关键不变式**：L1 永远只读事件的 3 字段 · 即使该事件含 11 字段（见 `05 §6.2`）· L1 也**禁止**顺便读其他 8 字段——这是"O(1) 字段数上限"契约，防止 L1 膨胀为 L2。

> **[MVP @v0.1 实装范围补注 · 来自 m6-mvp-smoke-report @v1 §4.3 · 2026-04-19 22:30]**
>
> 上表 L1 决策三态为 `06 @v1.1 draft` 锁定的 schema 全集。依据 `m6_final_decisions@v1 §1 决议 4-A (纯观测)` 锁定的 MVP 边界：
>
> - `pass_through` —— ✅ **MVP @v0.1 唯一实装态**（`scripts/piao-evolution-scan.sh @v0.1` 对所有 drift 硬编码该决策 · 不读 `counts` / `attribution_mode` 做分流）
> - `pull_detail` —— ⏸ **schema 保留 · MVP 未实装**（5-A 终止于 scan_result 决议下 · 本 rev 无 L2 拉取代码路径）
> - `dispatch` —— ⏸ **schema 保留 · MVP 未实装**（同 `pull_detail` · 属 §5.1 M2/M3 模式开放后再启用）
>
> **实施侧反证证据**：`_review/m6-mvp-smoke-report @v1 §3 R4 反证` + SMOKE 1-2 两条真实 artifact 的 `scanned_drifts[].decision: pass_through` 字面单态 + content_sha256 六字段白名单（`scope_kind / scope_ref / drift_event_id / drift_urn / decision / driver_event_id`）对齐 `final-decisions §4.1` SHA_WHITELIST 契约。
>
> **L1 不变式在 MVP 下的强化**：MVP @v0.1 不仅遵守"L1 只读 3 字段"契约 · 更进一步"L1 只使用 1 个字段（`subject`）做 scope 校验 + 事件前缀绑定"——`counts` / `attribution_mode` 在 MVP 范围内仅用于 SHA 计算参与不参与 decision 分流（当前恒 `pass_through` 无分流需求）· 属 4-A + 5-A 组合下对 L1 的进一步简化。

### 6.3 L2 详情拉取层 · 11+ 字段表

当 L1 决策为 `pull_detail` 时，evolution 按 `drift.detected.subject` URN 拉取 drift artifact body，读取以下字段做归因消费：

| # | 字段 | 来源（05 §2 drift body） | 消费语义 |
|---|------|-----------------------|--------|
| 1 | `diff_base.old_snapshot_urn` | `05 §2.3` | 定位基线快照 |
| 2 | `diff_base.new_snapshot_urn` | `05 §2.3` | 定位新快照 |
| 3 | `drift_kind` | `05 §3.5` 三枚举（`initial_snapshot` / `content_drift` / `no_change_drift`）| 分流不同决策路径 |
| 4 | `added[]` | `05 §2.3` 三列表之一 | 新增 artifact 清单（可能触发新 task） |
| 5 | `removed[]` | `05 §2.3` 三列表之一 | 移除 artifact 清单（可能触发清理 task） |
| 6 | `sha_changed[]` | `05 §2.3` 三列表之一 | 修改 artifact 清单（可能触发 diff review task） |
| 7 | `attribution[].subject_urn` | `05 §5.3` 归因三元组 | 该条归因对应的受影响 artifact |
| 8 | `attribution[].driver_event` | `05 §5.3` · `attribution_mode=full` 时必填 · `sha_only` 时为 null | **关键归因字段**：哪个事件驱动了本次变化（如 `task.completed` event_id） |
| 9 | `attribution[].driver_task` | `05 §5.3` · `attribution_mode=full` 时必填 | 哪个 task 是变化源（URN）· 用于 L2 产出下游 `task.proposed` 时填 `parent_task` |
| 10 | `attribution[].drift_role` | `05 §5.3` 五枚举（`added` / `removed` / `content_changed` / `identity_changed` / `derived_only`）| 变化的语义类型 · 决定下游事件类型（新 task / 清理 task / review task） |
| 11 | `attribution[].attribution_mode` | `05 §5.1` · 双模式（`full` / `sha_only`）· 单条归因级降级标记 | 本条是否可用于产新 task（sha_only 单条无 `driver_event` 时不产出 `task.proposed`） |

**"11+" 的加号含义**：body 中还可能含 `sha_diff[]` / `attribution[].derived_from_chain[]` / `counts` 等补充字段，消费方按需读（但 kernel 承诺的是上表 11 字段必读 · 其余字段属补充语义）。

### 6.4 L1/L2 禁止项（硬约束 R5 的禁止侧）

| # | 禁止行为 | 违反后果 | 契约依据 |
|---|---------|--------|--------|
| F1 | **禁止绕过事件流直读 drift artifact 目录** | O(1) 扫描退化为 O(N·M) 全目录扫描（N=drift 总数，M=artifact 大小）· 与 `m5_final_decisions §1 决议 5` R5 硬约束冲突 | TB'3 原文 + `m5_final_decisions §1 决议 5` |
| F2 | **禁止 L1 读 3 字段之外的其他 `drift.detected` 字段** | L1 的"O(1) 字段数上限"契约崩塌 · 反证链：L1 一旦允许读 4 字段，就可读 11 字段，L2 就失去存在价值 · 双层消费模型坍缩为单层 | 本节 §6.2 "L1 永远只读 3 字段"不变式 |
| F3 | **禁止 L2 拉取后反向写入 drift artifact** | 违反 `05 §6.3 C1 不得反向写` · drift 是 append-only 产物 | `05 §6.3 C1` |
| F4 | **禁止自行补全 `attribution_mode=sha_only` 的归因字段** | 违反 `05 §6.3 C2` · evolution 不得调用 mtime / git blame 补 `driver_event` | `05 §6.3 C2` |

### 6.5 C1–C4 前置契约继承表

`05 §6.3` 为 M6 预留的 C1–C4 前置契约，本节**全部继承并显式承诺**：

| 契约 | 05 §6.3 原文 | 本节继承点 | 实装证据 |
|-----|-----------|----------|--------|
| **C1** 不得反向写 | "M6 evolution 只允许从 `drift.detected` 事件单向读；不得反向写入 drift artifact" | §6.4 F3 禁止项 | evolution 扫描器代码层面不得 open drift artifact with write flag · `piao-evolution-scan.sh`（工具链承载 · 本 kernel 不实装）需在 code review 中反证 |
| **C2** 不得自补归因 | "M6 对 `attribution_mode=sha_only` 的 drift 不得尝试自行补全归因（不得调用 mtime / git blame）" | §6.4 F4 禁止项 · §6.3 字段 11（`attribution[].attribution_mode`）消费规则锁定 sha_only → 降级 `pass_through` | `m5-toolchain-extension-review §2 T'3` 已修复时间戳 UTC 统一 · 佐证降级透明暴露机制成熟 |
| **C3** 必须走 provenance | "M6 消化 drift 后若产生新的 task / proposal，必须通过 `02 §4` provenance 链关联回本 drift 的 URN" | §2.3 artifact schema `produced_by.{task_urn, event_id}` 必填 · E4 产出的下游事件 `produced_by.artifact_urn` 回指 evolution scan_result | `02 §4` provenance 四元组（@v1.3 已 published） |
| **C4** append-only | "M6 不得以'已消化 drift A'为由修改 drift A 的 status 或内容 —— drift 是 append-only artifact" | §2.4 B5 + §3.2 E5 事件流 append-only + §3.4 降级策略"不回滚 drift" | `03 §3.3` append-only + `02 §6` 生命周期 |

### 6.6 下游接口锁定 · evolution 产出喂给谁

**硬约束**：evolution 的 E4 步骤产出的下游事件**仅限**以下类型 · 禁止产出其他 kernel L1 事件：

| 事件类型 | 产出场景 | 下游消费者 | 契约依据 |
|---------|--------|----------|--------|
| `task.proposed` | L2 裁定"需要新 task 处理该 drift"（典型：`drift_role=added` 的新 artifact 需要审查 task）| M3 taskdag 调度器（kernel 未来篇 · 目前由 `mvvm-architecture-rules` 等工具链承载） | `03 §3.1` L1 事件十类之一 |
| `proposal.generated` | L2 裁定"需要新 proposal 启动 kernel 升版"（极罕见 · 典型：drift 揭示 kernel 契约本身需要修订） | 人工审阅 + kernel 升版流程 | `03 §3.1` L1 事件十类之一 |
| `observation_only` | L1/L2 均裁定"仅观测不决策"（典型：`pass_through` · 或 L2 拉取后发现无行动价值） | 无下游消费者 · 仅作为 evolution scan_result 的 decision 记录 | 非事件类型 · 仅 body 字段值 |

**禁止产出**：`task.started` / `task.completed` / `artifact.published` / `snapshot.published` / `drift.detected` / `retracted.*`——这些均属其他 kernel 层职责 · evolution 不得跨层产出。

**evolution 作为"决策终点"的边界**：
- evolution 不直接写 taskdag（由 M3 未来篇接管 · `task.proposed` 事件是 evolution 与 taskdag 的单向通知接口）
- evolution 不产出新 `artifact.published` 事件**除了自身的 scan_result**（§3.2 E5 原子写入的一部分）
- 是否引入 M8+ 更上层决策引擎由未来 kernel 层决定 · 本 M6 **不预设** M7/M8 接口（对齐 `m6_evolution_kickoff §4` Q6.5 候选三选一的"完全终止于产出 task 建议"路径）

### 6.7 锚点闭环声明（@v1 draft 门控 #4）

- `05 §6.1` 双通道设计 · 本节 §6.1 直接继承范式 · ✅ 无升版依赖
- `05 §6.2` `drift.detected` 11 必填字段 · 本节 §6.2 L1 读 3 字段 + §6.3 L2 读 11+ 字段 · ✅ 无升版依赖
- `05 §6.3` C1–C4 前置契约 · 本节 §6.5 继承表 · ✅ 四条契约全承诺
- `05 §2.3` drift body schema · 本节 §6.3 L2 字段表直接引用 · ✅ 无升版依赖
- `05 §5.3` 归因三元组 · 本节 §6.3 字段 7–10 引用 · ✅ 无升版依赖
- `03 §3.1` L1 事件十类 · 本节 §6.6 下游事件类型锁定 + §2.4 B2 新增 `evolution.scanned` · **依赖 03 下次小升**
- `02 §4` provenance 四元组 · 本节 §6.5 C3 依据 · ✅ 无升版依赖
- `m5_final_decisions §1 决议 5` R5 · 本节 §6.4 F1 直接引用 · ✅ 无升版依赖

> **[A1 · Q23 回应] L1 事件 3 字段上限契约的普适性声明**：
> 本节 §6.2 所锁定的 "L1 永远只读 3 字段"（`drift_urn` / `decision` / `driver_event_id`）契约 · 为 **06 M6 单边约束**（源自 TB'4 `05 §6.1-§6.3` 双通道范式在 evolution 层的具体化落实）· **不对外推广**。`03 §3.1` 尚未在 kernel 全局建立 L1 事件 body 字段数上限的统一 schema（当前 03 @v1 只锁"10 类事件枚举 + 通用骨架"· 未锁"每类 L1 事件 body 字段数"）· 若未来 M7+ 出现新 L1 事件类型（例 `task.*` / `proposal.*`）· 需在彼时根据各自消费语义重新评估 3 字段上限是否适用 · **本 M6 不假设该契约自动推广到其他 L1 事件类型**。本条声明兑现 `m6_evolution_draft_review §2 Q23` 路径 A 处置要求 · 属字面约束补齐 · 不升 rev。

---

## 7. evolution 生命周期与通胀控制（参考 05 §7 / 04 §6-§7 范式）

### 7.1 双轨生命周期（artifact + L1 事件 · 对齐 R1 双形态）

evolution 的生命周期严格对应 §2 R1 双形态决议：

**轨 A · artifact 形态**（`evolution.scan_result`）——仅两态 · 对齐 `05 §7.1` drift 范式：

```
  draft ──┬── artifact.published ──▶ published (永久态 · append-only)
          │
          └── 极罕见情况：artifact.retracted ──▶ retracted（见 §7.3）
```

**不引入** `superseded` 态——evolution artifact **不升 rev**，因为：
- evolution 的"rev"本应由扫描算法 rev 决定，但单次扫描产出是客观产物（给定同一输入必产出字面相同结果 · §3.3）
- 如果发现 evolution 扫描算法本身有 bug → 升的是 kernel rev（本篇 §8.2），不是单条 scan_result 的 rev
- 对齐 `05 §7.1` "drift artifact 不升 rev" 范式同构

**轨 B · L1 事件形态**（`evolution.scanned` / `task.proposed` / `proposal.generated`）——append-only · 无生命周期：
- L1 事件一旦 append 到 event-journal 即永久存在（对齐 `03 §3.3` append-only 契约）
- 事件流不存在"状态转换"概念（draft/published/retracted 不适用于事件）
- 禁止事件回滚：即使对应 artifact 被 retracted，事件本身仍保留（可被下游消费者读到历史上的扫描决策）

**双轨同步**：
- E5 原子写入保证 artifact `published` + `evolution.scanned` 事件 append 在同 txn（`03 §3.3.1` N 条同 txn）
- retracted 场景：额外产出 `artifact.retracted` 事件（不回滚 `evolution.scanned`）· 下游消费者读到两事件即可推导 "曾 scan · 后 retract"

### 7.2 体积预算

对齐 `05 §7.2 drift 体积预算` + `04 §6.1 snapshot 体积预算` 范式：

| 项 | 预期值 | 上限 | 依据 |
|----|-------|------|-----|
| 单条 `evolution.scan_result` artifact 大小 | < 10 KB | < 1 MB | 对标 `05 §7.2` 单 drift 预算（< 5 KB）· evolution 通常聚合多条 drift · 预算略放宽 |
| `scanned_drifts[]` 条目数 | 1～几十（模式 A / B 典型值） | < 500 | 与 drift 批聚合窗口大小相关（§4.3 模式 B）· 超上限应拆分为多次扫描 |
| `decisions[]` 条目数 | 0～几（典型大多为空或少量）| < `scanned_drifts[]` 上限 | decisions 是 scanned_drifts 的子集（每条 scanned drift 至多产出一条 decision · 不放大） |
| `orphan_check.orphans[]` 条目数（开启时）| 0～几（健康系统应接近 0）| < 1000 | 大量 orphan 揭示数据损坏 · 应优先修复而非写入 evolution artifact |
| 每 scope_ref 生命周期内 evolution artifact 总数 | 与 drift 总数近似（1:1 或 N:1 模式 B 聚合后 N:1）| < 5,000 | 对齐 `05 §7.2` 每 scope_ref drift 上限（< 10,000）· evolution 通过模式 B 聚合自然减半 |
| `evolution.scanned` L1 事件大小 | < 1 KB | < 10 KB | 仅含元信息（event_journal_range / scanned_drift_count / decision_count · §2.3）· 远小于 artifact |

**预算守恒声明**：
- 所有超预算情形需在 evolution artifact body 补 `volume_exceeded_reason` 字段说明（同时触发 `WARN` 级工具链日志 · 非阻塞）
- 超上限情形（1 MB artifact / 500 条 scanned_drifts）触发退出码非零 · 强制要求拆分扫描（对齐 `04 §6.2` 通胀硬边界）

### 7.3 retracted 的合法场景

evolution artifact 仅在以下情况可被 retracted（范式继承 `05 §7.3` drift retracted 三条件）：

1. **被扫 drift artifact 被 retracted**：
   - 当 evolution scan_result 的 `scanned_drifts[].drift_urn` 指向的 drift artifact 被 retracted（`05 §7.3`），该 evolution 的决策基础不复存在 · 应 retracted 重新扫描
   - **级联触发机制**：由工具链在 `drift.retracted` 事件订阅者中实现 · evolution scan_result 基础层面上无需主动监听（本 kernel 不承诺 evolution 引擎做级联订阅）

2. **evolution 扫描算法 kernel rev 升降且新 rev 显式声明旧语义失效**：
   - 仅当 `06 @vN → @vN+1` 的 `rev_history` 条目中**显式写明** `retroactive_invalidation: true`（含失效理由），触发当前 evolution artifact 批量 retracted
   - **默认情形**（新 rev 未声明 `retroactive_invalidation`）：旧 evolution artifact **保持 published** · 历史决策继续可被审计 · 对齐 `05 §7.1 R20` 脚注 "kernel 层默认不回溯作废" 精神
   - **[A4 · Q26 回应] 与 kernel rev 升版的对接语义**：承继 `05 §7.3` "默认不回溯作废" 范式 · kernel rev 升版（例：扫描算法从 v1 → v2 · 触发 06 本篇 §8.2 条件）**默认只对未来扫描生效** · **不自动批量 retracted 历史 published evolution.scan_result**；若 kernel rev 升版方认为历史产物需整体作废 · 必须走**独立 `evolution_retract_batch` proposal**（声明作废范围 + retracted 理由 + 恢复路径）· 由 proposal published 后的工具链执行批量 retracted · **不通过本 §7.3 条件 #2 的 `retroactive_invalidation: true` 自动化路径承载**。本条语义对齐 `m6_evolution_draft_review §2 Q26` 路径 A 处置要求 · 避免"kernel 升 rev 即旧 evolution 全部作废"的工具链误解 · 属字面约束补齐 · 不升 rev

3. **数据损坏**：
   - evolution artifact 文件被文件系统损坏 / 签名不匹配 · retracted 后由工具链重新运行扫描算法补产出（新 URN · 不复用旧 URN）

**禁止** retracted 的场景（硬约束）：

| # | 场景 | 禁止理由 |
|---|------|--------|
| 1 | 业务层"不喜欢"这条 evolution 的决策（例：觉得该 drift 不值得产出 task.proposed） | evolution 是**客观决策结果**（基于 L1/L2 契约字段的确定性推导）· 不是主观意见 · 决策偏好修正应升算法 rev 而非 retracted 单条 |
| 2 | 下游 `task.proposed` 被消费者拒绝（未被转为实际 task） | `task.proposed` 是"建议"不是"强制" · 下游不消费是下游决策权 · 不反向作废 evolution |
| 3 | 时间过久（例："一年前的扫描不再相关"） | 时间不是 retracted 触发条件 · 归档策略留给 M7+ GC（§7.5）· 不由 retracted 承载 |
| 4 | 被 evolution 产出的 `task.proposed` / `proposal.generated` 事件关联 artifact 被 retracted | evolution 决策是历史事实 · 下游 artifact 作废不反推上游决策作废 · 违反 append-only 精神 |

**级联声明**：evolution artifact retracted 时，**不**反向触发 `task.proposed` / `proposal.generated` 事件作废（事件 append-only）· 消费方需通过 `produced_by.artifact_urn` 反查发现 retracted 状态并自主处理。

### 7.4 通胀控制策略

对标 `05 §7.4` + `04 §6.2 snapshot 通胀是最大设计风险`：

**H1 · 避免小步扫描触发密集 evolution**：
- evolution 与 drift 密度挂钩（drift 1:1 消化模式 A）· drift 密度由 snapshot 密度约束（`04 §4.2`）· 自然级联控制
- 模式 B 批聚合进一步降低 evolution artifact 总量（同 scope 多 drift 合并为 1 scan_result）

**H2 · 避免 pass_through 污染事件流**：
- 典型场景：批量 no_change_drift 扫描可能产出大量 `scanned_drifts[].decision=pass_through` 记录
- **二阶过滤**：消费方可基于 `evolution.scanned` 事件的 `evidence.decision_count` 字段（当 `decision_count == 0` 时）在拉取 artifact 之前跳过纯观测批次
- 对齐 `05 §7.4 no_change_drift 二阶过滤` 范式

**H3 · orphan_check 开启频率控制**：
- 工具链侧建议：`--orphan-check` 仅在周期性健康检查运行（例：日终一次）· 非每次扫描必开启
- kernel 层不硬约束频率（客观性承诺涵盖开关状态 · 开关本身是配置不是运行时判定）· 但建议开关默认关闭（§5.2）避免每次扫描都额外产出 orphan 清单

**H4 · 归档策略**：
- 留给 M7+（本篇不覆盖 · 对齐 `05 §7.4` + `04 §9` 非目标清单 + `m6_evolution_kickoff §4` 非目标）
- 预期归档窗口：evolution artifact 与对应 scope 的 snapshot/drift 同步归档 · 保持三层 scope 一致性在归档层延续

### 7.5 与 drift / snapshot 的通胀级联比（参考值）

| 层 | 单 scope 生命周期内数量 | 级联比（上游 : 本层）|
|----|---------------------|-------------------|
| snapshot | < 10,000（`04 §6.1`） | — |
| drift | < 10,000（`05 §7.2`） | 1 : 1（N-1 条 drift 对应 N 条 snapshot）|
| evolution（模式 A 逐条）| < 10,000 | 1 : 1（1 drift 1 scan）|
| evolution（模式 B 批聚合）| < 5,000 | 1 : 0.5～0.2（N 条 drift 聚合为 1 scan · 取决于批窗口）|

**级联不变式**：evolution 总量 ≤ drift 总量 ≤ snapshot 总量（除 initial_snapshot 场景下 drift > snapshot 的 +1 情形外 · `05 §3.5`）。

### 7.6 锚点闭环声明

- `04 §6.1` snapshot 体积预算 · 本节 §7.2 范式继承 · ✅ 无升版依赖
- `04 §6.2` 通胀是最大设计风险 · 本节 §7.4 H1-H4 范式同构 · ✅ 无升版依赖
- `04 §7.1` snapshot 状态机 · 本节 §7.1 轨 A 范式同构 · ✅ 无升版依赖
- `05 §7.1/§7.2/§7.3/§7.4` drift 生命周期全套 · 本节 §7.1–§7.4 字面复用范式 · ✅ 无升版依赖
- `05 §7.1 R20` 脚注（历史 drift 回溯作废策略）· 本节 §7.3 条件 #2 字面继承 · ✅ 无升版依赖
- `02 §6` artifact 生命周期 · 本节 §7.1 轨 A `draft → published → retracted` · ✅ 无升版依赖
- `03 §3.3` append-only · 本节 §7.1 轨 B 事件生命周期依据 · ✅ 无升版依赖
- `03 §3.3.1` N 条同 txn · 本节 §7.1 双轨同步依据 · ✅ 无升版依赖

---

## 8. rev_history 与 M6 升版路径

### 8.1 rev_history

| rev | 发布时间 | 触发来源 | 变更摘要 |
|-----|---------|---------|---------|
| v0.1 | 2026-04-19 18:20 | `m6_evolution_kickoff@v1 §2.3` 分支 β-2 触发（阶段 α 工具链扩展零 05 歧义 · 4 发现均属 03 补齐/补注级） | 骨架起稿：§0 定位 + §1 五问清单 + §2–§6 Q6.1–Q6.5 占位（每节锁定 TB'x 证据锚点 + 展开方向 · 不填正文）+ §7 生命周期占位 + §8 rev_history + §9 前置契约 + §10 非目标 + §11 状态 |
| v0.2 | 2026-04-19 18:40 | 上一步 Ⓒ 裁定"先起稿 §2/§3/§6 三节硬核正文验证 TB' 证据层承载力"（路径 Ⓒ 分支执行产出） | **三节硬核正文起稿**：①§2 Q6.1 身份 R1 锁定（双形态并存 · 90 行 · 五子节 2.1-2.5）②§3 Q6.2 触发 R2 锁定（唯一触发器 `drift.detected` · E1-E5 原子流程 · 75 行 · 六子节 3.1-3.6）③§6 Q6.5 接口 R5 锁定（双层消费 L1/L2 · F1-F4 禁止项 · C1-C4 继承表 · 下游事件类型锁定 · 105 行 · 七子节 6.1-6.7）· §0.1 设计取舍表 R1/R2/R5 从"占位"升为"已锁定" · §1 答复摘要 Q6.1/Q6.2/Q6.5 从"待展开"改为实际一句话 · **§4/§5/§7 仍占位** · 证据层承载力验证结论：TB'1/TB'3/TB'5 + `05 §6` 足以支撑三硬约束 · @v1 draft 可一次性推进 |
| v1（draft） | 2026-04-19 19:10 | 上一步 Ⓑ 裁定"先 commit @v0.2 固化里程碑 · 再启动 @v1 draft 一次性填充 §4/§5/§7 + §8.2 门控复核"（@v0.2 commit `74820f3c` 已固化） | **首版 draft 收官**：①§4 Q6.3 scope R3 锁定（三层一致性链 L0/L1/L2 · 批聚合模式 A/B 允许 / C/D/E 拒绝 · 拒绝列表五条 · 客观性守恒 · 六子节 4.1–4.6 约 80 行）②§5 Q6.4 决策产物 R4 锁定（混合模型候选 C · 观测基础层恒定 + 决策扩展层按需 · `--orphan-check` 副作用开关 · 决策事件枚举 + 禁止产出事件 · 边界情况 B1-B4 · 六子节 5.1–5.6 约 110 行）③§7 生命周期 R1 驱动双轨锁定（轨 A artifact 两态 `draft→published→retracted` · 轨 B L1 事件 append-only · 体积预算六项 + 通胀控制 H1-H4 + 与 drift/snapshot 级联比表 · 六子节 7.1–7.6 约 75 行）· §0.1 设计取舍表 R3/R4 从"占位"升为"已锁定"· §1 答复摘要 Q6.3/Q6.4 从"待展开"改为实际一句话 · §8.2 四条门控全部 `[x]`· §11 本篇状态行从"@v0.2 三节硬核正文已起稿"改为"@v1 draft · R1–R5 全锁定"· 证据层闭合结论：TB'1/TB'2/TB'3/TB'4/TB'5 + `05 §6/§7` + `04 §3.3/§5.3/§6/§7` + `02 §6` + `03 §3.3` 共同支撑 R1–R5 · 无遗漏锚点 |
| **v1（draft · 路径 A 消化）** | 2026-04-19 19:54 | `_review/m6-evolution-draft-review.md @v1 draft §3.1` 路径 A 四条缺口（Q23/Q24/Q25/Q26）原地消化裁定 · 不升 rev（方案 α · "在 06 @v1 draft → @v1 published 直升版时同步刷进"范式 · 对标 M5 05 @v1 draft 路径 A 处置同构） | **路径 A 四条字面约束补齐 · 不升 rev · +18 行**：①§6.7 末尾追加 **A1 · Q23 回应** L1 事件 3 字段上限契约普适性声明（明示"06 M6 单边约束 · 03 未建立全局 schema · M7+ 新 L1 事件需重评 · 不假设自动推广"）②§2.3 身份 schema `scanned_drifts[]` 字段必填性说明 **A2 · Q24 回应**（`drift_urn`/`decision`/`drift_event_id` 必填 · `driver_event_id` 条件必填 · `attribution_mode=sha_only` 时为 null · 承继 `05 §5.3` 归因三元组语义）③§5.2 orphan_check schema 后追加 **A3 · Q25 回应** `orphan_check.scanned_at` 与顶层 `produced_at` 必须同值约束（§3.3 客观性承诺的字段级落实 · 工具链实现约束"同一时间戳变量" · 违反视为事实损坏走 §7.3 条件 #3）④§7.3 retracted 条件 #2 末尾追加 **A4 · Q26 回应** kernel rev 升版对接语义（默认只对未来扫描生效 · 历史批量作废走独立 `evolution_retract_batch` proposal · 不通过 `retroactive_invalidation: true` 自动化路径）· **门控 #1/#2/#3 保持 `[x]` · 门控 #4 待路径 B `m6_evolution_kernel_alignment@v1` proposal 落地后关闭** · §11 本篇状态行同步刷新 |
| **v1.1（draft）** | 2026-04-19 20:50 | `urn:piao:proposal:kernel:m6_evolution_kernel_alignment@v1 §4.4` · M6 路径 B · S4 跟随升版落地（B1/B2 反向对接完成后 06 本篇同步刷新锚点注释状态 · 对标 M5 `05 @v1 → @v1.1 draft` 范式同构 · draft 内小升 · 非 published 升版） | **draft 内小升 · 跟随对接 · 纯状态刷新（零 schema 改动 · 零硬约束改动 · 零字段类型变更 · 零工具链改动）**：①§2.4 关键边界锁定表 **B2 / B3 标签从"依赖 03/02 下次小升"改写为"已对接"**（B2 指向 `03 @v1 draft` 原地精化 · commit `76bbfff5` · 2026-04-19 20:30 · S1 驱动；B3 指向 `02 @v1.4 published` · commit `7a7bce04` · 2026-04-19 20:45 · S2 驱动 · `wordcheck_policy: exempt` 措辞精化为 `wordcheck_policy: machine_generated` 对齐 02 @v1.4 实际注册值）②§2.5 锚点闭环声明 `02 §2.2.4` / `03 §3.1` 两条依赖状态从"依赖下次小升"改写为"✅ 已对接"（附 commit hash 与驱动 proposal URN）③§8.2 门控 #4 达成段 · 内文"02 §2.2.4 派生类型注册依赖 02 下次小升 / 03 §3.1 L1 事件枚举依赖 03 下次小升"改写为"✅ 已对接"（并追加闭环证据 commit hash）· **门控 #1–#4 全部 `[x]` · 路径 B 外篇依赖关闭**④§9 前置契约表 `03 §3.1` L1 事件枚举 + `03 §3.1` 双轨原则 + `03 §3.3.1` 原子写入契约 三行状态从"✅ @v1 draft"精化为"✅ @v1 draft（路径 B S1 已反向对接 · 2026-04-19 20:30）" · `02 §2.2.4` 派生类型注册行从"✅ @v1.3 published"升为"✅ @v1.4 published（路径 B S2 已反向对接 · 2026-04-19 20:45）"⑤§11 本篇状态行从"@v1 draft · 路径 A 消化完成 · 等待路径 B"改写为"**@v1.1 draft · 路径 A/B 全消化 · 等待 §8.2 门控 #4 工具链反证（`scripts/piao-evolution-scan.sh` MVP）**"⑥§11 下游锚点表 · `02 @v1.4 draft` 行改写为"✅ `02 @v1.4 published`（2026-04-19 20:45 · S2 已消费）" · `03 @v1 draft → @v1.1 或原地修` 行改写为"✅ `03 @v1 draft` 原地精化（2026-04-19 20:30 · S1 已消费 · 十类枚举总数不变 · `evolution.scanned` 行按 §2.3 / §5.3 实锁 schema refresh）" · `m6_evolution_kernel_alignment@v1 proposal` 行从"待开"改写为"✅ published（2026-04-19 · 本篇升版的驱动源 · 5 commit 固化）"。**对 v1 draft 已锁定的 R1–R5 五硬约束零冲击**（§2–§7 正文字面保留）· **对 §8.2 门控 #1–#4 全部保持 `[x]`**（门控 #4 从"外篇依赖关闭后可勾"→ "外篇依赖已关闭 · 依据 commit `76bbfff5` + `7a7bce04`"）· 本次 draft 内小升对应无 L1 事件（draft 内小升不发 `spec.published` L1 事件 · 按 `01 §10.1` draft 契约 · 对标 M5 `05 @v1 draft → @v1.1 draft` 同构处置）· 下一步升 `@v1.1 published` 门控路径：`scripts/piao-evolution-scan.sh` MVP 产出首个真实 `evolution.scan_result` artifact 做反证（对标 M5 `piao-drift-compute.sh` 节奏 · 期间可能 `sha_whitelist` 六字段清单由 MVP 产出反证后补登 02 @v1.4 → @v1.5 · 节奏同 drift.propagation_record v1.2 → v1.3） |
| v1.1（draft · MVP 实装范围路径 A 小补注） | 2026-04-19 22:30 | `_review/m6-mvp-smoke-report.md @v1 §4` 三处清单驱动 · `scripts/piao-evolution-scan.sh @v0.1` MVP 产出反证后锁定 @v0.1 实装边界 · 路径 A 原地精化（不升 rev · 对标 `05 @v1 draft` 路径 A 消化范式同构） | **路径 A 三处 MVP 实装范围补注 · 不升 rev · 零 schema 改动 · 零硬约束改动**：①§2.3 artifact schema `decisions[]` 数组块下方追加 MVP 实装范围注释块（锁定 decision 恒为 `pass_through` 单态 · decisions[] 恒为空 · `pull_detail` / `dispatch` 为 schema 预留）②§5.1 产出模式矩阵"反例拒绝"段后追加 blockquote 补注（M1 ✅ MVP 实装 · M2/M3 ⏸ schema 保留未实装）③§6.2 L1 决策三态"关键不变式"段后追加 blockquote 补注（`pass_through` ✅ 唯一实装 · `pull_detail` / `dispatch` ⏸ schema 保留）· 三处补注均字面引用 `m6_final_decisions@v1 §1 决议 4-A + 5-A` 硬约束锚点 · 补注证据来源 `_review/m6-mvp-smoke-report @v1 §3 R4/R5 反证矩阵` + SMOKE 1/SMOKE 2 两条真实 artifact 的 `decision: pass_through` + `decisions: []` 字面反证 · draft 内原地修订不发 `spec.published` L1 事件（按 `01 §10.1` draft 契约）· 为下一行 @v1.1 published 升版做最终铺垫 |
| **v1.1（published）** | **2026-04-19 22:40** | `_review/m6-mvp-smoke-report.md @v1 published §2 SMOKE 1-4 全通` + `scripts/piao-evolution-scan.sh @v0.1` MVP 首版产出 · M6 milestone §8.2 门控 #4 工具链反证达成 · 对标 M5 `05 @v1.1 draft → @v1.1 published` 同构封版范式 | 同 rev 内部 `draft → published` 状态转换（不升 rev · 不触发 supersedes）· `§8.2` 四条门控全部达成：**#1** R1–R5 五硬约束锁定（@v0.2 + @v1 两阶段锁定 + 22:30 路径 A 三处 MVP 实装范围补注对齐 final-decisions §1 决议 4-A/5-A 不升 rev）· **#2** TB' 映射矩阵完整覆盖（Q6.x → TB'x 全五对一 · §11 末尾矩阵）· **#3** 锚点闭环六处声明 + 外篇对接完成（02 @v1.4 published + 03 @v1 draft 原地精化 · path B S1/S2 已消费）· **#4** 工具链 MVP 反证达成（`scripts/piao-evolution-scan.sh @v0.1` ~430 行 · SMOKE 1-4 冒烟全通 · R1–R5 反证矩阵见 `_review/m6-mvp-smoke-report @v1 §3` · 对标 M5 `piao-drift-compute.sh` 555 行节奏 · 决议 4-A + 5-A 保守组合代码路径简化至 ~430 行）。主要动作：①front-matter `status: draft → published` · `last_modified_at` 刷新至 22:40 · `upstream` 追加 `urn:piao:snapshot:kernel:m6_final_decisions@v1` + `urn:piao:artifact:kernel:m6_mvp_smoke_report@v1` 两条 · `artifact_model` 从 `@v1.3` 升至 `@v1.4`（path B S2 已消费）；②标题从"@v1 draft · 首版 draft 收官"改为"@v1.1 published · MVP 反证收官" · 起稿说明段首补 "@v1.1 published 定稿说明" 段（含升版全路径六阶段 + 四门控达成证据 + 三处 MVP 实装范围补注锁定）；③§8.2 门控复核表四条保持 `[x]`（门控 #4 达成段追加 MVP 反证证据 · `scripts/piao-evolution-scan.sh @v0.1` + `_review/m6-mvp-smoke-report @v1`）；④§11 本篇状态行从"@v1.1 draft · 等待工具链反证"改为"**@v1.1 published · MVP 反证达成 · M6 milestone 正文本体收官**" · 下游锚点表 `scripts/piao-evolution-scan.sh` 行从"待起稿"改为"✅ @v0.1 MVP 首版 · 2026-04-19 22:30 · ~430 行" · 追加 `_review/m6-mvp-smoke-report @v1 published` 行。**本次升版后触发序列**：发射 `artifact.published` L1 事件（kind=spec · event_id 前缀按 `01 §5` 规约 `snap-published-<YYMMDDHHmmss>-<rand6>` · 对标 `05 @v1.1 published` 范式同构 · 由独立事件写入步骤执行） |

### 8.2 升 `@v1 draft` 的门控条件（**四条全达成 · 2026-04-19 19:10** · 路径 A 消化补充 · 2026-04-19 19:54）

本篇 `@v0.1 骨架 → @v1 draft` 需同时满足：

- [x] §2–§6 Q6.1–Q6.5 五问均**锁定硬约束取值**（对标 `05 §0.1` R1–R5 模式 · 从"占位"升为"硬约束"）· 达成证据：R1/R2/R5 @v0.2 锁定（见 §2/§3/§6 · commit `74820f3c`）+ R3/R4 @v1 锁定（见 §4/§5 · 本 rev 展开）· §0.1 设计取舍表 5/5 标为"✅ 锁定"
- [x] 每条硬约束均引用 TB'1–TB'5 之一作为工具链视角证据锚点（严禁脱离证据层推理）· 达成证据：R1→TB'5（§2.4 B4）· R2→TB'1（§3.1 + §3.5 反证）· R3→TB'4（§4.1 字面引用）· R4→TB'2（§5.1 + §5.2 字面引用）· R5→TB'3（§6.1/6.2/6.3）· Q6.x→TB'x 映射矩阵完整覆盖（§11 末尾）
- [x] §7 生命周期随 Q6.1 身份决议同步展开（artifact / L1 事件 / 双形态三选一落地）· 达成证据：R1 双形态并存 → §7.1 双轨生命周期（轨 A artifact 两态 + 轨 B L1 事件 append-only）· §7.2 体积预算六项 + §7.3 retracted 三条件（**含 A4 · Q26 kernel rev 升版对接语义**）+ §7.4 通胀控制 H1-H4 + §7.5 级联比表完整对齐 `05 §7.2/§7.3/§7.4` 范式
- [x] `06` 与 `01 §2.1` / `02 §2.2` / `03 §3.1` / `05 §6` 的锚点闭环声明（对标 05 v1 的锚点闭环语）· 达成证据：§2.5 / §3.6 / §4.6 / §5.6 / §6.7 / §7.6 六处锚点闭环声明 · 共 42 处 TB' 引用 · `01/§2.1` ✅ 无升版 · `02 §2.2.4` 派生类型注册 ✅ **已对接**（@v1.4 published · 2026-04-19 20:45 · 由 `m6_evolution_kernel_alignment@v1 S2` 驱动 · 本篇 §2.4 B3 声明的外篇依赖关闭）· `03 §3.1` L1 事件枚举 ✅ **已对接**（@v1 draft 原地精化 · 2026-04-19 20:30 · 由 `m6_evolution_kernel_alignment@v1 S1` 驱动 · 10 类枚举总数不变 · `evolution.scanned` 行按本篇 §2.3 / §5.3 实锁 schema refresh · 本篇 §2.4 B2 + §5.3 声明的外篇依赖关闭）· `05 §6` ✅ 无升版

**路径 A 消化补充达成声明**（2026-04-19 19:54 · 对标 `_review/m6-evolution-draft-review.md @v1 §3.1` 四条修订）：

| 修订 # | 源自 review 缺口 | 修订位置 | 修订类型 | 达成状态 |
|-------|--------------|-------|-------|-------|
| A1 | Q23 · L1 事件 3 字段上限契约普适性 | `§6.7` 锚点闭环声明末尾（行 612）| 字面约束补齐 | ✅ 刷进 |
| A2 | Q24 · `scanned_drifts[]` schema 字段必填性 | `§2.3` 身份 schema `scanned_drifts[]` 字段注释（行 140）| 字段必填性标注 | ✅ 刷进 |
| A3 | Q25 · `orphan_check.scanned_at` 与 `produced_at` 对齐 | `§5.2` orphan_check schema 后（行 423）| schema 字段对齐约束 | ✅ 刷进 |
| A4 | Q26 · retracted 条件 #2 与 kernel rev 升版对接 | `§7.3` retracted 条件 #2 末尾（行 673）| 生命周期边界规则 | ✅ 刷进 |

**路径 A 消化评估**：
- **不触发 rev 升版**（维持 @v1 draft · 等待路径 B `m6_evolution_kernel_alignment@v1` proposal 落地后统一升 @v1 published 或 @v1.1）
- **不改变 R1–R5 五硬约束** · 仅为字面约束补齐 / 脚注澄清 · 符合 `m6-evolution-draft-review §4.1` "质量可接受 · 不触发返工"判定
- **门控 #4 状态不变**：外篇依赖（03 @v1.1 · 02 @v1.4）仍待路径 B proposal 驱动 · 本次路径 A 消化不影响外篇锚点
- **升 @v1 published 门控路径**：路径 A 已消化 ✅ + 路径 B proposal published → 外篇小升 @v1.1/@v1.4 published → 06 刷新 §9 锚点 → 升 @v1 published

**v1.1 draft 升版后事实补注**（2026-04-19 20:50 · 由 `m6_evolution_kernel_alignment@v1 §4.4 S4` 落地后追加）：
- 实际路径采取"**@v1.1 draft 小升而非 @v1 published 直升**"（理由：外篇对接 + 本篇锚点状态刷新**属状态同步性质**而非**工具链反证性质** · draft 内小升先固化状态事实 · 工具链反证后再升 @v1.1 published · 对标 M5 `05 @v1 → @v1.1 draft` 同构范式 · 上述"升 @v1 published 门控路径"修正为"**升 @v1.1 published 门控路径**"· 等同于工具链 MVP 反证 · 路径 A/B 全消化已由 @v1.1 draft 落定）
- 外篇实际对接结果：`03 @v1 draft` 原地精化 (commit `76bbfff5`) + `02 @v1.4 published` (commit `7a7bce04`) · 10 类 L1 枚举总数不变（03 占位字段精确化定性）· 02 派生类型注册表新增 1 条 `evolution.scan_result`

**@v1.1 published 升版达成声明**（2026-04-19 22:40 · MVP 反证收官 · 对标 M5 `05 @v1.1 draft → @v1.1 published` 同构范式）：

| # | 门控条件 | 达成状态 | 达成证据 |
|---|---------|--------|---------|
| #1 | R1–R5 五问硬约束全部锁定 | ✅ **已达成** | @v0.2 锁定 R1/R2/R5（commit `74820f3c`）+ @v1 锁定 R3/R4（本 rev §4/§5 展开）· §0.1 设计取舍表 5/5 标"✅ 锁定"· 2026-04-19 22:30 路径 A 三处 MVP 实装范围补注（§2.3/§5.1/§6.2）对齐 `m6_final_decisions@v1 §1 决议 4-A + 5-A` 不升 rev |
| #2 | 每条硬约束引用 TB'1–TB'5 + 工具链 MVP 首版产出（对标 M5 `piao-drift-compute.sh` 节奏） | ✅ **已达成** | R1→TB'5（§2.4 B4）· R2→TB'1（§3.1 + §3.5 反证）· R3→TB'4（§4.1 字面引用）· R4→TB'2（§5.1 + §5.2 字面引用）· R5→TB'3（§6.1/6.2/6.3）· Q6.x→TB'x 映射矩阵完整覆盖（§11 末尾矩阵）· **工具链 MVP**：`scripts/piao-evolution-scan.sh @v0.1`（~430 行 · 2026-04-19 22:30 · 对标 M5 `piao-drift-compute.sh` 555 行节奏 · 决议 4-A+5-A 保守组合代码路径简化 · 含 N=2 原子写入 + 跨 scope 反证 + 原子回滚 + event_id 双前缀分离 `drift-triggered-*` / `evolution-scanned-*`）|
| #3 | R1–R5 五硬约束在 MVP 实施中未被反例证伪（SMOKE 1–4 端到端） | ✅ **已达成** | `_review/m6-mvp-smoke-report @v1 published §3 R1-R5 反证矩阵` · SMOKE 1（基本通路 content_drift · 产出 sha `2b7df36fb8...` · `decision: pass_through` + `decisions: []`）· SMOKE 2（幂等性 no_change_drift · sha `050ca5602a...`）· SMOKE 3（跨 scope 拒绝 · event.subject ≠ artifact.urn · exit 1 · 无副作用）· SMOKE 4（原子回滚反证 · `head > rename` 绕开只读 journal 截断 · before/after lines 守恒 · artifact 同步删除）· R1 schema 反证 ✅ · R2 唯一触发器反证 ✅ · R3 scope 三层一致性链反证 ✅ · R4 4-A 纯观测反证 ✅ · R5 5-A 终止反证 ✅ · content_sha256 六字段白名单 `scope_kind/scope_ref/drift_event_id/drift_urn/decision/driver_event_id` 对齐 `m6_final_decisions §4.1 SHA_WHITELIST` |
| #4 | `06` 与 `01 §2.1` / `02 §2.2` / `03 §3.1` / `05 §6` 的锚点闭环声明 | ✅ **已达成** | §2.5 / §3.6 / §4.6 / §5.6 / §6.7 / §7.6 六处锚点闭环声明 · 共 42 处 TB' 引用 · `01/§2.1` ✅ 无升版 · `02 §2.2.4` 派生类型注册 ✅ 已对接（@v1.4 published · 2026-04-19 20:45 · 由 `m6_evolution_kernel_alignment@v1 S2` 驱动）· `03 §3.1` L1 事件枚举 ✅ 已对接（@v1 draft 原地精化 · 2026-04-19 20:30 · 由 `m6_evolution_kernel_alignment@v1 S1` 驱动 · 10 类枚举总数不变 · `evolution.scanned` 行按本篇 §2.3 / §5.3 实锁 schema refresh · 本篇 §2.4 B2 + §5.3 声明的外篇依赖关闭）· `05 §6` ✅ 无升版 |

**@v1.1 published 升版动作清单**（本次 commit 原地执行 · 2026-04-19 22:40）：
1. ✅ front-matter `status: draft → published` · `last_modified_at: 2026-04-19T22:40:00+08:00` · `upstream` 追加 `m6_final_decisions@v1` + `m6_mvp_smoke_report@v1` · `artifact_model` 由 `@v1.3` 升至 `@v1.4`
2. ✅ 标题从"@v1 draft · 首版 draft 收官"改为"@v1.1 published · MVP 反证收官 · R1–R5 全锁定 + 路径 A 三处 MVP 实装范围补注"
3. ✅ 首段补"@v1.1 published 定稿说明"段（含升版全路径六阶段 + 四门控达成证据 + 三处 MVP 实装范围补注锁定）
4. ✅ §8.1 rev_history 追加 `v1.1 draft 路径 A 小补注 @ 22:30` + `v1.1 published @ 22:40` 两行
5. ✅ §8.2 门控复核表追加本段（@v1.1 published 升版达成声明四条门控全 ✅）
6. ✅ §11 本篇状态行从"@v1.1 draft · 等待工具链反证"改为"**@v1.1 published · MVP 反证达成 · M6 milestone 正文本体收官**"
7. ✅ §11 下游锚点表 · `scripts/piao-evolution-scan.sh` 行从"待起稿"改为"✅ @v0.1 MVP 首版" · 追加 `_review/m6-mvp-smoke-report @v1 published` 行 · 追加 `m6_final_decisions@v1 published` 上游锚点行
8. ✅ 已发射 `artifact.published` L1 事件（kind=spec · `event_id: task-260419144000-86e9a2` · 落盘 `pipeline-output/piao/kernel-events/2026-04.jsonl` 第 14 条 · 2026-04-19 23:17 CST / 15:17 UTC 追认补发 · `reconstructed: true` · `content_sha256: c4830bb55fb453fe81dfeffdf4f359f6a16b630169a6f8da4709ce4f790b02cb` · 对标 `05 @v1.1 published` 范式 · 由 kernel-events-backfill batch 批量产出 · 详见 `_review/m6-debt-consumption.md` · **前缀字面勘误**：本文原稿 §11 + 本清单旧文"`snap-published-*`"前缀系类比 M5 drift artifact 修辞失准 · 按 `01 §5` 顶层规约 `artifact.*` 事件归入 `task` 域 · 实际落盘前缀为 `task-*` · 此前缀字面分歧登记为 `M1-debt-ledger @v8 §1.6 Q28` 续论）

### 8.3 触发升 `@v1 → @v2` 的条件（骨架阶段预声明）

- R1–R5（即 Q6.1–Q6.5 答复）任一条被实施反例证伪
- kickoff §4 五个必答问题被**新增**第六个（kernel 层引入新问题）
- `05` 或 `04` / `03` / `02` / `01` 的 kernel 锚点被升版且影响本篇引用

---

## 9. 前置契约（本篇依赖的上游 · @v1 draft 全锁定）

| 上游 | 依赖点 | 状态 |
|------|-------|------|
| `01 §1.1` URN grammar | §2 evolution URN 模板（若 Q6.1 选择 artifact 形态） | ✅ @v1.2 published |
| `01 §2.1` kind 枚举含 `evolution_source` | §2 身份字段合法性（TB'5 已锁定无需升 01） | ✅ @v1.2 published |
| `01 §5` event_id 规约 | §3 evolution 相关事件 event_id 格式 | ✅ @v1.2 published |
| `02 §1.1` artifact 五要素 | §2 evolution artifact schema（若 Q6.1 选择 artifact） | ✅ @v1.4 published |
| `02 §2.2` 派生类型注册 | §2 evolution `artifact_type` 注册路径 | ✅ @v1.4 published（路径 B S2 已反向对接 · 2026-04-19 20:45 · commit `7a7bce04`）|
| `02 §4` provenance 四元组 | §6 C3 "必须走 provenance" 契约依据 | ✅ @v1.4 published |
| `02 §6` 生命周期 | §7 evolution 生命周期对齐 | ✅ @v1.4 published |
| `03 §3.1` L1 事件枚举 | §3 / §5 若新增 `evolution.scanned` 等事件 · 属 03 升版范畴 | ✅ @v1 draft（路径 B S1 已反向对接 · 2026-04-19 20:30 · commit `76bbfff5` · 10 类枚举总数不变 · `evolution.scanned` 行按本篇 §2.3 / §5.3 实锁 schema refresh · draft 内原地修订不升 rev）|
| `03 §3.1` 双轨原则 | §6 消费接口双通道的 evidence 承载 | ✅ @v1 draft（路径 B S1 同步对接 · 2026-04-19 20:30）|
| `03 §3.3.1` 原子写入契约（N 条同 txn · M5 泛化） | §3 evolution 产出多事件场景的原子性依据 | ✅ @v1 draft（路径 B S1 同步对接 · 2026-04-19 20:30）|
| `04 §2.4` 触发判定客观性 | §3 evolution 触发客观性 | ✅ @v1.2 published |
| `04 §3.3` scope_kind 五类封板 | §4 evolution scope 继承的原始定义 | ✅ @v1.2 published |
| `05 §2` drift artifact schema | §6 详情拉取层 11 字段依赖 | ✅ @v1.1 published |
| `05 §3` drift 触发契约 | §3 evolution 订阅链路的上游触发 | ✅ @v1.1 published |
| `05 §4` drift scope 语义 | §4 三层 scope 一致性链的中间环（TB'4） | ✅ @v1.1 published |
| `05 §5` drift 归因算法 | §6 详情拉取层 `attribution[]` 消费 | ✅ @v1.1 published |
| `05 §6.1` drift → evolution 双通道 | §6 双层消费模型的直接上游（TB'3） | ✅ @v1.1 published |
| `05 §6.2` drift.detected 11 必填字段 | §6 详情拉取层 11+ 字段清单（TB'3） | ✅ @v1.1 published |
| `05 §6.3` C1–C4 前置契约 | §6.5 evolution 作为下游对 C1–C4 的继承 | ✅ @v1.1 published |
| `m6_evolution_kickoff@v1 §4` 必答五问 | §1 问题清单 + §2–§6 章节主线 | ✅ published |
| `m5-toolchain-extension-review@v1 §3` TB'1–TB'5 | §2–§6 每节工具链证据锚点（Q6.x → TB'x 映射矩阵见 §1） | ✅ published |

---

## 10. 非目标（M6 不做 · @v1 draft 边界锁定）

- **evolution 的优先级算法细节实现**（kickoff §4 非目标明列 · M6 只承诺 schema 与接口 · 实际排序由工具链侧）
- **evolution 的 UI 可视化 / dashboard**（工具链侧 · 非 kernel · 对齐 `05 §11` 非目标）
- **evolution 与外部系统对接**（IDE hook / CI 通知 / IM 推送 · 属 adapter 层范畴）
- **drift 消化的批处理策略本体**（`05 §6.4` 已明确留给 M6 但 kickoff §4 非目标明列"不必在 M6 首版 draft 一次定完 · 可留 Q6.x 续论" · 本 @v1 §4.3 仅锁定同 scope 批聚合允许边界 · 具体窗口大小/触发时机由工具链决定）
- **evolution 的优先级算法 / 排序策略**（工具链侧实施细节 · kernel 只承诺 schema 与接口）
- **evolution GC / 归档**（M7 之后 · 对齐 `05 §11` / `04 §9` · 见本 @v1 §7.4 H4）
- **evolution 跨 scope 联合扫描**（本 @v1 §4.3/§4.4 硬约束拒绝跨 scope 聚合 · 应用层需时用两次单 scope evolution）

---

## 11. 本篇状态与下游锚点（@v1.1 published · MVP 反证达成 · M6 milestone 正文本体收官）

**本篇状态**：**published @v1.1**（R1–R5 五硬约束全部锁定 · §2–§7 正文全起稿 · §8.2 四条门控全达成 · **路径 A 四条字面约束补齐已刷进**（2026-04-19 19:54 · 见 §2.3 A2 / §5.2 A3 / §6.7 A1 / §7.3 A4）· **路径 B 两条跨篇修订已反向对接**（2026-04-19 20:30 `03 @v1 draft` 原地精化 commit `76bbfff5` / 2026-04-19 20:45 `02 @v1.4 published` commit `7a7bce04` · 由 `m6_evolution_kernel_alignment@v1 §4.1 / §4.2` 驱动）· **路径 A 三处 MVP 实装范围补注已刷进**（2026-04-19 22:30 · 见 §2.3 / §5.1 / §6.2 · 对齐 `m6_final_decisions@v1 §1` 决议 4-A + 5-A · 依据 `_review/m6-mvp-smoke-report @v1 §4` 清单 · 不升 rev）· **工具链 MVP 反证达成**（2026-04-19 22:30 · `scripts/piao-evolution-scan.sh @v0.1` ~430 行 · SMOKE 1-4 冒烟全通 · 对标 M5 `piao-drift-compute.sh` 555 行节奏 · 决议 4-A+5-A 保守组合代码路径简化）· **2026-04-19 22:40 `draft → published` 封版**（同 rev 内部状态转换 · 不升 rev · 不触发 supersedes · 对标 M5 `05 @v1.1 draft → @v1.1 published` 同构范式）· **✅ 已发射** `artifact.published` L1 事件（kind=spec · `event_id: task-260419144000-86e9a2` · 2026-04-19 23:17 CST 追认补发 · `reconstructed: true` · 落盘 `pipeline-output/piao/kernel-events/2026-04.jsonl` · 详见 `_review/m6-debt-consumption.md` · 前缀字面按 `01 §5` 顶层规约用 `task-*` 而非原稿类比 M5 drift 的 `snap-published-*`·见 `M1-debt-ledger @v8 §1.6 Q28` 续论））

**上游锚点**：
- `urn:piao:proposal:kernel:m6_evolution_kickoff@v1 superseded`（本骨架触发源 · Q6.1–Q6.5 问题定义 · §4 必答五问 · 2026-04-19 21:34 `superseded_by: m6_final_decisions@v1`）
- `urn:piao:artifact:kernel:m5_toolchain_extension_review@v1 published`（§3 TB'1–TB'5 五条工具链视角强约束 · Q6.x → TB'x 映射矩阵的来源）
- `urn:piao:snapshot:kernel:m5_final_decisions@v1 published`（M5 milestone 收官快照 · 决议 1–6 矩阵 · §4 M6 入口检查清单）
- `urn:piao:spec:architecture:drift_propagation@v1.1 published`（M5 封版本体 · §6 双通道 + C1–C4 前置契约 + R1–R5 五硬约束 · 本篇 §6 直接上游）
- `urn:piao:spec:architecture:version_snapshot@v1.2 published`
- `urn:piao:spec:architecture:artifact_model@v1.4 published`（v1.1 升版 · §2.4 B3 派生类型注册已反向对接 · 2026-04-19 20:45 commit `7a7bce04`）
- `urn:piao:spec:architecture:layered_architecture@v1 draft`（v1.1 升版 · §2.4 B2 L1 事件枚举已反向对接 · 2026-04-19 20:30 commit `76bbfff5` · 10 类枚举总数不变 · draft 内原地修订）
- `urn:piao:spec:architecture:identity_model@v1.2 published`
- `urn:piao:proposal:kernel:m6_evolution_kernel_alignment@v1 published`（v1.1 升版驱动源 · 本篇 @v1 draft → @v1.1 draft 由 §4.4 S4 驱动）
- `urn:piao:snapshot:kernel:m6_final_decisions@v1 published`（**M6 milestone 收官快照 · 2026-04-19 21:34 · event_id `milestone-closeout-m6-final-decisions-v1` · §1 决议 4-A / 5-A 锁定本篇 MVP 实装范围 · 本篇 @v1.1 published 升版的契约唯一依据**）
- `urn:piao:artifact:kernel:m6_mvp_smoke_report@v1 published`（**MVP 反证证据 · 2026-04-19 22:30 · SMOKE 1-4 四场景全通 · §3 R1-R5 反证矩阵 + §4 path A 三处补注清单 · 本篇 §8.2 门控 #3/#4 达成的实施侧证据**）

**下游锚点**（已实际产出 + 待实际产出）：
- ✅ `_review/m6-evolution-draft-review.md @v1 published`（@v1 draft → published 的 review 产出 · 对标 `m5-drift-draft-review.md` 三段式 · review §3.1 路径 A 四条已消化刷进本篇 · review §3.2 路径 B 两条已由 `m6_evolution_kernel_alignment@v1` 驱动消化 · S5 追加路径 B 完成记录）
- ✅ `_review/m6-final-decisions.md @v1 published`（M6 milestone 收官快照 · 2026-04-19 21:34 · 本篇 @v1.1 published 升版的契约唯一依据 · event_id `milestone-closeout-m6-final-decisions-v1` · §1 六项决议矩阵含 4-A/5-A 锁定 · §4.1 工具链契约唯一来源 · §4.2 门控复核表 #2/#3 驱动）
- ✅ `scripts/piao-evolution-scan.sh @v0.1`（工具链承载 · 2026-04-19 22:30 首版 · ~430 行 · 对标 `piao-drift-compute.sh` 555 行节奏 · 决议 4-A+5-A 保守组合代码路径简化 · 承载 E1-E5 原子流程 §3.2 + scope 三层一致性链校验 §4 + N=2 原子写入 §3.3.1 + 双 event_id 前缀 `drift-triggered-*` / `evolution-scanned-*` 分离 §6.2 + `content_sha256` 六字段白名单 `scope_kind/scope_ref/drift_event_id/drift_urn/decision/driver_event_id`）
- ✅ `_review/m6-mvp-smoke-report.md @v1 published`（MVP 反证报告 · 2026-04-19 22:30 · SMOKE 1-4 四场景冒烟全通 · §3 R1-R5 反证矩阵 · §4 path A 三处补注清单 · 对标 M5 `_review/m5-toolchain-extension-review.md` 范式同构）
- ✅ `02 @v1.4 published`（本篇 §2.4 B3 要求在派生类型注册表补登 `evolution.scan_result` 条目 · **已消费** · 2026-04-19 20:45 · commit `7a7bce04` · 由 `m6_evolution_kernel_alignment@v1 S2 B2` 驱动 · 七字段齐全 · `wordcheck_policy=machine_generated`）
- ✅ `03 @v1 draft 原地精化`（本篇 §2.4 B2 要求 L1 事件枚举扩至十一类 · **已消费 · 但总数维持 10 类不变** · 2026-04-19 20:30 · commit `76bbfff5` · 由 `m6_evolution_kernel_alignment@v1 S1 B1` 驱动 · `evolution.scanned` 行 subject + 语义字段按本篇 §2.3 / §5.3 实锁 schema refresh · 03 整体 10 类枚举总数不变 · draft 内原地修订不升 rev · 本次升版由该 proposal §1.1 rev 升降矩阵确认"占位字段精确化"定性 · 非新增事件类型）
- ✅ `urn:piao:proposal:kernel:m6_evolution_kernel_alignment@v1 published`（路径 B 驱动源 · **已消费 · 5 commit 固化** · 承载路径 B 两条跨篇修订 · 对标 `m5_drift_kernel_alignment@v1 published` 范式）
- ⏳ **M7+ 潜在扩展**（本 rev 不承诺 · 仅预声明）：若未来 kickoff 决议放开 4-A 或 5-A 组合 · 可扩实装 §5.1 M2 / M3 产出模式 + §6.2 `pull_detail` / `dispatch` 决策态 · 仅需工具链补代码路径 · schema 无需升 rev（ABI 稳定性已由本 rev path A 三处 MVP 实装范围补注确保）

**Q6.x → TB'x 映射矩阵**（@v1 锁定状态全覆盖 · 供 draft-review 起稿直查）：

| Kickoff 问题 | 本篇章节 | 工具链锚点 | 强约束方向 | 锁定状态 |
|-------------|---------|----------|----------|--------|
| Q6.1 身份 | §2 | TB'5（`01 §2.2 evolution_source` 作输入源 kind 定稿） | 不新增核心 kind · `kind=artifact` + `artifact_type=evolution.scan_result` + L1 `evolution.scanned` 双形态 | ✅ R1 @v0.2 锁定 |
| Q6.2 触发 | §3 | TB'1（`05 §6.1` 通道 A 事件流） | 唯一触发器 = `drift.detected` · E1-E5 原子流程 · N=2+k 同 txn | ✅ R2 @v0.2 锁定 |
| Q6.3 scope | §4 | TB'4（`05 §6.2 + 04 §3.3/§5.3`） | 继承 drift 的 scope_kind + scope_ref · 三层一致性链 · 批聚合模式 A/B 允许 · C/D/E 拒绝 | ✅ R3 @v1 锁定 |
| Q6.4 决策产物 | §5 | TB'2（孤儿检测副作用开关） | 混合模型（候选 C）· 观测 + 可选决策 · `--orphan-check` 默认关闭 · 下游仅 `task.proposed` / `proposal.generated` | ✅ R4 @v1 锁定 |
| Q6.5 接口 | §6 | TB'3（`05 §6.2 + §6.1` 双通道） | 双层消费 L1(3 字段 O(1)) + L2(11+ 字段 O(N)) · F1-F4 禁止项 · C1-C4 继承 | ✅ R5 @v0.2 锁定 |

---

**@v1 守恒声明**：本 rev 在 @v0.2 三节硬核（§2/§3/§6 · R1/R2/R5）基础上展开 §4（R3 / TB'4）/ §5（R4 / TB'2）/ §7（双轨生命周期）三节 + §8.2 门控复核。正文展开严格遵循 TB'1–TB'5 字面证据 · 未引入占位范围外的推理 · R1–R5 五硬约束间无已知冲突（三层一致性链 / 客观性承诺 / append-only / provenance 全链自洽）。draft-review 阶段将在 `_review/m6-evolution-draft-review.md @v1` 对本 @v1 draft 做五问裁定 · 按 `m5-drift-draft-review` 三段式产出。
