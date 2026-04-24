#!/usr/bin/env bash
# =============================================================================
# pl-contract-query.sh — 反查谁在用某个 capability / skill / rule / build_command
# =============================================================================
#
# v1.7 CDC 系统的"读侧"工具。aggregate/verify 解决"写"和"对账"，query 解决：
#   - adapter 作者想砍某个资产前，先看看「谁在用」
#   - 用户想知道「我用了哪些 adapter 能力」
#   - PR review 时想看「这个 capability 被多少 change 签了约」
#
# 数据源：$PL_PROJECT/pl/contracts/{<change>.consumed.yaml,_registry.yaml}
# 不发起 verify 行为，只是格式化展示已有事实。
#
# 用法:
#   pl-contract-query.sh                              # 全局汇总
#   pl-contract-query.sh --capability <id> [--adapter <id>]
#   pl-contract-query.sh --skill <id>         [--adapter <id>]
#   pl-contract-query.sh --rule <id>          [--adapter <id>]
#   pl-contract-query.sh --build-command <id> [--adapter <id>]
#   pl-contract-query.sh --agent <id>         [--adapter <id>]
#   pl-contract-query.sh --adapter <id>               # 列某 adapter 全部 consumer + 资产
#   pl-contract-query.sh --change <id>                # 友好版 pact 视图
#   pl-contract-query.sh --json                       # 任何上述查询都可加 --json
#
# 退出码:
#   0 = 查询完成（命中或未命中都算成功）
#   1 = 找不到 contracts 目录 / pact 文件损坏
#   2 = 参数错误
# =============================================================================

source "$(dirname "${BASH_SOURCE[0]}")/_env.sh"
set -uo pipefail

KIND_FILTER=""        # capability / skill / rule / build_command / agent
ID_FILTER=""
ADAPTER_FILTER=""
CHANGE_FILTER=""
JSON_OUT=false

usage() {
  sed -n '2,32p' "$0" | sed 's/^# \{0,1\}//'
  exit 2
}

set_kind() {
  if [[ -n "$KIND_FILTER" ]]; then
    echo "Error: only one of --capability/--skill/--rule/--build-command/--agent allowed" >&2
    exit 2
  fi
  KIND_FILTER="$1"
  ID_FILTER="$2"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --capability)    set_kind capability    "$2"; shift 2 ;;
    --skill)         set_kind skill         "$2"; shift 2 ;;
    --rule)          set_kind rule          "$2"; shift 2 ;;
    --build-command) set_kind build_command "$2"; shift 2 ;;
    --agent)         set_kind agent         "$2"; shift 2 ;;
    --adapter)       ADAPTER_FILTER="$2"; shift 2 ;;
    --change)        CHANGE_FILTER="$2";  shift 2 ;;
    --json)          JSON_OUT=true;       shift ;;
    -h|--help)       usage ;;
    *) echo "Unknown option: $1" >&2; usage ;;
  esac
done

CONTRACTS_DIR="$PL_PROJECT/pl/contracts"
if [[ ! -d "$CONTRACTS_DIR" ]]; then
  if $JSON_OUT; then
    echo '{"apiVersion":"piao.dev/v1","kind":"ContractQueryReport","error":"no contracts dir","contracts_dir":"'"$CONTRACTS_DIR"'"}'
  else
    echo "No contracts directory: $CONTRACTS_DIR" >&2
    echo "Hint: run 'pl-contract-aggregate.sh --change <id>' first." >&2
  fi
  exit 1
fi

KIND_FILTER="$KIND_FILTER" ID_FILTER="$ID_FILTER" \
ADAPTER_FILTER="$ADAPTER_FILTER" CHANGE_FILTER="$CHANGE_FILTER" \
JSON_OUT=$JSON_OUT CONTRACTS_DIR="$CONTRACTS_DIR" \
python3 - <<'PYEOF'
import os, sys, json, glob

try:
    import yaml
except ImportError:
    print("PyYAML required. Install: pip3 install --user --break-system-packages pyyaml", file=sys.stderr)
    sys.exit(1)

KIND_FILTER    = os.environ.get('KIND_FILTER', '') or None
ID_FILTER      = os.environ.get('ID_FILTER', '') or None
ADAPTER_FILTER = os.environ.get('ADAPTER_FILTER', '') or None
CHANGE_FILTER  = os.environ.get('CHANGE_FILTER', '') or None
JSON_OUT       = os.environ.get('JSON_OUT') == 'true'
CONTRACTS_DIR  = os.environ['CONTRACTS_DIR']

# ---- 加载所有 pact + registry ----
pacts = []
for f in sorted(glob.glob(os.path.join(CONTRACTS_DIR, '*.consumed.yaml'))):
    try:
        d = yaml.safe_load(open(f)) or {}
    except Exception as e:
        print(f"Failed to parse {f}: {e}", file=sys.stderr)
        sys.exit(1)
    if (d.get('kind') or '') != 'ConsumerContract':
        continue
    pacts.append(d)

registry = None
reg_path = os.path.join(CONTRACTS_DIR, '_registry.yaml')
if os.path.isfile(reg_path):
    registry = yaml.safe_load(open(reg_path)) or {}

# 资产分类的复数→单数映射（pact 里的 section name vs 用户输入 kind）
KIND_TO_PLURAL = {
    'capability':    'capabilities',
    'skill':         'skills',
    'rule':          'rules',
    'build_command': 'build_commands',
    'agent':         'agents',
}
ALL_KINDS = list(KIND_TO_PLURAL.keys())

# =========== 模式 1：反查具体资产 (--capability/--skill/...) ==================
def query_asset(kind, asset_id, adapter_filter):
    """谁在用 kind/asset_id？返回 [{change_id, adapter, version, uses, phases, first_seen, last_seen}]"""
    plural = KIND_TO_PLURAL[kind]
    hits = []
    for pact in pacts:
        adapter = (pact.get('provider') or {}).get('adapter')
        if adapter_filter and adapter != adapter_filter:
            continue
        consumed = (pact.get('consumed') or {})
        items = consumed.get(plural, []) or []
        for it in items:
            if it.get('id') == asset_id:
                hits.append({
                    'change_id':  pact.get('metadata', {}).get('change_id'),
                    'adapter':    adapter,
                    'versions_seen': pact.get('provider', {}).get('versions_seen', []),
                    'uses':       it.get('uses', 0),
                    'phases':     it.get('phases', []),
                    'first_seen': it.get('first_seen'),
                    'last_seen':  it.get('last_seen'),
                })
    return hits

# =========== 模式 2：列某 adapter 的全部 consumer (--adapter alone) ===========
def query_adapter(adapter_id):
    """某 adapter 的所有 consumer pact + 资产消费总览"""
    related = [p for p in pacts if (p.get('provider') or {}).get('adapter') == adapter_id]
    by_change = []
    for p in related:
        meta = p.get('metadata') or {}
        consumed = p.get('consumed') or {}
        summary = {}
        for kind, plural in KIND_TO_PLURAL.items():
            items = consumed.get(plural, []) or []
            if items:
                summary[plural] = sorted(it.get('id') for it in items if it.get('id'))
        by_change.append({
            'change_id': meta.get('change_id'),
            'event_count': meta.get('event_count'),
            'consumed': summary,
        })
    return {
        'adapter': adapter_id,
        'consumer_count': len(by_change),
        'consumers': by_change,
    }

# =========== 模式 3：单 change pact 视图 (--change) ============================
def query_change(change_id):
    for p in pacts:
        if (p.get('metadata') or {}).get('change_id') == change_id:
            return p
    return None

# =========== 模式 4：全局汇总（无参） ==========================================
def query_summary():
    by_adapter = {}
    for p in pacts:
        adapter = (p.get('provider') or {}).get('adapter') or 'UNKNOWN'
        rec = by_adapter.setdefault(adapter, {'pacts': 0, 'kinds': {k: 0 for k in ALL_KINDS}})
        rec['pacts'] += 1
        consumed = p.get('consumed') or {}
        for kind, plural in KIND_TO_PLURAL.items():
            rec['kinds'][kind] += len(consumed.get(plural, []) or [])
    return {
        'total_pacts':   len(pacts),
        'total_adapters': len(by_adapter),
        'by_adapter':    by_adapter,
    }

# ============================ 调度 ============================================
result = {'apiVersion': 'piao.dev/v1', 'kind': 'ContractQueryReport'}

if KIND_FILTER:
    hits = query_asset(KIND_FILTER, ID_FILTER, ADAPTER_FILTER)
    result['query'] = {'kind': KIND_FILTER, 'id': ID_FILTER, 'adapter_filter': ADAPTER_FILTER}
    result['hit_count'] = len(hits)
    result['hits'] = hits
elif CHANGE_FILTER:
    pact = query_change(CHANGE_FILTER)
    result['query'] = {'change_id': CHANGE_FILTER}
    result['found'] = pact is not None
    result['pact']  = pact
elif ADAPTER_FILTER:
    result['query'] = {'adapter': ADAPTER_FILTER}
    result.update(query_adapter(ADAPTER_FILTER))
else:
    result['query'] = {'mode': 'summary'}
    result.update(query_summary())

# ============================ 输出 ============================================
if JSON_OUT:
    print(json.dumps(result, indent=2, ensure_ascii=False, default=str))
    sys.exit(0)

BOLD='\033[1m'; DIM='\033[2m'; GRN='\033[32m'; YEL='\033[33m'; CYN='\033[36m'; NC='\033[0m'
if not sys.stdout.isatty():
    BOLD = DIM = GRN = YEL = CYN = NC = ''

def fmt_phases(ps):
    return ','.join(ps) if ps else '-'

if KIND_FILTER:
    title = f"{KIND_FILTER}/{ID_FILTER}"
    if ADAPTER_FILTER:
        title += f"  (adapter: {ADAPTER_FILTER})"
    print(f"{BOLD}━━━ Query: {title} ━━━{NC}")
    print(f"  {result['hit_count']} consumer(s) found in {len(pacts)} pact(s)")
    print()
    if not result['hits']:
        print(f"  {DIM}(no consumer is using this asset){NC}")
        sys.exit(0)
    # 表头
    print(f"  {BOLD}{'change':<28} {'adapter':<24} {'uses':>5}  {'phases':<24}  {'last_seen'}{NC}")
    for h in result['hits']:
        ver = h['versions_seen'][0] if h['versions_seen'] else '?'
        ad  = f"{h['adapter']}@{ver}"
        print(f"  {h['change_id']:<28} {ad:<24} {GRN}{h['uses']:>5}{NC}  {fmt_phases(h['phases']):<24}  {DIM}{h['last_seen']}{NC}")

elif CHANGE_FILTER:
    if not result['found']:
        print(f"No pact found for change_id: {CHANGE_FILTER}")
        sys.exit(0)
    p = result['pact']
    meta = p.get('metadata') or {}
    prov = p.get('provider') or {}
    print(f"{BOLD}━━━ Pact: {meta.get('change_id')} ━━━{NC}")
    print(f"  adapter:       {CYN}{prov.get('adapter')}{NC}  versions: {prov.get('versions_seen')}")
    print(f"  events:        {meta.get('event_count')}  generated_at: {DIM}{meta.get('generated_at')}{NC}")
    print()
    consumed = p.get('consumed') or {}
    for kind, plural in KIND_TO_PLURAL.items():
        items = consumed.get(plural, []) or []
        if not items:
            continue
        print(f"  {BOLD}{plural}{NC} ({len(items)})")
        for it in items:
            print(f"    - {it.get('id'):<40} uses={it.get('uses', 0):<3} phases={fmt_phases(it.get('phases'))}")
        print()

elif ADAPTER_FILTER:
    print(f"{BOLD}━━━ Adapter: {ADAPTER_FILTER} ━━━{NC}")
    print(f"  {result['consumer_count']} consumer pact(s)")
    print()
    if not result['consumers']:
        print(f"  {DIM}(no pact references this adapter){NC}")
        sys.exit(0)
    for c in result['consumers']:
        print(f"  {CYN}■ {c['change_id']}{NC}  ({c['event_count']} events)")
        for plural, ids in (c.get('consumed') or {}).items():
            print(f"      {plural}: {', '.join(ids)}")
        print()

else:
    print(f"{BOLD}━━━ Contract Summary ━━━{NC}")
    print(f"  {result['total_pacts']} pact(s) across {result['total_adapters']} adapter(s)")
    print()
    if not result['by_adapter']:
        print(f"  {DIM}(no pacts in {CONTRACTS_DIR}){NC}")
        sys.exit(0)
    print(f"  {BOLD}{'adapter':<24} {'pacts':>5}  {'caps':>5} {'skl':>4} {'rul':>4} {'bld':>4} {'agt':>4}{NC}")
    for adapter, rec in sorted(result['by_adapter'].items()):
        k = rec['kinds']
        print(f"  {adapter:<24} {rec['pacts']:>5}  {k['capability']:>5} {k['skill']:>4} {k['rule']:>4} {k['build_command']:>4} {k['agent']:>4}")
    print()
    print(f"  {DIM}hint: pl-contract-query --capability <id> | --skill <id> | --change <id> | --adapter <id>{NC}")

PYEOF
