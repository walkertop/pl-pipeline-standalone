#!/usr/bin/env bash
# =============================================================================
# pl-contract-aggregate.sh — 把 trace 流的 adapter.use 事件聚合成 consumer pact + 注册表
# =============================================================================
#
# 这是 v1.7 双向 CDC 的 broker 等价物：不是 HTTP 服务、不是数据库，
# 而是一个"扫 trace、生成可 git diff 的 yaml 账本"的纯函数式脚本。
#
# 输入:
#   pipeline-output/trace/<change>.events.jsonl   (所有 trace 文件)
#
# 输出:
#   pl/contracts/<change>.consumed.yaml           (per-change consumer pact)
#   pl/contracts/_registry.yaml                   (跨 change 的反向索引)
#
# 用法:
#   pl-contract-aggregate.sh                      # 处理所有 change（默认写文件）
#   pl-contract-aggregate.sh --change <id>        # 仅处理一个 change
#   pl-contract-aggregate.sh --check              # 只检查是否有 diff（不写文件，CI 模式：有 → exit 1）
#   pl-contract-aggregate.sh --json               # dry-run，输出 JSON 摘要不写文件
#
# 退出码:
#   0 = 已生成 / 无变化
#   1 = --check 模式且有变化
#   2 = 参数错误
# =============================================================================

source "$(dirname "${BASH_SOURCE[0]}")/_env.sh"
set -uo pipefail

CHANGE_FILTER=""
CHECK_MODE=false
JSON_OUT=false

usage() {
  sed -n '2,30p' "$0" | sed 's/^# \{0,1\}//'
  exit 2
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --change) CHANGE_FILTER="$2"; shift 2 ;;
    --check)  CHECK_MODE=true; shift ;;
    --json)   JSON_OUT=true; shift ;;
    -h|--help) usage ;;
    *) echo "Unknown option: $1" >&2; usage ;;
  esac
done

TRACE_DIR_LOCAL="$PL_OUTPUT/trace"
CONTRACTS_DIR="$PL_PROJECT/pl/contracts"

if [[ ! -d "$TRACE_DIR_LOCAL" ]]; then
  echo "No trace directory: $TRACE_DIR_LOCAL" >&2
  exit 0
fi

mkdir -p "$CONTRACTS_DIR"

CHANGE_FILTER="$CHANGE_FILTER" CHECK_MODE=$CHECK_MODE JSON_OUT=$JSON_OUT \
TRACE_DIR_LOCAL="$TRACE_DIR_LOCAL" CONTRACTS_DIR="$CONTRACTS_DIR" \
python3 - <<'PYEOF'
import os, sys, json, glob, hashlib
from datetime import datetime, timezone
from collections import defaultdict, OrderedDict

CHANGE_FILTER  = os.environ.get('CHANGE_FILTER', '') or None
CHECK_MODE     = os.environ.get('CHECK_MODE') == 'true'
JSON_OUT       = os.environ.get('JSON_OUT') == 'true'
TRACE_DIR      = os.environ['TRACE_DIR_LOCAL']
CONTRACTS_DIR  = os.environ['CONTRACTS_DIR']
GENERATOR      = 'pl-contract-aggregate.sh@v1.7.0'

# 读 trace 文件（忽略 _global*）
trace_files = sorted(glob.glob(os.path.join(TRACE_DIR, '*.events.jsonl')))
trace_files = [f for f in trace_files if not os.path.basename(f).startswith('_')]

# 按 change_id 分组事件
by_change = defaultdict(list)
all_files_by_change = defaultdict(list)
for path in trace_files:
    with open(path) as f:
        for ln in f:
            ln = ln.strip()
            if not ln: continue
            try:
                ev = json.loads(ln)
            except json.JSONDecodeError:
                continue
            if ev.get('event') != 'adapter.use':
                continue
            cid = ev.get('change_id')
            if not cid:
                continue
            if CHANGE_FILTER and cid != CHANGE_FILTER:
                continue
            by_change[cid].append(ev)
            if path not in all_files_by_change[cid]:
                all_files_by_change[cid].append(path)

if not by_change:
    if CHANGE_FILTER:
        print(f"No adapter.use events found for change '{CHANGE_FILTER}'.", file=sys.stderr)
    else:
        print("No adapter.use events found in any trace file.", file=sys.stderr)
    sys.exit(0)

# ---- per-change consumer pact ----
def kind_to_section(kind):
    return {
        'skill':         'skills',
        'rule':          'rules',
        'template':      'templates',
        'agent':         'agents',
        'capability':    'capabilities',
        'build_command': 'build_commands',
    }.get(kind)

def now_iso():
    return datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')

def build_pact(change_id, events, source_files):
    # 按 (kind, id) 聚合
    grouped = defaultdict(list)
    adapters = set()
    versions_seen = set()
    for ev in events:
        d = ev.get('data') or {}
        kind = d.get('asset_kind')
        aid  = d.get('asset_id')
        if not kind or not aid: continue
        section = kind_to_section(kind)
        if not section: continue
        grouped[(section, aid)].append(ev)
        if d.get('adapter'):
            adapters.add(d['adapter'])
        if d.get('adapter_version'):
            versions_seen.add(d['adapter_version'])

    # 一个 change 通常对应一个 adapter；若多个，用 / 拼接（registry 保留每个）
    primary_adapter = '/'.join(sorted(adapters)) if adapters else 'unknown'

    consumed = OrderedDict()
    for section in ['templates', 'skills', 'rules', 'agents', 'build_commands', 'capabilities']:
        items = []
        keys = sorted([k for k in grouped if k[0] == section], key=lambda k: k[1])
        for (sec, aid) in keys:
            evs = sorted(grouped[(sec, aid)], key=lambda e: e.get('ts',''))
            phases = sorted({e.get('phase','') for e in evs if e.get('phase')})
            entry = OrderedDict([
                ('id',         aid),
                ('uses',       len(evs)),
                ('first_seen', evs[0].get('ts','')),
                ('last_seen',  evs[-1].get('ts','')),
            ])
            if phases:
                entry['phases'] = phases
            if sec == 'build_commands':
                entry['pass'] = sum(1 for e in evs if (e.get('data') or {}).get('status') == 'pass')
                entry['fail'] = sum(1 for e in evs if (e.get('data') or {}).get('status') == 'fail')
            items.append(entry)
        if items:
            consumed[section] = items

    pact = OrderedDict([
        ('apiVersion', 'piao.dev/v1'),
        ('kind',       'ConsumerContract'),
        ('metadata', OrderedDict([
            ('change_id',    change_id),
            ('generated_at', now_iso()),
            ('generator',    GENERATOR),
            ('source_files', [os.path.relpath(f, os.path.dirname(os.path.dirname(CONTRACTS_DIR))) for f in source_files]),
            ('event_count',  len(events)),
        ])),
        ('provider', OrderedDict([
            ('adapter',       primary_adapter),
            ('versions_seen', sorted(versions_seen)),
        ])),
        ('consumed', consumed),
    ])
    return pact

# ---- 简单 YAML emit（避免引入 PyYAML 依赖）----
# 用 indent_str（字符串）而非 indent（层级）以正确处理 list-of-dict 的混合缩进。
def yaml_dump(obj, indent_str=''):
    lines = []
    if isinstance(obj, (dict, OrderedDict)):
        for k, v in obj.items():
            if isinstance(v, (dict, OrderedDict)):
                if not v:
                    lines.append(f'{indent_str}{k}: {{}}')
                else:
                    lines.append(f'{indent_str}{k}:')
                    lines.extend(yaml_dump(v, indent_str + '  '))
            elif isinstance(v, list):
                if not v:
                    lines.append(f'{indent_str}{k}: []')
                else:
                    lines.append(f'{indent_str}{k}:')
                    for item in v:
                        if isinstance(item, (dict, OrderedDict)):
                            # list item 是 dict：先按"item 的所有 key 都比 list 名缩进 2 + 2"生成，
                            # 然后把首行的前 4 个空格换成 "  - "，让 YAML 认 list 项标记。
                            sub = yaml_dump(item, indent_str + '    ')
                            if sub:
                                # 切掉首行的 indent_str+"    " 前缀，换成 indent_str+"  - "
                                sub[0] = indent_str + '  - ' + sub[0][len(indent_str)+4:]
                            lines.extend(sub)
                        else:
                            lines.append(f'{indent_str}  - {yaml_scalar(item)}')
            else:
                lines.append(f'{indent_str}{k}: {yaml_scalar(v)}')
    return lines

def yaml_scalar(v):
    if v is None: return 'null'
    if isinstance(v, bool): return 'true' if v else 'false'
    if isinstance(v, (int, float)): return str(v)
    s = str(v)
    if s == '' or any(c in s for c in ':#"\'') or s.startswith(('-','>','|','&','*','!','%','@','`')):
        return json.dumps(s, ensure_ascii=False)
    return s

# ---- 写 per-change pacts，记录 hash 用于 --check ----
written = []
hashes  = {}
for cid in sorted(by_change.keys()):
    pact = build_pact(cid, by_change[cid], all_files_by_change[cid])
    text = '\n'.join(yaml_dump(pact)) + '\n'
    out  = os.path.join(CONTRACTS_DIR, f'{cid}.consumed.yaml')
    h    = hashlib.sha256(text.encode()).hexdigest()[:12]
    hashes[cid] = h
    prev = open(out).read() if os.path.exists(out) else ''
    def normalize(t):
        # generated_at 每次都不同，比对时剔除
        return '\n'.join(l for l in t.splitlines() if not l.lstrip().startswith('generated_at:'))
    changed = normalize(prev) != normalize(text)
    if JSON_OUT:
        written.append((cid, 'changed' if changed else 'unchanged'))
    elif CHECK_MODE:
        if changed:
            print(f'CHANGED  {os.path.relpath(out, os.path.dirname(CONTRACTS_DIR))}')
        written.append((cid, 'changed' if changed else 'unchanged'))
    else:
        with open(out, 'w') as f:
            f.write(text)
        written.append((cid, 'written' if changed else 'unchanged'))

# ---- 构建 _registry.yaml ----
adapter_to_consumers = defaultdict(set)
adapter_asset_usage  = defaultdict(lambda: defaultdict(lambda: defaultdict(lambda: {'changes': set(), 'total_uses': 0})))
pacts_summary = []
total_use_events = 0

for cid in sorted(by_change.keys()):
    evs = by_change[cid]
    total_use_events += len(evs)
    adapters_in_change = set()
    versions_in_change = set()
    section_counts = defaultdict(lambda: {'distinct': set(), 'uses': 0})
    last_seen = ''
    for ev in evs:
        d = ev.get('data') or {}
        kind = d.get('asset_kind'); aid = d.get('asset_id')
        adapter_id = d.get('adapter','unknown')
        ver = d.get('adapter_version','')
        section = kind_to_section(kind) if kind else None
        if not section or not aid: continue
        adapters_in_change.add(adapter_id)
        if ver: versions_in_change.add(ver)
        adapter_to_consumers[adapter_id].add(cid)
        adapter_asset_usage[adapter_id][section][aid]['changes'].add(cid)
        adapter_asset_usage[adapter_id][section][aid]['total_uses'] += 1
        section_counts[section]['distinct'].add(aid)
        section_counts[section]['uses'] += 1
        if ev.get('ts','') > last_seen:
            last_seen = ev.get('ts','')
    for ad in sorted(adapters_in_change):
        pacts_summary.append(OrderedDict([
            ('change_id',     cid),
            ('adapter',       ad),
            ('versions_seen', sorted(versions_in_change)),
            ('consumed_summary', OrderedDict([
                (section, OrderedDict([('distinct', len(c['distinct'])), ('uses', c['uses'])]))
                for section, c in sorted(section_counts.items())
            ])),
            ('last_seen',     last_seen),
        ]))

adapters_block = OrderedDict()
for ad in sorted(adapter_to_consumers.keys()):
    asset_usage = OrderedDict()
    for section in sorted(adapter_asset_usage[ad].keys()):
        asset_usage[section] = OrderedDict()
        for aid in sorted(adapter_asset_usage[ad][section].keys()):
            entry = adapter_asset_usage[ad][section][aid]
            asset_usage[section][aid] = OrderedDict([
                ('changes',    len(entry['changes'])),
                ('total_uses', entry['total_uses']),
            ])
    adapters_block[ad] = OrderedDict([
        ('consumer_count', len(adapter_to_consumers[ad])),
        ('consumers',      sorted(adapter_to_consumers[ad])),
        ('asset_usage',    asset_usage),
    ])

registry = OrderedDict([
    ('apiVersion', 'piao.dev/v1'),
    ('kind',       'ContractRegistry'),
    ('metadata', OrderedDict([
        ('generated_at',     now_iso()),
        ('generator',        GENERATOR),
        ('change_count',     len(by_change)),
        ('adapter_count',    len(adapter_to_consumers)),
        ('total_use_events', total_use_events),
    ])),
    ('pacts',     pacts_summary),
    ('adapters',  adapters_block),
])

reg_path = os.path.join(CONTRACTS_DIR, '_registry.yaml')
reg_text = '\n'.join(yaml_dump(registry)) + '\n'

if JSON_OUT:
    print(json.dumps({
        'change_count':     len(by_change),
        'adapter_count':    len(adapter_to_consumers),
        'total_use_events': total_use_events,
        'pacts': [{'change_id': c, 'status': s} for c, s in written],
    }, indent=2, ensure_ascii=False))
    sys.exit(0)

if CHECK_MODE:
    prev = open(reg_path).read() if os.path.exists(reg_path) else ''
    def normalize(t): return '\n'.join(l for l in t.splitlines() if not l.lstrip().startswith('generated_at:'))
    if normalize(prev) != normalize(reg_text):
        print(f'CHANGED  {os.path.relpath(reg_path, os.path.dirname(CONTRACTS_DIR))}')
    any_change = any(s == 'changed' for _, s in written) or normalize(prev) != normalize(reg_text)
    sys.exit(1 if any_change else 0)

with open(reg_path, 'w') as f:
    f.write(reg_text)

print(f"aggregated {len(by_change)} change(s), {len(adapter_to_consumers)} adapter(s), {total_use_events} use event(s)")
for cid, status in written:
    print(f"  - {cid}: {status}")
print(f"  registry: {os.path.relpath(reg_path, os.path.dirname(CONTRACTS_DIR))}")
PYEOF
