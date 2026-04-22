#!/usr/bin/env bash
#
# piao-contract-drift-compute.sh — 声明契约 vs 宿主实况漂移检测
#
# 新能力（retro-v2 E4 · pl-pipeline v1.1+）：
#   把 adapter.yaml 的 contract 段当作"声明契约"，采集宿主真实状态做 diff。
#   与 piao-drift-compute.sh（snapshot→snapshot）正交，共存不替换。
#
# 数据流:
#   declared  <─adapter.yaml.contract─>  actual(host)
#     ├── expected_files[]                 ├── existing_files
#     ├── peer_versions{npm,python}        ├── installed_versions
#     └── known_bad_combos[]               └── matched_bad_combos
#              ▼  diff
#     drift artifact YAML + trace event piao.contract_drift.detected
#
# 用法:
#   PL_PROJECT=$PWD/examples/demo-fastapi-users \
#     bash scripts/piao-contract-drift-compute.sh --change add-users-api
#
# 选项:
#   --change <id>        pl change 目录名
#   --adapter <path>     adapter 源路径（默认读 .pl-adapter.yaml.installed_from）
#   --output <file>      drift artifact 输出路径
#   --json               机读汇总到 stdout
#   --strict             任意 severity=error 条目令脚本 exit 1
#
# 退出码:
#   0  无 error / 或 非 --strict 模式
#   1  --strict 下命中 error
#   2  参数/环境问题
#   3  adapter 无 contract 段（opt-out）
#
# 注：本脚本把 Python 实现拆到 scripts/_lib/*.py 下，
#     以规避 bash 3.2 `$(cmd <<'EOF'...EOF)` 嵌套多括号时的解析 bug。
#
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/_lib"
# shellcheck source=_env.sh
source "$SCRIPT_DIR/_env.sh"
# shellcheck source=trace-emit.sh
source "$SCRIPT_DIR/trace-emit.sh"

log_info()  { printf "\033[0;34mℹ\033[0m %s\n" "$*" >&2; }
log_ok()    { printf "\033[0;32m✅\033[0m %s\n" "$*" >&2; }
log_warn()  { printf "\033[0;33m⚠\033[0m %s\n" "$*" >&2; }
log_error() { printf "\033[0;31m✗\033[0m %s\n" "$*" >&2; }

CHANGE=""
ADAPTER_PATH=""
OUTPUT=""
JSON_OUT=false
STRICT=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --change)  CHANGE="$2"; shift 2 ;;
    --adapter) ADAPTER_PATH="$2"; shift 2 ;;
    --output)  OUTPUT="$2"; shift 2 ;;
    --json)    JSON_OUT=true; shift ;;
    --strict)  STRICT=true; shift ;;
    -h|--help)
      sed -n '2,32p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
      exit 0 ;;
    *) log_error "unknown arg: $1"; exit 2 ;;
  esac
done

[[ -z "$CHANGE" ]] && { log_error "--change is required"; exit 2; }

ADAPTER_META="${PL_PROJECT}/.pl-adapter.yaml"
[[ ! -f "$ADAPTER_META" ]] && { log_error ".pl-adapter.yaml not found under $PL_PROJECT"; exit 2; }

# ---- 定位 adapter 源 ----
if [[ -z "$ADAPTER_PATH" ]]; then
  raw=$(grep -E '^[[:space:]]+installed_from:' "$ADAPTER_META" | head -1 \
        | sed -E 's/^.*installed_from:[[:space:]]*"([^"]+)".*$/\1/')
  # 纠偏：若 PL_HOME 被外部 session 污染到上级目录，重算
  if [[ "$raw" == *'$PL_HOME'* ]] && [[ ! -d "$PL_HOME/adapters" ]]; then
    _fix_home="$(cd "$SCRIPT_DIR/.." && pwd)"
    [[ -d "$_fix_home/adapters" ]] && export PL_HOME="$_fix_home"
  fi
  ADAPTER_PATH=$(eval echo "$raw")
fi
[[ ! -f "$ADAPTER_PATH/adapter.yaml" ]] && { log_error "adapter.yaml not found at $ADAPTER_PATH"; exit 2; }

log_info "adapter:     $ADAPTER_PATH"
log_info "host:        $PL_PROJECT"
log_info "change:      $CHANGE"

# 临时文件
_tmp_contract=$(mktemp -t pl-contract.XXXXXX)
_tmp_exists=$(mktemp -t pl-exists.XXXXXX)
_tmp_npm=$(mktemp -t pl-npm.XXXXXX)
_tmp_py=$(mktemp -t pl-py.XXXXXX)
_tmp_entries=$(mktemp -t pl-entries.XXXXXX)
cleanup_tmps() {
  rm -f "$_tmp_contract" "$_tmp_exists" "$_tmp_npm" "$_tmp_py" "$_tmp_entries"
}
trap cleanup_tmps EXIT

# ---- 解析 contract ----
python3 "$LIB_DIR/parse-contract.py" "$ADAPTER_PATH/adapter.yaml" > "$_tmp_contract"

contract_size=$(wc -c < "$_tmp_contract")
contract_body=$(cat "$_tmp_contract")
if [[ $contract_size -le 3 ]] || [[ "$contract_body" == "{}" ]] || [[ "$contract_body" == "null" ]]; then
  log_warn "adapter has no contract: {} block — drift skipped (opt-out)"
  trace_init "$CHANGE" "OBSERVE" "script:piao-contract-drift"
  trace_emit "piao.contract_drift.skipped" '{"reason":"no_contract_declared"}'
  $JSON_OUT && jq -nc '{result:"skipped",reason:"no_contract_declared"}'
  exit 3
fi

# ---- 采集 host state ----
python3 "$LIB_DIR/collect-exists.py" "$PL_PROJECT" > "$_tmp_exists"

: > "$_tmp_npm"
if [[ -f "$PL_PROJECT/package-lock.json" ]]; then
  python3 "$LIB_DIR/collect-npm.py" "$PL_PROJECT/package-lock.json" > "$_tmp_npm"
elif [[ -f "$PL_PROJECT/package.json" ]]; then
  python3 "$LIB_DIR/collect-npm.py" "$PL_PROJECT/package.json" > "$_tmp_npm"
fi

: > "$_tmp_py"
if [[ -f "$PL_PROJECT/uv.lock" ]]; then
  python3 "$LIB_DIR/collect-python.py" "$PL_PROJECT/uv.lock" > "$_tmp_py"
elif [[ -f "$PL_PROJECT/pyproject.toml" ]]; then
  python3 "$LIB_DIR/collect-python.py" "$PL_PROJECT/pyproject.toml" > "$_tmp_py"
fi

# ---- diff ----
python3 "$LIB_DIR/diff-contract.py" "$_tmp_contract" "$_tmp_exists" "$_tmp_npm" "$_tmp_py" "$PL_PROJECT" > "$_tmp_entries"

# ---- summary ----
SUMMARY=$(python3 "$LIB_DIR/summarize-drift.py" "$_tmp_entries" --summary)

# ---- drift artifact YAML ----
OUTPUT="${OUTPUT:-$PL_OUTPUT/drift/${CHANGE}-contract.yaml}"
mkdir -p "$(dirname "$OUTPUT")"

TS=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
ADAPTER_ID=$(grep -E '^[[:space:]]+id:' "$ADAPTER_META" | head -1 | sed -E 's/^[[:space:]]+id:[[:space:]]*//')

{
  echo "# piao contract drift artifact · pl-pipeline v1.1 · retro-v2 E4"
  echo "# Generated by piao-contract-drift-compute.sh"
  echo "apiVersion: piao.dev/v1"
  echo "kind: ContractDrift"
  echo "metadata:"
  echo "  change_id: \"$CHANGE\""
  echo "  adapter_id: \"$ADAPTER_ID\""
  echo "  host: \"$PL_PROJECT\""
  echo "  generated_at: \"$TS\""
  echo "  drift_kind: contract_drift"
  echo "summary: $SUMMARY"
  echo "entries:"
  python3 "$LIB_DIR/summarize-drift.py" "$_tmp_entries" --yaml
} > "$OUTPUT"

log_ok "drift artifact written: $OUTPUT"

# ---- trace event ----
trace_init "$CHANGE" "OBSERVE" "script:piao-contract-drift"
_drift_payload=$(jq -nc \
  --arg adapter "$ADAPTER_ID" \
  --arg artifact "$OUTPUT" \
  --argjson summary "$SUMMARY" \
  '{adapter:$adapter, artifact:$artifact, counts:$summary, drift_kind:"contract_drift"}')
trace_emit "piao.contract_drift.detected" "$_drift_payload"

# ---- 输出 ----
err=$(echo "$SUMMARY"  | python3 -c 'import json,sys;print(json.load(sys.stdin)["error"])')
warn=$(echo "$SUMMARY" | python3 -c 'import json,sys;print(json.load(sys.stdin)["warn"])')
total=$(echo "$SUMMARY" | python3 -c 'import json,sys;print(json.load(sys.stdin)["total"])')

echo ""
if [[ "$total" -eq 0 ]]; then
  log_ok "No contract drift detected. Host is aligned with declared contract."
else
  log_warn "Contract drift summary: $total entries ($err error, $warn warn)"
  python3 "$LIB_DIR/summarize-drift.py" "$_tmp_entries" --console
fi

if $JSON_OUT; then
  python3 -c "
import json
s = json.loads('$SUMMARY')
print(json.dumps({'drift_kind':'contract_drift','artifact':'$OUTPUT','summary':s}))
"
fi

if $STRICT && [[ "$err" -gt 0 ]]; then
  exit 1
fi

exit 0
