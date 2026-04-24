#!/usr/bin/env bash
# =============================================================================
# pl-detect.sh — 扫描项目结构，给出 pl-pipeline 接入建议（不写任何文件）
# =============================================================================
#
# 用法:
#   pl detect [<dir>] [--json] [--quiet]
#
# 行为:
#   - 默认扫 $PWD（也可以传一个目录）
#   - 识别每个子目录的技术栈（frontend / api / crawler / contracts ...）
#   - 输出"建议"列表：哪个模块装哪个 adapter / 写自定义 build.yaml
#   - 默认不写任何文件；纯 read-only
#
# 退出码: 0 永远成功（建议本身不是错误）
#
# =============================================================================
# 设计原则:
#   - detector 是无副作用纯函数，输入路径 → 输出 detection 行
#   - detection 行格式（用 \t 分隔，避免与文件名冲突）:
#       MODULE \t STACK \t CONFIDENCE \t EVIDENCE \t SUGGESTION
#   - confidence: high / medium / low
#   - 主入口收集所有 detection 后渲染 markdown table 或 JSON
# =============================================================================

# shellcheck source=./_env.sh
source "$(dirname "${BASH_SOURCE[0]}")/_env.sh"
# _env.sh 强制 set -euo pipefail；本脚本特殊：单个 detector 失败不能停整个扫描
# 而且 bash 3.2 在 set -e + process substitution + pipefail 组合下经常 silent crash
set +e
set +o pipefail
set -u

# ---- 颜色 ----
if [[ -t 1 ]]; then
  C_RED=$'\033[0;31m'; C_GRN=$'\033[0;32m'; C_YEL=$'\033[0;33m'
  C_BLU=$'\033[0;34m'; C_CYN=$'\033[0;36m'; C_BLD=$'\033[1m'
  C_DIM=$'\033[2m'; C_OFF=$'\033[0m'
else
  C_RED=; C_GRN=; C_YEL=; C_BLU=; C_CYN=; C_BLD=; C_DIM=; C_OFF=
fi

usage() {
  cat <<EOF
用法: pl detect [<dir>] [--json] [--quiet]

扫描项目结构（默认 \$PWD），输出 pl-pipeline 接入建议。
完全只读，不写任何文件。

选项:
  --json     输出结构化 JSON（适合脚本消费 / 后续 --apply）
  --quiet    精简输出，仅给建议清单
  -h, --help 本帮助
EOF
}

ROOT="$PWD"
JSON=false
QUIET=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)  usage; exit 0 ;;
    --json)     JSON=true; shift ;;
    --quiet)    QUIET=true; shift ;;
    --*)        echo "未知参数: $1" >&2; usage; exit 2 ;;
    *)          ROOT="$1"; shift ;;
  esac
done

[[ -d "$ROOT" ]] || { echo "目录不存在: $ROOT" >&2; exit 2; }
ROOT="$(cd "$ROOT" && pwd)"

# ---- detection 收集 ----
# 每行: MODULE\tSTACK\tCONFIDENCE\tEVIDENCE\tSUGGESTION_ID\tSUGGESTION_TEXT
DETECTIONS=()

emit() {
  # $1 module, $2 stack, $3 confidence, $4 evidence, $5 sugid, $6 sugtext
  DETECTIONS+=("$1"$'\t'"$2"$'\t'"$3"$'\t'"$4"$'\t'"$5"$'\t'"$6")
}

# ---- detectors ----
# 每个 detector 在传入的目录上跑，返回 0 = 命中、1 = 没命中

detect_existing_pl() {
  local d="$1" rel="$2"
  if [[ -f "$d/pl/config.yaml" ]]; then
    local change_count=0
    [[ -d "$d/pl/changes" ]] && change_count=$(find "$d/pl/changes" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')
    emit "$rel" "已接入 pl-pipeline" "high" \
      "pl/config.yaml + ${change_count} change(s)" \
      "noop" "已接入，无需重复装；如需新特性: cd $rel && pl init <feature>"
    return 0
  fi
  return 1
}

detect_frontend_nextjs() {
  local d="$1" rel="$2"
  if [[ -f "$d/package.json" ]] && grep -qE '"next"\s*:' "$d/package.json" 2>/dev/null; then
    local ver
    ver=$(grep -oE '"next"\s*:\s*"[^"]+"' "$d/package.json" 2>/dev/null | head -1)
    emit "$rel" "Next.js" "high" \
      "package.json deps: $ver" \
      "install-nextjs" "pl adapter install \$PL_HOME/adapters/adapter-nextjs-web $rel"
    return 0
  fi
  return 1
}

detect_frontend_vue_pnpm() {
  local d="$1" rel="$2"
  local has_pnpm_ws=false has_vue=false
  [[ -f "$d/pnpm-workspace.yaml" ]] && has_pnpm_ws=true
  if find "$d" -maxdepth 4 -name 'package.json' -not -path '*/node_modules/*' 2>/dev/null \
       | xargs grep -l '"vue"' 2>/dev/null | head -1 > /dev/null; then
    has_vue=true
  fi
  if $has_pnpm_ws && $has_vue; then
    local app_count
    app_count=$(find "$d" -maxdepth 3 -name 'package.json' -not -path '*/node_modules/*' 2>/dev/null | wc -l | tr -d ' ')
    emit "$rel" "Vue + pnpm monorepo" "high" \
      "pnpm-workspace.yaml + Vue deps + ${app_count} package.json files" \
      "bare-frontend" "无现成 Vue adapter；建议: cd $rel && pl new whatever --here --stack bare，再写 pl/adapters/build.yaml 注入 pnpm 命令"
    return 0
  fi
  if $has_pnpm_ws; then
    emit "$rel" "pnpm monorepo (栈未识别)" "medium" \
      "pnpm-workspace.yaml 在但未匹配到具体框架" \
      "bare-frontend" "建议: cd $rel && pl new whatever --here --stack bare + 自定义 build.yaml"
    return 0
  fi
  return 1
}

detect_python_fastapi() {
  local d="$1" rel="$2"
  if [[ -f "$d/pyproject.toml" ]] && grep -qE 'fastapi' "$d/pyproject.toml" 2>/dev/null; then
    local has_sqlmodel=false has_alembic=false has_users=false extras=""
    grep -qE 'sqlmodel|sqlalchemy' "$d/pyproject.toml" 2>/dev/null && has_sqlmodel=true
    grep -qE 'alembic' "$d/pyproject.toml" 2>/dev/null && has_alembic=true
    grep -qE 'fastapi-users' "$d/pyproject.toml" 2>/dev/null && has_users=true
    $has_sqlmodel && extras+=" + SQLModel"
    $has_alembic && extras+=" + alembic"
    $has_users && extras+=" + fastapi-users"
    emit "$rel" "FastAPI${extras}" "high" \
      "pyproject.toml deps include fastapi" \
      "install-fastapi" "pl adapter install \$PL_HOME/adapters/adapter-python-fastapi $rel  # adapter 主要覆盖 FastAPI 部分；SQLModel/alembic 通用 rules 适用"
    return 0
  fi
  return 1
}

detect_python_dlt_prefect() {
  local d="$1" rel="$2"
  if [[ -f "$d/pyproject.toml" ]] && grep -qE 'dlt|prefect' "$d/pyproject.toml" 2>/dev/null; then
    local detected=""
    grep -qE '"dlt"|^dlt|dlt[><=]' "$d/pyproject.toml" 2>/dev/null && detected+="dlt"
    grep -qE 'prefect' "$d/pyproject.toml" 2>/dev/null && detected+=" + Prefect"
    emit "$rel" "Python data pipeline (${detected})" "high" \
      "pyproject.toml uses${detected}" \
      "bare-pipeline" "无现成 dlt/Prefect adapter；建议: cd $rel && pl new whatever --here --stack bare + 自定义 build.yaml 注入 'uv run pytest' 等"
    return 0
  fi
  return 1
}

detect_python_scrapy() {
  local d="$1" rel="$2"
  if [[ -f "$d/pyproject.toml" ]] && grep -qE 'scrapy' "$d/pyproject.toml" 2>/dev/null; then
    emit "$rel" "Scrapy" "high" \
      "pyproject.toml uses scrapy" \
      "bare-scrapy" "建议: cd $rel && pl new whatever --here --stack crawler  # crawler stack 包含 scrapy 默认 build.yaml"
    return 0
  fi
  return 1
}

detect_python_generic() {
  local d="$1" rel="$2"
  if [[ -f "$d/pyproject.toml" ]] && [[ ! -f "$d/.pl-detect-claimed" ]]; then
    emit "$rel" "Python (栈未识别)" "low" \
      "只有 pyproject.toml，未匹配到 fastapi/dlt/scrapy 等" \
      "bare-python" "建议: cd $rel && pl new whatever --here --stack bare + 自定义 build.yaml"
    return 0
  fi
  return 1
}

detect_skeleton_frontend() {
  # apps/ + packages/ 但没 package.json：监控/wip 状态
  local d="$1" rel="$2"
  if [[ -d "$d/apps" && -d "$d/packages" ]] && [[ ! -f "$d/package.json" ]]; then
    local apps_n pkgs_n
    apps_n=$(find "$d/apps" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')
    pkgs_n=$(find "$d/packages" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')
    emit "$rel" "前端 monorepo 骨架（未初始化）" "medium" \
      "${apps_n} apps + ${pkgs_n} packages 子目录，但根 package.json 缺失" \
      "wip-frontend" "看起来你打算用 pnpm/turbo monorepo 还没真正 init。建议先 pnpm init + pnpm-workspace.yaml，再 pl detect 重跑"
    return 0
  fi
  return 1
}

detect_skeleton_python() {
  local d="$1" rel="$2"
  if [[ -d "$d/src" && -d "$d/tests" ]] && [[ ! -f "$d/pyproject.toml" ]]; then
    emit "$rel" "Python 骨架（未初始化）" "medium" \
      "src/ + tests/ 子目录，但 pyproject.toml 缺失" \
      "wip-python" "看起来要建 Python 项目但还没 pyproject.toml。建议先 uv init / poetry init，再 pl detect 重跑"
    return 0
  fi
  return 1
}

detect_openapi_contract() {
  local d="$1" rel="$2"
  local cnt
  cnt=$(find "$d" -maxdepth 4 \( -name 'openapi.yaml' -o -name 'openapi.yml' -o -name 'openapi.json' \) 2>/dev/null | wc -l | tr -d ' ')
  if [[ $cnt -gt 0 ]]; then
    local files
    files=$(find "$d" -maxdepth 4 \( -name 'openapi.yaml' -o -name 'openapi.yml' -o -name 'openapi.json' \) 2>/dev/null | head -3 | tr '\n' ' ')
    emit "$rel" "OpenAPI contract source" "high" \
      "$cnt 个 openapi 文件: $files" \
      "cdc-anchor" "💡 v1.7+ CDC 锚点: 让 api/crawler 模块的 adapter.use 事件指向这里，pl contract verify 自动盯漂移"
    return 0
  fi
  return 1
}

detect_mature_docs() {
  local d="$1" rel="$2"
  local cnt
  cnt=$(find "$d" -maxdepth 3 -name '*.md' 2>/dev/null | wc -l | tr -d ' ')
  if [[ $cnt -ge 8 ]]; then
    local samples
    samples=$(find "$d" -maxdepth 3 -name '*.md' 2>/dev/null | head -3 | xargs -I{} basename {} | tr '\n' ',' | sed 's/,$//')
    emit "$rel" "成熟规格文档（${cnt} 份 .md）" "high" \
      "${cnt} 个 markdown 文件，例: $samples" \
      "skip-spec" "💡 你已有完整 SPEC 阶段产物。新建 change 时让 .state.md 直接 link 这些 docs，跳过 SPEC，直接 PLAN/IMPLEMENT"
    return 0
  fi
  return 1
}

detect_infra() {
  local d="$1" rel="$2"
  local found=""
  [[ -f "$d/docker-compose.yml" || -f "$d/docker-compose.yaml" || -f "$d/docker-compose.dev.yml" ]] && found+=" docker-compose"
  [[ -d "$d/k8s" || -d "$d/k3s" || -f "$d/kustomization.yaml" ]] && found+=" k8s"
  [[ -f "$d/Dockerfile" ]] && found+=" Dockerfile"
  if [[ -n "$found" ]]; then
    emit "$rel" "Infra/部署 (${found# })" "medium" \
      "infra 描述存在" \
      "smoke-hint" "💡 pl smoke 可以塞 'docker compose up -d' 类 hooks 进 pl/config.yaml；目前未自动配置"
    return 0
  fi
  return 1
}

# ---- 主扫描循环 ----
scan_dir() {
  local d="$1" rel="$2"
  detect_existing_pl        "$d" "$rel" && return
  detect_frontend_nextjs    "$d" "$rel" && return
  detect_frontend_vue_pnpm  "$d" "$rel" && return
  detect_python_fastapi     "$d" "$rel" && return
  detect_python_scrapy      "$d" "$rel" && return
  detect_python_dlt_prefect "$d" "$rel" && return
  detect_python_generic     "$d" "$rel" && return
  detect_skeleton_frontend  "$d" "$rel" && return
  detect_skeleton_python    "$d" "$rel" && return
  return 0
}

# 扫 root 自身
scan_dir "$ROOT" "."

# 扫一级子目录
while IFS= read -r sub; do
  [[ -z "$sub" ]] && continue
  case "$(basename "$sub")" in
    .git|.github|node_modules|__pycache__|.venv|.uv|.next|dist|build|pipeline-output) continue ;;
  esac
  scan_dir "$sub" "$(basename "$sub")/"
done < <(find "$ROOT" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort)

# 跨目录的"全局型"建议
detect_openapi_contract "$ROOT" "."
detect_mature_docs "$ROOT/docs" "docs/"
detect_infra "$ROOT" "."
detect_infra "$ROOT/infra" "infra/"

# ---- 渲染 ----
if $JSON; then
  # 输出 JSON 数组
  echo "{"
  echo "  \"root\": \"$ROOT\","
  printf "  \"detections\": ["
  local_first=true
  for line in "${DETECTIONS[@]+"${DETECTIONS[@]}"}"; do
    IFS=$'\t' read -r m s c e sid st <<< "$line"
    if $local_first; then echo ""; local_first=false; else echo ","; fi
    # 简单转义
    m_e=$(printf '%s' "$m" | sed 's/"/\\"/g')
    s_e=$(printf '%s' "$s" | sed 's/"/\\"/g')
    e_e=$(printf '%s' "$e" | sed 's/"/\\"/g')
    st_e=$(printf '%s' "$st" | sed 's/"/\\"/g')
    printf '    {"module": "%s", "stack": "%s", "confidence": "%s", "evidence": "%s", "suggestion_id": "%s", "suggestion": "%s"}' \
      "$m_e" "$s_e" "$c" "$e_e" "$sid" "$st_e"
  done
  echo ""
  echo "  ]"
  echo "}"
  exit 0
fi

# 人读输出
if ! $QUIET; then
  echo ""
  echo "${C_BLD}pl detect${C_OFF}  ${C_DIM}$ROOT${C_OFF}"
  echo ""
fi

if [[ ${#DETECTIONS[@]} -eq 0 ]]; then
  echo "  ${C_YEL}(没扫到任何已知技术栈。可能是新建空目录。建议直接 pl new <name> --stack bare)${C_OFF}"
  exit 0
fi

# 按 module 分组
echo "${C_BLD}📁 检测到的模块${C_OFF}"
echo ""
for line in ${DETECTIONS[@]+"${DETECTIONS[@]}"}; do
  IFS=$'\t' read -r m s c e _ _ <<< "$line"
  case "$c" in
    high)   conf_color="${C_GRN}" conf_label="high" ;;
    medium) conf_color="${C_YEL}" conf_label="medium" ;;
    low)    conf_color="${C_DIM}" conf_label="low" ;;
    *)      conf_color="" conf_label="$c" ;;
  esac
  printf "  ${C_CYN}%-15s${C_OFF}  %-40s  %s[%s]%s\n" "$m" "$s" "$conf_color" "$conf_label" "$C_OFF"
  printf "  ${C_DIM}%-15s   ↳ 证据: %s${C_OFF}\n" "" "$e"
done

echo ""
echo "${C_BLD}💡 建议${C_OFF}"
echo ""
SUG_COUNT=0
SUG_IDX=1
for line in ${DETECTIONS[@]+"${DETECTIONS[@]}"}; do
  IFS=$'\t' read -r m _ _ _ sid st <<< "$line"
  [[ "$sid" == "noop" ]] && continue
  printf "  ${C_GRN}[%02d]${C_OFF} ${C_CYN}%s${C_OFF}\n" "$SUG_IDX" "$m"
  printf "       %s\n" "$st"
  echo ""
  SUG_IDX=$((SUG_IDX + 1))
  SUG_COUNT=$((SUG_COUNT + 1))
done

if [[ $SUG_COUNT -eq 0 ]]; then
  echo "  ${C_GRN}✓ 看起来这个项目已经接入 pl-pipeline 且子模块都健康。没有需要主动操作的建议。${C_OFF}"
  echo "  ${C_DIM}如要新建 change: cd <module>/ && pl init <feature-name>${C_OFF}"
  echo ""
fi

echo "${C_DIM}注：本命令完全只读，不会改你的任何文件。${C_OFF}"
echo "${C_DIM}如要执行某条建议，按上方文本手动跑（v1.10.x 暂不支持 --apply）。${C_OFF}"
