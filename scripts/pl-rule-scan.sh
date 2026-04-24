#!/usr/bin/env bash
#
# pl-rule-scan.sh — 从 adapter 注入的 rule 文件中扫"可执行检测"，对宿主代码打分
#
# 新能力（retro-v2 E3 · pl-pipeline v1.1+）：
#   把 rule/skill 里的"知识"从"AI prompt"升级为"CI 可执行 linter"。
#   只对声明了 YAML frontmatter 的 rule 文件生效；doc-only rule 静默跳过。
#
# rule frontmatter 最小 schema（向后兼容：没有 frontmatter 的 rule 继续是纯文档）：
#
#   ---
#   id: my-rule-id                # kebab-case, 必填
#   severity: error | warn | info # 默认 warn
#   scope: always | on-demand     # always=每次扫都跑，默认；on-demand 需 --rule <id>
#   applies_to:
#     glob: ["**/app/_actions/**/*.ts"]
#     exclude_glob: ["**/node_modules/**"]
#   detect:                       # 多 detect AND 语义
#     - kind: file_contains       # 必须含该 regex
#       pattern: "'use server'"
#     - kind: file_contains
#       pattern: "revalidateTag\\("
#     - kind: file_not_contains   # 必须不含该 regex
#       pattern: "fetch\\("
#   message: |
#     （可多行）违规原因 + 背景
#   fix_hint: 改用 revalidatePath('/your/path')
#   ---
#   （下面是纯文档 body，不受 E3 影响）
#
# 数据流:
#   rule frontmatter（声明侧）
#           ▼
#   applies_to.glob → 候选文件 → 逐 file 跑 detect[] AND 匹配
#           ▼
#   违规条目 → YAML artifact + trace 事件 piao.rule_violation.detected
#
# 用法:
#   PL_PROJECT=$PWD/examples/demo-nextjs-todo \
#     bash scripts/pl-rule-scan.sh --change add-todo-list
#
# 选项:
#   --change <id>        pl change id
#   --rule <id>          只跑某条（覆盖 scope=on-demand）
#   --output <file>      自定义输出路径
#   --json               stdout 打印机读 summary
#   --strict             severity=error 条目令脚本 exit 1
#
# 退出码:
#   0  无 error / 非 --strict
#   1  --strict 下命中 error
#   2  参数或环境错误
#   3  无任何可执行 rule（所有 rule 都是纯文档，opt-out）
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
ONLY_RULE=""
OUTPUT=""
JSON_OUT=false
STRICT=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --change) CHANGE="$2"; shift 2 ;;
    --rule)   ONLY_RULE="$2"; shift 2 ;;
    --output) OUTPUT="$2"; shift 2 ;;
    --json)   JSON_OUT=true; shift ;;
    --strict) STRICT=true; shift ;;
    -h|--help)
      sed -n '2,50p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
      exit 0 ;;
    *) log_error "unknown arg: $1"; exit 2 ;;
  esac
done

[[ -z "$CHANGE" ]] && { log_error "--change is required"; exit 2; }

# 规则根目录：v1.12 起 adapter-install 同时写 canonical pl/.adapter/rules 和 legacy .codebuddy/rules
# 三层资产栈解析：项目层 > adapter 层 > legacy（兼容 v1.11 及以前）
RULES_DIR=""
for cand in \
    "$PL_PROJECT/pl/rules" \
    "$PL_PROJECT/pl/.adapter/rules" \
    "$PL_PROJECT/.codebuddy/rules"; do
  if [[ -d "$cand" ]] && find "$cand" -maxdepth 1 -type f -name '*.md' | grep -q .; then
    RULES_DIR="$cand"
    break
  fi
done
if [[ -z "$RULES_DIR" ]]; then
  log_warn "no rules dir found (tried pl/rules, pl/.adapter/rules, .codebuddy/rules) under $PL_PROJECT — nothing to scan"
  trace_init "$CHANGE" "OBSERVE" "script:pl-rule-scan"
  trace_emit "pl.rule_scan.skipped" '{"reason":"no_rules_dir"}'
  $JSON_OUT && echo '{"result":"skipped","reason":"no_rules_dir"}'
  exit 3
fi

log_info "rules dir:   $RULES_DIR"
log_info "host:        $PL_PROJECT"
log_info "change:      $CHANGE"
[[ -n "$ONLY_RULE" ]] && log_info "only rule:   $ONLY_RULE"

# 临时文件
_tmp_vio_all=$(mktemp -t pl-rule-vio-all.XXXXXX.json)
cleanup_tmps() {
  rm -f "$_tmp_vio_all"
}
trap cleanup_tmps EXIT
echo "[]" > "$_tmp_vio_all"

EXECUTABLE_RULES=0
TOTAL_RULES=0

# 遍历所有 rule 文件
shopt -s nullglob
RULE_FILES=("$RULES_DIR"/*.md)
shopt -u nullglob

for rule_path in "${RULE_FILES[@]}"; do
  TOTAL_RULES=$((TOTAL_RULES + 1))
  _tmp_fm=$(mktemp -t pl-rule-fm.XXXXXX.json)
  python3 "$LIB_DIR/parse-rule-frontmatter.py" "$rule_path" > "$_tmp_fm"

  fm_size=$(wc -c < "$_tmp_fm" | tr -d ' ')
  fm_body=$(cat "$_tmp_fm")
  if [[ "$fm_size" -le 3 ]] || [[ "$fm_body" == "{}" ]] || [[ "$fm_body" == "null" ]]; then
    rm -f "$_tmp_fm"
    continue   # doc-only rule，跳过
  fi

  # 读 id / scope
  rule_id=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1])).get("id",""))' "$_tmp_fm")
  rule_scope=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1])).get("scope","always"))' "$_tmp_fm")

  # 过滤 on-demand
  if [[ "$rule_scope" == "on-demand" ]] && [[ "$ONLY_RULE" != "$rule_id" ]]; then
    rm -f "$_tmp_fm"
    continue
  fi
  # --rule 指定时只跑该 id
  if [[ -n "$ONLY_RULE" ]] && [[ "$ONLY_RULE" != "$rule_id" ]]; then
    rm -f "$_tmp_fm"
    continue
  fi

  EXECUTABLE_RULES=$((EXECUTABLE_RULES + 1))
  log_info "running rule: $rule_id"

  # 采集 applies_to.glob 命中的文件
  include_globs=$(python3 -c '
import json, sys
fm = json.load(open(sys.argv[1]))
a = fm.get("applies_to") or {}
globs = a.get("glob") or []
if isinstance(globs, str): globs = [globs]
print("\n".join(globs))
' "$_tmp_fm")
  exclude_globs=$(python3 -c '
import json, sys
fm = json.load(open(sys.argv[1]))
a = fm.get("applies_to") or {}
globs = a.get("exclude_glob") or []
if isinstance(globs, str): globs = [globs]
print("\n".join(globs))
' "$_tmp_fm")

  _tmp_files=$(mktemp -t pl-rule-files.XXXXXX)
  # 构造参数
  args=("$PL_PROJECT")
  while IFS= read -r g; do [[ -n "$g" ]] && args+=("$g"); done <<< "$include_globs"
  if [[ -n "$exclude_globs" ]]; then
    args+=("--exclude")
    while IFS= read -r g; do [[ -n "$g" ]] && args+=("$g"); done <<< "$exclude_globs"
  fi
  python3 "$LIB_DIR/collect-rule-files.py" "${args[@]}" > "$_tmp_files"

  file_count=$(wc -l < "$_tmp_files" | tr -d ' ')
  if [[ "$file_count" -eq 0 ]]; then
    log_info "  no files match applies_to; skip"
    rm -f "$_tmp_fm" "$_tmp_files"
    continue
  fi

  # 跑匹配
  _tmp_vio=$(mktemp -t pl-rule-vio.XXXXXX.json)
  python3 "$LIB_DIR/match-rule.py" "$_tmp_fm" "$_tmp_files" "$PL_PROJECT" > "$_tmp_vio"

  # 合并 violations
  _tmp_merged=$(mktemp -t pl-rule-merge.XXXXXX.json)
  python3 - "$_tmp_vio_all" "$_tmp_vio" > "$_tmp_merged" <<'PYEOF'
import sys, json
with open(sys.argv[1]) as f: a = json.load(f)
with open(sys.argv[2]) as f: b = json.load(f)
print(json.dumps(a + b, ensure_ascii=False))
PYEOF
  mv "$_tmp_merged" "$_tmp_vio_all"
  rm -f "$_tmp_fm" "$_tmp_files" "$_tmp_vio"
done

if [[ "$EXECUTABLE_RULES" -eq 0 ]]; then
  log_warn "all $TOTAL_RULES rules are doc-only (no frontmatter) — nothing scanned"
  trace_init "$CHANGE" "OBSERVE" "script:pl-rule-scan"
  trace_emit "pl.rule_scan.skipped" "$(jq -nc --argjson total "$TOTAL_RULES" '{reason:"no_executable_rules", total_rules:$total}')"
  $JSON_OUT && echo '{"result":"skipped","reason":"no_executable_rules"}'
  exit 3
fi

# Summary
SUMMARY=$(python3 "$LIB_DIR/summarize-rules.py" "$_tmp_vio_all" --summary)

# Artifact
OUTPUT="${OUTPUT:-$PL_OUTPUT/rule-scan/${CHANGE}.yaml}"
mkdir -p "$(dirname "$OUTPUT")"
TS=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

{
  echo "# pl rule scan · pl-pipeline v1.1+ · retro-v2 E3"
  echo "# Generated by pl-rule-scan.sh"
  echo "apiVersion: pl.dev/v1"
  echo "kind: RuleScanReport"
  echo "metadata:"
  echo "  change_id: \"$CHANGE\""
  echo "  host: \"$PL_PROJECT\""
  echo "  rules_dir: \"$RULES_DIR\""
  echo "  executable_rules: $EXECUTABLE_RULES"
  echo "  doc_only_rules: $((TOTAL_RULES - EXECUTABLE_RULES))"
  echo "  generated_at: \"$TS\""
  echo "summary: $SUMMARY"
  echo "violations:"
  python3 "$LIB_DIR/summarize-rules.py" "$_tmp_vio_all" --yaml
} > "$OUTPUT"

log_ok "rule-scan artifact: $OUTPUT"

# trace
trace_init "$CHANGE" "OBSERVE" "script:pl-rule-scan"
_payload=$(jq -nc \
  --arg artifact "$OUTPUT" \
  --argjson summary "$SUMMARY" \
  --argjson executable "$EXECUTABLE_RULES" \
  '{artifact:$artifact, counts:$summary, executable_rules:$executable}')
trace_emit "pl.rule_scan.completed" "$_payload"

# 判定
err=$(echo  "$SUMMARY" | python3 -c 'import json,sys;print(json.load(sys.stdin)["error"])')
warn=$(echo "$SUMMARY" | python3 -c 'import json,sys;print(json.load(sys.stdin)["warn"])')
total=$(echo "$SUMMARY" | python3 -c 'import json,sys;print(json.load(sys.stdin)["total"])')

echo ""
if [[ "$total" -eq 0 ]]; then
  log_ok "No rule violations ($EXECUTABLE_RULES executable rule(s) checked)."
else
  log_warn "$total violation(s): $err error, $warn warn"
  python3 "$LIB_DIR/summarize-rules.py" "$_tmp_vio_all" --console
fi

if $JSON_OUT; then
  python3 -c "
import json
s = json.loads('$SUMMARY')
print(json.dumps({'artifact':'$OUTPUT','summary':s,'executable_rules':$EXECUTABLE_RULES}))
"
fi

if $STRICT && [[ "$err" -gt 0 ]]; then
  exit 1
fi
exit 0
