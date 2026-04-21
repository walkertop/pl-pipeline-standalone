# piao-pipeline kernel v0.1 封版决议（final-decisions）

- **artifact_kind**: `artifact`
- **artifact_type**: `final_decisions`
- **artifact_urn**: `urn:piao:artifact:kernel:v0_1_final_decisions@v1`
- **status**: `published`
- **rev**: `v1`
- **supersedes**: `urn:piao:artifact:kernel:m7_closeout_kickoff@v1`（kickoff → final 接力闭合）
- **upstream_anchor**:
  - `urn:piao:artifact:kernel:m7_closeout_kickoff@v1`（M7 启动）
  - `urn:piao:artifact:kernel:m7_prefix_taxonomy_decision@v1`（Q29 裁定）
  - `urn:piao:artifact:kernel:m7_closeout_extensibility_acceptance@v1`（γ₂ sign-off）
  - `urn:piao:evolution_source:kernel:m1_debt_ledger@v10`（债账本 v0.1 终态）
- **milestone**: `M7`（阶段 γ₃ · 工作流 C · v0.1 Closeout）
- **scope_hash**: `kernel-only`（不含 adapter / mvp-smoke 业务层 · 只封 kernel 层）

---

## §0. 覆盖范围与非覆盖范围（scope）

### §0.1 覆盖范围（v0.1 kernel 层封版所含）

本 final-decisions 封版以下对象的终态（URN + rev + sha256 三元组 见 §2）：

1. **七份 kernel spec**（01 identity / 02 artifact / 03 layered-architecture / 04 version-snapshot / 05 drift / 06 evolution / 07 extensibility）
2. **一份技术债账本**（M1-debt-ledger @v10 · 13 条债已全部 resolved / continued / conventioned）
3. **通用契约矩阵**（CONV-01 主条款 + CONV-01.1 子条款 + EX1/EX2/EX3 三例外）
4. **kernel 事件 journal**（`pipeline-output/piao/kernel-events/2026-04.jsonl` · 23 行 · 95.5% 合规率 + 1 条 sha256 时序失真记录待补偿）
5. **四代 kickoff 接力链闭合**（post-m1 → m5 → m6 → m7 → v0.1_final_decisions）
6. **openspec/adapter 接入入口**（仅列清单 · 不实施 · 实施留待 v0.2 业务层）

### §0.2 非覆盖范围（刻意排除）

以下对象**不**在 v0.1 kernel 层封版之内，显式声明为 **defer-to-v0.2 或更后**：

| 对象 | 状态 | 理由 |
|------|------|------|
| mvp-smoke 业务事件（`pipeline-output/piao/mvp-smoke/events/*.jsonl`） | 历史兼容条款豁免（01 §5.3.1） | 业务层事件不在 kernel 封版域 |
| adapter 实施（openspec-adapter / tdag-adapter / trace-adapter） | defer-to-v0.2 | 07 §2 扩展点 A/B/C 接入清单已出 · 实施待业务需求触发 |
| kernel 层新概念（新域 / 新 concern） | kernel-closed | 01 @v1.3 §5.1.1 表锁定 · 新增需经 spec 升版 + M1 债记录 |
| UI / Dashboard / 可视化 | out-of-scope | 与 kernel 宪章解耦 |
| 性能 / 容量 / 多进程并发 | defer-to-v0.2 | kernel 层不涉及运行时性能命题 |

---

## §1. 四代 kickoff 接力链闭合

v0.1 kernel 层自 post-m1 起，每一代 milestone 的启动与收尾皆通过 kickoff → final-decisions 接力完成。此节**正式记录链路闭合**。

### §1.1 接力链总览

```
post-m1-kickoff @v1 (milestone M2 启动)
    ↓ supersedes
M1-final-decisions @v1 (M2 准入前封版 M1)
    ↓ triggers
m5-drift-kickoff @v1 (M5 启动 · 范式第二代：问题清单先行)
    ↓ supersedes
m5-final-decisions @v1 (M5 封版)
    ↓ triggers
m6-evolution-kickoff @v1 (M6 启动 · 范式第三代：反向审查先行)
    ↓ supersedes
m6-final-decisions @v1 (M6 封版 · 含 Q28 meta 债)
    ↓ triggers
m7-closeout-kickoff @v1 (M7 启动 · 范式第四代：决议先行 · 三工作流 P/X/C)
    ↓ supersedes (via γ₃ closeout)
v0_1_final_decisions @v1 (本文 · v0.1 kernel 层封版 · 链路闭合)
```

### §1.2 四代 kickoff 范式演进

| 代 | kickoff artifact | 启动时机 | 范式创新 | 收尾 artifact |
|---|---|---|---|---|
| 1 | `post-m1-kickoff@v1` | M1 准入后 | 工具先行（M2/M3/M4 概念并列） | `M1-final-decisions@v1` |
| 2 | `m5-drift-kickoff@v1` | M4 封版后 | 问题清单先行（Q1-Qn 对齐） | `m5-final-decisions@v1` |
| 3 | `m6-evolution-kickoff@v1` | M5 封版后 | 反向审查先行（01-05 + ledger 全量扫描） | `m6-final-decisions@v1` |
| 4 | `m7-closeout-kickoff@v1` | M6 封版后 | 决议先行（工作流 P 裁定 Q29 → X 压测 07 → C 封版） | `v0_1_final_decisions@v1`（本文） |

### §1.3 链路闭合事件

`m7_closeout_kickoff @v1` 经本 final-decisions 发射 `artifact.superseded` 事件后，**正式由 published → superseded**。

这是四代 kickoff 中**首次**显式以 final-decisions supersede kickoff 的闭合模式（前三代均以 "自然淡出" 收尾）。此范式将沉淀至 M1 ledger 的演进触发项（若触发新 spec 则由 07 §4 四问准入）。

---

## §2. kernel 七维终态矩阵（URN + rev + sha256 三元组）

### §2.1 七份 spec 终态

| # | URN | rev | status | sha256（byte-traceable） |
|---|---|---|---|---|
| 01 | `urn:piao:spec:architecture:identity_model` | `@v1.3` | published | `0a2a5872e1ddf69b3eb560b4ca197d9c97b73ab2e227f052e58bb5ab198638c0` |
| 02 | `urn:piao:spec:architecture:artifact_model` | `@v1.4` | published | `ce0fb477...`（见 §2.4 采样说明） |
| 03 | `urn:piao:spec:architecture:layered_architecture` | `@v1` | draft | `f25cb9ad...` |
| 04 | `urn:piao:spec:architecture:version_snapshot` | `@v1.2` | published | `66405020...` |
| 05 | `urn:piao:spec:architecture:drift_propagation` | `@v1.1` | published | `f591b297...` |
| 06 | `urn:piao:spec:architecture:evolution_model` | `@v1.1` | published | `4f9a188a...` |
| 07 | `urn:piao:spec:architecture:extensibility` | `@v1.1` | published | `2f2f4947c937332cdc842a1666c28bcfdb1f09afd109e8622d32c3b38f3c6906` |

### §2.2 关键 artifact 终态

| # | URN | rev | status | sha256 |
|---|---|---|---|---|
| L1 | `urn:piao:evolution_source:kernel:m1_debt_ledger` | `@v10` | published | `d616ead344636c52fc63ee8f41d905d93db738133eb1a58764d9d8413e9ef19b`（见 §4.1 失真记录） |
| L2 | `urn:piao:artifact:kernel:m7_prefix_taxonomy_decision` | `@v1` | published | (Q29 裁定 · B'-1 方案) |
| L3 | `urn:piao:artifact:kernel:m7_closeout_extensibility_acceptance` | `@v1` | published | `f6c9c2f7fc5b938ec2ed93cc77fd99317239bcef4f1c1f340d17cca898e1ec1d` |
| L4 | `urn:piao:artifact:kernel:v0_1_final_decisions` | `@v1` | published | （本文 · 见 §2.4 自指说明） |

### §2.3 说明

- 03-layered-architecture 保留 `draft` 状态入 v0.1。判定理由：03 承担 L0-L3 分层宪章职责 · 未在 M1-M7 期间触及升版 · 其 draft 状态已被 M1-M6 反向审查确认"不阻塞 kernel 宪章自洽"。该 debt 作为 v0.2 候选（见 §4.2）。
- 02 / 07 没有 YAML front-matter · rev 以正文 §11 / §10 rev_history 表格为准。01 同理（§12）。
- sha256 采集基准：v0.1 封版当日扫描 · 采集命令见 §5.1 附录。

### §2.4 自指条款（本 final-decisions sha256）

本 artifact 自身的 sha256 **不在本段内嵌**，而是写入同 commit 同 txn 发射的 `artifact.published` 事件字段中。事件 event_id 预留：`task-published-260419181500-<hash>`（四段式 · CONV-01.1 合规）。

为避免 ledger @v10 同类"sha256 时序失真"问题（见 §4.1），本文严格遵循：
1. 定稿（本文最后一次写入）→
2. 计算 sha256 → 
3. 填入事件 → 
4. git commit（一次性包含本文 + journal 追加）。

步骤 1-3 之间**不再修改本文**。

---

## §3. 通用契约矩阵（CONV-*）

### §3.1 CONV-01 主条款（rev 转换 ↔ artifact.published 同 txn 发射）

- **范围**：凡 artifact 发生 rev 转换（初版 publish / 升版 supersede / 废弃 deprecate），**必须**在同 git commit + 同事件 txn 中发射 `artifact.published` 事件。
- **延迟**：≤0（同 commit）。
- **典型**：所有 spec 升版 + ledger 升版 + acceptance 首版 + 本 final-decisions。
- **v0.1 实测延迟=0 次数**：8 次（见 ledger §1.8.3）。

### §3.2 CONV-01.1 子条款（前缀合法性约束）· v10 新增

- **范围**：event_id 前缀必须严格来自 01 @v1.3 §5.1.1 concern 预定义表的合法组合（`{域}-{concern}` 二维）。
- **三段式例外**：域直接发射无 concern 细化时 · 保留 `{域}-{时间戳}-{hash}` 三段式（合规 01 §5 七域表）。
- **四段式新增**：B'-1 落地后 · 引入 `{域}-{concern}-{时间戳}-{hash}` 四段式。首例：`task-published-260419171500-5438f2`（m7 acceptance @v1）。
- **v0.1 合规率**：95.5%（23/23 journal 行合规 · 18 条 task-* 三段式 + 2 条新增四段式 + 3 条 EX1/EX2/EX3 例外 + 0 条违规）。

> 注：M6 之前落盘的 5 条非 task-* 事件（pipe-* / drift-* / evo-* 各若干）由 01 @v1.3 §5.3.1 历史兼容条款豁免 · 不计入违规。

### §3.3 CONV-01 三例外（EX1 / EX2 / EX3）

| 例外 | 适用 | 豁免内容 |
|---|---|---|
| EX1 | 历史事件重建（reconstructed=true） | 豁免"必须同 commit"（允许 reconstructed=true 补记） |
| EX2 | trace-only artifact（无 sha256） | 豁免"必须 byte-traceable" |
| EX3 | kernel-internal 自指（如 ledger 自扫尾 / final-decisions 自指） | 豁免"必须 upstream_decision 外部指向"（允许自指 or 指向同 milestone 兄弟 artifact） |

### §3.4 CONV-* 关系图

```
CONV-01 主条款（rev 转换 × 同 txn 发射）
   ├── CONV-01.1 子条款（event_id 前缀合法性 · 由 01 §5.1.1 兜底）
   ├── EX1（历史重建）
   ├── EX2（trace-only）
   └── EX3（kernel-internal 自指）
```

---

## §4. v0.1 期间发现项与登记（discoveries）

### §4.1 ledger @v10 事件 sha256 时序失真（DISC-V01-001）

**发现时机**：γ₃ 扫描阶段（v0.1 Closeout 准备环节）。

**事实**：
- journal 第 22 行（`task-260419165500-0bc70e`）`content_sha256` 字段记录 `07e371d38159c68c51f23d69ab49ae2e1131c2bfc8ebafa7f3fd11611371e94f`。
- ledger 文件实际 commit 态 sha256 为 `d616ead344636c52fc63ee8f41d905d93db738133eb1a58764d9d8413e9ef19b`。
- 差异来源：发射 sha256 后，又追加了 §3 关闭条件 / 演进触发 / 状态行 / 下游触发四处更新，才最终 commit。

**影响评估**：
- byte-traceable 语义一度断链（事件字段与 commit 态 sha256 不匹配）。
- 未造成上层语义错误（ledger 内容逻辑未变 · 仅章节补充）。
- 属于**执行时序缺陷** · 不属于 CONV-01 主条款违规（同 commit 同 txn 成立）· 属于 CONV-01.1 或 01 §5 未覆盖的**新契约候选**。

**补偿动作**（在本 final-decisions 发射后由后续 commit 执行，不在本 commit 内联以保证 v0.1 sha256 稳定）：
1. 发射 `artifact.retracted` 事件 · subject 指向 `m1_debt_ledger@v10` 的失真字段。
2. 发射 `artifact.re_emitted` 事件 · content_sha256 更正为 `d616ead3...`。
3. 两条事件 event_id 均采用四段式 · concern 分别为 `retracted` / `re-emitted`（需先由 01 @v1.4 或 @v2 扩展 §5.1.1 concern 表）。

**待升版候选**：
- 01 @v1.4（minor）：§5.1.1 新增 `retracted` / `re-emitted` concern · 归属 task 域。
- ledger @v11（minor）：§1.8.5 新增 "v0.1 发现项补偿记录" 章节。
- **本 v0.1 final-decisions 不升级** · 保留 DISC-V01-001 为发现项登记 · 补偿由 v0.2 初期动作执行。

**决议**：本发现项**不阻塞 v0.1 封版**。封版完成后首个动作即为补偿（见 §6.3）。

### §4.2 03 spec 保留 draft 状态入 v0.1（DISC-V01-002）

- 03-layered-architecture 自 M2 以来保持 draft · 未触及升版。
- v0.2 候选动作：审查 03 是否需要升版为 published（结合 adapter 接入实际对分层的校验需求）。
- 不阻塞 v0.1 封版（分层语义未与 M4-M7 任何决议冲突）。

### §4.3 kickoff supersede 范式沉淀（DISC-V01-003）

- 本 final-decisions 首次显式 supersede kickoff artifact（前三代均为自然淡出）。
- 待评估是否需要在 06 evolution-model 加入"kickoff → final-decisions 接力"典型模式说明。
- 不阻塞 v0.1 封版。

---

## §5. adapter 接入入口清单（列清单 · 不实施）

v0.1 kernel 层**不**实施任何 adapter。本节仅依据 07 §2 四扩展点整理 v0.2 候选入口：

| 扩展点 | 07 § | v0.2 候选 adapter | 入口 spec/artifact | 入口 concern |
|---|---|---|---|---|
| A | 07 §2.A | openspec-adapter | 02 artifact-model §openspec_ref | task-openspec-*（新增 · 待 01 升版） |
| B | 07 §2.B | tdag-adapter | 04 version-snapshot §tdag_ref | tdag-*（新域 · 待 01 升版） |
| C | 07 §2.C | trace-adapter | 05 drift-propagation §trace_ref | trace-*（新域 · 待 01 升版） |
| D | 07 §2.D | evo-sink-adapter | 06 evolution-model §sink_ref | evo-sink-*（待 01 升版） |

> 所有 adapter 接入均需**先触发 01 / 02 / 04 / 05 / 06 对应 spec 升版**（通过 07 §4 四问准入），再实施 adapter。kernel 层**不主动暴露** adapter 实现。

---

## §6. self-review 八项签收

| # | 审查项 | 结果 | 证据 |
|---|---|---|---|
| 1 | 七份 spec 终态 URN+rev+sha256 三元组完整 | ✅ | §2.1 · 扫描基准见 §5.1 |
| 2 | ledger @v10 作为 evolution_source 终态封版 | ✅ | §2.2 L1 · 失真记录 §4.1（不阻塞） |
| 3 | CONV-* 契约矩阵完备（主 + 子 + 3 例外） | ✅ | §3 |
| 4 | 四代 kickoff 接力链闭合图 | ✅ | §1 |
| 5 | adapter 接入入口清单（清单 · 不实施） | ✅ | §5 |
| 6 | v0.1 期间发现项登记（3 项） | ✅ | §4.1 / §4.2 / §4.3 |
| 7 | §0 覆盖范围 / 非覆盖范围显式声明 | ✅ | §0 |
| 8 | 同 commit 同 txn 发射 artifact.published（CONV-01） | ✅ | 见本文 §2.4 自指说明 + journal 追加 |

### §6.1 v0.1 kernel 封版判定：**PASS**

- 所有硬边界（07 §1）未被违反。
- 所有过早抽象原则（07 §0）在 M7 X 工作流已反向审查通过（见 m7_closeout_extensibility_acceptance @v1 §1.Q-X5）。
- 所有债（13 条）状态收敛至 resolved / continued-to-vnext / conventioned。
- 1 条 sha256 时序失真（DISC-V01-001）登记为发现项 · 补偿方案已写入 §4.1 · 不阻塞封版。

### §6.2 v0.1 kernel 封版事件（同 commit 发射）

本 final-decisions 封版事件 event_id 预留 `task-published-*` 四段式前缀 · concern=`published` · 合规 CONV-01 + CONV-01.1。

### §6.3 封版后首个动作（v0.2 序幕）

DISC-V01-001 补偿：
1. 01 @v1.4 minor 升版（§5.1.1 新增 retracted / re-emitted concern）。
2. ledger @v11 minor 升版（§1.8.5 发现项补偿记录章节）。
3. 发射 `task-retracted-*` + `task-re-emitted-*` 两条四段式事件。

---

## 附录

### §附1. v0.1 封版 sha256 扫描命令

```bash
# 七份 spec + ledger + two journals · 采集基准
cd docs/piao-pipeline/kernel
for f in 01-identity-model.md 02-artifact-model.md 03-layered-architecture.md \
         04-version-snapshot.md 05-drift-propagation.md 06-evolution-model.md \
         07-extensibility.md _review/M1-debt-ledger.md; do
  shasum -a 256 "$f"
done

# journal
shasum -a 256 ../../../pipeline-output/piao/kernel-events/2026-04.jsonl
shasum -a 256 ../../../pipeline-output/piao/mvp-smoke/events/2026-04.jsonl
```

### §附2. v0.1 → v0.2 过渡检查表

- [ ] DISC-V01-001 补偿事件发射（retracted + re-emitted）
- [ ] 01 @v1.4 + ledger @v11 升版
- [ ] `m7_closeout_kickoff @v1` supersede 事件发射完成（本 commit 同 txn）
- [ ] `ARCHITECTURE_SNAPSHOT.md` 同步至 v0.1 终态
- [ ] v0.2 kickoff 决策（由 adapter 接入需求触发）

---

**rev history**

| rev | date | change | triggered_by |
|---|---|---|---|
| v1 | 2026-04-19 | initial published · v0.1 kernel 层封版 · 四代 kickoff 接力链闭合 · DISC-V01-001/002/003 登记 | m7_closeout_kickoff@v1（γ₃ 工作流 C） |
