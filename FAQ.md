# FAQ

> 常见问题。问不到你想要的，去 [GitHub Discussions](https://github.com/walkertop/pl-pipeline-standalone/discussions)。

---

## 概念

### Q: pl-pipeline 和 Cursor / Claude Code / Codex 什么关系？

**pl-pipeline 是给 AI IDE 的"操作系统"**。

- Cursor / Claude Code / Codex 是**发动机**（做代码生成）
- pl-pipeline 是**变速箱 + ABS + 行车记录仪**（管流程、门禁、产物、可审计性）

三者正交、互补。你可以在同一个项目里同时用 pl-pipeline 和任意 AI IDE。

### Q: pl-pipeline 和 spec-kit / OpenSpec 什么区别？

- **spec-kit** / **OpenSpec**：聚焦 "Spec 管理"（PRD → 可机械消费的规格）
- **pl-pipeline**：聚焦 **全流水线**（Spec → Plan → TaskDAG → Code → Verify → Archive），Spec 只是其中第 1 步

另外：
- pl-pipeline 有**门禁**（机器可校验的通过判据）
- pl-pipeline 有**adapter 体系**（把某技术栈的最佳实践打包）
- pl-pipeline 有**可恢复**（断点续跑靠 `.state.md`）

### Q: 三层架构（piao / pl-core / adapters）是必须的吗？

**不是**。

- **最少**：只用 pl-core（8 个模板 + 5 个 schema + 3 个脚本）即可开始
- **推荐**：+ 一个 adapter（有 agents/skills/rules 加持）
- **高阶**：+ 启用 piao_emit（跨 change / 跨 adapter 的语义追溯）

`piao_emit` 默认关闭，单人 / 单项目场景完全用不到。

---

## 接入

### Q: 怎么开始？

见 [README §30秒上手](./README.md) 或 [`MVP_STATUS.md`](./MVP_STATUS.md)。

三步：

```bash
export PL_HOME=/path/to/pl-pipeline-standalone
export PATH="$PL_HOME/bin:$PATH"     # 启用 pl CLI
cd your-project
pl adapter install $PL_HOME/adapters/adapter-nextjs-web .
```

### Q: 我的技术栈没有现成 adapter 怎么办？

```bash
pl adapter create my-stack --full
# 按 assets/adapter-sdk/docs/adapter-authoring-guide.md 填内容
# 有时间请 PR 回来 ❤️
```

### Q: 必须用 CodeBuddy 吗？

**不必须**。当前 `ide-integrations/` 只有 `codebuddy/`，但 `pl/` 下的所有
产物都是**普通 Markdown + YAML**，任何 IDE / AI 都能消费：

- Cursor：把 `.codebuddy/agents/*.md` 复制到 `.cursor/rules/`
- Claude Code：复制到 `.claude/commands/`
- 纯命令行：所有脚本都能单独跑

v0.3 计划提供 MCP 服务器，届时"任意 MCP 兼容 IDE" 都能一等公民接入。

### Q: 装了 adapter 之后，宿主项目多出来一堆文件会影响我的代码吗？

**不会**。Adapter 只注入三类位置：

| 位置 | 内容 | 影响 |
|---|---|---|
| `pl/templates/*.md` | spec/plan/taskdag 模板 | 只在你走流水线时被读 |
| `.codebuddy/{agents,skills,rules}/*.md` | AI 知识库 | 只在 AI 对话时被加载 |
| `scripts/adapter-<id>-*.sh` | 构建/校验/lint | 只在你显式调用时执行 |

所有注入文件都在 `.pl-adapter.yaml` 的 `installed_files` 里有记录；
未来 `pl uninstall-adapter` 可精确清理。

---

## 产物 & 门禁

### Q: 7 件产物必须都写吗？

**必须只有 3 件**：`spec.md` / `plan.md` / `taskdag.md`。

其他按需：
- `api.md`：涉及对外接口 / Server Action 时
- `testmatrix.md`：场景多（>5）需要显式梳理时
- `deps.md`：迁移类 change
- `.state.md`：**自动生成**（由 orchestrator / 手工推进都行），不用手写

### Q: 门禁可以跳过吗？

可以，但**不推荐**。跳过方式：直接编辑 `.state.md` 的 `gate_status: SKIPPED`。

脚本层面 `pl-status.sh --self-check` 会告警但不阻塞。
未来 CI 接入后会把 `SKIPPED` 标红但保留通过权。

### Q: `.state.md` 冲突怎么办？

- **两个 AI 同时改**：不要这样用。`.state.md` 是 single writer。
- **merge 冲突**：人工解决，以 `last_transition` 时间新者为准。
- **想回退**：直接 `git revert` 即可，`.state.md` 就是普通 git 文件。

---

## Adapter

### Q: adapter.yaml 里 `provides.templates` 是覆盖还是合并？

**覆盖**。Adapter 提供的 `spec.md` 会替换 pl-core 默认的那份。

设计依据：adapter 的定位就是"场景化模板"，覆盖是它的主要价值。

### Q: 一个项目能装多个 adapter 吗？

**v0.1 MVP 不支持**。因为 templates 是覆盖关系，多个 adapter 会互相踩。

未来版本会引入：
- `.pl-adapter-stack.yaml`（记录 adapter 栈）
- 模板 "层叠"机制（类似 CSS cascade）

### Q: Adapter 和 Preset / Plugin 什么区别？

都是同一个东西的不同叫法。最终定名 **Adapter**，因为它干的事是"把
pl-pipeline 通用流程**适配**到具体技术栈"。

### Q: Adapter 里的 `build_adapter.commands.compile_check` 有什么用？

它是 pl-core 的 `$PL_BUILD_CHECK_CMD` 环境变量的"数据源"。

安装 adapter 后，你执行：
```bash
export PL_BUILD_CHECK_CMD="$(grep PL_BUILD_CHECK_CMD .pl-adapter.yaml | cut -d\" -f2)"
```
之后 `should-build.sh` / `pipeline-orchestrator.sh` 就会在合适时机自动调用它。

---

## 疑难

### Q: `pl-status.sh` 显示 "UNKNOWN"？

两种可能：
1. `.state.md` 缺失 → 创建 `pl/changes/<id>/.state.md`
2. `.state.md` 里没有 `- stage: <X>` 这一行 → 用 `assets/pl/templates/state.md` 模板补齐

### Q: 宿主 KuiklyPolyCity 还能用老路径的脚本吗？

**能**。本仓独立化不影响宿主。宿主 `scripts/*.sh` 和本仓 `scripts/*.sh`
两套并行，互不冲突。

迁移建议：
- **不急**：宿主继续用自己的脚本
- **想用新特性**：在宿主设 `PL_HOME` 指向独立仓，调用独立仓脚本

### Q: bash 3.2 兼容重要吗？

**重要**。macOS 默认 bash 是 3.2.57（2007 年版本），因为 Apple 转向 zsh
后不再更新 bash。所有 pl-pipeline 脚本必须在 bash 3.2 下能跑：

- ❌ 禁用 `${var,,}` 大小写转换 → 用 `tr '[:upper:]' '[:lower:]'`
- ❌ 禁用 `declare -A` 关联数组 → 用 parallel array 或 `$(...)` 子进程
- ❌ 禁用 `[[ $x =~ $pattern ]]` 带 capture groups → 改用 `sed` / `awk`

### Q: 为什么不用 node / python 写？

**MVP 阶段坚持纯 bash** 的原因：

1. **零安装**：bash 每台机器都有
2. **无锁依赖**：不需要 `node_modules/` / `.venv/`
3. **可读**：脚本小到一眼能看懂
4. **好调试**：`bash -x` 就能追

v0.2 起 CLI 可能用 node / go 重写，但那只是**上层包装**，核心脚本不动。

---

## 哲学

### Q: 为什么叫 "pl-pipeline"？

**pl** = **P**roject-autonomous **L**ifecycle。一条代码层的自治生命线。

原叫 "openspec-extended"，后来发现 OpenSpec 社区重名，且 pl-pipeline 的
范畴（六阶段 + 门禁）已远超 "spec" 单一概念，故改名。

### Q: 为什么这么重视"证据链"？

我们的核心假设：**AI 编码 ≠ AI 自动化，而是 AI 辅助**。辅助的价值在于
人类仍然要做最终决策。决策需要依据，依据需要证据，证据需要可审计的产物。

没有产物和审计，AI 写出的代码**没法被交接**，也就没法大规模应用于生产。

### Q: 这是开源项目吗？会一直免费吗？

是，Apache 2.0。核心永远免费且开源。未来若出企业付费版，也绝不影响核心。

---

> 还有其他问题？→ [提 Issue](https://github.com/walkertop/pl-pipeline-standalone/issues) 或 [Discussion](https://github.com/walkertop/pl-pipeline-standalone/discussions)
