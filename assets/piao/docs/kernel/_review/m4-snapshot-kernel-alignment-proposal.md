---
urn: urn:piao:proposal:kernel:m4_snapshot_kernel_alignment@v1
artifact_type: proposal.kernel_minor_upgrade
kind: proposal
rev: v1
status: published
schema_version: 1.0
created_at: 2026-04-19T01:30:00+08:00
created_by_event: manual-m4-snap-align-260419
content_sha256: ""
depends_on:
  - urn: urn:piao:artifact:kernel:m4_snapshot_draft_review@v1
    strength: strong
  - urn: urn:piao:spec:architecture:version_snapshot@v1
    strength: strong
  - urn: urn:piao:spec:architecture:layered_architecture@v1
    strength: strong
  - urn: urn:piao:artifact:kernel:identity_model@v1.1
    strength: strong
  - urn: urn:piao:artifact:kernel:artifact_model@v1.1
    strength: strong
  - urn: urn:piao:proposal:kernel:m2_kernel_minor_upgrade@v1
    strength: weak
produced_by:
  actor: human:caleb
  task_urn: urn:piao:task:kernel:m4_snapshot_kernel_alignment_planning
  event_id: manual-m4-snap-align-260419
wordcheck_exempt: true
---

# Kernel Alignment Proposal · M4 Snapshot 落地触发

> 本 proposal 是 **`m4-snapshot-draft-review.md §3.2 路径 B`** 的执行文档，沿用 **`m2-kernel-minor-upgrade-proposal.md`** 的格式与动作表范式。
> 输入：review §3.2 的 5 条路径 B 修订（R12–R16）+ 已 consumed 的路径 A 四条（R8–R11，04 draft 原地落地，见 review §5）。
> 输出：两份 published kernel 文档（`01@v1.1 → @v1.2`、`02@v1.1 → @v1.2`）的小升动作清单 + 一份 draft kernel 文档（`03@v1`）的原地修订清单。
> 完成后：M4 首版 draft 的 kernel 缺口全部闭环；`04-version-snapshot.md` 可从 draft → published（走升 rev 程序到 @v1.1 以反映 R13 带来的 schema 调整）。

---

## 1. 为什么是小升（03 原地 / 01·02 升 @v1.2）

按 `01-identity-model.md §4.2` rev 创建规则 + `01 §10.1` draft 契约综合判定，R12–R16 的处置分三类：

### 1.1 rev 升降矩阵

| 目标文档 | 当前 status | 本次处置 | rev 升降 |
|---------|-----------|---------|---------|
| `03-layered-architecture.md` | **draft** | R12（补 §3.3.1）· R13（§3.1 stage 事件加字段） | **不升 rev**（按 `01 §10.1` draft 可原地修订，沿用 `m2` 范式中 S3 的处置逻辑） |
| `01-identity-model.md` | **published @v1.1** | R14（§7.2 存储表按 scope_kind 细分） | **@v1.1 → @v1.2** |
| `02-artifact-model.md` | **published @v1.1** | R15（§5.3 lineage snapshot 特化）· R16（§4.3 snapshot 走 provenance 预留） | **@v1.1 → @v1.2** |

### 1.2 为什么不算大升

按 `01 §4.2`：

| 建议 | 变更类型 | 为什么不算大升 |
|-----|---------|-------------|
| R12（§3.3.1 原子写入契约） | 新增小节 | 03 既有 §3.3 append-only 硬约束未动；§3.3.1 是下钻说明（v0.1 阶段仅做语义承诺，实施细节留 M4 工具链） |
| R13（stage 事件加 `related_taskdag_urn`） | 字段新增（可选） | §3.1 L1 事件枚举 10 类封板未动；只给 stage 的两类事件加一个**可选**字段，不改语义字段表的必填列 |
| R14（§7.2 存储表按 scope_kind 细分） | 表格扩充 | 既有 `snapshot` 行未删，只追加细分子表；保持"默认位置"的非强制性质（§7.2 原文"不强制按这个目录放"） |
| R15（§5.3 lineage 接口补 snapshot 特化） | 补充说明 | §5.3 `lineage_query` 函数签名不变；只补"当目标 URN 的 kind=snapshot 时以 frozen_artifacts 作为 depends_on 等价替身"的行为说明 |
| R16（§4.3 snapshot 走 provenance 预留） | 补充说明 | §4.3 provenance 不可伪造的强制规则未动；只把 snapshot 显式纳入已有的"工具预留 event_id → 再按顺序写"流程 |

**零 schema 删减、零字段类型变更、零语义反转** → 小升（01/02）与 draft 原地修订（03）足矣。

### 1.3 对下游的影响

- **现有 adapter**（目前仅 `frontend-migration`）：**不需要任何改动**。R13 新增字段为**可选**；R14/R15/R16 均为读端行为补齐。
- **04-version-snapshot.md（draft）**：本 proposal 完成后，04 **需要走升 rev 程序到 @v1.1** 来反映 R13（stage 事件加 `related_taskdag_urn`）带来的 §2.2 产出契约语义微调——即 Q9 推荐方案 (c) 落地：`scope_kind=taskdag` 的 snapshot 由 stage 事件承载。详见 §7 下游触发。

---

## 2. 三文档动作矩阵（R → 文档 → 节号 → 动作）

| # | 来源 | 建议 | 目标文档 | 目标节 | 动作 |
|---|------|-----|---------|-------|------|
| 1 | Q8 / R12 | 原子写入契约 | `03-layered-architecture.md`（draft） | 新增 §3.3.1 | 补子节：`event-journal-append` 多事件同 txn 语义 + `artifact-validate.sh --check-orphan` 接口声明 |
| 2 | Q9 / R13 | stage 事件加可选字段 | `03-layered-architecture.md`（draft） | §3.1 表格 + §3.2 骨架说明 | 在 `stage.entered` / `stage.exited` 行补"可选 `related_taskdag_urn`"字段；§3.2 骨架后补一段字段语义说明 |
| 3 | Q12 / R14 | 存储表按 scope_kind 细分 | `01-identity-model.md` | §7.2 默认位置表 | 替换 `snapshot` 行为带五 scope_kind 子表；表格下方补一段补注 |
| 4 | Q13（联动）/ R15 | lineage 接口补 snapshot 特化 | `02-artifact-model.md` | §5.3 末尾 | 追加"snapshot 特化查询"段，明确 kind=snapshot 时的 depends_on 等价替身规则 |
| 5 | Q14（联动）/ R16 | §4.3 显式点名 snapshot 走预留流程 | `02-artifact-model.md` | §4.3 末尾 | 追加"snapshot 产出的 event_id 预留"段，引用 `04 §2.2` 作为调用方 |

**三文档升版总体积**：~80–100 行新增（纯补充，不删不改现有内容语义）。相比 `m2` 的 150–180 行更小，因为本次只针对 snapshot 场景做对接。

---

## 3. 执行顺序与依赖

**关键观察**：五条修订中 R12/R13 改 03；R14 改 01；R15/R16 改 02。三文档之间的依赖：

- **R13（03）→ 04**：stage 事件新增字段是 04 `scope_kind=taskdag` 语义落地的前置
- **R15（02）↔ 04 §3.2.2**：04 已声明"lineage 查询器遇 snapshot 特化"（见 review §5.4 前置锚点表），02 §5.3 反向对接
- **R16（02）↔ 04 §2.2**：04 已声明"event_id 预留引用 02 §4.3"，02 §4.3 反向对接

推荐执行顺序（基于依赖最小化 + 先 draft 后 published）：

```
(S1) 03-layered-architecture.md（draft 原地修订，不升 rev）
       │   动作 1（§3.3.1 原子写入契约）+ 动作 2（§3.1/§3.2 stage 字段）
       │
       ▼
(S2) 01-identity-model.md @v1.1 → @v1.2
       │   动作 3（§7.2 存储表细分）
       │
       ▼
(S3) 02-artifact-model.md @v1.1 → @v1.2
       │   动作 4（§5.3 snapshot 特化）+ 动作 5（§4.3 event_id 预留点名）
       │
       ▼
(S4) 两份 published 文档 rev_history 追加一行（v1.1→v1.2）+ 03 rev_history 追加一行（draft 阶段原地修订，参考路径 A 04 的范式）
       │
       ▼
(S5) review 文档追加 §6 路径 B 完成记录（对应 R12–R16 逐条 consumed 表）
       │
       ▼
(S6) 全量 wordcheck + commit
```

**回滚点**：S1 / S2 / S3 每一步都是**独立可 commit 的 git 节点**；若发现 S2 的某处补充不够可直接打补丁（仍在 `@v1.2` 同一 rev 内，因 03 是 draft、01/02 在小升窗口内允许微调，参考 `m2` §3 的回滚逻辑）。

---

## 4. 文档级精确修订锚点

### 4.1 R12 · 03 §3.3.1 新增"原子写入契约"

**落点**：紧跟 `03 §3.3 L1 append-only 的硬约束` 之后，在 `§4 事件 ID 规则` 之前。

**内容大纲**（约 30 行）：

- 动机引述（从 `04 §2.2` 的原子性要求反推 kernel 承诺层）
- **承诺 1**：`event-journal-append` 工具提供"多事件同 txn"语义——即使 v0.1 实现为顺序写 + 失败回滚，对调用方呈现为原子
- **承诺 2**：若 txn 中任一步失败，已写入的事件被标为 `retracted`（靠 `artifact.retracted` 补偿事件）；已写入的 artifact 进入"孤儿"状态
- **接口 1**：`artifact-validate.sh --check-orphan` ——扫描 `pipeline-output/` 下所有 artifact，比对 manifest 与 L1 事件，识别"写入但无对应 published 事件"的孤儿
- **kernel 不承诺的部分**：具体补偿路径（孤儿 artifact 是回收还是补写 published 事件）留 M5 drift 层或 M4 工具链层决定

### 4.2 R13 · 03 §3.1 stage 事件加可选 `related_taskdag_urn`

**落点**：`§3.1 L1 事件类型枚举` 表格的 `stage.entered` / `stage.exited` 两行；以及 `§3.2 L1 事件通用骨架` 代码块后补一段字段语义说明。

**修订动作**：

- 表格"语义字段"列在现有 `stage_urn, entry_snapshot_urn` / `stage_urn, exit_snapshot_urn, exit_reason` 后各补 `, [related_taskdag_urn?]`
- §3.2 骨架后新增一段：

  ```
  可选字段约定（R13 引入）：
  - stage.entered / stage.exited 事件允许携带 related_taskdag_urn 字段
  - 语义：该 stage 转换与某个 taskdag 的执行生命周期绑定（典型：一个 stage 对应一个 taskdag 的完整跑完）
  - 该字段是 04-version-snapshot §3.3 scope_kind=taskdag 触发的承载者（Q9 推荐方案 c）
  - 工具校验：若填写，字段值必须是合法 URN 且 kind=taskdag；kernel 不校验 taskdag 与 stage 的业务绑定关系（业务层 adapter 自行约束）
  ```

**副作用**：04 @v1 draft 中 `§3.3 scope_kind=taskdag` 条目被 R13 激活真实可行——M4 工具链可直接按 `stage.entered.related_taskdag_urn` 触发 taskdag 级 snapshot，不需要"扫所有 task 是否都终结"的计算触发。

### 4.3 R14 · 01 §7.2 存储表按 scope_kind 细分

**落点**：`§7.2 默认存储约定` 的 kind-路径表，将 `snapshot` 一行扩展为子表。

**修订动作**：

- 保留原表其它行不动
- 将 `| snapshot | pipeline-output/snapshots/<unit>/<snapshot_name>.json |` 一行替换为：

  ```
  | snapshot（按 scope_kind 细分） | 见下方子表 |
  ```

- 表格下方新增子表：

  | scope_kind | 默认位置 | 说明 |
  |----------|---------|------|
  | `unit` | `pipeline-output/snapshots/<unit>/<snapshot_name>.json` | 原默认路径 |
  | `stage` | `pipeline-output/snapshots/stages/<stage_name>/<snapshot_name>.json` | 跨 unit 的 stage 级 snapshot |
  | `taskdag` | `pipeline-output/snapshots/taskdags/<taskdag_name>/<snapshot_name>.json` | taskdag 完整执行完的冻结 |
  | `adapter` | `pipeline-output/snapshots/adapters/<adapter_name>/<snapshot_name>.json` | adapter 自治边界的冻结 |
  | `kernel` | `docs/piao-pipeline/kernel/_review/<snapshot_name>.md`（或同目录的专用子目录） | kernel 自身决策快照，当前放 `_review/`；未来可迁到 `docs/piao-pipeline/kernel/_snapshots/` |

- 子表下方补注：`kernel` scope_kind 的历史 snapshot（如 `M1-final-decisions.md`）当前位于 `_review/`，后续**可选**迁移至专用目录但不强制（保持"存储位置非 kernel 强制"的 §7.2 原则）。

### 4.4 R15 · 02 §5.3 lineage 接口补 snapshot 特化

**落点**：`§5.3 lineage 的 drift 应用` 末尾追加段落。

**修订动作**：

- 现有"查询"与"失效传播"两段保留
- 追加一段：

  ```
  ### 5.3.1 snapshot 特化（v1.2 新增）
  
  当 lineage_query 的目标 URN 的 kind=snapshot 时，查询器应用以下特化规则：
  
  - snapshot 的 front-matter 不含 depends_on 字段（见 04-version-snapshot §3.2.2 规约）
  - 查询器读取 snapshot body 中的 frozen_artifacts 列表，将其中每一条 artifact_urn 视为该 snapshot 的等价 strong depends_on
  - frozen_artifacts 条目中的 artifact_type 不参与 lineage 强度判定（即 snapshot 对被冻结 artifact 的依赖一律视为 strong）
  
  工具实现方：lineage-query.sh（M5 drift 层工具链）应在 URN kind 分支中特化 snapshot 的 depends_on 解析路径，不走默认的 front-matter 解析。
  ```

### 4.5 R16 · 02 §4.3 snapshot 走 provenance 预留流程

**落点**：`§4.3 Provenance 不可伪造` 末尾追加段落。

**修订动作**：

- 现有规则 + 工具自动填充路径保留
- 追加一段：

  ```
  ### 4.3.1 snapshot 产出的 event_id 预留（v1.2 新增）
  
  snapshot 作为 artifact 的特殊子类（kind=snapshot），其产出过程涉及"先写 snapshot、再写 stage 事件、最后写 artifact.published"的三步原子操作（见 04-version-snapshot §2.2）。第一步写 snapshot 时需要 produced_by.event_id 指向第三步才产生的 artifact.published 事件 id——这是典型的"先有鸡后有蛋"场景。
  
  snapshot 产出走与普通 artifact 完全相同的预留流程：
  - 工具在进入原子操作前先生成候选 event_id（格式见 03 §4.1 / 01 §5）
  - 将该 id 预写入 snapshot front-matter 的 produced_by.event_id（第一步）
  - 再按该预留 id 写入后续 L1 事件（第二/三步）
  - 若原子操作任一步失败，整批 id 作废，snapshot 进入"孤儿"状态（见 03 §3.3.1 原子写入契约）
  
  snapshot 不发明新的预留机制——完全复用 §4.3 已有契约，本小节仅作显式点名以避免调用方误解为 snapshot 需要特殊处理。
  ```

---

## 5. 风险与不确定性

| 风险 | 可能性 | 影响 | 缓解 |
|------|-------|-----|------|
| **R13 新增字段在未来 adapter 实践中被滥用**（stage 绑定多个 taskdag 或反过来） | 中 | 低 | 字段注释明确"kernel 不校验业务绑定关系"；后续若出现乱用场景可在 adapter 层的 `charter.md` 补强约束 |
| **R14 的 kernel scope_kind 存储路径未来需要重迁目录** | 低 | 低 | §7.2 原文即声明"不强制"；本次补注标明"未来可选迁移"，未做硬约束 |
| **R15 snapshot 特化在 lineage 查询实现方眼中与 depends_on 解析路径不一致** | 低 | 中 | 本 proposal 落地后需要在 `scripts/artifact-validate.sh` 的 v0.1 实现中加一个分支（待 M5 工具链层实施），kernel 层只承诺接口契约 |
| **R12 §3.3.1 的原子性承诺在 v0.1 JSONL 实现上做不到严格原子** | 中 | 中 | 明确标注 "v0.1 实现为顺序写 + 失败回滚"，对调用方呈现为原子但 crash 时可能遗留孤儿；`--check-orphan` 扫描是兜底 |
| **升版后三文档互相引用的锚点失效** | 低 | 高 | 引用均为节号（如 `§5.3.1`）；小升仅新增不删旧，锚点稳定（与 `m2` proposal 同风险模式） |

---

## 6. 完成条件（Definition of Done）

本 proposal 在以下所有条件全部满足后发 `proposal.implemented` 事件并归档：

- [ ] S1 落地：`03-layered-architecture.md` draft 原地修订（含 §3.3.1 + §3.1 表格 + §3.2 骨架字段说明），不升 rev（按 `01 §10.1` draft 契约）
- [ ] S2 落地：`01-identity-model.md @v1.1 → @v1.2` published（含 §7.2 scope_kind 细分子表）
- [ ] S3 落地：`02-artifact-model.md @v1.1 → @v1.2` published（含 §5.3.1 snapshot 特化 + §4.3.1 event_id 预留）
- [ ] S4 落地：两份 published 文档 rev_history 追加 v1.2 一行，指向本 proposal URN 作为 `triggered_by`；03 draft 在 §X rev_history（若有；或参考 04 的同类处理范式）追加一行 "draft 阶段原地修订 · 路径 B"
- [ ] S5 落地：`m4-snapshot-draft-review.md` 追加 §6 路径 B 完成记录（与 §5 路径 A 消化记录对称）
- [ ] `./scripts/kernel-wordcheck.sh --ci` 在 `docs/piao-pipeline/kernel/` 下返回 exit 0（BAN 违规数不增加；WARN 数不增加）
- [ ] `./scripts/kernel-wordcheck.sh --file` 对三份修订后文档各自 exit 0
- [ ] 五个路径 A 留下的前置锚点（review §5.4 的钩子表）逐一在 02 中反向对接完毕

---

## 7. 完成后的下游触发

- **`04-version-snapshot.md @v1 (draft) → @v1.1`**（**路径 B 后的下一步**）：
  - 反映 R13 带来的 §2.2 产出契约微调：snapshot 产出的步骤 2 `stage.entered/exited` 事件**明确**携带 `related_taskdag_urn`（当 scope_kind=taskdag 时必填，其它 scope_kind 可省略）
  - 反映 R12 的 §3.3.1 锚点接入：04 §2.2 的"容错"段引用 03 §3.3.1 `--check-orphan` 接口
  - 反映 R15/R16 落地后，04 §3.2.2 与 §2.2 的锚点注释从"待 02 升版对接"改为"已由 02 @v1.2 反向对接"
- **`M1-debt-ledger @v5 → @v6`**：§1.2 的 Q8–Q14 全部 consumed（对应 R8–R16 已全数处理完毕）
- **`m4-snapshot-draft-review.md` 状态更新**：§4.3 Step 2/3/4 推进——04 升 @v1.1 → M4 draft → published → `post-m1-kickoff @v1` 可标 superseded

---

## 8. 不做的事（scope out）

本 proposal **明确不包含**以下内容，避免范围蔓延（严格对齐 `m2` proposal §8 的 scope out 范式）：

| 不做的事 | 理由 |
|---------|-----|
| 新增任何 L1 事件类型 | 违反 `03 §3.1` 封板；R13 仅新增可选字段，不破坏 10 类枚举 |
| 新增任何 kind | 违反 `01 §2.1` 封板；R14 仅细分存储位置，不触达 kind 枚举 |
| 重构 `02 §4.3` provenance 强制规则 | R16 仅追加 snapshot 特化说明，不动既有规则 |
| 修改 lineage_query 函数签名 | R15 仅在查询器内部补特化分支，函数签名不变 |
| `scripts/` 下的工具实现 | 本 proposal 只承诺契约；工具实施留 M4 工具链层或 M5 drift 层 |
| 04 @v1 → @v1.1 升 rev（R8–R11 已在 draft 内部 merge） | 路径 A 已完结（见 review §5），本 proposal 不重复处理 |
| kernel scope_kind snapshot 的物理迁移（`_review/` → `_snapshots/`） | §7.2 原则即"非强制"，保持现状，后续按需 |

---

**本 proposal 状态**：published · rev v1（2026-04-19 01:30）
**上游锚点**：
- `urn:piao:artifact:kernel:m4_snapshot_draft_review@v1 §3.2`（R12–R16 来源）
- `urn:piao:spec:architecture:version_snapshot@v1 (draft @ 路径 A 消化后)`（04 前置锚点已声明）
- `urn:piao:artifact:kernel:identity_model@v1.1`（升版目标）
- `urn:piao:artifact:kernel:artifact_model@v1.1`（升版目标）
- `urn:piao:spec:architecture:layered_architecture@v1 (draft)`（原地修订目标）

**下游候选**：
- `03-layered-architecture.md`（draft 原地修订，不升 rev）
- `01-identity-model.md @v1.1 → @v1.2`
- `02-artifact-model.md @v1.1 → @v1.2`
- `m4-snapshot-draft-review.md @v1`（§6 追加路径 B 完成记录）
- `04-version-snapshot.md @v1 → @v1.1`（路径 B 完结后的下一步 · Step 3）
- `M1-debt-ledger @v5 → @v6`（Q8–Q14 全部 consumed）

**关闭候选**：`urn:piao:snapshot:kernel:m4_snapshot_kernel_alignment_complete@v1`（路径 B 完成快照，与 04 升 @v1.1 同步产出）
