# v1.7 CDC · A2 demo-fastapi-users dogfood

> **跑于**：2026-04-23（A1 完成后 1 小时）
> **目标 change**：`examples/demo-fastapi-users / add-users-api`（已 ARCHIVE）
> **目的**：复跑 A1 路径，验证 nextjs 不是孤例 + 暴露 fastapi-only 的 bug
> **结果**：✅ 全链路通；无新 bug；明确印证 1 个产品级判断（capabilities 的价值）

---

## 1. TL;DR

| 维度 | 结果 |
|---|---|
| Backfill `adapter.use` 事件 | 14 个（4 skill / 5 rule / 2 agent / 3 build_command），全部入 trace |
| ARCHIVE gate G（criteria-only）触发 auto-aggregate | ✅ 一次成功（A1 修的 bug 跨项目可复用） |
| 生成的 pact `add-users-api.consumed.yaml` | ✅ 结构与 nextjs pact 同构，14 → 14 计数对齐 |
| `pl-contract-verify` happy path | ✅ 1 satisfied / exit 0 |
| 4 个 negative scenario（skill/rule/agent/build_command 删除/改名） | ✅ 4/4 准确拦截 |

**核心信号**：A1 在 nextjs 上修的 `pl-runner` bug，在 fastapi 上立刻验证为通用修复（不是 adapter 特定）。CDC 三件套对**没有 capabilities 的 adapter 也能工作**——但 negative scenario 体验明显比 nextjs 弱一档，正是 A3（fastapi 加 capabilities）的产品价值证据。

---

## 2. 与 A1（nextjs）的差异点

### 2.1 adapter 形态差异

| | adapter-nextjs-web@0.1.0 | adapter-python-fastapi@0.1.0 |
|---|---|---|
| skills | 5 | 4 |
| rules | 4 | 5 |
| agents | 2 | 2 |
| build_commands | 4（`compile_check / lint / test / full_build`） | 4（同名） |
| **`provides.capabilities[]`** | **5（v1.7 已迁）** | **0（A3 未做）** |

### 2.2 dogfood 流程差异

| 步骤 | nextjs (A1) | fastapi (A2) |
|---|---|---|
| 1. Backfill | 14 events，含 5 capability | 14 events，全部具体资产（无 capability） |
| 2. trigger gate G | ❌ 第一次撞 criteria-only bug，修 `pl-runner.sh` | ✅ 一次成功（吃 A1 的修复红利） |
| 3. happy path | ✅ exit 0 | ✅ exit 0 |
| 4. negative scenarios | 4 个：skill 删 / cap deprecated / strict warn / cap removed | 4 个：skill 删 / rule 删 / build_cmd 改名 / agent 删 |

**关键区别**：nextjs 因为有 capabilities，可以测「演进语义」（deprecated_in / removed_in）；fastapi 没有 capabilities，只能测「资产是否还在」这个二值断言。

---

## 3. Negative scenarios 详细记录

所有 4 个场景：tmp 备份 → mod adapter → verify → restore（trap 兜底，0 副作用）。

| # | 场景 | 改动 | 期望 | 实际 | 错误片段 |
|---|---|---|---|---|---|
| N1 | skill 删除 | 删 `sqlalchemy-async` | broken, exit 1 | ✅ exit 1 | `error  skill/sqlalchemy-async: consumer used skill/sqlalchemy-async (uses=1) but adapter python-fastapi@0.1.0 no longer provides it` |
| N2 | rule 删除 | 删 `fastapi-no-sync-blocking-in-async` | broken, exit 1 | ✅ exit 1 | `error  rule/fastapi-no-sync-blocking-in-async: ... no longer provides it` |
| N3 | build_command 改名 | `compile_check` → `typecheck` | broken, exit 1 | ✅ exit 1 | `error  build_command/compile_check: ... no longer provides it` |
| N4 | agent 删除 | 删 `fastapi-architect` | broken, exit 1 | ✅ exit 1 | `error  agent/fastapi-architect: ... no longer provides it` |

错误信息一致、可读、定位精准。CI 拿这套日志足够 PR 反馈。

---

## 4. 📐 产品观察：capabilities[] 缺席的代价

A2 是「无 capabilities adapter」的现实切片。把它和 A1（有 capabilities）对照看：

### 4.1 现象一：错误信息粒度更"实"

nextjs N2（cap deprecated）：
> `warn  capability/server-action-support: deprecated in 0.2.0 (replaced by react-server-components skill)`

fastapi 没有等价物。如果想让 fastapi 用户得到「软迁移期」的体验，必须先做 A3。

### 4.2 现象二：adapter 演进路径被钉死

举一个具体场景：fastapi adapter 想把 `compile_check` 升级为 `typecheck`（更准确的命名）。

- **没 capabilities 时**：必须保留 `compile_check` 名字直到所有 consumer 都改完，否则一升级就 broken（A2-N3 验证过）。
- **有 capabilities 时**：可以发个 capability `typecheck`，让 `backed_by.build_command` 从 `compile_check` 切到新名字，consumer 侧 pact 记的是 capability 而非具体命令——adapter 内部命名自由。

→ **结论**：capabilities 不是装饰品，它是 adapter 的"演进退路"。**A3 的优先级应该提**——不要等到 fastapi 真发 0.2.0 才发现没有迁移路径。

### 4.3 现象三：consumer 侧体感

happy path 没差别（两边都是 1 satisfied / exit 0）。差别全在 adapter 升级时——consumer 没升级 capabilities 抽象，只能硬扛 adapter 内部细节变化。

---

## 5. 复用红利：A1 的 bug 修复在 A2 一次过

A1 修了 `pl-runner.sh maybe_run_archive_aggregate` 函数 + early-exit 路径调用。A2 完全没碰这块，gate G（criteria-only）自动 aggregate 直接成功：

```
━━━ Gate G ━━━
  from: OBSERVE  →  to: ARCHIVE
  eval: all_checks.pass

⚠  gate 'G' has no checks defined (v1 criteria only)

─── auto: pl-contract-aggregate --change add-users-api ───
  aggregated 1 change(s), 1 adapter(s), 14 use event(s)
    - add-users-api: written
    registry: contracts/_registry.yaml
```

**佐证**：`maybe_run_archive_aggregate` 函数抽取得当（不是 nextjs-only hack），跨 adapter 通用。

---

## 6. 数字汇总（A1 vs A2）

| 指标 | A1 nextjs | A2 fastapi |
|---|---|---|
| backfill 事件数 | 14 | 14 |
| 生成 pact 行数 | ~103 | ~95（无 capabilities 段，少 8 行） |
| happy path verify | exit 0 | exit 0 |
| negative scenarios 个数 | 4 | 4 |
| negative 全部正确拦截 | ✅ | ✅ |
| 新发现 bug | 1（criteria-only gate） | 0 |
| 验证 A1 bug 修复通用性 | — | ✅（不是 nextjs-only） |

---

## 7. 后续建议

| 优先级 | 任务 | 理由 |
|---|---|---|
| 🔴 P0 | A3：给 fastapi/kotlin adapter 加 `provides.capabilities[]` | A2 实证：无 capabilities 时 adapter 演进路径被钉死，等到真要升级再加就晚了 |
| 🟡 P1 | A4：CI cdc-broker-smoke 加 criteria-only gate fixture | 防 A1 bug 回归；本次 A2 跑通是间接证据，不是 CI 自动验证 |
| 🟡 P1 | A5：v1.7.0 release doc 引用 A1+A2 retro | 真实跑通两个 demo 的证据，比"E2E test 通过"更有说服力 |
| 🟢 P2 | 把 A2 的 pact 同步到 demo-fastapi-users 的 git | 已自动生成，commit 即可；作为 A2 产物保留 |

---

## 8. 一句话总结

**A1 是「能跑」的证明，A2 是「不是孤例」的证明。两个 demo 加起来等于 v1.7 CDC 系统的真实交付门槛。**
