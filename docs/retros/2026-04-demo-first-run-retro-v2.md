# Retro v2: 从 adapter 视角回到 pl/piao 本体视角

> 日期：2026-04-21（v2 修订）
> 替代：v1 retro（已归档作为 misdiagnosis 示例保留）

---

## 0. 为什么需要 v2

v1 retro 的结论是"**让 adapter 多声明几个字段**"——这是**被 adapter 视角绑架**的误诊。
用户指出核心矛盾：

> "demo 是 adapter 的应用场景，最终目的是推动 piao-pipeline 和 pl-pipeline 的改进，
> 不要被 adapter 困住。"

本 retro 从 **pl/piao 本体缺什么** 重新归因。

并且本 retro 额外补上一项 v1 漏检的严重证据：**demo 跑的时候根本没执行 pl 流程**。

---

## 1. 证据：demo 跑过，pl 流程没跑过

trace 文件是 pl 流水线的唯一真相源。检查：

```bash
$ find examples -name "*.events.jsonl"
(空)
$ ls examples/demo-nextjs-todo/pipeline-output/
(不存在)
$ ls /Users/guobin/Developer/djc1/daojuROOT/KuiklyPolyCity/pipeline-output/trace/
order_detail-report.html   order_detail.events.jsonl   ← 宿主是有的
```

- 我跑 demo 用的是 `npm run dev` / `uv run uvicorn` —— **应用层启动**
- `bash scripts/pipeline-orchestrator.sh --page add-todo-list --status` 能识别 change，
  但没触发任何 check，也没写一条 trace
- demo 的 `.state.md` 里那些 "11/11 DONE" 是手工填的叙事，**不是流水线跑出来的**

**换句话说：adapter-install 工作 → demo 手工填 → pl-status 识别 → 看起来都过了**。
但从头到尾没有**一次机器驱动的流水线执行**，也没有**一条 trace 事件**。

---

## 2. 为什么没跑起来？ pl 本体的 4 条断层

抛开 adapter，7 个 demo bug 重归因到 pl/piao 缺的通用能力：

### ❶ pl 缺"可执行契约层"（对所有技术栈通用）

`pl/config.yaml` 的门禁判据：

```yaml
D:
  criteria:
    - "lint PASS（scripts/lint.sh）"
    - "compile PASS（./gradlew build）"   ← 硬编码宿主栈
    - "网络层自检 PASS"                     ← 自然语言
```

三个问题：
1. 判据是**散文，不可执行**
2. 宿主栈 **硬编码进了通用配置**（scripts/lint.sh、gradle）
3. **gate 评估和 check 结果没闭环**：
   我本轮实验里明明 `ruff check` fail 了，但 `gate.eval` 还是写 "passed"

pl 本体应该提供的抽象：

```
GateDefinition {
  id: "D",
  from: IMPLEMENT, to: VERIFY,
  required_checks: [ref(compile), ref(lint), ref(test)],
  eval_rule: "all_checks.status == pass"
}

CheckDefinition {
  id: "compile",
  cmd: "${PL_BUILD_CHECK_CMD}",    ← adapter 填
  success_pattern: "${PL_BUILD_CHECK_SUCCESS_PATTERN}",
  timeout_sec: 180
}
```

**关键**：这个抽象属于 pl，不属于 adapter。Adapter 只填 `${...}` 占位。

### ❷ pl 缺 "SMOKE 阶段"（真的启动一次）

现有 6 阶段：`SPEC → PLAN → IMPLEMENT → VERIFY → OBSERVE → ARCHIVE`

VERIFY 是**静态检查**（lint / compile / unit test），OBSERVE 是**真实线上观察**。
中间缺一个 **SMOKE**：**真的启动应用 + 打一发请求**。

我本轮模拟 SMOKE 跑出来的 trace 证明它能工作：

```jsonl
{"phase":"VERIFY","event":"phase.start","data":{"phase_name":"SMOKE","mode":"..."}}
{"phase":"VERIFY","event":"smoke.boot","data":{"pid":33644,"cmd":"uvicorn app.main:app"}}
{"phase":"VERIFY","event":"smoke.ready","data":{"attempts":1}}
{"phase":"VERIFY","event":"smoke.probe","data":{"id":"register_happy","status_code":201,"expect":201,"pass":true}}
{"phase":"VERIFY","event":"smoke.probe","data":{"id":"register_duplicate","status_code":409,"expect":409,"pass":true}}
{"phase":"VERIFY","event":"smoke.probe","data":{"id":"list_without_auth","status_code":401,"expect":401,"pass":true}}
{"phase":"VERIFY","event":"smoke.probe","data":{"id":"list_with_auth","status_code":200,"expect":200,"pass":true}}
```

FastAPI demo **如果 pl 有 SMOKE 阶段**，B6（缺 python-multipart）会在 `smoke.boot` 立刻暴露
（OAuth2PasswordRequestForm 引用链解析失败），B5（HMR Map reset）会在两次 probe 差值里体现。

### ❸ pl 缺 "rule-as-code" 引擎（让 rule 可机器执行）

rule / skill 目前是 markdown prompt —— **只给 AI 看，不能 CI 跑**。

B3 的 `revalidateTag` 误用在 `nextjs-data-fetching.md` skill 里**白纸黑字**写了：
> revalidateTag 只对 fetch() 生效；module-state 请用 revalidatePath

但没有机器化的 detect 协议。这是 **pl 本体缺的通用能力**：

```markdown
---
id: <any-rule-id>
engine: ripgrep         ← 通用引擎，不特定于语言
rule:
  must_all:
    - pattern: "'use server'"
    - pattern: "revalidateTag"
  must_none:
    - pattern: "fetch\\("
severity: warn
---
... markdown body for humans and AI ...
```

这个声明**是 pl 层抽象**，用哪种引擎（ripgrep / ast-grep / semgrep）由 pl 实现决定。
Adapter 只是规则的**产出方**。

### ❹ piao 的漂移检测没对准"契约 vs 现实"

piao 现在的 `drift-compute` 只比较**不同时间点的 URN snapshot**，即"昨天写的 vs 今天写的"。
但 demo bug 反映的是另一种漂移：**声明的契约 vs 宿主真实状态**。

- B1：adapter 声明"需要 React 19"（可以加 peer_versions），宿主实际装 React 18.3 → **漂移**
- B4：adapter 声明 `requires.files: [package.json]`，但真实需要 `tsconfig.json / next.config.ts` → **声明不全**
- B7：adapter.yaml 没声明 `passlib + bcrypt>=5 = broken`，但世界上这个 combo 确实坏 → **知识漂移**

piao 应该提供的通用抽象：

```
ContractDrift = { declared: Snapshot, actual: Snapshot } → diff → events
```

declared 来自 adapter manifest / lockfile；actual 来自 `pl doctor` 实时扫描。
**这是 piao 层事，不是 adapter 层事。**

---

## 3. 对应的 4 个 pl/piao 本体增强（非 adapter）

| # | 改动层 | 能力 | 本次 trace 已证明 |
|---|---|---|---|
| **E1** | pl-core | 把 gate.criteria 从散文改成 `{checks: [...], eval: ...}` 结构，统一执行器 | ✅ 本轮手工模拟已跑通 |
| **E2** | pl-core | 新增 SMOKE 阶段（或 VERIFY 的强制子阶段），定义 `smoke.{boot,ready,probe,shutdown}` 事件 | ✅ 对 FastAPI 跑出 4 个 probe |
| **E3** | pl-core | rule frontmatter + 通用 `rule-engine.sh`（实现可以是 ripgrep/ast-grep） | ⏳ 未实现，但 B3 demo 可验证 |
| **E4** | piao | 新增 `contract-drift-compute`：比较 declared contract vs 实测 snapshot | ⏳ 未实现 |

Adapter 只承担**占位填充**的角色：
- E1：填 `${PL_BUILD_CHECK_CMD}`
- E2：填 `smoke.start_cmd` / `ready_url`
- E3：贡献 rule（按 frontmatter spec）
- E4：提供 declared contract

**这是关键区别**：v1 retro 要求 "adapter 多声明字段"（分散到 N 个 adapter 分别做），
v2 要求 "pl 新增抽象"（集中到一处做，所有 adapter 自动受益）。

---

## 4. 实验证据：trace 真的跑起来了

本 retro 过程中我用现有 `trace-emit.sh` + bash 手工调度，对两个 demo 真实跑了一遍 VERIFY + 模拟 SMOKE：

### demo-fastapi-users trace（14 事件）

```
examples/demo-fastapi-users/pipeline-output/trace/add-users-api.events.jsonl
```

包括：VERIFY 阶段（lint/compile/test）+ SMOKE 阶段（boot/ready/4 probe 全绿）。

### demo-nextjs-todo trace（10 事件）

```
examples/demo-nextjs-todo/pipeline-output/trace/add-todo-list.events.jsonl
```

包括：VERIFY（tsc） + SMOKE（next build 7s，First Load JS 测量）。

**这证明**：

1. pl 现有的 trace 基础设施是足够的（trace-emit.sh + jsonl 落盘）
2. 缺的不是"能力"，而是**统一的调度协议 + gate↔check 闭环规则**
3. 一旦把 E1/E2 的协议做出来，所有 adapter **自动**产生这类 trace

---

## 5. 对 ROADMAP 的重新排布

v1 retro 把 6 个方案都塞到 v0.2。v2 retro 按"改动谁"重新分类：

### v0.2（pl-core 本体）—— 必做
- **E1** 门禁-检查-执行协议（GateDefinition / CheckDefinition 数据模型）
- **E2** SMOKE 阶段规范 + `pl-runner.sh` 调度脚本
- 把 `pipeline-orchestrator.sh` 里硬编码的 `agent:migration-*` 改为 adapter 可配置
- 把 `pl/config.yaml` 里硬编码的 `gradle` / `ApiSelfCheck` 删掉

### v0.2（piao-kernel 本体）—— 必做
- **E4** `piao-contract-drift-compute.sh`

### v0.3（pl-core 本体）—— 可选
- **E3** rule-as-code 引擎（对应原 `pl-code-scan.sh` 方案，但归属改为 pl-core）

### v0.2（adapter 适配）—— 次要
- adapter.yaml schema 版本从 `pl.dev/v1` → `pl.dev/v1.1`，新增：
  - `build_adapter.smoke.{start_cmd,ready_url,probes}`
  - `requires.peer_versions`
  - `rules[].engine` / `rules[].spec`（如 E3 落地）
- 但这些都是 **pl 新抽象的消费侧**，不是"adapter 主动发起"

---

## 6. 真正要回答的哲学问题

> **adapter 是不是用来遮盖 pl 本体设计不足的？**

v1 retro 的倾向是"是，所以多让 adapter 做一点"。
v2 retro 的回答是"**不是，adapter 是 pl 抽象的消费方**。
pl 本体应该足够通用，让 adapter 只做填空题"。

判断标准：**如果一个能力要所有 adapter 都实现一遍，那它属于 pl-core 本体。**

按这个标准重新审视：
- 可执行 check → pl 本体（不能让每个 adapter 都自己造 `lint/test` 驱动协议）
- SMOKE 阶段 → pl 本体（不能让每个 adapter 自己定义"真启动"长啥样）
- rule 引擎 → pl 本体（不能让每个 adapter 自己实现一遍 ripgrep 调度）
- 契约漂移 → piao 本体（不能让每个 adapter 自己比对"声明 vs 实测"）

**→ 都是 pl/piao 本体责任，v1 retro 的分类错了。**

---

## 7. 沉淀清单

| 产物 | 位置 | 状态 |
|---|---|---|
| 真实 trace 示例 | `examples/demo-*/pipeline-output/trace/*.events.jsonl` | ✅ 已产出 |
| 本 retro | `docs/retros/2026-04-demo-first-run-retro-v2.md` | ✅ 本文 |
| v1 retro（misdiagnosis 归档） | `docs/retros/2026-04-demo-first-run-retro.md` | 保留 |
| ROADMAP v0.2 重排 | `ROADMAP.md` | ⏳ 下一步 |
| `pipeline-orchestrator.sh` 解耦 migration-* | `scripts/pipeline-orchestrator.sh` | ⏳ 下一步 |
| `pl/config.yaml` 清除宿主栈硬编码 | `assets/pl/config.default.yaml` | ⏳ 下一步 |
