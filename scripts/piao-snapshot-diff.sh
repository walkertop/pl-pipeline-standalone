#!/usr/bin/env bash
#
# piao-snapshot-diff.sh — piao-pipeline snapshot_diff 算子（MVP）
#
# 契约依据：
#   - ${PL_ASSETS}/piao/docs/kernel/04-version-snapshot.md @v1.1 published §5
#     snapshot_diff(old_urn, new_urn) → DiffReport {
#       added: List<artifact_urn>
#       removed: List<artifact_urn>
#       modified: List<{urn, old_sha, new_sha, old_producer_event_id, new_producer_event_id}>
#                 （输出命名 sha_changed 对齐 kickoff §2.2 验证条件）
#       unchanged: List<urn>   （MVP：完整列出；kernel §5 允许省略明细只给 count）
#     }
#
# 使用范式：
#   piao-snapshot-diff.sh <old_yaml> <new_yaml> [--format text|json]
#
# 非目标（MVP 明确不做）：
#   - URN 解析（输入直接是本地 yaml 路径，不做 manifest 查询）
#   - 跨 scope_kind 的差分（§5.3 明确禁止，MVP 遇到不一致 scope 直接报错退出）

# shellcheck source=./_env.sh
source "$(dirname "${BASH_SOURCE[0]}")/_env.sh"
set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "usage: $0 <old_yaml> <new_yaml> [--format text|json]" >&2
  exit 2
fi

OLD_YAML="$1"
NEW_YAML="$2"
shift 2

FORMAT="text"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --format) FORMAT="$2"; shift 2 ;;
    *) echo "ERROR: unknown arg: $1" >&2; exit 2 ;;
  esac
done

for f in "$OLD_YAML" "$NEW_YAML"; do
  [[ -f "$f" ]] || { echo "ERROR: not found: $f" >&2; exit 2; }
done

case "$FORMAT" in
  text|json) ;;
  *) echo "ERROR: invalid --format: $FORMAT (allowed: text|json)" >&2; exit 2 ;;
esac

python3 - "$OLD_YAML" "$NEW_YAML" "$FORMAT" <<'PYEOF'
"""
snapshot diff 算子（MVP）

算法：
  1. 从 old / new 两个 snapshot yaml 解析 frozen_scope + frozen_artifacts 列表
  2. 校验 scope_kind / scope_ref 一致（§5.3）
  3. 按 artifact_urn 建立 dict；计算 added / removed / sha_changed / unchanged
  4. 输出 text 或 json 格式

退出码：
  0 = diff 成功执行（无论是否有差异）
  1 = scope 不一致（§5.3 违反）
  2 = yaml 解析失败 / 必要字段缺失
"""
import sys, re, json

OLD_PATH, NEW_PATH, FORMAT = sys.argv[1], sys.argv[2], sys.argv[3]

def parse_snapshot(path):
    """从 snapshot yaml 解析 front-matter 关键字段 + frozen_artifacts 列表。
    MVP 手写解析器（避免依赖 PyYAML），仅覆盖 produce 产出的固定格式。"""
    with open(path, "r", encoding="utf-8") as f:
        text = f.read()

    # 切 front-matter
    if not text.startswith("---\n"):
        sys.stderr.write(f"ERROR: {path}: no front-matter\n"); sys.exit(2)
    end = text.find("\n---\n", 4)
    if end < 0:
        sys.stderr.write(f"ERROR: {path}: front-matter not closed\n"); sys.exit(2)
    fm_text = text[4:end]
    body_text = text[end + 5:]

    # 提取 front-matter 关键字段
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
    content_sha256 = fm_get(r"^content_sha256:\s*\"?([a-f0-9]+)\"?", required=False)

    # 提取 frozen_artifacts 列表
    # 格式固定（由 produce 脚本保证 canonical）：
    #   frozen_artifacts:
    #     - artifact_urn: "..."
    #       content_sha256: "..."
    #       producer_event_id: "..."
    #       producer_task_urn: "..."
    #       artifact_type: "..."
    records = {}
    current = None
    KEY_SET = {"artifact_urn","content_sha256","producer_event_id","producer_task_urn","artifact_type"}

    for line in body_text.splitlines():
        # 列表条目起始
        m = re.match(r'^  -\s+artifact_urn:\s*"([^"]+)"\s*$', line)
        if m:
            if current is not None:
                records[current["artifact_urn"]] = current
            current = {"artifact_urn": m.group(1)}
            continue
        # 延续字段
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
        "urn": urn,
        "scope_kind": scope_kind,
        "scope_ref": scope_ref,
        "content_sha256": content_sha256,
        "frozen_artifacts": records,
    }

old = parse_snapshot(OLD_PATH)
new = parse_snapshot(NEW_PATH)

# §5.3 跨 scope_kind / scope_ref 的 diff 不支持 → 直接抛错
if old["scope_kind"] != new["scope_kind"]:
    sys.stderr.write(f"ERROR: scope_kind mismatch: old={old['scope_kind']} new={new['scope_kind']} (§5.3)\n"); sys.exit(1)
if old["scope_ref"] != new["scope_ref"]:
    sys.stderr.write(f"ERROR: scope_ref mismatch: old={old['scope_ref']} new={new['scope_ref']} (§5.3)\n"); sys.exit(1)

old_urns = set(old["frozen_artifacts"].keys())
new_urns = set(new["frozen_artifacts"].keys())

added_urns     = sorted(new_urns - old_urns)
removed_urns   = sorted(old_urns - new_urns)
common_urns    = sorted(old_urns & new_urns)

sha_changed = []
unchanged = []
for urn in common_urns:
    o = old["frozen_artifacts"][urn]
    n = new["frozen_artifacts"][urn]
    if o.get("content_sha256") != n.get("content_sha256"):
        sha_changed.append({
            "artifact_urn": urn,
            "old_sha256": o.get("content_sha256"),
            "new_sha256": n.get("content_sha256"),
            "old_producer_event_id": o.get("producer_event_id"),
            "new_producer_event_id": n.get("producer_event_id"),
        })
    else:
        unchanged.append(urn)

report = {
    "old": {"urn": old["urn"], "content_sha256": old["content_sha256"]},
    "new": {"urn": new["urn"], "content_sha256": new["content_sha256"]},
    "scope_kind": old["scope_kind"],
    "scope_ref": old["scope_ref"],
    "added": added_urns,
    "removed": removed_urns,
    "sha_changed": sha_changed,
    "unchanged": unchanged,
    "summary": {
        "added_count": len(added_urns),
        "removed_count": len(removed_urns),
        "sha_changed_count": len(sha_changed),
        "unchanged_count": len(unchanged),
        "old_total": len(old_urns),
        "new_total": len(new_urns),
    }
}

if FORMAT == "json":
    print(json.dumps(report, ensure_ascii=False, indent=2, sort_keys=True))
else:
    # text 格式
    print(f"snapshot_diff")
    print(f"  old: {old['urn']}")
    print(f"  new: {new['urn']}")
    print(f"  scope: {old['scope_kind']} / {old['scope_ref']}")
    print()
    print(f"summary:")
    s = report["summary"]
    print(f"  added        = {s['added_count']}")
    print(f"  removed      = {s['removed_count']}")
    print(f"  sha_changed  = {s['sha_changed_count']}")
    print(f"  unchanged    = {s['unchanged_count']}")
    print(f"  (old={s['old_total']} → new={s['new_total']})")
    print()
    if added_urns:
        print("added:")
        for u in added_urns:
            print(f"  + {u}")
        print()
    if removed_urns:
        print("removed:")
        for u in removed_urns:
            print(f"  - {u}")
        print()
    if sha_changed:
        print("sha_changed:")
        for e in sha_changed:
            print(f"  ~ {e['artifact_urn']}")
            print(f"      old: {e['old_sha256']}")
            print(f"      new: {e['new_sha256']}")
        print()
    if unchanged and len(unchanged) <= 20:
        # 小规模时列出；大规模只给 count（§5.1 允许省略明细）
        print("unchanged:")
        for u in unchanged:
            print(f"  = {u}")
    elif unchanged:
        print(f"unchanged: {len(unchanged)} items (list omitted, §5.1 allows count-only)")

PYEOF
