#!/usr/bin/env bash
#
# piao-evolution-scan.sh — piao-pipeline evolution 扫描器 MVP
#
# 契约依据（唯一来源 · 快照即事实）：
#   - docs/piao-pipeline/kernel/_review/m6-final-decisions.md @v1 published
#     §1 六项决议：R1 双形态 / R2 唯一触发 drift.detected / R3 scope 完全继承 /
#                  R4 **纯观测 4-A** / R5 **终止于 scan_result 5-A** / R6 跨篇一致性
#     §4.1 MVP 前置清单（输入 / scope 继承 / 决策规则 / 输出 artifact / 输出事件 /
#                        双 event_id 前缀 / 原子写入 / 降级策略 / F1-F4 / G1-G5）
#     §4.3 Phase 2 启动依据
#   - docs/piao-pipeline/kernel/06-evolution-model.md @v1.1 draft
#     §2.3  evolution.scan_result schema（front-matter + body · 含 scan_base /
#           scanned_drifts[] / decisions[] / orphan_check）
#     §2.3  L1 evolution.scanned 事件 8 字段
#     §3.2  原子流程 E1-E5（E5: N=2+k 同 txn · k=0 in 4-A 纯观测）
#     §3.4  降级策略（E1/E3/E5/手动补救四场景）
#     §4    scope 硬约束 R3（完全继承 drift scope）
#     §6.2  L1 决策字段（4-A 纯观测下恒为 pass_through · 不读 counts/attribution_mode）
#   - docs/piao-pipeline/kernel/02-artifact-model.md @v1.4 published
#     §2.2.4 派生类型注册 evolution.scan_result（wordcheck_policy: machine_generated）
#   - docs/piao-pipeline/kernel/03-layered-architecture.md @v1 draft
#     §3.1   L1 事件 10 类枚举（含 artifact.published / evolution.scanned）
#     §3.3.1 N 条 L1 事件同 txn 原子写入契约（本脚本 N=2）
#     §4.1   事件 id 格式 <域>-<UTC12位>-<6位hash>
#
# 4-A + 5-A 语义锁定（final-decisions §1 决议 4/5）：
#   - 决策恒为单一态：`pass_through`（纯观测 · 不做 dispatch / pull_detail 分流）
#   - `decisions[]` 恒为空数组（不发 task.proposed / proposal.generated 下游事件）
#   - L1 evolution.scanned 事件 3 字段契约：drift_event_urn / scope_urn / decision
#   - N=2 硬约束：artifact.published(E) + evolution.scanned · k=0 不附加下游事件
#
# 使用范式（MVP 单档 · 默认 + --emit-events 二选一）：
#   # 基础通路：仅产 artifact · 不写事件
#   piao-evolution-scan.sh --drift-event-file drift-detected.jsonl \
#     --drift-artifact drift.yaml \
#     --name my_evolution --rev v1 --output evolution.yaml
#
#   # 完整通路：产 artifact + N=2 原子事件写入
#   piao-evolution-scan.sh --drift-event-file drift-detected.jsonl \
#     --drift-artifact drift.yaml \
#     --name my_evolution --rev v1 --output evolution.yaml \
#     --event-journal-dir pipeline-output/events \
#     --emit-events
#
# 命名空间：沿用 piao-drift-compute.sh / piao-snapshot-produce.sh 同簇前缀 `piao-`。
#

set -euo pipefail

# ==============================================================================
# 参数解析
# ==============================================================================

DRIFT_EVENT_FILE=""
DRIFT_ARTIFACT=""
NAME=""
REV=""
OUTPUT=""
TASK_URN="urn:piao:task:manual:piao_evolution_scan"
ACTOR="agent:piao-evolution-scan"
PRODUCED_AT=""
EVENT_JOURNAL_DIR=""
EMIT_EVENTS="0"

usage() {
  sed -n '2,60p' "$0"
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --drift-event-file)  DRIFT_EVENT_FILE="$2"; shift 2 ;;
    --drift-artifact)    DRIFT_ARTIFACT="$2"; shift 2 ;;
    --name)              NAME="$2"; shift 2 ;;
    --rev)               REV="$2"; shift 2 ;;
    --output)            OUTPUT="$2"; shift 2 ;;
    --task-urn)          TASK_URN="$2"; shift 2 ;;
    --actor)             ACTOR="$2"; shift 2 ;;
    --produced-at)       PRODUCED_AT="$2"; shift 2 ;;
    --event-journal-dir) EVENT_JOURNAL_DIR="$2"; shift 2 ;;
    --emit-events)       EMIT_EVENTS="1"; shift 1 ;;
    -h|--help)           usage ;;
    *) echo "ERROR: unknown arg: $1" >&2; usage ;;
  esac
done

# ==============================================================================
# 参数校验（按 final-decisions §4.1 前置清单）
# ==============================================================================

for var_name in DRIFT_EVENT_FILE DRIFT_ARTIFACT NAME REV OUTPUT; do
  if [[ -z "${!var_name}" ]]; then
    echo "ERROR: --$(printf '%s' "$var_name" | tr '[:upper:]' '[:lower:]' | tr '_' '-') is required" >&2
    exit 2
  fi
done

# 06 §7.1 + 05 §7.1 对齐：evolution artifact 不升次版
if [[ ! "$REV" =~ ^v[0-9]+$ ]]; then
  echo "ERROR: invalid rev: $REV (06 §7.1 evolution 不升 rev · 应形如 v1/v2/v3)" >&2
  exit 2
fi

[[ -f "$DRIFT_EVENT_FILE" ]] || { echo "ERROR: --drift-event-file not found: $DRIFT_EVENT_FILE" >&2; exit 2; }
[[ -f "$DRIFT_ARTIFACT" ]]   || { echo "ERROR: --drift-artifact not found: $DRIFT_ARTIFACT" >&2; exit 2; }

if [[ -z "$PRODUCED_AT" ]]; then
  PRODUCED_AT="$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
fi

if [[ "$EMIT_EVENTS" == "1" && -z "$EVENT_JOURNAL_DIR" ]]; then
  echo "ERROR: --emit-events requires --event-journal-dir <path> (03 §3.3.1 事件落点)" >&2
  exit 2
fi

# ==============================================================================
# 预留 event_id（06 §6.2 + final-decisions §1 决议 5 双前缀规约）
# ==============================================================================
# artifact.published(E) 事件 id 前缀：drift-triggered-*
# （语义：evolution artifact 是 drift.detected 驱动下的 artifact.published 派生）
# 对标 M5 drift artifact 的 snap-published-* 前缀范式（R19 裁定）
EVENT_ID="drift-triggered-$(date -u +'%y%m%d%H%M%S')-$(python3 -c 'import secrets,string;print("".join(secrets.choice(string.ascii_lowercase+string.digits) for _ in range(6)))')"

# ==============================================================================
# 调用 python3 解析 drift 事件 + drift artifact · 产出 scan_result meta/body
# ==============================================================================

TMP_META="$(mktemp)"       # scope + drift_urn + drift_event_id + scope_kind/ref
TMP_BODY="$(mktemp)"       # body canonical YAML（scan_base + scanned_drifts）
TMP_SHA_FILE="$(mktemp)"   # content_sha256 结果
trap 'rm -f "$TMP_META" "$TMP_BODY" "$TMP_SHA_FILE"' EXIT

python3 - \
  "$DRIFT_EVENT_FILE" "$DRIFT_ARTIFACT" \
  "$TMP_META" "$TMP_BODY" "$TMP_SHA_FILE" <<'PYEOF'
"""
piao-evolution-scan · python3 算子

步骤：
  1. 解析 drift.detected 事件 JSONL（读 subject / scope / counts / attribution_mode）
  2. 解析 drift artifact yaml（front-matter · 提取 drift URN / scope_kind / scope_ref）
  3. 校验 scope 一致性（final-decisions R3：E.scope == D.scope · 6 §4.1）
  4. 决策恒为 pass_through（final-decisions R4 · 4-A 纯观测 · 不读 counts/attribution_mode
     做分流 · 仅用于透传到 scanned_drifts[] 记录）
  5. 按 06 §2.3 schema 产出 scan_base + scanned_drifts[] canonical YAML body 片段
  6. content_sha256 计算（对齐 04 §3.2.3 通用契约 · SHA_WHITELIST = scan_base +
     scanned_drifts[] · 不含 orphan_check 因 MVP 默认关闭）
  7. 产出 meta KEY=VALUE 供 bash 端拼接 front-matter

退出码：
  0 = 成功
  1 = scope 不一致（final-decisions R3 违反 · 对应 SMOKE 3）
  2 = 事件 / artifact 解析失败 / 必填字段缺失
"""
import sys, os, re, json, hashlib

DRIFT_EVENT_PATH = sys.argv[1]
DRIFT_ARTIFACT_PATH = sys.argv[2]
OUT_META = sys.argv[3]
OUT_BODY = sys.argv[4]
OUT_SHA = sys.argv[5]

# ------------------------------------------------------------------------------
# 1. drift.detected 事件解析（JSONL · 单行单事件）
# ------------------------------------------------------------------------------

try:
    with open(DRIFT_EVENT_PATH, "r", encoding="utf-8") as f:
        # 支持两种输入格式：
        #   a) 单行 JSON（最常见 · MVP 默认路径）
        #   b) JSONL 多行但仅取第一行 event_type=drift.detected 的记录
        event = None
        for line in f:
            line = line.strip()
            if not line:
                continue
            obj = json.loads(line)
            if obj.get("event_type") == "drift.detected":
                event = obj
                break
        if event is None:
            sys.stderr.write(f"ERROR: no drift.detected event found in {DRIFT_EVENT_PATH}\n")
            sys.exit(2)
except json.JSONDecodeError as e:
    sys.stderr.write(f"ERROR: invalid JSON in {DRIFT_EVENT_PATH}: {e}\n")
    sys.exit(2)

# 05 §6.2 必填字段（本 MVP 只消费 subject / scope · 其他字段透传归档）
drift_urn = event.get("subject", "")
drift_event_id = event.get("event_id", "")
if not drift_urn or not drift_urn.startswith("urn:piao:drift:"):
    sys.stderr.write(f"ERROR: drift.detected.subject is not a drift URN: {drift_urn!r}\n")
    sys.exit(2)
if not drift_event_id or not drift_event_id.startswith("drift-detected-"):
    sys.stderr.write(f"ERROR: drift.detected.event_id format invalid: {drift_event_id!r}\n")
    sys.exit(2)

# 4-A 纯观测模式：counts / attribution_mode 仅作归档字段 · 不参与决策分流
counts = event.get("counts", {}) or {}
attr_mode = event.get("attribution_mode", "")

# ------------------------------------------------------------------------------
# 2. drift artifact front-matter 解析（提取 scope_kind / scope_ref）
# ------------------------------------------------------------------------------

try:
    with open(DRIFT_ARTIFACT_PATH, "r", encoding="utf-8") as f:
        text = f.read()
except OSError as e:
    sys.stderr.write(f"ERROR: cannot read drift artifact: {e}\n")
    sys.exit(2)

if not text.startswith("---\n"):
    sys.stderr.write(f"ERROR: {DRIFT_ARTIFACT_PATH}: no front-matter\n")
    sys.exit(2)
end = text.find("\n---\n", 4)
if end < 0:
    sys.stderr.write(f"ERROR: {DRIFT_ARTIFACT_PATH}: front-matter unterminated\n")
    sys.exit(2)
fm_text = text[4:end]

def extract_fm_field(key):
    m = re.search(rf'^{re.escape(key)}:\s*(.+?)$', fm_text, re.MULTILINE)
    return m.group(1).strip().strip('"') if m else ""

drift_artifact_urn = extract_fm_field("urn")
# 06 §4.1 R3：scope_kind + scope_ref 继承自 drift artifact
# drift artifact front-matter 按 05 §2.3 含 scope_kind / scope_ref 字段
scope_kind = extract_fm_field("scope_kind")
scope_ref = extract_fm_field("scope_ref")

if not drift_artifact_urn or not drift_artifact_urn.startswith("urn:piao:drift:"):
    sys.stderr.write(f"ERROR: drift artifact urn invalid: {drift_artifact_urn!r}\n")
    sys.exit(2)
if not scope_kind or not scope_ref:
    sys.stderr.write(f"ERROR: drift artifact missing scope_kind/scope_ref\n")
    sys.exit(2)

# ------------------------------------------------------------------------------
# 3. scope 一致性校验（final-decisions R3 · 06 §4.1）
# ------------------------------------------------------------------------------
# 事件 subject = drift_urn · drift artifact 自身 urn 也 = drift_urn
# 若事件 subject 与 artifact front-matter urn 不一致 → 指向另一 scope 的 drift
# → 违反 R3 "E.scope 必须继承 D.scope"（SMOKE 3 场景）

if drift_urn != drift_artifact_urn:
    sys.stderr.write(
        f"ERROR: scope inconsistent · event.subject={drift_urn!r} != "
        f"artifact.urn={drift_artifact_urn!r}\n"
    )
    sys.stderr.write(
        f"ERROR: violation of final-decisions §1 R3 (06 §4.1) "
        f"· E.scope must inherit D.scope\n"
    )
    sys.exit(1)

# 事件自身若携带 scope_kind/scope_ref 字段（非必填 · 06 §2.3 L1 schema 声明）
# 也作 cross-check：若事件带了且与 artifact 不一致 → 同样视为 scope 不一致
evt_scope_kind = event.get("scope_kind", "")
evt_scope_ref = event.get("scope_ref", "")
if evt_scope_kind and evt_scope_kind != scope_kind:
    sys.stderr.write(
        f"ERROR: scope_kind mismatch · event={evt_scope_kind!r} artifact={scope_kind!r}\n"
    )
    sys.exit(1)
if evt_scope_ref and evt_scope_ref != scope_ref:
    sys.stderr.write(
        f"ERROR: scope_ref mismatch · event={evt_scope_ref!r} artifact={scope_ref!r}\n"
    )
    sys.exit(1)

# ------------------------------------------------------------------------------
# 4. 决策：4-A 纯观测恒为 pass_through（final-decisions R4）
# ------------------------------------------------------------------------------

decision = "pass_through"  # 硬约束：本 MVP 不做 dispatch / pull_detail 分流

# driver_event_id 条件必填（06 §2.3 A2 字段必填性）
# attribution_mode=full 时可由事件 attribution 字段取 · MVP 阶段透传 null 即可
# （4-A 纯观测 · 不做归因消费 · driver 字段不影响下游决策）
driver_event_id = event.get("driver_event_id")  # 若事件不带此字段则为 None

# ------------------------------------------------------------------------------
# 5. canonical body 生成（06 §2.3 schema · scan_base + scanned_drifts[]）
# ------------------------------------------------------------------------------

body_lines = []
body_lines.append("scan_base:")
body_lines.append("  event_journal_range:")
body_lines.append(f'    from_event_id: "{drift_event_id}"')
body_lines.append(f'    to_event_id:   "{drift_event_id}"')
body_lines.append(f'  scope_kind: "{scope_kind}"')
body_lines.append(f'  scope_ref:  "{scope_ref}"')
body_lines.append("scanned_drifts:")
body_lines.append(f'  - drift_event_id: "{drift_event_id}"')
body_lines.append(f'    drift_urn:      "{drift_urn}"')
body_lines.append(f'    decision:       "{decision}"')
if driver_event_id:
    body_lines.append(f'    driver_event_id: "{driver_event_id}"')
else:
    body_lines.append(f'    driver_event_id: null')
body_lines.append("decisions: []  # 4-A 纯观测 · 恒为空（final-decisions R5 · 不发 task.proposed / proposal.generated）")
body_lines.append("orphan_check:")
body_lines.append("  enabled: false")
body_lines.append("  orphans: []")

body_text = "\n".join(body_lines) + "\n"

with open(OUT_BODY, "w", encoding="utf-8", newline="\n") as f:
    f.write(body_text)

# ------------------------------------------------------------------------------
# 6. content_sha256 计算（04 §3.2.3 canonical 通用契约）
# ------------------------------------------------------------------------------
# SHA_WHITELIST 六字段（按 06 §2.3 schema 取核心 body 字段）：
#   scope_kind / scope_ref / drift_event_id / drift_urn / decision / driver_event_id
# 客观性：同 drift.detected 事件 + 同 drift artifact + 同算法 → 同 sha

sha_input_parts = [
    f"scope_kind={scope_kind}",
    f"scope_ref={scope_ref}",
    f"drift_event_id={drift_event_id}",
    f"drift_urn={drift_urn}",
    f"decision={decision}",
    f"driver_event_id={driver_event_id if driver_event_id else ''}",
]
sha_input = "\n".join(sha_input_parts) + "\n"
content_sha = hashlib.sha256(sha_input.encode("utf-8")).hexdigest()

with open(OUT_SHA, "w", encoding="utf-8", newline="\n") as f:
    f.write(content_sha)

# ------------------------------------------------------------------------------
# 7. meta 输出
# ------------------------------------------------------------------------------

meta = {
    "DRIFT_URN": drift_urn,
    "DRIFT_EVENT_ID": drift_event_id,
    "SCOPE_KIND": scope_kind,
    "SCOPE_REF": scope_ref,
    "DECISION": decision,
    "ADDED_COUNT": str(counts.get("added", 0)),
    "REMOVED_COUNT": str(counts.get("removed", 0)),
    "SHA_CHANGED_COUNT": str(counts.get("sha_changed", 0)),
    "UNCHANGED_COUNT": str(counts.get("unchanged", 0)),
    "ATTRIBUTION_MODE": attr_mode,
}

with open(OUT_META, "w", encoding="utf-8", newline="\n") as f:
    for k, v in meta.items():
        f.write(f"{k}={v}\n")

sys.stderr.write(
    f"[piao-evolution-scan] ✅ parsed drift_event={drift_event_id} "
    f"drift_urn={drift_urn} scope={scope_kind}/{scope_ref} "
    f"decision={decision} (4-A pure observation)\n"
)
PYEOF

# ==============================================================================
# 读回 meta · 拼接 evolution.scan_result front-matter
# ==============================================================================

DRIFT_URN=""
DRIFT_EVENT_ID=""
SCOPE_KIND=""
SCOPE_REF=""
DECISION=""
ADDED_COUNT=0
REMOVED_COUNT=0
SHA_CHANGED_COUNT=0
UNCHANGED_COUNT=0
ATTRIBUTION_MODE=""

while IFS='=' read -r key value; do
  case "$key" in
    DRIFT_URN)          DRIFT_URN="$value" ;;
    DRIFT_EVENT_ID)     DRIFT_EVENT_ID="$value" ;;
    SCOPE_KIND)         SCOPE_KIND="$value" ;;
    SCOPE_REF)          SCOPE_REF="$value" ;;
    DECISION)           DECISION="$value" ;;
    ADDED_COUNT)        ADDED_COUNT="$value" ;;
    REMOVED_COUNT)      REMOVED_COUNT="$value" ;;
    SHA_CHANGED_COUNT)  SHA_CHANGED_COUNT="$value" ;;
    UNCHANGED_COUNT)    UNCHANGED_COUNT="$value" ;;
    ATTRIBUTION_MODE)   ATTRIBUTION_MODE="$value" ;;
  esac
done < "$TMP_META"

CONTENT_SHA="$(cat "$TMP_SHA_FILE")"

# evolution artifact URN（06 §2.3 schema · scope 继承 drift）
EVOLUTION_URN="urn:piao:artifact:${SCOPE_KIND}/${SCOPE_REF}:evolution/${NAME}@${REV}"

# ==============================================================================
# 最终 evolution.scan_result YAML 文件拼接
# ==============================================================================

mkdir -p "$(dirname "$OUTPUT")"

{
  cat <<EOF
---
urn: ${EVOLUTION_URN}
kind: artifact
artifact_type: evolution.scan_result
rev: ${REV}
status: published
produced_at: ${PRODUCED_AT}
produced_by:
  task_urn: ${TASK_URN}
  event_id: ${EVENT_ID}
  actor: ${ACTOR}
wordcheck_policy: machine_generated
wordcheck_exempt: true
depends_on:
  - ${DRIFT_URN}
content_sha256: "${CONTENT_SHA}"
---

# evolution.scan_result · ${SCOPE_KIND}/${SCOPE_REF} · ${NAME}

EOF
  cat "$TMP_BODY"
} > "$OUTPUT"

# ==============================================================================
# --emit-events：N=2 L1 事件同 txn 原子写入（03 §3.3.1 · final-decisions R5）
# ==============================================================================
#
# 两条事件（按 final-decisions §1 决议 5 · 06 §3.2 E5）：
#   E1 · artifact.published(E)  · event_id 前缀 drift-triggered-* · subject=evolution URN
#   E2 · evolution.scanned      · event_id 前缀 evolution-scanned-* · subject=evolution URN
#
# 物理落点：<event-journal-dir>/<YYYY-MM>.jsonl（对齐 03 §8.2 O1）
#
# 原子性：staging → 顺序 append → 失败则 rollback（截断 journal + 删 artifact）
# 对齐 piao-drift-compute.sh 同构实装（M5 T'4 多进程并发补注范式）

if [[ "$EMIT_EVENTS" == "1" ]]; then
  EMIT_MONTH="$(date -u +'%Y-%m')"
  JOURNAL_FILE="${EVENT_JOURNAL_DIR}/${EMIT_MONTH}.jsonl"
  mkdir -p "$EVENT_JOURNAL_DIR"
  touch "$JOURNAL_FILE"

  # 生成 evolution.scanned 事件 id（06 §6.2 双前缀规约 · 前缀 evolution-scanned-*）
  SCAN_EVENT_ID="evolution-scanned-$(date -u +'%y%m%d%H%M%S')-$(python3 -c 'import secrets,string;print("".join(secrets.choice(string.ascii_lowercase+string.digits) for _ in range(6)))')"

  # 事件序列化（python3 保证 JSON 正确性）
  EVENTS_STAGING="$(mktemp -d)"
  trap 'rm -f "$TMP_META" "$TMP_BODY" "$TMP_SHA_FILE"; rm -rf "$EVENTS_STAGING"' EXIT

  python3 - \
    "$EVENTS_STAGING" \
    "$EVENT_ID" "$SCAN_EVENT_ID" \
    "$EVOLUTION_URN" "$DRIFT_URN" "$DRIFT_EVENT_ID" \
    "$SCOPE_KIND" "$SCOPE_REF" "$DECISION" \
    "$TASK_URN" "$ACTOR" "$PRODUCED_AT" <<'PYEOF2'
"""
序列化 N=2 事件到 staging 文件（JSONL 扁平格式）。

E1 · artifact.published(E)  · 03 §3.1 L1 · final-decisions R5
E2 · evolution.scanned       · 03 §3.1 L1 · 06 §2.3 8 字段 · final-decisions R5 决议 4 3 字段上限
"""
import sys, json

(STAGING,
 ARTIFACT_EVENT_ID, SCAN_EVENT_ID,
 EVOLUTION_URN, DRIFT_URN, DRIFT_EVENT_ID,
 SCOPE_KIND, SCOPE_REF, DECISION,
 TASK_URN, ACTOR, PRODUCED_AT) = sys.argv[1:13]

# E1 · artifact.published(E) · 前缀 drift-triggered-*
# （evolution artifact 是 drift.detected 驱动下的 artifact.published 派生 · R19 对偶）
e1 = {
    "event_id": ARTIFACT_EVENT_ID,
    "event_type": "artifact.published",
    "event_layer": "L1",
    "emitted_at": PRODUCED_AT,
    "emitted_by": ACTOR,
    "subject": EVOLUTION_URN,         # 双轨原则：subject = evolution artifact URN
    "producer_task_urn": TASK_URN,
    "artifact_kind": "artifact",
    "artifact_type": "evolution.scan_result",
}

# E2 · evolution.scanned · 06 §2.3 8 字段 schema
# final-decisions §1 决议 5 · L1 永远只读 3 字段（drift_event_urn / scope_urn / decision）
# 事件自身 8 字段包含通用骨架 5 + 语义 3（evidence 汇总 / scope / decision）
e2 = {
    "event_id": SCAN_EVENT_ID,
    "event_type": "evolution.scanned",
    "event_layer": "L1",
    "emitted_at": PRODUCED_AT,
    "emitted_by": ACTOR,
    "subject": EVOLUTION_URN,         # 双轨原则：subject = evolution artifact URN
    "evidence": {
        "event_journal_range": {
            "from_event_id": DRIFT_EVENT_ID,
            "to_event_id":   DRIFT_EVENT_ID,
        },
        "scanned_drift_count": 1,
        "decision_count": 0,          # 4-A 纯观测 · decisions[] 恒为空
    },
    "scope_kind": SCOPE_KIND,
    "scope_ref":  SCOPE_REF,
}

# 写 staging（每文件一条事件）
for name, payload in [("E1", e1), ("E2", e2)]:
    out = f"{STAGING}/{name}.jsonl"
    with open(out, "w", encoding="utf-8", newline="\n") as f:
        f.write(json.dumps(payload, ensure_ascii=False, sort_keys=True) + "\n")

sys.stderr.write(
    f"[piao-evolution-scan] staged 2 events: E1={ARTIFACT_EVENT_ID} E2={SCAN_EVENT_ID}\n"
)
PYEOF2

  # ----------------------------------------------------------------------------
  # N=2 同 txn append（顺序写 · 失败整体回滚）
  # ----------------------------------------------------------------------------

  JOURNAL_BEFORE_LINES="$(wc -l < "$JOURNAL_FILE" | tr -d ' ')"

  rollback_txn() {
    local reason="$1"
    echo "ERROR: --emit-events txn failed: ${reason}" >&2
    echo "ERROR: rolling back · restoring journal to ${JOURNAL_BEFORE_LINES} lines · removing evolution artifact" >&2
    head -n "$JOURNAL_BEFORE_LINES" "$JOURNAL_FILE" > "${JOURNAL_FILE}.rollback" && \
      mv "${JOURNAL_FILE}.rollback" "$JOURNAL_FILE"
    rm -f "$OUTPUT"
    exit 4
  }

  for EVT_NAME in E1 E2; do
    EVT_FILE="${EVENTS_STAGING}/${EVT_NAME}.jsonl"
    if [[ ! -s "$EVT_FILE" ]]; then
      rollback_txn "staging file missing: ${EVT_FILE}"
    fi
    if ! cat "$EVT_FILE" >> "$JOURNAL_FILE"; then
      rollback_txn "append failed for ${EVT_NAME}"
    fi
  done

  echo "[piao-evolution-scan] 📮 emitted 2 L1 events to: ${JOURNAL_FILE}"
  echo "[piao-evolution-scan]   E1 artifact.published(E): ${EVENT_ID}"
  echo "[piao-evolution-scan]   E2 evolution.scanned:     ${SCAN_EVENT_ID}"
fi

# ==============================================================================
# 人类可读摘要（stdout）
# ==============================================================================

echo "[piao-evolution-scan] ✅ produced: $OUTPUT"
echo "[piao-evolution-scan] URN:              ${EVOLUTION_URN}"
echo "[piao-evolution-scan] scope:            ${SCOPE_KIND}/${SCOPE_REF}"
echo "[piao-evolution-scan] drift_urn:        ${DRIFT_URN}"
echo "[piao-evolution-scan] drift_event_id:   ${DRIFT_EVENT_ID}"
echo "[piao-evolution-scan] decision:         ${DECISION} (4-A pure observation · final-decisions R4)"
echo "[piao-evolution-scan] decisions[]:      [] (5-A terminate at scan_result · final-decisions R5)"
echo "[piao-evolution-scan] content_sha256:   ${CONTENT_SHA}"
echo "[piao-evolution-scan] event_id(artifact): ${EVENT_ID}"
if [[ "$EMIT_EVENTS" == "1" ]]; then
  echo "[piao-evolution-scan] event_id(scanned):  ${SCAN_EVENT_ID}"
fi
