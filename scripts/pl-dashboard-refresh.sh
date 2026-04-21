#!/usr/bin/env bash
# ============================================================================
# pl-dashboard-refresh.sh — 把 pl-status 的真相灌回 dashboard
# ----------------------------------------------------------------------------
# Usage:
#   scripts/pl-dashboard-refresh.sh              # 默认：upsert 并写回 dashboard
#   scripts/pl-dashboard-refresh.sh --validate   # 只校验一致性，不写文件；有漂移返回 1
#   scripts/pl-dashboard-refresh.sh --dry-run    # 打印将要改动的字段，不写文件
#
# 行为约定（upsert 语义）：
#   - dashboard 里已有的 change：只覆盖"可稳定推导"的字段（stage/pipeline/progress/lastUpdate 等）
#   - dashboard 里没有的 change：插入骨架条目（富内容如 taskGroups/questions 由人工补）
#   - dashboard 里有但 pl/ 没有的 change：保留（不删）
#
# 备份：每次写回前备份原文件到 pipeline-output/dashboard/.backup-<timestamp>.html
#
# Exit code:
#   0 = OK（正常写回 / --validate 无漂移）
#   1 = 运行错误（找不到文件 / json 解析失败 / 等等）
#   2 = --validate 模式检测到漂移
# ============================================================================
set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/_env.sh"
REPO_ROOT="$PL_PROJECT"
DASH_HTML="$PL_OUTPUT/dashboard/index.html"
PL_STATUS="$SCRIPT_DIR/pl-status.sh"

if [[ -t 1 ]]; then
  RED=$'\033[0;31m'; GREEN=$'\033[0;32m'; YELLOW=$'\033[0;33m'
  BOLD=$'\033[1m'; DIM=$'\033[2m'; NC=$'\033[0m'
else
  RED=; GREEN=; YELLOW=; BOLD=; DIM=; NC=
fi

MODE="write"   # write | validate | dry-run

while [[ $# -gt 0 ]]; do
  case "$1" in
    --validate) MODE="validate"; shift ;;
    --dry-run)  MODE="dry-run"; shift ;;
    -h|--help)
      sed -n '3,24p' "$0" | sed 's/^# \{0,1\}//'
      exit 0 ;;
    *)
      echo "${RED}未知参数: $1${NC}" >&2
      exit 1 ;;
  esac
done

# ─── 前置检查 ──────────────────────────────────────────────────────────────
if [[ ! -f "$DASH_HTML" ]]; then
  echo "${RED}找不到 dashboard: $DASH_HTML${NC}" >&2
  exit 1
fi
if [[ ! -x "$PL_STATUS" ]]; then
  echo "${RED}pl-status.sh 不可执行: $PL_STATUS${NC}" >&2
  exit 1
fi

# ─── 拿到 pl-status JSON ────────────────────────────────────────────────
STATUS_JSON=$("$PL_STATUS" --json)
if [[ -z "$STATUS_JSON" ]]; then
  echo "${RED}pl-status --json 输出为空${NC}" >&2
  exit 1
fi

# ─── 核心逻辑：Python 驱动 ────────────────────────────────────────────────
PY=$(mktemp /tmp/pl-dash.XXXXXX.py)
trap "rm -f '$PY'" EXIT

cat > "$PY" <<'PY'
"""
pl-dashboard-refresh.sh 的核心逻辑。
从 stdin 读取 pl-status JSON，定位 dashboard 里的 `const CHANGES = [...]`
（JS 对象数组字面量），upsert 后回写。
"""
import json
import os
import re
import sys
import datetime

MODE = os.environ.get('PL_DASH_MODE', 'write')
DASH_HTML = os.environ.get('PL_DASH_HTML', '')

# 颜色
C = {k: os.environ.get('C_' + k, '') for k in ('RED', 'GREEN', 'YELLOW', 'BOLD', 'DIM', 'NC')}

def color(s, k): return f"{C.get(k, '')}{s}{C.get('NC', '')}"

# ─── 读取 pl-status JSON ──────────────────────────────────────────────────
status = json.load(sys.stdin)
pl_changes_list = status.get('changes', [])
pl_changes = {c['id']: c for c in pl_changes_list}

# ─── 读取 dashboard HTML ──────────────────────────────────────────────────
with open(DASH_HTML, 'r', encoding='utf-8') as f:
    html = f.read()

# 定位 const CHANGES = [...]（寻找匹配的 ];）
# 关键挑战：JS 数组内含嵌套 {...} 和 [...]，正则不够用，需要括号计数
start_marker = 'const CHANGES = ['
start_idx = html.find(start_marker)
if start_idx < 0:
    print(color('找不到 dashboard 里的 `const CHANGES = [`', 'RED'), file=sys.stderr)
    sys.exit(1)

array_start = start_idx + len(start_marker) - 1  # 指向 '['
# 从 array_start 开始做括号配平（处理字符串与注释，保证精确）
depth = 0
i = array_start
in_string = False
string_quote = ''
escape_next = False
in_single_comment = False
in_multi_comment = False
end_idx = -1
while i < len(html):
    ch = html[i]
    nxt = html[i+1] if i+1 < len(html) else ''

    if escape_next:
        escape_next = False
        i += 1
        continue

    if in_single_comment:
        if ch == '\n':
            in_single_comment = False
        i += 1
        continue
    if in_multi_comment:
        if ch == '*' and nxt == '/':
            in_multi_comment = False
            i += 2
            continue
        i += 1
        continue
    if in_string:
        if ch == '\\':
            escape_next = True
        elif ch == string_quote:
            in_string = False
        i += 1
        continue

    # 非字符串状态
    if ch in ('"', "'", '`'):
        in_string = True
        string_quote = ch
        i += 1
        continue
    if ch == '/' and nxt == '/':
        in_single_comment = True
        i += 2
        continue
    if ch == '/' and nxt == '*':
        in_multi_comment = True
        i += 2
        continue

    if ch == '[':
        depth += 1
    elif ch == ']':
        depth -= 1
        if depth == 0:
            end_idx = i  # 指向最后的 ]
            break
    i += 1

if end_idx < 0:
    print(color('找不到匹配的 `];` 闭合', 'RED'), file=sys.stderr)
    sys.exit(1)

# 抽出 [...] 子串（含两端括号）
array_str = html[array_start:end_idx + 1]

# ─── 把 JS 数组转成 Python 列表 ──────────────────────────────────────────
# 这是 JS 对象字面量（允许无引号 key、单引号字符串、结尾逗号），不是严格 JSON。
# 策略：用一个轻量的"JS 对象字面量"解析器；失败时降级到 json.loads 失败提示。
# 为减少依赖，自写一个手写解析器（仅支持 CHANGES 里出现的子集）。

class JSLiteralParser:
    def __init__(self, s):
        self.s = s
        self.i = 0

    def err(self, msg):
        context = self.s[max(0, self.i-30):self.i+30]
        raise ValueError(f'{msg} at index {self.i}: ...{context}...')

    def skip_ws_comments(self):
        while self.i < len(self.s):
            ch = self.s[self.i]
            if ch in ' \t\n\r':
                self.i += 1
            elif ch == '/' and self.peek(1) == '/':
                while self.i < len(self.s) and self.s[self.i] != '\n':
                    self.i += 1
            elif ch == '/' and self.peek(1) == '*':
                self.i += 2
                while self.i + 1 < len(self.s) and not (self.s[self.i] == '*' and self.s[self.i+1] == '/'):
                    self.i += 1
                self.i += 2
            else:
                break

    def peek(self, n=0):
        p = self.i + n
        return self.s[p] if p < len(self.s) else ''

    def expect(self, ch):
        self.skip_ws_comments()
        if self.i >= len(self.s) or self.s[self.i] != ch:
            self.err(f'expected {ch!r}')
        self.i += 1

    def parse(self):
        self.skip_ws_comments()
        v = self.parse_value()
        self.skip_ws_comments()
        if self.i != len(self.s):
            self.err('trailing content')
        return v

    def parse_value(self):
        self.skip_ws_comments()
        ch = self.peek()
        if ch == '[': return self.parse_array()
        if ch == '{': return self.parse_object()
        if ch in ('"', "'", '`'): return self.parse_string()
        if ch == 't' or ch == 'f': return self.parse_bool()
        if ch == 'n': return self.parse_null()
        if ch == '-' or ch.isdigit(): return self.parse_number()
        self.err(f'unexpected char {ch!r}')

    def parse_array(self):
        self.expect('[')
        out = []
        self.skip_ws_comments()
        if self.peek() == ']':
            self.i += 1
            return out
        while True:
            self.skip_ws_comments()
            if self.peek() == ']':   # trailing comma
                self.i += 1
                return out
            out.append(self.parse_value())
            self.skip_ws_comments()
            if self.peek() == ',':
                self.i += 1
                continue
            self.expect(']')
            return out

    def parse_object(self):
        self.expect('{')
        out = {}
        self.skip_ws_comments()
        if self.peek() == '}':
            self.i += 1
            return out
        while True:
            self.skip_ws_comments()
            if self.peek() == '}':
                self.i += 1
                return out
            key = self.parse_key()
            self.skip_ws_comments()
            self.expect(':')
            val = self.parse_value()
            out[key] = val
            self.skip_ws_comments()
            if self.peek() == ',':
                self.i += 1
                continue
            self.expect('}')
            return out

    def parse_key(self):
        self.skip_ws_comments()
        ch = self.peek()
        if ch in ('"', "'", '`'):
            return self.parse_string()
        # 无引号 identifier
        start = self.i
        while self.i < len(self.s) and (self.s[self.i].isalnum() or self.s[self.i] in '_$'):
            self.i += 1
        if start == self.i:
            self.err('expected key')
        return self.s[start:self.i]

    def parse_string(self):
        quote = self.s[self.i]
        self.i += 1
        out = []
        while self.i < len(self.s):
            ch = self.s[self.i]
            if ch == '\\':
                nxt = self.peek(1)
                if nxt in ('n',): out.append('\n')
                elif nxt == 't': out.append('\t')
                elif nxt == 'r': out.append('\r')
                elif nxt == '\\': out.append('\\')
                elif nxt == "'": out.append("'")
                elif nxt == '"': out.append('"')
                elif nxt == '`': out.append('`')
                else: out.append(nxt)
                self.i += 2
                continue
            if ch == quote:
                self.i += 1
                return ''.join(out)
            out.append(ch)
            self.i += 1
        self.err('unterminated string')

    def parse_bool(self):
        if self.s.startswith('true', self.i):
            self.i += 4
            return True
        if self.s.startswith('false', self.i):
            self.i += 5
            return False
        self.err('expected true/false')

    def parse_null(self):
        if self.s.startswith('null', self.i):
            self.i += 4
            return None
        self.err('expected null')

    def parse_number(self):
        start = self.i
        if self.peek() == '-':
            self.i += 1
        while self.i < len(self.s) and (self.s[self.i].isdigit() or self.s[self.i] in '.eE+-'):
            self.i += 1
        lit = self.s[start:self.i]
        try:
            if '.' in lit or 'e' in lit or 'E' in lit:
                return float(lit)
            return int(lit)
        except ValueError:
            self.err(f'bad number {lit!r}')

try:
    existing = JSLiteralParser(array_str).parse()
except ValueError as e:
    print(color(f'dashboard CHANGES 数组解析失败: {e}', 'RED'), file=sys.stderr)
    sys.exit(1)

if not isinstance(existing, list):
    print(color('CHANGES 不是数组', 'RED'), file=sys.stderr)
    sys.exit(1)

# ─── Upsert 逻辑 ──────────────────────────────────────────────────────────
STAGE_ORDER = ['SPEC', 'PLAN', 'IMPLEMENT', 'VERIFY', 'OBSERVE', 'ARCHIVE']
STAGE_ICON = {'done': '✅', 'active': '💻', 'warn': '🟡', 'pending': '⬜'}

def stage_class(stage):
    return stage.lower() if isinstance(stage, str) else ''

def derive_pipeline(stage):
    """根据当前 stage 推导 pipeline 数组每个节点的 status/icon。"""
    out = []
    try:
        cur_idx = STAGE_ORDER.index(stage)
    except ValueError:
        cur_idx = -1
    for idx, name in enumerate(STAGE_ORDER):
        if cur_idx < 0:
            status = 'pending'
        elif idx < cur_idx:
            status = 'done'
        elif idx == cur_idx:
            status = 'active'
        else:
            status = 'pending'
        out.append({'name': name, 'status': status, 'icon': STAGE_ICON[status]})
    return out

UPSERT_FIELDS = {
    'stage', 'stageClass', 'pipeline',
    'progress', 'lastUpdate', 'complexity',
    'name',
}

diffs = []     # for dry-run / validate

def upsert_one(dash_entry, pl_entry):
    """按字段粒度覆盖；返回 (更新后的 entry, diff 列表)"""
    d = dict(dash_entry)  # copy
    this_diffs = []

    # 1. stage / stageClass
    new_stage = pl_entry.get('stage', 'UNKNOWN')
    if new_stage != 'UNKNOWN' and d.get('stage') != new_stage:
        this_diffs.append(('stage', d.get('stage'), new_stage))
        d['stage'] = new_stage
    new_sc = stage_class(new_stage)
    if new_sc and d.get('stageClass') != new_sc:
        this_diffs.append(('stageClass', d.get('stageClass'), new_sc))
        d['stageClass'] = new_sc

    # 2. pipeline（按 stage 完全推导）
    if new_stage in STAGE_ORDER:
        new_pipe = derive_pipeline(new_stage)
        if d.get('pipeline') != new_pipe:
            this_diffs.append(('pipeline', '...', f'derived from stage={new_stage}'))
            d['pipeline'] = new_pipe

    # 3. progress
    tasks = pl_entry.get('tasks')
    if tasks:
        new_prog = {'done': tasks.get('done', 0), 'total': tasks.get('total', 0)}
        if d.get('progress') != new_prog:
            this_diffs.append(('progress', d.get('progress'), new_prog))
            d['progress'] = new_prog

    # 4. lastUpdate
    lu = pl_entry.get('last_update')
    if lu and d.get('lastUpdate') != lu:
        this_diffs.append(('lastUpdate', d.get('lastUpdate'), lu))
        d['lastUpdate'] = lu

    # 5. complexity（保留 dashboard 的文字，除非 dashboard 没有且 pl 有）
    pl_cx = pl_entry.get('complexity')
    if pl_cx and not d.get('complexity'):
        this_diffs.append(('complexity', None, pl_cx))
        d['complexity'] = pl_cx

    # 6. name（同上，只在 dashboard 缺时补）
    pl_name = pl_entry.get('name')
    if pl_name and not d.get('name'):
        this_diffs.append(('name', None, pl_name))
        d['name'] = pl_name

    return d, this_diffs

def make_new_entry(pl_entry):
    """dashboard 里没有时，造一个最小骨架 entry。"""
    stage = pl_entry.get('stage', 'UNKNOWN')
    tasks = pl_entry.get('tasks', {}) or {}
    return {
        'id': pl_entry['id'],
        'name': pl_entry.get('name', pl_entry['id']),
        'pageId': None,
        'icon': '📋',
        'iconClass': '',
        'stage': stage,
        'stageClass': stage_class(stage),
        'complexity': pl_entry.get('complexity') or '',
        'domain': pl_entry.get('business_domain') or '',
        'fileCount': 0,
        'reuseRate': '',
        'weexSource': '',
        'lastUpdate': pl_entry.get('last_update') or '',
        'pipeline': derive_pipeline(stage) if stage in STAGE_ORDER else [],
        'selfCheck': [],
        'progress': {'done': tasks.get('done', 0), 'total': tasks.get('total', 0)},
        'alert': None,
        'questions': [],
        'commands': [
            {'label': 'Status', 'icon': '📊', 'cmd': '/pl:status', 'desc': '查看状态', 'class': 'primary'},
        ],
        'nextAction': '（pl-pipeline 自动生成骨架；请按实际补齐 taskGroups/questions 等富内容）',
        'taskGroups': [],
    }

existing_ids = {e['id']: idx for idx, e in enumerate(existing)}
new_array = list(existing)
upserted = 0
inserted = 0
for pl_id, pl_entry in pl_changes.items():
    if pl_id in existing_ids:
        idx = existing_ids[pl_id]
        updated, this_diffs = upsert_one(existing[idx], pl_entry)
        if this_diffs:
            diffs.append({'id': pl_id, 'action': 'upsert', 'fields': this_diffs})
            upserted += 1
        new_array[idx] = updated
    else:
        new_entry = make_new_entry(pl_entry)
        diffs.append({'id': pl_id, 'action': 'insert', 'stage': pl_entry.get('stage')})
        inserted += 1
        new_array.append(new_entry)

# 漂移检测（validate 模式要报）
has_drift = bool(diffs)

# ─── 输出 / 写回 ─────────────────────────────────────────────────────────

def emit_report():
    if not diffs:
        print(color('✓ dashboard 已与 pl-status 一致（无漂移）', 'GREEN'))
        return
    print(color(f'发现 {len(diffs)} 处差异：', 'BOLD'))
    for d in diffs:
        if d['action'] == 'insert':
            print(f"  {color('+ INSERT', 'GREEN')} {d['id']}  (stage={d.get('stage')})")
        else:
            print(f"  {color('~ UPSERT', 'YELLOW')} {d['id']}")
            for field, old, new in d['fields']:
                def fmt(v):
                    if isinstance(v, (dict, list)): return json.dumps(v, ensure_ascii=False)
                    return str(v)
                print(f"      {field}: {color(fmt(old)[:60], 'DIM')} → {color(fmt(new)[:60], 'GREEN')}")

if MODE == 'validate':
    emit_report()
    sys.exit(2 if has_drift else 0)

if MODE == 'dry-run':
    emit_report()
    print()
    print(color(f'[dry-run] 不写文件。共计 upsert={upserted}, insert={inserted}', 'DIM'))
    sys.exit(0)

# ─── write 模式 ──────────────────────────────────────────────────────────
if not diffs:
    print(color('dashboard 已与 pl-status 一致，未写文件。', 'GREEN'))
    sys.exit(0)

# 构造新的 JS 数组字面量
def to_js(v, indent=0, min_indent=4):
    """Python 对象 -> JS 对象字面量字符串（保持可读性）"""
    pad = ' ' * (indent + min_indent)
    inner_pad = ' ' * (indent + min_indent + 2)
    if v is None:
        return 'null'
    if isinstance(v, bool):
        return 'true' if v else 'false'
    if isinstance(v, (int, float)):
        return str(v)
    if isinstance(v, str):
        # 单引号；转义单引号和反斜杠
        s = v.replace('\\', '\\\\').replace("'", "\\'")
        return f"'{s}'"
    if isinstance(v, list):
        if not v:
            return '[]'
        # 判断是否都是"短 dict"（每个 dict 长度 ≤ 4 且无嵌套 list/dict 字段）
        parts = []
        for item in v:
            parts.append(to_js(item, indent + 2, min_indent))
        # 统一多行
        return '[\n' + ',\n'.join(pad + p for p in parts) + f',\n{" " * indent}]'
    if isinstance(v, dict):
        if not v:
            return '{}'
        parts = []
        for k, val in v.items():
            # key：identifier 则不加引号，否则加单引号
            if isinstance(k, str) and re.match(r'^[A-Za-z_$][A-Za-z0-9_$]*$', k):
                key_repr = k
            else:
                key_repr = "'" + str(k).replace("'", "\\'") + "'"
            parts.append(f'{key_repr}: {to_js(val, indent + 2, min_indent)}')
        return '{\n' + ',\n'.join(inner_pad + p for p in parts) + f',\n{pad}}}'
    return 'null'

# 顶层数组整体字符串化（保持原缩进风格）
new_array_str = to_js(new_array, indent=0, min_indent=2)

# ─── 备份 ──────────────────────────────────────────────────────────────
ts = datetime.datetime.now().strftime('%Y%m%d-%H%M%S')
backup_path = os.path.join(os.path.dirname(DASH_HTML), f'.backup-{ts}.html')
with open(backup_path, 'w', encoding='utf-8') as f:
    f.write(html)

# ─── 重新组装 HTML 并写回 ──────────────────────────────────────────────
new_html = html[:array_start] + new_array_str + html[end_idx + 1:]
with open(DASH_HTML, 'w', encoding='utf-8') as f:
    f.write(new_html)

print(color('✓ dashboard 已刷新', 'GREEN'))
print(f"  备份: {backup_path}")
print()
emit_report()
print()
print(color(f'✓ upsert={upserted}, insert={inserted}', 'BOLD'))
PY

# ─── 执行 ───────────────────────────────────────────────────────────────
printf '%s' "$STATUS_JSON" | \
  PL_DASH_MODE="$MODE" \
  PL_DASH_HTML="$DASH_HTML" \
  C_RED="$RED" C_GREEN="$GREEN" C_YELLOW="$YELLOW" C_BOLD="$BOLD" C_DIM="$DIM" C_NC="$NC" \
  python3 "$PY"
rc=$?
exit "$rc"
