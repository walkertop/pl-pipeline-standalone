---
urn: urn:piao:snapshot:kernel:m1_final_decisions@v1
kind: snapshot
rev: v1
status: published
produced_by: m1-review-2026-04-18
supersedes: null
---

# M1 Final Decisions · Kernel 身份与边界收敛快照

> 本文档是 **M1 review（2026-04-18）** 的最终决议快照。
> 定位：作为 `07-extensibility.md §9.1`、`01-identity-model.md §2.2`、`scenario-wordlist.md` 等"历史追述"段落的**正式引用目标**，避免决议散落在 commit log 中不可溯源。
> 快照即事实：本文件**一经产出不再修改**；若未来推翻某条决议，新开 `M1-final-decisions@v2` 并在 v1 中标注 `superseded_by`。

---

## 0. 快照覆盖范围

- 受管文档：`docs/piao-pipeline/kernel/01-identity-model.md`、`02-artifact-model.md`、`03-layered-architecture.md`、`07-extensibility.md`、`scenario-wordlist.md`
- 决议时间窗：2026-04-15（M1 启动）至 2026-04-18（M1 收尾）
- 依据：`_review/conflict-review-M1-M3.md` 中的冲突识别与四项拍板

---

## 1. 四项最终决议

### 决议 1 — 移除 URN 中的 `realm` 段

**问题**：早期草案曾在 URN 中引入 `realm` 段区分 `kernel` / `adapter`，产生 `urn:piao:kernel:rule:scenario_wordlist@v1` 这种格式。

**决议**：**永久删除 `realm` 段**。

**最终 URN grammar**（`01-identity-model.md §1.1`）：
```
urn:piao:<kind>:<scope>:<name>[@<rev>]
```

**理由**：
1. `realm` 段的初衷是强调 kernel/adapter 边界，但该边界已通过 §2 kind 语义 + §7 存储布局（目录结构）充分表达
2. URN 层引入 realm 会让 kernel / adapter 边界变成**身份字符串的一部分**——一旦决定把某概念"升 kernel"或"降 adapter"，所有历史事件都指向失效 URN
3. RFC 8141 的 URN grammar 本身不需要 realm 级别的分组

**影响面清单**（已全部在 M1 迭代中执行）：
- `scenario-wordlist.md` front-matter URN 从 `urn:piao:kernel:rule:scenario_wordlist@v1` 改为 `urn:piao:rule:scenario_wordlist@v1`
- `07-extensibility.md §1 边界 2` 的"URN grammar / realm 下的 scope"改写为"URN grammar（含固定 `urn:piao:` 前缀与段序）/ `<scope>` 内部的命名方式"
- `07-extensibility.md §6` 目录注释"realm=kernel 的所有内容都在这"改写为"领域无关、跨业务可复用的契约与原理都在这"
- `01-identity-model.md §1.1` 末尾保留**反向兼容说明**（"本版不引入 realm 段；若未来需要多领域命名空间见 §11"）

**回滚代价**：零。M1 review 前 piao-pipeline 尚未落地运行，无历史事件/manifest 使用带 realm 的 URN。

---

### 决议 2 — 合并 `page` kind 到 `unit`

**问题**：早期 §2.2 曾预留 `page` kind 作为"UI 页面"场景的特化 kind，与 `unit` 语义重叠，制造"选哪个"的选择困扰。

**决议**：**删除 `page` kind**，所有 URN 业务单元统一使用 `unit`。

**理由**：
1. `page` 本质是 UI 场景的业务词，属于 `07-extensibility.md §1 边界 1` 明文禁止的场景词族
2. 语义上与 `unit` 完全重叠——"一个业务工作单元"的抽象已足够
3. 保留双 kind 会让 kernel 在"是否该区分 UI 页面与非 UI 工作单元"上反复摇摆

**最终 kind 枚举**（`01-identity-model.md §2.1`）：
```
核心 kind: artifact, task, taskdag, unit, stage, event_journal,
          snapshot, drift, proposal, rule
扩展 kind: evolution_source
```

**影响面清单**（已全部在 M1 迭代中执行）：
- `01-identity-model.md §2.2` 的扩展 kind 表中删除 `page` 行，补注"合并到 `unit`"说明段
- `01-identity-model.md §2.3 / §3.1 / §8.2 / §9` 所有 `page` / `page_id` 的表格与例子同步更新
- `07-extensibility.md §1 边界 1` 禁用词表追加 `page` / `page_id`
- `scenario-wordlist.md §3` 将 `page` / `page_id` 从"受限使用"升级为"强禁用（仅迁移/历史段落例外）"

**业务侧兼容说明**：
- 业务代码（`shared/**`、`openspec/**`、`.state.md`）里的 `page_id` 字段**不受影响**——它是 URN `<scope>` / `<name>` 段在业务层的别名，而非 kind 枚举
- kuikly adapter 在**下一次发 artifact 或写 event 时**自然使用 `urn:piao:unit:prop_confirm` 即可，无需批量字符串替换历史代码

---

### 决议 3 — 保留 `urn:piao:` 完整前缀

**问题**：M1 review 中曾评估"简化为 `piao:<kind>:...`"或"裸 `<kind>:...`"两种方案，以减少视觉噪音（每个 URN 前 9 字符固定）。

**决议**：**维持完整 `urn:piao:` 前缀**，三种方案对比后的最终选择。

**方案对比**：

| 方案 | 示例 | 字符数 | grep 命中纯度 | 标准合规 |
|------|------|--------|--------------|---------|
| A. 维持 `urn:piao:` | `urn:piao:artifact:prop_confirm:spec@v1` | 39 | ✅ 最强（`grep urn:piao:` 一次找齐） | ✅ RFC 8141 |
| B. 简化为 `piao:` | `piao:artifact:prop_confirm:spec@v1` | 35 | ⚠️ 可能和其他 `piao:` 前缀字段混淆 | ❌ 脱离 URN 语法 |
| C. 裸格式 | `artifact:prop_confirm:spec@v1` | 30 | ❌ 和 yaml key / 路径段混淆 | ❌ |

**理由**：
1. **grep 可检索性**：9 字符冗余换"全局 `grep urn:piao:` 一次定位所有身份引用"的能力，在事件 JSONL / front-matter / rule 交叉引用里回本极快
2. **视觉识别度**：`urn:` 前缀让身份字符串在代码/文档/日志里**一眼可辨**，不会和 yaml key、配置值、路径段混淆
3. **命名空间预留**：`piao:` 预留，未来若事件流混入外部 URN（如 `urn:w3c:...`、`urn:uuid:...`）不会重名
4. **RFC 8141 合规**：符合业界 URN 习惯，未来接入 OpenTelemetry / schema.org 等标准体系时无需改造

**正式入档位置**：`01-identity-model.md §1.1` URN 表格下方注脚。

---

### 决议 4 — 强化 kernel 场景词白名单

**问题**：`07-extensibility.md §1 边界 1` 的禁用词表在早期版本中不完整，`scenario-wordlist.md` 作为 v0.1 交付物尚未接入自动化。

**决议**：
1. 禁用词表新增 `page` / `page_id`（配套决议 2）
2. `scenario-wordlist.md` 升级为**写作自查清单 + v0.2 CI 接入路径**
3. 在 v0.2 迭代中落地 `scripts/kernel-wordcheck.sh`，含 `--ci` 参数

**最终禁用词**（`07-extensibility.md §1 边界 1`）：
```
kuikly / weex / vue / compose / detekt / logcat / android / ios / kotlin /
screenshot / miniapp / page / page_id
```

**自动化路径**：
- **v0.1（现状）**：`scripts/kernel-wordcheck.sh` 骨架到位，人工在提交前手动运行；`scenario-wordlist.md §5` 提供 `grep` 一行命令作为 fallback
- **v0.2（计划）**：git pre-commit hook 自动拦截违规 commit，返回行号 + 命中词 + 推荐改写
- **v0.2 扩展**：增加 inline escape 机制 `<!-- kernel-wordcheck: allow -->` 允许引用/对比段落豁免

---

## 2. 快照产出清单

| 文件 | 本次快照对应的 rev |
|------|------------------|
| `01-identity-model.md` | v1（草案内迭代，rev 不升） |
| `02-artifact-model.md` | v1 |
| `03-layered-architecture.md` | v1 |
| `07-extensibility.md` | v1 |
| `scenario-wordlist.md` | v1 |

> **关于 rev 不升的说明**：M1 review 期间各文档均处 `status: draft`，根据 `01-identity-model.md §10.1` 的"published/draft 两态契约"，draft 阶段原地修订不需要升 rev。上述四项决议均在 draft 期内完成，本快照记录的是"draft 收敛点"而非"published 跨版本变更"。

---

## 3. 引用方式

其他文档引用本快照时使用：
```
见 M1 最终决议快照：
urn:piao:snapshot:kernel:m1_final_decisions@v1
（docs/piao-pipeline/kernel/_review/M1-final-decisions.md）
```

---

## 4. 下一步（M2 入口检查清单）

本快照**不规定**下一步做什么，但记录 M2 入口前应确认的状态：

- [ ] `scripts/kernel-wordcheck.sh` 骨架就绪（v0.1 人工版）
- [ ] `docs/piao-pipeline/00-overview.md §1 核心公式` 章节索引与实际 kernel 文件对齐
- [ ] `03-layered-architecture.md` 含 kind 枚举变更史段落（回溯决议 2）
- [ ] `docs/piao-pipeline/adapters/kuikly/` 目录骨架可选启动（根据 M2 优先级）

---

**快照状态**：published（M1 review 终点的冻结照片）
**上游**：`_review/conflict-review-M1-M3.md`
**下游锚点**：本快照是任何引用 "M1 review 决议" 的文档的正式 URN 目标
