#!/usr/bin/env bash
# =============================================================================
# pl-runner.sh — E1 可执行契约层 / 统一 Gate & Check 执行器
# =============================================================================
#
# 职责：读取 pl/config.yaml 的 gates: 和 checks: 节，按契约执行，派生 gate 结果，
#       将每一步写入 $PL_OUTPUT/trace/<change>.events.jsonl。
#
# 用法:
#   pl-runner.sh --change <id> --gate <gate-id>
#   pl-runner.sh --change <id> --check <check-id>
#   pl-runner.sh --change <id> --gate D --dry-run
#   pl-runner.sh --change <id> --gate D --json        # 输出 gate 评估结果 JSON
#
# 退出码:
#   0 = gate passed 或 check pass
#   1 = gate blocked 或 check fail
#   2 = 参数错误 / 配置错误
#
# 环境变量解析优先级:
#   1. 宿主 $PL_PROJECT/.pl-adapter.yaml 的 build_adapter.env
#   2. 调用时已 export 的环境变量
#   3. check.cmd 里的 ${VAR} 若解析后仍为空，且 check.required=false → 跳过
#                                               若 check.required=true  → fail
# =============================================================================

# shellcheck source=./_env.sh
source "$(dirname "${BASH_SOURCE[0]}")/_env.sh"
# shellcheck source=./trace-emit.sh
source "$(dirname "${BASH_SOURCE[0]}")/trace-emit.sh"
set -uo pipefail

# ---- 颜色 ----
if [[ -t 1 ]]; then
  RED=$'\033[0;31m'; GREEN=$'\033[0;32m'; YELLOW=$'\033[0;33m'
  BLUE=$'\033[0;34m'; BOLD=$'\033[1m'; DIM=$'\033[2m'; NC=$'\033[0m'
else
  RED=; GREEN=; YELLOW=; BLUE=; BOLD=; DIM=; NC=
fi

log_info()  { echo "${BLUE}ℹ${NC} $*"; }
log_ok()    { echo "${GREEN}✅${NC} $*"; }
log_warn()  { echo "${YELLOW}⚠${NC}  $*"; }
log_error() { echo "${RED}✗${NC}  $*" >&2; }

# ---- 参数 ----
CHANGE=""
GATE=""
CHECK=""
DRY_RUN=false
JSON_OUT=false
CONFIG=""

usage() {
  sed -n '2,27p' "$0" | sed 's/^# \{0,1\}//'
  exit 2
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --change) CHANGE="$2"; shift 2 ;;
    --gate)   GATE="$2"; shift 2 ;;
    --check)  CHECK="$2"; shift 2 ;;
    --config) CONFIG="$2"; shift 2 ;;
    --dry-run) DRY_RUN=true; shift ;;
    --json)   JSON_OUT=true; shift ;;
    -h|--help) usage ;;
    *) log_error "Unknown option: $1"; usage ;;
  esac
done

[[ -z "$CHANGE" ]] && { log_error "Missing --change <id>"; usage; }
[[ -z "$GATE" && -z "$CHECK" ]] && { log_error "Must provide --gate or --check"; usage; }

# 默认从宿主 pl/config.yaml 找；否则用 pl-core 自带的 default
if [[ -z "$CONFIG" ]]; then
  if [[ -f "$PL_PROJECT/pl/config.yaml" ]]; then
    CONFIG="$PL_PROJECT/pl/config.yaml"
  else
    CONFIG="$PL_ASSETS/pl/config.default.yaml"
  fi
fi
[[ -f "$CONFIG" ]] || { log_error "Config not found: $CONFIG"; exit 2; }

# ---- 用 python 解析 yaml，输出我们要用的扁平结构 ----
parse_config() {
  python3 - "$CONFIG" "$GATE" "$CHECK" <<'PYEOF'
import sys, os, re, json

CONFIG_PATH = sys.argv[1]
GATE_ID = sys.argv[2]
CHECK_ID = sys.argv[3]

# 复用 adapter-validate 的 minimal parser（保持独立不依赖 PyYAML）
def minimal_yaml_load(text):
    lines = text.split('\n')
    clean = []
    for ln in lines:
        s = ln.rstrip()
        t = s.lstrip()
        if not t or t.startswith('#'):
            clean.append(''); continue
        if ' #' in s and s.count('"') % 2 == 0 and s.count("'") % 2 == 0:
            s = s[:s.rfind(' #')].rstrip()
        clean.append(s)

    def parse_scalar(val):
        val = val.strip()
        if val in ('', '~', 'null'): return None
        if val == 'true': return True
        if val == 'false': return False
        if (val.startswith('"') and val.endswith('"')) or (val.startswith("'") and val.endswith("'")):
            return val[1:-1]
        if val.startswith('[') and val.endswith(']'):
            inner = val[1:-1].strip()
            return [parse_scalar(p.strip()) for p in inner.split(',')] if inner else []
        try: return int(val)
        except: pass
        try: return float(val)
        except: pass
        return val

    def indent_of(line):
        if not line: return -1
        i = 0
        while i < len(line) and line[i] == ' ': i += 1
        return i

    pos = [0]
    def parse_block(indent):
        result = None
        while pos[0] < len(clean):
            line = clean[pos[0]]
            if not line: pos[0] += 1; continue
            cur = indent_of(line)
            if cur < indent: return result
            content = line[cur:]
            if content.startswith('- '):
                if result is None: result = []
                elif not isinstance(result, list): return result
                body = content[2:]
                if ':' in body and not body.startswith(('"', "'")):
                    k, _, v = body.partition(':')
                    k, v = k.strip(), v.strip()
                    pos[0] += 1
                    item = {}
                    if v: item[k] = parse_scalar(v)
                    else:
                        n = parse_block(cur + 2)
                        if n is not None: item[k] = n
                    while pos[0] < len(clean):
                        ln2 = clean[pos[0]]
                        if not ln2: pos[0] += 1; continue
                        i2 = indent_of(ln2)
                        if i2 < cur + 2: break
                        if ln2[cur+2:].startswith('- '): break
                        sc = ln2[cur+2:]
                        if ':' not in sc: break
                        sk, _, sv = sc.partition(':')
                        sk, sv = sk.strip(), sv.strip()
                        pos[0] += 1
                        if sv: item[sk] = parse_scalar(sv)
                        else:
                            n = parse_block(cur + 4)
                            if n is not None: item[sk] = n
                    result.append(item)
                elif body.strip():
                    result.append(parse_scalar(body)); pos[0] += 1
                else:
                    pos[0] += 1
                    n = parse_block(cur + 2)
                    result.append(n if n is not None else {})
            elif ':' in content:
                if result is None: result = {}
                elif not isinstance(result, dict): return result
                k, _, v = content.partition(':')
                k, v = k.strip(), v.strip()
                pos[0] += 1
                if v: result[k] = parse_scalar(v)
                else:
                    n = parse_block(cur + 2)
                    result[k] = n if n is not None else {}
            else:
                pos[0] += 1
        return result
    return parse_block(0) or {}

try:
    import yaml
    with open(CONFIG_PATH) as f:
        cfg = yaml.safe_load(f)
except ImportError:
    with open(CONFIG_PATH) as f:
        cfg = minimal_yaml_load(f.read())

checks_pool = {c['id']: c for c in (cfg.get('checks') or []) if isinstance(c, dict) and 'id' in c}
gates = cfg.get('gates') or {}

def resolve_check(ref):
    if isinstance(ref, str):
        c = checks_pool.get(ref)
        if c is None:
            return None
        return dict(c, _ref=ref)
    if isinstance(ref, dict) and 'id' in ref:
        return dict(ref, _ref='<inline>')
    return None

out = {'mode': None, 'items': []}

if GATE_ID:
    g = gates.get(GATE_ID)
    if g is None:
        print(json.dumps({'error': f'gate {GATE_ID} not found'}))
        sys.exit(2)
    out['mode'] = 'gate'
    out['gate'] = {
        'id': GATE_ID,
        'from': g.get('from'),
        'to': g.get('to'),
        'eval': g.get('eval', 'all_checks.pass'),
        'on_failure': g.get('on_failure', 'block'),
    }
    for ref in (g.get('checks') or []):
        ck = resolve_check(ref)
        if ck is not None:
            out['items'].append(ck)
elif CHECK_ID:
    c = checks_pool.get(CHECK_ID)
    if c is None:
        print(json.dumps({'error': f'check {CHECK_ID} not found'}))
        sys.exit(2)
    out['mode'] = 'check'
    out['items'].append(c)

print(json.dumps(out))
PYEOF
}

RESOLVED=$(parse_config)
if echo "$RESOLVED" | grep -q '"error":'; then
  err=$(echo "$RESOLVED" | python3 -c 'import json,sys;print(json.load(sys.stdin)["error"])')
  log_error "$err"
  exit 2
fi

MODE=$(echo "$RESOLVED" | python3 -c 'import json,sys;print(json.load(sys.stdin).get("mode",""))')

# ---- 从宿主 .pl-adapter.yaml 加载 build_adapter.env ----
ADAPTER_META="$PL_PROJECT/.pl-adapter.yaml"
if [[ -f "$ADAPTER_META" ]]; then
  # 用 python 提取 build_adapter.env.* 并以 KEY=VALUE 形式输出
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    eval "export $line"
  done < <(python3 - "$ADAPTER_META" <<'PYEOF'
import sys, shlex, re
with open(sys.argv[1]) as f:
    txt = f.read()
# 简易提取 build_adapter.env 下的 KEY: "VALUE"
in_env = False
base_indent = None
for line in txt.splitlines():
    if re.match(r'^\s*env:\s*$', line):
        in_env = True
        base_indent = len(line) - len(line.lstrip())
        continue
    if in_env:
        stripped = line.strip()
        if not stripped or stripped.startswith('#'):
            continue
        indent = len(line) - len(line.lstrip())
        if indent <= base_indent:
            in_env = False
            continue
        m = re.match(r'^([A-Z_][A-Z0-9_]*)\s*:\s*(.*)$', stripped)
        if m:
            k, v = m.group(1), m.group(2).strip()
            if v.startswith('"') and v.endswith('"'):
                v = v[1:-1]
                # YAML double-quoted style: unescape \" \\ \n \t
                v = v.replace('\\"', '"').replace("\\'", "'").replace('\\\\', '\\').replace('\\n', '\n').replace('\\t', '\t')
            elif v.startswith("'") and v.endswith("'"):
                v = v[1:-1].replace("''", "'")
            print(f"{k}={shlex.quote(v)}")
PYEOF
)
fi

# ---- 替换 cmd 里的 ${VAR} 占位 ----
expand_vars() {
  local raw="$1"
  # 只展开 ${VAR} / ${VAR:-default}，用 envsubst 如有；fallback 到 eval echo
  if command -v envsubst >/dev/null 2>&1; then
    echo "$raw" | envsubst
  else
    # safe-ish fallback
    eval "echo \"$(echo "$raw" | sed 's/"/\\"/g')\""
  fi
}

# ---- 执行一个 check ----
# 返回 0=pass 1=fail 2=skip
run_check() {
  local check_json="$1"
  local id label raw_cmd cwd timeout success_pattern required
  id=$(echo "$check_json" | python3 -c 'import json,sys;c=json.load(sys.stdin);print(c.get("id",""))')
  label=$(echo "$check_json" | python3 -c 'import json,sys;c=json.load(sys.stdin);print(c.get("label",""))')
  raw_cmd=$(echo "$check_json" | python3 -c 'import json,sys;c=json.load(sys.stdin);print(c.get("cmd",""))')
  cwd=$(echo "$check_json" | python3 -c 'import json,sys;c=json.load(sys.stdin);print(c.get("cwd",""))')
  timeout=$(echo "$check_json" | python3 -c 'import json,sys;c=json.load(sys.stdin);print(c.get("timeout_sec",180))')
  success_pattern=$(echo "$check_json" | python3 -c 'import json,sys;c=json.load(sys.stdin);print(c.get("success_pattern",""))')
  required=$(echo "$check_json" | python3 -c 'import json,sys;c=json.load(sys.stdin);print(str(c.get("required",True)).lower())')

  local cmd
  cmd=$(expand_vars "$raw_cmd")

  # 占位未解析：检查 cmd 是否还含 ${
  if [[ -z "${cmd// /}" ]] || echo "$cmd" | grep -qE '\$\{[A-Z_]'; then
    if [[ "$required" == "true" ]]; then
      log_error "check '$id' cmd unresolved (missing env var): $raw_cmd"
      trace_emit "check.run" "$(jq -nc --arg id "$id" --arg cmd "$raw_cmd" \
        '{checker:$id,cmd:$cmd,status:"fail",reason:"env_unresolved"}')"
      return 1
    else
      log_warn "check '$id' skipped (no cmd resolved, required=false)"
      trace_emit "check.run" "$(jq -nc --arg id "$id" \
        '{checker:$id,status:"skip",reason:"cmd_not_provided"}')"
      return 2
    fi
  fi

  local work_dir="${cwd:-$PL_PROJECT}"
  if [[ ! -d "$work_dir" ]]; then
    log_error "check '$id' cwd missing: $work_dir"
    return 1
  fi

  log_info "[$id] ${label:-$id}  ${DIM}\$ $cmd${NC}"

  if $DRY_RUN; then
    trace_emit "check.run" "$(jq -nc --arg id "$id" --arg cmd "$cmd" \
      '{checker:$id,cmd:$cmd,status:"dryrun"}')"
    return 0
  fi

  local t0 out rc
  t0=$(date +%s)
  # 带超时执行。优先 timeout/gtimeout，没有就裸跑（大多数 check 都秒级完成）
  if command -v timeout >/dev/null 2>&1; then
    out=$(cd "$work_dir" && timeout "${timeout}s" bash -c "$cmd" 2>&1) || rc=$?
  elif command -v gtimeout >/dev/null 2>&1; then
    out=$(cd "$work_dir" && gtimeout "${timeout}s" bash -c "$cmd" 2>&1) || rc=$?
  else
    out=$(cd "$work_dir" && bash -c "$cmd" 2>&1) || rc=$?
  fi
  rc="${rc:-0}"
  local duration=$(( $(date +%s) - t0 ))

  # success pattern 检查
  local pattern_ok=true
  if [[ -n "$success_pattern" ]]; then
    if ! echo "$out" | grep -Eq "$success_pattern"; then
      pattern_ok=false
    fi
  fi

  local status reason=""
  if [[ $rc -eq 0 ]] && $pattern_ok; then
    status=pass
    log_ok "[$id] pass (${duration}s)"
  else
    status=fail
    if [[ $rc -ne 0 ]]; then
      reason="exit_code=$rc"
    else
      reason="success_pattern_miss"
    fi
    log_error "[$id] fail (${duration}s): $reason"
    echo "$out" | tail -5 | sed 's/^/    /'
  fi

  # trace emit
  trace_emit "check.run" "$(jq -nc \
    --arg id "$id" --arg cmd "$cmd" --arg status "$status" \
    --arg reason "$reason" --argjson dur "$duration" \
    '{checker:$id,cmd:$cmd,status:$status,duration_sec:$dur} + (if $reason != "" then {reason:$reason} else {} end)')"

  # consumer→adapter 使用证据：若原始 cmd 引用了 adapter 注入的 ${PL_*} env，
  # 就记一条 adapter.use 事件（仅观测，不阻塞）。后续 broker 脚本可聚合产 consumer pact。
  local consumed_env
  consumed_env=$(echo "$raw_cmd" | grep -oE '\$\{PL_[A-Z0-9_]+(:-[^}]*)?\}' | sed -E 's/\$\{([A-Z0-9_]+).*/\1/' | sort -u | tr '\n' ',' | sed 's/,$//')
  if [[ -n "$consumed_env" ]]; then
    trace_adapter_use "build_command" "$id" "$(jq -nc \
      --arg env "$consumed_env" --arg cmd "$cmd" --arg status "$status" \
      '{via_env:$env, cmd:$cmd, status:$status}')"
  fi

  if [[ "$status" == "pass" ]]; then
    return 0
  else
    return 1
  fi
}

# ---- 主流程 ----
cd "$PL_PROJECT"

if [[ "$MODE" == "check" ]]; then
  # 单 check 模式
  trace_init "$CHANGE" "CHECK" "script:pl-runner"
  ITEM=$(echo "$RESOLVED" | python3 -c 'import json,sys;print(json.dumps(json.load(sys.stdin)["items"][0]))')
  if run_check "$ITEM"; then
    exit 0
  else
    exit 1
  fi
fi

# gate 模式
GATE_FROM=$(echo "$RESOLVED" | python3 -c 'import json,sys;print(json.load(sys.stdin)["gate"].get("from",""))')
GATE_TO=$(echo "$RESOLVED" | python3 -c 'import json,sys;print(json.load(sys.stdin)["gate"].get("to",""))')
GATE_EVAL=$(echo "$RESOLVED" | python3 -c 'import json,sys;print(json.load(sys.stdin)["gate"].get("eval","all_checks.pass"))')
GATE_ON_FAILURE=$(echo "$RESOLVED" | python3 -c 'import json,sys;print(json.load(sys.stdin)["gate"].get("on_failure","block"))')

trace_init "$CHANGE" "$GATE_FROM" "script:pl-runner"
trace_gate_start "$GATE" "$(jq -nc --arg from "$GATE_FROM" --arg to "$GATE_TO" \
  '{from:$from,to:$to}')"

echo "${BOLD}━━━ Gate $GATE ━━━${NC}"
echo "  from: $GATE_FROM  →  to: $GATE_TO"
echo "  eval: $GATE_EVAL"
echo ""

ITEMS_COUNT=$(echo "$RESOLVED" | python3 -c 'import json,sys;print(len(json.load(sys.stdin)["items"]))')
if [[ "$ITEMS_COUNT" -eq 0 ]]; then
  log_warn "gate '$GATE' has no checks defined (v1 criteria only)"
  trace_gate_end "$GATE" "passed" '{"reason":"no_checks_defined"}'
  if $JSON_OUT; then
    jq -nc --arg gate "$GATE" '{gate:$gate,result:"passed",checks:[],note:"v1 criteria only, no machine checks"}'
  fi
  exit 0
fi

PASS=0; FAIL=0; SKIP=0
for i in $(seq 0 $(( ITEMS_COUNT - 1 ))); do
  ITEM=$(echo "$RESOLVED" | python3 -c "import json,sys;print(json.dumps(json.load(sys.stdin)['items'][$i]))")
  rc=0
  run_check "$ITEM" || rc=$?
  case $rc in
    0) PASS=$((PASS+1)) ;;
    2) SKIP=$((SKIP+1)) ;;
    *) FAIL=$((FAIL+1)) ;;
  esac
done

# gate 评估
GATE_RESULT="unknown"
case "$GATE_EVAL" in
  all_checks.pass)
    [[ $FAIL -eq 0 ]] && GATE_RESULT="passed" || GATE_RESULT="blocked"
    ;;
  any_checks.pass)
    [[ $PASS -gt 0 ]] && GATE_RESULT="passed" || GATE_RESULT="blocked"
    ;;
  majority_checks.pass)
    total=$((PASS + FAIL))
    [[ $total -eq 0 ]] && GATE_RESULT="passed" || {
      [[ $PASS -gt $((total / 2)) ]] && GATE_RESULT="passed" || GATE_RESULT="blocked"
    }
    ;;
  *)
    log_warn "Unknown eval rule: $GATE_EVAL, fallback to all_checks.pass"
    [[ $FAIL -eq 0 ]] && GATE_RESULT="passed" || GATE_RESULT="blocked"
    ;;
esac

# on_failure 处理
if [[ "$GATE_RESULT" == "blocked" && "$GATE_ON_FAILURE" == "warn" ]]; then
  GATE_RESULT="warned"
elif [[ "$GATE_RESULT" == "blocked" && "$GATE_ON_FAILURE" == "skip" ]]; then
  GATE_RESULT="skipped"
fi

trace_gate_end "$GATE" "$GATE_RESULT" "$(jq -nc --arg eval "$GATE_EVAL" \
  --argjson pass "$PASS" --argjson fail "$FAIL" --argjson skip "$SKIP" \
  '{eval:$eval,pass:$pass,fail:$fail,skip:$skip}')"

# v1.7：ARCHIVE 阶段自动聚合 consumer pact（CDC broker）。
# 触发条件：gate 通过 + 此 gate 进入 ARCHIVE。
# 失败不阻断 gate 结果，只 warn——观测层不可成为流水线的故障源。
if [[ "$GATE_RESULT" == "passed" && "$GATE_TO" == "ARCHIVE" ]]; then
  AGG_SCRIPT="$PL_HOME/scripts/pl-contract-aggregate.sh"
  if [[ -x "$AGG_SCRIPT" ]]; then
    echo ""
    echo "${DIM}─── auto: pl-contract-aggregate --change $CHANGE ───${NC}"
    if "$AGG_SCRIPT" --change "$CHANGE" 2>&1 | sed 's/^/  /'; then
      echo "  ${DIM}(remember to: git add pl/contracts/${CHANGE}.consumed.yaml pl/contracts/_registry.yaml)${NC}"
    else
      log_warn "auto-aggregate failed (non-blocking); run manually: $AGG_SCRIPT --change $CHANGE"
    fi
  fi
fi

echo ""
echo "${BOLD}━━━ Summary ━━━${NC}"
echo "  Gate $GATE: ${BOLD}$GATE_RESULT${NC}  (pass=$PASS fail=$FAIL skip=$SKIP)"
echo "  Trace: $TRACE_DIR/$CHANGE.events.jsonl"

if $JSON_OUT; then
  jq -nc --arg gate "$GATE" --arg result "$GATE_RESULT" \
    --argjson pass "$PASS" --argjson fail "$FAIL" --argjson skip "$SKIP" \
    '{gate:$gate,result:$result,pass:$pass,fail:$fail,skip:$skip}'
fi

case "$GATE_RESULT" in
  passed|warned|skipped) exit 0 ;;
  *) exit 1 ;;
esac
