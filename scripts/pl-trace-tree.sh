#!/usr/bin/env bash
# =============================================================================
# pl-trace-tree.sh — 按 span_id / parent_span_id 把 trace 事件流渲染成层级树
# =============================================================================
#
# 用法:
#   pl-trace-tree.sh --change <id>
#   pl-trace-tree.sh --change <id> --no-points     # 隐藏 point 事件，只看 span 骨架
#   pl-trace-tree.sh --change <id> --json          # 输出结构化 JSON 而非可视树
#   pl-trace-tree.sh --file path/to/events.jsonl   # 直接指定文件
#
# 退出码:
#   0 = ok
#   2 = 参数错误 / 文件不存在
# =============================================================================

source "$(dirname "${BASH_SOURCE[0]}")/_env.sh"
set -uo pipefail

CHANGE=""
FILE=""
NO_POINTS=false
JSON_OUT=false

usage() {
  sed -n '2,15p' "$0" | sed 's/^# \{0,1\}//'
  exit 2
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --change) CHANGE="$2"; shift 2 ;;
    --file)   FILE="$2"; shift 2 ;;
    --no-points) NO_POINTS=true; shift ;;
    --json)   JSON_OUT=true; shift ;;
    -h|--help) usage ;;
    *) echo "Unknown option: $1" >&2; usage ;;
  esac
done

if [[ -z "$FILE" ]]; then
  [[ -z "$CHANGE" ]] && { echo "Missing --change <id> or --file <path>" >&2; usage; }
  FILE="$PL_OUTPUT/trace/${CHANGE}.events.jsonl"
fi
[[ -f "$FILE" ]] || { echo "Trace file not found: $FILE" >&2; exit 2; }

NO_POINTS=$NO_POINTS JSON_OUT=$JSON_OUT FILE="$FILE" python3 - <<'PYEOF'
import os, sys, json
from datetime import datetime, timezone

FILE = os.environ['FILE']
NO_POINTS = os.environ.get('NO_POINTS') == 'true'
JSON_OUT  = os.environ.get('JSON_OUT')  == 'true'

def parse_ts(s):
    if not s: return None
    try:
        return datetime.fromisoformat(s.replace('Z', '+00:00'))
    except Exception:
        return None

def fmt_dur(start, end):
    if not start or not end: return '?'
    sec = int((end - start).total_seconds())
    if sec < 1: return '<1s'
    if sec < 60: return f'{sec}s'
    if sec < 3600: return f'{sec//60}m{sec%60:02d}s'
    return f'{sec//3600}h{(sec%3600)//60:02d}m'

events = []
with open(FILE) as f:
    for ln in f:
        ln = ln.strip()
        if not ln: continue
        try:
            events.append(json.loads(ln))
        except json.JSONDecodeError:
            pass

if not events:
    print('(no events)')
    sys.exit(0)

# 1. 收集所有 span（带 span_id 的事件 = span 边界）
#    span_id -> {start_ts, end_ts, label, kind, parent_span_id, children, point_events, all_events}
spans = {}
ROOT = '__root__'
spans[ROOT] = {'start_ts': None, 'end_ts': None, 'label': '(session root)',
               'kind': 'root', 'parent_span_id': None,
               'children': [], 'point_events': [], 'open_event': None, 'close_event': None}

def derive_label(evt):
    e = evt['event']
    d = evt.get('data') or {}
    if e == 'phase.start':
        return f"PHASE  {d.get('phase_name') or evt.get('phase','?')}"
    if e == 'phase.end':
        return f"PHASE  {evt.get('phase','?')}  → {d.get('status','?')}"
    if e == 'gate.start':
        return f"GATE   {d.get('gate','?')}"
    if e == 'gate.eval':
        return f"GATE   {d.get('gate','?')}  → {d.get('result','?')}"
    if e == 'task.start':
        return f"TASK   {d.get('task_id','?')}"
    if e == 'task.end':
        return f"TASK   {d.get('task_id','?')}"
    return e

def summarize_point(evt):
    e = evt['event']
    d = evt.get('data') or {}
    ts = evt.get('ts','')[11:19]
    if e == 'check.run':
        return f"{ts}  check  {d.get('checker','?')}  → {d.get('status','?')}  ({d.get('duration_sec',0)}s)"
    if e == 'adapter.use':
        return f"{ts}  use    {d.get('asset_kind','?')}/{d.get('asset_id','?')}  ({d.get('adapter','?')}@{d.get('adapter_version','?')})"
    if e == 'artifact.create':
        return f"{ts}  create {d.get('path','?')}"
    if e == 'artifact.update':
        return f"{ts}  update {d.get('path','?')}"
    if e == 'error':
        return f"{ts}  ERROR  {d.get('message','?')}"
    return f"{ts}  {e}  {json.dumps({k:v for k,v in d.items() if k not in ('cmd',)}, ensure_ascii=False)[:80]}"

# 第一遍：所有带 span_id 的事件，建/更新 span 节点
for ev in events:
    sid = ev.get('span_id')
    if not sid: continue
    if sid not in spans:
        spans[sid] = {'start_ts': None, 'end_ts': None, 'label': '',
                      'kind': '', 'parent_span_id': ev.get('parent_span_id'),
                      'children': [], 'point_events': [], 'open_event': None, 'close_event': None}
    s = spans[sid]
    e = ev['event']
    ts = parse_ts(ev.get('ts'))
    if e.endswith('.start'):
        s['start_ts'] = ts
        s['label']    = derive_label(ev)
        s['kind']     = e.split('.')[0]
        s['open_event'] = ev
        if not s['parent_span_id']:
            s['parent_span_id'] = ev.get('parent_span_id')
    elif e.endswith('.end') or e == 'gate.eval':
        s['end_ts']    = ts
        s['close_event'] = ev
        # gate.eval 既是关，也是 result-bearing 标签来源
        if e == 'gate.eval':
            s['label'] = derive_label(ev)

# 第二遍：所有不带 span_id 的事件（point），挂到 parent_span_id（或 root）下
for ev in events:
    sid = ev.get('span_id')
    if sid: continue
    parent = ev.get('parent_span_id') or ROOT
    if parent not in spans:
        # 父 span 还没出现（异常事件），临时挂到 root
        parent = ROOT
    spans[parent]['point_events'].append(ev)

# 第三遍：构建父子关系
for sid, s in spans.items():
    if sid == ROOT: continue
    parent = s['parent_span_id'] or ROOT
    if parent not in spans:
        parent = ROOT
    spans[parent]['children'].append(sid)

# Root 的 start/end 取所有事件的最早最晚 ts
all_ts = [parse_ts(ev.get('ts')) for ev in events]
all_ts = [t for t in all_ts if t]
if all_ts:
    spans[ROOT]['start_ts'] = min(all_ts)
    spans[ROOT]['end_ts']   = max(all_ts)

if JSON_OUT:
    def to_dict(sid):
        s = spans[sid]
        return {
            'span_id': None if sid == ROOT else sid,
            'label':   s['label'],
            'kind':    s['kind'],
            'start':   s['start_ts'].isoformat() if s['start_ts'] else None,
            'end':     s['end_ts'].isoformat() if s['end_ts'] else None,
            'duration_sec': int((s['end_ts'] - s['start_ts']).total_seconds()) if s['start_ts'] and s['end_ts'] else None,
            'point_events': [{'event': p['event'], 'ts': p['ts'], 'data': p.get('data')} for p in s['point_events']],
            'children': [to_dict(c) for c in s['children']],
        }
    print(json.dumps(to_dict(ROOT), indent=2, ensure_ascii=False))
    sys.exit(0)

def render(sid, prefix='', is_last=True, is_root=False):
    s = spans[sid]
    if is_root:
        print(f"{s['label']}  {fmt_dur(s['start_ts'], s['end_ts'])}")
        new_prefix = ''
    else:
        connector = '└─ ' if is_last else '├─ '
        dur = fmt_dur(s['start_ts'], s['end_ts'])
        print(f"{prefix}{connector}{s['label']}  {dur}")
        new_prefix = prefix + ('   ' if is_last else '│  ')

    if not NO_POINTS:
        for pe in s['point_events']:
            print(f"{new_prefix}·  {summarize_point(pe)}")

    n_children = len(s['children'])
    for i, ch in enumerate(s['children']):
        render(ch, new_prefix, is_last=(i == n_children - 1), is_root=False)

render(ROOT, is_root=True)
PYEOF
