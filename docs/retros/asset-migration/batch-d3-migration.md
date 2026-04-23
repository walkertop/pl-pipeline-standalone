# Batch Migration · D3（M2~M7 六个核心资产）

**执行时间**: 2026-04-23
**关联 milestone**: [`v1.5-migrate-core-assets`](../../milestones/v1.5-migrate-core-assets.md) D3 阶段
**前置**: D1+D2（骨架 + spec-normalizer 样本，已完成于 pl-v1.5.0-alpha）

---

## 摘要

六个通用资产**一次性批量**从 KuiklyPolyCity 脱敏迁入 pl-pipeline-standalone。

| # | 资产 | 类型 | 源大小 | 源耦合 | 目标大小 | 目标实质耦合 |
|---|------|------|--------|--------|---------|------------|
| M2 | `finalization-template` | skill | 263 行 | 3 | 244 行 | 0 |
| M3 | `piao-pipeline-discipline` | rule | 205 行 | 16 | 194 行 | 0 |
| M4 | `acceptance-criteria` | rule | 133 行 | 4 | 154 行 | 0 |
| M5 | `build-verification` | rule | 162 行 | 4 | 143 行 | 0 |
| M6 | `pipeline-master` | agent | 212 行 | 4 | 171 行 | 0 |
| M7 | `knowledge-archiver` | agent | 164 行 | 6 | 141 行 | 0 |
| **合计** | | | **1139 行** | **37 hits** | **1047 行** | **0 real** |

> 文件大小略缩是正常的：脱敏替换往往让冗余的栈特定描述消失。
> 6 处命中全部是合法的 `migrated_from: KuiklyPolyCity` frontmatter 追溯字段。

---

## 分资产脱敏要点

### M2 · finalization-template（skill）

**Before**：SKILL.md 的"使用示例"节用 piao-pipeline v0.2 / Weex→Kuikly Q2 收口做例子。

**脱敏动作**：
- 保留核心"六段式 + γ 8 项门禁"模板（完全通用）
- 示例改为：
  1. "子系统的 v0.2 封版"（抽象）
  2. "跨季度阶段性收口"
  3. "技术栈迁移收口"（保留但不钦定栈）
- 历史案例改为"某演进型 pipeline 的 v0.1 封版（2026-04）"，不具名
- 相关联 skill 从 `migration-doc-generator` / `kotlin-code-review` 改为"栈级 migration-doc-generator skill（若存在）" / "栈级 code-review skill"

### M3 · piao-pipeline-discipline（rule）

**Before**：提了 13 次 piao、4 次"piao v0.1 封版"。

**脱敏动作**：
- rule-id 保留 `PIAO-001`（这个 id 本身已经成为概念代号，像 `SOLID` 一样无特指）
- "来源"从 `piao-pipeline v0.1 封版（M1→M7）` 改为 `某真实演进型 pipeline（2026-04 某子系统 v0.1）`
- 违规案例（`DISC-V01-001` ledger @v10）改为 "真实案例中已记录一次此类陷阱（某 ledger @v10...）"
- `kernel-events/2026-04.jsonl` 等具体路径去掉
- openspec 引用全删（用 frontmatter 的 `applies_to.glob` 表达作用域）

### M4 · acceptance-criteria（rule）

**Before**：P0 自动化检查段直接写 `./gradlew :kuikly-dynamic-apk-builder:packSplitApkRelease` 和 `grep '!!' --include='*.kt'`。

**脱敏动作**：
- P0/P1/P2 框架完全保留
- 每个检查项表格增加一列"栈级具体化示例"（Kotlin/Node/Py 三栈对比）
- 具体命令从"硬编码 gradle"改为"由 `.pl-adapter.yaml` 声明，`pl-runner.sh` 统一执行"
- "OpenSpec 交付标准" → "pl-pipeline 阶段门禁标准"（加 SMOKE、调整到 7 阶段）
- 阶段退出条件更新为 pl 的标准产物（spec.md / taskdag.md / ...）

### M5 · build-verification（rule）

**Before**：给出了具体 Kotlin/Gradle 版本表 + Kotlin 编译错误速查。

**脱敏动作**：
- 保留 `BUILD-001-STD` / `BUILD-001-WHEN` / `BUILD-001-AUTO` 三个子规则框架
- 把"标准构建命令"从 `./gradlew packSplitApkRelease` 改为"从 `.pl-adapter.yaml` 的 `build_adapter.build` 读取"
- **变更感知自动构建**（BUILD-001-AUTO）的 6 条触发规则完全通用，保留
- Agent 检查点协议保留
- 删除"构建环境约束"的具体 Kotlin/Kuikly 版本 → 改为"由 `.pl-adapter.yaml` 声明"
- 删除 Kotlin 编译错误速查表 → NO-list 里明确"栈特定错误速查放 `adapters/adapter-<stack>/rules/build-errors.md`"

### M6 · pipeline-master（agent）

**Before**：阶段调度表里 subagent 写死 `migration-analyzer` / `migration-coder` / `migration-guardian`，prompt 里有 `Weex/src/...` 和 `vue-to-kuikly-syntax` 等项目专属引用。

**脱敏动作**：
- 六阶段 → 七阶段（补 SMOKE）
- 调度表的 subagent 列改为 "项目自定义的 <XXX> subagent"
- prompt 模板保留，但变量改为通用名（`{change_id}` / `{spec_ref}` / `{taskdag_ref}`），不再写死 `{page_id}` / `{weex_source}` / `{business_domain}`
- 脚本路径从 `./scripts/xxx.sh` 改为 `$PL_HOME/scripts/pl-runner.sh / pl-smoke.sh / pl-status.sh`（独立仓提供的脚本）
- 新增"辩证模式"节，指向 [`working-with-fuzzy-intent.md`](../../guides/working-with-fuzzy-intent.md)
- 新增 `spec.revision` 和 `gate.soft_pass` 事件支持

### M7 · knowledge-archiver（agent）

**Before**：Step 3 / Step 4 直接点名 `vue-to-kuikly-syntax` / `kuikly-debugger` / `kuikly-ui-framework` 等 Kuikly 专属 rules/skills。

**脱敏动作**：
- 8 步归档流程完全保留
- Step 3/4 改为"栈级 rule / skill"+"通用 rule / skill"二元判断，给出判断标准（跨栈成立 → 通用，只某栈成立 → 栈级）
- Step 5 推广候选**明确声明不在 ARCHIVE 执行代码修改**，推广应新开 change
- Step 7 Memory 模板从 "Vue→Kuikly 迁移完成" 改为通用的 "change 交付总结"
- 约束条款新增：**遵守 `PIAO-001-DEFERRED` 和 `PIAO-001-SHA256`**（知识沉淀链路也要符合元级纪律）

---

## 验证（扫描报告）

详见 [`batch-d3-coupling-scan.txt`](./batch-d3-coupling-scan.txt)。

```
[OK] SKILL.md                                 1 total | 1 legit | 0 real
[OK] piao-pipeline-discipline.md              1 total | 1 legit | 0 real
[OK] acceptance-criteria.md                   1 total | 1 legit | 0 real
[OK] build-verification.md                    1 total | 1 legit | 0 real
[OK] pipeline-master.md                       1 total | 1 legit | 0 real
[OK] knowledge-archiver.md                    1 total | 1 legit | 0 real

TOTAL: 6 hits | 6 legitimate (migrated_from frontmatter) | 0 real coupling
```

---

## v1.5 D3 Checklist

- [x] 6 个资产全部迁入 `assets/pl/` 对应目录
- [x] Frontmatter 齐全（id / version / scope / category / migrated_from / sanitization_date）
- [x] 硬脱敏扫描 0 real coupling
- [x] 每个资产跨引用更新（rule → rule、agent → skill、agent → rule）
- [x] 批量扫描报告生成

### 未做（转 D4）

- [ ] KuiklyPolyCity 侧改为 override（M1 spec-normalizer 已计划，M2~M7 同步处理）
- [ ] override 回测：从 KuiklyPolyCity 跑一次 change，验证能正确加载通用 + Kuikly 扩展
- [ ] `adapter-kotlin/` 目录建立 + 收纳 Kotlin 专属的 Rule（serialization / kotlin-coding-standards / mvvm-architecture）

### 未做（转 D5）

- [ ] `docs/guides/adapter-authoring.md` —— 如何写 adapter 级 skill/rule
- [ ] `docs/migration/v1.4-to-v1.5.md` —— 现有用户升级

---

## 后续里程碑

- **D4** (回测) + **D5** (文档) 完成后 → 打 `pl-v1.5.0-beta`
- 完整稳定后 → 打正式版 `pl-v1.5.0`（脱掉 beta）
- 解锁 **E'**（干净新需求跑完整流程），进 B（retro-miner 跑真实 trace）

---

## 相关文档

- [D1+D2 里程碑](../../../CHANGELOG.md#150-alpha) — spec-normalizer 样本迁移
- [v1.5 整体计划](../../milestones/v1.5-migrate-core-assets.md)
- [脱敏指南](../../guides/asset-sanitization-guide.md)
