#!/usr/bin/env bash
#
# piao-drift-compute.sh — piao-pipeline drift artifact 计算器
#
# 契约依据：
#   - ${PL_ASSETS}/piao/docs/kernel/05-drift-propagation.md @v1.1 published
#     §2.1   drift artifact 的 URN/kind/artifact_type/scope
#     §2.3   drift artifact schema（front-matter + body）
#     §2.5   content_sha256 可重复性（正向白名单 SHA_WHITELIST 六字段 · R17）
#     §3.2   触发流程（T3/T4 产出 artifact · T5 N=2 同 txn 写两条事件 · 05 §6.2）
#     §3.5   drift_kind 枚举（initial_snapshot / content_drift / no_change_drift）
#     §4.1   scope 必须同 scope_kind + 同 scope_ref（直接继承 04 §5.3 拒绝契约）
#     §5.1   attribution_mode 两模式（full / sha_only · R4 降级透明暴露）
#     §5.2   降级 reason 必须写明（禁止隐式降级 + 部分归因）
#     §5.3   full 模式归因算法（O(N·K) 三步链条）
#     §6.1   drift→evolution 双通道（A 事件流 · B artifact 拉取）
#     §6.2   drift.detected L1 事件 11 必填字段（含 evidence 双轨）
#   - ${PL_ASSETS}/piao/docs/kernel/04-version-snapshot.md @v1.2 published
#     §3.2.3 canonical YAML 通用工具契约（三承诺：key 正则 + pick_fields + SHA_WHITELIST）
#     §5.1   snapshot_diff 算子（modified / sha_changed 双名 alias · @v1.2 起）
#     §5.3   跨 scope_kind 直接拒绝
#   - ${PL_ASSETS}/piao/docs/kernel/03-layered-architecture.md @v1 draft
#     §3.1   L1 事件 10 类枚举（含 artifact.published / drift.detected）
#     §3.3.1 N 条 L1 事件同 txn 原子写入契约（R22 · N=2 drift 两写实例）
#     §4.1   事件 id 格式 <域>-<UTC12位>-<6位hash>（7 选 1 域枚举）
#   - ${PL_ASSETS}/piao/docs/kernel/02-artifact-model.md @v1.3 published
#     §2.2.4 派生类型注册 schema（wordcheck_policy: machine_generated / content_safe_default）
#
# 运行模式（三档 · 向后兼容）：
#   A) MVP 占位模式（默认 · 不指定 --full-mode 也不指定 --emit-events）
#      产出 drift artifact yaml · attribution_mode=sha_only（占位符触发降级）· 不写事件
#
#   B) --full-mode + --event-journal-dir <path>
#      按 05 §5.3 归因算法 O(N·K) 反查 event-journal 的 producer_event_id
#      成功 → attribution_mode=full + body.attribution[] 非空 + 每条携带 driver_event/driver_task
#      任一 event_id 反查失败 → 整体降级 sha_only + reason="event-journal missing event_id=<id>"
#      （05 §5.2 禁止隐式降级 + 部分归因）
#
#   C) --emit-events
#      drift artifact 写入后，按 03 §3.3.1 N=2 同 txn 原子写入两条 L1 事件：
#        - artifact.published(drift) · event_id 前缀 snap-published-*（R19 裁定）
#        - drift.detected · event_id 前缀 drift-detected-* · 11 必填字段全量
#      event-journal 物理载体：<journal-dir>/<YYYY-MM>.jsonl（对齐 03 §8.2 O1 决议）
#      原子性实现：两条事件先写 staging 文件 → drift artifact 写入 → fsync 后 cat >> 主 journal
#      任一步失败 → 全部回滚（rm staging + rm drift artifact · 不留半成品）
#
# 使用范式：
#   # MVP 占位模式
#   piao-drift-compute.sh --new-snapshot new.yaml [--old-snapshot old.yaml] \
#     --name my_drift --rev v1 --output drift.yaml
#
#   # full 归因 + 事件原子写入（M6 evolution 起稿前置形态）
#   piao-drift-compute.sh --new-snapshot new.yaml --old-snapshot old.yaml \
#     --name my_drift --rev v1 --output drift.yaml \
#     --full-mode --event-journal-dir pipeline-output/events \
#     --emit-events
#
# 若省略 --old-snapshot：触发 initial_snapshot 分支（05 §3.5）· 产出空 drift
# （四字段全零 · drift_kind=initial_snapshot · attribution_mode 仍按 S_new 判定）。
#
# 命名空间规避：本脚本前缀 `piao-` 与 `piao-snapshot-produce.sh` / `piao-snapshot-diff.sh`
# 同属 piao-pipeline 工具链簇；避让项目业务侧 `snapshot-generator.sh`（Kuikly 架构扫描器）。

set -euo pipefail

# ==============================================================================
# 参数解析
# ==============================================================================

OLD_SNAPSHOT=""
NEW_SNAPSHOT=""
NAME=""
REV=""
OUTPUT=""
TASK_URN="urn:piao:task:manual:piao_drift_compute"
ACTOR="agent:piao-drift-compute"
PRODUCED_AT=""
SUPERSEDES="null"
# 阶段 α 扩展参数（m6_evolution_kickoff §2.2 两扩展 flag）
FULL_MODE="0"
EVENT_JOURNAL_DIR=""
EMIT_EVENTS="0"

usage() {
  sed -n '2,72p' "$0"
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --old-snapshot)      OLD_SNAPSHOT="$2"; shift 2 ;;
    --new-snapshot)      NEW_SNAPSHOT="$2"; shift 2 ;;
    --name)              NAME="$2"; shift 2 ;;
    --rev)               REV="$2"; shift 2 ;;
    --output)            OUTPUT="$2"; shift 2 ;;
    --task-urn)          TASK_URN="$2"; shift 2 ;;
    --actor)             ACTOR="$2"; shift 2 ;;
    --produced-at)       PRODUCED_AT="$2"; shift 2 ;;
    --supersedes)        SUPERSEDES="$2"; shift 2 ;;
    --full-mode)         FULL_MODE="1"; shift 1 ;;
    --event-journal-dir) EVENT_JOURNAL_DIR="$2"; shift 2 ;;
    --emit-events)       EMIT_EVENTS="1"; shift 1 ;;
    -h|--help)           usage ;;
    *) echo "ERROR: unknown arg: $1" >&2; usage ;;
  esac
done

# ==============================================================================
# 参数校验（按 05 §2.1 / §3.2 / §4.1 契约）
# ==============================================================================

for var_name in NEW_SNAPSHOT NAME REV OUTPUT; do
  if [[ -z "${!var_name}" ]]; then
    # bash 3.2 兼容：不用 ${var,,} 小写化，改用 tr
    var_lower="$(printf '%s' "$var_name" | tr '[:upper:]' '[:lower:]')"
    echo "ERROR: --${var_lower//_/-} is required" >&2
    exit 2
  fi
done

# 05 §7.1 + 04 §4.2 对齐：drift artifact 不升次版（与 snapshot 同步）
if [[ ! "$REV" =~ ^v[0-9]+$ ]]; then
  echo "ERROR: invalid rev: $REV (05 §7.1 drift 不升 rev · 应形如 v1/v2/v3)" >&2
  exit 2
fi

[[ -f "$NEW_SNAPSHOT" ]] || { echo "ERROR: --new-snapshot not found: $NEW_SNAPSHOT" >&2; exit 2; }
if [[ -n "$OLD_SNAPSHOT" ]]; then
  [[ -f "$OLD_SNAPSHOT" ]] || { echo "ERROR: --old-snapshot not found: $OLD_SNAPSHOT" >&2; exit 2; }
fi

if [[ -z "$PRODUCED_AT" ]]; then
  PRODUCED_AT="$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
fi

# 阶段 α 扩展参数组合校验（m6_evolution_kickoff §2.2）
if [[ "$FULL_MODE" == "1" ]]; then
  if [[ -z "$EVENT_JOURNAL_DIR" ]]; then
    echo "ERROR: --full-mode requires --event-journal-dir <path> (05 §5.1 前置条件)" >&2
    exit 2
  fi
  if [[ ! -d "$EVENT_JOURNAL_DIR" ]]; then
    echo "ERROR: --event-journal-dir not found or not a directory: $EVENT_JOURNAL_DIR" >&2
    exit 2
  fi
fi
if [[ "$EMIT_EVENTS" == "1" && -z "$EVENT_JOURNAL_DIR" ]]; then
  echo "ERROR: --emit-events requires --event-journal-dir <path> (03 §3.3.1 事件落点)" >&2
  exit 2
fi

# ==============================================================================
# 入口目录锚定（允许从任意 CWD 调用）
# ==============================================================================
#
# 注：本脚本不依赖任何 "项目根目录" 概念——所有输入都是绝对路径/相对 CWD
# 的 yaml 文件。_env.sh 已提供 $PL_PROJECT / $PL_OUTPUT 供需要的子模块使用。

# ==============================================================================
# 预留 event_id（05 §2.3 R19 裁定：前缀 snap-published-*）
# ==============================================================================
# 注：drift artifact 的 produced_by.event_id 本身是"artifact.published(D)"事件的 id
# 按 R19 裁定，该事件的 event_id 使用 snap-published-* 前缀（非 drift-detected-*）
EVENT_ID="snap-published-$(date +'%y%m%d%H%M%S')-$(python3 -c 'import secrets,string;print("".join(secrets.choice(string.ascii_lowercase+string.digits) for _ in range(6)))')"

# ==============================================================================
# 调用 python3 执行差分 + attribution_mode 判定 + canonical 计算
# ==============================================================================

TMP_META="$(mktemp)"         # scope + diff_base URN + drift_kind + attribution_mode（KEY=VALUE 形式）
TMP_BODY="$(mktemp)"         # body（added/removed/sha_changed/unchanged_count canonical YAML）
TMP_SHA_INPUT="$(mktemp)"    # 参与 sha 计算的 canonical YAML 全量输入（SHA_WHITELIST 六字段）
TMP_SHA_FILE="$(mktemp)"     # 最终 content_sha256
TMP_ATTRIBUTION="$(mktemp)"  # full 模式的 attribution[] 列表 body 片段（sha_only 模式下为空文件）
trap 'rm -f "$TMP_META" "$TMP_BODY" "$TMP_SHA_INPUT" "$TMP_SHA_FILE" "$TMP_ATTRIBUTION"' EXIT

python3 - \
  "${OLD_SNAPSHOT:-}" "$NEW_SNAPSHOT" \
  "$TMP_META" "$TMP_BODY" "$TMP_SHA_INPUT" "$TMP_SHA_FILE" \
  "$TMP_ATTRIBUTION" \
  "$FULL_MODE" "${EVENT_JOURNAL_DIR:-}" <<'PYEOF'
"""
piao-drift-compute · python3 算子

步骤：
  1. 解析 new / (可选) old snapshot yaml，提取 frozen_scope + frozen_artifacts
  2. 校验 scope 一致（04 §5.3 + 05 §4.1）
  3. 计算 added / removed / sha_changed / unchanged_count（04 §5.1 算子）
  4. 判定 drift_kind（05 §3.5）与 attribution_mode（05 §5.1）
  5. 若 FULL_MODE=1：扫 EVENT_JOURNAL_DIR 的所有 .jsonl → 按 05 §5.3 归因算法反查
     producer_event_id 得到 attribution 列表 · 任一 event_id 缺失整体降级 sha_only
  6. 按 05 §2.5 SHA_WHITELIST 六字段拼 canonical YAML + 计 sha256
  7. 产出 body 片段（供主脚本拼接到 front-matter 之后）
  8. 若 FULL_MODE=1 且归因成功：产出 attribution[] body 片段（TMP_ATTRIBUTION）

退出码：
  0 = 差分成功
  1 = scope 不一致（04 §5.3 / 05 §4.1 违反）
  2 = snapshot 解析失败 / 必填字段缺失
"""
import sys, os, re, json, hashlib

OLD_PATH = sys.argv[1] or None
NEW_PATH = sys.argv[2]
OUT_META, OUT_BODY, OUT_SHA_INPUT, OUT_SHA = sys.argv[3], sys.argv[4], sys.argv[5], sys.argv[6]
OUT_ATTRIBUTION = sys.argv[7]
FULL_MODE = sys.argv[8] == "1"
EVENT_JOURNAL_DIR = sys.argv[9] if len(sys.argv) > 9 and sys.argv[9] else None

# ------------------------------------------------------------------------------
# snapshot 解析器（与 piao-snapshot-diff.sh 对齐 · 独立实现避免 exec 依赖）
# ------------------------------------------------------------------------------

PLACEHOLDER_PRODUCER_EVENT_ID = "task-unknown-000000-000000"

def parse_snapshot(path):
    with open(path, "r", encoding="utf-8") as f:
        text = f.read()
    if not text.startswith("---\n"):
        sys.stderr.write(f"ERROR: {path}: no front-matter\n"); sys.exit(2)
    end = text.find("\n---\n", 4)
    if end < 0:
        sys.stderr.write(f"ERROR: {path}: front-matter not closed\n"); sys.exit(2)
    fm_text = text[4:end]
    body_text = text[end + 5:]

    def fm_get(pattern, required=True):
        m = re.search(pattern, fm_text, re.MULTILINE)
        if m:
            return m.group(1).strip().strip('"')
        if required:
            sys.stderr.write(f"ERROR: {path}: front-matter missing pattern: {pattern}\n")
            sys.exit(2)
        return None

    urn = fm_get(r"^urn:\s*(.+)$")
    scope_kind = fm_get(r"^\s{2}scope_kind:\s*(.+)$")
    scope_ref  = fm_get(r"^\s{2}scope_ref:\s*(.+)$")

    records = {}
    current = None
    KEY_SET = {"artifact_urn","content_sha256","producer_event_id","producer_task_urn","artifact_type"}
    for line in body_text.splitlines():
        m = re.match(r'^  -\s+artifact_urn:\s*"([^"]+)"\s*$', line)
        if m:
            if current is not None:
                records[current["artifact_urn"]] = current
            current = {"artifact_urn": m.group(1)}
            continue
        m = re.match(r'^    ([a-z_][a-z_0-9]*):\s*"([^"]*)"\s*$', line)
        if m and current is not None:
            k, v = m.group(1), m.group(2)
            if k in KEY_SET:
                current[k] = v
    if current is not None:
        records[current["artifact_urn"]] = current

    if not records:
        sys.stderr.write(f"ERROR: {path}: no frozen_artifacts parsed\n"); sys.exit(2)

    return {
        "path": path,
        "urn": urn,
        "scope_kind": scope_kind,
        "scope_ref": scope_ref,
        "frozen_artifacts": records,
    }

new = parse_snapshot(NEW_PATH)
old = parse_snapshot(OLD_PATH) if OLD_PATH else None

# ------------------------------------------------------------------------------
# scope 一致性校验（05 §4.1 R3）
# ------------------------------------------------------------------------------

if old is not None:
    if old["scope_kind"] != new["scope_kind"]:
        sys.stderr.write(
            f"ERROR: scope_kind mismatch (05 §4.1 R3): "
            f"old={old['scope_kind']} new={new['scope_kind']}\n"); sys.exit(1)
    if old["scope_ref"] != new["scope_ref"]:
        sys.stderr.write(
            f"ERROR: scope_ref mismatch (05 §4.1 R3): "
            f"old={old['scope_ref']} new={new['scope_ref']}\n"); sys.exit(1)

# ------------------------------------------------------------------------------
# 差分计算（04 §5.1 算子契约 · sha_changed 命名对齐 05 §2.3）
# ------------------------------------------------------------------------------

new_urns = set(new["frozen_artifacts"].keys())
old_urns = set(old["frozen_artifacts"].keys()) if old else set()

added_list = []
removed_list = []
sha_changed_list = []
unchanged_count = 0

if old is None:
    # initial_snapshot 分支：空 drift（四字段全零）
    drift_kind = "initial_snapshot"
else:
    for urn in sorted(new_urns - old_urns):
        r = new["frozen_artifacts"][urn]
        added_list.append({
            "artifact_urn": urn,
            "new_sha256": r.get("content_sha256", ""),
            "new_producer_event_id": r.get("producer_event_id", ""),
        })
    for urn in sorted(old_urns - new_urns):
        r = old["frozen_artifacts"][urn]
        removed_list.append({
            "artifact_urn": urn,
            "old_sha256": r.get("content_sha256", ""),
            "old_producer_event_id": r.get("producer_event_id", ""),
        })
    for urn in sorted(old_urns & new_urns):
        o = old["frozen_artifacts"][urn]
        n = new["frozen_artifacts"][urn]
        if o.get("content_sha256") != n.get("content_sha256"):
            sha_changed_list.append({
                "artifact_urn": urn,
                "old_sha256": o.get("content_sha256", ""),
                "new_sha256": n.get("content_sha256", ""),
                "old_producer_event_id": o.get("producer_event_id", ""),
                "new_producer_event_id": n.get("producer_event_id", ""),
            })
        else:
            unchanged_count += 1

    if added_list or removed_list or sha_changed_list:
        drift_kind = "content_drift"
    else:
        drift_kind = "no_change_drift"

# ------------------------------------------------------------------------------
# attribution_mode 判定（05 §5.1 R4 · 降级透明暴露）
# ------------------------------------------------------------------------------
#
# 两阶段判定：
#   阶段 1 · 占位符前置检查（MVP 既有逻辑 · sha_only 默认兜底）
#     若任一 producer_event_id 为占位符 PLACEHOLDER_PRODUCER_EVENT_ID → 直接 sha_only
#     降级 reason 指向首个触发降级的 snapshot + urn
#
#   阶段 2 · FULL_MODE 归因反查（本次扩展新增 · 仅当 FULL_MODE=1 且阶段 1 未降级时进入）
#     按 05 §5.3 三步算法扫 EVENT_JOURNAL_DIR 下所有 *.jsonl，按 event_id 反查
#     任一 event_id 在 journal 中不存在 → 整体降级 sha_only + reason="event-journal missing event_id=<id>"
#     （05 §5.2 禁止部分归因：不得"成功 N-1 条 + 失败 1 条"部分输出 full）
#     归因成功 → attribution_mode=full + attribution[] 列表写入 OUT_ATTRIBUTION

attribution_mode = "full"
attribution_reason = ""
attribution_entries = []  # full 模式下的归因元组列表 · 供 body 片段输出

def scan_placeholder(snap, snap_label):
    """返回首个使用占位符 producer_event_id 的 (label, urn, event_id)，若无则 None。"""
    for urn, r in snap["frozen_artifacts"].items():
        ev = r.get("producer_event_id", "")
        if ev == PLACEHOLDER_PRODUCER_EVENT_ID or not ev:
            return (snap_label, urn, ev)
    return None

# 阶段 1：占位符前置检查
for snap, label in [(new, "new")] + ([(old, "old")] if old else []):
    hit = scan_placeholder(snap, label)
    if hit:
        attribution_mode = "sha_only"
        # reason 文本避免括号以兼容 shell meta 文件消费（详见主脚本 read 循环）
        attribution_reason = f"placeholder producer_event_id detected in {hit[0]}_snapshot urn={hit[1]}"
        break

# 阶段 2：FULL_MODE 归因反查（05 §5.3 O(N·K) 三步算法）
# 仅当 FULL_MODE=1 且阶段 1 未降级时执行
if FULL_MODE and attribution_mode == "full" and EVENT_JOURNAL_DIR:
    # ---- 载入 event-journal（所有 .jsonl 文件 · 03 §8.2 O1 决议 JSONL 扁平文件）----
    # 索引 event_id → event 记录（O(1) 查询支撑 05 §5.3 步骤 1 的复杂度承诺）
    event_index = {}
    try:
        for root, _dirs, files in os.walk(EVENT_JOURNAL_DIR):
            for fn in sorted(files):
                if not fn.endswith(".jsonl"):
                    continue
                fpath = os.path.join(root, fn)
                with open(fpath, "r", encoding="utf-8") as f:
                    for line_no, line in enumerate(f, 1):
                        line = line.strip()
                        if not line:
                            continue
                        try:
                            ev = json.loads(line)
                        except json.JSONDecodeError as e:
                            sys.stderr.write(f"ERROR: {fpath}:{line_no} invalid JSON: {e}\n")
                            sys.exit(2)
                        eid = ev.get("event_id")
                        if eid:
                            event_index[eid] = ev
    except OSError as e:
        sys.stderr.write(f"ERROR: event-journal-dir unreadable: {e}\n")
        sys.exit(2)

    # ---- 收集所有待归因的 producer_event_id（去重保序）----
    # 归因目标：added/removed/sha_changed 三类 drift 条目
    # 每条 drift 条目可能对应 1～2 个 event_id：
    #   added      → new_producer_event_id
    #   removed    → old_producer_event_id
    #   sha_changed → old_producer_event_id + new_producer_event_id（两条均要归因）
    targets = []  # [(drift_kind_label, artifact_urn, event_id_role, event_id), ...]
    for e in added_list:
        targets.append(("added", e["artifact_urn"], "new", e["new_producer_event_id"]))
    for e in removed_list:
        targets.append(("removed", e["artifact_urn"], "old", e["old_producer_event_id"]))
    for e in sha_changed_list:
        targets.append(("sha_changed", e["artifact_urn"], "old", e["old_producer_event_id"]))
        targets.append(("sha_changed", e["artifact_urn"], "new", e["new_producer_event_id"]))

    # ---- 逐条归因（05 §5.3 三步：event_id → 事件 → task_urn）----
    # 05 §5.2 禁止隐式降级 + 部分归因：任一失败 → 全体 sha_only + 清空 attribution_entries
    for drift_label, art_urn, role, eid in targets:
        if eid not in event_index:
            attribution_mode = "sha_only"
            attribution_reason = f"event-journal missing event_id={eid}"
            attribution_entries = []  # 部分归因禁止：整体清空
            break
        ev = event_index[eid]
        driver_task_urn = ev.get("producer_task_urn") or ev.get("emitted_by") or ""
        driver_event_type = ev.get("event_type", "")
        if not driver_task_urn:
            attribution_mode = "sha_only"
            attribution_reason = f"event missing producer_task_urn event_id={eid}"
            attribution_entries = []
            break
        attribution_entries.append({
            "artifact_urn": art_urn,
            "drift_role": f"{drift_label}.{role}",  # e.g. "sha_changed.old" / "added.new"
            "driver_event_id": eid,
            "driver_event_type": driver_event_type,
            "driver_task_urn": driver_task_urn,
        })

    # ---- initial_snapshot / no_change_drift 场景 ----
    # targets 为空但 FULL_MODE=1 → attribution_entries 为空是合法的 full 模式
    # （归因对象为空 · 不触发降级 · 05 §5.1 "full" 语义为"所有条目都携带有效归因"
    #  · 零条目平凡满足）

# ------------------------------------------------------------------------------
# 写入 attribution body 片段（仅 full 模式 · sha_only 写空文件）
# ------------------------------------------------------------------------------
# body 片段格式对齐 05 §2.3：
#   attribution:
#     - artifact_urn: "..."
#       drift_role: "sha_changed.new"
#       driver_event_id: "..."
#       driver_event_type: "artifact.published"
#       driver_task_urn: "..."

with open(OUT_ATTRIBUTION, "w", encoding="utf-8", newline="\n") as f:
    if attribution_mode == "full":
        if not attribution_entries:
            # full 模式但归因对象为空（initial_snapshot / no_change_drift）
            f.write("attribution: []\n")
        else:
            f.write("attribution:\n")
            for a in attribution_entries:
                for i, (k, v) in enumerate([
                    ("artifact_urn",      a["artifact_urn"]),
                    ("drift_role",        a["drift_role"]),
                    ("driver_event_id",   a["driver_event_id"]),
                    ("driver_event_type", a["driver_event_type"]),
                    ("driver_task_urn",   a["driver_task_urn"]),
                ]):
                    prefix = "  - " if i == 0 else "    "
                    # 字符串值双引号（复用主脚本 quote 规则）
                    if '"' in v:
                        sys.stderr.write(f"ERROR: attribution value contains \": key={k} value={v!r}\n")
                        sys.exit(3)
                    f.write(f'{prefix}{k}: "{v}"\n')
    # sha_only 模式：空文件（主脚本 cat 时不输出 attribution 块）

# ------------------------------------------------------------------------------
# body canonical YAML 构造（05 §2.3 + §2.5 · 对标 04 §3.2.1 五步规范化）
# ------------------------------------------------------------------------------
#
# 输出两个产物：
#   - TMP_BODY：人类可读的 body YAML 片段（拼接到 drift artifact 文件 body 区）
#     仅含 added / removed / sha_changed / unchanged_count 四字段 ——
#     因 diff_base 已在 front-matter 中表达（05 §2.3），body 无需重复。
#   - TMP_SHA_INPUT：参与 sha 计算的 canonical YAML 全量输入（六字段 SHA_WHITELIST）
#     含 diff_base.old_snapshot_urn + diff_base.new_snapshot_urn + 四 body 字段 ——
#     这与 drift artifact 写入文件内容分离，是纯虚拟的 canonical 切片。
#
# 规则（与 04 §3.2.1 五步同构）：
#   - key 固定顺序（05 §2.5 SHA_WHITELIST 数组顺序）
#   - 字符串一律双引号；整数裸写
#   - 两空格缩进
#   - 列表按 artifact_urn 字典序排序（已在上面 sorted() 保证）
#   - 文件末尾恰好一个 \n

def quote(s):
    if '"' in s:
        sys.stderr.write(f"ERROR: value contains double-quote (not allowed by 04 §3.2.1): {s!r}\n")
        sys.exit(3)
    return f'"{s}"'

def emit_list_block(name, entries, key_order):
    lines = [f"{name}:"]
    if not entries:
        lines[0] = f"{name}: []"
        return lines
    for e in entries:
        first = True
        for k in key_order:
            v = e[k]
            prefix = "  - " if first else "    "
            lines.append(f"{prefix}{k}: {quote(v)}")
            first = False
    return lines

body_lines = []
sha_input_lines = []

# sha_input 按 05 §2.5 SHA_WHITELIST 顺序：
#   [ diff_base.old_snapshot_urn, diff_base.new_snapshot_urn,
#     added, removed, sha_changed, unchanged_count ]
#
# initial_snapshot 场景下 old_snapshot_urn = "" （空串占位 · 保证 whitelist 字段不缺项）
sha_input_lines.append("diff_base:")
sha_input_lines.append(f'  old_snapshot_urn: {quote(old["urn"] if old else "")}')
sha_input_lines.append(f'  new_snapshot_urn: {quote(new["urn"])}')
sha_input_lines.append("")

# body_lines 不含 diff_base（已在 front-matter 中 · 避免重复）
for name, entries, key_order in [
    ("added", added_list, ["artifact_urn", "new_sha256", "new_producer_event_id"]),
    ("removed", removed_list, ["artifact_urn", "old_sha256", "old_producer_event_id"]),
    ("sha_changed", sha_changed_list, ["artifact_urn", "old_sha256", "new_sha256", "old_producer_event_id", "new_producer_event_id"]),
]:
    block = emit_list_block(name, entries, key_order)
    body_lines.extend(block)
    body_lines.append("")
    sha_input_lines.extend(block)
    sha_input_lines.append("")

# unchanged_count 放两处末尾
tail = f"unchanged_count: {unchanged_count}"
body_lines.append(tail)
sha_input_lines.append(tail)

body_canonical = "\n".join(body_lines) + "\n"
sha_input_canonical = "\n".join(sha_input_lines) + "\n"

# ------------------------------------------------------------------------------
# content_sha256 计算（05 §2.5 SHA_WHITELIST 六字段 · 04 §3.2.3 承诺 2/3）
# ------------------------------------------------------------------------------
#
# SHA_WHITELIST = [
#   diff_base.old_snapshot_urn,
#   diff_base.new_snapshot_urn,
#   added, removed, sha_changed, unchanged_count
# ]
# sha_input_canonical 已按白名单六字段严格拼接 → 对其 UTF-8 字节流做 sha256
# 即满足"sha256(canonical_yaml(pick_fields(drift, SHA_WHITELIST)))"契约。
#
# 注意：body_canonical ≠ sha_input_canonical
#   - body_canonical：写入 drift artifact 文件的 body 区（不含 diff_base ∵ 已在 front-matter）
#   - sha_input_canonical：虚拟切片（含 diff_base 两字段）· 仅用于 sha 计算
# 这样分离保证：① 文件无冗余 ② sha 输入仍覆盖 SHA_WHITELIST 全部六字段 ③ 消费方
# 验算 sha 时只需 "front-matter.diff_base + body 四字段" 重组即可，无需再次解析 body 中
# 的 diff_base（不存在）与 front-matter 的差异。

with open(OUT_SHA_INPUT, "w", encoding="utf-8", newline="\n") as f:
    f.write(sha_input_canonical)

content_sha = hashlib.sha256(sha_input_canonical.encode("utf-8")).hexdigest()
with open(OUT_SHA, "w", encoding="utf-8") as f:
    f.write(content_sha)

with open(OUT_BODY, "w", encoding="utf-8", newline="\n") as f:
    f.write(body_canonical)

# ------------------------------------------------------------------------------
# meta 输出（供 bash 主脚本消费）
# ------------------------------------------------------------------------------

def esc(s):
    # meta 文件采用 KEY=VALUE 行格式，value 可含 = (消费方 while-read 按首个 = 切分保留其余)；
    # 仅去换行（meta 行结构依赖）。
    return s.replace("\n", " ")

with open(OUT_META, "w", encoding="utf-8") as f:
    f.write(f"SCOPE_KIND={esc(new['scope_kind'])}\n")
    f.write(f"SCOPE_REF={esc(new['scope_ref'])}\n")
    f.write(f"NEW_URN={esc(new['urn'])}\n")
    f.write(f"OLD_URN={esc(old['urn']) if old else ''}\n")
    f.write(f"DRIFT_KIND={drift_kind}\n")
    f.write(f"ATTRIBUTION_MODE={attribution_mode}\n")
    f.write(f"ATTRIBUTION_REASON={esc(attribution_reason)}\n")
    f.write(f"ADDED_COUNT={len(added_list)}\n")
    f.write(f"REMOVED_COUNT={len(removed_list)}\n")
    f.write(f"SHA_CHANGED_COUNT={len(sha_changed_list)}\n")
    f.write(f"UNCHANGED_COUNT={unchanged_count}\n")

sys.stderr.write(
    f"[piao-drift-compute] drift_kind={drift_kind} · "
    f"attribution_mode={attribution_mode} · "
    f"added={len(added_list)} removed={len(removed_list)} "
    f"sha_changed={len(sha_changed_list)} unchanged={unchanged_count} · "
    f"content_sha256={content_sha[:12]}...\n"
)
PYEOF

# ==============================================================================
# 读回 python 产出的 meta，拼接最终 drift yaml
# ==============================================================================
# 使用 while-read 而非 source，因 meta value 可能含 shell 元字符（括号/空格等）。
# meta 文件格式契约（由 python 端保证）：每行 KEY=VALUE · KEY 为 snake_case 大写 · VALUE 可含空格、URN冒号、等号但不含换行。

SCOPE_KIND=""
SCOPE_REF=""
NEW_URN=""
OLD_URN=""
DRIFT_KIND=""
ATTRIBUTION_MODE=""
ATTRIBUTION_REASON=""
ADDED_COUNT=""
REMOVED_COUNT=""
SHA_CHANGED_COUNT=""
UNCHANGED_COUNT=""

while IFS='=' read -r _key _value; do
  [[ -z "$_key" ]] && continue
  # 首个 = 为分隔符；value 中的 = 保留（e.g. reason "urn=...")
  case "$_key" in
    SCOPE_KIND)         SCOPE_KIND="$_value" ;;
    SCOPE_REF)          SCOPE_REF="$_value" ;;
    NEW_URN)            NEW_URN="$_value" ;;
    OLD_URN)            OLD_URN="$_value" ;;
    DRIFT_KIND)         DRIFT_KIND="$_value" ;;
    ATTRIBUTION_MODE)   ATTRIBUTION_MODE="$_value" ;;
    ATTRIBUTION_REASON) ATTRIBUTION_REASON="$_value" ;;
    ADDED_COUNT)        ADDED_COUNT="$_value" ;;
    REMOVED_COUNT)      REMOVED_COUNT="$_value" ;;
    SHA_CHANGED_COUNT)  SHA_CHANGED_COUNT="$_value" ;;
    UNCHANGED_COUNT)    UNCHANGED_COUNT="$_value" ;;
  esac
done < "$TMP_META"

CONTENT_SHA="$(cat "$TMP_SHA_FILE")"

# ------------------------------------------------------------------------------
# drift URN 构造（05 §2.1 · urn:piao:drift:<scope>:<name>@<rev>）
# ------------------------------------------------------------------------------
# scope 段派生（对齐 piao-snapshot-produce.sh 的派生逻辑）
case "$SCOPE_KIND" in
  unit)    SCOPE_SEG="${SCOPE_REF#urn:piao:unit:}" ;;
  stage)   SCOPE_SEG="${SCOPE_REF#urn:piao:stage:}" ;;
  taskdag) SCOPE_SEG="${SCOPE_REF#urn:piao:taskdag:}" ;;
  adapter) SCOPE_SEG="${SCOPE_REF#urn:piao:artifact:}"
           SCOPE_SEG="${SCOPE_SEG%%:*}" ;;
  kernel)  SCOPE_SEG="kernel" ;;
  *) echo "ERROR: unknown scope_kind from snapshot: $SCOPE_KIND" >&2; exit 2 ;;
esac

DRIFT_URN="urn:piao:drift:${SCOPE_SEG}:${NAME}@${REV}"

# ==============================================================================
# 最终 drift yaml 文件拼接
# ==============================================================================

mkdir -p "$(dirname "$OUTPUT")"

# attribution_mode block（05 §5.2 · sha_only 必须写 reason · full 时 reason 为空）
ATTRIBUTION_REASON_LINE=""
if [[ "$ATTRIBUTION_MODE" == "sha_only" ]]; then
  # 按 05 §5.2 强约束：sha_only 必须写明 reason
  ATTRIBUTION_REASON_LINE="  reason: \"${ATTRIBUTION_REASON}\""
else
  ATTRIBUTION_REASON_LINE="  reason: \"\""
fi

{
  cat <<EOF
---
urn: ${DRIFT_URN}
kind: drift
artifact_type: drift.propagation_record
rev: ${REV}
status: published
supersedes: ${SUPERSEDES}
schema_version: "1.0"
produced_by:
  actor: ${ACTOR}
  task_urn: ${TASK_URN}
  event_id: ${EVENT_ID}
produced_at: ${PRODUCED_AT}
diff_base:
  old_snapshot_urn: "${OLD_URN}"
  new_snapshot_urn: "${NEW_URN}"
scope:
  scope_kind: ${SCOPE_KIND}
  scope_ref: ${SCOPE_REF}
drift_kind: ${DRIFT_KIND}
attribution_mode:
  value: ${ATTRIBUTION_MODE}
${ATTRIBUTION_REASON_LINE}
content_sha256: "${CONTENT_SHA}"
---

# drift · ${SCOPE_SEG} · ${NAME}

EOF
  cat "$TMP_BODY"
  # full 模式且 attribution 列表非空时追加（sha_only 模式下 TMP_ATTRIBUTION 为空文件 · 不输出）
  if [[ "$ATTRIBUTION_MODE" == "full" && -s "$TMP_ATTRIBUTION" ]]; then
    echo ""
    cat "$TMP_ATTRIBUTION"
  fi
} > "$OUTPUT"

# ==============================================================================
# --emit-events：N=2 L1 事件同 txn 原子写入（03 §3.3.1 R22 · 05 §6.2）
# ==============================================================================
#
# 两条事件（按 03 §3.1 封板 · 05 §3.2 T5 / §6.2）：
#   E1 · artifact.published(drift) · event_id 前缀 snap-published-* · subject=drift URN
#   E2 · drift.detected           · event_id 前缀 drift-detected-*  · subject=drift URN
#
# 物理落点（对齐 03 §8.2 O1 决议 · JSONL 扁平文件）：
#   <event-journal-dir>/<YYYY-MM>.jsonl
#
# 原子性实现（v0.1 "顺序写 + 失败回滚" · 03 §3.3.1 承诺 1 末段授权）：
#   步骤 1：序列化两条事件到 staging 文件（tmp/piao-drift-txn-<pid>/E1.jsonl · E2.jsonl）
#   步骤 2：在单次 flock 保护下，依次 append E1 → E2 到主 journal 文件
#   步骤 3：任一步失败 → rm 主 journal 中刚追加的行（tail -n 回溯） + rm drift artifact
#          （整体回滚 · 不留半成品 · 不留孤儿 artifact）
#
# 注：本 v0.1 实现不承诺 crash-safe（依赖 03 §3.3.1 承诺 2 的孤儿扫描兜底）·
# 仅承诺"正常执行路径的 all-or-nothing"。

if [[ "$EMIT_EVENTS" == "1" ]]; then
  EMIT_MONTH="$(date -u +'%Y-%m')"
  JOURNAL_FILE="${EVENT_JOURNAL_DIR}/${EMIT_MONTH}.jsonl"
  mkdir -p "$EVENT_JOURNAL_DIR"
  touch "$JOURNAL_FILE"

  # 生成 drift-detected 事件 id（域前缀 drift · 03 §4.1 表格）
  DRIFT_EVENT_ID="drift-detected-$(date -u +'%y%m%d%H%M%S')-$(python3 -c 'import secrets,string;print("".join(secrets.choice(string.ascii_lowercase+string.digits) for _ in range(6)))')"

  # 事件序列化（python3 保证 JSON 正确性 · avoids shell quoting hell）
  EVENTS_STAGING="$(mktemp -d)"
  trap 'rm -f "$TMP_META" "$TMP_BODY" "$TMP_SHA_INPUT" "$TMP_SHA_FILE" "$TMP_ATTRIBUTION"; rm -rf "$EVENTS_STAGING"' EXIT

  python3 - \
    "$EVENTS_STAGING" \
    "$EVENT_ID" "$DRIFT_EVENT_ID" \
    "$DRIFT_URN" "$OLD_URN" "$NEW_URN" \
    "$DRIFT_KIND" "$ATTRIBUTION_MODE" "$ATTRIBUTION_REASON" \
    "$ADDED_COUNT" "$REMOVED_COUNT" "$SHA_CHANGED_COUNT" "$UNCHANGED_COUNT" \
    "$TASK_URN" "$ACTOR" "$PRODUCED_AT" <<'PYEOF2'
"""
序列化 N=2 事件到 staging 文件（每行一个 JSON 对象 · 对齐 JSONL 扁平格式）。

E1 · artifact.published(drift) · 03 §3.1 L1 · 05 §3.2 T5
E2 · drift.detected            · 03 §3.1 L1 · 05 §6.2 (11 必填字段)
"""
import sys, json

(STAGING,
 SNAP_EVENT_ID, DRIFT_EVENT_ID,
 DRIFT_URN, OLD_URN, NEW_URN,
 DRIFT_KIND, ATTR_MODE, ATTR_REASON,
 ADDED, REMOVED, SHA_CHANGED, UNCHANGED,
 TASK_URN, ACTOR, PRODUCED_AT) = sys.argv[1:17]

# E1 · artifact.published(drift)
# 对齐 03 §3.2 通用骨架 + §3.1 artifact.published 语义字段
e1 = {
    "event_id": SNAP_EVENT_ID,
    "event_type": "artifact.published",
    "event_layer": "L1",
    "emitted_at": PRODUCED_AT,
    "emitted_by": ACTOR,
    "subject": DRIFT_URN,                 # 双轨原则：主语 = drift artifact 本身
    "producer_task_urn": TASK_URN,         # 03 §3.1 language 字段
    "artifact_kind": "drift",
    "artifact_type": "drift.propagation_record",
}

# E2 · drift.detected · 05 §6.2 的 11 必填字段全量
e2 = {
    "event_id": DRIFT_EVENT_ID,
    "event_type": "drift.detected",
    "event_layer": "L1",
    "emitted_at": PRODUCED_AT,
    "emitted_by": ACTOR,
    "subject": DRIFT_URN,                 # 双轨原则：subject = drift artifact URN
    "drift_kind": DRIFT_KIND,
    "evidence": {                          # 05 §6.2 evidence 双轨：承载"怎么样"补充
        "old_snapshot_urn": OLD_URN,
        "new_snapshot_urn": NEW_URN,
    },
    "attribution_mode": ATTR_MODE,         # 消费方无需拉 artifact 即可知晓归因能力
    "counts": {                            # 四集合速览 · 消费方判定值不值得拉取
        "added":       int(ADDED),
        "removed":     int(REMOVED),
        "sha_changed": int(SHA_CHANGED),
        "unchanged":   int(UNCHANGED),
    },
}

# sha_only 模式下的 reason 透明暴露（事件层面同步承载 · 05 §5.2）
if ATTR_MODE == "sha_only" and ATTR_REASON:
    e2["attribution_reason"] = ATTR_REASON

# 写 staging（每文件一条事件 · newline 结尾）
for name, payload in [("E1", e1), ("E2", e2)]:
    out = f"{STAGING}/{name}.jsonl"
    with open(out, "w", encoding="utf-8", newline="\n") as f:
        f.write(json.dumps(payload, ensure_ascii=False, sort_keys=True) + "\n")

sys.stderr.write(f"[piao-drift-compute] staged 2 events: E1={SNAP_EVENT_ID} E2={DRIFT_EVENT_ID}\n")
PYEOF2

  # ----------------------------------------------------------------------------
  # N=2 同 txn append（flock 保护 · 失败则整体回滚）
  # ----------------------------------------------------------------------------

  JOURNAL_BEFORE_LINES="$(wc -l < "$JOURNAL_FILE" | tr -d ' ')"

  # 回滚函数：恢复 journal 到追加前的行数 + 删除 drift artifact
  rollback_txn() {
    local reason="$1"
    echo "ERROR: --emit-events txn failed: ${reason}" >&2
    echo "ERROR: rolling back · restoring journal to ${JOURNAL_BEFORE_LINES} lines · removing drift artifact" >&2
    # 恢复 journal 文件行数（head -n 截断）
    head -n "$JOURNAL_BEFORE_LINES" "$JOURNAL_FILE" > "${JOURNAL_FILE}.rollback" && \
      mv "${JOURNAL_FILE}.rollback" "$JOURNAL_FILE"
    # 删除已写入的 drift artifact（不留孤儿 · 03 §3.3.1 承诺 2 精神前置）
    rm -f "$OUTPUT"
    exit 4
  }

  # 顺序追加两条事件（单进程 · 同一脚本内无并发）
  # 注：多进程场景下 v0.1 建议调用方在外层加 flock；v0.2+ 可能内建
  for EVT_NAME in E1 E2; do
    EVT_FILE="${EVENTS_STAGING}/${EVT_NAME}.jsonl"
    if [[ ! -s "$EVT_FILE" ]]; then
      rollback_txn "staging file missing: ${EVT_FILE}"
    fi
    if ! cat "$EVT_FILE" >> "$JOURNAL_FILE"; then
      rollback_txn "append failed for ${EVT_NAME}"
    fi
  done

  echo "[piao-drift-compute] 📮 emitted 2 L1 events to: ${JOURNAL_FILE}"
  echo "[piao-drift-compute]   E1 artifact.published: ${EVENT_ID}"
  echo "[piao-drift-compute]   E2 drift.detected:     ${DRIFT_EVENT_ID}"
fi

# ==============================================================================
# 人类可读摘要输出（stdout · 对齐 produce/diff 风格）
# ==============================================================================

echo "[piao-drift-compute] ✅ produced: $OUTPUT"
echo "[piao-drift-compute] URN:               ${DRIFT_URN}"
echo "[piao-drift-compute] drift_kind:        ${DRIFT_KIND}"
echo "[piao-drift-compute] attribution_mode:  ${ATTRIBUTION_MODE}"
if [[ "$ATTRIBUTION_MODE" == "sha_only" ]]; then
  echo "[piao-drift-compute]   reason:          ${ATTRIBUTION_REASON}"
fi
if [[ "$FULL_MODE" == "1" && "$ATTRIBUTION_MODE" == "full" ]]; then
  ATTRIBUTION_LINES="$(wc -l < "$TMP_ATTRIBUTION" | tr -d ' ')"
  echo "[piao-drift-compute] attribution body:  ${ATTRIBUTION_LINES} lines (from event-journal: ${EVENT_JOURNAL_DIR})"
fi
echo "[piao-drift-compute] counts:            added=${ADDED_COUNT} removed=${REMOVED_COUNT} sha_changed=${SHA_CHANGED_COUNT} unchanged=${UNCHANGED_COUNT}"
echo "[piao-drift-compute] content_sha256:    ${CONTENT_SHA}"
echo "[piao-drift-compute] event_id(artifact): ${EVENT_ID}"
if [[ "$EMIT_EVENTS" == "1" ]]; then
  echo "[piao-drift-compute] event_id(drift):    ${DRIFT_EVENT_ID}"
fi
