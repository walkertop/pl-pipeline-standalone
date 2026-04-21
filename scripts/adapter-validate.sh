#!/usr/bin/env bash
# =============================================================================
# adapter-validate.sh — pl-pipeline Adapter Manifest 校验器
# =============================================================================
#
# 校验一个 adapter 包是否合法：
#   1. 存在 adapter.yaml
#   2. YAML 语法正确
#   3. 符合 adapter-manifest.schema.json 的 JSON Schema
#   4. provides.*.path 引用的文件真实存在
#   5. metadata.id 与目录名一致
#
# 用法:
#   ./scripts/adapter-validate.sh <adapter-dir>
#   ./scripts/adapter-validate.sh adapters/adapter-nextjs-web
#   ./scripts/adapter-validate.sh --all          # 校验 adapters/ 下所有
#
# 退出码:
#   0 = 全部通过
#   1 = 校验失败
#   2 = 参数错误 / 环境问题
#
# 环境依赖: python3（内置 yaml 解析 + 轻量 schema 校验，不依赖 jsonschema pip 包）
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
MODE="single"
TARGET=""

usage() {
  sed -n '2,24p' "$0" | sed 's/^# \{0,1\}//'
  exit 2
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --all)     MODE="all"; shift ;;
    -h|--help) usage ;;
    --*)       log_error "Unknown option: $1"; usage ;;
    *)
      if [[ -z "$TARGET" ]]; then
        TARGET="$1"
      else
        log_error "Too many arguments"; usage
      fi
      shift
      ;;
  esac
done

SCHEMA_FILE="$PL_ASSETS/adapter-sdk/schemas/adapter-manifest.schema.json"
if [[ ! -f "$SCHEMA_FILE" ]]; then
  log_error "Schema not found: $SCHEMA_FILE"
  log_info "请确认 PL_ASSETS 指向正确的 pl-pipeline 安装：$PL_ASSETS"
  exit 2
fi

# ---- 单 adapter 校验 ----
validate_one() {
  local adapter_dir="$1"
  local name
  name=$(basename "$adapter_dir")

  echo ""
  echo "${BOLD}━━━ $name ━━━${NC}"

  if [[ ! -d "$adapter_dir" ]]; then
    log_error "Directory not found: $adapter_dir"
    return 1
  fi

  local manifest="$adapter_dir/adapter.yaml"
  if [[ ! -f "$manifest" ]]; then
    log_error "adapter.yaml not found in $adapter_dir"
    return 1
  fi

  # 用 python3 一次性做所有校验（YAML 解析 + schema + path 引用）
  python3 - "$manifest" "$SCHEMA_FILE" "$adapter_dir" <<'PYEOF'
import sys, os, json, re

MANIFEST, SCHEMA_PATH, ADAPTER_DIR = sys.argv[1], sys.argv[2], sys.argv[3]

errors = []
warnings = []

# ---- 1. YAML 解析 ----
# 优先用 PyYAML；不可用时 fallback 到内置 minimal parser（仅支持 adapter.yaml
# 受限子集：无 anchor/alias、无 flow style、无 multi-document、字符串要求
# 单/双引号或无引号，列表用 '- ' 前缀，值类型 str/int/bool/null/list/dict 即可）
import re as _re

def minimal_yaml_load(text):
    """极简 YAML 解析器，仅覆盖 adapter.yaml 规范范围。"""
    lines = text.split('\n')
    # 预处理：去除纯注释行 + 行尾 " # comment"（但保留字符串内的 #）
    clean_lines = []
    for ln in lines:
        stripped = ln.rstrip()
        # 跳过全空行 / 整行注释
        s = stripped.lstrip()
        if not s or s.startswith('#'):
            clean_lines.append('')
            continue
        # 去除行尾内联注释（粗糙：只要不在引号里）
        # 简化：检测最后一个 ' #' 且前面有空格
        if ' #' in stripped and stripped.count('"') % 2 == 0 and stripped.count("'") % 2 == 0:
            idx = stripped.rfind(' #')
            stripped = stripped[:idx].rstrip()
        clean_lines.append(stripped)

    def parse_scalar(val):
        val = val.strip()
        if val in ('', '~', 'null', 'Null', 'NULL'):
            return None
        if val in ('true', 'True'): return True
        if val in ('false', 'False'): return False
        if (val.startswith('"') and val.endswith('"')) or (val.startswith("'") and val.endswith("'")):
            return val[1:-1]
        # inline flow list: [a, b, "c"]
        if val.startswith('[') and val.endswith(']'):
            inner = val[1:-1].strip()
            if not inner:
                return []
            # 简单逗号切割（不支持嵌套 flow；够用）
            items = []
            for piece in inner.split(','):
                items.append(parse_scalar(piece.strip()))
            return items
        # inline flow dict: {k: v, k2: v2} — MVP 不需要，跳过
        # try int
        try: return int(val)
        except: pass
        try: return float(val)
        except: pass
        return val

    # 递归解析基于缩进的 block 结构
    def indent_of(line):
        if not line: return -1
        i = 0
        while i < len(line) and line[i] == ' ':
            i += 1
        return i

    pos = [0]

    def parse_block(indent):
        """在 >= indent 的缩进层级上解析一个 dict 或 list。"""
        result = None
        while pos[0] < len(clean_lines):
            line = clean_lines[pos[0]]
            if not line:
                pos[0] += 1
                continue
            cur_indent = indent_of(line)
            if cur_indent < indent:
                return result
            content = line[cur_indent:]

            if content.startswith('- '):
                # list item
                if result is None: result = []
                elif not isinstance(result, list):
                    # indentation error or mixed; stop
                    return result
                item_body = content[2:]
                # 有可能 "- key: value"（list-of-dict 内联起始）
                if ':' in item_body and not item_body.startswith(('"', "'")):
                    # inline first kv of dict item
                    key_part, _, val_part = item_body.partition(':')
                    key = key_part.strip()
                    val = val_part.strip()
                    pos[0] += 1
                    item = {}
                    if val:
                        item[key] = parse_scalar(val)
                    else:
                        # 嵌套
                        nested = parse_block(cur_indent + 2)
                        if nested is not None:
                            item[key] = nested
                    # 继续解析此 item 后续的同级 key
                    while pos[0] < len(clean_lines):
                        ln2 = clean_lines[pos[0]]
                        if not ln2:
                            pos[0] += 1
                            continue
                        ind2 = indent_of(ln2)
                        if ind2 < cur_indent + 2:
                            break
                        if ind2 > cur_indent + 2:
                            # 属于上一个 key 的嵌套，不该到这（parse_block 应已消费）
                            break
                        if ln2[cur_indent+2:].startswith('- '):
                            break  # 下一个 list item 从 cur_indent 开始，这里断
                        sub_content = ln2[cur_indent+2:]
                        if ':' not in sub_content:
                            break
                        sk, _, sv = sub_content.partition(':')
                        sk = sk.strip()
                        sv = sv.strip()
                        pos[0] += 1
                        if sv:
                            item[sk] = parse_scalar(sv)
                        else:
                            nested = parse_block(cur_indent + 4)
                            if nested is not None:
                                item[sk] = nested
                    result.append(item)
                elif item_body.strip():
                    # simple scalar list item
                    result.append(parse_scalar(item_body))
                    pos[0] += 1
                else:
                    # nested block after "-"
                    pos[0] += 1
                    nested = parse_block(cur_indent + 2)
                    result.append(nested if nested is not None else {})
            elif ':' in content:
                if result is None: result = {}
                elif not isinstance(result, dict):
                    return result
                key, _, val = content.partition(':')
                key = key.strip()
                val = val.strip()
                pos[0] += 1
                if val:
                    result[key] = parse_scalar(val)
                else:
                    nested = parse_block(cur_indent + 2)
                    result[key] = nested if nested is not None else {}
            else:
                # skip 未知行
                pos[0] += 1
        return result

    return parse_block(0) or {}

try:
    import yaml
    with open(MANIFEST, 'r', encoding='utf-8') as f:
        manifest = yaml.safe_load(f)
except ImportError:
    # fallback: minimal parser
    try:
        with open(MANIFEST, 'r', encoding='utf-8') as f:
            manifest = minimal_yaml_load(f.read())
        warnings.append("PyYAML 未安装，使用内置极简解析器（建议 pip3 install pyyaml 以获得完整 YAML 支持）")
    except Exception as e:
        errors.append(f"minimal YAML parse failed: {e}")
        for e in errors: print(f"  \033[0;31m✗\033[0m {e}")
        sys.exit(1)
except Exception as e:
    errors.append(f"YAML parse failed: {e}")
    for e in errors: print(f"  \033[0;31m✗\033[0m {e}")
    sys.exit(1)

# ---- 2. JSON Schema 轻量校验（不依赖 jsonschema 包）----
with open(SCHEMA_PATH, 'r', encoding='utf-8') as f:
    schema = json.load(f)

def check_required(obj, req_list, path=""):
    for key in req_list:
        if key not in obj:
            errors.append(f"required field missing: {path}{key}")

def check_enum(value, enum_list, field):
    if value not in enum_list:
        errors.append(f"{field}: value '{value}' not in enum {enum_list}")

def check_pattern(value, pattern, field):
    if not isinstance(value, str):
        errors.append(f"{field}: expected string, got {type(value).__name__}: {value!r}")
        return
    if not re.match(pattern, value):
        errors.append(f"{field}: value '{value}' does not match pattern {pattern}")

# Top-level required
check_required(manifest, schema.get("required", []), "")

# apiVersion / kind const
if manifest.get("apiVersion") != "pl.dev/v1":
    errors.append(f"apiVersion must be 'pl.dev/v1', got '{manifest.get('apiVersion')}'")
if manifest.get("kind") != "Adapter":
    errors.append(f"kind must be 'Adapter', got '{manifest.get('kind')}'")

# metadata
md = manifest.get("metadata", {})
check_required(md, ["id", "version", "compatible_pl"], "metadata.")

if "id" in md:
    check_pattern(md["id"], r"^[a-z][a-z0-9-]*$", "metadata.id")
if "version" in md:
    check_pattern(md["version"], r"^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.-]+)?$",
                  "metadata.version")

# metadata.id vs directory name
dir_name = os.path.basename(ADAPTER_DIR)
expected_id = dir_name.replace("adapter-", "", 1) if dir_name.startswith("adapter-") else dir_name
if md.get("id") and md["id"] != expected_id:
    errors.append(f"metadata.id='{md['id']}' does not match directory name"
                  f" (expected '{expected_id}' from '{dir_name}')")

# ---- 3. provides 节文件引用 ----
provides = manifest.get("provides", {})

def check_file_ref(rel_path, field_label):
    full = os.path.join(ADAPTER_DIR, rel_path)
    if not os.path.isfile(full):
        errors.append(f"{field_label}: referenced file not found: {rel_path}"
                      f"  (full: {full})")

templates = provides.get("templates", {}) or {}
for k, v in templates.items():
    if isinstance(v, str):
        check_file_ref(v, f"provides.templates.{k}")

for i, agent in enumerate(provides.get("agents", []) or []):
    if "path" in agent:
        check_file_ref(agent["path"], f"provides.agents[{i}].path")

for i, skill in enumerate(provides.get("skills", []) or []):
    if "path" in skill:
        check_file_ref(skill["path"], f"provides.skills[{i}].path")

for i, rule in enumerate(provides.get("rules", []) or []):
    if "path" in rule:
        check_file_ref(rule["path"], f"provides.rules[{i}].path")
    if "scope" in rule and rule["scope"] not in ("always", "on-demand"):
        errors.append(f"provides.rules[{i}].scope: must be 'always' or 'on-demand',"
                      f" got '{rule['scope']}'")

scripts_dict = provides.get("scripts", {}) or {}
for k, v in scripts_dict.items():
    if isinstance(v, str):
        full = os.path.join(ADAPTER_DIR, v)
        if not os.path.isfile(full):
            errors.append(f"provides.scripts.{k}: file not found: {v}")
        elif not os.access(full, os.X_OK):
            warnings.append(f"provides.scripts.{k}: file not executable: {v}"
                            f"  (run: chmod +x {v})")

# build_adapter.type enum
ba = provides.get("build_adapter")
if ba:
    btype = ba.get("type")
    allowed = ["npm", "pnpm", "yarn", "gradle", "maven", "cargo", "go",
               "uv", "pip", "poetry", "make", "xcodebuild", "custom"]
    if btype not in allowed:
        errors.append(f"provides.build_adapter.type: '{btype}' not in {allowed}")

# ---- 4. piao_emit ----
pe = manifest.get("piao_emit")
if pe:
    if "urn_namespace" not in pe:
        errors.append("piao_emit.urn_namespace is required when piao_emit is present")
    else:
        ns = pe["urn_namespace"]
        if not re.match(r"^urn:piao:[a-z_]+:pl:[a-z_][a-z0-9_-]*$", ns):
            errors.append(f"piao_emit.urn_namespace: '{ns}' does not match expected"
                          f" format 'urn:piao:<kind>:pl:<id>'")

    stages = pe.get("on_stages", [])
    allowed_stages = ["SPEC", "PLAN", "IMPLEMENT", "VERIFY", "OBSERVE", "ARCHIVE"]
    for s in stages:
        if s not in allowed_stages:
            errors.append(f"piao_emit.on_stages: '{s}' not in {allowed_stages}")

# ---- 5. 最小内容检查（建议性）----
if not provides.get("templates"):
    warnings.append("provides.templates is empty (recommend at least spec/plan/taskdag)")
elif not all(k in provides.get("templates", {}) for k in ("spec", "plan", "taskdag")):
    warnings.append("provides.templates should include spec/plan/taskdag (minimum 3)")

if not provides.get("agents"):
    warnings.append("provides.agents is empty (recommend at least 1 architect agent)")

if not provides.get("skills"):
    warnings.append("provides.skills is empty (recommend at least 1 skill)")

# ---- 6. README / case-study 建议检查 ----
if not os.path.isfile(os.path.join(ADAPTER_DIR, "README.md")):
    warnings.append("README.md missing at adapter root")
if not os.path.isfile(os.path.join(ADAPTER_DIR, "docs/case-study.md")):
    warnings.append("docs/case-study.md missing (recommended for user onboarding)")

# ---- 输出 ----
if errors:
    for e in errors:
        print(f"  \033[0;31m✗\033[0m {e}")
if warnings:
    for w in warnings:
        print(f"  \033[0;33m⚠\033[0m {w}")
if not errors and not warnings:
    print("  \033[0;32m✅\033[0m all checks passed")
elif not errors:
    print(f"  \033[0;32m✅\033[0m no errors ({len(warnings)} warnings)")

sys.exit(1 if errors else 0)
PYEOF
  return $?
}

# ---- 主入口 ----
if [[ "$MODE" == "all" ]]; then
  if [[ ! -d "$PL_HOME/adapters" ]]; then
    log_error "adapters/ directory not found at $PL_HOME"
    exit 2
  fi

  local_total=0
  local_pass=0
  local_fail=0
  for d in "$PL_HOME"/adapters/adapter-*; do
    [[ -d "$d" ]] || continue
    local_total=$((local_total + 1))
    if validate_one "$d"; then
      local_pass=$((local_pass + 1))
    else
      local_fail=$((local_fail + 1))
    fi
  done

  echo ""
  echo "${BOLD}━━━ Summary ━━━${NC}"
  echo "Total:  $local_total"
  echo "Pass:   ${GREEN}$local_pass${NC}"
  echo "Fail:   ${RED}$local_fail${NC}"
  [[ $local_fail -eq 0 ]]
  exit $?
fi

if [[ -z "$TARGET" ]]; then
  log_error "Missing <adapter-dir> argument"
  usage
fi

# 解析 TARGET: 支持 adapters/adapter-x 或 /abs/path 或 x (auto-resolve)
if [[ -d "$TARGET" ]]; then
  ADAPTER_DIR="$(cd "$TARGET" && pwd)"
elif [[ -d "$PL_HOME/adapters/$TARGET" ]]; then
  ADAPTER_DIR="$PL_HOME/adapters/$TARGET"
elif [[ -d "$PL_HOME/adapters/adapter-$TARGET" ]]; then
  ADAPTER_DIR="$PL_HOME/adapters/adapter-$TARGET"
else
  log_error "Cannot resolve adapter: $TARGET"
  log_info "Tried: $TARGET, $PL_HOME/adapters/$TARGET, $PL_HOME/adapters/adapter-$TARGET"
  exit 2
fi

validate_one "$ADAPTER_DIR"
