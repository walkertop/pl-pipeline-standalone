# Adapter Injection Contract

> 当用户执行 `pl init --adapter <id>` 或 `bash scripts/adapter-install.sh
> adapters/adapter-<id> <target-project>` 时，adapter 的资产**按什么规则**
> 被注入到宿主项目？本文给出形式化契约。

---

## 0. 总则

Adapter 注入是一个**单向、幂等、可撤销**的操作：

- **单向**：从 adapter 包 → 宿主项目；不会反向影响 adapter 包
- **幂等**：同一 adapter 同一版本注入多次，结果一致
- **可撤销**：保留 `.pl-adapter` 元数据，`pl uninstall` 可清理注入的文件

---

## 1. 注入前置条件

执行 `adapter-install.sh` 前，宿主项目必须：

1. **已初始化 pl 结构**：存在 `pl/config.yaml`（由 `pl init` 自动创建）
2. **未装过同 id adapter**（或用户同意覆盖）
3. **必要的 IDE 目录就位**（如 `.codebuddy/` 根据 `pl init --ide` 决定）

---

## 2. 注入路径映射表

以 adapter `rust-axum` 安装到目标项目 `/my-project` 为例：

| adapter 内路径 | 宿主目标路径 | 合并策略 |
|---|---|---|
| `adapter.yaml` | `.pl-adapter.yaml`（精简版） | 覆盖 |
| `README.md` | — (不拷贝) | 忽略 |
| `templates/spec.md` | `pl/templates/spec.md`（adapter 覆盖 pl-core 默认） | 覆盖 |
| `templates/plan.md` | `pl/templates/plan.md` | 覆盖 |
| `templates/taskdag.md` | `pl/templates/taskdag.md` | 覆盖 |
| `templates/<any>.md` | `pl/templates/<any>.md` | 覆盖 |
| `agents/<file>.md` | `.codebuddy/agents/<file>.md` | 跳过已存在文件 (warn) |
| `skills/<file>.md` | `.codebuddy/skills/<file>.md` | 跳过已存在文件 (warn) |
| `rules/<file>.md` | `.codebuddy/rules/<file>.md` | 跳过已存在文件 (warn) |
| `scripts/<name>.sh` | `scripts/adapter-<id>-<name>.sh` | 覆盖（加 adapter-<id> 前缀避免冲突） |
| `docs/case-study.md` | — (不拷贝) | 忽略（留在 adapter 包内） |
| 其他文件 | — (不拷贝) | 忽略 |

### 2.1 `.pl-adapter.yaml` 精简版

不是 adapter 包里完整的 `adapter.yaml`，而是宿主项目记录"装了什么 adapter"
的元数据：

```yaml
# /my-project/.pl-adapter.yaml
apiVersion: pl.dev/v1
adapter:
  id: rust-axum
  version: 0.1.0
  installed_at: "2026-04-21T21:50:00Z"
  installed_from: "adapters/adapter-rust-axum"
  source_sha256: <adapter.yaml 的 sha256>  # 用于检测漂移

installed_files:
  - pl/templates/spec.md
  - pl/templates/plan.md
  - pl/templates/taskdag.md
  - .codebuddy/agents/rust-axum-architect.md
  - .codebuddy/skills/axum-patterns.md
  - .codebuddy/skills/sqlx-async.md
  - .codebuddy/rules/rust-api-design.md
  - .codebuddy/rules/rust-error-handling.md
  - scripts/adapter-rust-axum-build.sh
  - scripts/adapter-rust-axum-verify.sh
  - scripts/adapter-rust-axum-lint.sh

build_adapter:
  type: cargo
  env:
    PL_BUILD_CHECK_CMD: "cargo check"
    PL_LINT_CMD: "cargo clippy -- -D warnings"
    PL_TEST_CMD: "cargo test"
```

**这份文件由 `adapter-install.sh` 自动生成**，用户不必手写。

---

## 3. 文件冲突策略

### 3.1 覆盖策略适用（直接替换）

- `pl/templates/*.md`：adapter 的模板总是赢（adapter 的定位就是场景化模板）
- `scripts/adapter-<id>-*.sh`：因为加了 id 前缀，同 id 重装就是更新
- `.pl-adapter.yaml`：总是最新

### 3.2 跳过策略适用（保留已有文件）

- `.codebuddy/agents/*.md`：用户可能已有自定义 agent
- `.codebuddy/skills/*.md`：同上
- `.codebuddy/rules/*.md`：同上

冲突时输出警告：

```
⚠️  .codebuddy/agents/rust-axum-architect.md already exists, skipped.
    To force overwrite: bash scripts/adapter-install.sh --force <adapter> <target>
```

### 3.3 `--force` 覆盖

用户显式允许时全部覆盖（包括 .codebuddy/ 下的 agents/skills/rules）。

### 3.4 `--dry-run` 预览

只输出"会写什么文件"，不实际写。

---

## 4. 卸载（uninstall）

`bash scripts/adapter-uninstall.sh <id> <target>`（未来实现）：

1. 读 `.pl-adapter.yaml` 的 `installed_files[]`
2. 逐个删除这些文件（按契约只删 adapter 装的，不删用户手写的）
3. 删除 `.pl-adapter.yaml` 自身

**注意**：pl/templates/ 下的文件删除后会落回 pl-core 默认模板。

---

## 5. 版本升级（upgrade）

`bash scripts/adapter-install.sh --upgrade <adapter> <target>`（未来实现）：

1. 读 `.pl-adapter.yaml` 的旧版本
2. 对比新旧 adapter.yaml 的 `installed_files[]` 差集：
   - 旧有新无 → 删除
   - 新有旧无 → 新增
   - 共有 → 用新版覆盖（默认）或对比 diff（`--interactive`）
3. 更新 `.pl-adapter.yaml`

---

## 6. 多 adapter 共存？

**v0.1 MVP 不支持**：每个宿主项目只能装一个场景 adapter。

原因：templates 是"覆盖"关系，多个 adapter 会互相踩；agents / skills /
rules 命名空间可以共存但缺乏冲突仲裁规则。

未来版本若要支持，需要引入：
- `.pl-adapter-stack.yaml`（记录 adapter 栈）
- 模板"层叠"机制（类似 CSS cascade）

---

## 7. 注入过程的 piao 事件

若 adapter 声明了 `piao_emit`，`adapter-install.sh` 在完成注入后会：

1. 生成一个 `urn:piao:artifact:pl:<adapter-id>:installed@v<version>` URN
2. 写一条 `artifact.published` 事件到宿主的 `$PL_OUTPUT/piao/kernel-events/<YYYY-MM>.jsonl`
3. 事件 `event_id` 前缀为 `adapter-installed-`

这让 piao 的漂移 / 演化系统能追踪"某个项目在某时点装了某个 adapter"。

---

## 8. 引用完整性保证

以下是 `adapter-validate.sh` 在注入前会检查的点：

| 检查项 | 检查内容 |
|---|---|
| Manifest 语法 | 符合 `adapter-manifest.schema.json` |
| `provides.templates.*` 指向的文件存在 | 否则注入过程会失败 |
| `provides.agents[].path` 文件存在 | 同上 |
| `provides.skills[].path` 文件存在 | 同上 |
| `provides.rules[].path` 文件存在 | 同上 |
| `provides.scripts.*` 文件存在且可执行 | 否则报 warning |
| `piao_emit.urn_namespace` 格式 | 必须匹配 URN 规范 |
| `metadata.id` 和目录名一致性 | 目录 `adapters/adapter-<id>/` |

---

## 9. 安全边界

adapter-install.sh **不应**做以下事情：

- ❌ 修改宿主 `.git/hooks/`（这是 `setup-hooks.sh` 的职责）
- ❌ 修改宿主源码目录（只碰 `pl/` / `.codebuddy/` / `scripts/adapter-*`）
- ❌ 执行 `adapter.yaml` 里声明的 `build_adapter.commands.*`（那是 pl-core
  运行时做的事）
- ❌ 调用 `curl` / 网络下载（adapter 必须在本地完全可验证）

---

## 10. 本契约版本

| 版本 | 日期 | 变化 |
|---|---|---|
| v1.0 | 2026-04-21 | 首版定义，MVP 阶段适用 |
