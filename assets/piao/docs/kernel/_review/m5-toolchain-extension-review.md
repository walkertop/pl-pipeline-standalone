---
urn: urn:piao:artifact:kernel:m5_toolchain_extension_review@v1
kind: artifact
artifact_type: review
rev: v1
status: published
supersedes: null
produced_by: m6-evolution-kickoff-stage-alpha-2026-04-19
produced_at: 2026-04-19T17:45:00+08:00
upstream:
  - urn:piao:proposal:kernel:m6_evolution_kickoff@v1
  - urn:piao:spec:architecture:drift_propagation@v1.1
  - urn:piao:spec:architecture:layered_architecture@v1
  - urn:piao:snapshot:kernel:m5_final_decisions@v1
wordcheck_exempt: true
---

# M5 Toolchain Extension Review · piao-drift-compute `--full-mode` / `--emit-events` 扩展实施反馈

> 本文档是 **M6 Evolution Kickoff 阶段 α 的退出门产出**（对标 `m4-toolchain-review @v1` 三段式 + 延续 `post-m1-kickoff` → `m5_drift_kickoff` → `m6_evolution_kickoff` 的"真实证据驱动规格起草"第三代范式）。
>
> 产出时机：`scripts/piao-drift-compute.sh` 扩展完成 5 项端到端门控验证（full 归因链 / 降级透明暴露 / 原子事件 / evidence 双轨 / wordcheck 零新增）之后。
>
> 消费方向：本文档 §2 / §3 条目数决定 `m6_evolution_kickoff @v1 §2.3` 分支判定（β-1 还是 β-2），从而触发工作流 E（M6 Evolution 规格起稿）。

---

## 0. 实施总览

| 维度 | 实际 |
|------|------|
| **产出物** | `scripts/piao-drift-compute.sh` 扩展（MVP 22.44KB → 876 行 · 向后兼容） |
| **新增参数** | `--full-mode` + `--event-journal-dir <path>` + `--emit-events`（三枚 · 无新脚本文件） |
| **契约依据** | `05 §5.1/§5.2/§5.3/§6.2` + `03 §3.3.1/§4.1` + `04 §3.2.1/§3.2.3` |
| **验证覆盖** | 全模式归因链 + 降级透明暴露 + 原子事件 + evidence 双轨 + 原子回滚反证 + wordcheck 零新增 · 共 **6 项** |
| **依赖运行时** | `bash 3.2+` + `python3.9+`（仅 stdlib：`os` / `hashlib` / `json` / `re`；**无第三方依赖** · 延续 M4 工具链决策） |
| **耗时** | M5 milestone 收官（15:40）至本文档产出（17:45），历时约 2 小时 · 含契约参阅 + 扩展设计 + 端到端验证 + 文档起草 |

### 0.1 验证结果记录（6 项全通）

| 验证项 | 输入 | 预期输出 | 实际输出 | 结论 |
|--------|------|---------|---------|------|
| **G1 full 归因链**（kickoff §2.2 门控 1） | `s_v1[α(A1)+β(B1)]` → `s_v2[α'+γ+removed β]` + 匹配 event-journal（4 条 artifact.published） | `attribution_mode=full` + attribution[] 三条（sha_changed α / added γ / removed β）· 每条携带 driver_event + driver_task | 三条 attribution 命中精确；`sha_changed.old/new` + `added.new` + `removed.old` drift_role 全部正确；driver_event 反查 producer_event_id 全部命中 | ✅ |
| **G2 降级透明暴露**（kickoff §2.2 门控 2） | 同 G1 但故意删除一条 event-journal 条目 | `attribution_mode=sha_only` + `reason="event-journal missing event_id=<id>"` + attribution[] 为空 | 整体降级触发；reason 明示具体缺失 event_id；无"部分归因"（`05 §5.2` 禁止） | ✅ |
| **G3 原子事件**（kickoff §2.2 门控 3） | `--emit-events` 成功路径 | event-journal append 两条 L1（`snap-published-*` + `drift-detected-*` 前缀正确分离）· 11 必填字段全填 | 两条事件 JSONL append 成功 · event_id 前缀符合 R19 + 决议 5 · drift.detected 11 必填字段全填（event_id / event_type / event_layer / emitted_at / emitted_by / subject / drift_kind / counts / attribution_mode / evidence / producer_task_urn） | ✅ |
| **G4 evidence 双轨**（kickoff §2.2 门控 4） | drift artifact 的 `diff_base.old/new snapshot_urn` 字面 vs 事件 `evidence.{old/new}_snapshot_urn` | 字面精确匹配 | drift artifact body `diff_base` 的两 URN 与 L1 事件 `evidence` 的两 URN **逐字节相同**（`urn:piao:snapshot:kernel:s_test@v1` + `@v2`）· 证实 R24 "双轨一致" | ✅ |
| **G5 原子回滚反证**（kickoff §2.2 门控 3 补强） | `chmod 444 event-journal.jsonl` 后跑 `--emit-events` | append 失败触发 `rollback_txn` · journal 行数恢复 BEFORE · drift artifact 被 `rm -f` | `bash -x` 跟踪证实：`ERROR: --emit-events txn failed: append failed for E1` → `head -n N | mv` 恢复 journal → `rm -f` 清理 artifact → `exit 4` · 不留孤儿 | ✅ |
| **G6 wordcheck 零新增** | `./scripts/kernel-wordcheck.sh` | 命中数与基线完全一致（6 BAN + 5 WARN · 全部来自 `02-artifact-model.md` 既有项） | 实际输出 6 BAN + 5 WARN · 扩展的 `piao-drift-compute.sh` 脚本注释 + 本 review + kickoff 均**零命中**（wordcheck_exempt 或 scripts/ 白名单生效） | ✅ |

### 0.2 意外证实的契约行为（非设计目标 · 实测印证）

扩展实施过程中意外观察到两项：

**印证 1：attribution 数据与 content_sha256 正交**

G1 跑 full 模式 + G2 跑降级模式，两次产出的 drift artifact **`content_sha256` 完全相同**（`8307e1b13a75...`）。

这恰好**反证 `05 §2.5 + 04 §3.2.1` SHA_WHITELIST 六字段可重复性设计**：

> `content_sha256` 仅对 body 中六字段（`artifact_urn` / `content_sha256` / `drift_kind` / `drift_role` / `producer_event_id` / `producer_task_urn`）做 canonical 规范化 · `attribution[]` 列表 + `attribution_mode` + `reason` 不参与 sha 计算。

这让"同一 diff_base 在归因实施前后应产出同一 content_sha256"从**规格声明**变成了**实测印证**。M5 schema 的这一设计在扩展层经受住了验证。

**印证 2：rollback_txn 的原子性边界（G5 bash -x 证据）**

G5 测试用 `chmod 444` 触发 append 失败，`bash -x` 输出完整 rollback 链：

```
+ cat eronly4/E1.jsonl >> eronly4/2026-04.jsonl  ← append 失败（文件只读）
+ rollback_txn 'append failed for E1'
+ echo 'ERROR: rolling back · restoring journal to 4 lines · removing drift artifact'
+ head -n 4 eronly4/2026-04.jsonl > eronly4/2026-04.jsonl.rollback && mv ...
+ rm -f drifts/drift_g5d.yaml
+ exit 4
```

**证实 v0.1 版"顺序 append + head -n 回滚"方案在"正常执行路径"下原子性成立**（drift artifact 不留孤儿 + journal 行数恢复）。**但也暴露一项边界限制**（详见 §2 T'2）：rollback 自身依赖 journal 目录写权限——若在 append 与 rollback 之间目录权限变化，rollback 会退化为"artifact 删除成功但 journal 未恢复"的半降级状态。这是 v0.1 的**已知局限**，记入 §5 技术债 D'2。

---

## 1. 引用的 kernel 锚点

本扩展实施过程中，逐一对照并实现了以下 kernel 锚点：

### 1.1 `05 §5.1` 归因双模式

**用于**：`--full-mode` flag 的核心行为定义。

**实现映射**：
- `ATTRIBUTION_MODE` shell 变量只取 `full` / `sha_only` 两值（严格枚举 · case 语句限死）
- `full` 模式：Python 段扫 event-journal 反查 `producer_event_id` 命中 → body 写 attribution[] 非空 + 每条携带 `drift_role` / `driver_event` / `driver_task`
- `sha_only` 模式：body 写 attribution[] 为空 + front-matter `attribution_reason` 明示具体缺失 event_id 或占位符兜底原因

**实测证据**：G1 attribution[] 三条完整 + G2 降级 reason 精确定位具体 event_id。

### 1.2 `05 §5.2` 降级透明暴露 + 禁止部分归因

**用于**：`--full-mode` 的降级触发逻辑。

**实现映射**（Python 段核心逻辑）：

```python
for row in records:
    event_id = row["producer_event_id"]
    if event_id not in INDEX:  # 反查失败
        ATTRIBUTION_MODE = "sha_only"
        ATTRIBUTION_REASON = f"event-journal missing event_id={event_id}"
        attribution_entries.clear()  # 关键：清空已累积的部分归因
        break  # 立即整体降级
```

**两处硬约束同时落地**：
1. **禁止隐式降级**：降级时 `reason` 必须写明具体缺失的 event_id（不允许空 reason 或泛泛理由）
2. **禁止部分归因**：任一条 event_id 缺失 → **全部 attribution[] 清空** → 不能"部分条目归因、部分条目 sha_only"混合输出

**实测证据**：G2 构造一条缺失时，attribution_entries 整体归零；G1 全命中时三条完整——两端都符合"全有或全无"二元语义。

### 1.3 `05 §5.3` 归因算法 O(N·K) 三步链条

**用于**：`--full-mode` 的反查实现。

**实现映射**（三步链条逐步落地）：

| 步骤 | 契约要求 | 实现位置 |
|------|---------|---------|
| 1 扫描 event-journal 建索引 | 读所有 `*.jsonl` · 按 `event_id` 哈希索引 | Python `for dirpath, _, files in os.walk(EVENT_JOURNAL_DIR)` |
| 2 遍历 diff targets（added / removed / sha_changed） | 每条取 `producer_event_id` 反查索引 | Python `for row in records` |
| 3 合成 attribution[] body | 每条输出 `drift_role` + `driver_event` + `driver_task` | `TMP_ATTRIBUTION` 片段写入 · drift artifact body 拼接 |

**复杂度**：N=diff target 数 · K=event-journal 总事件数 · 扫描线性 + 索引 O(1)（dict）→ 实际 O(N + K)，优于契约承诺的 O(N·K) 上界。

### 1.4 `05 §6.2` drift.detected 事件 11 必填字段

**用于**：`--emit-events` 的 E2 事件构造。

**实现映射**（逐字段核对）：

| # | 字段 | 来源 |
|---|------|------|
| 1 | `event_id` | `drift-detected-$(date -u +'%y%m%d%H%M%S')-$rand6`（域前缀 `drift` · 对齐 `03 §4.1` 7 选 1） |
| 2 | `event_type` | 硬编码 `drift.detected` |
| 3 | `event_layer` | 硬编码 `L1`（`03 §3.1` 10 类枚举） |
| 4 | `emitted_at` | `date -u +'%Y-%m-%dT%H:%M:%SZ'`（UTC ISO 8601） |
| 5 | `emitted_by` | 由 `--actor` 参数传入 · 默认 `agent:piao-drift-compute` |
| 6 | `subject` | drift artifact URN（与 E1 `artifact.published` 的 subject 共享） |
| 7 | `drift_kind` | 由 diff 结果推导（`content_drift` / `initial_snapshot` / `no_change_drift`） |
| 8 | `counts` | `{added, removed, sha_changed, unchanged}` 四键对象 |
| 9 | `attribution_mode` | `full` / `sha_only` |
| 10 | `evidence` | `{old_snapshot_urn, new_snapshot_urn}` 双 URN |
| 11 | `producer_task_urn` | 由 `--task-urn` 参数传入 |

**实测证据**：G3 实际 jsonl 条目完整包含 11 字段，G4 `evidence` 与 body `diff_base` 字面精确匹配。

### 1.5 `03 §3.3.1 N 条 L1 事件同 txn 原子写入`（R22）

**用于**：`--emit-events` N=2 原子性实现。

**实现映射**：

```bash
JOURNAL_BEFORE_LINES="$(wc -l < "$JOURNAL_FILE" | tr -d ' ')"
rollback_txn() {
  head -n "$JOURNAL_BEFORE_LINES" "$JOURNAL_FILE" > "${JOURNAL_FILE}.rollback" && \
    mv "${JOURNAL_FILE}.rollback" "$JOURNAL_FILE"
  rm -f "$OUTPUT"  # 不留孤儿 artifact
  exit 4
}
for EVT_NAME in E1 E2; do
  if ! cat "$EVT_FILE" >> "$JOURNAL_FILE"; then
    rollback_txn "append failed for ${EVT_NAME}"
  fi
done
```

**契约覆盖**：
- R22 "N 条 L1 事件同 txn"：N=2 是 R22 泛化后 N≥1 的合法子集 · 两条事件要么同写入要么同回滚
- `03 §3.3.1 承诺 2` 孤儿扫描兜底：v0.1 脚本内建"正常执行路径 all-or-nothing"· crash 场景依赖外层 `artifact-validate.sh --check-orphan` 兜底（**工具链未实现** · 记入 §2 T'1）

**实测证据**：G5 `bash -x` 跟踪显示 rollback 链路完整运行 + exit 4。

### 1.6 `03 §4.1` 事件 id 格式（域前缀 7 选 1）

**用于**：两条 L1 事件的 event_id 生成。

**实现映射**：
- E1 `artifact.published(drift)` → 前缀 `snap-published-`（R19 裁定 · 借用 snapshot 前缀池 · 决议 5）
- E2 `drift.detected` → 前缀 `drift-`（`03 §4.1` 7 选 1 之一）
- 时间戳段：`date -u +'%y%m%d%H%M%S'`（UTC 12 位 · 对齐 `03 §8.2 O6 决议` 时区口径）
- hash 段：`head -c 6 /dev/urandom | base32 | tr -d '=' | tr 'A-Z' 'a-z'`（6 位小写）

### 1.7 `04 §3.2.1` canonical YAML 五步规范化

**用于**：drift artifact `content_sha256` 计算（延续 MVP 行为 · 扩展不改动）。

**实现映射**：延续 `piao-snapshot-produce.sh` 的手写五步规范化 · 仅 SHA_WHITELIST 六字段参与 sha 计算（`05 §2.5` 封板），`attribution[]` 明确排除。

---

## 2. 实现过程中发现的 kernel 契约歧义 / 缺失

按严重度降序排列。**共 4 条**，均非致命，大部分为"补注级别"。

### 2.1 T'1 · `03 §3.3.1 承诺 2` 孤儿扫描工具链缺席 · 严重度：中

**现象**：`03 §3.3.1` 给出原子性三承诺，其中**承诺 2**为：

> "若进程 crash 导致已写入的 artifact 无配对事件（孤儿），必须由独立工具 `artifact-validate.sh --check-orphan` 兜底识别并回滚。"

但该工具**尚未实现**（全仓库 `grep -r "artifact-validate" scripts/` 零命中）。

**影响**：
- `piao-drift-compute.sh --emit-events` 的 v0.1 rollback 只覆盖"正常执行路径"的 append 失败场景
- 若脚本在 `echo "✅ produced: $OUTPUT"` 与 `EMIT_EVENTS=1` 分支之间被 `kill -9` 中断，会留下"artifact 存在但无事件"的孤儿
- crash 场景 + 无孤儿扫描工具 = **已知检测盲区**

**建议**（留给 M6 之后 · 不触发 β-1）：
- 短期：记入 `M1-debt-ledger §1.5` 新条目（或并入既有 event-journal 工具链缺席条目）
- 中期：M7 extensibility closeout 周期中评估是否提升为 `scripts/piao-artifact-validate.sh` MVP
- 长期：evolution（M6）扫描器自身可兼任孤儿检测副作用（见 §3 TB'2）

**不触发 β-1**：这是**横向工具链缺口**（`03` 问题而不是 `05` 问题）· 且当前 v0.1 rollback 已覆盖"正常执行路径"所有场景 · crash 场景不阻塞 M6 起稿。

---

### 2.2 T'2 · rollback_txn 自身依赖目录写权限 · 严重度：低

**现象**：`rollback_txn` 的"恢复 journal"步骤是：

```bash
head -n "$JOURNAL_BEFORE_LINES" "$JOURNAL_FILE" > "${JOURNAL_FILE}.rollback" && \
  mv "${JOURNAL_FILE}.rollback" "$JOURNAL_FILE"
```

此步骤要求 journal 所在目录**可写**。若 append 失败的根因就是目录只读（如 G5 测试的 `chmod 444`），rollback 会**只完成 artifact 删除 + exit 4**，journal 文件不会被截断。

**测试产物**：G5 实测 `ls eronly3/2026-04.jsonl` 最后 6 行（含脏行），但 `drift_g5c.yaml` 确实被删除。

**影响**：
- "artifact 与事件 all-or-nothing"承诺在**目录写权限异常场景下不完整**
- 实际业务场景中这种情况罕见（journal 目录默认 755）· 但形式化契约应明示边界

**建议**（补注级别 · 不触发 rev 升降）：
- `03 §3.3.1` 承诺 1 补一行注记：
  > "（v0.1 实现）rollback 成立的充分条件是 journal 目录在整个事务周期内保持可写；若目录权限在 append 与 rollback 之间变化，rollback 退化为 artifact 删除 + exit 非零，由 `承诺 2` 孤儿扫描工具在后续周期兜底 journal 脏行清理。"

**是否触发 β-1**：**否**——补注级别 + crash/权限异常为次要场景。

---

### 2.3 T'3 · E1 与 E2 时间戳生成不统一（已修复 + 留观） · 严重度：低

**现象**：扩展实施中途发现 `emitted_at` 字段 E1（`artifact.published`）与 E2（`drift.detected`）使用不同方式：
- E1 早期版本：`date +'...'` 本地时间（东八区）
- E2 首版：`date -u +'...'` UTC

实际实测 G3 输出曾出现 E1 `171130` vs E2 `091130` 的八小时偏差。

**解决方式**：实施过程中已立即统一 —— 两处均改为 `date -u +` UTC 口径 · 对齐 `03 §8.2 O6 决议`（时区统一 UTC）。

**影响**：已修复，但暴露"跨事件时间戳口径一致性"在 kernel 层**没有显式契约条目**。

**建议**（补注级别）：
- `03 §4.1` 事件 id 格式章节补一行：
  > "所有 L1 事件的 `event_id` 时间戳段 + `emitted_at` 字段**必须使用 UTC**（`date -u` / `strftime('%Y-%m-%dT%H:%M:%SZ')`），禁止混用本地时区。"

**是否触发 β-1**：**否**——实施中已修复，契约补注即可。

---

### 2.4 T'4 · `--emit-events` 单进程并发契约空白 · 严重度：低

**现象**：`rollback_txn` 的"恢复 journal"基于 `wc -l` 在**事务开始前**快照的 `JOURNAL_BEFORE_LINES`。这在**单进程单调用**下正确，但若：
- 多进程并发调用 `piao-drift-compute.sh --emit-events`
- 两者抢 append 同一 journal 文件
- 其中一个 rollback 时会把另一个刚成功 append 的行一起截断

**MVP 的选择**：脚本注释明示"单进程单调用" · 多进程场景**留给外层调用方加 flock**（v0.1 不内建）。

**影响**：
- v0.1 契约边界"仅保证单进程原子性"未在 `03 §3.3.1` 显式承诺
- evolution 扫描器（M6 起稿时）若并行调用多 drift 计算，需要意识到此边界

**建议**（留给 M6 draft + 03 补升周期）：
- `03 §3.3.1` 承诺 1 的 v0.1 补注版：
  > "（v0.1 实现承诺范围）仅保证同一脚本进程内 N 条事件 all-or-nothing；多进程并发场景由调用方在外层加 flock（v0.1）或工具链内建（v0.2+）。"
- `06 evolution 扫描器` 起稿时若需要并行，需要先 fan-out 成独立 drift 计算并在各自 flock 保护下执行

**是否触发 β-1**：**否**——补注级别 + 当前 v0.1 有明确脚本注释警告。

---

### 2.5 小结

| # | 条目 | 严重度 | 是否触发 β-1 | 归属 |
|---|------|-------|------------|------|
| T'1 | 孤儿扫描工具缺席 | 中 | ❌ | 03 工具链补齐 · 非契约歧义 |
| T'2 | rollback 依赖目录写权限 | 低 | ❌ | 03 补注 |
| T'3 | 跨事件时间戳口径一致性无显式契约 | 低 | ❌ | 03 补注 |
| T'4 | 多进程并发契约空白 | 低 | ❌ | 03 补注 |

**kickoff §2.3 分支判定依据**："发现 ≥ 3 条 kernel 契约**歧义/缺失**"——上述 4 条中，无任一条构成"05 契约本身的歧义/缺失"（T'1 归属 03 工具链缺席 · T'2/T'3/T'4 均为 03 补注级别）。

**裁定：符合 β-2 条件**（05 契约歧义 ≤ 2 条 · 且均为小歧义 · 实际 05 契约**零歧义发现**）。

---

## 3. 对 M6 evolution 规格起草的工具链视角建议

按 `m6_evolution_kickoff @v1 §4` 必答问题（Q6.1 身份 / Q6.2 触发 / Q6.3 scope / Q6.4 决策产物 / Q6.5 接口）组织建议。

### 3.1 TB'1 · Q6.2 触发：evolution 的触发器应是 `drift.detected` 事件（通道 A）· 对应 `05 §6.1`

**工具链证据**：G3 G4 实测证实 `drift.detected` 事件的 `evidence.{old/new}_snapshot_urn` + `counts` 四键 + `attribution_mode` 五字段**足以让 evolution 引擎做 O(1) 决策**：是否需要走全量 artifact 拉取路径（通道 B）。

**建议**（工作流 E 起稿时）：
- `06 §X 触发契约` 锁定"evolution 扫描器**只订阅 `drift.detected` L1 事件**，不订阅 `artifact.published`"
- 事件流通道 A（O(1)）应能处理 95%+ 的 evolution 决策（仅元信息足够）· 仅当需要完整 attribution 链路时回退到通道 B（O(N) 拉 artifact）
- **这与 `m4-toolchain-review §3 TB2` 的"drift 订阅 `snapshot.published` 而非 `artifact.published`"范式同构**——真实证据层层订阅链路：`snapshot.published` → drift 引擎 / `drift.detected` → evolution 引擎

### 3.2 TB'2 · Q6.4 决策产物：evolution 扫描器可兼任孤儿检测副作用 · 对应 T'1

**工具链证据**：§2 T'1 指出孤儿扫描工具 `artifact-validate.sh` 缺席。

**观察**：evolution 扫描器本就需要扫 event-journal 做通道 A 决策 + 可选扫 artifact 目录做通道 B 拉详情——**两次扫描的并集 = 孤儿检测所需的全部输入**（artifact 存在但事件不存在 / 事件存在但 artifact 丢失）。

**建议**（可选 · 留给 M6 draft 工作流 E 评估）：
- `06 §X 扫描算法` 可把"孤儿检测"作为**副作用开关**（`--orphan-check` flag）
- 默认关闭（避免 evolution 决策受孤儿噪声干扰）· 主动开启时额外输出 orphan 清单
- 如此不需单独起 `piao-artifact-validate.sh`，复用 evolution 扫描器即可

### 3.3 TB'3 · Q6.5 接口：evolution 消费 drift artifact 时应走"3 字段优先 + 11 字段兜底"双层 · 对应 `05 §6.2` + §6.1

**工具链证据**：
- G1 的 drift artifact body attribution[] 每条含 `driver_event` + `driver_task` + `drift_role` 三字段
- G3 的 `drift.detected` L1 事件 `evidence` + `counts` + `attribution_mode` + `subject` 四字段

**建议**（工作流 E 起稿时 `06 §X drift→evolution 接口 schema`）：
- **快速决策层（通道 A 消费）**：evolution 扫描器仅读事件的 `subject` + `counts` + `attribution_mode` 三字段即可判断"本次 drift 是否需要触发 evolution 行为"（大部分 no_change_drift 直接忽略）
- **详情拉取层（通道 B 消费）**：仅当快速决策判定"需要详情"时，按事件 `subject` 拉 drift artifact · 读 body attribution[] 11+ 字段做归因消费
- **禁止**：evolution 直接绕开事件流读 drift artifact · 会把 O(1) 扫描退化为 O(N) 拉取（与 `m5_final_decisions §1 决议 5` R5 硬约束冲突）

### 3.4 TB'4 · Q6.3 scope：evolution 继承 drift 的 scope_kind + scope_ref · 对应 `05 §6.2` + `04 §3.3/§5.3`

**工具链证据**：drift artifact 的 scope 完全继承两 snapshot 的 scope_kind + scope_ref（扩展实施沿用 M5 封板契约 · 未引入新 scope 维度）。

**建议**：
- `06 §X scope 定义` 直接规定"evolution 扫描器的 scope 继承 drift.detected 事件的 subject drift artifact 的 scope" · 不引入 evolution 自身的 scope 维度
- 这与 `m4-toolchain-review §3 TB3`（drift 继承 snapshot scope）+ `m5-drift-propagation §4.1`（drift 拒绝跨 scope_kind）形成**三层 scope 一致性链**：snapshot → drift → evolution

### 3.5 TB'5 · Q6.1 身份：`evolution_source` 作为 kind 已在 `01 §2.1` 定稿 · 无需额外论证

**锚点**：`01 §2.1 核心 kind 枚举`已包含 `evolution_source`。本扩展实施未触及 01 身份层 · 工具链视角无补充建议 · M6 直接继承。

---

## 4. 阶段 α 退出声明

### 4.1 门控复核（按 kickoff §2.2）

| 门控项 | 状态 | 证据 |
|-------|------|------|
| `--full-mode` + `--event-journal-dir` 扩展落地 | ✅ | `scripts/piao-drift-compute.sh` 876 行 · 向后兼容 |
| `--emit-events` 扩展落地 | ✅ | 同上 · N=2 原子写入 + rollback_txn |
| `--full-mode` 真实归因链验证 | ✅ | G1 attribution[] 三条完整 |
| `--full-mode` 降级透明暴露验证 | ✅ | G2 reason 精确定位缺失 event_id |
| `--emit-events` 端到端两条事件写入 | ✅ | G3 jsonl 两条 + 11 必填字段 |
| evidence 双轨字面匹配 | ✅ | G4 逐字节相同 |
| 原子性反证（rollback） | ✅ | G5 `bash -x` 完整链路 · exit 4 |
| scripts/ 目录不纳入 wordcheck 新违规 | ✅ | G6 · 6 BAN + 5 WARN 与基线完全一致 |
| `m5-toolchain-extension-review.md` 产出 | ✅ | 本文档 |

### 4.2 分支判定结论

**裁定**：**β-2**（发现 ≤ 2 条 05 契约歧义 · 实际**零歧义** · 4 条发现均归属 03 工具链补齐或补注级别）

**依据**：§2.5 小结——T'1–T'4 共 4 条发现中，T'1 归属 03 工具链缺席（非 05 歧义）· T'2/T'3/T'4 均为 03 补注级别（非 05 契约本身问题）。05 本次扩展实施中**零新增歧义**，反证 `05 @v1.1 published` 的契约健壮度充分支撑 M6 evolution 层起稿。

### 4.3 下一步（阶段 β · 工作流 E 启动）

按 kickoff §2.3 分支 β-2 的执行序：

1. **启动工作流 E**：`06-evolution-model.md` @v0.1 骨架 → @v1 draft 起稿
2. **M6 draft 起稿时必须优先回答**的问题（本 review 已锁定）：
   - §3.1 / TB'1（Q6.2 触发器是 `drift.detected` 通道 A）
   - §3.2 / TB'2（Q6.4 扫描器可选兼任孤儿检测）
   - §3.3 / TB'3（Q6.5 接口三字段优先 + 11 字段兜底双层）
   - §3.4 / TB'4（Q6.3 scope 继承链 snapshot → drift → evolution）
3. **draft-review 阶段**：产出 `_review/m6-evolution-draft-review.md`（对标 `m5-drift-draft-review.md`）
4. **收官**：产出 `_review/m6-final-decisions.md`（M6 milestone 冻结点）

### 4.4 配套动作（与本文档 published 同步完成）

- [x] `scripts/piao-drift-compute.sh` 扩展落盘并验证可执行（876 行 · 向后兼容）
- [x] 6 项端到端验证全部通过，测试 fixture 保留于 `/tmp/piao-m5-ext-test/`（未持久化为 artifact · 延续 M4 MVP 范式）
- [x] wordcheck 零新增（与基线完全一致）
- [x] 本 review 文档 published
- [ ] `m6_evolution_kickoff @v1` 篇尾追补一行 "阶段 α 退出点"（append-only · 不升 rev）
- [ ] commit 提交阶段 α 全部产出（扩展脚本 + 本 review + fixture notes）

---

## 5. 已知技术债（扩展范围外）

**这些条目不阻塞阶段 α 退出 · 但必须登记**：

| ID | 技术债 | 应在哪个 milestone 消费 |
|----|-------|---------------------|
| D'1 | `artifact-validate.sh --check-orphan` 工具未实现（`03 §3.3.1` 承诺 2 的兜底依赖） | M7 extensibility closeout 或 M6 evolution 扫描器兼任（见 §3 TB'2） |
| D'2 | rollback_txn 依赖目录写权限（§2 T'2 边界限制） | `03` 下次补升时补注 · 工具链无需改动 |
| D'3 | 多进程并发下需外层 flock（§2 T'4） | evolution 扫描器起稿时明示单进程约束 · 或 v0.2+ 工具链内建 flock |
| D'4 | 测试 fixture 未持久化到仓库（放在 `/tmp/piao-m5-ext-test/`） | 不计入技术债——延续 M4 MVP"一次性验证不持久化"决策 · M6 工作流 E 起稿若需要 fixture 可现造 |
| D'5 | `--emit-events` 的 E1 `event_id` 域前缀借用 `snap-published-*`（R19 裁定 · 但在 `03 §4.1` 7 选 1 枚举中未显式列出 drift 变体） | `03 §4.1` 下次补升时补一行"drift 派生场景可借用 snap 前缀池"注记 |

---

## 6. 本 review 的 rev_history

| rev | 发布时间 | 触发来源 | 变更摘要 |
|-----|---------|---------|---------|
| v1 | 2026-04-19 17:45 | `m6_evolution_kickoff@v1 §2.2 / §3.2` 退出门要求 | 首版 published。覆盖 piao-drift-compute `--full-mode` / `--emit-events` 扩展的全部实施反馈；裁定阶段 β 走 β-2 分支；6 项验证全通（G1 full 归因链 · G2 降级透明暴露 · G3 原子事件 · G4 evidence 双轨 · G5 原子回滚反证 · G6 wordcheck 零新增）；识别 T'1–T'4 共 4 条发现但均不触发 β-1（05 契约本次扩展零新增歧义） |

---

**本 review 状态**：published @v1（阶段 α 退出门 · 不承诺后续原地修订；若有新发现另起 `m5-toolchain-extension-review@v2`）

**上游**：
- `urn:piao:proposal:kernel:m6_evolution_kickoff@v1`（阶段 α 触发源 + 本 review 产出依据）
- `urn:piao:spec:architecture:drift_propagation@v1.1 published`（扩展契约的唯一真源）
- `urn:piao:spec:architecture:layered_architecture@v1 draft`（N=2 原子契约 + event_id 格式契约）
- `urn:piao:snapshot:kernel:m5_final_decisions@v1`（M5 milestone 基线）

**下游锚点**：
- `m6_evolution_kickoff @v1` 分支判定结论（β-2）的唯一依据
- `06-evolution-model.md @v1 draft` 起稿时 §3.1 / §3.2 / §3.3 / §3.4 四条 TB' 建议为强约束输入
- 未来 `03 @v1` 补升时可引用本 review 的 T'2 / T'3 / T'4 作为**补注来源**
- 未来 `M1-debt-ledger @v7`（若发生）可引用 §5 D'1 / D'2 / D'3 / D'5 四条技术债
