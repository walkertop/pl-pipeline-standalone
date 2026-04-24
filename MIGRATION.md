# Migration Guide — v1.0 → v1.2.0

本文档指导你把 **v1.0 时代的 pl-pipeline 项目** 升级到 **v1.2.0**（retro-v2 收官版）。

> 🆕 **新项目启动 ≠ 老项目升级**：如果你是**全新项目**，请直接看
> [README §30 秒上手](./README.md#30-秒上手v110)（一键 `curl | bash` + `pl new`），
> 不需要读本文档。本文档只服务于"已经在跑 v1.0 老项目想吸收 v1.2 新能力"的存量场景。

> 📌 **v1.8+ 提示**：本文档保留 v1.2 时期的 `bash $PL_HOME/scripts/<x>.sh ...` 调用风格作为
> 历史快照。**v1.8.0 起所有这些命令都有等价的 `pl <subcmd>` 形式**，
> 一一对应见 [`docs/cli-reference.md`](./docs/cli-reference.md)。
> 如果你是新读者：先 `export PATH="$PL_HOME/bin:$PATH"`，然后把下文每条
> `bash $PL_HOME/scripts/pl-runner.sh ...` 心理替换成 `pl run ...`。

---

## TL;DR

v1.2.0 完全向后兼容 v1.0 的项目，**不做任何改动也能继续用**。但想享受 v1.2 的
四项新能力（E1/E2/E3/E4），需要做下列 3 件事，每件都是 **opt-in 增量**：

| 步骤 | 耗时 | 动作 |
|---|---|---|
| 1 | 5 分钟 | 升级 pl-core：下载新版 `pl-pipeline-standalone`，重置 `PL_HOME` |
| 2 | 10-30 分钟 / adapter | 在 adapter.yaml 里填 `build_adapter.smoke` + `contract` |
| 3 | 5-15 分钟 / rule | 给最痛的 rule 加 YAML frontmatter（executable 标志） |

做完每一步都能立刻跑新工具验证效果，不需要一次做完。

---

## 升级动机一览

| 新能力 | 解决什么问题 | 效果 |
|---|---|---|
| **E1** 可执行契约层 | v1.0 的 gate 判据是散文，无法机器验证 | `pl-runner.sh` 按 check 结果**自动派生** gate 通过/阻塞 |
| **E2** SMOKE 阶段 | v1.0 的 VERIFY 只跑静态检查，不真启动应用 | `pl-smoke.sh` boot 应用 + 跑 HTTP probe + 关停 |
| **E3** rule-as-code | v1.0 的 rule 只是 AI prompt，CI 没法消费 | rule 加 frontmatter → `pl-rule-scan.sh` 自动执行 |
| **E4** 契约-现实漂移 | v1.0 无法发现"宿主依赖/文件和 adapter 期望不一致" | `piao-contract-drift-compute.sh` 对齐 declared vs actual |

---

## Step 1 · 升级 pl-core 本体（5 分钟）

### 1.1 拉最新代码

```bash
cd /path/to/pl-pipeline-standalone
git fetch --tags
git checkout pl-v1.2.0
```

### 1.2 确认 `PL_HOME` 正确

```bash
# 在任何 shell 打开 pl-pipeline-standalone 目录下
echo $PL_HOME
# 期望：/absolute/path/to/pl-pipeline-standalone
```

> ⚠️ **坑位警告**：如果你之前在**父目录** `source scripts/_env.sh`，
> `PL_HOME` 可能被污染到父目录（ZSH vs bash `source` 行为差异）。
> 从 v1.1.1 起脚本有纠偏逻辑，但仍建议每次手动：
> ```bash
> unset PL_HOME PL_PROJECT
> export PL_HOME="/absolute/path/to/pl-pipeline-standalone"
> ```

### 1.3 验证新脚本可用

```bash
bash $PL_HOME/scripts/pl-runner.sh --help                    # E1
bash $PL_HOME/scripts/pl-smoke.sh --help                     # E2
bash $PL_HOME/scripts/pl-rule-scan.sh --help                 # E3
bash $PL_HOME/scripts/piao-contract-drift-compute.sh --help  # E4
```

**到这里 Step 1 就完成了**——所有新工具对**原 v1.0 项目**已经可用，只是它们都会
给你返回 "skipped"（因为 adapter 还没声明新字段）。这正是 v1.2 "opt-in 增量"
的设计：不配置 = 不打扰。

---

## Step 2 · 给 adapter 填上新字段（每个 adapter 10-30 分钟）

v1.2 的 `adapter.yaml` 支持 3 个新顶级字段。**全部 optional**，不写就 skip。

### 2.1 `build_adapter.smoke`（E2 消费）

```yaml
build_adapter:
  # ... 原有 commands 保持 ...

  smoke:                              # v1.2 新增
    start_cmd: "uvicorn app.main:app --host 127.0.0.1 --port ${SMOKE_PORT:-38765}"
    cwd: "."
    ready_url: "http://127.0.0.1:${SMOKE_PORT:-38765}/health"
    ready_timeout_sec: 15
    probes:
      - id: health_happy
        method: GET
        path: "/health"
        expect_status: 200
      - id: register_happy
        method: POST
        path: "/auth/register"
        body_json:
          email: "test@example.com"
          password: "Test1234!"
        expect_status: 201
```

**如果你的应用是 Next.js dev server 这种"HMR 清 map"的特殊场景**，可以写成
显式 opt-out：

```yaml
build_adapter:
  smoke:
    skip: true
    skip_reason: "dev server 不适合单次冒烟；用 VERIFY 的编译检查兜底"
```

**决策树**：

- 你的 adapter 有明确的 `start_cmd` + `ready_url` → 写完整 smoke 段
- 是 dev server / 交互式工具 / 不适合单次冒烟 → 写 `skip: true`
- 暂时不想配 → **不写**（默认等价于 skip，但不会发 `smoke.skip` 事件）

### 2.2 `contract`（E4 消费）

描述**宿主项目应该是啥样**：

```yaml
contract:
  # 期望的文件（不存在则产 drift 条目）
  expected_files:
    - path: pyproject.toml
      severity: error
    - path: app/main.py
      severity: error
    - path: app/layout.tsx
      alt_paths: ["app/layout.js", "pages/_app.tsx"]    # 任一存在即通过
      severity: error
    - path: tests/
      kind: dir                                          # 目录而非文件
      severity: warn

  # 期望的依赖版本（pkg_manager → { name: semver_spec }）
  peer_versions:
    npm:                              # 适用于 package.json / package-lock.json
      next: ">=15.0.0"
      react: ">=19.0.0"
      "@types/react": ">=19.0.0"      # 带 @ 的 key 要加引号
      typescript: ">=5.5"
    python:                           # 适用于 uv.lock / pyproject.toml
      fastapi: ">=0.110"
      bcrypt: ">=4.0,<5.0"            # 多 constraint（npm 和 pip 风格都支持）
      python-multipart: ">=0.0.9"     # 真跑时发现会缺的包

  # 已知坏组合（命中任一即产 drift）
  known_bad_combos:
    - id: passlib-vs-bcrypt-5
      when:
        python:
          passlib: "*"
          bcrypt: ">=5.0"
      severity: error
      message: "passlib 对 bcrypt>=5.x 有 AttributeError / 72 字节 bug"
```

**从哪里挖出这些字段？**

- `expected_files`：回想"宿主缺哪个文件时应用直接起不来"
- `peer_versions`：看 adapter 对应技术栈的**近 6 个月 CVE / 破坏性更新**
- `known_bad_combos`：看你的项目**真实踩过的**依赖兼容坑（这是活的经验）

### 2.3 验证 adapter

```bash
bash $PL_HOME/scripts/adapter-validate.sh adapters/your-adapter
```

schema 校验会告诉你字段是否合规。

### 2.4 重新安装到宿主项目

```bash
bash $PL_HOME/scripts/adapter-install.sh --force \
  $PL_HOME/adapters/your-adapter \
  /path/to/your-project
```

**这一步关键**：`adapter-install.sh --force` 会把新 rule 文件拷到宿主的
`.codebuddy/rules/`，`.pl-adapter.yaml` 也会更新。

### 2.5 跑 E2 / E4 验证效果

```bash
export PL_PROJECT=/path/to/your-project

# E2 SMOKE
bash $PL_HOME/scripts/pl-smoke.sh --change my-change --json

# E4 contract drift
bash $PL_HOME/scripts/piao-contract-drift-compute.sh --change my-change --json
```

如果 `peer_versions` 写得靠谱，E4 会立刻告诉你哪些依赖不符合期望。

---

## Step 3 · 给 rule 加 executable frontmatter（每条 5-15 分钟）

v1.2 之前 rule 是纯 markdown，只给 AI 读。v1.2 后 rule 顶部可以加 YAML
frontmatter，`pl-rule-scan.sh` 会自动消费。

### 3.1 改造现有 rule

以 retro-v2 B3 "revalidateTag 误用"为例：

```markdown
---
id: nextjs-revalidate-for-non-fetch
severity: warn
scope: always
applies_to:
  glob:
    - "app/**/_actions/**/*.ts"
    - "app/**/_actions/**/*.tsx"
  exclude_glob:
    - "**/node_modules/**"
    - "**/.next/**"
detect:
  - kind: file_contains
    pattern: "'use server'"
  - kind: file_contains
    pattern: "revalidateTag\\("
  - kind: file_not_contains
    pattern: "fetch\\("
message: |
  revalidateTag 仅对 fetch() 发起的数据源生效。
  如果你的数据源是 module-state / globalThis / DB 直连，revalidateTag 不会触发重渲染。
fix_hint: |
  改用 revalidatePath('/your/path')
---

# Next.js: revalidateTag 只对 fetch 数据源生效

（原有的 markdown 内容保留，AI 继续受益）
...
```

**三个核心字段**：

| 字段 | 说明 |
|---|---|
| `applies_to.glob` | 哪些文件应被这条 rule 扫 |
| `detect[]` | 多条 detect **AND** 语义：全部满足才算违规 |
| `severity` | `error` / `warn` / `info`（`error` 会让 scan 整体 fail） |

**支持的 `detect.kind`**：

- `file_contains` — 整个文件中 regex 至少匹配 1 次
- `file_not_contains` — 整个文件中 regex 一次都不匹配
- `line_contains` — 逐行匹配，结果记录行号

### 3.2 在 adapter.yaml 登记 executable rule

```yaml
rules:
  - id: nextjs-revalidate-for-non-fetch
    path: "rules/nextjs-revalidate-for-non-fetch.md"
    scope: always
    description: "..."
    executable: true      # ← v1.2 新增标志
```

> `executable: true` 不是 schema 强制，但推荐加上，方便 `pl-rule-scan.sh` 未来做
> 分类统计。没加也能扫（引擎直接读 frontmatter 判断）。

### 3.3 重装 + 跑 scan

```bash
bash $PL_HOME/scripts/adapter-install.sh --force $PL_HOME/adapters/your-adapter /path/to/your-project

export PL_PROJECT=/path/to/your-project
bash $PL_HOME/scripts/pl-rule-scan.sh --change my-change --json
```

产出：

- `pipeline-output/rule-scan/<change>.yaml`（详细 violation）
- trace 事件 `pl.rule_scan.completed`（进 `pipeline-output/trace/<change>.events.jsonl`）

---

## Step 4 （可选）· 跑完整四通道合流

升级三步都做完，可以跑完整流水线验证 pl ↔ piao 合流：

```bash
export PL_PROJECT=/path/to/your-project

# 按顺序 4 个脚本（各自写事件到同一条 events.jsonl）
bash $PL_HOME/scripts/pl-runner.sh               --change my-change --gate D --json
bash $PL_HOME/scripts/pl-smoke.sh                --change my-change --json
bash $PL_HOME/scripts/piao-contract-drift-compute.sh --change my-change --json
bash $PL_HOME/scripts/pl-rule-scan.sh            --change my-change --json

# 看四通道事件
cat $PL_PROJECT/pipeline-output/trace/my-change.events.jsonl | jq -c '{phase, event}'
```

期望你会看到四类事件合流：

```
IMPLEMENT gate.eval              ← E1
SMOKE     smoke.boot → probe*n → smoke.shutdown   ← E2
OBSERVE   piao.contract_drift.detected            ← E4
OBSERVE   pl.rule_scan.completed                  ← E3
```

---

## 常见问题

### Q1：我的项目用自研 adapter，不想改怎么办？

完全可以。adapter.yaml 的新字段全部 optional。所有 v1.2 新脚本遇到缺字段会：
- E2 / E4：emit `{event}.skip` 事件 + 返回 exit code 3（约定的 skipped 码）
- E3：scan 完返回 "no executable rules found, skipped"

**不会有任何破坏性行为**。你可以分 rule / 分 adapter 渐进升级。

### Q2：升级后现有脚本（pl-status / pl-dashboard-refresh）还能跑吗？

可以。v1.2 **不修改**任何 v1.0 的脚本入口和产物格式。
- `pl/config.default.yaml` schema 升 v1.1，但新字段均 optional
- `adapter-manifest.schema.json` apiVersion 升 `pl.dev/v1.1`，新字段均 optional
- 7 件核心产物（spec.md / plan.md / ...）格式不变

### Q3：我之前没打过 pl-v1.0.0 tag 怎么办？

没关系。pl-v1.0.0 是**概念分水岭**，不是 git tag。
你的项目只要能跑 `pl-status.sh` 就算 v1.0 兼容。直接 checkout `pl-v1.2.0` 即可。

### Q4：想回退怎么办？

```bash
cd /path/to/pl-pipeline-standalone
git checkout <老 commit>
```

宿主项目的 `.pl-adapter.yaml` / `.codebuddy/rules/` 是 `adapter-install` 时拷进去的，
不会被 pl-core 回退影响。adapter 新加的 `contract` / `smoke` 段如果你不想要，
从 adapter.yaml 删掉即可。

### Q5：bash 3.2（macOS 系统默认）能跑所有新脚本吗？

**能**。v1.2 为了绕开 bash 3.2 的 `$(cmd <<'EOF' ... EOF)` 多括号 heredoc bug，
已经把所有复杂 Python 逻辑拆到 `scripts/_lib/*.py`。bash 脚本只做薄编排，都能在
3.2 跑通。

### Q6：v2.0 计划是什么？要等 v2 再升吗？

v2.0 的计划是 TypeScript CLI 重写 + MCP Server，属于**底层实现替换**，v1.x 的
YAML schema / 7 件产物 / 门禁语义都会保持兼容。**现在升 v1.2 完全不浪费**。

---

## 升级追踪表

给团队用的 checklist：

- [ ] Step 1：`PL_HOME` 指向 `pl-v1.2.0` checkout 的目录
- [ ] Step 1：`bash $PL_HOME/scripts/pl-runner.sh --help` 能出 usage
- [ ] Step 2：adapter-nextjs-web 填 `smoke` + `contract`（如果你用）
- [ ] Step 2：adapter-python-fastapi 填 `smoke` + `contract`（如果你用）
- [ ] Step 2：自研 adapter 填 `smoke` + `contract`
- [ ] Step 2：`adapter-install.sh --force` 同步到所有消费项目
- [ ] Step 3：至少 1 条最痛的 rule 加 frontmatter 改成 executable
- [ ] Step 3：`pl-rule-scan.sh` 对目标项目跑通 + 0 false positive
- [ ] Step 4：完整四通道合流跑通（可选，但很爽）

---

## 参考材料

- [CHANGELOG.md](./CHANGELOG.md) — 完整变更历史
- [docs/retros/2026-04-demo-first-run-retro-v2.md](./docs/retros/2026-04-demo-first-run-retro-v2.md) — 4 剂药的设计根因
- [docs/retros/evidence-2026-04/README.md](./docs/retros/evidence-2026-04/README.md) — 真实的四通道合流示例
- [ROADMAP.md](./ROADMAP.md) — v0.2 本体增强表（E1/E2/E3/E4）

有问题请提 issue：https://github.com/walkertop/pl-pipeline-standalone/issues
