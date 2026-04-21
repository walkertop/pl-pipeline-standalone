---
name: "PL: Verify"
description: "全链路验证：过 D 门禁进入 VERIFY → 闭合 E 门禁（pl-pipeline v1）"
argument-hint: "[change-id]"
---

对 `pl/changes/<id>/` 已完成编码的 change 运行全链路验证：静态检查 + 编译 + 网络/解析自检 + 运行时日志 + UI 截图 diff，产出 `Self-Check Results` 节，闭合 E 门禁。

---

## 输入

`$ARGUMENTS` = change-id；省略时选 `stage=IMPLEMENT, gate=C-passed` 或 `stage=VERIFY` 的 change。

---

## 步骤

### 1. 评估 D 门禁

D 判据（`pl/config.yaml`）：

- [ ] **lint PASS**：`./scripts/lint.sh`（detekt + 自定义规则）
- [ ] **compile PASS**：`./gradlew build` 或 `./scripts/build-all.sh`
- [ ] **网络层自检 PASS**：Mock fallback 下关键接口可回源
- [ ] **解析层自检 PASS**：宽松解析降级不崩

**逐项执行**：

```bash
# 静态检查
./scripts/lint.sh || { echo "lint FAIL"; exit 1; }

# 迁移专项检查（若适用）
./scripts/kuikly-migration-lint.sh --page <id>

# 编译
./scripts/build-all.sh || { echo "build FAIL"; exit 1; }

# 迁移验证一键流水线（含运行时）
./scripts/migration-verify.sh --page <id>
# 若 pl-migration-verify.sh 存在，优先用它
[ -x scripts/pl-migration-verify.sh ] && ./scripts/pl-migration-verify.sh --change <id>
```

**自动修复**：lint/build 失败若属于明显可机修类（未引入 import / 格式问题 / 未使用变量），直接修并重跑；否则报告用户。

通过后：`.state.md` 写入 `stage=VERIFY, gate=D-passed`。

### 2. 运行时观测与 TraceContract

- 按 taskdag.md 中定义的关键路径走一遍（登录 / 进入页面 / 点击支付 / ...）
- 用 `./scripts/migration-logcat-analyzer.sh --page <id>` 抓 logcat，分析 ERROR / WARN
- TraceContract：把旧版本埋点列表（来源 deps.md 或 spec.md）和新版实际触发的埋点对比

### 3. UI 截图对比（若适用）

```bash
./scripts/auto-test-runner.sh --change <id>
# 或手动
./scripts/trace-report.sh --page <id> --open
```

产出 diff 报告，阈值：默认 ≤ 5%（pl/config.yaml E 判据可覆盖）。

### 4. 写 Self-Check Results 节到 `.state.md`

```markdown
## Self-Check Results

**Gate D (IMPLEMENT→VERIFY):** PASSED @ <ISO>
- lint: PASS (0 errors, 2 warnings)
- migration-lint: PASS (黑名单 0 命中)
- build: PASS (android + ios)
- api self-check: PASS (5/5 接口 mock fallback 正常)
- parse self-check: PASS (宽松解析降级验证通过)

**Gate E (VERIFY→OBSERVE):** <PENDING | PASSED | FAILED> @ <ISO>
- runtime logs: <N ERROR / M WARN>
- TraceContract: <K/K 埋点对齐> | <K-X/K 缺失: ...>
- UI diff: <2.3% ≤ 5% PASS> | <FAIL: ...>

**Artifacts Produced:**
- pipeline-output/trace/<id>.events.jsonl
- pipeline-output/reports/<id>.html
- pipeline-output/screenshots/<id>/*.png
```

### 5. 评估 E 门禁

- E 全绿 → `.state.md` 写 `stage=VERIFY, gate=E-passed`，next → `/pl:archive` 前先手动 OBSERVE N 天
- E 有失败项：
  - 自动列出失败项 + 定位（代码文件 / 日志行）
  - 优先用 migration-guardian subagent 给自愈建议
  - 若是轻量修复（≤ 2 文件，≤ 50 行），直接修 + 重跑验证
  - 否则报告用户选择：`修 X 后重跑 verify` / `退回 implement` / `接受风险继续 observe`

### 6. Trace 与 piao 对接（降级）

verify 通过时发一条 `artifact.registered` 事件给 piao：

```bash
if [ -f scripts/pl-trace-emit.sh ]; then
  ./scripts/pl-trace-emit.sh \
    --change <id> --stage VERIFY --event verify.passed \
    --emit-piao \
    --sha256-scan "pl/changes/<id>/*.md"   # 现场算 sha256（PIAO-001-SHA256 纪律）
fi
```

### 7. 输出摘要

```
## Verify Complete

**Change:** <id>
**Stage:** IMPLEMENT → VERIFY
**Gate D:** ✓ PASSED
**Gate E:** <✓ PASSED | ⚠ PARTIAL | ✗ FAILED>

**Self-Check Results:**
- Lint / Build / Network / Parse: 4/4 ✓
- Runtime Logs: 0 ERROR, 2 WARN
- TraceContract: 11/11 埋点对齐
- UI Diff: 1.7% (阈值 5%)

**Reports:**
- pipeline-output/reports/<id>.html
- pipeline-output/trace/<id>.events.jsonl

**Next Steps:**
→ 观察 N 天，期间通过 `/pl:status <id>` 跟进
→ 稳定后 `/pl:archive <id>` 归档
```

---

## Guardrails

- **D 不过不做 E**（门禁顺序不可跳）
- **不要**在 verify 阶段改业务代码逻辑，只做 lint-fix / import-fix / 测试补齐
- **必须现场算 sha256**（PIAO-001-SHA256），不使用缓存值
- **必须**跑 migration-verify.sh 全套，不允许只跑 lint 就宣布通过
- 截图 diff 超阈值 → 默认 FAIL，除非用户明确接受（UI 细节差异在 E 判据允许范围内记录备注）
- 自动修复只做「确定无副作用」的机修项；有歧义的一律报告用户
- 不要在本命令里做归档（那是 `/pl:archive` 的事）
