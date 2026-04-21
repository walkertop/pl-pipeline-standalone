#!/usr/bin/env bash
# =============================================================================
# adapter-install.sh — pl-pipeline Adapter 注入器
# =============================================================================
#
# 把一个 adapter 包的资产按 injection-contract.md 注入到宿主项目。
#
# 用法:
#   ./scripts/adapter-install.sh <adapter-dir> [target-project]
#   ./scripts/adapter-install.sh --force <adapter-dir> [target-project]
#   ./scripts/adapter-install.sh --dry-run <adapter-dir> [target-project]
#
#   target-project 默认 = \$PL_PROJECT
#
# 选项:
#   --force        覆盖已存在的 agents/skills/rules（默认跳过）
#   --dry-run      只显示将要执行的操作，不实际写文件
#   --no-validate  跳过 adapter-validate.sh 预检（不推荐）
#
# 退出码:
#   0 = 成功
#   1 = 失败
#   2 = 参数错误
#
# 安装后产物:
#   <target-project>/.pl-adapter.yaml     ← 注入元数据
#   <target-project>/pl/templates/*.md    ← adapter 的模板
#   <target-project>/.codebuddy/{agents,skills,rules}/*.md
#   <target-project>/scripts/adapter-<id>-*.sh
#
# =============================================================================

# shellcheck source=./_env.sh
source "$(dirname "${BASH_SOURCE[0]}")/_env.sh"
set -euo pipefail

# ---- 颜色 ----
if [[ -t 1 ]]; then
  RED=$'\033[0;31m'; GREEN=$'\033[0;32m'; YELLOW=$'\033[0;33m'
  BLUE=$'\033[0;34m'; BOLD=$'\033[1m'; DIM=$'\033[2m'; NC=$'\033[0m'
else
  RED=; GREEN=; YELLOW=; BLUE=; BOLD=; DIM=; NC=
fi

log_info()    { echo "${BLUE}ℹ${NC} $*"; }
log_ok()      { echo "${GREEN}✅${NC} $*"; }
log_warn()    { echo "${YELLOW}⚠${NC}  $*"; }
log_error()   { echo "${RED}✗${NC}  $*" >&2; }

# ---- 参数 ----
ADAPTER_DIR=""
TARGET=""
FORCE=false
DRY_RUN=false
SKIP_VALIDATE=false

usage() {
  sed -n '2,31p' "$0" | sed 's/^# \{0,1\}//'
  exit 2
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --force)       FORCE=true; shift ;;
    --dry-run)     DRY_RUN=true; shift ;;
    --no-validate) SKIP_VALIDATE=true; shift ;;
    -h|--help)     usage ;;
    --*)           log_error "Unknown option: $1"; usage ;;
    *)
      if [[ -z "$ADAPTER_DIR" ]]; then
        ADAPTER_DIR="$1"
      elif [[ -z "$TARGET" ]]; then
        TARGET="$1"
      else
        log_error "Too many positional arguments"; usage
      fi
      shift
      ;;
  esac
done

[[ -z "$ADAPTER_DIR" ]] && { log_error "Missing <adapter-dir>"; usage; }

# ---- 解析 adapter-dir ----
if [[ -d "$ADAPTER_DIR" ]]; then
  ADAPTER_DIR="$(cd "$ADAPTER_DIR" && pwd)"
elif [[ -d "$PL_HOME/adapters/$ADAPTER_DIR" ]]; then
  ADAPTER_DIR="$PL_HOME/adapters/$ADAPTER_DIR"
elif [[ -d "$PL_HOME/adapters/adapter-$ADAPTER_DIR" ]]; then
  ADAPTER_DIR="$PL_HOME/adapters/adapter-$ADAPTER_DIR"
else
  log_error "Cannot find adapter: $ADAPTER_DIR"
  exit 2
fi

MANIFEST="$ADAPTER_DIR/adapter.yaml"
[[ -f "$MANIFEST" ]] || { log_error "adapter.yaml not found at $MANIFEST"; exit 2; }

# ---- 目标项目 ----
[[ -z "$TARGET" ]] && TARGET="$PL_PROJECT"
TARGET="$(cd "$TARGET" && pwd)"
[[ -d "$TARGET" ]] || { log_error "Target project directory not found: $TARGET"; exit 2; }

if [[ ! -f "$TARGET/pl/config.yaml" ]]; then
  log_warn "Target not pl-initialized (missing pl/config.yaml)"
  log_info "建议先在目标项目创建 pl/config.yaml（可从 \$PL_ASSETS/pl/config.default.yaml 拷贝）"
fi

# ---- 预检（除非 --no-validate） ----
if ! $SKIP_VALIDATE; then
  log_info "Running adapter-validate.sh first..."
  if ! "$(dirname "${BASH_SOURCE[0]}")/adapter-validate.sh" "$ADAPTER_DIR"; then
    log_error "Validation failed. Fix the issues or use --no-validate to skip."
    exit 1
  fi
  echo ""
fi

# ---- 解析 manifest 关键字段（给 shell 用）----
# 用 python3 提取字段，输出 KEY=VALUE，shell 再 eval
META=$(python3 - "$MANIFEST" <<'PYEOF'
import sys, re, os

MANIFEST = sys.argv[1]
ADAPTER_DIR = os.path.dirname(MANIFEST)

# 复用 adapter-validate.sh 里的 minimal parser
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
        if val in ('true',): return True
        if val in ('false',): return False
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
    with open(MANIFEST) as f:
        m = yaml.safe_load(f)
except ImportError:
    with open(MANIFEST) as f:
        m = minimal_yaml_load(f.read())

md = m.get('metadata', {})
prov = m.get('provides', {})
ba = prov.get('build_adapter', {}) or {}
pe = m.get('piao_emit', {}) or {}

import shlex

def emit(key, val):
    """输出 shell-safe 的 KEY='quoted value' 形式"""
    if val is None:
        val = ''
    s = str(val)
    # 用 shlex.quote 保证 eval 安全（含空格、单引号等）
    print(f"{key}={shlex.quote(s)}")

emit("ADAPTER_ID", md.get('id',''))
emit("ADAPTER_VERSION", md.get('version',''))
emit("ADAPTER_NAME", md.get('name',''))

# templates
tpls = prov.get('templates', {}) or {}
emit("TPL_KEYS", ' '.join(tpls.keys()))
for k, v in tpls.items():
    emit(f"TPL_{k.upper()}_PATH", v)

# agents
agents = prov.get('agents', []) or []
emit("AGENTS_COUNT", len(agents))
for i, a in enumerate(agents):
    emit(f"AGENT_{i}_PATH", a.get('path',''))

# skills
skills = prov.get('skills', []) or []
emit("SKILLS_COUNT", len(skills))
for i, s in enumerate(skills):
    emit(f"SKILL_{i}_PATH", s.get('path',''))

# rules
rules = prov.get('rules', []) or []
emit("RULES_COUNT", len(rules))
for i, r in enumerate(rules):
    emit(f"RULE_{i}_PATH", r.get('path',''))

# scripts
scripts = prov.get('scripts', {}) or {}
emit("SCRIPT_KEYS", ' '.join(scripts.keys()))
for k, v in scripts.items():
    safe_k = k.replace('-', '_').upper()
    emit(f"SCRIPT_{safe_k}_PATH", v)

# build_adapter env derivation
if ba:
    cmds = ba.get('commands', {}) or {}
    cc = cmds.get('compile_check', {})
    cc_cmd = cc if isinstance(cc, str) else (cc.get('cmd', '') if isinstance(cc, dict) else '')
    emit("BA_TYPE", ba.get('type',''))
    emit("BA_COMPILE_CHECK_CMD", cc_cmd)
    ln = cmds.get('lint', '')
    emit("BA_LINT_CMD", ln if isinstance(ln, str) else (ln.get('cmd','') if isinstance(ln, dict) else ''))
    ts = cmds.get('test', '')
    emit("BA_TEST_CMD", ts if isinstance(ts, str) else (ts.get('cmd','') if isinstance(ts, dict) else ''))

# piao_emit
if pe:
    emit("PIAO_URN_NS", pe.get('urn_namespace',''))
PYEOF
)
eval "$META"

[[ -z "${ADAPTER_ID:-}" ]] && { log_error "Failed to parse adapter.yaml"; exit 1; }
[[ -z "${ADAPTER_VERSION:-}" ]] && { log_error "Failed to parse version"; exit 1; }

echo "${BOLD}━━━ Installing adapter ━━━${NC}"
echo "  id:      $ADAPTER_ID"
echo "  version: $ADAPTER_VERSION"
echo "  name:    ${ADAPTER_NAME:-(no name)}"
echo "  source:  $ADAPTER_DIR"
echo "  target:  $TARGET"
$DRY_RUN && echo "  ${YELLOW}(dry-run mode - no files will be written)${NC}"
$FORCE   && echo "  ${YELLOW}(force mode - existing agents/skills/rules will be overwritten)${NC}"
echo ""

# ---- 操作记录 ----
INSTALLED_FILES=()

# 统一拷贝函数
do_copy() {
  local src="$1" dst="$2" strategy="$3"   # strategy: overwrite | skip-if-exists
  local rel_dst="${dst#$TARGET/}"

  if [[ ! -f "$src" ]]; then
    log_warn "source not found: $src (skipped)"
    return
  fi

  if [[ "$strategy" == "skip-if-exists" ]] && [[ -f "$dst" ]] && ! $FORCE; then
    log_warn "$rel_dst exists, skipped (use --force to overwrite)"
    return
  fi

  if $DRY_RUN; then
    echo "  ${DIM}would copy → $rel_dst${NC}"
  else
    mkdir -p "$(dirname "$dst")"
    cp "$src" "$dst"
    log_ok "$rel_dst"
  fi
  INSTALLED_FILES+=("$rel_dst")
}

# ---- 1. templates → pl/templates/ (overwrite) ----
echo "${BOLD}[1/5] templates${NC}"
for k in ${TPL_KEYS:-}; do
  # bash 3.2 兼容：用 tr 做 uppercase
  k_upper=$(printf '%s' "$k" | tr '[:lower:]' '[:upper:]')
  varname="TPL_${k_upper}_PATH"
  path_val="${!varname:-}"
  [[ -z "$path_val" ]] && continue
  do_copy "$ADAPTER_DIR/$path_val" "$TARGET/pl/templates/$k.md" "overwrite"
done

# ---- 2. agents → .codebuddy/agents/ (skip-if-exists) ----
echo ""
echo "${BOLD}[2/5] agents${NC}"
for ((i=0; i<${AGENTS_COUNT:-0}; i++)); do
  varname="AGENT_${i}_PATH"
  path_val="${!varname:-}"
  [[ -z "$path_val" ]] && continue
  basename=$(basename "$path_val")
  do_copy "$ADAPTER_DIR/$path_val" "$TARGET/.codebuddy/agents/$basename" "skip-if-exists"
done

# ---- 3. skills → .codebuddy/skills/ ----
echo ""
echo "${BOLD}[3/5] skills${NC}"
for ((i=0; i<${SKILLS_COUNT:-0}; i++)); do
  varname="SKILL_${i}_PATH"
  path_val="${!varname:-}"
  [[ -z "$path_val" ]] && continue
  basename=$(basename "$path_val")
  do_copy "$ADAPTER_DIR/$path_val" "$TARGET/.codebuddy/skills/$basename" "skip-if-exists"
done

# ---- 4. rules → .codebuddy/rules/ ----
echo ""
echo "${BOLD}[4/5] rules${NC}"
for ((i=0; i<${RULES_COUNT:-0}; i++)); do
  varname="RULE_${i}_PATH"
  path_val="${!varname:-}"
  [[ -z "$path_val" ]] && continue
  basename=$(basename "$path_val")
  do_copy "$ADAPTER_DIR/$path_val" "$TARGET/.codebuddy/rules/$basename" "skip-if-exists"
done

# ---- 5. scripts → scripts/adapter-<id>-<key>.sh ----
echo ""
echo "${BOLD}[5/5] scripts${NC}"
for k in ${SCRIPT_KEYS:-}; do
  # key 转大写 + 下划线 (bash 3.2 兼容)
  safe_k=$(printf '%s' "$k" | tr '[:lower:]-' '[:upper:]_')
  varname="SCRIPT_${safe_k}_PATH"
  path_val="${!varname:-}"
  [[ -z "$path_val" ]] && continue
  dst="$TARGET/scripts/adapter-${ADAPTER_ID}-${k}.sh"
  do_copy "$ADAPTER_DIR/$path_val" "$dst" "overwrite"
  if ! $DRY_RUN && [[ -f "$dst" ]]; then
    chmod +x "$dst"
  fi
done

# ---- 生成 .pl-adapter.yaml ----
echo ""
echo "${BOLD}━━━ metadata ━━━${NC}"

ADAPTER_SHA=$(shasum -a 256 "$MANIFEST" | awk '{print $1}')
INSTALLED_AT=$(date -u +'%Y-%m-%dT%H:%M:%SZ')

if $DRY_RUN; then
  log_info "would write $TARGET/.pl-adapter.yaml"
else
  cat > "$TARGET/.pl-adapter.yaml" << EOF
# Managed by pl-pipeline adapter-install.sh
# Do not edit by hand; use adapter-install --upgrade / --remove instead.

apiVersion: pl.dev/v1
adapter:
  id: $ADAPTER_ID
  version: $ADAPTER_VERSION
  name: "${ADAPTER_NAME:-}"
  installed_at: "$INSTALLED_AT"
  installed_from: "$ADAPTER_DIR"
  source_sha256: "$ADAPTER_SHA"

installed_files:
EOF
  for f in "${INSTALLED_FILES[@]}"; do
    echo "  - $f" >> "$TARGET/.pl-adapter.yaml"
  done
  echo "" >> "$TARGET/.pl-adapter.yaml"

  if [[ -n "${BA_TYPE:-}" ]]; then
    cat >> "$TARGET/.pl-adapter.yaml" << EOF
build_adapter:
  type: $BA_TYPE
  env:
    PL_BUILD_CHECK_CMD: "${BA_COMPILE_CHECK_CMD:-}"
    PL_LINT_CMD: "${BA_LINT_CMD:-}"
    PL_TEST_CMD: "${BA_TEST_CMD:-}"
EOF
  fi

  log_ok ".pl-adapter.yaml"
fi

# ---- Summary ----
echo ""
echo "${BOLD}━━━ Summary ━━━${NC}"
if $DRY_RUN; then
  echo "  ${YELLOW}Dry run — no changes applied${NC}"
  echo "  Would install ${#INSTALLED_FILES[@]} files"
else
  echo "  ${GREEN}✅ Installed${NC} $ADAPTER_ID@$ADAPTER_VERSION → $TARGET"
  echo "  Files written: ${#INSTALLED_FILES[@]}"
  echo ""
  echo "  Next steps:"
  if [[ -n "${BA_COMPILE_CHECK_CMD:-}" ]]; then
    echo "    • In your shell: ${BOLD}export PL_BUILD_CHECK_CMD=\"$BA_COMPILE_CHECK_CMD\"${NC}"
  fi
  echo "    • Start your first change: ${BOLD}/pl:proposal <change-id>${NC}"
  echo "    • Or (CLI): see adapters/adapter-$ADAPTER_ID/docs/case-study.md"
fi
