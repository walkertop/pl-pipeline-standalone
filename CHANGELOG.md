# Changelog

本项目的所有显著变更都会记录在此。

格式遵循 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/)，
版本号遵循 [语义化版本](https://semver.org/lang/zh-CN/)。

---

## [Unreleased]

### 新增

- `pl agent run`：Agent Execution Loop MVP，本地 executor 执行命令后可调用 gate 验证，失败时生成 repair context，并在 retry 预算内执行修复命令。
- `agent.repair.strategy`：可在 `pl/config.yaml` 按 `failure_kind` 配置 repair policy，替代每次手写 `--repair-cmd`。
- `pl agent run` trace metadata：新增 `--provider` / `--model` / `--prompt-path` / `--input-artifact` / `--output-artifact` / `--tool-call` / `--tokens-*`，为外部 executor adapter 预留统一观测模型。
- `examples/demo-agent-loop`：可验证 demo，故意写入错误 Python 实现，再通过 gate 失败上下文修复到 `unittest` 通过。
- `examples/demo-agent-crud-service`：更接近业务任务的 CRUD demo，展示 `policy:test_failure` 自动修复闭环。
- `tests/cli/test-pl-agent.sh`：覆盖 agent loop 的执行、repair context、trace 事件和最终 gate 通过路径。

## [pl-v1.12.0] - 2026-04-24

### 新增

#### `pl ide` 扩展到 4 个 IDE：Claude Code + Codex CLI

继 v1.11.0 首发 Cursor + CodeBuddy 之后, 利用 manifest 化的 IDE 集成层, 几乎零业务代码新增了：

- **Claude Code**（`ide-integrations/claude/manifest.yaml`）
  - `commands` → `.claude/commands/pl/*.md`（带 frontmatter）
  - `agents`   → `.claude/agents/pl-*.md`
  - `rules`    → 通过根 `CLAUDE.md` 引用（Claude 没 rules 子目录）
  - `skills`   → v1.13 计划支持目录型 skill；v1.12 先按 reference 模式列在 CLAUDE.md
  - 注册入口：`CLAUDE.md`（独立于 `AGENTS.md`）

- **Codex CLI**（`ide-integrations/codex/manifest.yaml`）
  - 完全 reference-only：不复制任何文件, 只在 `AGENTS.md` 维护 pl-managed 段, 列出 `@pl/...` 引用清单
  - 这种"零侵入"模式贴合 Codex 把 `AGENTS.md` 当 canonical 的设计

支持矩阵更新见 [`docs/ide-integration.md`](./docs/ide-integration.md)。

#### Manifest 新增 `target_file` 字段

`root_agents_md.target_file` 默认 `AGENTS.md`；Claude 用 `CLAUDE.md`。

#### Reference 列表智能化

`enabled: false` 的 section 不再写绝对 PL_HOME 路径。优化为：

- 项目内有 `pl/<section>/` → 列项目内相对路径（可移植）
- 项目内没有但 PL_HOME 自带 → 给一行 `cp -r $PL_HOME/...` 行动指引（不暴露绝对路径）

#### `adapter-install.sh` 三大改造

1. **canonical 双写**：除了 legacy `.codebuddy/`，**同时**写到 `pl/.adapter/{agents,skills,rules}/`。
   `pl ide sync` 自动从 `pl/.adapter/` 拉取并 fan-out 到所有目标 IDE，**adapter 不再需要关心 IDE**。
2. **新选项 `--no-legacy`**：跳过 `.codebuddy/` 写入（v2.0 起将默认开启）
3. **新选项 `--ide-sync`**：装完自动调用 `pl ide sync`，无缝衔接

#### `pl/config.yaml requires.pl_version` 启动自检

```yaml
# pl/config.yaml
requires:
  pl_version: ">=1.12"
```

`bin/pl` 启动时（除 `doctor`/`upgrade`/`version`/`help`/`detect`/`new`/`init`/`env` 外）会做 SemVer 比较：

- 当前 < 要求 → stderr 输出黄色警告 + 提示跑 `pl upgrade`，但**不阻塞**执行
- 当前 ≥ 要求 → 静默
- `PL_REQUIRE_CHECK=0` 关闭

支持的算子：`>=`、`>`、`<=`、`<`、`==`、`^`/`~`/`=`（后三者按 `>=` 处理）。

#### `pl-rule-scan.sh` 三层规则解析

为配合 `pl/.adapter/` canonical 路径，规则查找顺序：

```
PL_PROJECT/pl/rules/             # 项目层（最高）
PL_PROJECT/pl/.adapter/rules/    # adapter 注入层（v1.12+）
PL_PROJECT/.codebuddy/rules/     # legacy 兼容
```

不需要任何配置, 自动按优先级 fallback。

### 修复

- `pl_ide_sync.py` 在写 hash marker 时强制要求 source 在 PL_HOME 下；现已支持 `pl/.adapter/` 这种 PL_PROJECT 内 source

### 测试

新增 7 个 case（`Suite: ide-sync-v1.12` + `Suite: require-check`）：

- ide-integrations 目录包含 4 个内置 manifest
- `pl ide sync --ide claude` 写入 `.claude/` + `CLAUDE.md`
- `pl ide sync --ide codex` 仅写 `AGENTS.md`，不复制任何目录
- 4 个 IDE 共存时 `AGENTS.md`/`CLAUDE.md` 段落互不覆盖
- `requires.pl_version` 不匹配 → stderr 警告
- `PL_REQUIRE_CHECK=0` 关闭自检
- `doctor` 命令本身不被自检干扰

总用例 50/50。

### 文档

- 新增 `docs/ide-integration.md`：IDE 集成完整指南（支持矩阵、流程、设计原则、添加新 IDE、故障排查、路线图）
- 更新 `README.md` § 多 IDE 接入 章节
- `assets/pl/config.default.yaml` 加 `requires` section 示例

### 兼容性

- **完全向后兼容**：v1.11.0 行为保留, adapter-install 默认仍写 `.codebuddy/`
- **SemVer 政策**：`requires.pl_version` 自检默认开启, 但 warn-only, 不破坏既有流程
- v2.0 起 `.codebuddy/` legacy 路径默认关闭, 需 `--legacy` 启用（v1.x 期间会有 deprecation warning）

### 路线图

- v1.13: Claude `.claude/skills/<name>/SKILL.md` 目录型同步
- v1.13: `pl ide diff` 预览未来 sync 行为
- v2.0: legacy `.codebuddy/` 路径默认关闭

---

## [pl-v1.11.0] - 2026-04-24

### 新增

#### `pl ide` —— 多 IDE 资产同步（OpenSpec 风格）

把 `pl/{rules,agents,skills,commands}` 作为单一可信源，一条命令同步到各 AI IDE 约定目录。
解决了之前 v1.0 ~ v1.10 期间 `.codebuddy/` 硬编码、对其它 IDE 不友好的痼疾。

```bash
pl ide detect                          # 扫描项目, 列出已检测到的 IDE
pl ide list                            # 列出所有 pl 当前管理的 IDE 文件
pl ide sync   [--ide <id>] [--all]     # pl/ → IDE 目录 fan-out
pl ide unsync [--ide <id>] [--all]     # 撤回 pl 写过的文件
```

**IDE 差异化矩阵（v1.11.0 首发支持 Cursor + CodeBuddy）**：

|          | Cursor                              | CodeBuddy                       |
| -------- | ----------------------------------- | ------------------------------- |
| 检测     | `.cursor/` 或 `.cursorrules` 存在   | `.codebuddy/` 存在              |
| rules    | `.cursor/rules/pl-*.mdc` + frontmatter | `.codebuddy/rules/pl-*.md` plain |
| commands | `.cursor/commands/pl/*.md` 无 frontmatter | `.codebuddy/commands/pl/*.md` 带 frontmatter |
| agents   | 不复制（用 `@-mention` 引用 `pl/agents/*.md`） | `.codebuddy/agents/pl-*.md` 复制 |
| skills   | 不复制（同上）                       | 不复制                           |
| AGENTS.md | 写一段 `pl-pipeline:cursor managed section` | 写一段 `pl-pipeline:codebuddy managed section` |

差异由 `ide-integrations/<id>/manifest.yaml` 声明式描述, 不在脚本里 hardcode。
新增 IDE（如 Claude Code、Codex）只需加一份 manifest 即可, 无需改 Python 代码。

**冲突保护机制**：

1. **命名隔离**：所有 sync 出去的文件加 `pl-` 前缀（commands 在 `pl/` 子目录已隔离故不加），
   不会和用户已有 rules / agents 撞名。
2. **Hash 标记**：每个 sync 写入的文件首行（或 frontmatter 之后）插入：
   ```
   <!-- pl-managed: hash=<12位> source=<相对路径> ide=<id> -->
   ```
   重新 sync 时若 `sha256(剔除标记后的内容)[:12] != hash` → 检测为用户手改, 默认拒绝覆盖；
   `--force` 强制覆盖。
3. **分段 marker**：根 `AGENTS.md` 用 per-IDE marker 隔离, 同步多个 IDE 互不干扰。
4. **三层资产栈**：rules/agents 的 source 按 `pl/<type>/` → `pl/.adapter/<type>/` → `$PL_HOME/assets/pl/<type>/` 顺序查找, 项目级始终覆盖 adapter / pl 自带, 跟既有覆盖契约一致。

**幂等 + 可逆**：

- 多次跑 `pl ide sync` 行为一致（已在文件且 hash 匹配 → 跳过）
- `pl ide unsync` 恢复到 sync 前的状态（hash 校验过的才删, 用户手改自动保留, `--force` 强删）
- AGENTS.md 段落 sync 时写入, unsync 时干净剔除

#### `ide-integrations/cursor/` 首发支持

- Cursor 2026 约定：`.cursor/commands/*.md`（plain markdown）+ `.cursor/rules/*.mdc`（带 YAML frontmatter, `alwaysApply: true`）
- 复用 `ide-integrations/codebuddy/commands/pl/*.md` 作单源, sync 时按 manifest 自动剥除 frontmatter

### 改进

- `bin/pl` 帮助文案新增 "IDE 集成" 段落, 并把 `ide` 加入 namespace 路由
- `tests/cli/test-pl.sh` +7 case（Suite 7 `ide-sync`）：
  detect / sync 实际写入 / 文件格式正确（`.mdc` vs `.md`）/ AGENTS.md 段落正确 / hash 保护 / unsync 可逆

### 设计权衡（写给后续维护者）

- **为什么用 manifest.yaml 而不是硬编码**：
  支持新 IDE 的成本 = 加一个目录 + 一份 yaml, 不动 Python 代码。这跟 `adapters/` 的契约设计一致 —— 数据驱动, 行为收敛。

- **为什么 Cursor 的 agents/skills 不复制**：
  Cursor 没有"agents 目录约定", 用户用 `@pl/agents/foo.md` 直接引用即可。复制只会污染 `.cursor/`。
  CodeBuddy 不一样 —— 它强制要求 `.codebuddy/agents/*.md` 物理存在才能识别, 故复制。

- **为什么用 `pl-` 前缀**：
  用户的 rules / agents 跟 pl 的不在一个命名空间。前缀让用户一眼看出"哪些是 pl 维护的"。
  对应 `pl ide unsync` 时, hash 标记 + 前缀双保险, 不会误删用户文件。

- **为什么不同 IDE 用独立 marker 段**：
  早期实现用统一 marker 导致后 sync 的 IDE 把前一个段冲掉。改成 `pl-pipeline:<ide_id> managed section`
  后, 多 IDE 段独立存在；用户也容易一眼看出"cursor 的同步包括啥"。

- **为什么 sync 后用扫描而不是用本次新写文件做 AGENTS.md 列表**：
  幂等运行（无新写）若用"本次新写"列表, AGENTS.md 列表会变空。改成扫描"目标目录里所有打了 pl-managed 标记且 ide=<id> 的文件"后, 任何时候 sync 都能把 AGENTS.md 维护成"当前实际状态"。

### 兼容性

- 完全向后兼容：未跑 `pl ide sync` 的项目行为不变
- `adapter-install.sh` 暂未改, 仍写 `.codebuddy/`（v1.12 计划：先写到 `pl/agents` canonical, 再让 sync fan-out）
- `pipeline-output/` 路径暂未变（v1.12 计划：统一到 `pl/.runtime/`, 配合 `pl/config.yaml requires.pl_version`）

### 依赖

- 新增 PyYAML 软依赖（与 `adapter-install.sh` / `pl-contract-verify.sh` 等已有脚本一致）。`pl ide sync` 启动时检测, 缺失给出明确安装指引：
  ```
  [pl-ide] 致命错误：缺少 PyYAML。请运行 `pip3 install --user pyyaml` 后重试。
  ```

---

## [pl-v1.10.1] - 2026-04-24

### 新增

#### `pl upgrade` —— pl-pipeline 自身的版本升级命令

之前升级 pl-pipeline 只能：(a) 重跑 `install.sh`、(b) `cd $PL_HOME && git pull` 手动操作。
v1.10.1 起 pl 自己就能升：

```bash
pl upgrade                       # 升到最新 stable tag (pl-v*, 过滤 pre-release)
pl upgrade --check               # 只检查不升级
                                 #   exit 0  = 已是最新
                                 #   exit 10 = 有新版本可升
                                 #   exit 1  = 检查失败
pl upgrade --ref pl-v1.10.0      # 锁到指定版本
pl upgrade --ref main            # 切到主干（开发场景）
pl upgrade --no-fetch            # 离线模式，用本地已 fetch 的 ref
```

**安全约束**（避免吞掉本地改动）：
- PL_HOME 必须是 git 仓库（vendor 拷贝模式拒绝；submodule 模式提示走宿主仓 PR）
- PL_HOME 有未提交修改时拒绝 checkout，提示 `git stash` 或 commit 后再升
- 默认 `--depth` 不限制（可访问历史 tag）

#### `pl doctor` 新增 [版本] 段落的远端过期检查

`pl doctor` 现在会主动告诉你"是否过期"：

```bash
pl doctor
# [版本]
#   pl-pipeline = 1.10.0
#   ✓ 已是最新 stable                    ← 或
#   ↑ 有新版本: 1.10.1（运行 pl upgrade 升级；离线请设 PL_DOCTOR_OFFLINE=1）
```

**性能与隐私设计**：
- 24 小时内只 fetch 一次（缓存到 `$PL_HOME/.git/.pl-doctor-fetched`，第二次跑 doctor < 50ms）
- `PL_DOCTOR_OFFLINE=1` 完全跳过远端检查（适合 CI / 内网无外网）
- `PL_DOCTOR_NO_FETCH=1` 用本地已 fetch 的 tag 比对，但不联网（混合模式）
- 远端检查失败时静默降级（不让网络抖动把 doctor 报红）
- 仅当 PL_HOME 是 git 仓库时启用（vendor 模式自动跳过并提示）

### 改进

- `bin/pl` 帮助文案更新：`upgrade` 列入元命令；`doctor` 描述加上"版本是否过期"
- 测试套件 +6 case（`tests/cli/test-pl.sh` Suite 6）：upgrade --help / --check / --no-fetch / 非 git 报错 / doctor offline / doctor [版本] 段落

### 设计权衡（写给后续维护者）

为什么 doctor 远端检查默认启用、warn-only、不影响 rc？
- 启用：用户痛点是"不知道自己过期" — 默认 silent 失去价值
- warn-only：网络抖动不该让 `pl doctor && do_something` 这条链断
- 24h 缓存：避免每次 `pl doctor` 都打 fetch，对 GitHub API 友好
- 想要硬阻断（CI 强制最新）的用户可以自己 `pl upgrade --check`（exit 10 = 过期）

为什么 `pl upgrade` 拒绝 vendor / submodule？
- vendor：升级 = 替换文件，pl 无权代替你做这件事
- submodule：升级会污染宿主仓 git history，必须走宿主仓的 PR / commit 流程

---

## [pl-v1.10.0] - 2026-04-24

### 新增

#### `pl detect` / `pl scan` —— 扫描你的项目，给出建议（不写文件）

替代之前 `pl new --here` "硬塞模板"的强势作风。新姿势是 **detect → suggest → 你拍板**：

```bash
cd /your/existing/project
pl detect                 # 扫描子目录，识别 stack，给建议；纯只读
pl detect --json          # JSON 输出，给脚本/CI 消费
pl scan                   # detect 的别名
```

**识别清单（v1.10.0）：**
- 前端：`Next.js`（package.json 有 next 依赖）、`Vue + pnpm monorepo`（pnpm-workspace.yaml + Vue 依赖）
- Python：`FastAPI`、`Scrapy`、`dlt + Prefect`、未识别的通用 Python
- 契约：`OpenAPI` 文件（识别为 CDC 锚点）
- 文档：`docs/` 下 ≥ 8 份 .md（识别为成熟规格，建议跳过 SPEC 阶段）
- 骨架未初始化：`apps/+packages/` 但无 package.json；`src/+tests/` 但无 pyproject.toml
- 已接入 pl：模块根有 `pl/config.yaml`

每条 detection 输出 module / stack / confidence (high/medium/low) / evidence / suggestion。

#### `pl new --here` 默认改为只读 dry-run

之前的"灌模板"作风太武断。现在 `pl new --here` **不带 `--stack` 时自动调 detect**，
输出建议 + 提示下一步加 `--stack` 重跑。**完全不写文件**。

```bash
pl new whatever --here                    # 跑 detect，给建议，零写入
pl new whatever --here --stack bare       # 显式 → 装 pl 骨架（既有行为）
pl new whatever --here --stack fastapi    # 显式 → 装 fastapi adapter（既有行为）
```

老用法 100% 向后兼容（指定 `--stack` 即按既有逻辑装）。

### 修复

无（pure addition）。

### 改进

- README "30 秒上手" 段落升级到 v1.10：突出 `pl detect`，已有项目接入流程改为"先 detect 后选 stack"。
- `pl help` 把 `detect` 列在核心命令第一位（鼓励先扫描后操作）。
- 测试套件 +19 case（`tests/cli/test-pl-detect.sh`），覆盖：
  - 9 种 detector 准确性（fixture 项目验证）
  - JSON 输出 schema 校验
  - bash 3.2 兼容（不应有 unbound variable / declare -A 错误）
  - `pl new --here` 默认 dry-run 行为（验证不写文件）
  - `pl new --here --stack bare` 仍写文件（不破现有行为）

### CI

- 新增 `pl-detect-smoke` job（`.github/workflows/ci.yml`）。

### 教训沉淀

设计这个能力的契机是：v1.9.x 的 `pl new --here` 太强势，遇到 shop_agent 这种"已有
完整规格 + 初步代码骨架"的项目时硬塞模板会破坏既有结构。**正确姿势是工具应该
"先看清现状再建议"**，而不是"以为自己什么都懂"。

技术坑：bash 3.2 (macOS 默认) + `set -euo pipefail` + process substitution
(`< <(find | sort)`) 会 silent crash。本脚本特殊禁用 `-e` 和 `pipefail`，
单 detector 失败不影响其他。

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
>
> 🔍 **2026-04-24 v1.7.1**：CDC 读侧补齐——`pl-contract-query.sh` 让 adapter 作者
> 在「砍 capability/skill」前先看清谁在用；让 consumer 作者在升级前看清自己用了啥。
>
> 📺 **2026-04-24 v1.7.2**：CDC 进 Dashboard——pact 状态从 CLI 出现到首页角标，
> 每个 change 卡片自带 `pact ✓ / ! N / ✗ N` badge，顶部一行 `CDC contracts` 汇总，
> ARCHIVE auto-aggregate 后秒级自动刷新。让"契约健康度"成为日常可见的指标。
>
> 🔎 **2026-04-24 v1.7.3**：CDC drill-down——v1.7.2 的角标从"红或绿"升级为"点进去看哪里红"。
> 点首页角标 → 跳到 change 详情页 Contract 卡片，每条 violation 显示完整 reason
> 和源文件绝对路径（一键复制丢进 IDE 跳转）。从 visibility 到 actionability。
>
> 🛠 **2026-04-24 v1.8.0**：统一 CLI 收口——`bin/pl` 一个入口替代 34 个散落的
> `bash $PL_HOME/scripts/*.sh`。命名空间归口（`pl contract|trace|adapter|piao|...`），
> 修掉 README 长期画饼的 `pl proposal/plan/report` 文档欺诈，老路径 100% 向后兼容。
>
> 📑 **2026-04-24 v1.8.1**：文档真实化第 1 弹——清掉 README 6 个死链
> （pl-pipeline.dev / discord / twitter / your-org Roadmap）+ 重写 v2.0 愿景段
> （不再画饼，承诺转 issue）+ "alpha 阶段" → "stable, dogfooded"，
> 顺手修 `pl-status.sh: dirs[@]: unbound variable` 旧 bug（bash 3.2 + set -u 兼容）。
>
> 🍴 **2026-04-24 v1.8.2**：自吃狗粮——把 agent prompt / 用户文档 / CI workflow 全部
> 切成 `pl <subcmd>` 风格，让 v1.8 CLI 真正成为 first-class citizen 而非"装饰"。
> 19 个文件、120 行变更。`adapter-create` 输出的 "next steps" / 各 adapter README /
> dashboard 文档 / FAQ / MVP_STATUS / agent prompt 全部统一。
> MIGRATION.md 加头部 note 不全文改（保留历史快照）。
>
> ✅ **2026-04-24 v1.8.3**：测试扎实——首次给 `bin/pl` CLI 加 29 个单元测试
> （覆盖 meta-commands / 错误处理 / 命名空间路由 / 顶层映射 / argv 透传 / bash 3.2 兼容），
> 给 CDC 加 3 个真实场景测试（demo-nextjs / demo-fastapi 全闭环 + dashboard endpoint），
> CI 加两个新 job：`cli-smoke` + `cdc-real-scenarios`。
> 自此 v1.8.x CLI 改一行就有 32 个测试守。**v1.8.x 收官**。
>
> 🏗️ **2026-04-24 v1.8.4 · monorepo 接入指南 + demo-trio**：把"前端 + Python 服务端 + 爬虫"
> 三模块从 0 到 1 接入 pl-pipeline 的完整心智模型 / 步骤 / 可跑骨架沉淀成文档与示例，
> 关键澄清"无 adapter 的模块（爬虫/Go/Rust）也能裸跑 pl-core"。
>
> 🚀 **2026-04-24 v1.9.0 · zero-friction 上手**：把"装工具 + 起项目"从 8 步压成 2 条命令——
> `curl ... | bash` 装 + `pl new <name> --stack <stack>` 起。彻底解决"部署太麻烦"。
>
> 🔧 **2026-04-24 v1.9.1 · curl|bash + 已有项目接入加固**：修 `BASH_SOURCE[0] unbound`
> stdin 场景；`pl new --here` 现在 100% 不覆盖你已有的代码 / .gitignore / README / .git；
> README 加"已有项目接入"+"多版本并存（direnv）"段。

---

## [1.9.1] — 2026-04-24 · curl|bash 兼容 + `pl new --here` 安全化 🔧

### 背景

用户实测 `curl -fsSL .../install.sh | bash` 时报 `BASH_SOURCE[0]: unbound variable`
（虽然安装实际成功），同时疑问"已有 git 项目怎么接入"和"装到根目录会不会冲突"。
本版修第一个 bug，加固第二个流程，文档化第三个心智模型。

### 修复

**1. install.sh 在 `curl|bash` (stdin) 场景下的 unbound variable**

   `BASH_SOURCE[0]` 在脚本来自 stdin 时不存在，被 `set -u` 捕获。
   修复方式：用 `${BASH_SOURCE[0]:-}` 防御 + 仅当 SELF_DIR 存在时才检测 LOCAL_MODE。
   同时 `RC_FILE` 在 `PL_INSTALL_NO_RC=1` 时未定义的引用也修了。

**2. `pl new --here` 在已有项目上的破坏性覆盖**

   修复前：`cat > .gitignore` 直接覆盖；`tar xf -` 直接解包覆盖；`cp` 不检查目标存在性。
   用户已有 `.gitignore` / `README.md` / `package.json` 都会被静默吞掉。

   修复后引入三道安全闸：
   - `ensure_gitignore()`：已有 `.gitignore` → append 缺失的 pl 规则（带 `# >>> pl-pipeline >>>` marker）；
     不重写、不去重你的规则
   - `safe_cp()`：目标已存在 → 跳过 + log "保留不覆盖"
   - `prepare_from_example()`：tar 改用 `--keep-old-files` (GNU) / `-k` (BSD) 兼容方式
   - `--here` + 已有 `.git` → 自动 `NO_GIT=true`，绝不重 init
   - `--here` + 非 bare stack → 主动 warn 提示用户用 `--stack bare` 减少副作用

### 新增

**README "已有项目接入" 段**

```bash
cd /your/existing/project
pl new whatever --here --stack bare        # 零侵入装 pl 接入层
pl new whatever --here --stack nextjs      # + 装 nextjs adapter
```

**README "多版本并存" 段**

讲清楚 `PL_HOME` 是工具家、`PL_PROJECT` 是项目家的心智模型。
默认 `~/.pl-pipeline` 一份就够；如需项目锁版本，用 `PL_INSTALL_PREFIX` + direnv。

**测试新增 7 个 case**

`tests/cli/test-pl-new.sh` 从 38 → 45：
- Suite 5: --here 不覆盖已有 .gitignore / README.md / src/ / .git
- Suite 5: --here --stack nextjs 不覆盖已有 package.json (safe_cp)
- Suite 6: install.sh 通过 stdin 跑不应有 unbound variable

### 影响

- **零 breaking** — 所有原有用法行为不变
- **`pl new --here` 现在可放心地用在你任何已有 git 项目上**
- **CI 11 个 job 仍 100% 绿**（pl-new-smoke 从 38 → 45 case）

---

## [1.9.0] — 2026-04-24 · zero-friction 上手：install.sh + `pl new` 🚀

### 背景

用户反馈："这样部署太麻烦了，难道没有 npm install 或者脚本？"

之前接入 pl-pipeline 要 8 步：
```
git clone + git checkout + export PL_HOME + export PATH + 改 shell rc +
mkdir pl/changes + cp config + adapter install + git init + pl init
```

跟"30 秒上手"的承诺脱节。本版彻底解决：**装工具 1 条命令 + 起项目 1 条命令**。

### 新增

**1. `install.sh`（一键安装器）**

   - 支持 `curl | bash` 和 `wget | bash` 两种姿势
   - 也支持本地 `git clone + bash install.sh`
   - 自动检测依赖（bash / python3 / git / jq）
   - 自动 clone 到 `~/.pl-pipeline`（可由 `PL_INSTALL_PREFIX` 覆盖）
   - 切到最新 stable tag (`pl-v*`)
   - 幂等写入 shell rc：zsh / bash / fish / sh 都支持
   - 多次执行自动 git pull 升级
   - 选项：`PL_INSTALL_NO_RC` / `PL_INSTALL_FORCE` / `PL_INSTALL_QUIET` / `PL_INSTALL_REF`
   - LOCAL_MODE：从仓库内执行时自动识别，不重复 clone

**2. `pl new <name> --stack <stack>`（项目初始化器）**

   一条命令完成原本 6 步：mkdir + cp config + 装 adapter + git init + pl init + 写 README/.gitignore

   5 个 stack 开箱可用：
   - `bare` — 任意栈，仅 pl-core 骨架（无 adapter）
   - `nextjs` — 单 Next.js + adapter-nextjs-web 完整资产
   - `fastapi` — 单 FastAPI + adapter-python-fastapi 完整资产
   - `crawler` — 爬虫，无 adapter，自定义 `pl/adapters/build.yaml`
   - `monorepo-trio` — 前端 + 服务端 + 爬虫一次到位（基于 demo-monorepo-trio）

   选项：`--here` / `--no-git` / `--no-init` / `--first-change <id>` / `--force`

**3. CI 新 job：`pl-new-smoke`**

   `tests/cli/test-pl-new.sh` 38 个测试覆盖：
   - install.sh 语法 + LOCAL_MODE 检测
   - 5 个 stack × 真起项目 × 各 5-6 项断言（adapter 装上 / change 起来 / build.yaml 在位）
   - `--no-git` / `--no-init` / `--first-change` / `--force` 行为正确
   - 已存在目录无 `--force` 应拒绝

### 体验对比

**Before (v1.8.x)**：
```bash
git clone https://github.com/walkertop/pl-pipeline-standalone
cd pl-pipeline-standalone
git checkout pl-v1.8.4
export PL_HOME="$PWD"
export PATH="$PL_HOME/bin:$PATH"
echo 'export PL_HOME=...' >> ~/.zshrc
echo 'export PATH=...' >> ~/.zshrc
cd /path/to/your-project
mkdir -p pl/changes
cp $PL_HOME/assets/pl/config.default.yaml pl/config.yaml
export PL_PROJECT="$PWD"
pl adapter install $PL_HOME/adapters/adapter-nextjs-web .
git init
pl init add-user-login --name "添加用户登录" --domain auth
```

**After (v1.9.0)**：
```bash
curl -fsSL https://raw.githubusercontent.com/walkertop/pl-pipeline-standalone/main/install.sh | bash
source ~/.zshrc
pl new my-app --stack nextjs
```

**8 步 → 2 步，零 export，零 cp，零改 shell rc**。

### 修复

- `pl new` 处理绝对路径名（如 `pl new /tmp/foo` 之前会拼成 `$PWD/tmp/foo`）
- `pl-new-project.sh` 中所有 `$VAR` 紧贴中文的位置改用 `${VAR}`，避免 bash 3.2 `set -u` unbound 误判（macOS 默认 bash 3.2.57 的老问题）

### 影响

- **零 breaking** — 老的"手动 cp config + adapter install"流程 100% 仍可用
- **零新依赖** — install.sh 只用 bash/git/python3/jq，pl new 只用 bash + 已有脚本
- **README "30 秒上手" 完全重写**，从 8 步代码块缩成 3 个清晰子步骤
- **monorepo-quickstart.md** 同步更新，`pl new --stack monorepo-trio` 取代手工 mkdir 路径

### 升级路径

无 breaking。直接拉 `pl-v1.9.0` 或重新跑 install.sh 自动升级。

---

## [1.8.4] — 2026-04-24 · Monorepo Quickstart + demo-trio 🏗️

### 背景

用户反馈："准备把 pl-pipeline 用在一个全新仓库，里面有前端、Python 服务端、爬虫三个模块，
怎么接？爬虫没专属 adapter 是不是必须新写一个？"

这个问题其实是一类问题：**多模块 monorepo 接入策略 + 无 adapter 模块怎么办**，
v1.8.x 之前的文档只默认"一个项目一个 adapter"，没有显式覆盖。

### 新增

**1. `docs/guides/monorepo-quickstart.md`（10 节完整指南）**

   - 心智模型：`PL_PROJECT` 不必是 git 根，可以是子目录 → monorepo 自然支持 N 个独立宿主
   - 推荐目录结构（frontend / api / crawler 三模块平级 + pl-pipeline 工具独立 clone）
   - 一次性准备（`PL_HOME` + `PATH` + `pl doctor`）
   - 三个模块分别接入：nextjs adapter / fastapi adapter / **裸 pl-core + 自定义 build.yaml**
   - 日常工作流：用 `direnv` 自动切 `PL_PROJECT`
   - 跨模块协作 change 三种策略（推荐每模块各起 + 命名呼应）
   - CDC 在 monorepo 下的姿势（每模块独立 aggregate/verify/dashboard）
   - CI 接入示例（每模块一个 job + paths filter 省配额）
   - FAQ 5 条 + 心智清单 8 条

**2. `examples/demo-monorepo-trio/`（可 cp 走改的可跑骨架）**

   - `frontend/` — Next.js 模块，含 demo `.pl-adapter.yaml` 占位
   - `api/` — FastAPI 模块，含 demo `.pl-adapter.yaml` 占位
   - `crawler/` — 爬虫模块，**无 adapter**，自带 `pl/adapters/build.yaml`
   - 每个模块都已经真跑过 `pl init add-demo-feature`，`.state.md` 在位
   - `README.md` 给出"复用步骤"：cp → 删 demo change → 真实 install → 起自己的 change

**3. README.md 更新**

   - "已有 Adapter" 段加"未单列 adapter 怎么办"段：明确裸 pl-core + 手动 cherry-pick 通用 rule 的姿势
   - 30 秒上手段顶部加"多模块项目？"分叉提示，导向 quickstart
   - 快速链接段加 monorepo quickstart 入口

### 核心澄清

| 老想法 | v1.8.4 后正确认知 |
|---|---|
| "monorepo 只能装 1 个 adapter" | 每模块独立 `PL_PROJECT`，各装各的 |
| "没 adapter 就用不了 pl-pipeline" | 裸 pl-core 完全能用，gate 自动 skip |
| "爬虫得新写 adapter" | 不必。手动 cherry-pick `python-typing-strict.md` 等通用 rule 即可 |
| "跨模块需求要塞一个 change" | 推荐每模块各起一个，spec.md 互引 |

### 影响

- **零代码改动** —— 纯文档 + example，本质是把 v1.8.x 已经具备但没说清的能力沉淀出来
- **不扩 adapter 生态** —— 严格遵守"先把当前做扎实"的策略，不引入 crawler/Go adapter
- **example 可跑可改** —— `pl init` / `pl status` 在三模块上都真实跑通过

### 升级路径

无 breaking。直接拉 `pl-v1.8.4`。

> 至此 v1.8.x 系列正式完整：v1.8.0 统一 CLI → v1.8.1 文档真实化 → v1.8.2 自吃狗粮 →
> v1.8.3 测试扎实 → v1.8.4 多模块接入心智补齐。

---

## [1.8.3] — 2026-04-24 · 测试扎实 ✅

### 背景

v1.8.0 - v1.8.2 把 CLI 收口 + 自吃狗粮做完了，但有一个尴尬现实：
- `bin/pl` 没有任何单元测试，改一行可能就坏
- CI 的 `cdc-broker-smoke` 跑的是手写 8 行最小 yaml，没覆盖 demo 真实场景
- v1.7 → v1.8 升级 + agent prompt 改动如果回归，CI 抓不到

本里程碑给所有"v1.8 已经做了的事"上测试守，让 v1.8.x 系列收官时是真的扎实。

### 新增测试

**`tests/_lib/runner.sh`** — 极简 shell 测试 runner（不引外部依赖，遵守 pl-pipeline 内核约束）
- `tc_case` / `tc_ok` / `tc_fail` / `tc_skip`
- `tc_assert_pass` / `tc_assert_exit <rc>` / `tc_assert_contains <s>` / `tc_assert_not_contains <s>`
- 彩色输出（自动降级 CI 无 TTY 场景）
- 末尾 summary + 列出所有 failed cases

**`tests/cli/test-pl.sh`** — 29 个 case，5 个 suite：

| Suite | Cases | 覆盖 |
|---|---|---|
| meta-commands | 7 | `--version` / `version` / `env` / `help` / `--help` / 无参 / `doctor` |
| error-handling | 10 | unknown subcmd → exit 2、namespace 缺 verb → exit 2、bash 3.2 unbound 兼容 |
| namespace-routing | 5 | `pl contract verify\|aggregate\|query --help` 路由可达；`pl status --self-check` |
| top-level-mappings | 5 | `pl run\|smoke\|phase\|orchestrator\|status` 路由可达 |
| argv-passthrough | 2 | argv 完整传到底层脚本，缺参时由底层脚本报错 |

特别守住 v1.8.0 修过的 bash 3.2 + set -u 多字节字符（`${cmd}（...）`）兼容。

**`tests/cli/test-cdc-real.sh`** — 3 个 case，3 个 suite：

| Suite | Cases | 覆盖 |
|---|---|---|
| demo-nextjs-todo | 1 | trace use → aggregate → verify → query 全闭环 |
| demo-fastapi-users | 1 | 同上（验证不是 nextjs 孤例） |
| dashboard endpoint | 1 | dashboard-server.py 真起 → curl `/_data/contracts.json` → 含真实 pact |

复制 demo 到 sandbox 跑，不污染 repo。

### CI 新增 jobs

`.github/workflows/ci.yml` 加两个 job：

- **`cli-smoke`** — `runs-on: ubuntu-latest` → `bash tests/cli/test-pl.sh`
- **`cdc-real-scenarios`** — `runs-on: ubuntu-latest` + py setup → `bash tests/cli/test-cdc-real.sh`

老的 `cdc-broker-smoke`（手写最小 yaml）保留作快速冒烟，
`cdc-real-scenarios`（真实 demo）作回归保险。两条互补。

### 不动的部分

- 原有 8 个 CI job 全部保留
- pl-status.sh / dashboard-server.py 等核心脚本逻辑零改动

### 验证

本地全套：32/32 pass。
CI：`cli-smoke` + `cdc-real-scenarios` 加入后 push，等绿打 tag。

### v1.8.x 收官

至此 v1.8.x 系列工作完成：

| 版本 | 主题 | 内容 |
|---|---|---|
| v1.8.0 | 统一 CLI 收口 | bin/pl 一个入口替代 34 个脚本 |
| v1.8.1 | 文档真实化 | 删 6 个死链、删 v2.0 画饼、修 dirs[@] bug |
| v1.8.2 | 自吃狗粮 | agent / docs / CI 全切到 pl CLI（19 文件） |
| v1.8.3 | 测试扎实 | 32 个测试 + 2 个 CI job 守 v1.8.x |

下一步方向（未承诺时间，看 issue）：v1.9 / v2.0 路线。

---

## [1.8.2] — 2026-04-24 · 自吃狗粮：全面切到 pl CLI 🍴

### 背景

v1.8.0 收口 CLI 后存在严重的"使用一致性债"：
agent prompt 还在告诉 agent 用 `bash $PL_HOME/scripts/...`、各 README 一直写老路径、
CI workflow 也是 `bash scripts/...`。CLI 摆在那里却没人用 = 摆设。

本里程碑全面把"应该改"的地方切到新 CLI，让 v1.8 真正成为 first-class citizen。

### 改动范围（19 个文件，120/89 行）

**Agent prompt（让 agent 用新 CLI）**
- `assets/pl/agents/pipeline-master.md` 9 处 → `pl run` / `pl smoke` / `pl trace use` / `pl contract aggregate|verify|query` / `pl status`
- `assets/pl/rules/acceptance-criteria.md` → `pl rule-scan`
- `assets/pl/rules/build-verification.md` → `pl run --check build` / `pl should-build`
- `assets/adapter-sdk/docs/adapter-authoring-guide.md` → `pl adapter create`

**用户文档**
- `docs/dashboard-guide.md` 8 处 → `pl dashboard ...`（含 30 秒上手 / 三种姿势 / FAQ / 调试）
- `docs/guides/adapter-authoring.md` 6 处 → `pl adapter install/validate` / `pl contract aggregate|verify|query`
- `dashboard/README.md` 2 处 → `pl dashboard ...`
- `dashboard/index.html` empty state → `pl observe --change`
- `FAQ.md` 3 处 → `pl adapter install/create`
- `MVP_STATUS.md` 6 处 → 全部 pl + 推荐 PATH 方式
- `MIGRATION.md` 头部加 v1.8+ note，指向 `docs/cli-reference.md`（保留历史快照不全改）

**Adapter 文档**
- `adapters/adapter-nextjs-web/{README.md,docs/case-study.md}`
- `adapters/adapter-python-fastapi/{README.md,docs/case-study.md}`
- `adapters/adapter-kotlin/README.md`
- 全部 → `pl adapter install/validate`

**CI workflow（让 CI 用新 CLI 验证 CLI 自己）**
- `.github/workflows/ci.yml` 17 处 `bash scripts/...` → `pl <subcmd>`
- 每个 step 头部加 `export PATH="$PWD/bin:$PATH"`
- 包括：pl-core self-check / adapter validate&install&create / CDC scenario 1-4

**脚本输出**
- `scripts/adapter-create.sh` 生成的 README 模板 + "Next steps" 输出 5 处全切
- `scripts/trace-adapter-use.sh` 注释里的 usage 示例

### 不动的部分

- `CHANGELOG.md` / `README.md`：合法引用"老路径仍兼容"
- `docs/retros/*` / `docs/milestones/*` / `docs/migration/v1.4-to-v1.5.md`：历史快照
- `docs/cli-reference.md`：在讲 CLI 与脚本等价性，必须出现两种形式
- `assets/pl/config.default.yaml` 引用不存在的 `check-spec-complete.sh` / `check-taskdag.sh`：
  另一个长期债（脚本本身缺失），不在本里程碑范围

### 验证

本地预演了全部 CI scenario：
- pl status / pl adapter validate / pl adapter create
- CDC scenario 1（happy path：trace use → aggregate → verify → satisfied）
- Scenario 4（criteria-only ARCHIVE 自动 aggregate）
全部绿。

---

## [1.8.1] — 2026-04-24 · 文档真实化 + 旧 bug 📑

### 背景

v1.8.0 收口 CLI 后扫了一遍现实债，发现：
- README 6 个死链（pl-pipeline.dev / discord / twitter / your-org Roadmap）
- README 大段 v1.2 / "alpha 阶段" 文字（停在 2 个月前）
- v2.0 愿景段还在画饼（Smart init / pl proposal/plan/...）
- `pl-status.sh` 一个 bash 3.2 set -u 下的旧 bug 1.6+ 一直没修

本版做"扎实化里程碑 1"：把这些丢分项一次清掉。

### 修复

- README 6 处死链全部删除，替换成 repo 内真实文档：
  - `pl-pipeline.dev` → `./docs/cli-reference.md`
  - `discord.gg/pl-pipeline` / `twitter.com/pl_pipeline` → 删除
  - `github.com/your-org/pl-pipeline/projects` → `github.com/walkertop/pl-pipeline-standalone/issues`
- 重写 v2.0 愿景段 → "v1.9+ 路线（未承诺）"，明确说"未承诺时间，社区 issue 排"
- "🚧 v2.0 规划" 的 Smart Init / 多 IDE 适配两段全部删除（再不画饼）
- "alpha 阶段" → "stable, 自吃狗粮中"
- 现状段全面重写，反映 v1.5 → v1.7 → v1.8 真实进度（CDC 双向闭环 / 统一 CLI / CI 全绿纪律）
- adapter 列表加上 Kotlin KMM（之前漏列）+ 注明 Next/FastAPI 已经过完整 CDC dogfood
- `scripts/pl-status.sh: dirs[@]: unbound variable` 修复
  - 原因：bash 3.2 + `set -u` 下 `local dirs=()` 空数组扩展 `"${dirs[@]}"` 触发
  - 修复：在 for 之前 `[[ ${#dirs[@]} -eq 0 ]] && return 0`
  - 验证：`bash scripts/pl-status.sh` 不再报 warning；`--self-check` 仍 OK

### 文件变更

| 文件 | 变更类型 |
|---|---|
| `README.md` | 修订 5 段（badge / 四件门禁 / CDC 闭环 / Smart Init 段删除 / 快速链接 / 现状） |
| `scripts/pl-status.sh` | bug 修复（4 行） |
| `VERSION` | `1.8.0` → `1.8.1` |
| `CHANGELOG.md` | 加 v1.8.1 段 |

### 已知边界

- `pl-status.sh` 输出里仍有 `/pl:proposal <change-id>` 旧词（另一处文档欺诈），
  留待 v1.8.2 全面切 pl CLI 时一并扫掉。
- README 历史叙事保留 v1.2 / v1.5 / v1.7 节点（"v1.2 起稳定" / "v1.5 起就位"等），
  这是合法的版本谱系，不算债。

---

## [1.8.0] — 2026-04-24 · 统一 CLI 收口 🛠

### 背景

到 v1.7.3 为止，scripts/ 已经有 **34 个独立 .sh 脚本**（`pl-*` 24 个，`piao-*` 6 个，`adapter-*` 3 个，`trace-*` 3 个，其它 8 个）。
README 顶部一直写 `pl proposal` / `pl plan` / `pl report` 风格用法，但**这些命令根本不存在**——
新用户照 README 试一下 `pl proposal` 就拿到 `command not found`，心智断崖。
v1.8 做"thin wrapper 收口"：dispatcher 0 业务逻辑，纯路由。

### 新增

- `bin/pl` — 统一 CLI dispatcher
  - 顶层命令：`init / status / run / phase / orchestrator / smoke / dashboard / observe / active-time / retro-mine / rule-scan / migrate-legacy / should-build / setup-hooks / log-error`
  - 命名空间：`pl contract <verb>` / `pl trace <verb>` / `pl adapter <verb>` / `pl piao <verb>` / `pl dashboard [refresh]` / `pl observe [check]`
  - 元命令：`pl --version` / `pl env` / `pl doctor` / `pl help [<sub>]`
  - 所有 flag 透传给底层脚本 → `pl run --change foo --gate D --json` ≡ `bash scripts/pl-runner.sh --change foo --gate D --json`
  - 退出码透传；未知子命令 → exit 2 + 友好提示
  - macOS bash 3.2 兼容（已修一处 set -u 下中文标点贪婪解析的坑：`$cmd（...)` → `${cmd}（...)`）
- `pl doctor` 自检：PATH / python3 / jq / yq / `$PL_HOME` / `$PL_PROJECT/pl/changes`
- `docs/cli-reference.md` — 完整子命令 → 底层脚本对照表 + 设计约定 + 食谱

### 修复（文档欺诈）

- README 顶部 badge: `v1.2.0 → v1.8.0`
- 痛点表里的伪命令 `pl proposal` / `pl plan` 改成真实存在的 `pl init <id>` / `pl run --gate B1`
- "30 秒上手" 整段改成 `pl <subcmd>` 风格，加 `export PATH="$PL_HOME/bin:$PATH"` + `pl doctor`
- `pl report` → `pl trace report --page <id>`（前者一直是空话）
- v2.0 愿景段加注释，明确哪些是已实现、哪些是 v2.0 规划

### 验证

```
================ pl --version ================
pl-pipeline 1.8.0
  PL_HOME = /.../pl-pipeline-standalone

================ pl doctor ================
[路径]    PL_HOME / PATH 包含 $PL_HOME/bin    OK
[依赖]    bash python3 jq                       OK
[版本]    pl-pipeline = 1.8.0
✓ doctor: 关键项全部通过

================ 错误处理 ================
$ pl bogus
pl: 未知子命令: bogus（用 'pl help' 看清单）
exit=2

$ pl contract bogus
pl: 未知 contract verb: bogus（aggregate|verify|query）
exit=2

================ 透传 ================
$ pl status --json | head -3
{ "schema_version": "pl-status-v1", ... }
exit=0

$ pl contract verify --help | head -3
pl-contract-verify.sh — 拿 consumer pacts 对账当前 adapter.yaml ...
exit=0
```

### 文件变更

| 文件 | 变更类型 |
|---|---|
| `bin/pl` | 新增（dispatcher，280 行） |
| `docs/cli-reference.md` | 新增（完整 CLI 文档） |
| `README.md` | 修订 6 处（badge / 痛点表 / 30 秒上手 / v2.0 段 / pl report / adapter 段） |
| `VERSION` | `1.5.0` → `1.8.0`（顺手修正历史漏更新：v1.6/v1.7 都没改过 VERSION） |
| `CHANGELOG.md` | 加 v1.8.0 段 |

### 已知边界

- dispatcher **不为伪命令兜底**：`pl proposal` 仍然报"未知子命令"，因为当前没有对应脚本。
  这是有意为之，避免造"假装能用"的入口。等 v2.0 阶段语义糖落地再说。
- VERSION 文件一直停在 `1.5.0` 直到 v1.8 才同步，是一个长期债。
  本次顺手修，后续 `pl-pipeline-master` agent 应把"打 tag 必同时改 VERSION"也纳入纪律。
- `pl-status.sh` 在某些路径有 `dirs[@]: unbound variable` 旧 bug（与 dispatcher 无关），
  不在本次范围；后续单独 patch。

### 向后兼容

100%。`bash $PL_HOME/scripts/<x>.sh ...` 全部继续工作。
CI、agent prompt、第三方集成无须立刻迁移。

---

## [1.7.3] — 2026-04-24 · CDC drill-down 🔎

**主题**：v1.7.2 让契约健康度首页可见，但角标只回答 "红 or 绿"——红的时候用户还是要
回到 CLI 跑 `pl-contract-verify.sh` 看具体哪条 violation。v1.7.3 让点击直接到详情、
显示完整 reason 和文件路径，把"看到问题"和"开始修"之间的步骤压到接近零。

### 🆕 新增

- **Dashboard server 新端点 `GET /_data/contract-detail.json?change=<id>`**
  （`scripts/_lib/dashboard-server.py`）
  - 内部 shell out 到 `pl-contract-verify.sh --change <id> --json`，**完整 report 不削减**
  - 给每条 violation/warning/satisfied 补 `source_path`：根据 kind 解析到
    `adapters/<dir>/skills|rules|agents|templates/<id>.{md,yaml,yml}` 或 `adapter.yaml`
  - adapter 目录映射（`metadata.id` → 目录路径）30s 缓存，单次扫描；不依赖 PyYAML
  - per-change 3s TTL 缓存
  - 非阻塞失败：跟 `/_data/contracts.json` 一致的 graceful degradation
- **change 详情页 Contract 卡片**（`dashboard/change.html`）
  - 显示 status badge / adapter@version / 计数（broken · warn · satisfied）
  - "Broken" / "Warnings" 表格：每行 kind + id + 完整 reason + `📋 copy path` 按钮
  - "Satisfied" 默认折叠（避免淹没违规），点击展开
  - 顶部 `📋 copy adapter.yaml path` 按钮
  - 复制实现：navigator.clipboard 优先 → execCommand 兜底 → "✗ copy failed" 兜底反馈
  - URL `#contract` anchor 自动滚动定位
- **首页角标可点跳转**（`dashboard/index.html`）
  - `pact ✓ / ! N / ✗ N` 角标变为 button，点击 stopPropagation + preventDefault
    → 跳到 `change.html?id=<id>#contract`
  - 卡片整体仍跳到 timeline，行为不冲突

### 🛠 改进

- 文档：`docs/dashboard-guide.md` 新增 "Contract 下钻 — 看 violation 详情（v1.7.3+）"
  小节，含完整 ASCII 图示、kind→source_path 映射表、graceful degradation 说明
- 技术对照表：新增 v1.7.3 行

### ✅ 验证

- ✅ Next.js demo `add-todo-list` (satisfied)：14/0/0，全部 source_path 正确解析
- ✅ Next.js demo `add-todo-list` 人为破坏（删 react-server-components skill + react-hooks rule）：
  status=broken, summary=2/0/12，violations 表显示完整 reason
- ✅ FastAPI demo `add-users-api` (satisfied)：14/0/0，python-fastapi 适配器路径解析正常
- ✅ 边界：`?change=does-not-exist` → `available:false, reason:"no pact for change ..."`
- ✅ 边界：缺 `?change` 参数 → HTTP 400
- ✅ 跨 adapter 目录命名（`adapter-nextjs-web` 目录 + `metadata.id: nextjs-web`）正确解析

### 📁 文件变更

```
M scripts/_lib/dashboard-server.py    (+~200 行：新端点 + adapter dir scan + source_path)
M dashboard/change.html               (+~210 行：Contract section + copy logic)
M dashboard/index.html                (badge 改 button + onclick drill-down)
M docs/dashboard-guide.md             (+~70 行新章节)
M CHANGELOG.md                        (本条)
```

### 🚧 已知边界

- `clipboard.writeText` 在没有 https 或 document 没 focus 时会拒（headless 测试就遇到了）；
  已加 execCommand fallback + "✗ copy failed" 反馈，不会卡死按钮
- adapter `metadata.id` 解析用的是行扫描（避免 PyYAML 依赖），如果 yaml 把 metadata
  写成 inline `metadata: {id: foo}` 会解析失败 → fallback 到目录名（仍能工作，只是
  显示的 adapter 名可能跟项目惯例不一致）

---

## [1.7.2] — 2026-04-24 · CDC 进 Dashboard 📺

**主题**：v1.7.0/v1.7.1 让 pact 写入、对账、读出，但状态仍只在 CLI 里。
v1.7.2 把它接到 dashboard 上——每天看 dashboard 的人，再不需要主动跑 verify
就能看到「我这条 change 的契约健不健康」。

### 🆕 新增

- **Dashboard server 新端点 `GET /_data/contracts.json`**
  （`scripts/_lib/dashboard-server.py`）
  - 内部 shell out 到 `pl-contract-verify.sh --json`，削减成「卡片角标够用」的形态：
    `{ status, adapter, adapter_version, broken_count, warn_count, broken_examples[≤3], warn_examples[≤3] }`
  - **3 秒 TTL 缓存**，避免每帧 fetch 都跑 yaml 解析
  - 非阻塞失败：`pl-home/pl-project` 缺失、contracts dir 不存在、verify 超时 / 报错 → 返回
    `{ available: false, reason: "..." }` 合法 JSON，前端识别后直接不渲染角标
- **首页卡片角标**（`dashboard/index.html`）
  - `pact ✓ / pact ! N / pact ✗ N` 三态，复用现有 `badge-green/yellow/red`，零 CSS 新增
  - tooltip（`title=`）列出前 3 条 `kind/id` + adapter@version
  - 顶部一行 `CDC contracts ✓ N satisfied · ! M warn · ✗ K broken across X changes` 汇总
- **自动刷新**：收到 `_events/index updated` 推送时自动重 fetch contracts.json，
  ARCHIVE 触发 auto-aggregate 后角标在几秒内跳转
- **`scripts/pl-dashboard.sh`** 把 `--pl-home / --pl-project / --contracts-dir` 透传给 server
- **文档**：`docs/dashboard-guide.md` 新增「Contract 角标」一节 + 技术对照表加一行

### 🎯 设计特征

- **零侵入**：现有 dashboard 任何视图都不变；contracts dir 不存在的老 project 不会因此报错
- **零 CSS 新增**：复用 v1.3 已有 `badge-{green,yellow,red}`，一致的暗/亮色适配
- **架构上仍然是 server-side verify**：浏览器里不解析 yaml，避免把 PyYAML 模拟打包进前端
- **跟 SSE 解耦**：contracts 走普通 JSON + 节流，不走 EventSource，逻辑简单可缓存

### 🧪 验证

5 个本地 scenario，全部通过：
1. nextjs demo 启动 → 端点返回 `add-todo-list satisfied (nextjs-web@0.1.0)`，浏览器卡片显示 `pact ✓`
2. fastapi demo 启动 → 端点返回 `add-users-api satisfied (python-fastapi@0.1.0)`，行为一致
3. 删除 `react-server-components` skill → 4 秒后端点跳到 `broken=1`，浏览器卡片切到 `pact ✗ 1`
4. 恢复 adapter → 4 秒后切回 `satisfied`，浏览器卡片切回 `pact ✓`
5. 不传 `--pl-home/--contracts-dir` 启动 → 端点 `available:false, reason: "dashboard server 没拿到 --pl-home / --pl-project"`，浏览器无角标无报错

均使用真实 dashboard server（不是 mock）+ 真实 demo project + Chrome 渲染。

### 📦 兼容性

- ✅ 0 breaking changes
- ✅ 旧 dashboard 用法（`pl-dashboard.sh` 不传 contracts 参数）继续可用
- ✅ pact / registry / adapter.yaml schema 全部未变
- ✅ `--static-only` 模式仍工作，只是没有 contract 角标（端点不存在，前端兜底）

---

## [1.7.1] — 2026-04-24 · CDC 读侧 🔍

**主题**：v1.7.0 解决了"写 pact"和"对账 pact"，但缺了"读 pact"。
v1.7.1 补一个纯查询工具，闭合「决策前的事实陈述」环节。

### 🆕 新增

- **`scripts/pl-contract-query.sh`**：5 种查询模式
  - 全局汇总（无参）—— 一眼看清本 project 有几份 pact、跨几个 adapter
  - `--capability/--skill/--rule/--build-command/--agent <id>` —— 反查谁在用
  - `--adapter <id>` —— 列某 adapter 的全部 consumer 与资产消费
  - `--change <id>` —— 单 change 的友好版 pact 视图
  - `--json` —— 任何模式都可结构化输出（CI / 脚本组合用）
  - 可选 `--adapter <id>` 过滤具体资产查询的范围
- **文档**：`docs/guides/adapter-authoring.md` § 12.5 加 5 个查询模式 + 与 verify 的边界
- **agent 引导**：`assets/pl/agents/pipeline-master.md` broker 工作流表加一行 query

### 🎯 设计特征

- **纯读，不触发任何 verify 行为**：query 永远不报 broken/warn，它的价值在「事实陈述」
- **零依赖扩展**：只读 `$PL_PROJECT/pl/contracts/{*.consumed.yaml,_registry.yaml}`，
  不需要再读 adapter.yaml；对未生成 pact 的 project 友好退出
- **跨 project 反查留给 v1.8**：当下做法是各 consumer project 自己跑 query，结果汇 release notes

### 🧪 验证

11 个本地 test scenario：单 demo 5 种模式 + 多 pact 聚合 + 不存在 capability + JSON 输出 + 缺 contracts dir，全过。
两个真实 demo（nextjs / fastapi）的 query 输出与各自 `_registry.yaml` 内容互相印证。

### 📦 兼容性

- ✅ 0 breaking changes（纯新增脚本 + 文档）
- ✅ pact / registry / adapter.yaml schema 全部未变
- ✅ 老 project 无需任何调整即可用 query

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
