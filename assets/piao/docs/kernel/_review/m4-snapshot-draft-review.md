---
urn: urn:piao:artifact:kernel:m4_snapshot_draft_review@v1
kind: artifact
artifact_type: report.review
rev: v1
status: published
schema_version: 1.0
created_at: 2026-04-18T23:58:00+08:00
created_by_event: task-260418155800-m4rev01
content_sha256: ""
depends_on:
  - urn: urn:piao:spec:architecture:version_snapshot@v1
    strength: strong
  - urn: urn:piao:snapshot:kernel:m1_final_decisions@v1
    strength: strong
  - urn: urn:piao:proposal:kernel:post_m1_kickoff@v1
    strength: strong
produced_by:
  actor: agent:kernel-reviewer
  task_urn: urn:piao:task:kernel/m4:snapshot_draft_review
  event_id: task-260418155800-m4rev01
wordcheck_exempt: true
---

# M4 Snapshot Model · 首版 draft 配对 review

> **定位**：对 `04-version-snapshot.md@v1 (draft)` 的配对 review。沿用阶段 2 路径 A 的三段式：
> - §1 锚点与回答质量 · §2 找不到答案的问题 · §3 对 kernel 的建议修订
>
> **和 kernel 三份 v1.1 小升的关系**：本 review 是**分支 2b 工作流 A 的首次压测**——用 M4 首版 draft 去反证 "kernel 已有契约 + v1.1 小升成果" 能否承载 snapshot 模型。若 §2 出现新 kernel 缺口，登记到 `M1-debt-ledger @v5`（届时再开账本 rev）。

---

## 1. 锚点盘点 · 回答质量

### 1.1 post-m1-kickoff §4 四问回答质量

| 问题 | 04 draft 的回答位置 | 回答质量评估 |
|-----|-----------------|------------|
| **何时打快照** | §2（三层触发 + §2.2 阶段边界契约 + §2.3 非触发点清单 + §2.4 客观性） | ✅ **充分**。L1 阶段边界为唯一强制，L2/L3 各司其职；非触发点的排除清单明确（防通胀的硬兜底） |
| **快照装什么** | §3（三方案对比 + §3.2 schema + §3.3 scope_kind + §3.4 最小示例） | ✅ **充分**。选 C 方案（URN + sha256 双轨）有明确推理，排除 A / B 的理由站得住；最小示例 < 1 KB 体现了 §6 的体积预算 |
| **快照如何寻址** | §4（URN 语义 + §4.1 scope 选用表 + §4.2 rev 升降 + §4.3 命名风格 + §4.4 反模式） | ✅ **充分**。五类 scope_kind 对应 URN 格式的对照表穷举清晰；反模式章节明确边界 |
| **快照与 drift 的接口** | §5（snapshot_diff 算子契约 + §5.1 复杂度证明 + §5.2 drift 消费姿势 + §5.3 跨 scope_kind 禁用） | ✅ **充分**。O(1) 表述的精确化澄清到位；drift 只读 diff 不改 snapshot，方向清晰 |

### 1.2 对 kernel 三件套 + v1.1 小升的锚点使用

| 被引用的 kernel 条目 | 04 的引用位置 | 引用是否准确 |
|-------------------|------------|------------|
| `01 §1.1` URN grammar | §1.1 三要素 · §4 URN 语义 | ✅ 准确 |
| `01 §2.1` snapshot kind 版本化 | §1.1 三要素 · §7.1 状态机 | ✅ 准确 |
| `01 §3.4` adapter 资产 scope（v1.1 新增） | §3.3 scope_kind=adapter · §4.1 URN 示例 | ✅ **v1.1 补丁直接被消费**，证明路径 A 有效 |
| `01 §4.4` 命名风格约定（v1.1 新增） | §4.3 命名风格 | ✅ **v1.1 补丁直接被消费** |
| `01 §10.1` published 契约 | §0 铁律 · §1.2 误解纠正 · §7.1 状态机 | ✅ 准确 |
| `02 §1.1` 五要素 front-matter | §3.2 schema | ✅ 准确 |
| `02 §3.2` URN + sha256 双轨 | §1.1 三要素 · §3.2 schema · §6.1 体积 | ✅ 准确 |
| `02 §6` artifact 生命周期 | §7.1 状态机 · §7.2 事件关系 | ✅ 准确，特化合理（snapshot 无 draft、无 retracted） |
| `03 §3.1` L1 事件类型封板 | §2.1 触发源 · §2.2 产出契约 · §7.2 事件关系 | ✅ 准确，**复用既有事件类型**是亮点（不新增 event_type） |
| `03 §3.2` L1 通用骨架 | §2.2 产出契约步骤 3 | ✅ 准确 |
| `03 §3.3` append-only 硬约束 | §7.1 状态机 | ✅ 准确 |
| `03 §6.2` 归档三条件客观性 | §2.4 触发判定客观性 | ✅ 引用风格对齐 |
| `07 §1` 边界 2 adapter 不扩 kernel 枚举 | §3.3 scope_kind 封板理由 | ✅ 准确 |
| `07 §2` 四扩展点 | §9.1 不增设新扩展点 | ✅ 准确 |

**小结**：04 draft 对 kernel 现有契约**全覆盖引用**，没有发明新术语 / 新 kind / 新事件类型；v1.1 小升的三条补丁（`01 §3.4`、`01 §4.4`、`02 §3.2` + `§6` 及相关）均被**实际使用**，验证小升决策合理。

### 1.3 设计铁律与自洽性

- ✅ **"snapshot 只做冻结，不做推断"**（§0 铁律）贯穿始终：§5 明确 drift 不是 snapshot 的触发源而是消费者
- ✅ **scope_kind 五类封板**消除了"adapter 新增 scope_kind"的诱惑（与 `07 §1` 边界 2 对齐）
- ✅ **snapshot body 字典序约束**（§3.2）是 §5 "O(N) 线性扫描"承诺的硬前提，没有"想当然"的跳步
- ✅ **体积预算 < 10 KB**（§6.1）为 snapshot 通胀风险提供了**可被工具检测的数字门槛**

---

## 2. 找不到答案的问题（**kernel 维度**）

按阶段 2 路径 A 的格式列出，每条标注严重性、在 kernel 的哪一篇需要回应、建议的 rev 升降路径。

### Q8 · 04 §2.2 "原子性"依赖的 event-journal-append 尚无 kernel 层 schema 定义

**问题**：04 §2.2 要求 "产出 snapshot artifact + 写 stage 事件 + 写 artifact.published 事件" 三步原子。但原子性的实施方在 `03 §3.3` 脚注里被一笔带过（"依赖 event-journal-append 工具保证"），**kernel 层没有对原子性进行 schema 层面的承诺或接口定义**。

**影响**：M5 drift 引擎若要信任 snapshot-diff 的结果不会因"写 snapshot 成功但 stage 事件写失败"导致 snapshot 与事件流不一致，需要 kernel 在 `03` 或本篇 `04` 里给出**原子性的判定与补偿 schema**（例如 "孤儿 snapshot 的定义 + 扫描脚本接口"）。

**严重性**：**中**（不影响 M4 draft 收敛，但 M4 工具链层做 `scripts/snapshot-produce.sh` 时必须回头定义）

**kernel 回应建议**：
- 建议在 `03-layered-architecture.md @v1.1` 补 `§3.3.1 原子写入契约`，定义：
  - `event-journal-append` 的"多事件同 txn"语义（即使 v0.1 实现为顺序写 + 失败回滚）
  - 孤儿 artifact 的判定：`artifact-validate.sh --check-orphan` 的可调用接口
- 或者 04 自己在 `§2.2` 补 "原子性的 kernel 承诺来源 → 待 03@v1.1 补充"的锚点，等 03 补完后回来升 04 @v1.1

### Q9 · 04 §3.3 scope_kind=`taskdag` 的实际触发时机未明

**问题**：04 §3.3 列出了 `scope_kind=taskdag`（触发：taskdag 完整执行完，所有终止 task 都有 `task.finished/failed`），但 `03 §3.1` 的 L1 事件封板里**没有 `taskdag.*` 事件**——既没有 `taskdag.started` 也没有 `taskdag.finished`。

**影响**：`scope_kind=taskdag` 的触发目前**无对应的 L1 事件锚点**。M4 工具链要产出 taskdag 级 snapshot，只能靠"扫描所有 task 是否都终结"——这属于**计算而非事件触发**，破坏了 §2.4 的"触发 100% 基于 L1 事件存在性"契约。

**严重性**：**中**

**kernel 回应建议**：三选一
- (a) `03 §3.1` 扩展一条 `taskdag.finished` L1 事件（破坏封板 → 需 kernel major rev）
- (b) 04 §3.3 删除 `scope_kind=taskdag`（减少一种 scope_kind，影响使用灵活度）
- (c) 04 §3.3 把 `scope_kind=taskdag` 改为**"由 stage.exited 附带 taskdag_ref 派生"**（即 taskdag 级 snapshot 由 stage 事件承载）

**推荐 (c)**：最小改动，不破坏 `03 §3.1` 封板；只需在 `stage.entered/exited` 事件 schema 中补一个可选 `related_taskdag_urn` 字段（可以在 M3 @v1.1 小升里随动）。

### Q10 · snapshot 作为 artifact 时的 `artifact_type` 未明确

**问题**：04 §3.2 给 snapshot 的 front-matter 列出了 `kind: snapshot`（来自 `01 §2.1` 核心 kind），但**没有声明 `artifact_type` 字段**——这与 `02 §1.1` 强制的五要素契约冲突（五要素里 `artifact_type` 是必填的）。

**自查**：查 `02 §2.1` 的映射表：

| URN kind | 合法的 artifact_type |
|----------|-------------------|
| `snapshot` | `snapshot` 或 `snapshot.<subtype>` |

**所以 snapshot 的 artifact_type 应填 `snapshot` 或 `snapshot.<subtype>`**，但 04 §3.2 示例的 front-matter 里**漏了这一行**。

**影响**：**低**（可在 04 内部原地修订；若 04 已 published 则需升 @v1.1）

**kernel 回应建议**：
- 04 原地补 §3.2 schema：在 `kind: snapshot` 下加一行 `artifact_type: snapshot`（或更细化的 subtype）
- 可选：`02 §2.1` 增补示范 `snapshot.stage_entered` / `snapshot.unit_frozen` 等（**本项非必需**，看后续 adapter 实践是否有统一细化需求）

### Q11 · snapshot 的 `sha256` 计算规则未定义

**问题**：04 §3.2 要求 `frozen_artifacts` 字典序排列以保证 snapshot 自身的 `content_sha256` 稳定，但**"snapshot 内容规范化后 sha256 具体怎么算"没有文字定义**——是对整个 markdown 文件 sha256？还是对 `frozen_artifacts` 段的 YAML canonical 形式 sha256？

**对比**：`02 §3.2` 对 artifact sha256 的定义也是简化的，只说"由工具写入"——相当于把规则推给工具实现。但对 snapshot 而言，**sha256 的稳定性是 `snapshot_diff` 可重复执行的前提**（同样 frozen_artifacts 必须得到同样 sha）。

**严重性**：**中**（对 M4 工具链层是硬需求）

**kernel 回应建议**：
- 建议在 04 @v1.1 补 `§3.2.1 规范化规则`：
  - snapshot 的 `content_sha256` = `sha256(canonical_yaml_of(frozen_artifacts))`，其中 canonical 规则：key 按字典序、数值无前导零、字符串统一双引号、无末尾换行
  - 即**只对 body 的 frozen_artifacts 段计算 sha**，front-matter（尤其 `produced_at` 这种每次不同的字段）**不参与**
- 或者延迟到 M4 工具链层决定；但工具层决定后必须反向升 04 @v1.1（不能让工具层裸定义跨工具契约）

### Q12 · `01 §7.2` 建议存储位置对 `scope_kind=kernel/adapter` 场景不足

**问题**：`01 §7.2` 的存储建议表里 `snapshot` → `pipeline-output/snapshots/<unit>/<snapshot_name>.json`。这个默认位置**只对 `scope_kind=unit` 友好**；对 `scope_kind=kernel`（如 `m1_final_decisions`）放在 `pipeline-output/snapshots/kernel/` 还是 `docs/piao-pipeline/kernel/_review/`？当前实际位置是后者，但 `01 §7.2` 没说。

**严重性**：**低**（04 §9.2 已识别为开放问题 #1）

**kernel 回应建议**：
- 04 已把该项列入 §9.2 开放问题，本 review 记账即可
- 若做：`01 §7.2` 升 @v1.2 扩充存储位置表，按 scope_kind 细分默认路径

### Q13 · snapshot 的 `depends_on` 是否需要记录被冻结的 artifact

**问题**：04 §3.2 用 `frozen_artifacts` 字段记录冻结范围，但**没有用 `02 §5.1` 的 `depends_on` 字段**。这两者的关系：

- `frozen_artifacts` 是**快照语义**——"这些 artifact 是我冻结的内容"
- `depends_on` 是 lineage 语义——"我在被产出时依赖这些 artifact"

理论上 snapshot 的 `depends_on` **应当等于 frozen_artifacts 的 URN 集合**（因为 snapshot 就是 depends 在这些 artifact 上的结果），但冗余存两套会有同步问题。

**影响**：**低**（04 当前选择不冗余，是合理的设计决策，但**应当显式说明**）

**kernel 回应建议**：
- 04 §3.2 补一段"为何 snapshot 不需要 `depends_on`"——frozen_artifacts 本身即担任 lineage 角色，lineage 查询器（`02 §5.3`）应能识别 snapshot 的 frozen_artifacts 作为 depends_on 的等价替身
- 对应的 `02 §5.3` 可在 @v1.2 小升里补一行"snapshot 的 lineage 接口特化"

### Q14 · "原子 snapshot + 事件" 产出时的 event_id 先后问题

**问题**：04 §2.2 产出契约三步：
```
1. snapshot artifact 写入 manifest
2. 写 stage.entered/exited 事件（entry/exit_snapshot_urn 指向步骤 1）
3. 写 artifact.published 事件标记 snapshot 发布
```

问题：步骤 1 的 snapshot front-matter 需要 `created_by_event`（即对应 artifact.published 事件的 event_id），但 artifact.published 事件在步骤 3 才写入——**步骤 1 时 event_id 还不存在**。

这是典型的"先有鸡还是先有蛋"。对普通 artifact，`02 §4.3` 的解决方案是"工具先预留 event_id，再按顺序写"——但 04 §2.2 没显式说这套机制也适用于 snapshot。

**严重性**：**低**（实施层可解，但 schema 层应锚定）

**kernel 回应建议**：
- 04 §2.2 补一小段"event_id 预留"，引用 `02 §4.3` 的 provenance 填充机制
- 或者 02 @v1.2 在 §4.3 显式点名"snapshot 产出走同样的预留流程"

---

## 3. 对 kernel 的建议修订（按路径 A/B 分类）

### 3.1 路径 A（04 自身 v1 → v1.1 小升候选）

这些修订**只改 04，不动 01/02/03/07**，属于 04 draft 定稿前的内部补齐：

| 修订 | 源自 | 操作 |
|-----|-----|------|
| R8 | Q10 | §3.2 front-matter 示例加 `artifact_type: snapshot` |
| R9 | Q11 | 新增 §3.2.1 `content_sha256` 规范化规则 |
| R10 | Q13 | §3.2 末尾加"为何 snapshot 不需要 depends_on"说明段 |
| R11 | Q14 | §2.2 补"event_id 预留"一句，引用 `02 §4.3` |

**建议处置顺序**：以上四条**在 04 draft → published 前内部 merge 完毕**（即 04 @v1 的最终形态包含这些），**不升 rev**。理由：04 仍在 draft 阶段，按 `01 §10.1` 可原地修订，升 rev 属于浪费。

### 3.2 路径 B（需要同步升降其它 kernel 文档）

这些修订涉及 `01/02/03` 的变更，需要在完成 M4 draft 后**单独开 proposal 处理**：

| 修订 | 源自 | 目标 kernel 文档 | 严重性 | 建议 rev |
|-----|-----|---------------|-------|---------|
| R12 | Q8 | `03 §3.3.1` 新增"原子写入契约" | 中 | 03 @v1.1 |
| R13 | Q9 | `03 §3.1` stage 事件加可选 `related_taskdag_urn` 字段（推荐方案 c） | 中 | 03 @v1.1 |
| R14 | Q12 | `01 §7.2` 存储位置表按 scope_kind 细分 | 低 | 01 @v1.2 |
| R15 | Q13（联动） | `02 §5.3` lineage 接口补"snapshot 特化" | 低 | 02 @v1.2 |
| R16 | Q14（联动） | `02 §4.3` 显式点名 snapshot 走预留流程 | 低 | 02 @v1.2 |

**建议打包成 `urn:piao:proposal:kernel:m4_snapshot_kernel_alignment@v1`**，在 M4 draft → published 之间或之后启动，执行方式同阶段 2 路径 A（合并小升）。

---

## 4. 小结与分支建议

### 4.1 M4 draft 成色

- 四问回答**充分**（§1.1）
- kernel 契约**全覆盖引用**，未出现新术语/新事件类型/新 kind（§1.2）
- 设计铁律（冻结 ≠ 推断 · scope_kind 封板）**自洽**（§1.3）

### 4.2 Q8–Q14 七条缺口的处置分工

- **4 条路径 A**（Q10/Q11/Q13/Q14）：04 内部原地消化，不升 rev；完成后 04 可 draft → published
- **3 条路径 B**（Q8→R12 / Q9→R13 / Q12→R14；外加 R15/R16 联动）：**统一开 `m4_snapshot_kernel_alignment@v1` proposal** 合并处理

### 4.3 分支建议

**推荐方案 · 先 A 后 B**：

```
Step 1 · 消化 R8–R11（04 内部修订）
Step 2 · 启动 m4_snapshot_kernel_alignment proposal（R12–R16）
Step 3 · proposal 执行完 → 04 因 03/01/02 升降同步升 04 @v1.1（反映 R12/R13 的 schema 调整）
Step 4 · M4 draft → published；同时 post-m1-kickoff @v1 可标 superseded（其 §4 任务已完成）
Step 5 · M5 Drift 模型起稿（下一个 milestone）
```

**备选方案 · 仅做 Step 1 先把 04 draft 收敛**：若希望快速推进 M5，可把 Step 2/3 推到与 M5 启动并行。但这会让 04 在"缺 Q8/Q9/Q12 的 kernel 锚点"状态下 draft → published，属于**带债上线**。**不推荐**，除非节奏压力显著。

> **编者注**：本节末原有的"本 review 状态"段落（记录到 §6 路径 B 完成为止）已被文末 §7 闭环后的统一状态行取代（见 §7.8 之后）。保留本节正文不动，避免历史锚点失效。

---

## 5. 路径 A 消化记录（2026-04-19 01:00）

按 §4.3 推荐方案 "先 A 后 B" 的 Step 1，R8–R11 四条已在 `04-version-snapshot.md @v1 (draft)` 内部原地 merge 完毕，**不升 rev**（按 `01 §10.1` draft 可原地修订契约）。

### 5.1 落地位置

| 修订 | 源自 | 04 落地位置 | 操作说明 |
|-----|-----|------------|---------|
| R8 | Q10 | §3.2 front-matter + §3.4 最小示例 | 两处同步加 `artifact_type: snapshot`，允许 adapter 细化为 `snapshot.<subtype>` 但需以 `snapshot.` 为前缀 |
| R9 | Q11 | **新增** §3.2.1 `content_sha256` 规范化规则 | 显式规定只对 `frozen_artifacts` 做 canonical YAML 后 SHA-256；固定五个必填 key + 字典序 + 规范化规则五步；front-matter 不参与 sha 计算 |
| R10 | Q13 | **新增** §3.2.2 为何 snapshot 不需要 `depends_on` | 声明 lineage 查询器特化：`kind: snapshot` 时 `frozen_artifacts` 充当 `depends_on` 等价替身；显式指出 R15（`02 §5.3` 升版）路径 B 处理 |
| R11 | Q14 | §2.2 代码块之后补 "event_id 预留契约" 段 | 引用 `02 §4.3` provenance 填充流程，规定工具先生成 id、再预写入 snapshot、再按 id 写事件的三步顺序 |

### 5.2 R9 与 R10 的新增小节对路径 B 的前置锚点效应

- **§3.2.1（R9 落地）** 让 M4 工具链层 `scripts/snapshot-diff.sh` / `scripts/snapshot-produce.sh` 有了可直接实施的规范化契约，不需要等路径 B
- **§3.2.2（R10 落地）** 在 `02` 升版前承担 lineage 特化的接口声明职责——**即使 02 @v1.2 尚未落地，lineage 查询器的实现方也已有锚点可查**。这是"先 A 后 B"策略的直接收益：路径 A 成果可作为路径 B 的前置契约，避免双盲

### 5.3 自检确认

- ✅ wordcheck：零新增违规（仍是 §1.1 历史 6 BAN + Q4 延期 5 WARN 基线）
- ✅ IDE 诊断：0 错误
- ✅ 章节编号自洽：§3.2 → §3.2.1 → §3.2.2 → §3.3 → §3.4 连续无跳号
- ✅ 与 §3.1 建议吻合：四条描述在 04 的落地位置与本 review §3.1 表格 100% 一致
- ✅ §9.1 已决清单增 4 条（7→10），明确标注 "路径 A · R8–R11 · 2026-04-19 消化"
- ✅ §10 rev_history 新增一行 "v1（draft · 路径 A 原地消化）" 作为变更追溯

### 5.4 遗留给路径 B 的钩子

路径 A 消化过程中产生的**路径 B 前置锚点**（在 04 内部声明但需 `02` 升版对接）：

| 04 中的锚点声明 | 需 `02 @v1.2` 补的对接 | 对应 review 修订 |
|---------------|---------------------|---------------|
| §3.2.2 "lineage 查询器遇 `kind: snapshot` 时以 frozen_artifacts 为 depends_on 等价替身" | `02 §5.3` 显式点名 snapshot 特化 | R15 |
| §2.2 "event_id 预留契约引用 `02 §4.3` provenance 流程" | `02 §4.3` 显式点名 snapshot 产出走同流程 | R16 |

两条锚点已在 04 内部自洽可实施，路径 B proposal 的作用是让 `02` 反向记录这两个特化，避免未来对 `02` 独立演进时漏改。

**路径 A 完成后的下一动作**：启动 `urn:piao:proposal:kernel:m4_snapshot_kernel_alignment@v1` proposal（R12–R16 · 涉及 03 原地修订 + 01 @v1.2 + 02 @v1.2）。

---

## 6. 路径 B 完成记录（2026-04-19 01:45）

按 §4.3 推荐方案 "先 A 后 B" 的 Step 2，R12–R16 五条已通过 `urn:piao:proposal:kernel:m4_snapshot_kernel_alignment@v1` 落地完毕。

### 6.1 处置矩阵实际落地

| 修订 | 源自 | 目标文档（实际） | 落地方式 | rev 升降 |
|-----|-----|-----------------|---------|---------|
| R12 | Q8 | `03-layered-architecture.md` | 新增 §3.3.1 原子写入契约（多事件同 txn 语义 + `--check-orphan` 接口声明） | draft 原地修订，**不升 rev** |
| R13 | Q9 | `03-layered-architecture.md` | §3.1 `stage.entered/exited` 语义字段列追加 `[related_taskdag_urn?]`；§3.2 骨架代码块后补"可选字段约定"表（显式对接 `04 §3.3 scope_kind=taskdag`） | draft 原地修订，**不升 rev** |
| R14 | Q12 | `01-identity-model.md` | §7.2 默认存储约定表的 `snapshot` 行扩为按 `scope_kind` 五类的子表；保留 `storage-policy.md` 覆盖原则 | **@v1.1 → @v1.2** |
| R15 | Q13（联动） | `02-artifact-model.md` | 新增 §5.3.1 snapshot 特化查询：`kind=snapshot` 时 `lineage_query` 以 `frozen_artifacts` 为 `depends_on` 等价替身（strong 强度） | **@v1.1 → @v1.2** |
| R16 | Q14（联动） | `02-artifact-model.md` | 新增 §4.3.1 snapshot 产出的 event_id 预留：显式点名 snapshot 复用 §4.3 既有预留流程，不发明新机制 | **@v1.1 → @v1.2** |

### 6.2 与 proposal §1.1 rev 矩阵的一致性

proposal §1.1 预判 "03 draft 不升 rev、01 升 v1.2、02 升 v1.2"，实际落地完全一致：

- 03 作为 M1 review 周期内的 draft 按 `01 §10.1` 原地修订（与路径 A · 04 的处置范式一致）
- 01 / 02 作为 published @v1.1 严格按 `01 §4.2` 补充说明类变更升次版
- 零 schema 删减、零字段类型变更、零语义反转

### 6.3 路径 A · 路径 B 的闭环对接

路径 A（04 内部）声明的 **两个前置锚点**（见 §5.4 钩子表）在路径 B 中反向对接完毕：

| 路径 A 声明位置 | 路径 B 对接位置 | 对接状态 |
|---------------|---------------|---------|
| `04 §3.2.2` "lineage 查询器遇 `kind: snapshot` 时以 frozen_artifacts 为 depends_on 等价替身" | `02 §5.3.1`（v1.2 新增） | ✅ 已对接——02 明确写出该特化规则 + 工具实施方要求 |
| `04 §2.2` "event_id 预留契约引用 `02 §4.3` provenance 流程" | `02 §4.3.1`（v1.2 新增） | ✅ 已对接——02 明确写出 snapshot 产出的三步预留流程 |

路径 A 在 04 内部单边声明的锚点不再孤立，02 升 @v1.2 后形成 **04 ↔ 02 双向可追溯**，满足"kernel 契约不留单边依赖"的健壮性要求。

### 6.4 新增的 04 → 03 锚点（R13 衍生）

除路径 A 已有的两个锚点外，本次 R13 落地新建了一条 **04 → 03 的锚点**：

- `04-version-snapshot.md §3.3 scope_kind=taskdag` 的触发实现依赖 `03 §3.1/§3.2` 中 `stage.entered/exited` 事件的可选 `related_taskdag_urn` 字段
- 该锚点在 04 @v1 → @v1.1 升版（见 §6.5 Step 3）时会在 04 §2.2 产出契约中显式引用

### 6.5 自检确认

- ✅ wordcheck：零新增违规（延续 §1.1 历史 6 BAN + Q4 延期 5 WARN 基线）
- ✅ IDE 诊断：0 错误（三份文档全绿）
- ✅ 章节编号自洽：
  - 03：§3.3 → §3.3.1 → §4 连续；§3.1 表格、§3.2 骨架自洽；篇尾新增 §10 rev_history
  - 01：§7.2 子表插入后表格结构完好；§12 rev_history 新增 v1.2 行
  - 02：§4.3 → §4.3.1 → §4.4；§5.3 → §5.3.1 → §6 连续；§11 rev_history 新增 v1.2 行
- ✅ 与 proposal §4.1–§4.5 描述 100% 对齐：五处落点位置、段落大纲与 proposal 预告完全一致
- ✅ 三份 rev_history 均指向 `urn:piao:proposal:kernel:m4_snapshot_kernel_alignment@v1` 作为 `triggered_by`

### 6.6 路径 B 完成后的下一动作

按 §4.3 推荐方案的 Step 3 推进：

1. **04 @v1 (draft) → @v1.1**：反映 R13 带来的 §2.2 产出契约微调（stage 事件的 `related_taskdag_urn` 在 scope_kind=taskdag 时必填）+ §2.2 容错段引用 `03 §3.3.1 --check-orphan` 接口 + §3.2.2/§2.2 锚点注释从"待 02 对接"改为"已由 02 @v1.2 反向对接"。这是 04 draft → published 的前置
2. **04 draft → published**（Step 4）：完成 @v1.1 升版后，04 可走 draft → published 的标准 `artifact.published` 流程
3. **`M1-debt-ledger @v5 → @v6`**：§1.2 Q8–Q14 全部标 consumed
4. **`post-m1-kickoff @v1` 标 superseded**：其 §4 的四问已被 04 回答完毕（通过 M4 首版 draft + 两轮消化）
5. **M5 Drift 模型起稿**：kernel 体系的下一 milestone

---

## 7. Step 3–5 闭环记录（2026-04-19 02:10）

按 §4.3 推荐方案的 Step 3 / Step 4 / Step 5 合并推进，M4 milestone 自此**全面收官**。本节补齐 §6.6 五条下一动作的实际落地追述。

### 7.1 Step 3 · 04 @v1 draft → @v1.1 draft（反向对接，2026-04-19 02:00）

路径 B 完成后的跨篇一致性维护升版，六处锚点/schema 微调已在 `04 §10 rev_history` v1.1 draft 行完整登载，此处不重述。关键定性：

- **rev 升降**：v1 → v1.1（**仍 draft**），按 review 明示；非"原地修订"范畴（因变更源自外部 kernel 文档升降，属跨篇一致性维护）
- **schema 骨架不变**：纯补充性小升，已产出 snapshot 实例（若有）不受影响
- **commit**：`da82e999` · +12/-9

### 7.2 Step 4 · 04 @v1.1 draft → @v1.1 published + m4_final_decisions@v1 产出（2026-04-19 02:10）

按 `04 §2.2` 产出契约的三步原子顺序执行，对应 L1 事件三连（piao-pipeline 本体采用文档级叙事 event trail，非 jsonl）：

| 事件 | 对应文档层动作 | 产出位置 |
|------|-------------|---------|
| **事件 1** · `artifact.published(snapshot:kernel:m4_final_decisions@v1)` | 产出 M4 收官快照，按 M1-final-decisions.md 范式撰写，含五项决议（四问 + 跨篇一致性结论）+ 快照产出清单 + 下一步检查清单 | `_review/m4-final-decisions.md` 新建 |
| **事件 2** · `stage.exited(stage=M4_draft_review, scope=kernel, snapshot_urn=m4_final_decisions@v1)` | review artifact（本 §7）记录"draft review 阶段退出"——`related_taskdag_urn` 字段在此处为 N/A（scope_kind=kernel 非 taskdag，见 04 §2.2 绑定规则） | 本节记录 |
| **事件 3** · `artifact.published(spec:architecture:version_snapshot@v1.1)` | 04 front-matter `status: draft → published` + 新增 `published_at` + `upstream` 追加 M4 三件套 + rev_history 新增 v1.1 published 行 + 篇尾状态行更新 | `04-version-snapshot.md` 五处同步修改 |

**原子性证据**：三个动作在同一 commit 内完成（见 §7.5）；任一失败则整批回滚（无部分产出）。

**最终快照产出清单**（见 `m4-final-decisions.md §2`）：

- `04-version-snapshot.md`：**v1.1 / published** ✅
- `03-layered-architecture.md`：v1 / draft（仍在 M1 review 周期）
- `01-identity-model.md`：v1.2 / published
- `02-artifact-model.md`：v1.2 / published
- `07-extensibility.md` / `scenario-wordlist.md`：M4 未改动，沿用既有状态

### 7.3 Step 5-1 · M1-debt-ledger @v4 → @v5（Q8–Q14 登记 + consumed）

按 review §3.1/§3.2 的 Q–R 对照，将 M4 review 过程中识别的 Q8–Q14 七条 kernel 缺口**一次性登记并标 consumed**（与 @v3→@v4 路径 A 范式一致）：

| 编号 | 源头 | R | 已落位 |
|------|------|---|--------|
| Q8 | snapshot 与 L1 事件的原子写入 | R12 | ✅ `03 draft §3.3.1`（原地修订） |
| Q9 | stage 事件如何关联 taskdag | R13 | ✅ `03 draft §3.1/§3.2`（原地修订） |
| Q10 | snapshot artifact_type 怎么写 | R8 | ✅ `04 §3.2 front-matter + §3.4`（路径 A 内部消化） |
| Q11 | content_sha256 规范化规则 | R9 | ✅ `04 §3.2.1`（路径 A 新增小节） |
| Q12 | snapshot 的存储位置怎么定 | R14 | ✅ `01@v1.2 §7.2`（按 scope_kind 五类细分） |
| Q13 | snapshot 与 lineage 的关系 | R10 + R15 | ✅ `04 §3.2.2`（路径 A）+ `02@v1.2 §5.3.1`（路径 B · lineage 特化） |
| Q14 | snapshot 的 event_id 怎么来 | R11 + R16 | ✅ `04 §2.2`（路径 A）+ `02@v1.2 §4.3.1`（路径 B · 预留流程点名） |

**debt-ledger @v5 rev_history 追加**：登记 Q8–Q14 + 全部标 consumed + 证据指向各自目标文档锚点。

**§1.1 六条 BAN 遗留状态不变**：继续延期至阶段 3 `02@v2` 清理（与 Q4 合并）。

### 7.4 Step 5-2 · post-m1-kickoff @v1 → superseded

按 post-m1-kickoff §6 "消费事件 / 关闭条件" 的契约，其关闭条件是"工作流 A 首版 draft 落地 + 工作流 B 至少两份 adapter 文档 published + M1-debt-ledger consumed"。

**现状评估**：

| 关闭条件 | 当前达成 |
|---------|---------|
| 工作流 A 首版 draft 落地 | ✅ 不仅落地，且已 published @v1.1 |
| 工作流 B 至少两份 adapter 文档 published | ⚠️ 首个 adapter 的 charter + task-types 两份 review artifact 已产出，charter 本体仍在迭代 |
| M1-debt-ledger consumed | ⚠️ §1.2 已全部 consumed（@v5），但 §1.1 六条 BAN 仍保留至阶段 3 |

**定性裁决**：工作流 A 目标（M4 snapshot 模型）已**超额达成**（不只 draft 落地而是 published），工作流 B 也已产出配套 review 证据。§1.1 BAN 遗留属于独立清理轨道，不阻断 post-m1-kickoff 的 superseded 判定（见 post-m1-kickoff §2.4 原文"阶段 3 是独立轨道，不能先做"）。

**执行动作**：post-m1-kickoff front-matter `status: published → superseded`，新增 `superseded_by: urn:piao:snapshot:kernel:m4_final_decisions@v1` + `superseded_at`。

### 7.5 Step 5-3 · M5 Drift 模型起稿

kernel 体系下一 milestone。本次 Step 5 仅产出 M5 入口骨架文档 `docs/piao-pipeline/kernel/05-drift-propagation.md`（draft @v0.1，仅含目录大纲与必答问题锚点），正式 draft 留 M5 review 周期启动后承接。

**前置契约**（已全部 published）：
- `04 §5 snapshot_diff 算子` · `04 §3.2.1 content_sha256 规范化`（drift 算法基石）
- `04 §3.3 scope_kind 五类封板`（drift 比对的边界语义）
- `02 §6 artifact 生命周期`（不删除只升 rev 的 drift 前提）

### 7.6 commit 编排

按 `01 §14` 快照即事实原则，Step 3+4+5 成果分为两个 commit：

1. **commit A**（Step 4 · M4 milestone 收官）：`_review/m4-final-decisions.md` 新建 + `04-version-snapshot.md` draft→published 同步 + 本 §7 追述
2. **commit B**（Step 5 · 债务收尾 + M5 起稿）：`M1-debt-ledger.md` @v4→@v5 + `post-m1-kickoff.md` → superseded + `05-drift-propagation.md` 骨架

### 7.7 自检确认

- ✅ wordcheck：零新增违规（延续历史基线）
- ✅ IDE 诊断：0 错误
- ✅ 04 @v1.1 published 与 draft 末态字节一致（本次 published 仅改 front-matter status / published_at / upstream 与篇尾状态行，不改正文）
- ✅ m4-final-decisions.md 与 `04 §3.2 snapshot schema` 规约自洽（front-matter 五要素齐备 + `produced_by` 三元组 + `upstream` 清单）
- ✅ Q8–Q14 七条在 debt-ledger @v5 中 100% 有对应 R 编号与落位证据
- ✅ post-m1-kickoff @v1 的 `superseded_by` 指向本 milestone 收官快照，闭合"触发 → 承载 → 超越"的三段生命周期

### 7.8 M4 milestone 关闭声明

自 2026-04-19 02:10 起，**M4 Snapshot 模型 milestone 正式关闭**。kernel 七维度中：

| 维度 | 状态 |
|------|------|
| Identity（M1） | ✅ @v1.2 published |
| Artifact（M2） | ✅ @v1.2 published（§1.1 六条 BAN 遗留至阶段 3） |
| Layering × Event（M3） | ⚠️ @v1 draft（M1 review 周期内继续） |
| **Snapshot（M4）** | ✅ **@v1.1 published（本次收官）** |
| Drift（M5） | 🚧 入口骨架已产出，正式起稿待 M5 review 启动 |
| Evolution（M6） | 🚧 依赖 M5 drift + L1 events 积累 |
| Extensibility（M7） | ✅ @v1.1 published |

---

**本 review 状态**：published（2026-04-18 23:58）· 路径 A 消化完毕（2026-04-19 01:00 追加 §5）· 路径 B 完成（2026-04-19 01:45 追加 §6）· **Step 3–5 闭环（2026-04-19 02:10 追加 §7）· M4 milestone 正式关闭**
**上游锚点**：
- `urn:piao:spec:architecture:version_snapshot@v1` （04 draft 本身，已 published @v1.1）
- `urn:piao:snapshot:kernel:m1_final_decisions@v1` （kernel 基线）
- `urn:piao:proposal:kernel:post_m1_kickoff@v1` （触发 M4 的 proposal，本次同步标 superseded）
**下游候选**：
- R8–R11 → 04 原地修订 ✅ **已 consumed（见 §5）**
- R12–R16 → `urn:piao:proposal:kernel:m4_snapshot_kernel_alignment@v1` ✅ **已 consumed（见 §6）**
- Q8–Q14 → `M1-debt-ledger @v5` ✅ **已 consumed（见 §7.3）**
- M4 milestone 收官快照 → `urn:piao:snapshot:kernel:m4_final_decisions@v1` ✅ **已产出（见 §7.2）**
- M5 drift 起稿 → `05-drift-propagation.md @v0.1 (draft)` ✅ **入口骨架（见 §7.5）**
