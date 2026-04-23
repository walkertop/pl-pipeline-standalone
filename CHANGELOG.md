# Changelog

本项目的所有显著变更都会记录在此。

格式遵循 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/)，
版本号遵循 [语义化版本](https://semver.org/lang/zh-CN/)。

---

> 📍 **2026-04-23 阶段性回顾**：v1.3.x 观察层系列已在两天内完成
> （v1.3.0-alpha → v1.4.0-alpha → v1.3.2-alpha → v1.3.2-alpha.2）。
> 总结文档 + 下一阶段规划见 [`docs/milestones/2026-04-v1.3.x-summary.md`](./docs/milestones/2026-04-v1.3.x-summary.md)。
>
> 🎉 **2026-04-23 v1.5.0 正式发布**：pl-pipeline-standalone 从"空壳工具"升级为**有脑**的完整研发流水线。
> 三层资产栈（generic/stack/project）落地，64 处源耦合点脱敏为 0，11/11 资产 frontmatter 合规。
> 发布说明：[`docs/milestones/2026-04-v1.5.0-release.md`](./docs/milestones/2026-04-v1.5.0-release.md)
> 下一步规划：[`docs/milestones/v1.6-next-planning.md`](./docs/milestones/v1.6-next-planning.md)
>
> 📖 本版同时新增辩证方法论文档：[`docs/guides/working-with-fuzzy-intent.md`](./docs/guides/working-with-fuzzy-intent.md)
> —— 教用户怎么用格式化工具而不被它框死。
>
> 🤝 **2026-04-23 v1.6.x → v1.7.0 一日推完**：观察层从"事件流"升级为"契约系统"。
> v1.6.0 让观测不可被绕过；v1.6.1 给事件加因果树 + active 时间估算 + adapter.use；
> v1.7.0 把 adapter.use 流变成可读的 consumer pact，并在 CI 拦截会打到 consumer 的 adapter PR。

---

## [1.7.0] — 2026-04-23 · CDC 双向闭环 🤝

**主题**：把 v1.6 的 `adapter.use` 事件流升级为可读、可校验、可在 CI 拦截 PR 的契约系统。

### ✨ 里程碑级变化

- **CDC broker 三件套上线**：`adapter.use`（记录）→ `pl-contract-aggregate.sh`（沉淀）→ `pl-contract-verify.sh`（对账）
- **首次让 adapter 升级"不能默默打到 consumer"**：CI 阶段就能看到哪些 change 会因 PR 而 broken
- **`provides.capabilities[]`**：在 adapter.yaml 里增加抽象层，吸收内部 skill/rule 改名

### 🆕 新增

#### CDC broker 脚本（`scripts/`）

- **`pl-contract-aggregate.sh`**：扫描 `pipeline-output/trace/*.events.jsonl` 的 `adapter.use` 事件，
  按 `change_id` 聚合为 `pl/contracts/<change>.consumed.yaml`（per-change pact），并维护
  跨 change 的反向索引 `pl/contracts/_registry.yaml`
  - 支持 `--change <id>` 单 change 聚合 / `--check` 干跑 diff（CI 拦"漏 commit pact"）/ `--json` 摘要
  - 时间戳剥离 → 幂等 diff
  - 自实现 yaml emitter，零 PyYAML 依赖（CI 装 pyyaml 仅用于 verify）

- **`pl-contract-verify.sh`**：拿 pact 对账当前 `adapter.yaml`，输出 satisfied / warn / broken
  - `--strict` 模式：warn 也按 1 退出（CI 用）
  - 处理 `backed_by: null` / `deprecated_in` / `removed_in` 三种 capability 演进语义
  - 简易 semver 比较（仅 major.minor.patch，已覆盖 v1.7 全部用例）

#### 契约 schema（`assets/pl/schemas/`）

- `consumer-contract.schema.json`：单个 change 的 pact，记录消费的 templates / skills / rules / agents / build_commands / capabilities，每条带 uses / first_seen / last_seen / phases
- `contract-registry.schema.json`：全局注册表，支持反查"哪些 change 在用某 adapter"

#### `provides.capabilities[]` 抽象层

- adapter.yaml 新增可选 `provides.capabilities[]` 数组，每条声明一个 abstract capability id（如 `typecheck` / `server-action-support`），通过 `backed_by` 指向真实实现（skill / rule / build_command / null）
- 支持 `since` / `deprecated_in` / `removed_in` 字段，让 capability 优雅演进
- 完整文档：[`docs/guides/adapter-authoring.md` §3.4](./docs/guides/adapter-authoring.md)
- 示例迁移：[`adapters/adapter-nextjs-web/adapter.yaml`](./adapters/adapter-nextjs-web/adapter.yaml) 声明 9 条 capability，含一条 `backed_by: null`（smoke-probe）

### 🔧 流水线集成

- **pl-runner.sh**：gate 通过且 `GATE_TO=ARCHIVE` 时自动调 `pl-contract-aggregate.sh --change <id>`，输出末尾提示 `git add pl/contracts/...`。失败只 warn 不阻断（观测层永不能成为流水线故障源）
- **pipeline-master.md**：ARCHIVE 阶段提示词加 v1.7 自动聚合说明 + 提交 pact 强约束；新增"何时跑 broker"触发表 + 完整双向 CDC 流程图
- **`.github/workflows/ci.yml`**：新增 Job 6 `cdc-broker-smoke`，3 个 scenario（happy path / broken pact / `--check` 幂等），自包含 fixture，本地 + CI 同样行为

### 📚 文档

- `docs/guides/adapter-authoring.md` 新增 §12 "在 consumer 项目里启用契约校验"：
  - §12.1 consumer 项目侧 GitHub Actions snippet
  - §12.2 adapter 仓库侧 cross-consumer matrix snippet
  - §12.3 退出码 → CI 行为映射表
  - §12.4 4 类最常见拦截场景

### 📊 验证矩阵

| 维度 | 验证 |
|---|---|
| broker 三件套基础正确性 | 8 个本地 E2E case 全绿（B1+B2+B3） |
| ARCHIVE 钩子 | 2/2：ARCHIVE gate 触发、非 ARCHIVE gate 不触发 |
| CI 三 scenario | 3/3 本地复现全绿 |
| 幂等 | 第二次 aggregate `--check` exit 0 |
| `--strict` 拦截 | broken pact 准确 exit 1，含详细 reason |

### 🎯 设计取舍

- **broker 用脚本而不是服务**：`bash + git` 比独立 HTTP/DB broker 简单一个数量级，pact 沉淀进 git 也天然有审计、回放、code review
- **触发点放 pl-runner 而不是 pipeline-master**：脚本是确定执行的，agent prompt 容易漏 follow。结构性强约束 > 文档约束
- **`backed_by: null` 是一等公民**：明确"这个 capability 我不支持"比沉默更重要——sane consumer 看到 null + reason 就会自己绕开

### 🔗 相关 commit

`8e125e5` broker 聚合 · `1baeea7` capabilities 抽象 · `627640a` verify 对账
`6a7ca3d` ARCHIVE 钩子 · `6baf997` CI 接入 + 文档

---

## [1.6.1] — 2026-04-23 · trace span 因果树 + active 时间统计代理 🌳

**主题**：让"监督 Agent 生产过程"这件事真正可被看清——按因果链回放、按密度估算 active 时间、补齐 adapter 消费观测。

### 🆕 新增

- **trace 信封补齐 `change_id`**：event-v1.3.schema.json 早把它列为 required，本次让 trace_emit 真的写。多文件聚合 / broker / 跨工具消费不再依赖文件名做关联
- **span 栈 + 自动父子关系**：trace-emit.sh 新增 `_SPAN_STACK`，phase/gate/task 开始 push、结束 pop。中间 emit 的 point 事件（check.run / adapter.use / artifact.*）自动从栈顶继承 `parent_span_id`，因果链不再依赖人手维护注释
- **新辅助函数**：`trace_gate_start` / `trace_gate_end`，pl-runner.sh + pl-smoke.sh 全部裸 emit 迁移
- **`pl-trace-tree.sh`**：按 span 渲染因果树，point 事件挂父 span 下；`--no-points` / `--json` / `--file` 任意 jsonl
- **`pl-active-time.sh`**：用事件密度做 active vs wall 时间估算代理；默认 5min idle 阈值，支持 `--by-phase`；显式说明这是估计、安全失败方向是低估
- **`adapter.use` 事件类型 + 配套工具**：trace-emit.sh `trace_adapter_use()` 自动读 `.pl-adapter.yaml` id/version；pl-runner.sh check.cmd 引用 `${PL_*}` env 时自动 emit；CLI `trace-adapter-use.sh` 给 agent / 脚本手动记录

### 📐 观测系统设计原则（pipeline-master.md 新增章节）

明文写入今后扩展事件 schema 必须遵守的硬约束，避免噪声字段污染数据：
1. 字段必须有真实可获得的数据源（不为 cost/token 盖楼）
2. 事件必须能稳定 emit，不依赖 LLM 自觉（用脚本/统计代理代替自报）

### 🔧 兼容

- macOS bash 3.2 友好（不用 `declare -g`）
- pl-runner.sh / pl-smoke.sh 的裸 `trace_emit gate.*` 全部统一迁移到 span 版

### 🔗 相关 commit

`86f9eaa` trace 信封补 change_id + span 因果树 + active 时间统计代理

---

## [1.6.0] — 2026-04-23 · 观测层不可被绕过 🔒

**主题**：手动走阶段时观测层被绕过的问题（`.state.md` 简陋 / trace 为空），由"靠 agent 自觉"升级为"脚本兜底"。

### 🆕 新增 pl-core 脚本

- **`pl-state-init.sh`**：创建 change 时自动生成完整 10 章节的 `.state.md` + 初始 trace 事件（`workflow.start` + `phase.start`）
  - 用法：`pl-state-init.sh <change-id> --name '变更名'`
- **`pl-phase.sh`**：手动走阶段的 trace 包装命令，每条命令同时写 trace 事件 + 更新 `.state.md` History
  - 子命令：`start` / `end` / `gate` / `task` / `check` / `artifact` / `done` / `status`
- **`pl-observe-check.sh`**：观测完整性检查（VERIFY 阶段必跑）
  - 检查：`.state.md` 完整性 / trace 非空 / `workflow.start` 存在 / 阶段覆盖
  - 支持 `--strict` 模式（warn 变 error）

### 📦 解决的问题

- 手动走阶段时观测层被绕过（`.state.md` 简陋 / trace 为空）→ pl-state-init 兜底完整初始化
- VERIFY 阶段无法检测观测数据缺失 → pl-observe-check 提供机械检查
- E' retro 从工具仓迁出到目标项目内（产物跟着项目走）

### 🔗 相关 commit

`4fd1c33` 三个新脚本让观测层不可被绕过

---

## [1.5.0] — 2026-04-23 · Core Assets Migration · RELEASE 🎉

**主题**：pl-pipeline-standalone 从"空壳工具"升级为**有脑**的完整研发流水线。

### ✨ 里程碑级变化

- **三层资产栈落地**：generic（`assets/pl/`）→ stack（`adapters/adapter-*/`）→ project（`<user-project>/.codebuddy/`）
- **11 个核心资产完成脱敏迁移**（Tier 0 的 7 + Tier 1 的 4）
- **首个栈级基础 adapter：adapter-kotlin**（可被 android / kmp-kuikly 叠加）
- **64 处源耦合点清零**（硬耦合 3→0 + 软耦合 5→0 + D3 37→0 + D2 19→0）

### 📦 完整产物清单

| 类别 | 产物数量 | 新增 |
|------|---------|------|
| 通用 skills | 2 | spec-normalizer, finalization-template |
| 通用 rules | 4 | acceptance-criteria, build-verification, piao-pipeline-discipline, git-commit |
| 通用 agents | 2 | pipeline-master, knowledge-archiver |
| 栈级 adapter | 1 | adapter-kotlin（2 rules + 1 skill + 3 scripts）|
| 指南文档 | 4 | asset-sanitization-guide, adapter-authoring, working-with-fuzzy-intent, v1.4-to-v1.5 |
| 里程碑文档 | 2 | v1.5-migrate-core-assets, 2026-04-v1.5.0-release |
| 后续规划 | 1 | v1.6-next-planning |
| 迁移证据 | 8 | 3 批 before/after/retro 完整证据链 |

### 📊 质量指标

- adapter-validate 通过率: **3/3 (100%)**
- Frontmatter 合规率: **11/11 (100%)**
- 真实耦合点: **0**
- Breaking changes: **3 minor**（文件名归一化 / gradle 命令外化 / 六→七阶段）

### 🎯 完成 v1.5 milestone 的 4 条成功标准

| # | 成功标准 | 达成 |
|---|---------|------|
| 1 | 独立仓有完整通用资产目录 | ✅ |
| 2 | 7 个关键资产脱敏迁移 | ✅ 超额 8/7 + 4 Tier 1 |
| 3 | KuiklyPolyCity 改 override | ⏭ 用户要求跳过 |
| 4 | 任何新用户能用 | ✅ 通过 validate + 0 耦合 |

### 🗺 下一步方向（v1.6+）

详见 [`docs/milestones/v1.6-next-planning.md`](./docs/milestones/v1.6-next-planning.md)。

4 条候选路径：
- **E'**：跑一个干净新项目验证（推荐优先）
- F: 扩充 adapter 生态（android / kmp-kuikly / go）
- G: v0.2 CLI 打包（`pl init` / `pl install-adapter`）
- H: retro-miner 真实 trace 挖掘链路

推荐方案 A（保守路径）：**E' → H → F → G**，总周期 10~15 天。

---

## [1.5.0-rc.1] — 2026-04-23 · Tier 1 资产 + D5 升级文档

v1.5 第三阶段：**Tier 1 四个资产迁移 + 新建 adapter-kotlin + 作者指南**。
至此 v1.5 的核心资产栈（assets/pl/* + adapters/adapter-kotlin）完整可分发。

### ✨ Added · Tier 1 批量迁入

| # | 资产 | 类型 | 分层归属 | 源行数 → 目标行数 | 实质耦合 |
|---|------|------|---------|-----------------|---------|
| T1 | `git-commit` | rule | generic | 122 → 186 行 | 0 |
| T2 | `kotlin-coding-standards` | rule | adapter-kotlin | 188 → 202 行 | 0 |
| T3 | `kotlinx-serialization` | rule | adapter-kotlin | 167 → 174 行 | 0 |
| T4 | `kotlin-code-review` | skill | adapter-kotlin | 385 → 318 行 | 0 |
| 合计 | | | | **862 → 880 行** | **0 real coupling** |

### 🆕 新增 adapter：adapter-kotlin

- 首个**栈级基础 adapter**（不绑定 UI 框架）
- 可被 `adapter-android` / `adapter-kmp-kuikly` 等未来 adapter 通过 `requires` 叠加
- 完整产物：
  - `adapter.yaml`（gradle 构建基座，含 contract / expected_files）
  - `README.md`
  - `rules/`（kotlin-coding-standards + kotlinx-serialization）
  - `skills/kotlin-code-review/SKILL.md`（P0/P1/P2 三档审查，10 维度）
  - `scripts/{build,verify,lint}.sh`（优雅降级，detekt/ktlint 缺失时不报错）

### 📘 D5 · 作者指南与升级文档

- **[`docs/guides/adapter-authoring.md`](./docs/guides/adapter-authoring.md)**
  - 三个判断：何时该写 adapter
  - 标准目录结构 + adapter.yaml 规范
  - rules / skills / agents / scripts 写作规范
  - 脱敏检查清单（10 项）
  - 以 adapter-kotlin 为例的走查
  - 4 个常见陷阱 + 12 条发布 checklist
  - 附录：与 assets/pl 分层关系速查 + 3 个参考实现

- **[`docs/migration/v1.4-to-v1.5.md`](./docs/migration/v1.4-to-v1.5.md)**
  - 变化一览（新增文件与目录 / 版本总览）
  - 升级步骤（3 层加载策略 + adapter 安装）
  - KuiklyPolyCity 用户迁移对照表（11 项资产映射）
  - Breaking 与兼容性（3 个 minor breaking：gradle 命令外化 / 文件名归一化 / 七阶段）
  - 新功能速览 + 验证脚本 + 5 条 FAQ + 回退策略

### 🔧 关键抽象动作

- `git-commit`：`chore(gradle): update Kuikly dependency` 示例改为 `chore(deps): bump framework to v2.3`；迁移记录章节去项目专属化；Scope 表改为"模式 + 示例"；Type 扩充 `ci` / `build`
- `kotlin-coding-standards`：`console` 专属 Logger 抽象为"项目约定 Logger"，举 slf4j / android.util.Log / console 三例；序列化示例移至独立 rule 避免重复
- `kotlinx-serialization`：匈牙利命名法从"强约束"改为"选择之一"，新增选择标准
- `kotlin-code-review`：`基于腾讯 Kotlin 代码规范` 改为 `基于 Kotlin 官方规范 + 业界最佳实践`；references/*.md 12 文件暂不迁（内容是官方文档复述，许可存疑）

### 📋 迁移证据

- `docs/retros/asset-migration/batch-tier1-coupling-scan-before.txt` — 迁移前扫描（硬耦合 3 / 软耦合 5）
- `docs/retros/asset-migration/batch-tier1-coupling-scan-after.txt` — 迁移后扫描（0 耦合）
- `docs/retros/asset-migration/batch-tier1-migration.md` — 详细对比 + 分层决策 + 关键决策记录 + 经验沉淀

### 📊 v1.5 累计状态

| 阶段 | 产物 | 状态 |
|------|------|------|
| D1 | 三目录骨架 + 脱敏指南 | ✅ |
| D2 | spec-normalizer 样本迁移 | ✅ |
| D3 | 6 个核心资产批量迁移 | ✅ |
| Tier 1 | git-commit + 3 kotlin 资产 + adapter-kotlin | ✅ |
| D4 | KuiklyPolyCity override 回测 | ⏭ 用户选择跳过 |
| D5 | adapter-authoring + v1.4→v1.5 指南 | ✅ |
| D6 | 打正式版 `pl-v1.5.0` | 🔜 |

**v1.5 RC 完成**：assets/pl/ 拥有 2 skills + 4 rules + 2 agents；新增 adapter-kotlin 含 2 rules + 1 skill + 3 scripts。

---



## [1.5.0-beta] — 2026-04-23 · Core Assets Migration · D3 批量

v1.5 第二阶段：**6 个核心资产一次性批量迁移**。
至此 pl-pipeline-standalone 的核心资产栈（skills + rules + agents）基本完整。

### ✨ Added · 批量迁入

| # | 资产 | 类型 | 源大小 → 目标大小 | 实质耦合 |
|---|------|------|-----------------|---------|
| M2 | `finalization-template` | skill | 263 → 244 行 | 0 |
| M3 | `piao-pipeline-discipline` | rule | 205 → 194 行 | 0 |
| M4 | `acceptance-criteria` | rule | 133 → 154 行 | 0 |
| M5 | `build-verification` | rule | 162 → 143 行 | 0 |
| M6 | `pipeline-master` | agent | 212 → 171 行 | 0 |
| M7 | `knowledge-archiver` | agent | 164 → 141 行 | 0 |
| 合计 | | | **1139 → 1047 行** | **0 real coupling** |

37 处源耦合点全部脱敏；6 处 `migrated_from: KuiklyPolyCity` frontmatter 追溯字段保留（合法元数据）。

### 🔧 关键抽象动作

- `build-verification` 的具体 `gradle xxx` / 版本表 **全部抽象**到 `.pl-adapter.yaml`，rule 只定义框架（BUILD-001-STD / WHEN / AUTO）
- `acceptance-criteria` 的 P0/P1/P2 每项增加"栈级具体化示例"列（Kotlin/Node/Py 三栈对比）
- `pipeline-master` 六阶段 → 七阶段（补 SMOKE），subagent 调度表改为"项目自定义"，新增辩证模式章节
- `knowledge-archiver` 的 Step 3/4 改为栈级 vs 通用二元判断，给出"跨栈成立→通用，只某栈→栈级"的判断标准
- `pipeline-master` / `knowledge-archiver` 增加遵守 `PIAO-001-SHA256` / `PIAO-001-DEFERRED` 的约束（知识沉淀链路也要符合元级纪律）

### 📋 迁移证据

- `docs/retros/asset-migration/batch-d3-coupling-scan.txt` — 最终扫描报告（6/6 OK）
- `docs/retros/asset-migration/batch-d3-migration.md` — 详细 Before/After 对比 + 分资产脱敏要点

### 🔜 v1.5 后续

- D4: KuiklyPolyCity 侧改 override + 回测（M1~M7 同步处理）
- D5: `docs/guides/adapter-authoring.md` + `docs/migration/v1.4-to-v1.5.md`
- D6: 打正式版 tag `pl-v1.5.0`

---

## [1.5.0-alpha] — 2026-04-23 · Core Assets Migration · D1+D2

v1.5 第一阶段：**核心资产基础设施 + 样本迁移**。
完成后 pl-pipeline-standalone 不再"有流程无脑"。

### ✨ Added

- **通用资产目录骨架**
  - `assets/pl/skills/` + README（含分层说明：通用 < 栈级 < 项目级）
  - `assets/pl/rules/` + README（含 frontmatter 规范）
  - `assets/pl/agents/` + README
  - 三层加载优先级：项目 > 栈 > 通用

- **脱敏指南**：[`docs/guides/asset-sanitization-guide.md`](./docs/guides/asset-sanitization-guide.md)
  - 硬脱敏 / 软脱敏规则
  - Frontmatter 强制字段（id / version / scope / category / migrated_from）
  - 5 步迁移工作流 + PR Review Checklist
  - 3 种常见错误

- **样本资产：`spec-normalizer@1.0.0`**
  - 从 KuiklyPolyCity 迁入并脱敏
  - **硬耦合点 19 → 0**（仅保留合法的 `migrated_from` 追溯字段）
  - 2 个不同域示例（电商订单 / 博客编辑器）
  - 改良：标注可选章节、新增辩证使用提示、提及 working-with-fuzzy-intent

### 📋 迁移证据
- `docs/retros/asset-migration/spec-normalizer-coupling-scan-before.txt`
- `docs/retros/asset-migration/spec-normalizer-coupling-scan-after.txt`
- `docs/retros/asset-migration/spec-normalizer-migration.md`（Before/After 详细对比 + override 计划）

### 🔜 v1.5 后续阶段

- D3: 批量迁移 M2~M7（finalization-template / 3 个 rules / 2 个 agents）
- D4: KuiklyPolyCity 侧改为 override 并回测
- D5: 写 `adapter-authoring.md` + `v1.4-to-v1.5.md` 升级文档
- D6: 打正式版 tag `pl-v1.5.0`

---

## [1.3.2] — 2026-04-23 · Dashboard Live Reload（正式版）

本版本是 `1.3.2-alpha` → `1.3.2-alpha.2` 两次打磨后的**稳定版**。
包含了原 alpha 的全部能力 + 一个严重 bug 修复 + 完整用户文档。

- **完整能力**：自写 SSE server + `EventSource` 客户端 + 增量 render + 自动重连 + 静默降级（详见 [1.3.2-alpha] 段）
- **关键修复**：per-subscriber snapshot（详见 [1.3.2-alpha.2] 段）
- **用户文档**：[`docs/dashboard-guide.md`](./docs/dashboard-guide.md)（30 秒上手 / 4 种启动姿势 / 5 条 FAQ）
- **辩证方法论**：[`docs/guides/working-with-fuzzy-intent.md`](./docs/guides/working-with-fuzzy-intent.md)

从 alpha 升级：**无 API 变更**，只需 `git pull` 重启 `pl-dashboard.sh`。

---

## [1.3.2-alpha.2] — 2026-04-23 · snapshot-lost 修复 + 用户文档

### 🐛 Fixed

- **snapshot 丢失 bug（严重）**：v1.3.2-alpha 里 `tail_jsonl_watcher` 的 snapshot 由共享 watcher 线程广播给当前所有订阅者，变量 `snapshot_sent` 是 watcher 级别而非订阅者级别。第二个及以后的订阅者都收不到初始全量，导致 Dashboard 多开浏览器 tab 时部分 tab 只显示空壳。
  - 修复：Broadcaster 引入 `snapshot_fn` 字段，`subscribe()` 时对**每个新订阅者**独立生成并发送当前全量 snapshot；watcher 只负责后续 `append / reset / missing`。
  - 影响面：所有 change 详情页和 index 首页的 live 订阅。
  - 复现命令：连跑两次 `curl -N /_events/stream?change=<id>`；修复前第二次只见 `hello`，修复后每次都能收到完整 snapshot。

- **ConnectionResetError 噪音**：浏览器切页/关 tab 时大量 "Connection reset by peer" traceback 污染 server log，掩盖真实错误。
  - 修复：重载 `ThreadingHTTPServer.handle_error`，对 `ConnectionResetError / BrokenPipeError` 静音；设 `PL_DASHBOARD_VERBOSE=1` 可恢复。

- **index_watcher 启动多推一条相同 updated**：`last_sig=None` 导致首次循环必然 publish；snapshot 职责移出后应初始化为当前 sig。
  - 修复：新增 `_compute_index_sig()`，watcher 启动时即以当前状态初始化。

### 📝 Docs

- 新增用户使用文档：[`docs/dashboard-guide.md`](./docs/dashboard-guide.md)
  - 30 秒上手 / 三种启动姿势 / 视图详解 / live badge 四态 / 降级策略 / 常见问题 5 条
  - 引用 `docs/retros/evidence-2026-04-v1.3.2/change-live.png` 作为效果示例

### 🧪 验证

- 两个连续订阅者均收到完整 snapshot
- 浏览器切页时 server log 干净
- E2E 手测：3 个 change 的卡片 / change 详情页 info-cards / timeline 均正确渲染

---

**主题：Dashboard 从静态快照升级为实时推送。**

v1.3.0-alpha 提供了可视化基础设施（observe 层 + dashboard 双视图），
但观察者每次必须手动刷新页面才能看到新事件。本版完成实时推送，让"观察"真正具备可观性。

### ✨ Added

- **SSE 长连接服务端**（`scripts/_lib/dashboard-server.py`）
  - 零第三方依赖（仅 Python stdlib：`http.server` + `threading` + `queue`）
  - `GET /_events/stream?change=<id>` — 单 change events.jsonl tail，推送 `snapshot / append / reset / missing` 事件
  - `GET /_events/index` — trace 目录整体变化（新 change 出现 / 现有 change 有更新）
  - `HEAD /_events/ping` — 前端能力探测端点
  - 多订阅者共享单个 watcher 线程；最后一个订阅者离开时 watcher 自动停止
  - 15s 心跳（`: keepalive\n\n`）防中间件断连
  - 支持 jsonl rotate / truncate（发 `reset` 事件让客户端重订阅）

- **SSE 客户端库**（`dashboard/assets/live.js`）
  - `probeLiveReload()` — HEAD 探测，2s 超时
  - `subscribeChange(changeId, handlers)` — 订阅单 change 流
  - `subscribeIndex(handlers)` — 订阅目录流
  - `EventSource` 指数退避自动重连（1s → 15s，上限）
  - `mountStatusBadge()` — 头部状态徽章工厂

- **前端 Live Reload 集成**
  - `change.html`：收到 `snapshot` 渲染全量，`append` 增量 prepend（1.2s 闪烁高亮），同步刷新 info cards 和 stage pipeline
  - `index.html`：收到 `updated` 按 change_id 粒度增量 upsert / remove 卡片
  - 顶部 Live 徽章四态：`● live` / `◐ connecting` / `✕ reconnect` / `○ static`

- **降级路径**
  - `pl-dashboard.sh --static-only` 回退到 `python3 -m http.server`（v1.3.0 原行为）
  - 前端 probe 失败自动退回一次性静态加载模式，徽章显示 `○ static`

### 🎨 UI

- 新事件行进场动画：`@keyframes event-flash`（1.2s accent 色背景渐隐）
- Live 徽章脉动：`@keyframes live-pulse`（on 状态 1.8s 周期，connecting 0.9s）
- 新增 `.live-badge` 4 种状态样式

### 🔧 Changed

- `scripts/pl-dashboard.sh` 默认走新 server（live-reload 模式），新增 `--static-only` 参数
- live-reload 模式下 `/trace/*` 路由由 server 直接处理（不再强依赖 symlink；symlink 仍保留用于 static-only 兼容）

### 📐 架构备注

选 SSE 而非 WebSocket：
- WebSocket 需要额外库 + 握手复杂度
- SSE 单向推送已满足"服务端→浏览器"的事件流场景
- 浏览器 `EventSource` 原生支持自动重连，客户端代码极简

选自写 `BaseHTTPRequestHandler` 而非 `python3 -m http.server`：
- stdlib `http.server` 不支持长连接端点
- 自写 server 仍保持零第三方依赖原则

### 🧪 E2E 验证

- `pl-dashboard.sh` 启动 → curl `/_events/stream` 看到 `hello / snapshot / append` 推送
- Playwright 打开 index.html → 追加事件后卡片自动刷新任务计数 + 事件数
- Playwright 打开 change.html → 追加事件后 timeline 实时多出新行
- `--static-only` 模式下前端 probe 失败，徽章显示 `○ static`，功能降级到 v1.3.0

证据快照：`docs/retros/evidence-2026-04-v1.3.2/change-live.png`

---

## [1.3.0-alpha] — 2026-04-22 · Observe 层 MVP

**主题：从"事件已发生"到"事件可被看见"。**

### ✨ Added

- **事件信封 schema v1.3**（`assets/pl/schemas/event-v1.3.schema.json`）
  - 8 字段规范：`ts / trace_id / change_id / phase / actor / event / data / parent_trace_id?`
  - actor 三类：`agent:<id>@<ver>` / `rule:<id>@<ver>` / `skill:<id>@<ver>`

- **零依赖 fs watcher**（`scripts/_lib/observe-fs.py`）
  - Python stdlib 轮询（0.5s 间隔）
  - 21 个资产（rule / skill）批量补 frontmatter `id + version`（`scripts/_lib/backfill-frontmatter.py`）

- **业务语义规则引擎**（`scripts/_lib/observe-apply-rules.py`）
  - 5 条默认规则（`assets/pl/observe-rules.default.yaml`）：taskdag row added / taskdag task done / state stage transition / rule asset promoted / skill asset promoted
  - 规则把 `artifact.modified` 类底层事件聚合为 `plan.task.added / task.done / state.transition / asset.promoted` 业务事件
  - 去重 key 含 captures，避免一次大修改被当成一条

- **Dashboard MVP 双视图**（`dashboard/`）
  - index.html：change 列表（卡片、stage、gate、tasks、violation）
  - change.html：单 change timeline + 3 维过滤 + payload 展开
  - 纯静态 HTML + CSS + ES modules，无构建
  - dark/light 主题切换（localStorage 持久化）

### 🧪 实测

- 48 events，Playwright 验证 index / change / filter / payload expand 全通过

---

## [1.2.0] — 2026-04-22 · retro-v2 收官版

**主题：pl/piao 从"文档契约层"彻底升级为"可执行契约层"。**

本版本合并了 `pl-v1.1.0-alpha` / `pl-v1.1.1-alpha` / `pl-v1.1.2-alpha`
三个 alpha tag 的所有能力，作为 retro-v2 四剂药完全闭环后的首个正式版。

### 🎯 核心叙事

retro-v1 时代，pl 的门禁是散文式的口头承诺，导致 2026-04 首次跑 demo 时 **7 个 bug**
全部从纸面绿门禁溜过。retro-v2 把根因归到 pl / piao 本体缺 4 个通用抽象（E1 / E2 / E3 / E4），
本版完成 4/4 落地：retro-v2 的原始 7 个 bug 现在 **7/7 都有机器检测路径**。

### ✨ Added — pl-core 本体

- **E1 可执行契约层**（`pl-runner.sh` + `GateDefinition / CheckDefinition` 数据模型）
  - 新增 `assets/pl/schemas/gate.schema.json`
  - `config.default.yaml` v1.0 → v1.1：定义 `checks[]` 池 + `gate.eval` 机器可求值规则
  - 移除配置里的 `gradle` / `ApiSelfCheck` 等宿主硬编码
  - 新增 `scripts/pl-runner.sh`：解析 `gate → checks` 引用 → 按 `.pl-adapter.yaml` 载 env → 跑 check → 按 `eval` 派生 gate 结果
- **E2 SMOKE 阶段**（`pl-smoke.sh` + `adapter.smoke` 声明）
  - `ORDERED_STAGES` 新增 🔥 SMOKE（位于 VERIFY 和 OBSERVE 之间）
  - `adapter-manifest.schema.json` 新增 `build_adapter.smoke.{start_cmd,ready_url,probes[]}`
  - 新增 `scripts/pl-smoke.sh`：boot 应用 → 轮询 ready_url → 逐 probe HTTP 断言 → 关停整个进程树
  - SMOKE opt-out 也发 `smoke.skip` + `gate.eval:skipped` 事件（不静默）
- **E3 rule-as-code 引擎**（`pl-rule-scan.sh` + rule frontmatter）
  - rule 文件顶部可声明 YAML frontmatter：
    `id / severity / scope / applies_to.glob / detect[].{kind,pattern} / message / fix_hint`
  - 支持 3 种 `detect.kind`：`file_contains` / `file_not_contains` / `line_contains`
  - 新增 `scripts/pl-rule-scan.sh` + 4 个 `scripts/_lib/*.py` 协作库
  - 没有 frontmatter 的 rule 仍是纯文档（完全向后兼容）
- **orchestrator 解耦**
  - `pipeline-orchestrator.sh` 的 `stage_actor()` 移除 `agent:migration-*` 硬编码
  - 改为 `${STAGE}_ACTOR` 环境变量可被 adapter 注入

### ✨ Added — piao-kernel 本体

- **E4 契约-现实漂移**（`piao-contract-drift-compute.sh`）
  - 与原 `piao-drift-compute.sh`（snapshot→snapshot 时序差分）正交共存
  - 新 drift 维度：**declared contract**（adapter.yaml.contract）vs **actual state**（宿主实测 lockfile/filetree）
  - 三类 diff 条目：`missing_file` / `peer_version_violation` / `bad_combo_hit`
  - 产物：`pipeline-output/drift/<change>-contract.yaml`（`apiVersion: piao.dev/v1, kind: ContractDrift`）
  - `adapter-manifest.schema.json` 新增 `properties.contract` 完整字段
  - **piao ↔ pl trace 首次合流**：`piao.contract_drift.detected` 直接落 pl 的 `events.jsonl`

### ✨ Added — adapter 消费侧

- `adapters/adapter-nextjs-web/adapter.yaml`：
  - 新增 `build_adapter.smoke`（SMOKE opt-out，dev server 特殊性）
  - 新增 `contract.expected_files`（tsconfig.json / app/layout.tsx / ...）
  - 新增 `contract.peer_versions.npm`（next>=15 / react>=19 / @types/*>=19 / ...）
  - 新增 `contract.known_bad_combos`（`types-react-dom-18-with-useFormState`）
  - 新增 `rules/nextjs-revalidate-for-non-fetch.md`（可执行，对应 retro-v2 B3）
- `adapters/adapter-python-fastapi/adapter.yaml`：
  - 新增 `build_adapter.smoke`（uvicorn boot + 3 probe：happy / duplicate / unauthorized）
  - 新增 `contract.expected_files`（pyproject.toml / app/main.py / ...）
  - 新增 `contract.peer_versions.python`（fastapi>=0.110 / bcrypt>=4,<5 / python-multipart / ...）
  - 新增 `contract.known_bad_combos`（`passlib-vs-bcrypt-5`）
  - 新增 `rules/fastapi-no-sync-blocking-in-async.md`（可执行）
  - 新增 `rules/fastapi-depends-pass-callable.md`（可执行）

### 🧪 Changed

- `adapter-manifest.schema.json`：apiVersion `pl.dev/v1` → `pl.dev/v1.1`
  新增 `build_adapter.smoke` + `contract` 两个顶级字段（均 optional，向后兼容）
- `pl/config.default.yaml`：v1.0 → v1.1
  - 新增 `checks` 池（定义可复用检查器）
  - 每条 gate 增加 `eval` 字段（机器可求值规则，如 `all_checks.pass`）
  - 移除所有宿主特定字符串
- rule 文件 frontmatter 是**新能力**，不破坏现有纯文档 rule

### 📚 Docs

- 新增 `docs/retros/2026-04-demo-first-run-retro-v1.md`（故意保留作为"误诊归档示例"）
- 新增 `docs/retros/2026-04-demo-first-run-retro-v2.md`（正确归因 + 4 剂药设计）
- 新增 `docs/retros/evidence-2026-04/`：
  - `demo-fastapi-users.events.jsonl`（15 events，四通道合流）
  - `demo-fastapi-users-contract-drift.yaml`（E4 artifact）
  - `demo-fastapi-users-rule-scan.yaml`（E3 artifact）
  - `demo-nextjs-todo.events.jsonl`（8 events，SMOKE opt-out）
  - 配套 contract-drift.yaml + rule-scan.yaml
  - 完整 README：反证实验 + 四通道合流示意
- 更新 `ROADMAP.md`：v0.2 本体增强表 E1/E2/E3/E4 全部 ✅
- 新增 `MIGRATION.md`：v1.0 → v1.2 升级指南

### 🔬 反证实验（最有说服力的证据）

retro-v2 的 7 个原始 bug，现在每个都有机器检测路径：

| bug | 类型 | 检测路径 |
|---|---|---|
| B1 | React 18.3 × `@types/react-dom` canary 缺失 | **E4** `known_bad_combos.types-react-dom-18-with-useFormState` |
| B2 | TypeScript 编译错 | **E1** `compile_check` |
| B3 | `revalidateTag` 对 module-state 数据源无效 | **E3** `nextjs-revalidate-for-non-fetch` |
| B4 | 缺 `tsconfig.json` / 根 `app/layout.tsx` | **E4** `expected_files` |
| B5 | HMR 清空 module state | **E2** SMOKE 两次 POST + GET 对比 |
| B6 | 缺 `python-multipart` | **E4** `peer_versions` / **E2** SMOKE boot 报错 |
| B7 | `passlib × bcrypt 5.x` 坏 combo | **E4** `known_bad_combos.passlib-vs-bcrypt-5` |

- pre-retro：0/7 被机器抓住
- post-retro：7/7 被机器抓住

### 🔧 Fixed（实施过程的踩坑修复）

- **macOS bash 3.2** 对 `$(cmd <<'HEREDOC' ... HEREDOC)` 多 `)` heredoc 的解析 bug：
  所有复杂 Python 代码迁移到独立 `scripts/_lib/*.py` 文件，bash 脚本只做薄编排
- **`PL_HOME` 被父目录污染**：`piao-contract-drift-compute.sh` 加纠偏逻辑
- **YAML 简易解析器**：支持 flow-style list (`["a","b"]`)、带引号 key (`"@types/react": ...`)、
  双引号 value 里的转义（`"pat\\("` 解析为 `pat\(`）
- **glob → regex 转换**：`**/` 正确等价于"零或多个路径段"（原 `fnmatch.translate` 译法要求至少一段，导致 `app/**/_actions/**/*.ts` 命中不了 `app/todos/_actions/todos.ts`）
- **semver 空格/逗号兼容**：`">=18.0.0 <19.0.0"`（npm 风格）等价于 `">=18.0.0,<19.0.0"`（pip 风格）

### 🏁 统计

- 新增脚本：`pl-runner.sh` / `pl-smoke.sh` / `pl-rule-scan.sh` / `piao-contract-drift-compute.sh`（4 个主脚本 + 10+ 个 `_lib/*.py` 协作库）
- 新增 schema：`gate.schema.json` + `adapter-manifest.schema.json` 扩展
- 单元级 orchestrator / pl-core / piao-kernel 三层触达
- 首次实现 piao ↔ pl **同一条 events.jsonl**

---

## [pl-v1.1.2-alpha] — 2026-04-22

**仅 E3 rule-as-code 落地**；其余变更见 [1.2.0]。

### Added
- `scripts/pl-rule-scan.sh` + `_lib/{parse-rule-frontmatter,collect-rule-files,match-rule,summarize-rules}.py`
- adapter-nextjs-web/rules/nextjs-revalidate-for-non-fetch.md
- adapter-python-fastapi/rules/fastapi-no-sync-blocking-in-async.md
- adapter-python-fastapi/rules/fastapi-depends-pass-callable.md
- trace 事件 `pl.rule_scan.completed`
- 四通道合流：`IMPLEMENT.gate.eval` + `SMOKE.*` + `OBSERVE.piao.contract_drift` + `OBSERVE.pl.rule_scan`

### Fixed
- YAML frontmatter 双引号值的转义处理
- glob `**/` 零或多路径段语义

---

## [pl-v1.1.1-alpha] — 2026-04-21（晚间）

**仅 E4 契约-现实漂移 落地**；其余变更见 [1.2.0]。

### Added
- `scripts/piao-contract-drift-compute.sh`（主 orchestrator）
- `scripts/_lib/{parse-contract,collect-exists,collect-npm,collect-python,diff-contract,summarize-drift}.py`
- `adapter-manifest.schema.json` 新增 `properties.contract`
- 两个 adapter 的 `contract` 段
- trace 事件 `piao.contract_drift.detected`（piao ↔ pl 首次合流）

### Fixed
- bash 3.2 嵌套 heredoc 解析策略：拆到 `_lib/*.py`
- PL_HOME 父目录污染纠偏
- `@types/react` 带引号 key 解析
- semver `>=18.0.0 <19.0.0` 空格分隔支持

---

## [pl-v1.1.0-alpha] — 2026-04-21（下午）

**E1 + E2 + orchestrator 解耦**；其余变更见 [1.2.0]。

### Added
- `assets/pl/schemas/gate.schema.json`（GateDefinition / CheckDefinition 数据模型）
- `scripts/pl-runner.sh`（E1 可执行契约层）
- `scripts/pl-smoke.sh`（E2 SMOKE 阶段）
- `adapter-manifest.schema.json` 新增 `build_adapter.smoke`
- `ORDERED_STAGES` 新增 SMOKE

### Changed
- `pl/config.default.yaml`：v1.0 → v1.1（checks 池 + gate.eval）
- 移除 `pipeline-orchestrator.sh` 的 `migration-*` 硬编码
- adapter-manifest.schema.json：apiVersion `pl.dev/v1` → `pl.dev/v1.1`

---

## [1.0.0] — 2026-04-20（历史快照）

> **注意**：v1.0 是"门禁是散文" 时代的最后一个版本。
> 建议所有用户**直接跳到 v1.2.0**，不要在 v1.0 基础上积累项目代码。

### Added（那时已完成的）
- 6 阶段 × 7 门禁状态机（SPEC → PLAN → IMPLEMENT → VERIFY → OBSERVE → ARCHIVE）
- 7 件核心产物（spec.md / plan.md / taskdag.md / api.md / testmatrix.md / deps.md / .state.md）
- `pl-status.sh` / `pl-dashboard-refresh.sh` / `pl-migrate-legacy.sh`
- adapter 协议 v1（requires / piao_emit / build_adapter / rules / skills / agents）
- 两个官方 adapter：`adapter-nextjs-web` / `adapter-python-fastapi`
- 两个端到端 demo：`demo-nextjs-todo` / `demo-fastapi-users`

### Known Issues（v1.0 的主要限制，在 v1.2.0 解决）
- gate 判据是散文 → **v1.2 E1 解决**
- VERIFY 不启动应用（只跑静态检查）→ **v1.2 E2 解决**
- rule 只是 AI prompt 不能 CI 跑 → **v1.2 E3 解决**
- 无法发现"宿主依赖不符合 adapter 期望"类 bug → **v1.2 E4 解决**

---

## Unreleased

### Planned for v1.3
- KuiklyPolyCity 宿主级迁移验证（跑 pl-runner/pl-smoke/contract-drift/rule-scan 四件套）
- 更多 adapter（kotlin-kmm / rust-cargo / go-modules）
- `pl-runner` MVP 级联测试：一条命令跑完整 5 门禁

### Planned for v2.0
- TypeScript CLI 重写（`packages/cli` + `packages/core`）
- `pl init --smart`：技术栈扫描 + Preset 推荐
- MCP Server 适配所有 MCP 兼容 IDE
- 文档站（pl-pipeline.dev）

---

[1.2.0]: https://github.com/walkertop/pl-pipeline-standalone/releases/tag/pl-v1.2.0
[pl-v1.1.2-alpha]: https://github.com/walkertop/pl-pipeline-standalone/releases/tag/pl-v1.1.2-alpha
[pl-v1.1.1-alpha]: https://github.com/walkertop/pl-pipeline-standalone/releases/tag/pl-v1.1.1-alpha
[pl-v1.1.0-alpha]: https://github.com/walkertop/pl-pipeline-standalone/releases/tag/pl-v1.1.0-alpha
[1.0.0]: https://github.com/walkertop/pl-pipeline-standalone/releases/tag/v1.0.0
[Unreleased]: https://github.com/walkertop/pl-pipeline-standalone/compare/pl-v1.2.0...HEAD
