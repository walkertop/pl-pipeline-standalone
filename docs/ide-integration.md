# IDE 集成（pl ide）

> v1.11.0 引入 `pl ide`，v1.12.0 扩展到 4 个 IDE 并打通 adapter 链路。

`pl-pipeline` 把 commands / agents / rules / skills 这四类资产存为 canonical 单源（`pl/` 目录），由 `pl ide sync` 按各 IDE 的约定 fan-out 到对应目录。这样：

- 项目作者只需维护 `pl/`，**不必关心你的同事用什么 IDE**
- 跨 IDE 协作（你用 Cursor、同事用 Claude Code、CI 用 Codex）零摩擦
- 卸载某个 IDE：`pl ide unsync --ide <id>` 一键回滚

## 支持矩阵

| IDE        | commands              | rules                  | agents                | skills      | 注册入口      |
| ---------- | --------------------- | ---------------------- | --------------------- | ----------- | ------------- |
| `cursor`   | `.cursor/commands/pl/`| `.cursor/rules/pl-*.mdc` (frontmatter) | 引用 (`@`) | 引用 (`@`)  | `AGENTS.md`   |
| `codebuddy`| `.codebuddy/commands/pl/` (带 frontmatter) | `.codebuddy/rules/pl-*.md` | `.codebuddy/agents/pl-*.md` | 引用 | `AGENTS.md` |
| `claude`   | `.claude/commands/pl/`| 通过 `CLAUDE.md` 引用  | `.claude/agents/pl-*.md` | 引用 (v1.13 计划目录型) | `CLAUDE.md` |
| `codex`    | 引用 (`@`)            | 引用 (`@`)             | 引用 (`@`)            | 引用 (`@`)  | `AGENTS.md`   |

> 「引用」= 不复制实体文件，只在注册入口（`AGENTS.md` / `CLAUDE.md`）的 pl-managed 段里以 `@pl/<section>/<name>.md` 列出，IDE 用户按需 `@-mention`。

## 常用流程

### 一次性接入（最常用）

```bash
cd your-project/
pl detect              # 看一眼 pl 推荐的接入方式（只读，不写）
pl new --here .        # 或 pl init, 把 pl/ 骨架建出来
pl ide sync            # 自动检测 .cursor / .codebuddy / .claude / .codex 并 fan-out
```

### 装 adapter 后联动 sync

```bash
# v1.12+ 的 adapter-install 会写到 canonical pl/.adapter/{agents,skills,rules}/
# 加上 --ide-sync 一气呵成
bash $PL_HOME/scripts/adapter-install.sh --ide-sync adapter-python-fastapi /path/to/project
```

### 强制覆盖手改文件

`pl ide sync` 默认会保护被用户手改的 IDE 资产（hash 校验失败就跳过）。要强制覆盖：

```bash
pl ide sync --force                # 全部 IDE
pl ide sync --ide cursor --force   # 只刷 cursor
```

### 撤销

```bash
pl ide unsync                      # 删掉所有 pl-managed 文件 + 清理 AGENTS.md/CLAUDE.md 段落
pl ide unsync --ide claude         # 只清 claude
```

## 设计原则

### 1. canonical 单源 + 三层资产栈

`pl ide sync` 按以下优先级解析每类资产的 source：

```
{PL_PROJECT}/pl/<section>/        # 项目层（你手动维护的, 优先级最高）
{PL_PROJECT}/pl/.adapter/<section>/   # adapter-install 注入的（v1.12+）
{PL_HOME}/assets/pl/<section>/    # pl 内置（兜底）
```

> 项目层覆盖 adapter 层覆盖内置。如果 adapter 注入了 `pl/.adapter/agents/foo.md` 而你想覆盖它，把同名文件放到 `pl/agents/foo.md` 即可。

### 2. 命名隔离 + hash 保护 + 分段管理

- **命名隔离**：所有 pl 管理的文件加 `pl-` 前缀（如 `pl-acceptance-criteria.mdc`），与你手写的同名文件错开
- **hash 保护**：每个 managed 文件头部嵌 `<!-- pl-managed: hash=... source=... ide=... -->` 标记，下次 sync 时校验 hash —— 不一致就跳过（说明你改过）
- **分段管理**：每个 IDE 在 `AGENTS.md` / `CLAUDE.md` 拥有独立的 `<!-- >>> pl-pipeline:<id> managed section >>> -->` 段，互不踩踏

### 3. 可逆 + 幂等

- 同一个 `pl ide sync` 跑多少次都不会重复写
- `pl ide unsync` 能完整回滚到接入前的状态（除了你手改过的文件，那些会保留）

## 添加新 IDE

`ide-integrations/<id>/manifest.yaml` 是唯一接口；不需要改 Python 代码。Manifest 完整 schema 见 `ide-integrations/cursor/manifest.yaml` 注释。最小骨架：

```yaml
ide_id: my-ide
display_name: My IDE
detect:
  any_of:
    - .my-ide
sync:
  commands:
    enabled: true
    source: ide-integrations/codebuddy/commands/pl    # 复用 codebuddy 模板
    target: .my-ide/commands/pl
    target_ext: .md
    name_prefix: ""
    strip_frontmatter: true   # 你的 IDE 不识别 frontmatter 就 true
  rules:
    enabled: false
  agents:
    enabled: false
  skills:
    enabled: false
root_agents_md:
  enabled: true
  target_file: AGENTS.md     # 或 MY_IDE.md
  marker_begin: "<!-- >>> pl-pipeline:my-ide managed section >>> -->"
  marker_end: "<!-- <<< pl-pipeline:my-ide managed section <<< -->"
```

写完 `pl ide detect` 就能识别它，`pl ide sync --ide my-ide` 就能跑。

## 故障排查

| 现象                                     | 原因                                                | 解决                                          |
| ---------------------------------------- | --------------------------------------------------- | --------------------------------------------- |
| `pl ide sync` 提示「文件被手工修改」   | 某 managed 文件 hash 不匹配                          | 想保留你的改动 → 不动；想覆盖 → 加 `--force` |
| 装了 adapter 但 IDE 看不到新 rules       | adapter-install 已写到 `pl/.adapter/`, 但你没 sync   | `pl ide sync` 一下                            |
| Claude 看不到 commands                   | 项目根没建 `.claude/`                                | `mkdir .claude && pl ide sync --ide claude`   |
| Codex 用户找不到任何文件                 | Codex 设计上不复制；`AGENTS.md` 里有引用列表          | 用 `@pl/agents/<name>.md` 等方式 `@-mention`  |
| 4 个 IDE 同时存在但只生效 1 个 AGENTS.md | < v1.11 的 marker 不带 IDE id, 互相覆盖              | 升 v1.11.0+；旧 AGENTS.md 删掉 pl 段重 sync   |

## v1.12+ 兼容性说明

- `adapter-install.sh` 默认双写 `pl/.adapter/` 和 `.codebuddy/`。`--no-legacy` 跳过 `.codebuddy/`
- `pl-rule-scan.sh` 三层解析（`pl/rules/` → `pl/.adapter/rules/` → `.codebuddy/rules/`）
- v2.0 起 `.codebuddy/` 兼容路径将默认关闭（届时会提前一个版本周期 deprecate 通知）

## 路线图

- v1.13: Claude skills 目录型同步（`.claude/skills/<name>/SKILL.md`）
- v1.13: 增加 `pl ide diff` 命令，预览未来 sync 会写哪些文件
- v2.0: `.codebuddy/` legacy 路径默认关闭，需 `--legacy` 显式启用
