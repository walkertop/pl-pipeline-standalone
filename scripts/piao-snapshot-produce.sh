#!/usr/bin/env bash
#
# piao-snapshot-produce.sh — piao-pipeline snapshot artifact 产出器（MVP）
#
# 契约依据：
#   - ${PL_ASSETS}/piao/docs/kernel/04-version-snapshot.md @v1.1 published
#     §3.2   front-matter + body schema
#     §3.2.1 content_sha256 canonical YAML 五步规范化
#     §3.3   scope_kind 五类封板（unit / stage / taskdag / adapter / kernel）
#     §4     URN 寻址语义
#
# 产出范围（MVP）：
#   - 仅产出 snapshot artifact yaml 文件；**不**写入 L1 事件（§2.2 三步原子
#     契约中的步骤 2/3 由 event-journal-append 工具承担，不在本 MVP 范围）
#
# 使用范式：
#   piao-snapshot-produce.sh \
#     --scope-kind kernel \
#     --scope-ref urn:piao:artifact:kernel \
#     --name kernel_state_now \
#     --rev v1 \
#     --frozen-list frozen.tsv \
#     --output "${PL_OUTPUT}/piao/snapshots/kernel/kernel_state_now@v1.yaml" \
#     [--trigger-event-type stage.exited] \
#     [--task-urn urn:piao:task:...] \
#     [--actor agent:manual] \
#     [--produced-at 2026-04-19T03:00:00+08:00] \
#     [--base-dir /path/to/host-project]  # 默认 = $PL_PROJECT
#
# frozen-list 格式（TAB 分隔，一行一 artifact）：
#   <artifact_urn><TAB><relative_file_path>[<TAB><artifact_type>]
#
#   若第三列 artifact_type 缺省，则从文件 front-matter `kind:` 字段推断；
#   若文件无 front-matter 或无 kind 字段，默认 `spec`。
#
#   relative_file_path 相对 $PL_PROJECT（可通过 --base-dir 覆盖）。

# shellcheck source=./_env.sh
source "$(dirname "${BASH_SOURCE[0]}")/_env.sh"
set -euo pipefail

# ==============================================================================
# 参数解析
# ==============================================================================

SCOPE_KIND=""
SCOPE_REF=""
NAME=""
REV=""
FROZEN_LIST=""
OUTPUT=""
TRIGGER_EVENT_TYPE="stage.exited"
TASK_URN="urn:piao:task:manual:piao_snapshot_produce"
ACTOR="agent:piao-snapshot-produce"
PRODUCED_AT=""
SUPERSEDES="null"
BASE_DIR=""

usage() {
  sed -n '2,35p' "$0"
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --scope-kind)           SCOPE_KIND="$2"; shift 2 ;;
    --scope-ref)            SCOPE_REF="$2"; shift 2 ;;
    --name)                 NAME="$2"; shift 2 ;;
    --rev)                  REV="$2"; shift 2 ;;
    --frozen-list)          FROZEN_LIST="$2"; shift 2 ;;
    --output)               OUTPUT="$2"; shift 2 ;;
    --trigger-event-type)   TRIGGER_EVENT_TYPE="$2"; shift 2 ;;
    --task-urn)             TASK_URN="$2"; shift 2 ;;
    --actor)                ACTOR="$2"; shift 2 ;;
    --produced-at)          PRODUCED_AT="$2"; shift 2 ;;
    --supersedes)           SUPERSEDES="$2"; shift 2 ;;
    --base-dir)             BASE_DIR="$2"; shift 2 ;;
    -h|--help)              usage ;;
    *) echo "ERROR: unknown arg: $1" >&2; usage ;;
  esac
done

# ==============================================================================
# 参数校验（按 04 §3.2 / §3.3 / §4 契约）
# ==============================================================================

for var_name in SCOPE_KIND SCOPE_REF NAME REV FROZEN_LIST OUTPUT; do
  if [[ -z "${!var_name}" ]]; then
    # bash 3.2 兼容：不用 ${var,,} 小写化，改用 tr
    var_lower="$(printf '%s' "$var_name" | tr '[:upper:]' '[:lower:]')"
    echo "ERROR: --${var_lower//_/-} is required" >&2
    exit 2
  fi
done

# §3.3 scope_kind 枚举封板（unit / stage / taskdag / adapter / kernel）
case "$SCOPE_KIND" in
  unit|stage|taskdag|adapter|kernel) ;;
  *) echo "ERROR: invalid scope_kind: $SCOPE_KIND (§3.3 封板五类)" >&2; exit 2 ;;
esac

# §4.2 rev 语法约束（@v<N>，不允许次版）
if [[ ! "$REV" =~ ^v[0-9]+$ ]]; then
  echo "ERROR: invalid rev: $REV (§4.2 snapshot 不做次版；应形如 v1/v2/v3)" >&2
  exit 2
fi

# §2.1 trigger_event_type 枚举
case "$TRIGGER_EVENT_TYPE" in
  stage.entered|stage.exited|task.finished) ;;
  *) echo "ERROR: invalid trigger_event_type: $TRIGGER_EVENT_TYPE (§2.1 仅允许 stage.entered/stage.exited/task.finished)" >&2; exit 2 ;;
esac

if [[ ! -f "$FROZEN_LIST" ]]; then
  echo "ERROR: --frozen-list not found: $FROZEN_LIST" >&2
  exit 2
fi

if [[ -z "$PRODUCED_AT" ]]; then
  PRODUCED_AT="$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
fi

# ==============================================================================
# 入口目录锚定（关键：允许从任意 CWD 调用）
# ==============================================================================
#
# BASE_DIR 语义：frozen-list 里相对路径的解析基准目录
#   - 优先级：--base-dir 参数 > $PL_PROJECT（由 _env.sh 提供，默认为 $PWD）
#   - 历史版（宿主内）取 SCRIPT_DIR/..，假设脚本与宿主项目同根
#   - 独立版必须显式使用 $PL_PROJECT，因为脚本本身不在宿主项目内

if [[ -z "${BASE_DIR:-}" ]]; then
  BASE_DIR="$PL_PROJECT"
fi
if [[ ! -d "$BASE_DIR" ]]; then
  echo "ERROR: --base-dir not a directory: $BASE_DIR" >&2
  exit 2
fi
REPO_ROOT="$(cd "$BASE_DIR" && pwd)"

# ==============================================================================
# 步骤 1：解析 frozen-list 并规范化（§3.2.1 canonical YAML 五步）
# ==============================================================================
#
# 执行方：由 python3 脚本完成，原因：
#   - canonical YAML 对"空格、引号、换行、顺序"敏感，shell 字符串拼接易错
#   - sha256 计算用 hashlib，避免跨平台 shasum 输出差异

# 预留 event_id（§2.2 `event_id` 预留契约；MVP 以时间+随机后缀生成占位符）
# 注：用 python3 生成以规避 shell pipefail + tr + head 组合的 SIGPIPE 陷阱
EVENT_ID="snap-$(date +'%y%m%d%H%M%S')-$(python3 -c 'import secrets,string;print("".join(secrets.choice(string.ascii_lowercase+string.digits) for _ in range(6)))')"

# 构建本 snapshot 的 URN（§4.1）
SNAPSHOT_URN="urn:piao:snapshot:${SCOPE_REF//urn:piao:*:/}:${NAME}@${REV}"
# 上式对 SCOPE_REF 做了简化剥离，但 §4 的 URN 组装语义是：
#   urn:piao:snapshot:<scope>:<name>@<rev>
# 其中 <scope> 由 scope_kind 决定（§4.1 表）。MVP 让调用方直接提供 <scope> 段
# 更稳妥——这里按 scope_kind 派生：
case "$SCOPE_KIND" in
  unit)    SNAP_SCOPE_SEG="${SCOPE_REF#urn:piao:unit:}" ;;
  stage)   SNAP_SCOPE_SEG="${SCOPE_REF#urn:piao:stage:}" ;;
  taskdag) SNAP_SCOPE_SEG="${SCOPE_REF#urn:piao:taskdag:}" ;;
  adapter) SNAP_SCOPE_SEG="${SCOPE_REF#urn:piao:artifact:}"
           SNAP_SCOPE_SEG="${SNAP_SCOPE_SEG%%:*}" ;;
  kernel)  SNAP_SCOPE_SEG="kernel" ;;
esac
SNAPSHOT_URN="urn:piao:snapshot:${SNAP_SCOPE_SEG}:${NAME}@${REV}"

# ==============================================================================
# 步骤 2：调用 python3 执行 canonical YAML 规范化 + sha256 计算
# ==============================================================================

TMP_CANONICAL="$(mktemp)"
TMP_SHA_FILE="$(mktemp)"
trap 'rm -f "$TMP_CANONICAL" "$TMP_SHA_FILE"' EXIT

python3 - "$FROZEN_LIST" "$REPO_ROOT" "$TMP_CANONICAL" "$TMP_SHA_FILE" <<'PYEOF'
"""
canonical YAML 五步规范化器（仅处理 frozen_artifacts）

按 04 §3.2.1 契约：
  1. 解析 frozen-list TSV（一行一 artifact · <urn>\t<file_path>[\t<artifact_type>]）
  2. 对每个条目取五个必填 key；从文件计算 content_sha256；从 front-matter 推断 artifact_type
  3. 按 artifact_urn 字典序排序（UTF-8 字节序）
  4. 输出 canonical YAML：key 固定顺序、字符串双引号、两空格缩进、文件末尾恰好一个 \n
  5. 对 canonical YAML UTF-8 字节流做 sha256，小写 hex

Output:
  TMP_CANONICAL: canonical frozen_artifacts YAML 片段（供主脚本拼接进产出文件的 body）
  TMP_SHA_FILE:  本 snapshot 的 content_sha256（小写 hex，无换行）
"""
import sys, os, hashlib, re

FROZEN_LIST, REPO_ROOT, OUT_CANONICAL, OUT_SHA = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]

# 读 frozen-list（TSV）
entries = []
with open(FROZEN_LIST, "r", encoding="utf-8") as f:
    for line_no, line in enumerate(f, 1):
        line = line.rstrip("\n")
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        parts = line.split("\t")
        if len(parts) < 2:
            sys.stderr.write(f"ERROR: line {line_no} invalid (need at least 2 TAB-separated fields): {line!r}\n")
            sys.exit(3)
        urn = parts[0].strip()
        rel_path = parts[1].strip()
        override_type = parts[2].strip() if len(parts) >= 3 and parts[2].strip() else None
        entries.append({"urn": urn, "rel_path": rel_path, "override_type": override_type, "line_no": line_no})

# 从文件 front-matter 推断 artifact_type（02 §2.1 kind→artifact_type 映射简化版）
KIND_TO_TYPE = {
    "spec": "spec",
    "artifact": "spec",  # 兜底
    "snapshot": "snapshot",
    "proposal": "proposal",
    "rule": "rule",
    "evolution_source": "evolution_source",
}

def infer_artifact_type(abs_path):
    """读 front-matter kind: 字段；无则返回 'spec' 作为默认兜底"""
    try:
        with open(abs_path, "r", encoding="utf-8") as f:
            first_chunk = f.read(2048)
    except FileNotFoundError:
        return None  # 上游会报错
    if not first_chunk.startswith("---\n"):
        return "spec"  # 无 front-matter，兜底 spec（M4 工具链视角歧义：kernel 下 01/02/07 当前无 front-matter）
    # 提取 front-matter 区块
    end = first_chunk.find("\n---", 4)
    if end < 0:
        return "spec"
    fm = first_chunk[4:end]
    m = re.search(r"^kind:\s*([a-z_]+)\s*$", fm, re.MULTILINE)
    if not m:
        return "spec"
    kind = m.group(1).strip()
    return KIND_TO_TYPE.get(kind, "spec")

# 对每个 entry 计算 content_sha256（文件字节直接 sha256）+ 推断 artifact_type
records = []
for e in entries:
    abs_path = e["rel_path"]
    if not os.path.isabs(abs_path):
        abs_path = os.path.join(REPO_ROOT, e["rel_path"])
    if not os.path.isfile(abs_path):
        sys.stderr.write(f"ERROR: line {e['line_no']} file not found: {abs_path}\n")
        sys.exit(3)
    with open(abs_path, "rb") as f:
        content_sha256 = hashlib.sha256(f.read()).hexdigest()
    artifact_type = e["override_type"] or infer_artifact_type(abs_path) or "spec"
    records.append({
        "artifact_urn": e["urn"],
        "content_sha256": content_sha256,
        # MVP：producer_event_id / producer_task_urn 用占位符
        # 正式场景下由 event-journal-query 填回，MVP 不承诺
        "producer_event_id": "task-unknown-000000-000000",
        "producer_task_urn": "urn:piao:task:manual:unknown",
        "artifact_type": artifact_type,
    })

# 按 artifact_urn 字典序排序（UTF-8 字节序）
records.sort(key=lambda r: r["artifact_urn"].encode("utf-8"))

# 构建 canonical YAML body（只含 frozen_artifacts 块）
# 规则：key 固定顺序 / 字符串双引号 / 两空格缩进 / 末尾恰好一个 \n
KEY_ORDER = ["artifact_urn", "content_sha256", "producer_event_id", "producer_task_urn", "artifact_type"]

lines = ["frozen_artifacts:"]
for r in records:
    # 列表条目首行带 "  - key: value"，后续键用 "    key: value"
    first = True
    for k in KEY_ORDER:
        v = r[k]
        prefix = "  - " if first else "    "
        # 所有 value 一律双引号（值中不含 " 字符，这是 URN/sha/event_id 的语义保证）
        if '"' in v:
            sys.stderr.write(f"ERROR: value contains double-quote (not allowed by §3.2.1): key={k} value={v!r}\n")
            sys.exit(3)
        lines.append(f'{prefix}{k}: "{v}"')
        first = False

canonical = "\n".join(lines) + "\n"  # §3.2.1 步骤 4：文件末尾恰好一个 \n

with open(OUT_CANONICAL, "w", encoding="utf-8", newline="\n") as f:
    f.write(canonical)

# §3.2.1 步骤 5：对 canonical YAML 的 UTF-8 字节流执行 SHA-256
content_sha = hashlib.sha256(canonical.encode("utf-8")).hexdigest()
with open(OUT_SHA, "w", encoding="utf-8") as f:
    f.write(content_sha)

sys.stderr.write(f"[piao-snapshot-produce] canonicalized {len(records)} frozen_artifacts entries · content_sha256={content_sha[:12]}...\n")
PYEOF

CONTENT_SHA="$(cat "$TMP_SHA_FILE")"

# ==============================================================================
# 步骤 3：拼接最终 snapshot yaml 文件（front-matter + body）
# ==============================================================================

mkdir -p "$(dirname "$OUTPUT")"

{
  cat <<EOF
---
urn: ${SNAPSHOT_URN}
kind: snapshot
artifact_type: snapshot
rev: ${REV}
status: published
supersedes: ${SUPERSEDES}
schema_version: "1.0"
produced_by:
  actor: ${ACTOR}
  task_urn: ${TASK_URN}
  event_id: ${EVENT_ID}
  trigger_event_type: ${TRIGGER_EVENT_TYPE}
produced_at: ${PRODUCED_AT}
frozen_scope:
  scope_kind: ${SCOPE_KIND}
  scope_ref: ${SCOPE_REF}
content_sha256: "${CONTENT_SHA}"
---

# snapshot · ${SNAP_SCOPE_SEG} · ${NAME}

EOF
  cat "$TMP_CANONICAL"
} > "$OUTPUT"

echo "[piao-snapshot-produce] ✅ produced: $OUTPUT"
echo "[piao-snapshot-produce] URN:          ${SNAPSHOT_URN}"
echo "[piao-snapshot-produce] content_sha256: ${CONTENT_SHA}"
echo "[piao-snapshot-produce] event_id(reserved): ${EVENT_ID}"
