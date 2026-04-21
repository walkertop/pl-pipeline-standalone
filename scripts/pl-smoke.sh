#!/usr/bin/env bash
# =============================================================================
# pl-smoke.sh — E2 冷启动烟测阶段驱动
# =============================================================================
#
# 职责：
#   1. 从宿主 .pl-adapter.yaml 的 installed_from 找到 adapter 源包
#   2. 读 adapter.yaml 的 provides.build_adapter.smoke 配置
#   3. boot 应用 → 等 ready → 逐个 probe → shutdown
#   4. 每步写 trace 事件；全部 probe pass 则 gate E_smoke 通过
#
# 用法:
#   pl-smoke.sh --change <id>
#   pl-smoke.sh --change <id> --port 8910           # 自选端口
#   pl-smoke.sh --change <id> --dry-run             # 只解析配置不跑
#   pl-smoke.sh --change <id> --json                # 输出汇总 JSON
#
# 事件类型:
#   smoke.start / smoke.boot / smoke.ready / smoke.ready_timeout
#   smoke.probe(check.run 同义子类)
#   smoke.shutdown / smoke.end
#
# 退出码: 0=pass 1=fail 2=arg-err 3=adapter-missing-smoke
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
SMOKE_PORT="${SMOKE_PORT:-}"
DRY_RUN=false
JSON_OUT=false

usage() { sed -n '2,22p' "$0" | sed 's/^# \{0,1\}//'; exit 2; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --change)  CHANGE="$2"; shift 2 ;;
    --port)    SMOKE_PORT="$2"; shift 2 ;;
    --dry-run) DRY_RUN=true; shift ;;
    --json)    JSON_OUT=true; shift ;;
    -h|--help) usage ;;
    *) log_error "unknown opt: $1"; usage ;;
  esac
done
[[ -z "$CHANGE" ]] && { log_error "--change required"; usage; }

# 随机端口（1024-65535）如未指定
if [[ -z "$SMOKE_PORT" ]]; then
  SMOKE_PORT=$(( (RANDOM % 55000) + 10000 ))
fi
export SMOKE_PORT

# ---- 定位 adapter 源包 + 解析 smoke 段 ----
ADAPTER_META="$PL_PROJECT/.pl-adapter.yaml"
if [[ ! -f "$ADAPTER_META" ]]; then
  log_error ".pl-adapter.yaml not found in $PL_PROJECT; run adapter-install first"
  exit 2
fi

INSTALLED_FROM=$(grep -E '^\s*installed_from:' "$ADAPTER_META" | head -1 | sed -E 's/.*installed_from:[[:space:]]*"?([^"]*)"?/\1/')
# 支持 $PL_HOME 占位
INSTALLED_FROM="${INSTALLED_FROM//\$PL_HOME/$PL_HOME}"
ADAPTER_SRC="$INSTALLED_FROM"
if [[ ! -d "$ADAPTER_SRC" ]]; then
  log_error "adapter source not found: $ADAPTER_SRC"
  exit 2
fi
ADAPTER_YAML="$ADAPTER_SRC/adapter.yaml"
[[ -f "$ADAPTER_YAML" ]] || { log_error "adapter.yaml missing: $ADAPTER_YAML"; exit 2; }

# ---- 用 python 把 smoke 段解析成 JSON ----
SMOKE_JSON=$(python3 - "$ADAPTER_YAML" <<'PYEOF'
import sys, json, re

# 极简 YAML 解析（复用 adapter-validate 的兜底）
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
    with open(sys.argv[1]) as f:
        data = yaml.safe_load(f)
except ImportError:
    with open(sys.argv[1]) as f:
        data = minimal_yaml_load(f.read())

smoke = (data.get('provides') or {}).get('build_adapter', {}).get('smoke')
print(json.dumps({'smoke': smoke}))
PYEOF
)

HAS_SMOKE=$(echo "$SMOKE_JSON" | python3 -c 'import json,sys;print("yes" if json.load(sys.stdin).get("smoke") else "no")')
if [[ "$HAS_SMOKE" != "yes" ]]; then
  log_warn "adapter has no build_adapter.smoke configured"
  log_info "skipping SMOKE stage (not an error; adapter opted out)"
  trace_init "$CHANGE" "SMOKE" "script:pl-smoke"
  trace_emit "smoke.skip" '{"reason":"no_smoke_config_in_adapter"}'
  trace_emit "gate.eval" '{"gate":"E_smoke","result":"skipped","reason":"no_smoke_config"}'
  $JSON_OUT && jq -nc '{gate:"E_smoke",result:"skipped",reason:"no_smoke_config"}'
  # skipped 视为 opt-out 不是 failure；返回 0 不阻塞整条流水
  exit 0
fi

# 提取各字段
SMOKE_FIELD() { echo "$SMOKE_JSON" | python3 -c "import json,sys;v=json.load(sys.stdin)['smoke'].get('$1','');print(v if v is not None else '')"; }
SMOKE_FIELD_INT() { echo "$SMOKE_JSON" | python3 -c "import json,sys;print(json.load(sys.stdin)['smoke'].get('$1',$2))"; }
PROBE_COUNT() { echo "$SMOKE_JSON" | python3 -c 'import json,sys;print(len(json.load(sys.stdin)["smoke"].get("probes",[]) or []))'; }
GET_PROBE() { echo "$SMOKE_JSON" | python3 -c "import json,sys;print(json.dumps(json.load(sys.stdin)['smoke']['probes'][$1]))"; }

START_CMD_RAW=$(SMOKE_FIELD "start_cmd")
READY_URL_RAW=$(SMOKE_FIELD "ready_url")
READY_TIMEOUT=$(SMOKE_FIELD_INT "ready_timeout_sec" 30)
SHUTDOWN_GRACE=$(SMOKE_FIELD_INT "shutdown_grace_sec" 3)
CWD_RAW=$(SMOKE_FIELD "cwd")
N_PROBES=$(PROBE_COUNT)

# 展开 $SMOKE_PORT
START_CMD="${START_CMD_RAW//\$SMOKE_PORT/$SMOKE_PORT}"
READY_URL="${READY_URL_RAW//\$SMOKE_PORT/$SMOKE_PORT}"
WORK_DIR="${CWD_RAW:-$PL_PROJECT}"
[[ "$WORK_DIR" != /* ]] && WORK_DIR="$PL_PROJECT/$WORK_DIR"

echo "${BOLD}━━━ SMOKE ━━━${NC}"
echo "  port:      $SMOKE_PORT"
echo "  cwd:       $WORK_DIR"
echo "  ready_url: $READY_URL (timeout ${READY_TIMEOUT}s)"
echo "  probes:    $N_PROBES"
echo "  start:     ${DIM}$START_CMD${NC}"
echo ""

trace_init "$CHANGE" "SMOKE" "script:pl-smoke"
trace_emit "smoke.start" "$(jq -nc --arg port "$SMOKE_PORT" --arg url "$READY_URL" --argjson probes "$N_PROBES" \
  '{port:($port|tonumber),ready_url:$url,probe_count:$probes}')"

if $DRY_RUN; then
  log_info "dry-run, skipping boot"
  trace_emit "smoke.end" '{"result":"dryrun"}'
  exit 0
fi

# ---- boot ----
BOOT_LOG="/tmp/pl-smoke-boot-$$.log"
( cd "$WORK_DIR" && exec bash -c "$START_CMD" > "$BOOT_LOG" 2>&1 ) &
APP_PID=$!
trace_emit "smoke.boot" "$(jq -nc --arg pid "$APP_PID" --arg cmd "$START_CMD" --arg log "$BOOT_LOG" \
  '{pid:($pid|tonumber),cmd:$cmd,log:$log}')"

# cleanup：按进程树杀干净（包含 uvicorn 的 workers 和嵌套的 shell）
cleanup() {
  if [[ -n "${APP_PID:-}" ]] && kill -0 "$APP_PID" 2>/dev/null; then
    # 收集进程树的所有后代
    local all_pids=("$APP_PID")
    local children
    children=$(pgrep -P "$APP_PID" 2>/dev/null || true)
    if [[ -n "$children" ]]; then
      for c in $children; do
        all_pids+=("$c")
        # 再下一层
        local grand
        grand=$(pgrep -P "$c" 2>/dev/null || true)
        [[ -n "$grand" ]] && for g in $grand; do all_pids+=("$g"); done
      done
    fi
    # 优雅终止
    for p in "${all_pids[@]}"; do kill -TERM "$p" 2>/dev/null || true; done
    sleep "$SHUTDOWN_GRACE"
    # 强杀
    for p in "${all_pids[@]}"; do kill -KILL "$p" 2>/dev/null || true; done
  fi
  # 兜底：凡是监听本次 SMOKE_PORT 的进程全杀
  if [[ -n "${SMOKE_PORT:-}" ]]; then
    local pids
    pids=$(lsof -ti ":$SMOKE_PORT" 2>/dev/null || true)
    if [[ -n "$pids" ]]; then
      echo "$pids" | xargs kill -KILL 2>/dev/null || true
    fi
  fi
}
trap cleanup EXIT INT TERM

# ---- wait ready ----
READY=false
for ((i=1; i<=READY_TIMEOUT; i++)); do
  if curl -fsS --max-time 2 "$READY_URL" >/dev/null 2>&1; then
    READY=true
    trace_emit "smoke.ready" "$(jq -nc --argjson attempts "$i" '{attempts:$attempts}')"
    log_ok "ready after ${i}s"
    break
  fi
  sleep 1
done

if ! $READY; then
  trace_emit "smoke.ready_timeout" "$(jq -nc --argjson timeout "$READY_TIMEOUT" '{timeout_sec:$timeout,boot_log:"see smoke.boot.log"}')"
  log_error "app never became ready within ${READY_TIMEOUT}s"
  log_info "boot log tail:"
  tail -20 "$BOOT_LOG" | sed 's/^/    /'
  trace_emit "smoke.shutdown" "$(jq -nc --arg pid "$APP_PID" '{pid:($pid|tonumber),reason:"ready_timeout"}')"
  trace_emit "gate.eval" '{"gate":"E_smoke","result":"blocked","reason":"ready_timeout"}'
  $JSON_OUT && jq -nc '{gate:"E_smoke",result:"blocked",reason:"ready_timeout"}'
  exit 1
fi

# ---- probes ----
PASS=0; FAIL=0
for ((p=0; p<N_PROBES; p++)); do
  PROBE=$(GET_PROBE "$p")
  P_ID=$(echo "$PROBE" | python3 -c 'import json,sys;print(json.load(sys.stdin)["id"])')
  P_METHOD=$(echo "$PROBE" | python3 -c 'import json,sys;print(json.load(sys.stdin).get("method","GET"))')
  P_URL_RAW=$(echo "$PROBE" | python3 -c 'import json,sys;print(json.load(sys.stdin)["url"])')
  P_EXPECT=$(echo "$PROBE" | python3 -c 'import json,sys;print(json.load(sys.stdin).get("expect_status",200))')
  P_BODY=$(echo "$PROBE" | python3 -c 'import json,sys;b=json.load(sys.stdin).get("body","");print(b if isinstance(b,str) else json.dumps(b))')
  P_HEADERS_JSON=$(echo "$PROBE" | python3 -c 'import json,sys;print(json.dumps(json.load(sys.stdin).get("headers",{})))')
  P_EXPECT_RE=$(echo "$PROBE" | python3 -c 'import json,sys;print(json.load(sys.stdin).get("expect_body_regex",""))')

  # 展开 URL 占位
  P_URL="${P_URL_RAW//\$SMOKE_PORT/$SMOKE_PORT}"
  # 如是相对路径，拼 localhost
  if [[ "$P_URL" != http* ]]; then
    P_URL="http://127.0.0.1:${SMOKE_PORT}${P_URL}"
  fi

  # 构造 curl
  CURL_ARGS=(-s -o /tmp/pl-smoke-body-$$ -w "%{http_code}" -X "$P_METHOD" --max-time 10)
  while IFS= read -r h; do
    [[ -z "$h" ]] && continue
    CURL_ARGS+=(-H "$h")
  done < <(echo "$P_HEADERS_JSON" | python3 -c 'import json,sys
d = json.load(sys.stdin)
for k,v in d.items(): print(f"{k}: {v}")')

  if [[ -n "$P_BODY" && "$P_METHOD" != "GET" && "$P_METHOD" != "HEAD" ]]; then
    CURL_ARGS+=(-d "$P_BODY")
  fi
  CURL_ARGS+=("$P_URL")

  t0=$(date +%s)
  code=$(curl "${CURL_ARGS[@]}" 2>/dev/null || echo "000")
  duration=$(( $(date +%s) - t0 ))

  probe_pass=true
  reason=""
  if [[ "$code" != "$P_EXPECT" ]]; then
    probe_pass=false
    reason="status_mismatch:got=$code,expect=$P_EXPECT"
  elif [[ -n "$P_EXPECT_RE" ]]; then
    if ! grep -Eq "$P_EXPECT_RE" /tmp/pl-smoke-body-$$ 2>/dev/null; then
      probe_pass=false
      reason="body_regex_miss"
    fi
  fi

  if $probe_pass; then
    PASS=$((PASS+1))
    log_ok "[probe:$P_ID] $P_METHOD $P_URL → $code (${duration}s)"
  else
    FAIL=$((FAIL+1))
    log_error "[probe:$P_ID] $P_METHOD $P_URL → $code (${duration}s) — $reason"
  fi

  trace_emit "check.run" "$(jq -nc \
    --arg id "probe:$P_ID" --arg url "$P_URL" --arg method "$P_METHOD" \
    --argjson code "${code:-0}" --argjson expect "$P_EXPECT" \
    --arg status "$( $probe_pass && echo pass || echo fail )" --arg reason "$reason" \
    --argjson dur "$duration" \
    '{checker:$id,method:$method,url:$url,status_code:$code,expect:$expect,status:$status,duration_sec:$dur} + (if $reason != "" then {reason:$reason} else {} end)')"
done

# ---- 汇总 ----
cleanup
trace_emit "smoke.shutdown" "$(jq -nc --arg pid "$APP_PID" '{pid:($pid|tonumber)}')"

GATE_RESULT="passed"
[[ $FAIL -gt 0 ]] && GATE_RESULT="blocked"

trace_emit "gate.eval" "$(jq -nc --arg result "$GATE_RESULT" --argjson p "$PASS" --argjson f "$FAIL" \
  '{gate:"E_smoke",result:$result,pass:$p,fail:$f,eval:"all_probes.pass"}')"

trace_emit "smoke.end" "$(jq -nc --arg result "$GATE_RESULT" '{result:$result}')"

echo ""
echo "${BOLD}━━━ Summary ━━━${NC}"
echo "  Gate E_smoke: ${BOLD}$GATE_RESULT${NC}  (probes: pass=$PASS fail=$FAIL)"
echo "  Trace: $TRACE_DIR/$CHANGE.events.jsonl"

if $JSON_OUT; then
  jq -nc --arg result "$GATE_RESULT" --argjson p "$PASS" --argjson f "$FAIL" \
    '{gate:"E_smoke",result:$result,pass:$p,fail:$f}'
fi

rm -f /tmp/pl-smoke-body-$$
[[ "$GATE_RESULT" == "passed" ]] && exit 0 || exit 1
