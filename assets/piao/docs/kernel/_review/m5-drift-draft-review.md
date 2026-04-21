---
urn: urn:piao:artifact:kernel:m5_drift_draft_review@v1
kind: artifact
artifact_type: review
rev: v1
status: draft
supersedes: null
produced_by: m5-drift-workflow-d-stage-beta-2026-04-19
produced_at: 2026-04-19T13:35:00+08:00
upstream:
  - urn:piao:spec:architecture:drift_propagation@v1
  - urn:piao:proposal:kernel:m5_drift_kickoff@v1
  - urn:piao:artifact:kernel:m4_toolchain_review@v1
  - urn:piao:artifact:kernel:m4_snapshot_draft_review@v1
  - urn:piao:spec:architecture:version_snapshot@v1.1
  - urn:piao:spec:architecture:artifact_model@v1.2
  - urn:piao:spec:architecture:layered_architecture@v1
  - urn:piao:spec:architecture:identity_model@v1.2
wordcheck_exempt: true
---

# M5 Drift Propagation Model · 首版 draft 配对 review

> **定位**：对 `05-drift-propagation.md @v1 (draft)` 的配对 review。沿用 `m4-snapshot-draft-review.md` 三段式：
>
> - §1 锚点与回答质量 · §2 找不到答案的问题 · §3 对 kernel 的建议修订
>
> **工作流定位**：本 review 是 `m5_drift_kickoff @v1 §2.3` 分支 β-2 下**工作流 D 的退出门**——用 M5 首版 draft 去反证 "kernel 已有契约 + M4 snapshot 成果 + M4 toolchain 证据" 能否承载 drift 模型。若 §2 出现需升降外篇的缺口，开 `m5_drift_kernel_alignment@v1` proposal（对标 `m4_snapshot_kernel_alignment@v1`）统一处置。
>
> **与 `m4-toolchain-review @v1` 的角色分工**：
> - `m4-toolchain-review` 从**工具链实施视角**反向提供契约证据（TB1–TB5 建议），已在阶段 α published
> - 本 review 从**契约自洽视角**正向校验 draft 的 kernel 锚点闭环与五问回答质量，阶段 β 产出
> - 两份 review 互为正反向证据链，共同支撑 05 `draft → published` 的升版决议

---

## 0. 定位

本文档回答三件事：

1. **05 draft 对 kickoff §4 Q5.1–Q5.5 五问的回答是否充分？**（§1.1）
2. **05 draft 的 kernel 锚点闭环是否真实成立？**（§1.2）即 §10 前置契约表中声明的 20 条引用，每条在源文档里都能找到对应条款
3. **05 draft 开放问题 Q1–Q5 + 新识别缺口 Q15–Q20 的处置建议是什么？**（§2 / §3）

---

## 1. 锚点盘点 · 回答质量

### 1.1 kickoff §4 Q5.1–Q5.5 五问回答质量

| 问题 | 05 draft 回答位置 | 硬约束标识 | 回答质量评估 |
|-----|----------------|----------|------------|
| **Q5.1 drift 的身份** | §2（艺术品形态 + schema + 与 snapshot 对偶） | **R1** · `kind=drift` + `artifact_type=drift.propagation_record` | ✅ **充分**。沿用 `01 §2.1` kind 封板，不发明新 kind；`02 §2.2` 派生 artifact_type 路径已走通；§2.4 对偶表让"drift 是 snapshot 差分快照的差分 artifact"身份一目了然 |
| **Q5.2 drift 的触发** | §3（唯一触发器 + 原子三步 + 非触发点清单 + 客观性 + drift_kind 枚举） | **R2** · 唯一触发器 `snapshot.published` | ✅ **充分**。§3.1 明确拒绝 `artifact.published` 作触发器（避免事件洪流）· §3.2 T1–T5 同 txn 对齐 `03 §3.3.1` · §3.3 非触发点清单闭合 · §3.5 三枚举 `drift_kind` 封板让消费方可预判 body 形态 |
| **Q5.3 drift 的 scope** | §4（R3 硬约束 + scope 继承 + 邻接语义 + 4 种拒绝变体） | **R3** · 同 scope_kind + 同 scope_ref | ✅ **充分**。完全复用 `04 §5.3` 跨 scope_kind 拒绝契约，不引入新 scope 维度；邻接语义"按 published_at 降序 + URN 字典序打破平局"可被第三方独立重算（符合 §3.4 客观性）；§4.4 拒绝变体清单把"跨 scope 联合 / 滚动窗口 / 时间切片 / drift of drift"四种诱惑一网打尽 |
| **Q5.4 drift 的归因** | §5（两模式 + 降级透明暴露 + full 模式算法 O(N·K) + 反模式清单 + 与 provenance 对偶） | **R4** · 强依赖 event-journal · 无 journal 降级 `sha_only`（透明暴露） | ✅ **充分**。`m4-toolchain-review TB1 选项 ①` 的降级路径被 §5.2 完整锚定；§5.3 归因算法用 `02 §4.1` provenance 正向 → `01 §5` event_id 唯一性 → `03 §3.1` 双轨的三层事实做反向查询，链条清晰；§5.4 反模式表（mtime / git blame / 时间邻接猜）把 `m4-toolchain-review §3.1 TB1 选项 ②` 明确拒绝的反模式全部登记 |
| **Q5.5 drift → evolution 接口** | §6（双通道 + drift.detected 11 必填字段 + M6 前置契约 C1–C4 + 非本篇承诺列表） | **R5** · 双通道（事件 + artifact）· 双 producer_event_id | ✅ **充分**。事件流通道 O(1) + artifact 拉取通道 O(N) 的组合让 M6 调度器能先筛后拉；C1–C4 把 "M6 不得做什么" 前置锁死（不得反向写入 drift / 不得自行补归因 / 必须走 provenance 链 / 不得修改 status）；§6.4 明确划定"本篇不承诺"边界，给 M6 留清晰起稿空间 |

### 1.2 20 条 kernel 锚点引用校验

对 `05 §10 前置契约` 表中声明的 20 条引用逐条校验**源文档是否存在被引用的条款**：

| # | 05 声明的锚点 | 源文档条款实际存在性 | 引用姿势 |
|---|-------------|-------------------|---------|
| 1 | `01 §1.1` URN grammar | ✅ 存在（`01-identity-model.md §1.1`） | 准确 |
| 2 | `01 §2.1` kind 枚举含 drift | ✅ 存在 · drift 是封板核心 kind | 准确 |
| 3 | `01 §5` event_id 规约 | ✅ 存在（`01 §5 事件 id 唯一性`） | 准确 |
| 4 | `02 §1.1` artifact 五要素 | ✅ 存在 | 准确（drift schema §2.3 严格对齐五要素） |
| 5 | `02 §4.1/§4.3` provenance 四元组 + 不可伪造 | ✅ 存在 | 准确（§5.3 反向查询依赖 §4.3 不可伪造） |
| 6 | `02 §5.3/§5.3.1` lineage snapshot 特化 | ✅ 存在（M4 路径 B 已新增 §5.3.1） | 准确，但**§2.5 的 drift 新特化需 02 反向对接** → Q20 |
| 7 | `02 §6` artifact 生命周期 | ✅ 存在 | 准确（§7.1 drift 状态机为 02 §6 的真子集） |
| 8 | `03 §3.1` L1 事件枚举含 drift.detected | ✅ 存在 · `drift.detected` 已在 M1 review 周期封板 | 准确 |
| 9 | `03 §3.1` 双轨原则（subject vs 语义字段） | ✅ 存在 | **引用姿势存疑** → Q16（`drifting_artifact_urn` 与 `subject` 重复） |
| 10 | `03 §3.3.1` 原子写入契约 | ✅ 存在（M4 路径 B 新增） | **引用姿势需补锚点** → Q18（03 原文只规定"snapshot + stage + artifact.published"三写，drift 引入的新"artifact.published(D) + drift.detected"同 txn 是新场景） |
| 11 | `04 §2.4` 触发判定客观性 | ✅ 存在 | 准确 |
| 12 | `04 §3.2` snapshot schema | ✅ 存在 | 准确（§2.4 对偶表完全对齐） |
| 13 | `04 §3.2.1` canonical YAML 规范化 | ✅ 存在 | **引用姿势存疑** → Q15（05 §2.5 声明"不参与 sha 的字段清单"，但 04 §3.2.1 只规定"五必填 key 参与"正向清单，未规定反向排除机制） |
| 14 | `04 §3.3` scope_kind 五类封板 | ✅ 存在 | 准确 |
| 15 | `04 §5.1` snapshot_diff 算子契约 | ✅ 存在 · 字段 `added`/`removed`/`modified`/`unchanged_count` | **命名冲突已登记** → 05 §9 Q1（`modified` vs `sha_changed`），本 review §3.1 给裁定 |
| 16 | `04 §5.3` 跨 scope_kind diff 拒绝 | ✅ 存在 | 准确 |
| 17 | `04 §6.1` snapshot 体积预算 | ✅ 存在（10 KB 单 snapshot） | 准确 · §7.2 drift 5 KB 合理小于 snapshot |
| 18 | `04 §7.1` snapshot 状态机 | ✅ 存在（draft 外部可见 / published / retracted · 无 superseded） | 准确 |
| 19 | `m5_drift_kickoff@v1 §4` 必答五问 | ✅ 存在 · published | 准确 |
| 20 | `m4-toolchain-review@v1 §3` TB1–TB5 建议 | ✅ 存在 · published | 准确 |

**小结**：20 条锚点**全部在源文档存在**，引用的**事实基础成立**；但三条引用的**姿势存在可完善空间**（Q15/Q16/Q18 · 非"锚点虚构"级缺口），已列入 §2 待处置。

### 1.3 R1–R5 五条硬约束与 TB1–TB5 的对接自洽性

| 硬约束 | 来源（`m4-toolchain-review` / `kickoff`） | 05 落位 | 自洽性 |
|-------|---------------------------------------|--------|-------|
| R1 · drift 是 artifact | `01 §2.1` 已封板 + `02 §2.2` 派生机制 | §2 全章 | ✅ 自洽 |
| R2 · 唯一触发器 `snapshot.published` | `TB2` 工具链印证（事件洪流论证） | §3.1 + §3.3 非触发点 | ✅ 自洽 |
| R3 · 同 scope_kind + 同 scope_ref | `TB3` + `04 §5.3` 继承 | §4.1 + §4.4 拒绝变体 | ✅ 自洽 |
| R4 · 归因降级透明暴露 | `TB1 选项 ①` + `m4-toolchain-review §2.3 T3`（MVP 占位符教训） | §5.1 两模式 + §5.2 降级暴露 + §5.4 反模式 | ✅ 自洽 |
| R5 · 双通道 + 双 producer_event_id | `TB4` 工具链印证（MVP diff 输出已记录两个 event_id） | §6.1 双通道 + §6.2 必填字段清单 | ✅ 自洽 |

**小结**：五条硬约束的**来源证据完备、落位章节清晰、相互不冲突**。符合 draft §0.1 声明的"修章节不修 R1–R5"的优先级设定。

### 1.4 设计铁律与自洽性

- ✅ **"drift 不是 snapshot 的高级 diff，而是差分之上的语义层"**（§0 定位）贯穿始终：§5 归因 + §6 接口是"语义层"的两条具象化路径
- ✅ **"归因强依赖 event-journal，无 journal 时不承诺归因"**（R4 / §5.2）拒绝了"用文件系统信息猜归因"的诱惑——这是 `m4-toolchain-review §3.1 TB1` 的直接落地
- ✅ **drift 状态机仅两态（published + retracted）**（§7.1）比 snapshot 还简——drift 不升 rev 的推理链条（输入 snapshot 不可变 → drift 输出内容由输入决定 → drift 无独立演进需求）清晰
- ✅ **§4.4 拒绝变体清单**把 "跨 scope 联合 / 滚动窗口 / 时间切片 / drift of drift" 四种看似合理的诱惑一一拒绝——提前堵死未来 kernel rev 升版压力

### 1.5 kickoff §2.3 分支判定复核

按 kickoff §2.3 规定：若 draft review 中出现 ≥ 3 条必须 kernel 外篇升版的缺口（路径 B），则**升级**为 β-1（04 补升）再启动工作流 D。当前 §2 发现六条（Q15–Q20），其中路径 B 类（必须升外篇的）共 **4 条**（Q15/Q16/Q18/Q20），路径 A 类（05 原地消化的）**2 条**（Q17/Q19）。

**是否触发 β-1 升级？否**。理由：

- Q15/Q16/Q18/Q20 四条路径 B 均为**补充说明 / 小升**级别（小 patch 扩表字段 / 追加小节 / 补充反向对接），**不涉及 `04/02/03` 的 schema 骨架骨变更**
- 与 M4 review 同场景对比：M4 review 路径 B 也是 5 条（R12–R16），同样未触发 "M4 draft 返工重写"，而是走统一 `m4_snapshot_kernel_alignment` proposal 处理
- 故本 review 的 4 条路径 B 建议按 `m4_snapshot_kernel_alignment` 范式，开 **`m5_drift_kernel_alignment@v1` proposal** 一次性处理

定性结论：**保持 β-2 判定不变**；05 draft 无需重写，走 "先 A 后 B" 范式走向 published。

---

## 2. 找不到答案的问题（**kernel 维度**）

按 M4 review 编号延续，本次使用 Q15–Q20（Q1–Q14 已在 M1/M4 review 消化完毕）。每条标注严重性、目标 kernel 文档、建议 rev 升降路径。

### Q15 · 05 §2.5 drift 的 `content_sha256` "不参与字段清单" 与 04 §3.2.1 正向白名单机制不一致

**问题**：05 §2.5 声明 drift 的 content_sha256 计算用**反向排除清单**（`produced_by` / `produced_at` / `event_id` / `attribution_mode` / `scope` 不参与），但 04 §3.2.1 的 canonical YAML 规范化用**正向白名单**（固定五必填 key 参与 · 字典序 · 规范化）。两套规则在语义上等价但实现路径不同：

- 04 §3.2.1 的工具实现：`pick_fields(front_matter, KEY_ORDER); canonical(); sha256()`
- 05 §2.5 的工具实现：需要两套 pick——drift body 的三列表（正向）+ front-matter 部分字段（反向 / 白名单？）

**影响**：若工具实现方不小心用"反向排除"机制，很容易漏掉某个新字段（例如未来 05 补 `priority` 字段，若不更新排除清单则该字段会意外参与 sha，破坏可重复性）。

**严重性**：**中**（对工具链层是硬需求，与 `m4-toolchain-review §2.5 T5` 的 key 正则教训同类）

**建议处置**：
- **路径 A（05 原地修订）**：改写 §2.5 为**正向白名单**机制——明确列出参与 sha 的字段（`diff_base.old_snapshot_urn` / `diff_base.new_snapshot_urn` / `added` / `removed` / `sha_changed` / `unchanged_count` 共六字段），不参与的字段靠"不在白名单即不参与"的工具逻辑自然排除
- **路径 B（04 补锚点）**：`04 §3.2.1` 补一个"canonical YAML 通用实施建议"段，供 drift 复用（与 `m4-toolchain-review §2.5 T5` 建议的 §3.2.3 附录合并）

### Q16 · 05 §6.2 `drift.detected` 事件的 `drifting_artifact_urn` 字段与 `subject` 同值，违反 `03 §3.1` 双轨原则的本意

**问题**：05 §6.2 的 `drift.detected` 事件必填字段清单含两行：

| 字段 | 语义 |
|------|-----|
| `subject` | drift artifact URN |
| `drifting_artifact_urn` | drift artifact URN · 与 subject 必须同 URN |

两字段同值。`03 §3.1` 双轨原则的本意是：

> `subject` 为事件作用的**主语**（who/what），语义字段承载**怎么样**的补充信息。

但 drift 事件里 `drifting_artifact_urn` 完全是 `subject` 的 alias，没有承载额外"怎么样"信息——属于**冗余命名**。

**影响**：消费方会疑惑"到底该读哪个字段"，未来若事件流批处理工具依据字段命名推语义（例如 `subject` 做索引 key），这种 alias 会污染索引。

**严重性**：**中**（不影响正确性但影响可维护性）

**建议处置**：
- **路径 A**：05 §6.2 去掉 `drifting_artifact_urn` 字段，明确"drift 事件的 subject 即 drift artifact URN"；`evidence` 字段已经承担了"驱动本次 drift 的两张 snapshot URN"的补充语义，足够
- **路径 B**：不动——但若保留，需在 `03 §3.1` 双轨原则段补"alias 字段允许场景"的豁免（不推荐，引入更多复杂度）

**推荐**：路径 A（去掉 alias）

### Q17 · drift artifact 的 `produced_by.event_id` 与 `drift.detected` 事件的 `event_id` 前缀规约冲突

**问题**：05 §9 Q3 已登记本问题但未裁定——

- `produced_by.event_id`：drift artifact **自己的** event_id（标识 drift 产出的 artifact.published 事件）
- `drift.detected.event_id`：**另一条** L1 事件的 id（标识 drift 被检测的事件）

若两者都用 `drift-<YYMMDDHHmmss>-<rand6>` 前缀，会造成**两条不同事件共享同一前缀格式**——语义混淆。

**对比 M4**：`04 §2.2` 的 snapshot 产出同一 txn 也写两条事件（`stage.exited` + `artifact.published`），两条事件的 `event_id` 前缀分别是 `stage-exited-<ts>-<rand>` / `snap-published-<ts>-<rand>`（见 `m4-toolchain-review §2.3 T3` MVP 占位符举例），未共享前缀。

**严重性**：**低**（05 §9 已登记为开放问题，此处给出裁定即可）

**建议处置（路径 A · 05 原地）**：
- drift artifact 的 `produced_by.event_id` 前缀 = `snap-published-<ts>-<rand>`（drift artifact 的 published 事件是"snapshot.published 驱动下的 artifact.published"的派生，沿用 snap 前缀更符合事件语义）
- `drift.detected.event_id` 前缀 = `drift-detected-<ts>-<rand>`
- 两者通过前缀明确区分，避免共享 `drift-` 裸前缀

### Q18 · 05 §3.2 T5 同 txn 的"artifact.published(D) + drift.detected"写入语义，`03 §3.3.1` 原子写入契约**未显式支持**

**问题**：`03 §3.3.1`（M4 路径 B 新增）原文规定的"多事件同 txn"场景是"snapshot 产出的三写"（artifact.published(snapshot) + stage.exited/entered + artifact.published(其他 artifact)）。05 §3.2 T5 引入的**新场景**是：

```
T5  写入 D 文件 + artifact.published(D) + drift.detected
```

这是"artifact.published + drift.detected"**两条 L1 事件同 txn 写**的组合——与 03 §3.3.1 目前的三写场景**不是子集关系**（03 假设至少有一条 stage 事件，drift 场景没有 stage 事件）。

**严重性**：**中**（工具实现方若严格按 `03 §3.3.1` 现有列举来写原子性支持，可能漏掉 drift 场景）

**建议处置（路径 B · 03 补锚点）**：
- `03 §3.3.1` 补"多事件同 txn 语义"章节，把场景从具体列举改为**通用契约**：`event-journal-append` 支持 **N 条** L1 事件同 txn 提交，N ≥ 1 · 事件间无固定 type 约束；并举例当前两种场景（snapshot 三写 / drift 两写），未来新增场景不需要改 03

### Q19 · 05 §7.3 "drift 算法 kernel rev 升降" 作为 retracted 条件与 §7.1 "drift 不升 rev" 语义张力

**问题**：05 §7.3 列出 drift artifact 可被 retracted 的三种合法场景，其中**第二条**：

> 2. **drift 算法的 kernel rev 升降**（例如 `05 @v1 → @v2` 修改了归因语义）且当前 drift 被判定不符合新语义——需在 `retracted` 事件中引用新 rev 的契约条款

但 §7.1 明确规定：

> **不引入** `superseded` 态——drift artifact **不升 rev**...如果发现 drift 算法本身有 bug → 升的是 kernel rev（本篇 §8.2），不是单条 drift 的 rev

两段文字存在**轻微张力**：

- §7.1 暗示"旧算法产出的 drift 在新算法出现后**仍保持 published**"
- §7.2 要求"不符合新语义的 drift 应 retracted"

若严格按 §7.3 执行，则每次 05 kernel rev 升版都可能触发**历史 drift 批量 retracted**——这与 `02 §6` 生命周期的"artifact 产出后一般不可回溯作废"精神有冲突。

**严重性**：**低**（极端边界场景 · 实际很少发生）

**建议处置（路径 A · 05 原地）**：
- 修 §7.3 条件 #2 的表述："drift 算法 kernel rev 升降后，**若新 rev 明确宣告旧 drift 语义失效**，触发批量 retracted；否则旧 drift 保持 published 状态（按 R1 + §7.1 语义）"
- 配套在 §7.1 补脚注："rev 升版默认不回溯作废已 published 的 drift，除非新 rev 的 `rev_history` 明确声明`retroactive_invalidation: true`"

### Q20 · 05 §2.5 drift 的 lineage "等价替身规则" 在 `02 §5.3.1` 当前定义下**属于新增特化**

**问题**：05 §2.5 声明：

> `lineage_query` 访问 drift artifact 时，把 `diff_base.old_snapshot_urn` + `diff_base.new_snapshot_urn` 视为 drift 的**等价 strong `depends_on`**

但 `02 §5.3.1`（M4 路径 B 新增）当前只定义了 **snapshot 特化**：

> `kind=snapshot` 时 `lineage_query` 以 `frozen_artifacts` 为 `depends_on` 等价替身

`kind=drift` 的等价替身规则（`diff_base` 两字段）**尚未在 02 里**。与 `m4-snapshot-draft-review §5.4 路径 A/B 前置锚点钩子`同模式——05 内部单边声明 drift 特化，但 02 需反向对接。

**严重性**：**低**（路径 A 先行、路径 B 跟进的标准范式 · 与 M4 Q13/R15 同类）

**建议处置（路径 B · 02 补锚点）**：
- `02 §5.3.1` 扩展为**通用 lineage 特化注册表**，允许 kernel 的派生 kind 注册自己的 `depends_on` 等价替身规则
- 首批注册：
  - `kind=snapshot` → `frozen_artifacts` 为等价 depends_on（M4 已有）
  - `kind=drift` → `diff_base.old_snapshot_urn` + `diff_base.new_snapshot_urn` 为等价 depends_on（本 review 新增）

---

## 3. 对 kernel 的建议修订

### 3.1 路径 A（05 自身 draft → published 前原地修订）

以下修订**只改 05，不动外篇**，属于 05 draft 定稿前的内部补齐：

| 修订 | 源自 | 05 落地位置 | 操作 |
|-----|-----|------------|------|
| R17 | Q15 | §2.5 | 将"不参与 sha 的字段清单"改写为**正向白名单**机制（列六字段） |
| R18 | Q16 | §6.2 | 去掉 `drifting_artifact_urn` 字段（与 `subject` 重复），保留 `evidence` 承载两张 snapshot URN |
| R19 | Q17 | §6.2 + §2.3（schema）+ §9 Q3 裁定 | drift artifact 的 `produced_by.event_id` 前缀 = `snap-published-*`；`drift.detected.event_id` 前缀 = `drift-detected-*`；§9 Q3 关闭 |
| R20 | Q19 | §7.1 补脚注 + §7.3 条件 #2 重写 | 默认不回溯作废；新 rev 显式声明 `retroactive_invalidation: true` 时才触发批量 retracted |

**配套裁定（05 §9 开放问题）**：

| 开放问题 | 本 review 裁定 | 落地 |
|---------|-------------|-----|
| Q1 · `modified` vs `sha_changed` 命名 | **保持 draft 方案 A**（05 body 用 `sha_changed`，04 下次补升双名兼容） | 05 §9 Q1 标 "review-accepted"；路径 B 对接 04 |
| Q2 · `sha_only` 模式下 `producer_event_id` 字段 | **保持 draft 方案（保留 + nullable）** | 05 §9 Q2 标 "review-accepted" |
| Q3 · `produced_by.event_id` 前缀 | 按 R19 裁定（**非 draft 预选的候选 A/B**，而是引入新细分） | 05 §9 Q3 标 "review-resolved"；落地即 R19 |
| Q4 · `initial_snapshot` 产出空 drift artifact | **保持 draft 方案（产出空 artifact）** | 05 §9 Q4 标 "review-accepted" |
| Q5 · drift 默认 `wordcheck_exempt` | **保持 draft 方案**（由 `02 §2.2 派生类型注册`的 `wordcheck_policy: machine_generated` 控制） | 05 §9 Q5 标 "review-accepted"；路径 B 对接 02 |

**处置顺序建议**：R17–R20 在 05 draft → published 前**内部 merge 完毕**，**不升 rev**（按 `01 §10.1` draft 可原地修订契约，与 M4 Q10/Q11/Q13/Q14 消化范式一致）。

### 3.2 路径 B（需要同步升降其他 kernel 文档）

以下修订涉及 `04/02/03` 的变更，打包成统一 proposal 处理：

| 修订 | 源自 | 目标文档 | 严重性 | 建议 rev |
|-----|-----|---------|-------|---------|
| R21 | Q15 + `m4-toolchain-review §2.5 T5`（合并） | `04-version-snapshot.md` §3.2.1 新增 `§3.2.3 canonical YAML 工具实施建议`（含 key 正则 `^[a-z_][a-z_0-9]*$` + 正向白名单 pick 规则 + drift 复用锚点） | 中 | 04 @v1.1 → @v1.2 |
| R22 | Q18 | `03-layered-architecture.md` §3.3.1 原子写入契约**泛化**为"N 条 L1 事件同 txn 提交"通用契约（snapshot 三写 / drift 两写均为实例） | 中 | 03 draft 原地修订，**不升 rev** |
| R23 | Q20 | `02-artifact-model.md` §5.3.1 扩展为**通用 lineage 特化注册表**，首批注册 `kind=snapshot` + `kind=drift` 两条规则 | 低 | 02 @v1.2 → @v1.3 |
| R24 | 05 §9 Q1 联动 | `04-version-snapshot.md` §5.1 snapshot_diff 算子字段补 `sha_changed` 作为 `modified` 的 alias，新实施用 `sha_changed`，旧 `modified` 保留向下兼容 | 低 | 04 @v1.1 → @v1.2（与 R21 合并） |
| R25 | 05 §9 Q5 联动 | `02-artifact-model.md` §2.2 派生类型注册机制补 `wordcheck_policy: machine_generated` 的语义字段，让 drift.propagation_record 等自动 exempt | 低 | 02 @v1.2 → @v1.3（与 R23 合并） |

**建议打包成 `urn:piao:proposal:kernel:m5_drift_kernel_alignment@v1`**，在 05 draft → published 之间或之后启动，执行方式同 M4 范式（先 05 路径 A 消化，再统一提 proposal 做路径 B）。

---

## 4. 小结与分支建议

### 4.1 M5 首版 draft 成色

- **五问回答充分**（§1.1）· R1–R5 五条硬约束证据完备、落位清晰、相互不冲突（§1.3）
- **kernel 锚点 20 条全部存在**（§1.2）· 引用事实基础成立；三条引用姿势（Q15/Q16/Q18）有完善空间但不构成"锚点虚构"
- **设计铁律自洽**：drift 不是 snapshot 高级 diff 而是语义层 · 归因强依赖 event-journal 拒绝文件系统猜测 · 状态机仅两态 · 拒绝变体清单堵死未来诱惑（§1.4）
- **不触发 kickoff β-1 升级**（§1.5）· 保持 β-2 判定 · 4 条路径 B 走 `m5_drift_kernel_alignment` proposal

### 4.2 Q15–Q20 六条缺口的处置分工

- **4 条路径 A**（Q15/Q16/Q17/Q19 → R17/R18/R19/R20）：05 内部原地消化，不升 rev；完成后 05 可 draft → published
- **4 条路径 B**（Q15+Q18+Q20 + 05 §9 Q1/Q5 联动 → R21/R22/R23/R24/R25）：统一开 `m5_drift_kernel_alignment@v1` proposal 处理

### 4.3 分支建议（沿用 M4 "先 A 后 B" 推荐方案）

```
Step 1 · 消化 R17–R20 + 05 §9 Q1–Q5 五条开放问题裁定（05 内部修订）
Step 2 · 启动 m5_drift_kernel_alignment@v1 proposal（R21–R25）
Step 3 · proposal 执行完 → 05 因 04/02 升降同步升 @v1.1（反映 R21/R23 的 schema 调整 + 锚点注释从"待外篇对接"改为"已反向对接"）
Step 4 · 05 draft → published；同时 `m5_drift_kickoff@v1` 保持 published（其 §3 工作流 T 阶段 α 已在 commit D 完成 · 工作流 D 阶段 β 在 Step 4 完成后可触发 superseded 判定）
Step 5 · 产出 `m5-final-decisions.md` M5 milestone 收官快照 + 实现 `scripts/piao-drift-compute.sh` 工具链（对标 M4 snapshot-produce/diff 的 MVP 范式）
Step 6 · M6 Evolution 模型起稿（下一 milestone）
```

**备选 · 仅做 Step 1**：若希望快速让 05 draft → published 以便 M6 并行起稿，可把 Step 2/3 推迟至与 M6 启动并行。但这会让 05 在"缺 R21/R22/R23 锚点"状态下 published → **带债上线**。与 M4 review §4.3 结论一致：**不推荐**除非节奏压力显著。

### 4.4 M5 published 升版门控复核（对照 05 §8.2）

05 §8.2 列出了 draft → published 的四条门控：

| 门控条件 | 本 review 后当前状态 |
|---------|------------------|
| `_review/m5-drift-draft-review.md` 产出 + 锚点完整性校验 | ✅ **本 review 产出 · 20 条锚点校验完成（见 §1.2）** |
| 至少一条**真实 drift artifact** 产出验证 schema 可实施 | ⚠️ 待 Step 5（`scripts/piao-drift-compute.sh` 产出 + 端到端验证） |
| R1–R5 五条硬约束未被实施反例证伪 | ⚠️ 待 Step 5（工具链实施过程中持续观察） |
| `_review/m5-final-decisions.md` 产出 | ⚠️ 待 Step 5 |

**定性**：本 review（门控 #1）**达成**。门控 #2/#3/#4 均待 Step 5 工具链实施完成 + final-decisions 产出后闭合。

### 4.5 与 `m4-toolchain-review` 的正反向证据链闭合

| 视角 | 产出时机 | 角色 |
|------|--------|-----|
| `m4-toolchain-review @v1`（正向推驱动契约） | 阶段 α 完成时 | 从**工具链实施视角**给出 TB1–TB5 五条契约建议，驱动 05 draft 的 R1–R5 硬约束成形 |
| `m5-drift-draft-review @v1`（反向校验契约自洽） | 阶段 β 完成时 | 从**契约自洽视角**校验 R1–R5 确实被 05 §2–§7 正确承载，并识别 Q15–Q20 六条可完善空间 |
| `m5-final-decisions @v1`（终态快照封冻） | Step 5 完成后 | 封冻 M5 milestone 所有决议，包括 R17–R25 九条修订的落地证据 |

至此 M5 milestone 的 **"工具链证据 → 契约起稿 → 契约 review → 契约 published → 工具链实装 → 终态封冻"** 闭环路径清晰。

---

## 5. 路径 A/B 消化记录（2026-04-19 14:10 / 14:45）

对标 `m4-snapshot-draft-review @v1 §5/§6` 追补范式。§5.1 简述路径 A（R17–R20）· §5.2–§5.5 详述路径 B（R21–R25 · 由 `m5_drift_kernel_alignment@v1` 驱动）。

### 5.1 路径 A 消化追述（R17–R20 · 2026-04-19 14:10）

按 §4.3 推荐方案 "先 A 后 B" 的 Step 1，R17–R20 四条已在 `05-drift-propagation.md @v1 (draft)` 内部原地 merge 完毕，**不升 rev**（按 `01 §10.1` draft 可原地修订契约 · 与 M4 路径 A · 04 处置范式一致）。

| 修订 | 源自 | 05 落地位置 | 操作说明 |
|-----|-----|------------|---------|
| R17 | Q15 | §2.5 | "不参与 sha 的字段清单" 改写为**正向白名单** · 列六字段（diff_base 两 URN + added + removed + sha_changed + unchanged_count） |
| R18 | Q16 | §6.2 | 删除 `drifting_artifact_urn` 字段 · 明确 "subject 即 drift artifact URN"· evidence 承载两张 snapshot URN |
| R19 | Q17 | §6.2 + §2.3 schema + §9 Q3 裁定 | drift artifact 的 `produced_by.event_id` 前缀 = `snap-published-*`· `drift.detected.event_id` 前缀 = `drift-detected-*`· §9 Q3 标 "review-resolved" |
| R20 | Q19 | §7.1 脚注 + §7.3 条件 #2 | 默认不回溯作废 · 新 rev 显式声明 `retroactive_invalidation: true` 时才批量 retracted |

**路径 A 遗留给路径 B 的钩子**：

- R17 声明正向白名单六字段 → 需 04 侧补"canonical YAML 通用工具实施建议"提供 pick_fields 范式 → 路径 B R21
- R17 声明 `sha_changed` 字段名 → 需 04 §5.1 补 `sha_changed` 作为 `modified` alias → 路径 B R24
- §2.5 等价替身规则 → 需 02 侧反向注册 `kind=drift` 特化 → 路径 B R23
- front-matter `wordcheck_exempt: true` → 需 02 §2.2 派生类型注册补 `wordcheck_policy` 字段 → 路径 B R25

### 5.2 路径 B 完成记录（R21–R25 · 2026-04-19 14:30–14:45）

按 §4.3 推荐方案 "先 A 后 B" 的 Step 2，R21–R25 五条已通过 `urn:piao:proposal:kernel:m5_drift_kernel_alignment@v1` 落地完毕。

### 5.3 处置矩阵实际落地

| 修订 | 源自 | 目标文档（实际） | 落地方式 | rev 升降 | commit |
|-----|-----|-----------------|---------|---------|-------|
| R22 | Q18 | `03-layered-architecture.md` | §3.3.1 原子写入契约泛化为"N 条 L1 事件同 txn（N≥1）· 无 type 约束"通用契约 · 附 N 值实例段（N=3 snapshot / N=2 drift / N=1 普通 / 未来 M6 N≥4 · 声明非 type 白名单）+ §10 rev_history 追加 v1 draft 原地修订行 | draft 原地修订，**不升 rev** | `49608733` · S1 |
| R21 | Q15 + `m4-toolchain-review §2.5 T5`（合并） | `04-version-snapshot.md` | 新增 §3.2.3 "canonical YAML 通用工具实施建议"（三承诺：key 正则 `^[a-z_][a-z_0-9]*$` + 正向白名单 `pick_fields` 伪码 + `SHA_WHITELIST` 声明范式）· 合并 `m4-toolchain-review §2.5 T5` 遗留债 · 点名 05 §2.5 为首个复用案例 | **@v1.1 → @v1.2** | `c3b8fe82` · S2 |
| R24 | 05 §9 Q1 联动 | `04-version-snapshot.md` | §5.1 字段表 `modified` 行下追加"v1.2 起新实施优先使用 `sha_changed`· `modified` 保留为向下兼容 alias · 两字段值必须同语义 · 双名至少保留两个小版本周期" | **同 @v1.2 合并** | `c3b8fe82` · S2 |
| R23 | Q20 | `02-artifact-model.md` | §5.3.1 从 "snapshot 一次性特化" 扩写为 "lineage 特化注册表"· 引入 5 列结构化表（kind / depends_on 等价替身 / 强度 / 来源 / 首设 rev）· 首批注册 `kind=snapshot`（保留）+ `kind=drift`（新增两 URN 路径）· 追加 4 条注册表规则（反向注册/特化执行位置/强度一致性/跨表一致性） | **@v1.2 → @v1.3** | `f25dc403` · S3 |
| R25 | 05 §9 Q5 联动 | `02-artifact-model.md` | 新增 §2.2.4 "派生类型注册 schema（v1.3 首次形式化）"七字段表 · 第 7 字段 `wordcheck_policy: machine_generated/content_safe_default`（可选 · 默认后者兜底）+ YAML 表达范式示例 + v1.3 兼容性承诺（既有 artifact_type 按默认值向下兼容） | **同 @v1.3 合并** | `f25dc403` · S3 |

### 5.4 与 proposal §1.1 rev 矩阵的一致性

proposal §1.1 预判 "03 draft 不升 rev、04 @v1.1→@v1.2、02 @v1.2→@v1.3、05 @v1 draft→@v1.1 draft 跟随升版"，实际落地完全一致：

- 03 作为 M1 review 周期内的 draft 按 `01 §10.1` 原地修订（与 M4 · 03 处置范式一致 · 均为 draft 原地）
- 04 / 02 作为 published 严格按 `01 §4.2` 补充说明类变更升次版（零 schema 删减、零字段类型变更、零语义反转）
- 05 作为 draft 内小升按 `01 §10.1` draft 契约（M4 · 04 @v1 draft→@v1.1 draft 先例 · 已接受范式）· **不触发 supersedes**

### 5.5 路径 A · 路径 B 的闭环对接

路径 A（05 内部）声明的**四个前置锚点**（见 §5.1 钩子列表）在路径 B 中反向对接完毕：

| 路径 A 声明位置 | 路径 B 对接位置 | 对接状态 |
|---------------|---------------|---------|
| `05 §2.5` 正向白名单六字段 + 工具实施模式 | `04 §3.2.3`（v1.2 新增 · 三承诺 · 点名 05 §2.5 复用） | ✅ 已对接——pick_fields 范式 + SHA_WHITELIST 声明模式供 drift 复用 |
| `05 §2.4 + §2.5` 使用 `sha_changed` 字段名 | `04 §5.1`（v1.2 追加 alias 注解） | ✅ 已对接——双名兼容 · 新实施优先 `sha_changed`· `modified` 保留 |
| `05 §2.5 末尾` 等价替身规则 | `02 §5.3.1`（v1.3 注册表扩写 · `kind=drift` 条目） | ✅ 已对接——02 注册表明示 drift 特化 + lineage_query 实施规则 |
| `05 front-matter` `wordcheck_exempt: true` | `02 §2.2.4`（v1.3 新增七字段 schema · `wordcheck_policy: machine_generated`） | ✅ 已对接——drift.propagation_record 可通过注册表声明自动 exempt |

路径 A 在 05 内部单边声明的四个锚点不再孤立，04 升 @v1.2 + 02 升 @v1.3 后形成 **05 ↔ 04 + 05 ↔ 02 双向可追溯**，满足"kernel 契约不留单边依赖"的健壮性要求。

### 5.6 05 跟随升版的锚点注释同步（S5 · @v1 draft → @v1.1 draft · 2026-04-19 14:45）

路径 B 完成后的跨篇一致性维护升版，六处锚点/状态同步已在 `05 §8.1 rev_history` v1.1 行完整登载（commit `d6ee71ac`），关键定性：

- **rev 升降**：v1 → v1.1（**仍 draft**）· 按 proposal §1.1 明示 · 非"原地修订"范畴（变更源自外部 kernel 文档升降，属跨篇一致性维护）
- **six touchpoints**：front-matter rev + upstream 升级 / 起稿说明段扩写 / §2.5 R23 对接注释 / §8.1 rev_history / §9 Q1&Q5 consumed 注释 / §10 前置契约表全面刷新
- **schema 骨架不变**：纯锚点注释性小升 · 未来产出 drift 实例（若有）不受影响

### 5.7 Q1/Q5 开放问题闭合

`05 §9 开放问题` 表中联动路径 B 的两条：

| 问题 | 14:45 裁定 | 闭合证据 |
|------|-----------|---------|
| Q1 · `modified` vs `sha_changed` | 已 consumed · **04 @v1.2 §5.1 双名 alias 落地** | commit `c3b8fe82`· `04 §5.1` modified 行下追加注解 |
| Q5 · drift 默认 `wordcheck_exempt` | 已 consumed · **02 @v1.3 §2.2.4 `wordcheck_policy: machine_generated` schema 落地** | commit `f25dc403`· `02 §2.2.4` 七字段表 |

05 @v1.1 draft 的 §9 两条已分别追加"已 consumed · 14:45"注释 · 等效 M4 的"review-resolved"状态。

### 5.8 自检确认

- ✅ wordcheck：零新增违规（延续 6 BAN + 5 WARN 基线 · 均在 02 既有条款 · 本次升版无新增）
- ✅ IDE 诊断：四份修订后文档各 0 错误
- ✅ 章节编号自洽：
  - 03：§3.3 → §3.3.1（泛化）→ §3.4 连续；§10 rev_history v1 draft 追述行
  - 04：§3.2.1 → **§3.2.3（新增）** → §3.3 连续（§3.2.2 既有不动）；§5.1 字段表后追加 alias 注解段；§10 rev_history v1.2 行
  - 02：§2.2.3 → **§2.2.4（新增）** → §2.3 连续；§5.3.1 扩表（首条保留 + 新增 drift 条目）；§11 rev_history v1.3 行
  - 05：front-matter rev 改 v1.1；§2.5 / §8.1 / §9 / §10 四处同步更新
- ✅ 与 proposal §4.1–§4.6 描述 100% 对齐：五处落点位置、段落大纲与 proposal 预告完全一致
- ✅ 所有 rev_history 均指向 `urn:piao:proposal:kernel:m5_drift_kernel_alignment@v1` 作为 `triggered_by`
- ✅ S0 预检通过（proposal §3 前置步 · 2026-04-19 14:25）：kernel front-matter 全部匹配 `^[a-z_][a-z_0-9]*$`· 零阻塞

### 5.9 路径 B 完成后的下一动作

按 proposal §7 下游触发的指引推进：

1. **`05-drift-propagation.md @v1.1 draft → @v1.1 published`**：走 §8.2 门控 #2/#3/#4
   - 门控 #1（本 review 产出 + 锚点完整性校验）✅ 已达成
   - 门控 #2/#3：依赖 `scripts/piao-drift-compute.sh` MVP 产出 ≥1 条真实 drift artifact（对标 M4 阶段 α `piao-snapshot-produce.sh` + `piao-snapshot-diff.sh` 范式）
   - 门控 #4：`_review/m5-final-decisions.md` 产出
2. **`M1-debt-ledger @v6 → @v7`**（如适用）：登记 Q15–Q20 六条 + R17–R25 九条 consumed 证据
3. **`m5_drift_kickoff @v1 status published → superseded`**：与 `m5-final-decisions@v1` 产出同步（与 `post-m1-kickoff @v1` 当前状态对称）
4. **下一 milestone · M6 Evolution 起稿**：由 `m6_evolution_kickoff@v1` proposal 启动（05 published + final-decisions 封冻后）

---

## 6. 本 review 状态

**本 review 状态**：draft @v1（阶段 β 工作流 D 退出门产出 · **路径 A/B 消化记录已追补（见 §5）**· 待 `scripts/piao-drift-compute.sh` MVP 产出真实 drift artifact 后可升 published · 类 m4-snapshot-draft-review @v1 追补推进节奏）

**上游锚点**：
- `urn:piao:spec:architecture:drift_propagation@v1 (draft)` · 本 review 对象 · **当前为 @v1.1 draft（见 §5.6）**
- `urn:piao:proposal:kernel:m5_drift_kickoff@v1 published` · 本 review 归属 milestone 的工作编排 proposal
- `urn:piao:proposal:kernel:m5_drift_kernel_alignment@v1 published` · **路径 B 驱动 proposal（见 §5.2–§5.6）**
- `urn:piao:artifact:kernel:m4_toolchain_review@v1 published` · 与本 review 互为正反向证据 · **§2.5 T5 已在 R21 合并 consumed**
- `urn:piao:artifact:kernel:m4_snapshot_draft_review@v1 published` · 本 review 的范式参照

**下游候选**：
- R17–R20 → 05 原地消化 ✅ **已 consumed（见 §5.1）**
- R21–R25 → `urn:piao:proposal:kernel:m5_drift_kernel_alignment@v1` ✅ **已 consumed（见 §5.2–§5.5）**
- 05 @v1 draft → @v1.1 draft ✅ **已跟随升版（见 §5.6）**
- 05 @v1.1 draft → @v1.1 published：⚠️ 待 `scripts/piao-drift-compute.sh` MVP + final-decisions（见 §5.9）
- `_review/m5-final-decisions.md`：⚠️ M5 milestone 收官快照 · 待 05 published 后产出
