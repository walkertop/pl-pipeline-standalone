---
urn: urn:piao:artifact:kernel:m6_evolution_draft_review@v1
kind: artifact
artifact_type: review
rev: v1
status: published
supersedes: null
produced_by: m6-evolution-workflow-e-stage-beta-2026-04-19
produced_at: 2026-04-19T19:40:00+08:00
last_modified_at: 2026-04-19T21:05:00+08:00
published_at: 2026-04-19T21:05:00+08:00
upstream:
  - urn:piao:spec:architecture:evolution_model@v1.1
  - urn:piao:proposal:kernel:m6_evolution_kickoff@v1
  - urn:piao:proposal:kernel:m6_evolution_kernel_alignment@v1
  - urn:piao:artifact:kernel:m5_toolchain_extension_review@v1
  - urn:piao:snapshot:kernel:m5_final_decisions@v1
  - urn:piao:artifact:kernel:m5_drift_draft_review@v1
  - urn:piao:spec:architecture:drift_propagation@v1.1
  - urn:piao:spec:architecture:version_snapshot@v1.2
  - urn:piao:spec:architecture:artifact_model@v1.3
  - urn:piao:spec:architecture:layered_architecture@v1
  - urn:piao:spec:architecture:identity_model@v1.2
wordcheck_exempt: true
---

# M6 Evolution Model · 首版 draft 配对 review

> **定位**：对 `06-evolution-model.md @v1 (draft)` 的配对 review。沿用 `m5-drift-draft-review.md` 三段式：
>
> - §1 锚点与回答质量 · §2 找不到答案的问题 · §3 对 kernel 的建议修订
>
> **工作流定位**：本 review 是 `m6_evolution_kickoff @v1 §2.3` 分支 β-2 下**工作流 E 的退出门**——用 M6 首版 draft 去反证 "kernel 已有契约 + M5 milestone 成果 + M5 toolchain 扩展证据（TB'1–TB'5）" 能否承载 evolution 模型。若 §2 出现需升降外篇的缺口，按 `m5_drift_kernel_alignment@v1` 范式开 `m6_evolution_kernel_alignment@v1` proposal 统一处置。
>
> **与 `m5-toolchain-extension-review @v1` 的角色分工**（延续 M5 范式到 M6）：
> - `m5-toolchain-extension-review` 从**工具链实施视角**反向提供契约证据（TB'1–TB'5 工具链视角强约束），已在阶段 α published
> - 本 review 从**契约自洽视角**正向校验 06 @v1 draft 的 kernel 锚点闭环与五问回答质量，阶段 β 产出
> - 两份 review 互为正反向证据链，共同支撑 06 `draft → published` 的升版决议
>
> **Q 编号规则**：m5 review 用到 Q15–Q20，本 review **从 Q21 起编号**（全局延续范式 · 不独立起编）

---

## 0. 定位

本文档回答三件事：

1. **06 @v1 draft 对 kickoff §4 Q6.1–Q6.5 五问的回答是否充分？**（§1.1）
2. **06 @v1 draft 的 kernel 锚点闭环是否真实成立？**（§1.2）即 §9 前置契约表 + §2–§7 六处锚点闭环声明中声明的 20+ 条引用，每条在源文档里都能找到对应条款
3. **06 @v1 draft 开放问题 + 新识别缺口 Q21+ 的处置建议是什么？**（§2 / §3）

---

## 1. 锚点盘点 · 回答质量

### 1.1 kickoff §4 Q6.1–Q6.5 五问回答质量

| 问题 | 06 draft 回答位置 | 硬约束标识 | 回答质量评估 |
|-----|----------------|----------|------------|
| **Q6.1 身份** | §2（双形态并存 + schema + 与 drift 范式同构反证） | **R1** · `kind=artifact` + `artifact_type=evolution.scan_result` 双形态 | ✅ **充分**。§2.2 范式同构反证直接复用 `05 §2.2` drift 双形态四理由（体积预算 / provenance 锚点 / O(1) 扫描 / 生命周期独立），逐条在 evolution 侧复现——该反证链是 draft 最硬的论证骨架。§2.4 B3/B4 显式承认本决议对 02 @v1.4 派生类型注册表的增量依赖，边界透明 |
| **Q6.2 触发** | §3（唯一触发器 `drift.detected` + E1–E5 原子流程 + 订阅链三层同构 + 反证为什么不订阅 artifact.published） | **R2** · 唯一触发器 `drift.detected` L1 事件（通道 A） | ✅ **充分**。§3.1 订阅链三层同构 `snapshot.published → drift / drift.detected → evolution` 是 kernel 层该范式的**第三次复用**——范式一致性强；§3.5 反证"为什么不能订阅 artifact.published"用四步推理封死替代方案（过滤责任下推 / 字段缺失 / O(1) 退化 / 分层崩塌），堵死诱惑；§3.4 降级策略覆盖四场景（读 journal 失败 / 拉 artifact 失败 / E5 原子写失败 / 手动补救）且明确"不反向改 drift 状态"（C1 契约） |
| **Q6.3 scope** | §4（R3 硬约束 + 三层一致性链 L0/L1/L2 + 批聚合 A/B 允许 · C/D/E 拒绝 + 拒绝列表五条 + 客观性守恒） | **R3** · scope 完全继承 drift（= 继承 snapshot） | ✅ **充分**。§4.2 三层一致性链（snapshot `04 §3.3` / drift `05 §4` / evolution 本节）用表格直观呈现 scope 字段在三层间**字面传递无需重计算**——这是 TB'4 最直接的落地；§4.3 批聚合模式 A/B 允许 + C/D/E 拒绝的五模式矩阵把"跨 scope_kind / 跨 scope_ref / 滚动窗口"三种诱惑一网打尽；§4.4 拒绝列表五条直接同构 `05 §4.4` drift 的四拒绝，额外新增"evolution 跨 snapshot 重计算 / evolution 跨 rev 聚合" |
| **Q6.4 决策产物** | §5（混合模型候选 C + 产出模式矩阵 M1/M2/M3 + orphan_check 副作用开关 schema + 决策事件枚举 + 禁止产出事件 + G1-G5 产出禁止项） | **R4** · 观测基础层恒定 + 决策扩展层按需 | ✅ **充分**。§5.1 显式拒绝候选 A（纯观测独占 → C3 provenance 链断裂）和候选 B（纯决策独占 → 扫过不行动无痕迹），论证为什么必须混合；§5.3 产出事件表 + 禁止产出事件表（`task.started`/`task.completed` / 非自身 `artifact.published` / `snapshot.published` / `drift.detected` / `retracted.*` 五类）把 evolution 的"产出边界"硬边界化；§5.4 G1–G5 产出禁止项与 §6.4 F1–F4 消费禁止项形成**产出侧 ∥ 消费侧**对偶禁止，职责切分清晰 |
| **Q6.5 接口** | §6（双层消费 L1/L2 · 3 字段 O(1) + 11+ 字段 O(N) · F1-F4 禁止项 · C1-C4 前置契约全继承 · 下游事件类型锁定） | **R5** · 双层消费（L1 O(1) + L2 O(N)） | ✅ **充分**。§6.2/§6.3 L1 读 3 字段 + L2 读 11+ 字段双层表格化，每字段标注"来源" + "决策语义"/"消费语义"，可直接作为工具链实施参考；§6.5 C1–C4 前置契约继承表逐条对接 `05 §6.3` 原文 + 本节继承点 + 实装证据，三列格式与 M5 "反向对接锚点" 范式同构；§6.4 F1 "禁止绕过事件流直读 artifact 目录" 由 TB'3 + `m5_final_decisions §1 决议 5` 双证据锚定；§6.6 下游接口"evolution 作为决策终点"边界明确（不预设 M7/M8） |

**小结**：五问回答**全部充分**。相较 M5 draft-review 的"五问回答充分 + 三条姿势存疑（Q15/Q16/Q18）"，M6 @v1 draft 的五问回答**更成熟**——这是因为 M6 站在 M4 snapshot + M5 drift 两层已封板契约的肩膀上，可直接复用成熟范式（双形态 / 双通道 / 三层订阅链 / 拒绝列表 / C1-C4 继承），论证密度与自洽性显著高于 M5。

### 1.2 kernel 锚点引用校验（20+ 处 · 逐条核查）

对 `06 §9 前置契约` 表 + `§2.5 / §3.6 / §4.6 / §5.6 / §6.7 / §7.6` 六处锚点闭环声明中声明的 20+ 条引用逐条校验**源文档是否存在被引用的条款**：

| # | 06 声明的锚点 | 源文档条款实际存在性 | 引用姿势 |
|---|-------------|-------------------|---------|
| 1 | `01 §1.1` URN grammar | ✅ 存在（`01-identity-model.md §1.1`） | 准确 |
| 2 | `01 §2.1` kind 枚举含 `evolution_source` | ✅ 存在（`01 §2.1/§2.2` line 87，M1 review 已封板） | 准确（TB'5 字面引用） |
| 3 | `01 §5` event_id 规约 | ✅ 存在 | 准确 |
| 4 | `02 §1.1` artifact 五要素 | ✅ 存在 | 准确（§2.3 evolution schema 与五要素对齐） |
| 5 | `02 §2.2` 派生类型注册 | ✅ 存在（v1.3 published · 见 m5 drift review 路径 B R25 落地） | 准确（§2.4 B3 明示对 `02 @v1.4` 的增量依赖）|
| 6 | `02 §2.2.4` 派生类型注册 schema（v1.3 新增七字段）| ✅ 存在（line 193，含 `wordcheck_policy: machine_generated`）| 准确（§2.4 B3 要求补登 `evolution.scan_result` 条目）|
| 7 | `02 §4` provenance 四元组 | ✅ 存在（`02 §4.1/§4.3` @v1.3 published）| 准确（§6.5 C3 继承依据）|
| 8 | `02 §6` artifact 生命周期 | ✅ 存在 | 准确（§7.1 轨 A `draft → published → retracted` 与 02 §6 子集对齐）|
| 9 | `03 §3.1` L1 事件枚举（十类） | ✅ 存在 | **引用姿势需补锚点** → Q21（06 §5.3 声明 `evolution.scanned` 新增为十一类 · 但 03 当前仍为十类 · 需 03 小升）|
| 10 | `03 §3.1` 双轨原则 | ✅ 存在 | 准确 |
| 11 | `03 §3.3` append-only | ✅ 存在 | 准确（§7.1 轨 B 依据）|
| 12 | `03 §3.3.1` 原子写入契约（N 条同 txn · M5 泛化）| ✅ 存在（`03 §3.3.1` line 173，M5 路径 B R22 已泛化为"N 条 L1 事件同 txn · N ≥ 1 · 无固定 type 约束"）| 准确（§3.2 E5 的 `N=2+k` 是该泛化契约的合法子集 · M5 泛化的直接受益者）|
| 13 | `04 §2.4` 触发判定客观性 | ✅ 存在 | 准确（§3.3 客观性承诺字面继承）|
| 14 | `04 §3.3` scope_kind 五类封板 | ✅ 存在 | 准确（§4.2 L0 层依据 · §4.5 B3 "不新增枚举值"承诺）|
| 15 | `04 §5.3` 跨 scope_kind diff 拒绝 | ✅ 存在 | 准确（§4.2 三层一致性链 L0 层依据）|
| 16 | `04 §6.1` snapshot 体积预算 | ✅ 存在 | 准确（§7.2 范式继承）|
| 17 | `04 §6.2` snapshot 通胀是最大设计风险 | ✅ 存在 | 准确（§7.4 H1-H4 同构）|
| 18 | `04 §7.1` snapshot 状态机 | ✅ 存在 | 准确（§7.1 轨 A 同构）|
| 19 | `05 §2` drift artifact schema | ✅ 存在（`05 §2.2/§2.3` @v1.1 published）| 准确（§2 双形态同构反证依据 · §6.3 L2 字段表引用）|
| 20 | `05 §3` drift 触发契约 | ✅ 存在 | 准确（§3 订阅链上游依据）|
| 21 | `05 §4.1/§4.2` drift R3 + scope 继承 | ✅ 存在 | 准确（§4.1 R3 继承三层链 L1 层）|
| 22 | `05 §4.4` drift 拒绝列表 | ✅ 存在 | 准确（§4.4 五条范式同构扩展）|
| 23 | `05 §5.3` 归因三元组 | ✅ 存在（`05 §5.3` line 358，@v1.1 published）| 准确（§6.3 L2 字段 7–10 引用）|
| 24 | `05 §6.1` 双通道设计 · 通道 A | ✅ 存在 | 准确（§3.1 R2 直接依据 + §6.1 R5 依据）|
| 25 | `05 §6.2` `drift.detected` 11 必填字段 | ✅ 存在 | 准确（§6.2 L1 读 3 字段是 11 字段子集 · §6.3 L2 读 11+ 字段）|
| 26 | `05 §6.3` C1–C4 前置契约 | ✅ 存在（`05 §6.3` line 456，四条字面对齐）| 准确（§6.5 继承表逐条对接 · C1/C2/C3/C4 全承诺）|
| 27 | `05 §7.1` drift artifact 不升 rev | ✅ 存在 | 准确（§7.1 轨 A 范式同构 + §7.3 条件 #2 "默认不回溯作废"脚注继承）|
| 28 | `05 §7.2/§7.3/§7.4` drift 生命周期全套 | ✅ 存在 | 准确（§7.1–§7.4 字面复用）|
| 29 | `m5_final_decisions §1 决议 5` | ✅ 存在 · published | 准确（§6.4 F1 "禁止绕过事件流直读 artifact 目录" 直接引用）|
| 30 | `m5-toolchain-extension-review @v1 §3` TB'1–TB'5 | ✅ 五条全部存在（§3.1 TB'1 / §3.2 TB'2 / §3.3 TB'3 / §3.4 TB'4 / §3.5 TB'5） | 准确（§2-§6 每节工具链证据锚点 · Q6.x → TB'x 映射矩阵 §11 末完整覆盖）|
| 31 | `m5-toolchain-extension-review §2 T'1` 长期建议（evolution 兼任孤儿检测）| ✅ 存在 | 准确（§5.1/§5.2 TB'2 复用论证字面继承）|
| 32 | `m5-toolchain-extension-review §2 T'3` 时间戳 UTC 统一 | ✅ 存在 | 准确（§6.5 C2 佐证）|
| 33 | `m5-toolchain-extension-review §2 T'4` 多进程并发补注 | ✅ 存在 | 准确（§3.4 降级策略覆盖）|
| 34 | `m6_evolution_kickoff@v1 §4` 必答五问 | ✅ 存在 · published | 准确 |

**小结**：34 条锚点**全部在源文档存在**，引用的**事实基础成立**；唯一一条引用姿势需补锚点的是 **#9（`03 §3.1` L1 事件十类 → 需扩为十一类）**，已被 06 draft 内部透明声明（§2.4 B2 + §5.3 + §8.2 门控 #4 明示），非"锚点虚构"级缺口，已列入 §2 Q21 处置。

### 1.3 R1–R5 五条硬约束与 TB'1–TB'5 的对接自洽性

| 硬约束 | 工具链证据来源 | 06 落位章节 | 自洽性 |
|-------|-------------|-----------|-------|
| R1 · 双形态并存 | TB'5（`01 §2.2 evolution_source` 作输入源 kind 定稿 · 不参与产出决议） | §2 全章 · 重点 §2.2 范式同构反证 | ✅ 自洽（TB'5 仅明示"evolution_source 已定稿 · 身份层无补充建议"· R1 从 drift 范式反证推导 · 两者不冲突）|
| R2 · 唯一触发器 `drift.detected` | TB'1（`drift.detected` 事件 5 字段足以让 evolution 做 O(1) 决策） | §3.1 R2 + §3.5 反证 | ✅ 自洽（TB'1 G3/G4 实测证实 5 字段承载力 · R2 E1-E5 E2 步骤读 5 字段的 3 字段子集 · 自洽且留扩展空间）|
| R3 · scope 完全继承 drift | TB'4（drift scope 完全继承两 snapshot · 扩展实施未引入新 scope 维度 · 建议 `06 §X` 直接规定 scope 继承） | §4 全章 · 重点 §4.1 R3 字面引用 + §4.2 三层一致性链 | ✅ 自洽（TB'4 原文直接指向"06 §X 规定 scope 继承"· R3 完全兑现该建议 · 三层一致性链是 TB'4 的结构化呈现）|
| R4 · 混合模型（候选 C）· `--orphan-check` 副作用开关 | TB'2（evolution 扫描器可兼任孤儿检测 · 长期建议 T'1 提取为独立 MVP 留给 M7+） | §5 全章 · 重点 §5.1 TB'2 字面引用 + §5.2 orphan_check schema | ✅ 自洽（TB'2 明示"副作用开关 + 默认关闭 + 主动开启时输出 orphan 清单" · R4 §5.2 字面兑现 schema · R4 拒绝候选 A（纯观测）/候选 B（纯决策）的反证链完整）|
| R5 · 双层消费（L1 3 字段 + L2 11+ 字段） | TB'3（`3 字段优先 + 11 字段兜底`双层 · 禁止绕过事件流直读 artifact） | §6 全章 · 重点 §6.1-§6.3 双层表 + §6.4 F1 禁止项 | ✅ 自洽（TB'3 G1 实测证实 11 字段承载力 · G3/G4 证实 5 字段承载力 · R5 直接兑现双层模型 · F1 "禁止绕过事件流" 与 `m5_final_decisions §1 决议 5` 双证据锚定）|

**小结**：五条硬约束的**来源证据完备、落位章节清晰、相互不冲突**，与 TB'1–TB'5 对接**字面一致**。符合 draft §0.1 声明的 "R1–R5 全部锁定" 的门控设定。

**Q6.x → TB'x 映射矩阵回扣**（06 §11 末完整列出）：

```
Q6.1 身份 → TB'5 → R1 双形态并存（@v0.2 锁定）
Q6.2 触发 → TB'1 → R2 唯一触发器 drift.detected（@v0.2 锁定）
Q6.3 scope → TB'4 → R3 完全继承 drift scope（@v1 锁定）
Q6.4 决策产物 → TB'2 → R4 混合模型候选 C（@v1 锁定）
Q6.5 接口 → TB'3 → R5 双层消费 L1/L2（@v0.2 锁定）
```

该矩阵在 06 @v1 draft 首部说明段、§0.1 设计取舍表、§11 末全覆盖，三处表达一致——符合 M4/M5 review 对"硬约束 ↔ 证据锚点"的可追溯性要求。

### 1.4 设计铁律与自洽性

- ✅ **"evolution 不是 drift 的高级消费 · 而是在接口之上的决策层"**（§0 定位）贯穿始终：§5 决策产物 + §6 接口是"决策层"的两条具象化路径
- ✅ **"唯一触发器 `drift.detected`" + 订阅链三层同构**（R2 / §3.1）是 M4→M5→M6 范式的**第三次复用**——kernel 层事件流分层契约的自然推论，而非 M6 的发明
- ✅ **"混合产物形态（候选 C）"**（R4 / §5.1）通过反证拒绝候选 A（纯观测 · C3 provenance 链断裂）+ 候选 B（纯决策 · 扫过不行动无痕迹），论证链条闭合
- ✅ **双形态 artifact 两态（published + retracted · 不引入 superseded）**（§7.1）比 drift 更简——evolution 不升 rev 的推理链条（单次扫描客观产物 → 算法 rev 升级由 kernel 承载 → 单条 scan_result 无独立演进需求）清晰且范式同构 `05 §7.1`
- ✅ **§4.4 拒绝列表五条 + §5.3 禁止产出事件五类 + §6.4 F1-F4 消费禁止 + §5.4 G1-G5 产出禁止**——四道"禁止边界"形成 evolution 的完整边界护栏：横向（kind/scope）× 纵向（消费/产出）交叉覆盖，提前堵死未来 kernel rev 升版压力
- ✅ **三层一致性链**（§4.2 snapshot → drift → evolution · scope 字面传递无需重计算）是 TB'4 最有分量的结构化呈现——kernel 层客观性原则在 scope 维度的连续性证明
- ✅ **双层消费模型**（§6.1 L1 O(1) + L2 O(N)）通过 §6.2 L1 永远只读 3 字段的**O(1) 字段数上限契约**保证"L1 不膨胀为 L2"，是架构意图的字面硬边界

**综合评价**：06 @v1 draft 的设计铁律密度显著高于 M5 draft——这是 M6 作为 "M1–M5 五层既有封板契约之上的决策层" 的必然结果：可复用的成熟范式越多，新 milestone 的论证密度越高，新发明越少，锚点闭环越清晰。

### 1.5 kickoff §2.3 分支判定复核

按 `m6_evolution_kickoff §2.3` 规定：若 draft review 中出现 ≥ 3 条必须 kernel 外篇升版的缺口（路径 B），则**升级**为 β-1（05/02/03 补升）再启动工作流 E。当前 §2 发现**少量缺口**（Q21+），初步计数：

- **路径 B 类**（必须升外篇的）· 初步计数 **2 条以内**（见 §2 详述 · 主要 Q21 `03 §3.1` 小升 + Q22 `02 §2.2.4` 补登 evolution.scan_result）
- **路径 A 类**（06 原地消化的）· 初步计数 **少量**（见 §2 详述 · 如字段命名 / 子节澄清）

**是否触发 β-1 升级？否**。理由：

- 路径 B 两条均为**补登 / 小升**级别（03 L1 事件枚举扩一项 · 02 派生类型注册表补一条），**不涉及 `03/02` 的 schema 骨架变更**
- 与 M5 review 同场景对比：M5 review 路径 B 也是 5 条，同样未触发 "M5 draft 返工重写"，而是走统一 `m5_drift_kernel_alignment` proposal 处理
- 06 @v1 draft 内部对两条升版依赖已**透明声明**（§2.4 B2/B3 明示 · §8.2 门控 #4 明示 · §11 下游锚点明示），并未回避——这符合 kernel 契约"边界透明"原则

**定性结论**：**保持 β-2 判定不变**；06 @v1 draft 无需重写，走 "先 A 后 B" 范式走向 published。与 `m5_drift_kernel_alignment@v1` 范式同构，M6 按需开 `m6_evolution_kernel_alignment@v1` proposal 统一处理路径 B 修订。

---

## 2. 找不到答案的问题（**kernel 维度**）

本节识别 06 @v1 draft 中"说了但锚点未完整闭合"或"说了但姿势欠定"的缺口。Q 编号从 **Q21** 起全局延续 m5 review（Q15–Q20）范式。

经逐节排查（§2 身份 R1 / §3 触发 R2 / §4 scope R3 / §5 决策产物 R4 / §6 接口 R5 / §7 生命周期 / §8 门控 / §9 前置契约 / §10 非目标 / §11 下游锚点）· 共识别 **6 条缺口**（2 条路径 B · 4 条路径 A）· 均为"增量完善"级别 · **不触发 draft 返工重写**（与 §1.5 分支判定保持 β-2 一致）。

### Q21 · `03 §3.1` L1 事件枚举需扩为十一类（`evolution.scanned` 新增）

**缺口描述**：
- 06 @v1 draft §5.3 / §6.6 声明 `evolution.scanned` 作为 L1 事件新增类型（从十类扩为十一类）
- §8.2 门控 #4（`evolution.scanned` L1 事件 · 依赖 03 下次小升）将其标为"外篇升版依赖"· 内部已透明声明（§2.4 B2 锚点）
- 当前 `03 §3.1` 实际仍停留在十类枚举 · 06 @v1 draft 全篇所有引用 `03 §3.1` 的位置均暗含"未来十一类"语义

**严重性**：中
- 不影响 06 @v1 draft → published 的逻辑闭环（因已透明声明）
- 但影响 M6 最终 published 升版的客观可验证性（外篇锚点未真实扩版 · 工具链一致性校验会漏）
- 与 M5 review Q17 路径 B 同构（05 引用 03 §3.1 十类 · 但 05 实际需扩至"N 条同 txn"· 已通过 `m5_drift_kernel_alignment §4.3` proposal 落地）

**处置倾向**：**路径 B**（跨篇升版 · 03 @v1 → @v1.1）

### Q22 · `02 §2.2.4` 派生类型注册表缺 `evolution.scan_result` 条目

**缺口描述**：
- 02 @v1.3 的 §2.2.4 派生类型注册 schema 已就位（七字段 · 含 `wordcheck_policy`）
- 现有注册表已登记：`drift.propagation_record` / `snapshot.diff` 等
- 06 @v1 draft §2.4 B3 锚点明示依赖 02 @v1.4 补登 `evolution.scan_result`（含 `wordcheck_policy: machine_generated` · `parent_type: evolution`）
- 当前 02 派生注册表中**无**该条目 · 06 @v1 draft 将其列为 "M6 最终 published 的跨篇升版依赖"

**严重性**：低
- 不影响 06 @v1 draft 的逻辑闭环
- 但影响 `kernel-wordcheck.sh` 工具链识别 · 若未补登 · `evolution.scan_result` artifact 会默认走 `content_safe_default` 扫描（尽管其 body 由确定性算法产出 · 实际无违禁风险 · 但工具链会产生多余扫描开销）
- 与 M5 路径 B R25 派生注册 schema 落地同源 · 属"schema 实施遗漏"

**处置倾向**：**路径 B**（跨篇升版 · 02 @v1.3 → @v1.4 · 补登一条）

### Q23 · `evolution.scanned` L1 事件的 3 字段上限是否需要 `03 §3.1` 独立锚点？

**缺口描述**：
- 06 @v1 draft §6.2 为 L1 "3 字段上限" 给出字面契约（`drift.detected` 读 3 字段 · L1 永远禁止读第 4 字段）
- 但 06 自身产出的 `evolution.scanned` L1 事件 · 其"L1 读 3 字段上限"契约**仅在 06 §6.2 单边声明** · 未在 `03 §3.1` L1 事件 schema 层建立统一契约
- 对比 M5：`drift.detected` 的 3 字段契约 · 由 `05 §6.2` 单边声明 + `m5_final_decisions §1 决议 5 R5` 双向锚定
- M6 的 `evolution.scanned` 若不在 `03 §3.1` 注册 "L1 事件 body 字段数上限" schema · 则未来若有 M7+ 新 L1 事件出现 · 可能无依据反证"3 字段上限"是否普遍适用

**严重性**：低
- 属于"kernel 全局契约可推广性"问题 · 不阻塞 M6
- 但留下未来 M7+ 事件 schema 设计的不一致风险
- 与 M5 review Q18（L1 事件一般化 schema）同类 · 均为"单次 milestone 不处理 · 留待 kernel 层稳定后统一回补"

**处置倾向**：**路径 A**（06 §6.7 锚点闭环声明补一句 · 承认该契约仅在 06 §6.2 生效 · 若未来 M7+ 出现新 L1 事件需重新评估）· 不触发外篇升版

### Q24 · `scanned_drifts[]` schema 的 driver_event_id 字段必填性

**缺口描述**：
- 06 @v1 draft §2.3 artifact schema 的 `scanned_drifts[].driver_event_id` 字段未明示"是否必填"
- 场景：若 drift 本身的 `attribution_mode=sha_only`（无 `driver_event` 可引用）· evolution 的 `scanned_drifts[]` 条目能否省略 `driver_event_id`？
- §6.3 L2 字段 8（`attribution[].driver_event`）明示"`sha_only` 时为 null"· 但 evolution `scanned_drifts[].driver_event_id` 的对应语义未字面锁定
- §3.3 客观性要求 "同一输入必产出字面相同 artifact" · 含义上 `driver_event_id` 应允许 null（对 sha_only drift）

**严重性**：低
- 属于 schema 字段必填性细节 · 未阻塞逻辑闭环
- 但下游工具链（如 HTML 报告生成器）若未预期 null 值 · 会崩溃

**处置倾向**：**路径 A**（06 §2.3 schema 表补一列"必填性/可空性"· 逐字段明示 · `driver_event_id` 标为"sha_only drift 时为 null"）· 不触发外篇升版

### Q25 · `orphan_check.scanned_at` 与 evolution 主 artifact 的 `produced_at` 时间对齐

**缺口描述**：
- 06 §5.2 orphan_check schema 定义 `scanned_at: <ISO8601>` 字段（enabled=true 时必填）
- 06 §2.3 evolution artifact schema 含 front-matter 顶层 `produced_at` 字段（继承 02 §1.1 五要素）
- 未字面约束 `orphan_check.scanned_at` 与顶层 `produced_at` 的关系
- 场景：orphan_check 扫描 artifact 目录通常是 E3 步骤的副作用 · 理应与主 evolution 扫描同一时间窗口内完成
- §3.3 客观性要求 "不得以当前时刻作为决策输入" · 若 `orphan_check.scanned_at` 与 `produced_at` 允许不同 · 下游可能误认为 "两次不同时间的扫描产物被强行拼合"

**严重性**：低
- 属于字段语义边界问题 · 未阻塞逻辑闭环
- 但影响 audit 可追溯性

**处置倾向**：**路径 A**（06 §5.2 orphan_check schema 补一句 · 锁定 `orphan_check.scanned_at == 顶层 produced_at` · 同一次扫描的两个字段必同值）· 不触发外篇升版

### Q26 · §7.3 retracted 条件 #2 与 06 本篇 kernel rev 升版路径的对接

**缺口描述**：
- 06 §7.1 明示 "evolution artifact 不升 rev · 若发现扫描算法 bug 则升的是 kernel rev（本篇 §8.2）"
- 06 §7.3 retracted 三合法条件之一（条件 #2）涉及"扫描算法 bug 导致的事实错误"· 触发 retracted 的前提是 kernel 本篇已升 rev
- 未字面锁定"kernel 本篇升 rev 时 · 已 published 的历史 evolution.scan_result 是否自动批量 retracted"
- 对比 M5 范式：`05 §7.3` drift retracted 条件 #2 明示"默认不回溯作废已产 drift" · 仅对"未来扫描"适用新 rev 算法
- M6 若未明示对齐 · 容易被工具链误解为 "kernel 升 rev 即旧 evolution 全部作废"

**严重性**：低～中
- 属于生命周期语义的边界规则 · 不影响 M6 @v1 draft 闭环
- 但影响 M6 @v2 / kernel rev 升版时的实施决策

**处置倾向**：**路径 A**（06 §7.3 脚注补一句 · 承继 `05 §7.3` "默认不回溯作废"范式 · 字面锁定"kernel rev 升版只对未来扫描生效"）· 不触发外篇升版

### Q21–Q26 计数小结

| 缺口 | 类型 | 严重性 | 处置路径 | 阻塞 06 @v1 draft 升 published？ |
|-----|-----|-------|--------|------------------------------|
| Q21 | 03 §3.1 L1 事件枚举十→十一类 | 中 | **路径 B** | 是（依赖 03 小升） |
| Q22 | 02 §2.2.4 派生注册补 `evolution.scan_result` | 低 | **路径 B** | 是（依赖 02 小升） |
| Q23 | L1 事件 3 字段上限契约普适性 | 低 | 路径 A | 否 |
| Q24 | `scanned_drifts[].driver_event_id` 必填性 | 低 | 路径 A | 否 |
| Q25 | `orphan_check.scanned_at` 与 `produced_at` 对齐 | 低 | 路径 A | 否 |
| Q26 | retracted 条件 #2 与 kernel rev 升版对接 | 低～中 | 路径 A | 否 |

**路径 B 合计**：2 条（Q21 / Q22）· **不超过 §1.5 判定阈值**（≥ 3 条才触发 β-1 升级）· **保持 β-2 分支不变**

**路径 A 合计**：4 条（Q23 / Q24 / Q25 / Q26）· 均为 06 原地消化 · 通过 v1.1 draft 追加或在 v1 published 版刷进

**与 M5 review 同题对照**（参考价值）：
- M5 review §2 识别 Q1–Q14 共 14 条缺口（含 5 条路径 B + 9 条路径 A）· 通过 `m5_drift_kernel_alignment@v1` proposal 统一处置
- M6 review §2 识别 Q21–Q26 共 6 条缺口（含 2 条路径 B + 4 条路径 A）· **密度显著低于 M5**
- 原因：M6 站在 M1–M5 五层封板契约之上 · 可复用范式密度高 · 新发明少 · 缺口自然少

---

## 3. 对 kernel 的建议修订

按 `m5-drift-draft-review.md §3` 范式 · 分路径 A（06 原地消化）/ 路径 B（跨篇升版 proposal）两类。

### 3.1 路径 A · 06 @v1 draft 原地消化（不升 rev · 就地刷进）

**适用范围**：在 06 @v1 draft 内部补充或澄清 · 不触发跨篇升版 · 在 06 → published 升版前完成。

| # | 修订条款 | 修订位置 | 修订内容 | 源自 |
|---|--------|--------|--------|-----|
| A1 | L1 事件 3 字段上限契约普适性脚注 | `06 §6.7` 锚点闭环声明末尾 | 补一条：*本节 §6.2 的"L1 永远只读 3 字段"契约为 06 M6 单边约束 · `03 §3.1` 尚未在 kernel 全局建立 L1 事件 body 字段数上限的统一 schema · 若未来 M7+ 出现新 L1 事件 · 需在彼时重新评估 3 字段上限是否普遍适用 · 本 M6 不假设该契约自动推广* | Q23 |
| A2 | `scanned_drifts[]` schema 字段必填性列 | `06 §2.3` artifact schema 表新增一列 | 为 `scanned_drifts[]` 每字段补"必填性"标注：`drift_urn`/`decision` 必填；`driver_event_id` **sha_only drift 时为 null**；其余补充字段可选（按 05 §2.3 drift body 的 `attribution_mode=sha_only` 语义推导） | Q24 |
| A3 | `orphan_check.scanned_at` 与顶层 `produced_at` 对齐约束 | `06 §5.2` orphan_check schema 说明段 | 补一句：*`orphan_check.scanned_at` 与 evolution artifact front-matter 的 `produced_at` **必同值** · 同一次扫描的两个字段不得分叉 · 这是 §3.3 客观性承诺在 orphan_check 字段上的具体化落实* | Q25 |
| A4 | retracted 条件 #2 与 kernel rev 升版对接脚注 | `06 §7.3` retracted 三合法条件 #2 末尾脚注 | 补一条：*承继 `05 §7.3` "默认不回溯作废"范式 · kernel rev 升版（例：扫描算法从 v1 → v2）只对**未来扫描**生效 · 不触发对历史 published evolution.scan_result 的批量 retracted；若 kernel rev 升版认为历史产物需整体作废 · 走独立 `evolution_retract_batch` proposal 而非本 §7.3 条件 #2 自动化路径* | Q26 |

**路径 A 合计**：4 条修订 · 全部限于 06 @v1 draft 内部 · 影响面 4 节（§6.7 / §2.3 / §5.2 / §7.3）· 均为 "字面补 1 条约束/脚注"级别 · 预期字数增量 < 300 字。

**实施时机**：
- 方案 α（推荐）：`06 @v1 draft` → `06 @v1 published` 直升版时同步刷进（单次刷版 · 不额外升 rev · 与 M5 05 @v1 draft → @v1.1 draft 的路径 A 处置范式同构）
- 方案 β：先独立出一个 `06 @v1.0.1 draft` rev（仅含路径 A）· 再过渡到 `06 @v1.1 draft`（含路径 B）· 两 rev 分离（不推荐 · rev 粒度过细）

**倾向**：方案 α · 路径 A 四条在"先 A 后 B"范式的"A"阶段统一刷进 · 不额外增加 rev。

### 3.2 路径 B · 跨篇升版（通过 `m6_evolution_kernel_alignment@v1` proposal 统一处置）

**适用范围**：必须触发 kernel 其他篇（03 / 02）升版的缺口 · 按 `m5_drift_kernel_alignment@v1` 范式开独立 proposal 处理。

**建议新建 proposal**：
- URN: `urn:piao:proposal:kernel:m6_evolution_kernel_alignment@v1`
- 对标范式：`urn:piao:proposal:kernel:m5_drift_kernel_alignment@v1 published`
- 状态路径：`draft → proposal.published → kernel 各篇 alignment 落地 → 06 @v1.1 draft → 06 @v1.1 published`

| # | 修订条款 | 修订目标篇 | 修订内容 | 源自 |
|---|--------|---------|--------|-----|
| B1 | `03 §3.1` L1 事件枚举扩为十一类 | 03-layered-architecture.md @v1 → @v1.1 | §3.1 L1 事件枚举追加第 11 项 `evolution.scanned`：*evolution 扫描器每次扫描完成后必产出一条 · 作为观测基础层的事件载体 · body schema 由 `06 §2.3` 定义*；鸣谢锚点：`06 §5.3 / §6.6`；本次扩展不改变前 10 项语义 · 向后兼容；适用 @v1.1 rev_history 追加 | Q21 |
| B2 | `02 §2.2.4` 派生注册表新增 `evolution.scan_result` 条目 | 02-artifact-model.md @v1.3 → @v1.4 | §2.2.4 派生类型注册表新增七字段条目：<br/>- `artifact_type`: `evolution.scan_result`<br/>- `parent_type`: `evolution`<br/>- `description`: *"evolution 扫描器产出的观测基础层 artifact · 由 `scripts/piao-evolution-scan.sh` 产出"*<br/>- `schema_version`: `1.0`<br/>- `owner`: `kernel:m6`<br/>- `stability`: `beta`<br/>- `wordcheck_policy`: `machine_generated`（body 由确定性算法产出 · 跳过 kernel-wordcheck）<br/>鸣谢锚点：`06 §2.4 B3 / §5.3`；适用 @v1.4 rev_history 追加 | Q22 |

**路径 B 合计**：2 条修订 · 触及 2 篇（03 / 02）· 不触发 05 / 04 / 01 升版。

**proposal 结构范式**（对标 `m5_drift_kernel_alignment@v1`）：
- §1 背景（来自 06 @v1 draft → published 升版的两条路径 B 缺口）
- §2 修订明细（B1 / B2 · 字面对应本 §3.2 表格）
- §3 下游影响（03 @v1.1 / 02 @v1.4 · 06 @v1.1 · 不触发 05/04/01 升版）
- §4 实施顺序（B1 先 B2 后 · 或同 txn 批升 · 按 03 §3.3.1 N 条同 txn 契约处理）
- §5 状态（draft → published 触发 kernel alignment 落地）

**路径 B 的 06 响应**：
- 06 @v1 draft → 06 @v1.1 draft · 路径 B 落地后同步升版（rev_history 追加 v1.1 行）
- §8.2 门控 #4 从"依赖 03 下次小升"→ "已依赖 03 @v1.1 / 02 @v1.4 落地"
- §9 前置契约表中 03/02 锚点版本 refresh
- §11 下游锚点表的"依赖"栏对应刷新

### 3.3 顺序与节奏建议

**推荐执行顺序**（按 M5 范式同构推导）：

```
Step 1 · 06 @v1 draft → @v1 published（或 @v1.0.1 draft · 方案 α）
         ├── 刷进路径 A 四条修订（A1/A2/A3/A4）
         └── §8.2 门控 #4 继续声明"依赖外篇升版"· 暂不关闭

Step 2 · 开 m6_evolution_kernel_alignment@v1 draft proposal
         ├── §1 背景（引用本 review §3.2）
         ├── §2 明细（B1/B2）
         └── §3/§4/§5 按范式补齐

Step 3 · proposal published · 触发 kernel 各篇小升
         ├── 03-layered-architecture.md @v1 → @v1.1（执行 B1）
         └── 02-artifact-model.md @v1.3 → @v1.4（执行 B2）

Step 4 · 06 @v1 published → @v1.1 draft → @v1.1 published
         ├── 依赖 03 @v1.1 / 02 @v1.4 · §9 锚点 refresh
         ├── §8.2 门控 #4 关闭（evolution.scanned L1 已在 03 @v1.1 正式登记）
         └── 完成 M6 milestone 升版闭环

Step 5 · M6 milestone 封板（产出 m6_final_decisions@v1）
         ├── 对标 m5_final_decisions@v1 范式
         └── 盖章 R1-R5 五条硬约束 + Q6.1-Q6.5 五问最终回答
```

**节奏评估**：
- 与 M5 流程一致（draft review → 路径 A 原地消化 → alignment proposal → 跨篇小升 → 本篇 @v1.1 → milestone 封板）
- 预期时长：按 M5 实际节奏（2–3 个工作日完成 Step 2–Step 4）· M6 路径 B 更少（2 条 vs M5 5 条）· 预期更快

### 3.4 与 M5 同场景对标小结

| 维度 | M5 drift draft review | M6 evolution draft review |
|-----|---------------------|------------------------|
| 缺口总数 | 14 条（Q1–Q14） | 6 条（Q21–Q26） |
| 路径 A 条数 | 9 条 | 4 条 |
| 路径 B 条数 | 5 条 | 2 条 |
| 触发 β-1 升级？ | 否（5 条 < 阈值调整前，当时阈值模糊） | 否（2 条 < 阈值 3 条 · 明确保持 β-2） |
| 跨篇影响 | 02/03/04 三篇升版 | 03/02 两篇升版 |
| alignment proposal 产出 | `m5_drift_kernel_alignment@v1` published | 建议 `m6_evolution_kernel_alignment@v1`（待开） |
| 同题延续性 | ✅ 三层一致性链首次提出 | ✅ 三层一致性链在 evolution 层最终兑现 |

**定性结论**：M6 @v1 draft 的 review 缺口密度仅为 M5 的 43%（6 / 14）· 路径 B 密度为 M5 的 40%（2 / 5）· 这是 M6 作为 "M1–M5 既有契约之上的决策层" 在论证复用性上的必然收益 · 符合 kernel 层"越往后 milestone 越薄"的设计预期。

---

## 4. 小结与分支建议

### 4.1 总体判定

**06 @v1 draft 质量等级**：**✅ 可接受（Acceptable · 不触发返工重写）**

| 判定维度 | 评估结果 | 证据锚点 |
|--------|--------|--------|
| 五问回答密度 | **5/5 全部充分** · 无一项"待展开" | §1.1 Q6.1–Q6.5 五行全 ✅ |
| kernel 锚点自洽度 | **20+ 处引用 · 20/20 源文档存在** · 仅 2 处姿势需小升外篇（Q21/Q22） | §1.2 锚点清单逐条校验通过 |
| 范式复用密度 | **显著高于 M5 draft** · 直接复用 drift 四理由 / snapshot 双形态 / drift 双通道等成熟范式 | §1.3 M5 → M6 范式复用表 |
| TB' 证据承载力 | **TB'1–TB'5 全部落地** · Q6.x → TB'x 映射矩阵无空格 | 06 §8.2 门控 #2 · 本 review §1.4 |
| 分支判定（β-2） | **路径 B 2 条 < 阈值 3 条** · 维持 β-2 不触发 β-1 升级 | 本 review §1.5 / §2 末尾复核 |
| 缺口密度（vs M5） | **43%**（6/14）· 论证复用性收益显著 | 本 review §2 / §3.4 对标表 |

**一句话评语**：
> M6 @v1 draft 是 kernel 层第三次复用"双形态 / 双通道 / 三层一致性 / C1–C4 继承"范式的成熟产物 · 其 6 条缺口均属"字面约束补齐 / 跨篇锚点小升"级别 · **不存在结构性缺陷** · 按 §3 五步执行顺序即可落地 06 @v1.1 published → M6 milestone 封板。

### 4.2 分支建议（最终锁定）

**维持 β-2 分支**（由 `m6_evolution_kickoff@v1 §2.3` 在阶段 α 工具链扩展零 05 歧义条件下选定）。

**锁定依据**：
- §1.5 β-2 vs β-1 分支阈值复核：路径 B 缺口数 = 2 · **严格小于阈值 3 条**
- §2 缺口识别全量完成后 · Q21–Q26 六条均为 "增量完善" 级别 · 无一条触及 Q6.1–Q6.5 五大硬约束 R1–R5 本身
- §3.4 与 M5 对标：M6 缺口密度 43% · 路径 B 密度 40% · 两指标均低于 M5 · 不需要升级到更严格的 β-1 路径（β-1 通常用于"发现结构性问题需 kickoff 回退重评"）

**拒绝升级到 β-1 的反证**：
- 若升级 β-1 → 需要将 06 @v1 draft 降级为 @v0.x 重整骨架 · 但 §1.1 五问回答已全部充分 + §1.2 锚点闭环已成立 · 降级动作无正当性
- 若升级 β-1 → 需要重开 `m6_evolution_kickoff@v2` 追加第六问 · 但 §2 缺口识别未发现任何五问之外的新维度 · 追加动作无必要性

### 4.3 06 @v1 draft → published 升版门控达成路径

对照 06 §8.2 四条门控（@v1 draft 阶段全部 `[x]` 达成）· 本 review 补充"升 published"阶段的门控达成路径：

| 门控 # | @v1 draft 状态 | 升 published 附加条件 | 本 review 认定 |
|-------|-------------|------------------|-------------|
| #1 · 五问硬约束锁定 | [x] R1–R5 全锁定（`74820f3c` + `d527a859`）| 无附加 · 本 review §1.1 已认定"全部充分" | ✅ 即达成 |
| #2 · TB' 证据锚定 | [x] 42 处 TB' 引用 · Q6.x→TB'x 映射完整 | 无附加 · 本 review §1.4 已认定"证据链闭合" | ✅ 即达成 |
| #3 · 生命周期随身份展开 | [x] 双轨生命周期落地 · §7 完整 | 无附加 · 本 review §1.2 行 24–27 已校验 | ✅ 即达成 |
| #4 · 跨篇锚点闭环 | [x] 42 处声明全部定位 · 但 `03 §3.1` + `02 §2.2.4` 两处外篇锚点仍需小升 | **要求**：`m6_evolution_kernel_alignment@v1` proposal 推动 `03 @v1 → @v1.1` + `02 @v1.3 → @v1.4` 落地（本 review §3.2 B1/B2） | ⏳ 依赖路径 B proposal 完成 |

**升版路径总结**：
```
06 @v1 draft (d527a859)
 ├─[路径 A 原地消化]─▶ 06 @v1 draft' (本 review §3.1 A1-A4 刷进)
 │                                │
 │          ┌─[开 proposal]───────┘
 │          ▼
 │    m6_evolution_kernel_alignment@v1 draft
 │          │
 │          ├── B1 · 03 @v1 → @v1.1（evolution.scanned L1 事件登记）
 │          └── B2 · 02 @v1.3 → @v1.4（evolution.scan_result 派生类型登记）
 │                │
 │                ▼
 │          proposal published
 │                │
 │          ┌─[触发 06 升版]───────┐
 │          ▼                      ▼
 └─▶ 06 @v1.1 draft ──▶ 06 @v1.1 published
                                     │
                                     ▼
                              [M6 milestone 封板]
                                     │
                                     ▼
                        m6_final_decisions@v1 published
                        （对标 m5_final_decisions@v1 范式）
```

### 4.4 风险提示与缓解

**风险 R_A · 路径 A 四条修订的"字面漂移"风险**：
- **风险描述**：A1–A4 四条修订均为"补一句脚注/约束" · 若在 06 @v1 → @v1 published 直升版时被遗漏 · 则 A 类缺口延留至 @v1.1
- **严重性**：低（缺口本身严重性均为"低～低中"）
- **缓解措施**：
  1. 本 review §3.1 表格已字面列出四条修订的"修订位置 + 修订内容" · 可直接复制粘贴到 06 对应章节
  2. M6 milestone 封板的 `m6_final_decisions@v1` 产出前 · 由本 review §4.3 门控 #4 的完成度检查强制确认路径 A 已刷进

**风险 R_B · 路径 B 两条跨篇升版的"工具链同步"风险**：
- **风险描述**：B1（`03 §3.1` 十→十一类）落地后 · `scripts/piao-event-journal-append.sh` / `kernel-wordcheck.sh` 等工具链需识别新事件类型 `evolution.scanned` · 若工具链同步滞后 · 会产生"contract published 但 tooling 未识别"的窗口期
- **严重性**：中（影响 M6 milestone 封板的工具链可执行性）
- **缓解措施**：
  1. `m6_evolution_kernel_alignment@v1` proposal 的 §4 实施顺序 · 应明示 "tooling 同步纳入 proposal 的 published 门控"（对标 M5 `m5_drift_kernel_alignment@v1` published 时对 `piao-drift-detector.sh` 的同步要求）
  2. B2（`02 §2.2.4` 补登 `evolution.scan_result`）在 proposal published 时同步刷新 `kernel-wordcheck.sh` 的派生类型白名单 · 避免 `evolution.scan_result` artifact 被误判为 "machine_generated 跳过扫描" 之外的策略

**风险 R_C · M6 → M7 接口预设过早的"架构反噬"风险**：
- **风险描述**：06 §6.6 明示 "本 M6 不预设 M7/M8 接口"（对齐 kickoff §4 Q6.5 候选三选一的"完全终止于产出 task 建议"路径）· 但 §5.3 `task.proposed` 事件作为 evolution 与 taskdag 的单向通知接口 · 实际上已隐含 M7 taskdag 层的存在
- **严重性**：低（不阻塞 M6 封板 · 但留下 M7 启动时的"接口二次确认"工作量）
- **缓解措施**：
  1. `m6_final_decisions@v1` 封板时 · 显式声明 "M7 taskdag 层开启时 · 需复核 06 §6.6 下游事件类型锁定表的 `task.proposed` 字段语义是否仍适用"
  2. 参照 M5 final decisions 范式 · 在 `m6_final_decisions@v1 §3` 列出 "M7+ 层可能触发 M6 小升的场景" · 提前声明反例证伪条件（对标 06 §8.3 触发升 @v2 的三条件）

**综合风险结论**：**低风险**（R_A 低 · R_B 中但有明确缓解 · R_C 低）· 不构成 β-2 → β-1 升级的理由 · 不阻塞 06 @v1 draft → published 升版推进。

---

## 5. 路径 A/B 消化记录（2026-04-19 19:54 / 20:15–20:50）

> **章节定位**：本章为 `m6-evolution-draft-review @v1 draft` 的**后置追补记账段**（对标 M5 `m5-drift-draft-review @v1 §5` 范式），在 review 正文 §0–§4 全部起稿完成后追加，用于固化 `§3.1 路径 A 四条` 与 `§3.2 路径 B 两条` 的实际消化落地证据。**追加本章不触发 review 自身升版**（按 `01 §10.1` draft 契约 · 路径 B 驱动 proposal `m6_evolution_kernel_alignment@v1` S5 动作下的"review 归档"属性 · 等同 M5 同位 S6）。路径 A 细节沿袭 `06 @v1 draft` 的 §8.1 rev_history v1（路径 A 消化）行 + §2.3/§5.2/§6.7/§7.3 四处字面补齐（见 §5.1）· 本章重点在 §5.2–§5.7 路径 B 的四步完整落地证据。

### 5.1 路径 A 消化追述（A1–A4 · 2026-04-19 19:54）

路径 A 四条缺口（Q23/Q24/Q25/Q26）已在 `06 @v1 draft` 本篇原地消化（非独立 rev 升版 · 方案 α · 对标 M5 `05 @v1 draft` 路径 A 处置同构）：

| # | 源缺口 | 落点（06 @v1 draft） | 修订类型 | 字面增量 |
|---|------|-------------------|--------|--------|
| A1 | Q23 · L1 事件 3 字段上限契约普适性 | `§6.7` 末尾追加普适性声明段 | 契约边界澄清 | +3 行 |
| A2 | Q24 · `scanned_drifts[]` 字段必填性 | `§2.3` 身份 schema `scanned_drifts[]` 字段说明处追加 | schema 必填性补注 | +4 行 |
| A3 | Q25 · `orphan_check.scanned_at` 时间对齐 | `§5.2` orphan_check schema 后追加 `produced_at` 同值约束 | 客观性承诺字段级落实 | +5 行 |
| A4 | Q26 · `§7.3` retracted 条件 #2 与 kernel rev 升版对接 | `§7.3` retracted 条件 #2 末尾追加 kernel rev 升版对接语义 | retracted 分支语义补齐 | +6 行 |

**消化证据** · `06 @v1 draft §8.1 rev_history` 追加"v1（draft · 路径 A 消化）" 行（2026-04-19 19:54）· commit `e6e18d5f`（`docs(piao/kernel): m6 06-evolution-model @v1 draft · 路径 A 四条字面约束消化`）· IDE lint × 0 错误 · **不升 rev**。

### 5.2 路径 B 完成记录（B1–B2 · 2026-04-19 20:15–20:50 · S1–S5）

路径 B 两条缺口（Q21/Q22）由 `urn:piao:proposal:kernel:m6_evolution_kernel_alignment@v1 published` 驱动 · 五步 S1–S5 已全部落地（S6 为最终 wordcheck/lint 收官 · 非本章范围）：

| 步 | 动作 | 落点 | 执行时刻 | commit | IDE lint |
|---|-----|-----|---------|--------|---------|
| S0 | 预检（`evolution.scan_result` 零冲突） | `02 @v1.3` `§2.2.4` 注册区 · `grep` 零命中 | 2026-04-19 20:10 | —（执行性质 · 见 proposal §6 DoD 首行）| — |
| S1 | `03 @v1 draft` 原地精化（B1） | `§3.1` `evolution.scanned` 行 subject + 语义字段精化 + `§3.1` "禁止扩展"段补注 + `§6.3` 连带精化 + `§10` rev_history 追述 | 2026-04-19 20:30 | `76bbfff5` | ✅ 0 错 |
| S2 | `02 @v1.3 → @v1.4 published`（B2） | `§2.2.4` 新增 `evolution.scan_result` YAML 登记示例 + "注释 3" 补注 + 承诺段补加 v1.4 专项条目 + `§11` rev_history v1.4 行 | 2026-04-19 20:45 | `7a7bce04` | ✅ 0 错 |
| S3 | proposal `draft → published` · self-review 签收 | proposal 自身 front-matter `status: draft → published` + `§9` self-review 段追加（对标 M5 `m5_drift_kernel_alignment@v1 §8`）| 2026-04-19 20:15 | `1c106937` | ✅ 0 错 |
| S4 | `06 @v1 draft → @v1.1 draft` 跟随升版 | front-matter `urn`/`rev`/`last_modified_at` 三字段同步 + `§2.4` B2/B3 "已对接"改写 + `§2.5` 锚点闭环两条 refresh + `§8.2` 门控 #4 达成段正文 refresh + `§8.2` "v1.1 事实补注"段追加 + `§8.1` rev_history v1.1 行 + `§9` 前置契约表 02/03 六行状态 refresh + `§11` 章节标题 + 状态行 + 上下游锚点全 refresh | 2026-04-19 20:50 | `44bf034b` | ✅ 0 错 |
| S5 | review §5 追加路径 A/B 消化记录（本章追补） | 本 review `§5.1–§5.7` 追加 + 原 `§5 本 review 状态` 下移为 `§6` 并 refresh | 2026-04-19 20:55 | 本次 commit | ✅ 待校验 |

**路径 B 合计**：3 篇文档触达（03 / 02 / 06）+ 1 篇 proposal（驱动源）+ 1 篇 review（归档）= 5 份文件 · 6 个 commit 固化（含 S0 预检不产 commit）。

### 5.3 consumed 矩阵（B1/B2 与实际落点的对齐）

| 源条款 | 目标篇 rev 升降 | 落点字面 | commit 固化 | 对标 M5 同位 |
|-------|--------------|--------|----------|----------|
| **B1** · `03 §3.1` L1 事件枚举 `evolution.scanned` 语义字段 refresh | `03 @v1 draft` 原地精化（**不升 rev** · 按 `01 §10.1` draft 契约 · 10 类枚举总数不变）| `§3.1` L1 表第 10 行：subject 从"task URN"→"scope URN"；语义字段从 `target_task_urn, extracted_memory_ids[]`（M4 占位）→ `drift_event_urn, scope_urn, scanned_drifts[], decision_log[]`（对齐 `06 §2.3 / §5.3` 实锁 schema）+ `§3.1` 末段"禁止扩展"段补注 + `§6.3` 连带精化 + `§10` rev_history 追述行 | `76bbfff5` | M5 路径 B R22（03 `§3.3.1` 原子写入契约 N 条同 txn 泛化 · 同为 draft 原地精化 · 不升 rev）|
| **B2** · `02 §2.2.4` 派生注册表新增 `evolution.scan_result` 条目 | `02 @v1.3 → @v1.4 published`（升小版 published · 对齐 M5 `02 @v1.2 → @v1.3` 同构范式）| `§2.2.4` 示例区追加第 2 个 YAML 登记块（七字段齐全 · `artifact_type` / `parent_type: evolution` / `description` / `schema_version: 1.0` / `owner: kernel:m6` / `stability: beta` / `wordcheck_policy: machine_generated`）+ "注释 3（v1.4 · 本 proposal S2 B2）"补注段 + 承诺段 v1.4 专项条目 + `§11` rev_history v1.4 行 | `7a7bce04` | M5 路径 B R25（02 `§2.2.4` 派生注册表首设七字段 schema · 同为 02 小升）|

**关键洞察**：B1 走 draft 原地精化 · B2 走 published 小升 · 两条采取**差异化 rev 策略** · 原因在 proposal `§1.1 rev 升降矩阵`明示——03 尚未 published · 可就地精化；02 已 @v1.3 published · 必须走 `@v1.3 → @v1.4` 小升才能增派生类型注册条目 · 对齐 `01 §10.1` published 不可变契约。本差异化策略与 M5 路径 B R22/R25 的同构处置一致（R22 03 原地 · R25 02 小升）· 系 kernel 层 rev 升降范式的**跨 milestone 稳定模式**。

### 5.4 06 跟随升版锚点注释同步（S4 专段 · @v1 draft → @v1.1 draft · 2026-04-19 20:50）

**升版性质**：draft 内小升（**仍 draft**）· 按 proposal `§4.4 / §1.1` 明示 · 非"原地修订"范畴（变更源自外部 kernel 文档升降 · 属跨篇一致性维护 · 对标 M5 `05 @v1 → @v1.1 draft` 范式同构）。

**修订要点（8 处锚点）**：
- **front-matter 三字段同步**：`urn:@v1 → @v1.1` · `rev: v1 → v1.1` · `last_modified_at: 19:10 → 20:50`
- **§2.4 关键边界锁定表 · B2 / B3 "已对接"改写**（两条标签从"依赖 03/02 下次小升"→ "已对接 @v1 draft 原地精化（commit `76bbfff5`）/ @v1.4 published（commit `7a7bce04`）"）
- **§2.5 锚点闭环声明两条 refresh**（`02 §2.2.4` + `03 §3.1` 依赖从"下次小升"→ "✅ 已对接"）
- **§8.2 门控 #4 达成段正文 refresh**（外篇依赖关闭 · 附两条 commit hash · 门控 #1–#4 全部保持 `[x]`）
- **§8.2 追加"v1.1 事实补注"段**（说明实际路径"@v1.1 draft 小升而非 @v1 published 直升"的理由：外篇对接 + 本篇锚点刷新属状态同步性质而非工具链反证性质 · 先 draft 内小升固化事实 · 工具链反证后再升 @v1.1 published）
- **§8.1 rev_history 追加 v1.1 行**（触发源 `urn:piao:proposal:kernel:m6_evolution_kernel_alignment@v1 §4.4` · 覆盖 6 处主修订 · draft 内小升不发 `spec.published` L1 事件）
- **§9 前置契约表 02/03 六行状态 refresh**（02 四行 `@v1.3 → @v1.4 published` · 02/03 三行追加"路径 B 已反向对接 · commit hash"）
- **§11 章节标题 + 状态行 + 上下游锚点表全 refresh**（章节标题 "@v1 draft · 路径 A 消化完成" → "@v1.1 draft · 路径 A/B 全消化" · 上游锚点表 02 升 @v1.4 + 新增一行 proposal published 为驱动源 · 下游锚点表 02/03/proposal 三行从"待对接"改写为"✅ 已消费"）

**schema 骨架不变**：纯锚点注释性小升 · 未来产出 `evolution.scan_result` 实例（若有）不受影响 · R1–R5 五硬约束字面保留 · §2–§7 正文零冲击 · 行数 837 → 858（+21 行 · 与 proposal §2 预估 ~30 行范围吻合）。

### 5.5 与 proposal §1.1 rev 升降矩阵的一致性

`m6_evolution_kernel_alignment@v1 §1.1 rev 升降矩阵` 对 03 / 02 / 06 三篇的升降定性与实际落地 100% 一致：

| 篇 | proposal §1.1 定性 | 实际落地 | 一致性 |
|---|-------------------|--------|------|
| `03` | **占位字段精确化 · 不升 rev**（draft 原地修订 · 10 类枚举总数不变） | `@v1 draft` 原地精化（commit `76bbfff5`）· 枚举数确 10 类 · `evolution.scanned` subject + 语义字段实锁刷新 | ✅ 100% |
| `02` | **派生注册表扩列 · @v1.3 → @v1.4 published**（小升 · 对齐 `wordcheck_policy: machine_generated` 模式） | `@v1.3 → @v1.4 published`（commit `7a7bce04`）· 七字段齐全 · `wordcheck_policy=machine_generated` | ✅ 100% |
| `06` | **跟随升版 · @v1 draft → @v1.1 draft**（纯锚点注释同步 · 不升 published · 非工具链反证） | `@v1 draft → @v1.1 draft`（commit `44bf034b`）· 8 处锚点同步 · schema 骨架不变 · R1–R5 保持 | ✅ 100% |

**一致性验证**：proposal `§1.1 rev 升降矩阵` 三行预判与 S1/S2/S4 实际 commit 实施的 rev 升降 **零偏移**。

### 5.6 路径 A/B 全消化后的闭环对接

| 维度 | 路径 A（4 条） | 路径 B（2 条） |
|------|-------------|------------|
| 源缺口 | Q23 / Q24 / Q25 / Q26 | Q21 / Q22 |
| 驱动方式 | 06 `@v1 draft` 原地消化（不开独立 proposal） | `m6_evolution_kernel_alignment@v1` proposal 驱动（对标 M5 `m5_drift_kernel_alignment@v1`）|
| rev 升降 | 06 不升 rev（`§8.1 rev_history v1（路径 A 消化）`行原地追述）| 03 不升 rev（draft 原地）· 02 `@v1.3 → @v1.4 published` · 06 `@v1 → @v1.1 draft` |
| commit 节点 | `e6e18d5f` · 1 个 | `76bbfff5` / `7a7bce04` / `1c106937` / `44bf034b` / 本次 S5 · 共 5 个 |
| 落点字面 | 06 `§2.3` / `§5.2` / `§6.7` / `§7.3` 四处补齐 · 总 +18 行 | 03 `§3.1` / 02 `§2.2.4` / 06 多处 · 总 ~45 行 |
| 完成时刻 | 2026-04-19 19:54 | 2026-04-19 20:15 – 20:55（40 分钟内连做 S3–S5）|

**06 published 升版门控达成路径状态**（对照 `06 §8.2` 门控 #1–#4）：
- **门控 #1**（本 review 产出 + 锚点完整性校验）· ✅ 已达成（`fc10ef2f` / `56d1ddc8` / `f546719b` 三段式 + 本次 S5 追补 §5 消化记录）
- **门控 #2**（R1–R5 未被反例证伪）· ⚠️ 待 `piao-evolution-scan.sh` MVP 运行结果反证
- **门控 #3**（`evolution.scan_result` artifact 首例真实产出）· ⚠️ 待 MVP 输出
- **门控 #4**（外篇对接 · 03/02 锚点）· ✅ **已达成**（路径 B S1/S2 固化 commit `76bbfff5` + `7a7bce04` · 06 `§8.2` 门控 #4 达成段已 refresh）

**综合判定**：**契约侧四条门控中三条已达成 · 余下门控 #2/#3 需工具链 MVP 反证** · 对标 M5 `05 @v1.1 draft → published` 同节奏（M5 亦卡在 `piao-drift-compute.sh` MVP 反证处 · 两周内完成 MVP 产出）。

### 5.7 路径 B 完成后的下一动作

按 proposal `§7 完成后的下游触发` + `§6 DoD` 未勾选条目指引：

1. **S6（本 proposal 自身收官）**：`./scripts/kernel-wordcheck.sh --ci`（如有）或等价命令在 `docs/piao-pipeline/kernel/` 下返回 `exit 0`（BAN/WARN 数不增加）+ IDE lint 对三份修订后文档（03 / 02 / 06）各自 0 错误 + `06 §9` 前置契约表可查性验证 + Step 5 就绪声明 + 本 proposal 发 `proposal.implemented` 事件（对标 M5 `m5_drift_kernel_alignment@v1` final commit `c0991418` 节奏）
2. **`06-evolution-model.md @v1.1 (draft) → @v1.1 (published)`**（路径 B 闭环后的下一阶段 · 非本 proposal 范围）：
   - 依赖 `scripts/piao-evolution-scan.sh` MVP 产出至少 1 条真实 `evolution.scan_result` artifact（对标 M5 `piao-drift-compute.sh` 节奏 / M4 `piao-snapshot-produce.sh` + `piao-snapshot-diff.sh` 范式）
   - 依赖 `_review/m6-final-decisions.md` 产出（对标 M5 `m5-final-decisions@v1` 范式）
   - 预计时长：按 M5 实际节奏 2–3 个工作日
3. **`M1-debt-ledger @v6 → @v7`**（如适用）· 登记 Q21–Q26 六条缺口 consumed 证据 + R17–R25 对标九条（M6 侧 R1–R5 五条硬约束 + Q23–Q26 四条 A 类补齐 + Q21–Q22 两条 B 类 proposal 条款消化）
4. **`m6_evolution_kickoff@v1 status: published → superseded`**：与 `m6-final-decisions@v1 published` 产出同步（对称 `m5_drift_kickoff@v1` 当前 `superseded` 状态）
5. **下一 milestone · M7 起稿**：待 06 published + `m6-final-decisions@v1 published` 封冻后 · 由 `m7_*_kickoff@v1` proposal 启动（对标 M5→M6 过渡 commit `aa6c7489` 节奏）

**当前阶段定位**：M6 `evolution` 层 kernel 契约侧工作 **基本封闭** · 路径 A/B 全消化 · 06 `@v1.1 draft` 锚点状态刷新 · 等待工具链 MVP 反证后升 `@v1.1 published` · 整体节奏与 M5 对标 **完全同构**。

---

## 6. 本 review 状态

**本 review 状态**：**published** @v1（阶段 β 工作流 E 退出门产出 · **§0 + §1 + §2 + §3 + §4 + §5 全部起稿完成 · 四段式 review 收官 · S6 最终收官批升 published @ 2026-04-19 21:05 · 与 `m6_evolution_kernel_alignment@v1 proposal.implemented` 事件同 commit 固化**）
- §0 定位锁定三件事（五问充分性 / 锚点闭环 / Q21+ 处置建议）
- §1 锚点盘点（1.1 五问回答 ✅ 5/5 · 1.2 引用校验 ✅ 20+/20+ · 1.3 范式复用密度 · 1.4 TB' 证据承载力 · 1.5 β-2 分支判定复核）
- §2 缺口识别（Q21–Q26 六条 · 路径 A 四条 + 路径 B 两条）
- §3 建议修订（§3.1 路径 A 四条原地消化 · §3.2 路径 B 两条跨篇升版 proposal · §3.3 五步执行顺序 · §3.4 与 M5 同场景对标）
- §4 小结与分支建议（§4.1 总体判定"可接受" · §4.2 锁定 β-2 分支 · §4.3 升 published 门控达成路径 · §4.4 三条风险提示与缓解）
- §5 路径 A/B 消化记录（§5.1 路径 A 追述 · §5.2 路径 B 四步执行表 · §5.3 consumed 矩阵 · §5.4 06 跟随升版 S4 专段 · §5.5 与 proposal §1.1 一致性 · §5.6 闭环对接 · §5.7 下一动作）← **S5 本次追补**

**review 自身升版路径**：
- @v1 draft → **@v1 published（当前 · 2026-04-19 21:05 · commit 本次 S6 固化）** · 升版触发条件（三条全满足 · 已兑现）：
  1. ✅ **路径 A 四条修订在 06 @v1 draft 内部刷进完成**（commit `e6e18d5f` · 2026-04-19 19:54）
  2. ✅ **`m6_evolution_kernel_alignment@v1` proposal 开出 published**（commit `1c106937` · 2026-04-19 20:15 · 路径 B 处置路径已明示并全落地）
  3. ✅ **本 review §2/§3/§4 正文无新增缺口识别或分支判定翻转**（§5 仅追补消化记录 · 不触发 §2/§3/§4 改动）
- S6 最终收官批升：与 `m6_evolution_kernel_alignment@v1 proposal.implemented` 事件 + 三文档（03 / 02 / 06）wordcheck + IDE lint 全通过 **同 commit 批升** · 对标 M5 `m5-drift-draft-review @v1 published` 同步 commit `c0991418` 节奏 · 完整同构

**上游锚点**：
- `urn:piao:spec:architecture:evolution_model@v1.1 (draft)` · 本 review 对象 · **当前为 @v1.1 draft**（S4 commit `44bf034b` · 路径 B 闭环后跟随升版）
- `urn:piao:proposal:kernel:m6_evolution_kickoff@v1 published` · 本 review 归属 milestone 的工作编排 proposal（Q6.1–Q6.5 五问来源）
- `urn:piao:proposal:kernel:m6_evolution_kernel_alignment@v1 published` · **路径 B 驱动 proposal（见 §5.2–§5.6）**（commit `1c106937` · 5 commit 固化）
- `urn:piao:artifact:kernel:m5_toolchain_extension_review@v1 published` · 与本 review 互为正反向证据（TB'1–TB'5 来源）
- `urn:piao:snapshot:kernel:m5_final_decisions@v1 published` · M5 milestone 收官快照
- `urn:piao:artifact:kernel:m5_drift_draft_review@v1 published` · 本 review 的四段式范式参照

**下游锚点**（§5 追补后 refresh）：
- **路径 A 四条**（§3.1 A1–A4）✅ **已 consumed**（见 §5.1 · 06 `e6e18d5f`）
- **路径 B 两条**（§3.2 B1–B2）✅ **已 consumed**（见 §5.2–§5.6 · `m6_evolution_kernel_alignment@v1 published` 驱动 · S1/S2 commit `76bbfff5` + `7a7bce04`）
- **06 升版链**：✅ `06 @v1 draft` 路径 A 消化完成（`e6e18d5f`）→ ✅ `06 @v1 draft → @v1.1 draft` 跟随升版（`44bf034b`）→ ⚠️ `@v1.1 draft → @v1.1 published`（待 `piao-evolution-scan.sh` MVP + `m6-final-decisions@v1`）
- **M6 milestone 封板**：`urn:piao:snapshot:kernel:m6_final_decisions@v1 published`（⚠️ 待产 · 对标 M5 final decisions 范式）

**四段式 review 产出清单**：
| 段 | 起稿 commit | 内容范围 | 行数增量 |
|---|-----------|-------|-------|
| 第一段 | `4b1e7b9e` | §0 + §1（1.1/1.2/1.3/1.4/1.5）| +180 |
| 第二段 | `56d1ddc8` | §2（Q21–Q26）+ §3（A1–A4 + B1–B2 + 顺序 + M5 对标）| +207 |
| 第三段 | `f546719b` | §4（4.1/4.2/4.3/4.4）+ 原 §5 状态行刷新 | +~120 |
| **第四段** | 本次 commit | **§5 路径 A/B 消化记录**（§5.1–§5.7 · S5 追补）+ 原 §5 下移为 §6 + §6 状态行刷新 | +~130 |
| **合计** | — | **全文约 640 行** | — |

---
