#!/usr/bin/env bash
# =============================================================================
# pl-active-time.sh — 基于事件密度的 active vs wall_clock 统计代理
# =============================================================================
#
# 为什么要做这个：
#   交互式 IDE（Cursor / Claude Code）里 LLM 不会自报 turn.start/end，
#   外部脚本也无法稳定卡住每一次 agent 调用边界。
#   所以 "AI 真实工时" 不能精确测，只能用 trace 事件流的密度做统计代理：
#     - 把所有事件按 ts 排序
#     - 相邻事件间隔 ≤ idle_threshold（默认 5 分钟）→ 算同一活动窗口
#     - 间隔 > idle_threshold → 视为 idle / 等人间隙，剔除
#     - active_ms = Σ(每个活动窗口的 last_ts - first_ts)
#
# 这是估计，不是精确值，但对监督者"AI 大概忙了多久"的判断足够。
# 安全失败方向：会低估 active 时间（思考间没事件 → 算成 idle），
# 永远不会高估，符合"宁可少记不要多算"的原则。
#
# 用法:
#   pl-active-time.sh --change <id>
#   pl-active-time.sh --change <id> --idle 600          # 自定义 idle 阈值（秒，默认 300）
#   pl-active-time.sh --change <id> --json              # 输出 JSON
#   pl-active-time.sh --change <id> --by-phase          # 按 phase 拆分
#   pl-active-time.sh --file path/to/events.jsonl
# =============================================================================

source "$(dirname "${BASH_SOURCE[0]}")/_env.sh"
set -uo pipefail

CHANGE=""
FILE=""
IDLE=300
JSON_OUT=false
BY_PHASE=false

usage() {
  sed -n '2,25p' "$0" | sed 's/^# \{0,1\}//'
  exit 2
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --change)   CHANGE="$2"; shift 2 ;;
    --file)     FILE="$2"; shift 2 ;;
    --idle)     IDLE="$2"; shift 2 ;;
    --json)     JSON_OUT=true; shift ;;
    --by-phase) BY_PHASE=true; shift ;;
    -h|--help) usage ;;
    *) echo "Unknown option: $1" >&2; usage ;;
  esac
done

if [[ -z "$FILE" ]]; then
  [[ -z "$CHANGE" ]] && { echo "Missing --change <id> or --file <path>" >&2; usage; }
  FILE="$PL_OUTPUT/trace/${CHANGE}.events.jsonl"
fi
[[ -f "$FILE" ]] || { echo "Trace file not found: $FILE" >&2; exit 2; }

FILE="$FILE" IDLE="$IDLE" JSON_OUT=$JSON_OUT BY_PHASE=$BY_PHASE python3 - <<'PYEOF'
import os, sys, json
from datetime import datetime
from collections import defaultdict

FILE     = os.environ['FILE']
IDLE     = int(os.environ.get('IDLE', '300'))
JSON_OUT = os.environ.get('JSON_OUT') == 'true'
BY_PHASE = os.environ.get('BY_PHASE') == 'true'

def parse_ts(s):
    try:
        return datetime.fromisoformat(s.replace('Z', '+00:00'))
    except Exception:
        return None

def fmt_dur(sec):
    sec = int(sec)
    if sec < 60: return f'{sec}s'
    if sec < 3600: return f'{sec//60}m{sec%60:02d}s'
    return f'{sec//3600}h{(sec%3600)//60:02d}m'

events = []
with open(FILE) as f:
    for ln in f:
        ln = ln.strip()
        if not ln: continue
        try:
            ev = json.loads(ln)
            ts = parse_ts(ev.get('ts'))
            if ts:
                ev['_ts'] = ts
                events.append(ev)
        except json.JSONDecodeError:
            pass

if not events:
    print('(no events)')
    sys.exit(0)

events.sort(key=lambda e: e['_ts'])

def burst_stats(evs):
    """对一组按 ts 排序好的事件做 burst 切分，返回 (wall_sec, active_sec, n_bursts, max_idle_sec)"""
    if not evs:
        return 0, 0, 0, 0
    bursts = [[evs[0]]]
    max_idle = 0
    for e in evs[1:]:
        gap = (e['_ts'] - bursts[-1][-1]['_ts']).total_seconds()
        if gap > IDLE:
            max_idle = max(max_idle, gap)
            bursts.append([e])
        else:
            bursts[-1].append(e)
    wall = (evs[-1]['_ts'] - evs[0]['_ts']).total_seconds()
    active = sum((b[-1]['_ts'] - b[0]['_ts']).total_seconds() for b in bursts)
    return wall, active, len(bursts), max_idle

# 全局
wall, active, n_bursts, max_idle = burst_stats(events)

result = {
    'change_id': events[0].get('change_id') or events[0].get('trace_id','').split('_')[0],
    'event_count': len(events),
    'idle_threshold_sec': IDLE,
    'wall_clock_sec': int(wall),
    'active_sec':     int(active),
    'idle_sec':       int(wall - active),
    'bursts':         n_bursts,
    'max_idle_sec':   int(max_idle),
}

if BY_PHASE:
    by_phase = defaultdict(list)
    for ev in events:
        ph = ev.get('phase', '') or '(unknown)'
        by_phase[ph].append(ev)
    result['by_phase'] = []
    for ph, evs in by_phase.items():
        w, a, nb, mi = burst_stats(evs)
        result['by_phase'].append({
            'phase': ph,
            'event_count': len(evs),
            'wall_clock_sec': int(w),
            'active_sec':     int(a),
            'bursts':         nb,
        })

if JSON_OUT:
    print(json.dumps(result, indent=2, ensure_ascii=False))
    sys.exit(0)

print(f"change:           {result['change_id']}")
print(f"events:           {result['event_count']}")
print(f"idle threshold:   {IDLE}s ({IDLE//60}m)")
print()
print(f"wall_clock:       {fmt_dur(wall)}")
print(f"active (proxy):   {fmt_dur(active)}   ← 估计：{int(active*100/max(wall,1))}% of wall")
print(f"idle (剔除):      {fmt_dur(wall - active)}   ({n_bursts} 个活动窗口, 最长 idle {fmt_dur(max_idle)})")

if BY_PHASE:
    print()
    print(f"{'phase':<14} {'wall':>10} {'active':>10}  events  bursts")
    print('-' * 56)
    for row in result['by_phase']:
        print(f"{row['phase']:<14} {fmt_dur(row['wall_clock_sec']):>10} {fmt_dur(row['active_sec']):>10}  {row['event_count']:>6}  {row['bursts']:>6}")

print()
print('注：active 是估计值，不是精确测量。Cursor/Claude Code 不暴露 per-turn 边界，')
print('   active 计算依赖事件密度。安全失败方向是低估（思考时无事件→算 idle）。')
PYEOF
