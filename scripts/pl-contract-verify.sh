#!/usr/bin/env bash
# =============================================================================
# pl-contract-verify.sh — 拿 consumer pacts 对账当前 adapter.yaml，报 broken / warn
# =============================================================================
#
# 这是 v1.7 双向 CDC 第 3 步（broker verify）。
# B1 的 aggregator 把"事实"沉淀成了 pl/contracts/<change>.consumed.yaml；
# B3 的 verify 把"事实"和"adapter 当前承诺"对齐：
#   - 如果 consumer 用了某个 skill/rule/build_command 现在 adapter 不再 provides → BROKEN
#   - 如果 consumer 用了某个 capability，但 adapter 声明 backed_by: null → BROKEN
#   - 如果 capability removed_in <= 当前 adapter version → BROKEN
#   - 如果 capability deprecated_in <= 当前 adapter version 但还能用 → WARN
#
# 用法:
#   pl-contract-verify.sh                       # 验所有 consumer pact
#   pl-contract-verify.sh --change <id>         # 只验一个
#   pl-contract-verify.sh --json                # 输出 JSON 报告
#   pl-contract-verify.sh --strict              # 警告也算失败（CI 模式）
#
# 退出码:
#   0 = 全部 satisfied（warnings 不影响）
#   1 = 至少一个 broken；或 --strict 下有任意 warning
#   2 = 参数错误 / 找不到 adapter / pact 文件损坏
# =============================================================================

source "$(dirname "${BASH_SOURCE[0]}")/_env.sh"
set -uo pipefail

CHANGE_FILTER=""
JSON_OUT=false
STRICT=false

usage() {
  sed -n '2,28p' "$0" | sed 's/^# \{0,1\}//'
  exit 2
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --change) CHANGE_FILTER="$2"; shift 2 ;;
    --json)   JSON_OUT=true; shift ;;
    --strict) STRICT=true; shift ;;
    -h|--help) usage ;;
    *) echo "Unknown option: $1" >&2; usage ;;
  esac
done

CONTRACTS_DIR="$PL_PROJECT/pl/contracts"
ADAPTERS_DIR="$PL_HOME/adapters"

if [[ ! -d "$CONTRACTS_DIR" ]]; then
  echo "No contracts directory: $CONTRACTS_DIR (run pl-contract-aggregate.sh first)" >&2
  exit 0
fi

CHANGE_FILTER="$CHANGE_FILTER" JSON_OUT=$JSON_OUT STRICT=$STRICT \
CONTRACTS_DIR="$CONTRACTS_DIR" ADAPTERS_DIR="$ADAPTERS_DIR" \
python3 - <<'PYEOF'
import os, sys, json, glob
from collections import defaultdict

try:
    import yaml
except ImportError:
    print("PyYAML required. Install: pip3 install --user --break-system-packages pyyaml", file=sys.stderr)
    sys.exit(2)

CHANGE_FILTER  = os.environ.get('CHANGE_FILTER', '') or None
JSON_OUT       = os.environ.get('JSON_OUT') == 'true'
STRICT         = os.environ.get('STRICT') == 'true'
CONTRACTS_DIR  = os.environ['CONTRACTS_DIR']
ADAPTERS_DIR   = os.environ['ADAPTERS_DIR']

# ---- 加载所有 adapter.yaml，按 id 索引 ----
adapters = {}
for ayml in sorted(glob.glob(os.path.join(ADAPTERS_DIR, '*/adapter.yaml'))):
    try:
        d = yaml.safe_load(open(ayml))
        aid = (d.get('metadata') or {}).get('id') or os.path.basename(os.path.dirname(ayml))
        adapters[aid] = {'path': ayml, 'spec': d}
    except Exception as e:
        print(f"WARN: failed to load {ayml}: {e}", file=sys.stderr)

# ---- 构建 adapter -> {kind: set(ids)} 的索引 ----
def index_adapter(spec):
    p = spec.get('provides') or {}
    idx = defaultdict(dict)  # kind -> id -> meta
    for sk in (p.get('skills') or []):
        idx['skills'][sk['id']] = sk
    for rl in (p.get('rules') or []):
        idx['rules'][rl['id']] = rl
    for ag in (p.get('agents') or []):
        idx['agents'][ag['id']] = ag
    tmpls = p.get('templates') or {}
    if isinstance(tmpls, dict):
        for tid in tmpls.keys():
            idx['templates'][tid] = {'id': tid, 'path': tmpls[tid]}
    elif isinstance(tmpls, list):
        for t in tmpls:
            idx['templates'][t['id']] = t
    ba = p.get('build_adapter') or {}
    cmds = ba.get('commands') or {}
    for cid in cmds.keys():
        idx['build_commands'][cid] = cmds[cid] if isinstance(cmds[cid], dict) else {'cmd': cmds[cid]}
    for cap in (p.get('capabilities') or []):
        idx['capabilities'][cap['id']] = cap
    return idx

# ---- semver 比较（简单但够用：major.minor.patch；非 semver 视为 0.0.0）----
def parse_semver(s):
    if not s: return None
    s = str(s).split('-', 1)[0].split('+', 1)[0].lstrip('v')
    try:
        parts = s.split('.')
        while len(parts) < 3: parts.append('0')
        return tuple(int(parts[i]) for i in range(3))
    except (ValueError, AttributeError):
        return None

def semver_le(a, b):
    """a <= b? 任一无效→False"""
    pa, pb = parse_semver(a), parse_semver(b)
    return pa is not None and pb is not None and pa <= pb

# ---- 加载所有 consumer pacts ----
pact_files = sorted(glob.glob(os.path.join(CONTRACTS_DIR, '*.consumed.yaml')))
if CHANGE_FILTER:
    pact_files = [p for p in pact_files if os.path.basename(p) == f'{CHANGE_FILTER}.consumed.yaml']

if not pact_files:
    msg = f"No consumer pacts found"
    if CHANGE_FILTER: msg += f" for change '{CHANGE_FILTER}'"
    print(msg, file=sys.stderr)
    sys.exit(0)

# ---- 验每个 pact ----
SECTION_LABEL = {
    'templates':      'template',
    'skills':         'skill',
    'rules':          'rule',
    'agents':         'agent',
    'build_commands': 'build_command',
    'capabilities':   'capability',
}

reports = []
for pf in pact_files:
    pact = yaml.safe_load(open(pf))
    cid  = pact['metadata']['change_id']
    adapter_id = pact['provider']['adapter']
    adapter_versions = pact['provider'].get('versions_seen') or []

    if adapter_id not in adapters:
        reports.append({
            'change_id': cid, 'adapter': adapter_id, 'status': 'broken',
            'violations': [{
                'kind': 'adapter', 'id': adapter_id, 'severity': 'error',
                'reason': f"adapter '{adapter_id}' not found under {ADAPTERS_DIR}/*/adapter.yaml",
            }],
            'satisfied': [], 'warnings_count': 0,
        })
        continue

    spec = adapters[adapter_id]['spec']
    current_version = (spec.get('metadata') or {}).get('version', '')
    idx = index_adapter(spec)

    violations = []
    warnings   = []
    satisfied  = []
    consumed = pact.get('consumed') or {}
    for section, items in consumed.items():
        kind_label = SECTION_LABEL.get(section, section)
        provided = idx.get(section, {})
        for it in items:
            aid = it['id']
            uses = it.get('uses', 0)
            if aid not in provided:
                violations.append({
                    'kind': kind_label, 'id': aid, 'severity': 'error',
                    'reason': f"consumer used {kind_label}/{aid} (uses={uses}) but adapter {adapter_id}@{current_version} no longer provides it",
                })
                continue

            # capabilities 多走一段：检查 backed_by null / deprecated / removed
            if section == 'capabilities':
                cap = provided[aid]
                backed_by = cap.get('backed_by', 'MISSING')
                deprecated_in = cap.get('deprecated_in')
                removed_in    = cap.get('removed_in')

                if backed_by is None:
                    violations.append({
                        'kind': 'capability', 'id': aid, 'severity': 'error',
                        'reason': f"capability '{aid}' is declared with backed_by: null (explicitly unsupported). reason: {cap.get('reason','(none)')}",
                    })
                    continue
                if removed_in and current_version and semver_le(removed_in, current_version):
                    violations.append({
                        'kind': 'capability', 'id': aid, 'severity': 'error',
                        'reason': f"capability '{aid}' was removed_in {removed_in} (current adapter {current_version})",
                    })
                    continue
                if deprecated_in and current_version and semver_le(deprecated_in, current_version):
                    warnings.append({
                        'kind': 'capability', 'id': aid, 'severity': 'warn',
                        'reason': f"capability '{aid}' deprecated_in {deprecated_in} (current adapter {current_version}); plan migration",
                    })
                    satisfied.append({'kind': 'capability', 'id': aid, 'note': 'deprecated'})
                    continue

            satisfied.append({'kind': kind_label, 'id': aid})

    if violations:
        status = 'broken'
    elif warnings:
        status = 'warn'
    else:
        status = 'satisfied'

    reports.append({
        'change_id':       cid,
        'adapter':         adapter_id,
        'adapter_version': current_version,
        'versions_seen':   adapter_versions,
        'status':          status,
        'violations':      violations,
        'warnings':        warnings,
        'satisfied':       satisfied,
        'warnings_count':  len(warnings),
    })

# ---- 输出 ----
broken_count    = sum(1 for r in reports if r['status'] == 'broken')
warn_count      = sum(1 for r in reports if r['status'] == 'warn')
satisfied_count = sum(1 for r in reports if r['status'] == 'satisfied')

if JSON_OUT:
    print(json.dumps({
        'apiVersion': 'piao.dev/v1',
        'kind':       'ContractVerifyReport',
        'summary': {
            'total':     len(reports),
            'satisfied': satisfied_count,
            'warn':      warn_count,
            'broken':    broken_count,
        },
        'reports': reports,
    }, indent=2, ensure_ascii=False))
else:
    BOLD = '\033[1m'; RED = '\033[31m'; YEL = '\033[33m'; GRN = '\033[32m'; DIM = '\033[2m'; NC = '\033[0m'
    if not sys.stdout.isatty():
        BOLD = RED = YEL = GRN = DIM = NC = ''

    print(f"{BOLD}━━━ Contract Verify ━━━{NC}")
    print(f"  {len(reports)} pact(s) checked")
    print(f"  {GRN}{satisfied_count} satisfied{NC}, {YEL}{warn_count} with warnings{NC}, {RED}{broken_count} broken{NC}")
    print()

    for r in reports:
        if r['status'] == 'satisfied':
            symbol, color = '✓', GRN
        elif r['status'] == 'warn':
            symbol, color = '!', YEL
        else:
            symbol, color = '✗', RED
        ver_str = f"@{r.get('adapter_version','?')}" if r.get('adapter_version') else ''
        print(f"  {color}{symbol}{NC}  {r['change_id']:<28s} → {r['adapter']}{ver_str}  [{r['status']}]")
        for v in r.get('violations', []):
            print(f"       {RED}error{NC}  {v['kind']}/{v['id']}: {v['reason']}")
        for w in r.get('warnings', []):
            print(f"       {YEL}warn {NC}  {w['kind']}/{w['id']}: {w['reason']}")
        if r.get('satisfied') and r['status'] != 'satisfied':
            sat_summary = defaultdict(int)
            for s in r['satisfied']: sat_summary[s['kind']] += 1
            note = ', '.join(f"{k}={v}" for k, v in sorted(sat_summary.items()))
            print(f"       {DIM}also satisfied: {note}{NC}")

    print()
    if broken_count > 0:
        print(f"{RED}FAILED{NC}: {broken_count} broken pact(s). adapter is missing capabilities consumers depend on.")
    elif warn_count > 0 and STRICT:
        print(f"{YEL}STRICT FAIL{NC}: {warn_count} warning(s); --strict treats warnings as errors.")
    elif warn_count > 0:
        print(f"{YEL}OK with warnings{NC}: {warn_count} pact(s) using deprecated capability.")
    else:
        print(f"{GRN}OK{NC}: all pacts satisfied.")

# ---- 退出码 ----
if broken_count > 0:
    sys.exit(1)
if warn_count > 0 and STRICT:
    sys.exit(1)
sys.exit(0)
PYEOF
