---
urn: urn:piao:artifact:adapter/frontend_migration:charter_review@v1
artifact_type: report.review
kind: artifact
rev: v1
status: published
schema_version: 1.0
created_at: 2026-04-18T22:25:00+08:00
created_by_event: manual-charter-review-260418
content_sha256: ""
depends_on:
  - urn:piao:artifact:adapter/frontend_migration:charter@v1
  - urn:piao:snapshot:kernel:m1_final_decisions@v1
  - urn:piao:proposal:kernel:post_m1_kickoff@v1
produced_by:
  actor: human:caleb
  task_urn: urn:piao:task:adapter/frontend_migration:charter_review
  event_id: manual-charter-review-260418
---

# Charter Review · frontend-migration adapter 00-charter

> 本 review 是 `post-m1-kickoff.md §2.2` **阶段 1 门控 3** 的收尾产物，与 `00-charter.md` 配对存在。
> 定位：**本 review 不打分 charter 写得好不好，只负责两件事**——① 登记 charter 在 kernel 中找不到答案的问题；② 给出对 kernel 的建议修订条目。
> 本 review 的结论决定 `post-m1-kickoff.md §2.3` 进入分支 2a（继续写第 2 份 adapter 文档）还是分支 2b（启动 M4 Snapshot）。
> 强制格式遵循 `post-m1-kickoff.md §3.3` 三段式。

---

## 0. 出厂自查

- [x] charter front-matter 五要素齐全（URN / artifact_type / content_sha256（待工具填） / provenance / depends_on）
- [x] charter 显式引用 kernel ≥5 篇章节锚点（实际覆盖 4 篇 kernel 文档 + scenario-wordlist + 3 份 M1 review 产物）
- [x] `./scripts/kernel-wordcheck.sh --file adapters/frontend-migration/00-charter.md` exit=0（实测 3 条 WARN，均为 adapter 目录下合法使用）
- [x] 产出本 review 文档

---

## 1. 引用的 kernel 锚点

> 目的：验证"kernel 足够可被引用"。每一条都对应 charter 正文的一处 §x 引用。

| 引用 kernel 锚点 | charter 中的使用位置 | 用途 |
|-----------------|-------------------|-----|
| `kernel/00-overview.md §1` 核心公式 7 维 | §0 Charter 定位 | 锚定 adapter 必须对齐的 7 个 kernel 维度 |
| `kernel/01-identity-model.md §1.1` URN grammar | §1.1 基本信息 / §1.2 scope 分工 | adapter scope URN 组装 |
| `kernel/01-identity-model.md §2` kind 枚举 | §5.1 承诺 1 | 不扩展 kind 的硬约束 |
| `kernel/01-identity-model.md §3.1` 通过 scope 段表达业务归属 | §1.2 scope 分工的决策依据 | 分清 adapter scope 与 unit scope |
| `kernel/01-identity-model.md §3.3` 校验器如何识别越界 | §1.2 末尾决策理由 | 解释为何业务产物不挂 adapter scope |
| `kernel/02-artifact-model.md §1` 五要素契约 | charter front-matter + §6.1 | artifact 最小 schema |
| `kernel/02-artifact-model.md §2` artifact_type 派生规则 | §5.2 N2 诉求 | 申请 `spec.charter` 的合法性 |
| `kernel/02-artifact-model.md §2.1` kind 与 artifact_type 映射 | charter front-matter `kind: artifact` + `artifact_type: spec.charter` | 双字段必须一致 |
| `kernel/02-artifact-model.md §6` 生命周期 | §7 本 charter 的演进 | draft→published→superseded 路径 |
| `kernel/03-layered-architecture.md §2.3` L1/L2 事件关联 | §5.1 承诺 5 | L2 事件必须挂 L1 |
| `kernel/03-layered-architecture.md §3.1` L1 事件枚举 | §3.2 不归 adapter 管的事项 | 识别事件结构变更归 kernel |
| `kernel/07-extensibility.md §1` 五条硬边界 | §5.1 全部 6 条承诺 | adapter 的硬约束来源 |
| `kernel/07-extensibility.md §2` 四个扩展点 | §4 四个扩展点占位声明 | 逐一占位声明 |
| `kernel/07-extensibility.md §6` 维护规则 | §5.1 承诺 6 | adapter 目录边界约束 |
| `kernel/scenario-wordlist.md §2/§3` 禁用词 + 受限词 | 通篇写作约束 | adapter 写作词汇选择 |

**锚点覆盖评估**：**15 处 kernel 锚点**，远超门控要求的 ≥5，且横跨 kernel 全部 4 篇已 published 文档。验证 kernel 具备"被 adapter 引用的最小能力集"。

---

## 2. 在 kernel 中找不到答案的问题

> 这是本 review 的**核心产物**。每一条都是一个具体的 charter 写作卡点，触发场景真实。条目数决定 `post-m1-kickoff.md §2.3` 的分支路径。

### [Q1] adapter scope 与 unit scope 的分工没有显式章节

**卡点**：charter §1.2 必须回答"这个 adapter 自身资产（charter / task-types / acceptance）用什么 scope？业务单元产物用什么 scope？"——kernel `01 §3.1` 隐含提到"业务专属实体 scope 须以 unit 名开头"，但**没有正面回答 adapter 自身资产的 scope 约定**。

**触发场景**：写 charter front-matter 的 URN 时立刻遇到。

**临时裁决**：charter §1.2 给出了两段分工（adapter 自身用 `adapter/<name>`，业务单元用 unit 名），需要 kernel 确认。

**严重性**：**高**—— 未来每个新 adapter 都会撞到同一问题。

---

### [Q2] `artifact_type: spec.charter` 是否为合法派生？

**卡点**：charter front-matter 写 `artifact_type: spec.charter`，但 kernel `02 §2` 的派生示例只给了 `spec.structured` / `spec.api_contract`，没有明确"派生的**登记流程**"——是 adapter 自用即可，还是需要在 kernel 层面登记？

**触发场景**：charter front-matter 填写。

**临时裁决**：按 `02 §2` 的 `.` 分层约定自用，不向 kernel 登记，但在本 review §3 R2 里给 kernel 提修订建议。

**严重性**：**中**—— 不阻塞 charter，但长期会有多 adapter 乱派生 `spec.xxx` 的风险。

---

### [Q3] 四扩展点的"占位声明"缺最小字段集

**卡点**：kernel `07 §2` 给了四个扩展点的完整 schema（正式注册时），但没有说"adapter 启动期**占位**声明时最少写什么"。charter §4 是凭经验写的，不同 adapter 可能写法大相径庭。

**触发场景**：charter §4 四个扩展点的格式选择。

**临时裁决**：按 "派生名 | 继承的 kernel 基础类型 | 语义" 三列写，其他细节留给后续 `task-types.md`。

**严重性**：**低**—— adapter 间可以互相参考格式收敛，kernel 层暂不需要强约束。

---

### [Q4] kernel `00-overview.md:93` 出现了 `viewmodel` WARN（kernel 内部遗留）

**卡点**：跑 `kernel-wordcheck.sh --ci` 时发现 `docs/piao-pipeline/00-overview.md:93` 有一条 `viewmodel` WARN，来自 "TaskType 扩展: component/module/viewmodel"——这属于 kernel 文档引用 adapter 场景词，**M1-debt-ledger §1.1 没有登记**。

**触发场景**：charter 写完跑全量 wordcheck 验收时发现。

**临时裁决**：本 review 不处理，但登记到本 §3 R3，建议并入 `M1-debt-ledger §1.1` 或起新的 §1.2 条目。

**严重性**：**低**——只是 WARN，不阻塞；但遗漏登记是 kernel 自己的卫生问题，应补。

---

### 小结

| 条目 | 严重性 |
|------|--------|
| [Q1] adapter scope 与 unit scope 分工 | **高** |
| [Q2] `spec.charter` 合法性与派生登记流程 | 中 |
| [Q3] 扩展点占位声明的最小字段集 | 低 |
| [Q4] kernel overview.md `viewmodel` WARN 遗漏登记 | 低 |

**缺口总数**：**4 条**（1 高 + 1 中 + 2 低）

**对 `post-m1-kickoff.md §2.3` 分支判定的影响**：
- 规则："缺口 ≥ 3 条且至少一条高严重性 → 分支 2a"
- 结论：**进入分支 2a**——先登记 4 条缺口到 `M1-debt-ledger.md §1.2`，继续写第 2 份 adapter 文档，不启动 M4 Snapshot 草案。

---

## 3. 对 kernel 的建议修订

> 每一条建议都精确到 kernel 文档的**某一节**与**建议变更类型**（新增 / 澄清 / 修正）。

### [R1] 对应 [Q1] —— 在 `kernel/01-identity-model.md §3` 新增"§3.4 adapter 自身资产 scope 约定"

**建议变更**：新增一小节，明确：

> adapter 自身的资产（charter / task-types.yaml / acceptance.yaml 等）的 URN scope 使用 `adapter/<adapter_name>`（下划线分隔内部字符）；业务单元（被 adapter 处理的 unit）的产物 URN scope 直接使用 unit 名，**不加 adapter 前缀**。
>
> 校验器（§3.3）判断规则：位于 `adapters/<name>/` 目录下的文件若其 URN scope 不以 `adapter/<name>` 或某个 unit 名开头 → 警告。

**影响范围**：`01-identity-model.md` 升 `@v1.1`（点分版本，兼容性补充）；`adapters/README.md` 的"新增 adapter 最小 Checklist"同步加一条自检。

**优先级**：**高**（[Q1]）

---

### [R2] 对应 [Q2] —— 在 `kernel/02-artifact-model.md §2` 的派生类型段补"派生注册方式"小节

**建议变更**：在 §2 "派生子类型"附近补一段：

> adapter 自用派生（如 `spec.charter` / `spec.structured` / `report.review`）**无需向 kernel 登记**，但必须：
> 1. 派生名在本 adapter 目录内唯一（防止本 adapter 内同名歧义）
> 2. 派生名的语义不与现有 kernel 基础类型冲突（如不得用 `spec.log`——`log` 是另一个基础类型）
> 3. 若某派生名被**两个以上 adapter 使用**，触发"升 kernel"流程（在 `02 §2` 表格中正式登记为 kernel 级派生，随 `02` rev 升降）

**影响范围**：`02-artifact-model.md` 升 `@v1.1` 或并入阶段 3 `@v2`；不阻塞现有 adapter 开发。

**优先级**：**中**（[Q2]）

---

### [R3] 对应 [Q4] —— 在 `M1-debt-ledger.md §1` 开 `§1.2` 章节收纳新增遗留

**建议变更**：在 `kernel/_review/M1-debt-ledger.md` 新开 §1.2 "Post-M1 阶段发现的 kernel 遗留"，首批登记：

- `docs/piao-pipeline/00-overview.md:93` 的 `viewmodel` WARN
- 未来阶段 1–2 过程中发现的任何 kernel 词表违规

处置方案：并入阶段 3 的 `02-artifact-model.md@v2` 清理时一并处理。

**影响范围**：`M1-debt-ledger.md` 升 `@v2`；不触发 kernel 主文档 rev 升降。

**优先级**：**低**（[Q4]）

---

### [R4] 对应 [Q3] —— `kernel/07-extensibility.md §2` 末尾补"扩展点占位声明建议格式"

**建议变更**：补一段非强制性参考，列出占位声明的最小字段集（名 / 继承类型 / 语义 / 落地状态）。**不强制**，只作为新 adapter 的起步模板。

**影响范围**：`07-extensibility.md` 升 `@v1.1`；不影响现有 adapter。

**优先级**：**低**（[Q3]）

---

## 4. 下一步行动

按 §2 分支判定为 **2a**，后续动作：

1. **立即**：将 [Q1]–[Q4] 四条缺口以 `§1.2` 形式登记进 `kernel/_review/M1-debt-ledger.md`（触发 `M1-debt-ledger` rev v1→v2）
2. **立即**：将本 review 的 4 条 R 建议登记进 `post-m1-kickoff.md` 的下游候选清单（作为阶段 2 的输入）
3. **阶段 2 开始**：写第 2 份 adapter 文档（候选：`10-event-mapping.md` 或 `task-types.md`），继续积累 kernel 反馈
4. **暂不启动**：工作流 A（M4 Snapshot Model）继续冻结，等阶段 2 结束再评估

---

**本 review 状态**：published
**上游锚点**：`urn:piao:artifact:adapter/frontend_migration:charter@v1`
**关联 proposal**：`urn:piao:proposal:kernel:post_m1_kickoff@v1` · §2.2 阶段 1 门控 3
**下游触发**：
- `M1-debt-ledger.md` rev v1→v2（新增 §1.2）
- `post-m1-kickoff.md` §2.3 分支判定结果登记
- 阶段 2 第 2 份 adapter 文档启动
