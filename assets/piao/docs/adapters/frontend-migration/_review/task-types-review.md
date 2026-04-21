---
urn: urn:piao:artifact:adapter/frontend_migration:task_types_review@v1
artifact_type: report.review
kind: artifact
rev: v1
status: published
schema_version: 1.0
created_at: 2026-04-18T23:05:00+08:00
created_by_event: manual-task-types-review-260418
content_sha256: ""
depends_on:
  - urn:piao:artifact:adapter/frontend_migration:task_types@v1
  - urn:piao:artifact:adapter/frontend_migration:charter@v1
  - urn:piao:proposal:kernel:post_m1_kickoff@v1
  - urn:piao:evolution_source:kernel:m1_debt_ledger@v2
produced_by:
  actor: human:caleb
  task_urn: urn:piao:task:adapter/frontend_migration:task_types_review
  event_id: manual-task-types-review-260418
---

# Task Types Review · frontend-migration adapter task-types@v1

> 本 review 是 `post-m1-kickoff.md §3.3` 强制三段式格式的第 2 份 adapter review。
> 定位：**把第 2 份 adapter 文档再次当作 kernel 的压测仪**，输出新的缺口证据与修订建议；决定阶段 2 是否继续（2a→2a 继续 or 2a→2b 转向）。
> 配对对象：`task-types.md@v1`。

---

## 0. 出厂自查

- [x] task-types.md front-matter 五要素齐全（URN / artifact_type / depends_on / extends.kernel_anchor / provenance）
- [x] task-types.md 显式 `extends` 指向 kernel `07 §2 扩展点 A`
- [x] `./scripts/kernel-wordcheck.sh --file task-types.md` exit=0（4 条 WARN 均为 `viewmodel` / `migration` 在 adapter 目录的合法使用）
- [x] task-types.md §1 类型总表覆盖 kernel 四个基础类型中的 ≥2 类（实际覆盖 3 类：`file_op` / `code_gen` / `verification` / `integration` 中三类，仅 `integration` 为 §2.7 一条，其余各 ≥2 条）
- [x] §4 主动产出新的 kernel 压测点（本文件的核心价值）

---

## 1. 引用的 kernel 锚点

| kernel 锚点 | task-types.md 中的使用位置 | 用途 |
|------------|--------------------------|-----|
| `kernel/07-extensibility.md §2 扩展点 A` | front-matter `extends.kernel_anchor` + §1 类型总表 + §5 承诺 | Task 类型派生的契约源 |
| `kernel/07-extensibility.md §2 扩展点 A` 基础类型四行表 | §1 / §2.1-§2.7 每行 `base` 列 | 所有派生的合法上游集合 |
| `kernel/01-identity-model.md §2` kind 枚举 | §2.2 module_migration 的不变量回顾 + §5.2 承诺 2 | "不扩展 kind" 的硬约束 |
| `kernel/01-identity-model.md §3.1` 业务实体 scope 段以 unit 开头 | §2.1 `unit_urn` 字段 + §2.3 `unit_urn` | task 的归属锚点必须对齐 unit |
| `kernel/02-artifact-model.md §2` artifact_type 派生 | §2.7 `emits: artifact.build_output` + §4 [N1] 压测 | `emits` 字段合法性 |
| `kernel/02-artifact-model.md §2.1` kind 与 artifact_type 映射 | §4 [N1] 临时裁决的依据 | 判断 `artifact.*` 派生是否可行 |
| `kernel/03-layered-architecture.md §3.1` L1 事件枚举 | §2 每类的"关联 L1 事件"段 + §3.3 拓扑违规处理 | L2 事件必须挂 L1 |
| `adapters/frontend-migration/00-charter.md §4.1` 占位清单 | §1 类型总表（展开 charter 占位） | 验证 charter→task-types 的连续性 |
| `adapters/frontend-migration/00-charter.md §5.1` 承诺 1 / 4 / 5 | §5 承诺的三条细化 | 承诺的具体化映射 |

**锚点覆盖评估**：共 **9 条 kernel / charter 锚点**，其中 kernel 直接引用 7 条（跨 `01` / `02` / `03` / `07` 四篇 kernel 文档）。对比 charter review 的 15 条，数量下降属**预期**——charter 本就是扇出最广的入口文档，单点文档（task-types）聚焦扩展点 A 即可。

**满足门控**：post-m1-kickoff §3 对阶段 2 后续文档**未强制** ≥5 锚点数量（这是阶段 1 的硬约束）；本文件 7 条 kernel 锚点仍远超该参考标准。

---

## 2. 在 kernel 中找不到答案的问题

> 本次压测的**增量**缺口——charter-review 的 Q1-Q4 不在本节重复登记（已在 `M1-debt-ledger §1.2`）。

### [Q5] `artifact.*` 派生类型的合法命名路径 kernel 未示范

**卡点**：写 `task-types.md §2.7 host_build` 的 `emits` 时，需要一个"构建产物"的 artifact 类型。kernel `02 §2` 的派生示例（`spec.structured` / `code.component` / `report.verify` 等）**没有覆盖"构建产物 / 可执行包"这类非"spec / code / report"的资产**。

**触发场景**：`host_build` 任务要输出一个代表"编译后产物"的 artifact URN。

**临时裁决**：使用 `artifact_type: artifact.build_output`——即 kind (`artifact`) 直接作为前缀。理由：kernel `02 §2.1` 的"kind 与 artifact_type 映射"规则里允许 `artifact_type` 以 kind 名开头（未禁止），但**无示例**。

**严重性**：**中**——不阻塞本 adapter，但"构建产物"在几乎所有后续 adapter 都会遇到；kernel 若不示范会出现各 adapter 各立门户的风险。

---

### [Q6] 派生类型命名风格（snake_case / dot.lowercase）kernel 未约束

**卡点**：
- task `type` 字段在 kernel `07 §2 扩展点 A` 示例中用 snake_case（如 `component_migration`）
- artifact `artifact_type` 字段在 kernel `02 §2` 示例中用 dot.lowercase（如 `code.component`）
- 两边的分隔符风格不一致，**kernel 没有明确说"这两条命名规则故意不同"还是"只是示例恰好这样"**

**触发场景**：本文件需要同时定义 task type 名与它 `emits` 的 artifact_type 名；写到 `emits: code.component` 与 `type: component_migration` 并排出现时意识到这一差异。

**临时裁决**：本 adapter 内部规则：
- task `type` 用 snake_case（kernel 扩展点 A 示例风格）
- artifact `artifact_type` 用 dot.lowercase，dot 后的段用 snake_case（合并两个约定）

**严重性**：**低**——不阻塞，但会影响多 adapter 一致性。

---

### [Q7] 扩展点 A 的"adapter 自验证"机制 kernel 未提供

**卡点**：kernel `07 §2 扩展点 A` 列出了硬约束（"`type` 可追溯到基础类型" / "kernel 只读共有字段"），**没有给 adapter 一套可执行的自验证 checklist 或测试集**来证明"我这份 task-types 文档/代码确实满足这些硬约束"。

**触发场景**：task-types.md §6 写"自验证清单"时不得不**自己拟定**清单——这本该是 kernel 提供的复用资产。

**临时裁决**：本文件 §6 给出 5 条自拟 checklist（带 `[x]` 实测），并标注"待 kernel 正式测试集发布后废弃本节"。

**严重性**：**中**——随 adapter 数量增加会放大。单 adapter 时各自写清单尚可接受；超过 2 个 adapter 时"清单漂移"会成为一个持续的治理负担。

---

### 小结

| 条目 | 严重性 | 与 charter-review 的关系 |
|------|--------|----------------------|
| [Q5] `artifact.*` 派生类型合法路径未示范 | 中 | 独立新增（charter 未触及构建产物类型） |
| [Q6] task type / artifact_type 命名风格未统一 | 低 | 独立新增 |
| [Q7] 扩展点 A 的 adapter 自验证机制缺失 | 中 | 与 Q3（占位声明最小字段集）同源但**不同层**：Q3 是"声明格式"，Q7 是"验证机制" |

**增量缺口总数**：**3 条**（2 中 + 1 低）

**累计缺口**（`M1-debt-ledger §1.2` 登记后的全量）：charter Q1-Q4 + 本文件 Q5-Q7 = **7 条**。

---

## 3. 对 kernel 的建议修订

### [R5] 对应 [Q5] —— 在 `kernel/02-artifact-model.md §2` 的派生示例表中补一行 `artifact.build_output` / `artifact.asset_bundle`

**建议变更**：扩充派生示例表，示范形如 `artifact.build_output` / `artifact.asset_bundle` 等"资产型"派生的合法写法，并显式说明"kind 作为 dot 前缀是合法的（与 `code.*` / `report.*` 同列）"。

**影响范围**：`02-artifact-model.md` 升 `@v1.1`；可与 [R2] 合并为同一次小升。

**优先级**：**中**（[Q5]）

---

### [R6] 对应 [Q6] —— 在 `kernel/01-identity-model.md §4` 或 `kernel/07-extensibility.md §2` 末尾增补"派生名命名风格"非强制建议

**建议变更**：
- task `type` → snake_case
- artifact `artifact_type` → dot.lowercase（dot 前是 kind，dot 后的段用 snake_case）
- 以"约定优于强制"的口吻写入，不进入校验器硬约束

**影响范围**：kernel 小版本文案修订；不触发 schema 变更。

**优先级**：**低**（[Q6]）

---

### [R7] 对应 [Q7] —— 在 `kernel/07-extensibility.md §2` 末尾新增"扩展点合规性自验证套件 v0.1"

**建议变更**：为四个扩展点各提供一份最小自验证 checklist（可放在同一节，每扩展点一小节）。checklist 内容必须是**可断言的**（能被 shell / python 脚本机械化判定），不是"人肉 review"。

**示例（扩展点 A）**：
- 断言 1：task_types.md / task_types.yaml 中所有 `type` 的值在 `base` 列都有**合法基础类型**（kernel 四选一）
- 断言 2：每个派生类型的"必需字段"集合是 kernel 基础类型共有字段的**真超集**
- 断言 3：所有派生类型的 `emits` 字段指向的 `artifact_type` 合法（通过 [R5] 建议的扩充表可被机械校验）

**影响范围**：`07-extensibility.md` 升 `@v1.1`；可**合并** [R4] 的"占位声明格式"建议（同属扩展点 A 的治理工具）。

**优先级**：**中**（[Q7]）

---

## 4. 下一步行动

按 `post-m1-kickoff §2.3` 分支判定规则再评估一次：

**累计缺口 7 条**（含 1 条 charter 高严重性 Q1 + 2 条 task-types 中严重性 Q5/Q7），**仍在分支 2a 触发条件内**（"缺口 ≥ 3 条且至少一条高/中严重性 → 2a 继续"）。

但已经靠近**拐点**：post-m1-kickoff §2.3 定义 "凑够 5–7 条真实缺口后再**统一**处理"——**现在正好达到 7 条下界**。

### 4.1 阶段 2 子路径决策

**路径 A（推荐）· 收敛 + 回补 kernel**：
- 停止再写第 3 份 adapter 文档
- 将 [R1]–[R7] 合并为**一次 kernel 小版本**：
  - `01-identity-model.md` 升 `@v1.1`（处理 [R1]）
  - `02-artifact-model.md` 升 `@v1.1`（处理 [R2] + [R5]）
  - `07-extensibility.md` 升 `@v1.1`（处理 [R4] + [R7]；[R6] 放 `07` 末尾）
  - [R3] 本就是 `M1-debt-ledger §1.2` 的自有升降，无需与 kernel 主文档合并
- 完成后重新评估：kernel 的健壮度是否足以启动工作流 A（M4 Snapshot）
- 预期结论：健壮度足够 → 阶段 2 收尾 → 进入**分支 2b**（启动 M4 Snapshot）

**路径 B（较慢但更稳）· 再写一份 adapter 文档确认稳定**：
- 继续写第 3 份（如 `acceptance-criteria.md`，压测扩展点 B）
- 若无新增 ≥中严重性缺口 → 说明 kernel 已饱和 → 走路径 A

**本 review 推荐**：**路径 A**——因为 7 条缺口已覆盖 3 个扩展点（A 通过 Q5-Q7，C 通过 Q2 间接，D 通过 Q3 间接）与 2 个身份模型维度（Q1 scope / Q6 命名），**压测的横向广度足够**；再写一份文档大概率会凑到 8-10 条同质缺口，边际价值下降，不如先做一次 kernel 小升消化证据。

### 4.2 立即动作

1. **立即**：将 [Q5]–[Q7] 三条缺口与 [R5]–[R7] 三条建议**追加登记**到 `M1-debt-ledger §1.2`（触发 ledger 再升一次 rev v2→v3）
2. **立即**：在 `task-types.md` 的 §7 演进条款里更新"配对 review 已就绪"
3. **下一步（由人类决策）**：选择路径 A 或 B；若选 A，起草 kernel 三文档的 `@v1.1` 小升 proposal；若选 B，起草 `acceptance-criteria.md`

---

**本 review 状态**：published（2026-04-18 23:05）
**上游锚点**：
- `urn:piao:artifact:adapter/frontend_migration:task_types@v1`
- `urn:piao:artifact:adapter/frontend_migration:charter@v1`
- `urn:piao:evolution_source:kernel:m1_debt_ledger@v2`（本 review 的产出将触发其升 v3）
**关联 proposal**：`urn:piao:proposal:kernel:post_m1_kickoff@v1` · §2.3 阶段 2 分支 2a 第 2 份
**下游触发**：
- `M1-debt-ledger` rev v2→v3（§1.2 追加 Q5-Q7）
- 本 review 为阶段 2 推荐**路径 A**（kernel 小升）的主要证据
