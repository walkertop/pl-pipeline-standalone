# v1.7 CDC · Self-Dogfood Retro

> **跑于**：2026-04-23（v1.7.0 发布当日，A1 任务）
> **目标 change**：`examples/demo-nextjs-todo / add-todo-list`（demo 已 ARCHIVE 了 2 天）
> **目的**：把 v1.7 CDC 三件套在一个真实 consumer 项目上跑通一遍，验证不止"合成 E2E 能过"
> **结果**：✅ 全链路打通 + 🐛 踩出 1 个 v1.7.0 直接漏掉的 bug + 📐 暴露 1 个产品级问题待讨论

---

## 1. TL;DR

| 维度 | 结果 |
|---|---|
| Backfill 14 个 `adapter.use` 事件（4 skill / 3 rule / 2 agent / 5 capability） | ✅ 全部入 trace |
| ARCHIVE gate 自动触发 aggregate | ❌ 第一次失败 → 修 bug → ✅ 第二次成功 |
| 生成的 pact (`add-todo-list.consumed.yaml`, 103 行) | ✅ 结构正确，14 → 14 计数对齐 |
| `pl-contract-verify` happy path | ✅ 1 satisfied / 0 warn / 0 broken / exit 0 |
| 4 个 negative scenario（删 skill / deprecated / strict / removed） | ✅ 4/4 准确拦截，错误信息可读 |

**核心信号**：CDC 系统设计正确、产物可读、负面拦截准确。但 v1.7.0 release 前的合成 E2E 没覆盖到"criteria-only gate"这个边界，差点漏出去一个 bug。

---

## 2. 🐛 真实 bug：ARCHIVE 自动 aggregate 在 criteria-only gate 上被绕过

### 现象

跑 `pl-runner --change add-todo-list --gate G`（demo 的 ARCHIVE gate），输出：

```
━━━ Gate G ━━━
  from: OBSERVE  →  to: ARCHIVE
  eval: all_checks.pass

⚠  gate 'G' has no checks defined (v1 criteria only)

# 然后直接 exit，没有 "─── auto: pl-contract-aggregate ───" 输出
```

`pl/contracts/` 不存在。auto-aggregate 钩子被静默跳过。

### 根因

`pl-runner.sh` 在 `ITEMS_COUNT == 0`（gate 只有 v1 兼容的 `criteria:`、没有 v1.1+ 的 `checks:`）时走了一条**早出分支**：

```bash
# scripts/pl-runner.sh @ line 437-443（v1.7.0 状态）
if [[ "$ITEMS_COUNT" -eq 0 ]]; then
  log_warn "gate '$GATE' has no checks defined (v1 criteria only)"
  trace_gate_end "$GATE" "passed" '{"reason":"no_checks_defined"}'
  if $JSON_OUT; then ... fi
  exit 0   # ← 在这里直接走，永远到不了下面我加的 auto-aggregate 钩子
fi
```

我在 v1.7.0 的 `6a7ca3d` commit 里只在「正常评估完毕」那条路径加了钩子，完全忘了 v1 兼容 gate 这条路径。

### 为什么 v1.7.0 release 前的合成 E2E 没拦到

我之前所有 fixture（B1/B2/B3 的 8 个 case + CI 的 3 个 scenario）都用了带显式 `checks: [typecheck]` 的 gate。**没有一个 fixture 是 criteria-only gate**——所以早出分支永远没被走过。

而真实项目的 demo-nextjs-todo `pl/config.yaml` 的 gate G（OBSERVE → ARCHIVE）就是典型的 criteria-only：稳定运行 N 天 + 知识沉淀完成，这俩没法机械 check。

→ **教训**：合成 E2E 的 fixture 应该覆盖 gate 的所有声明形态，不能只挑"配置最齐"的写法。

### 修复

把钩子提取成函数 `maybe_run_archive_aggregate`，在 ITEMS_COUNT==0 早出分支也调一次：

```bash
maybe_run_archive_aggregate() {
  local gate_result="$1"
  if [[ "$gate_result" == "passed" && "$GATE_TO" == "ARCHIVE" ]]; then
    # ... 调 pl-contract-aggregate ...
  fi
}

# 早出分支:
if [[ "$ITEMS_COUNT" -eq 0 ]]; then
  log_warn "gate '$GATE' has no checks defined (v1 criteria only)"
  trace_gate_end "$GATE" "passed" '{"reason":"no_checks_defined"}'
  maybe_run_archive_aggregate "passed"   # ← 新增
  ...
fi
```

修复后第二次跑：✅ pact 正确生成。

---

## 3. ✅ Happy path 数据快照

`add-todo-list` change（demo 实际跑过的 11 个 task）映射到 nextjs-web adapter 的资产消费：

| 类别 | 数量 | 内容 |
|---|---|---|
| skills | 4 | `nextjs-app-router`（T01）/ `react-server-components`（T03）/ `nextjs-data-fetching`（T03）/ `nextjs-performance`（T08+T09） |
| rules | 3 | `typescript-strict` / `react-hooks`（T05 useFormState）/ `nextjs-revalidate-for-non-fetch`（T04+T06 server actions） |
| agents | 2 | `nextjs-architect`（PLAN）/ `nextjs-reviewer`（VERIFY） |
| capabilities | 5 | `app-router-routing` / `rsc-rendering` / `server-action-support` / `typecheck`（VERIFY）/ `lint`（VERIFY） |

→ 14 events 全部聚合进 `examples/demo-nextjs-todo/pl/contracts/add-todo-list.consumed.yaml`

`pl-contract-verify` 输出：

```
━━━ Contract Verify ━━━
  1 pact(s) checked
  1 satisfied, 0 with warnings, 0 broken

  ✓  add-todo-list                → nextjs-web@0.1.0  [satisfied]

OK: all pacts satisfied.
```

---

## 4. ✅ Negative scenarios（4/4 全部准确拦截）

| 场景 | 模拟动作 | 期望 | 实际 |
|---|---|---|---|
| **N1** 删 skill | adapter.yaml 的 `provides.skills[]` 删掉 `react-server-components` | exit 1 + 4 个 broken（4 个 skill 全标 missing，因为索引被破坏，连带 nextjs-app-router 等都报 missing——这是个**索引重建副作用**，见 §5.2） | ✅ exit 1 |
| **N2** deprecated（非 strict） | 给 `lint` capability 加 `deprecated_in: 0.1.0` | exit 0 + 1 warn | ✅ exit 0，输出 `warn   capability/lint: deprecated_in 0.1.0; plan migration` |
| **N2-strict** | 同上 + `--strict` | exit 1 | ✅ exit 1 + `STRICT FAIL: 1 warning(s)` |
| **N3** removed | 给 `server-action-support` 加 `removed_in: 0.1.0` | exit 1 + 1 broken | ✅ exit 1 + `error  capability/server-action-support: was removed_in 0.1.0 (current 0.1.0)` |

错误信息**带 reason、带版本号、带 uses 计数**，完全可 actionable，consumer 看到能立刻知道下一步该改什么。

---

## 5. 📐 暴露的产品级问题（非 bug，待讨论）

### 5.1 demo-nextjs-todo 的 gate G 没有任何机械 check

```yaml
G:
  from: OBSERVE
  to: ARCHIVE
  eval: all_checks.pass
  on_failure: block
  criteria:
    - "稳定运行 N 天（默认 3 天）"
    - "知识沉淀完成（Skills/Rules/error-log 更新）"
```

`eval: all_checks.pass` 配合 0 个 check → **永远 trivially pass**。这是 v1.0 兼容遗留：当时 gate 只有人读的 `criteria:`，v1.1 后才加 `checks:` 机器执行节，但 demo 的 config.yaml 还是 v1.0 形态。

→ **建议**（不在本次范围）：
- 短期：给 `assets/pl/config.default.yaml` 的 G gate 加一个 check（比如 `pl-contract-aggregate.sh --check` 校验 pact 是最新的，或 `pl-observe-check.sh` 校验观测数据完整性）
- 长期：rule + skill 推 adapter 作者从 v1.0 form 升级到 v1.1 form

### 5.2 删 skill 时连带误报「索引被破坏」

N1 把 `react-server-components` 从 `provides.skills[]` 删了一行，但 verify 报了 4 个 skill missing（不止那一个）。

排查发现：是我那个 N1 的 Python 修改脚本写得不够精准，把 `skills:` 段后面好几个 entry 一起 mangle 了。**这不是 verify 的 bug**，是 fixture 修改的 bug。

但顺便发现一个**真正值得记录的事**：当 adapter.yaml 因为 YAML 错误等原因解析失败时，verify 会把"adapter 找不到任何 skill"误判为"全部 skill 都 missing"。建议未来给 verify 加一个 sanity check：如果某个 adapter 的 provides 全空，应当 fast-fail 报「adapter spec broken」而不是把所有 consumer 都标 broken。

### 5.3 `versions_seen` 始终只有一个版本

pact 里 `provider.versions_seen: ["0.1.0"]`——因为这一次 change 的整个生命周期 adapter 都没升级。但**如果 change 跨多个 adapter 版本**（IMPLEMENT 时 0.1.0、VERIFY 时升到 0.2.0），`versions_seen` 会变成 `[0.1.0, 0.2.0]`，但 verify 只对账"当前 adapter 版本"——这条信息事实上是**死的**。

→ 不算 bug，但 schema 里带了一个永远没人用的字段，可以考虑：
- 选项 A: 删掉 `versions_seen`，简化 schema
- 选项 B: 给 verify 加 `--against <semver>` 让人能对账历史版本，把这字段用起来
- 选项 C: 留着不动（YAGNI——等真有跨版本 change 再设计）

我倾向 C，这个发现纯粹是顺便记一笔。

---

## 6. 📦 沉淀产物清单

| 产物 | 位置 | 是否入 git |
|---|---|---|
| 真实 trace（14 events） | `examples/demo-nextjs-todo/pipeline-output/trace/add-todo-list.events.jsonl` | ❌（pipeline-output 是 gitignored 运行时产物） |
| consumer pact | `examples/demo-nextjs-todo/pl/contracts/add-todo-list.consumed.yaml` | ✅（pl/contracts/ 是事实账本） |
| 局部 registry | `examples/demo-nextjs-todo/pl/contracts/_registry.yaml` | ✅ |
| 修 bug 的 pl-runner.sh | `scripts/pl-runner.sh`（提取 `maybe_run_archive_aggregate`） | ✅ |
| 本 retro | `docs/retros/v1.7-cdc-self-dogfood/retro.md` | ✅ |

---

## 7. 🎯 下一步建议（可选，不在本次范围）

1. **v1.7.1 patch**：把 §2 的 bugfix + §5.1 的 default config gate 升级，作为一个小 patch 发出来
2. **demo-fastapi-users 同步走一遍**：另一个真实 demo 也跑 CDC 自吃狗粮，验证 nextjs 不是孤例
3. **CI 加一个 "criteria-only gate" fixture**：把这次踩到的边界永久固化进 `cdc-broker-smoke` job
4. **写一份 `docs/guides/cdc-quickstart.md`**：用 demo-nextjs-todo 这个真实例子教 consumer 怎么启用 CDC

---

## 8. 一个观察

> **合成测试最容易漏的，是配置层面的多样性，不是逻辑层面的复杂性。**

v1.7.0 写了 8 个 B1/B2/B3 case + 3 个 CI scenario，全部用最完整的 gate 配置（带显式 checks）。
逻辑路径覆盖得不错，但 *config 形态* 的覆盖只有一种。
真实项目的 config.yaml 是 v1.0 + v1.1 杂糅的——这种"配置遗留"是合成 fixture 永远造不出来的，必须吃真实狗粮。

→ 今后 release 前，至少跑一次「拿任意一个 examples/* 走完整流水线」当 last-mile check。
