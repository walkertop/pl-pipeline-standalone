#!/usr/bin/env bash
# ============================================================================
# pl-status.sh — pl-pipeline 状态查询 / JSON 导出 / 自检
# ----------------------------------------------------------------------------
# Usage:
#   scripts/pl-status.sh                         # 人读表格（全量）
#   scripts/pl-status.sh <change-id>             # 人读表格（单 change）
#   scripts/pl-status.sh --json                  # 全量 JSON（stdout）
#   scripts/pl-status.sh --json <change-id>      # 单 change JSON
#   scripts/pl-status.sh --self-check            # 自检（全量 → 跑 schema 校验 → 打印一行结论）
#
# Exit code:
#   0 = OK（包括 UNKNOWN 降级；只要没崩）
#   1 = 参数错误 / 找不到 change
#   2 = --self-check 失败（JSON 不符合 pl-status-v1.schema）
#
# Schema contract: pl/schemas/pl-status-v1.schema.json
# ============================================================================
set -euo pipefail

# ─── 环境解析 ──────────────────────────────────────────────────────────────
# 独立化后：脚本在 $PL_HOME/scripts/，数据在 $PL_PROJECT/pl/changes/
# _env.sh 会设置 PL_HOME / PL_PROJECT / PL_ASSETS / PL_CHANGES
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/_env.sh"

REPO_ROOT="$PL_PROJECT"                              # 向后兼容：REPO_ROOT 保留
CHANGES_DIR="$PL_CHANGES"
SCHEMA_FILE="$PL_ASSETS/pl/schemas/pl-status-v1.schema.json"
# 配置优先级：宿主项目的 pl/config.yaml > pl-pipeline 默认 config
if [[ -f "$PL_PROJECT/pl/config.yaml" ]]; then
  CONFIG_FILE="$PL_PROJECT/pl/config.yaml"
else
  CONFIG_FILE="$PL_ASSETS/pl/config.default.yaml"
fi

# ─── 颜色（仅 TTY）─────────────────────────────────────────────────────────
if [[ -t 1 ]]; then
  RED=$'\033[0;31m'; GREEN=$'\033[0;32m'; YELLOW=$'\033[0;33m'
  BLUE=$'\033[0;34m'; BOLD=$'\033[1m'; DIM=$'\033[2m'; NC=$'\033[0m'
else
  RED=; GREEN=; YELLOW=; BLUE=; BOLD=; DIM=; NC=
fi

# ─── 参数解析 ──────────────────────────────────────────────────────────────
MODE="human"          # human | json | self-check
TARGET_CHANGE=""      # 指定 change id

while [[ $# -gt 0 ]]; do
  case "$1" in
    --json)        MODE="json"; shift ;;
    --self-check)  MODE="self-check"; shift ;;
    --change)      TARGET_CHANGE="${2:-}"; shift 2 ;;
    -h|--help)
      sed -n '3,16p' "$0" | sed 's/^# \{0,1\}//'
      exit 0 ;;
    --*)
      echo "${RED}未知参数: $1${NC}" >&2
      exit 1 ;;
    *)
      if [[ -z "$TARGET_CHANGE" ]]; then
        TARGET_CHANGE="$1"
      else
        echo "${RED}多余参数: $1${NC}" >&2
        exit 1
      fi
      shift ;;
  esac
done

# ─── 读取 pl_version（不强求，失败降级 pl@v1.0）──────────────────────────
PL_VERSION="pl@v1.0"
if [[ -f "$CONFIG_FILE" ]]; then
  v=$(grep -E '^version:' "$CONFIG_FILE" | awk '{print $2}' | tr -d '"' || true)
  [[ -n "$v" ]] && PL_VERSION="$v"
fi

# ─── 前置校验 TARGET_CHANGE（若指定但目录不存在，直接 exit 1）─────────────
if [[ -n "$TARGET_CHANGE" ]]; then
  if [[ ! -d "$CHANGES_DIR/$TARGET_CHANGE" ]]; then
    echo "${RED}未找到 change: $TARGET_CHANGE${NC}" >&2
    echo "${DIM}  （预期在 ${CHANGES_DIR}/${TARGET_CHANGE}）${NC}" >&2
    # 列出可用的 change，方便用户纠错
    if [[ -d "$CHANGES_DIR" ]]; then
      echo "${DIM}  可用 change:${NC}" >&2
      find "$CHANGES_DIR" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; 2>/dev/null \
        | sort | sed "s/^/    /" >&2 || true
    fi
    exit 1
  fi
fi

# ─── 单 change 解析函数（输出制表符分隔的 kv 行，供 python 读取）───────────
# 参数：$1 = change 目录绝对路径
# 输出格式：KEY<TAB>VALUE（每行一对）
parse_one() {
  local dir="$1"
  local state="$dir/.state.md"
  local id
  id="$(basename "$dir")"
  printf 'id\t%s\n' "$id"
  printf 'state_path\tpl/changes/%s/.state.md\n' "$id"

  if [[ ! -f "$state" ]]; then
    printf 'parse_ok\tfalse\n'
    printf 'warning\t.state.md missing\n'
    printf 'stage\tUNKNOWN\n'
    return 0
  fi

  # stage
  local stage
  stage=$(grep -E '^- stage:' "$state" | head -1 | sed -E 's/^- stage:[[:space:]]*//' | tr -d '\r' || true)
  case "$stage" in
    SPEC|PLAN|IMPLEMENT|VERIFY|OBSERVE|ARCHIVE|DONE)
      printf 'stage\t%s\n' "$stage"
      printf 'parse_ok\ttrue\n'
      ;;
    "")
      printf 'stage\tUNKNOWN\n'
      printf 'parse_ok\tfalse\n'
      printf 'warning\tno "- stage:" line found in .state.md\n'
      ;;
    *)
      printf 'stage\tUNKNOWN\n'
      printf 'parse_ok\tfalse\n'
      printf 'warning\tunknown stage value: %s\n' "$stage"
      ;;
  esac

  # gate_status / next_gate
  local gs ng
  gs=$(grep -E '^- gate_status:' "$state" | head -1 | sed -E 's/^- gate_status:[[:space:]]*//' | tr -d '\r"' || true)
  ng=$(grep -E '^- next_gate:' "$state" | head -1 | sed -E 's/^- next_gate:[[:space:]]*//' | tr -d '\r"' || true)
  case "$gs" in
    PENDING|PASSED|FAILED|BLOCKED) printf 'gate_status\t%s\n' "$gs" ;;
    *) : ;;
  esac
  [[ -n "$ng" ]] && printf 'next_gate\t%s\n' "$ng"

  # change_name / complexity / business_domain
  local nm cx bd
  nm=$(grep -E '^- change_name:' "$state" | head -1 | sed -E 's/^- change_name:[[:space:]]*//' | tr -d '\r' || true)
  cx=$(grep -E '^- complexity:' "$state" | head -1 | sed -E 's/^- complexity:[[:space:]]*//' | tr -d '\r' || true)
  bd=$(grep -E '^- business_domain:' "$state" | head -1 | sed -E 's/^- business_domain:[[:space:]]*//' | tr -d '\r' || true)
  [[ -n "$nm" ]] && printf 'name\t%s\n' "$nm"
  [[ -n "$cx" ]] && printf 'complexity\t%s\n' "$cx"
  [[ -n "$bd" ]] && printf 'business_domain\t%s\n' "$bd"

  # tasks: total / done / blocked —— 从 Task Progress 表格统计
  # 表格行形如: | T01 | 名 | 0 | - | 0.5d | ⬜ TODO | - |
  # 状态列常见值: ⬜ TODO / 🔄 DOING / ✅ DONE / 🚫 BLOCKED
  local task_total task_done task_blocked
  task_total=$(awk '
    /^## Task Progress/ { inblk=1; next }
    inblk && /^## / { inblk=0 }
    inblk && /^\| T[0-9][A-Za-z0-9]*[[:space:]]*\|/ { n++ }
    END { print n+0 }
  ' "$state")
  task_done=$(awk '
    /^## Task Progress/ { inblk=1; next }
    inblk && /^## / { inblk=0 }
    inblk && /^\| T[0-9][A-Za-z0-9]*[[:space:]]*\|/ && /DONE/ { n++ }
    END { print n+0 }
  ' "$state")
  task_blocked=$(awk '
    /^## Task Progress/ { inblk=1; next }
    inblk && /^## / { inblk=0 }
    inblk && /^\| T[0-9][A-Za-z0-9]*[[:space:]]*\|/ && /BLOCKED/ { n++ }
    END { print n+0 }
  ' "$state")
  printf 'tasks_total\t%s\n' "$task_total"
  printf 'tasks_done\t%s\n' "$task_done"
  printf 'tasks_blocked\t%s\n' "$task_blocked"

  # open questions: total / blocking / open —— 从 Open Questions 表
  local oq_total oq_block oq_open
  # blocking = BLOCKING 且未 RESOLVED/CLOSED
  # open = 状态列含 OPEN（大小写不敏感）
  oq_total=$(awk '
    /^## Open Questions/ { inblk=1; next }
    inblk && /^## / { inblk=0 }
    inblk && /^\| Q[0-9]+[[:space:]]*\|/ { n++ }
    END { print n+0 }
  ' "$state")
  oq_block=$(awk '
    /^## Open Questions/ { inblk=1; next }
    inblk && /^## / { inblk=0 }
    inblk && /^\| Q[0-9]+[[:space:]]*\|/ && /BLOCKING/ && !/RESOLVED/ && !/CLOSED/ { n++ }
    END { print n+0 }
  ' "$state")
  oq_open=$(awk '
    /^## Open Questions/ { inblk=1; next }
    inblk && /^## / { inblk=0 }
    inblk && /^\| Q[0-9]+[[:space:]]*\|/ && (/[[:space:]]OPEN[[:space:]]/ || /\|[[:space:]]*OPEN[[:space:]]*\|/) { n++ }
    END { print n+0 }
  ' "$state")
  printf 'oq_total\t%s\n' "$oq_total"
  printf 'oq_blocking\t%s\n' "$oq_block"
  printf 'oq_open\t%s\n' "$oq_open"

  # last_update —— 取文件顶部 "最后更新: YYYY-MM-DD HH:MM" 注释
  local lu
  lu=$(grep -oE '最后更新:[[:space:]]*[0-9]{4}-[0-9]{2}-[0-9]{2}([[:space:]]+[0-9]{2}:[0-9]{2})?' "$state" \
       | head -1 | sed -E 's/^最后更新:[[:space:]]*//' || true)
  [[ -n "$lu" ]] && printf 'last_update\t%s\n' "$lu"
}

# ─── 发现所有 change（按字典序）────────────────────────────────────────────
discover_changes() {
  if [[ ! -d "$CHANGES_DIR" ]]; then
    return 0
  fi
  find "$CHANGES_DIR" -mindepth 1 -maxdepth 1 -type d | sort
}

# ─── 产出全量数据（所有 change 的 parse_one 汇总，用 0x1E 分隔）────────────
collect_raw() {
  local dirs=()
  if [[ -n "$TARGET_CHANGE" ]]; then
    local d="$CHANGES_DIR/$TARGET_CHANGE"
    if [[ ! -d "$d" ]]; then
      echo "${RED}未找到 change: $TARGET_CHANGE${NC}" >&2
      echo "${DIM}  （在 $CHANGES_DIR 下）${NC}" >&2
      exit 1
    fi
    dirs=("$d")
  else
    while IFS= read -r d; do dirs+=("$d"); done < <(discover_changes)
  fi

  local first=1
  for d in "${dirs[@]}"; do
    if [[ $first -eq 0 ]]; then
      printf '\036\n'   # 0x1E record separator
    fi
    first=0
    parse_one "$d"
  done
}

# ─── JSON 构造（交给 python3；失败给出清晰报错）──────────────────────────
# NOTE: 历史上曾试过 `collect_raw | python3 - <<'PY' ... PY`，但 bash 下 heredoc
#       优先于 pipe 绑定 stdin，导致 python 读到的是脚本源码而非 collect_raw 输出，
#       表现为 changes: []。改用临时 .py 文件 + 纯 pipe 的方式彻底规避。
emit_json() {
  if ! command -v python3 >/dev/null 2>&1; then
    echo "${RED}需要 python3 才能生成 JSON（未找到）${NC}" >&2
    exit 1
  fi
  local py
  py=$(mktemp /tmp/pl-status.XXXXXX.py)
  # 安装 EXIT 兜底清理（避免异常时残留 /tmp 文件）
  trap "rm -f '$py'" EXIT
  cat > "$py" <<'PY'
import os, sys, json, datetime

raw = sys.stdin.read()
records = [r for r in raw.split('\x1e\n') if r.strip()]

def parse(rec):
    d = {}
    for line in rec.splitlines():
        if '\t' not in line:
            continue
        k, v = line.split('\t', 1)
        d.setdefault(k, v)
    entry = {
        'id': d.get('id', ''),
        'stage': d.get('stage', 'UNKNOWN'),
        'source': {
            'state_path': d.get('state_path', ''),
            'parse_ok': d.get('parse_ok', 'false') == 'true',
        }
    }
    if 'warning' in d:
        entry['source']['warnings'] = [d['warning']]
    for k_src, k_dst in [
        ('name', 'name'),
        ('gate_status', 'gate_status'),
        ('next_gate', 'next_gate'),
        ('complexity', 'complexity'),
        ('business_domain', 'business_domain'),
        ('last_update', 'last_update'),
    ]:
        if k_src in d and d[k_src] != '':
            entry[k_dst] = d[k_src]
    if any(k in d for k in ('tasks_total', 'tasks_done', 'tasks_blocked')):
        entry['tasks'] = {
            'total':   int(d.get('tasks_total', 0) or 0),
            'done':    int(d.get('tasks_done', 0) or 0),
            'blocked': int(d.get('tasks_blocked', 0) or 0),
        }
    if any(k in d for k in ('oq_total', 'oq_blocking', 'oq_open')):
        entry['open_questions'] = {
            'total':    int(d.get('oq_total', 0) or 0),
            'blocking': int(d.get('oq_blocking', 0) or 0),
            'open':     int(d.get('oq_open', 0) or 0),
        }
    if 'name' not in entry:
        entry['name'] = entry['id']
    return entry

changes = [parse(r) for r in records]
changes.sort(key=lambda e: e['id'])

# 时区感知 UTC（py3.12+ 不再推荐 utcnow()）
now = datetime.datetime.now(datetime.timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')

out = {
    'schema_version': 'pl-status-v1',
    'generated_at':   now,
    'pl_version':     os.environ.get('PL_VERSION', 'pl@v1.0'),
    'changes':        changes,
}
json.dump(out, sys.stdout, ensure_ascii=False, indent=2)
sys.stdout.write('\n')
PY
  collect_raw | PL_VERSION="$PL_VERSION" python3 "$py"
  rm -f "$py"
  trap - EXIT
}

# ─── Schema 校验（self-check）────────────────────────────────────────────
# 策略：优先用 jsonschema；若没装，降级到内置轻校验（检字段必填 + stage enum）
# 数据流：shell 把 JSON 通过 stdin 喂给 python（避免 heredoc 内嵌引号陷阱）
schema_check() {
  local json_content="$1"
  local py
  py=$(mktemp /tmp/pl-schema-check.XXXXXX.py)
  trap "rm -f '$py'" RETURN
  cat > "$py" <<'PY'
import json, sys
schema_path = sys.argv[1]
with open(schema_path, encoding='utf-8') as f:
    schema = json.load(f)
data = json.load(sys.stdin)

def fail(msg):
    print('FAIL: ' + msg, file=sys.stderr)
    sys.exit(2)

try:
    import jsonschema
    try:
        jsonschema.validate(instance=data, schema=schema)
        print('OK: jsonschema validator passed (%d changes)' % len(data.get('changes', [])))
    except jsonschema.ValidationError as e:
        fail('schema violation: %s @ %s' % (e.message, list(e.absolute_path)))
except ImportError:
    # 降级轻校验
    for k in ('schema_version', 'generated_at', 'pl_version', 'changes'):
        if k not in data:
            fail('missing top-level field: ' + k)
    if data['schema_version'] != 'pl-status-v1':
        fail('schema_version must be pl-status-v1')
    valid_stages = {'SPEC','PLAN','IMPLEMENT','VERIFY','OBSERVE','ARCHIVE','DONE','UNKNOWN'}
    for i, c in enumerate(data['changes']):
        for k in ('id', 'stage', 'source'):
            if k not in c:
                fail('changes[%d] missing %s' % (i, k))
        if c['stage'] not in valid_stages:
            fail('changes[%d].stage invalid: %s' % (i, c['stage']))
        if 'state_path' not in c['source'] or 'parse_ok' not in c['source']:
            fail('changes[%d].source missing required field' % i)
    print('OK: lightweight validator passed (%d changes)' % len(data['changes']))
PY
  printf '%s' "$json_content" | python3 "$py" "$SCHEMA_FILE"
  local rc=$?
  rm -f "$py"
  return $rc
}

self_check() {
  local json_out
  if ! json_out=$(emit_json 2>&1); then
    echo "${RED}self-check: emit_json 失败${NC}" >&2
    echo "$json_out" >&2
    return 2
  fi
  # 交给 python 做 schema 校验
  if ! result=$(schema_check "$json_out" 2>&1); then
    echo "${RED}self-check: schema 校验失败${NC}" >&2
    echo "$result" >&2
    return 2
  fi
  echo "$result"
}

# ─── 人读表格 ──────────────────────────────────────────────────────────────
# 通过 stdin 把 JSON 喂给 python（避免 heredoc 内嵌 JSON 的引号陷阱）；
# 颜色常量通过环境变量传递。
human_table() {
  local json_out
  json_out=$(emit_json)
  local py
  py=$(mktemp /tmp/pl-human.XXXXXX.py)
  trap "rm -f '$py'" RETURN
  cat > "$py" <<'PY'
import json, os, sys
data = json.load(sys.stdin)
GRN = os.environ.get('C_GREEN', '')
YLW = os.environ.get('C_YELLOW', '')
RED = os.environ.get('C_RED', '')
BLU = os.environ.get('C_BLUE', '')
BLD = os.environ.get('C_BOLD', '')
DIM = os.environ.get('C_DIM', '')
NC  = os.environ.get('C_NC', '')

STAGE_ICON = {
    'SPEC': '📝', 'PLAN': '🗂', 'IMPLEMENT': '💻',
    'VERIFY': '🔍', 'OBSERVE': '👁', 'ARCHIVE': '📦',
    'DONE': '✅', 'UNKNOWN': '❓',
}

print(f"{BLD}pl-pipeline 状态总览{NC}  {DIM}({data['pl_version']}, {data['generated_at']}){NC}")
print()

if not data['changes']:
    print(f"  {DIM}（暂无 change，新建：/pl:proposal <change-id>）{NC}")
    sys.exit(0)

rows = []
for c in data['changes']:
    t = c.get('tasks', {})
    prog = f"{t.get('done', 0)}/{t.get('total', 0)}" if t else '-'
    oq = c.get('open_questions', {})
    oq_s = f"{oq.get('open', 0)}/{oq.get('total', 0)}" if oq else '-'
    rows.append({
        'id':      c['id'],
        'name':    c.get('name', c['id']),
        'stage':   f"{STAGE_ICON.get(c['stage'], '?')} {c['stage']}",
        'gate':    c.get('gate_status') or '-',
        'next':    c.get('next_gate') or '-',
        'tasks':   prog,
        'oq':      oq_s,
        'update':  c.get('last_update', '-') or '-',
        'parse':   c['source']['parse_ok'],
    })

# ASCII 表格（对齐考虑了中文全角：用显示宽度估算太复杂，先用简单等宽）
hdr = f"  {'ID':<32} {'阶段':<12} {'门禁':<8} {'下一':<5} {'进度':<7} {'Q':<5} {'最后更新':<16}"
print(hdr)
print(f"  {'-'*32} {'-'*12} {'-'*8} {'-'*5} {'-'*7} {'-'*5} {'-'*16}")
for r in rows:
    color = GRN if r['parse'] else YLW
    mark = '' if r['parse'] else f" {YLW}⚠{NC}"
    id_col = r['id'][:32]
    stage_col = r['stage'][:12]
    print(f"  {id_col:<32} {color}{stage_col:<12}{NC} {r['gate']:<8} {r['next']:<5} {r['tasks']:<7} {r['oq']:<5} {r['update']:<16}{mark}")

print()
warn = sum(1 for c in data['changes'] if not c['source']['parse_ok'])
ok = len(data['changes']) - warn
summary = f"  共 {BLD}{len(data['changes'])}{NC} 个 change（{GRN}{ok} 正常{NC}"
if warn:
    summary += f", {YLW}{warn} 解析降级{NC}"
summary += ")"
print(summary)
print()
print(f"  {DIM}单 change 详情: ./scripts/pl-status.sh <change-id>{NC}")
print(f"  {DIM}JSON 输出:     ./scripts/pl-status.sh --json [<change-id>]{NC}")
PY
  printf '%s' "$json_out" | \
    C_GREEN="$GREEN" C_YELLOW="$YELLOW" C_RED="$RED" C_BLUE="$BLUE" \
    C_BOLD="$BOLD" C_DIM="$DIM" C_NC="$NC" \
    python3 "$py"
  local rc=$?
  rm -f "$py"
  return $rc
}

# ─── 主分发 ────────────────────────────────────────────────────────────────
case "$MODE" in
  json)       emit_json ;;
  self-check) self_check ;;
  human)      human_table ;;
esac
