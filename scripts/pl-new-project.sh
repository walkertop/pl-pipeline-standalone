#!/usr/bin/env bash
# =============================================================================
# pl-new-project.sh — 一键创建并初始化新的 pl-pipeline 项目
# =============================================================================
#
# 取代之前需要 8 步的手动接入流程：
#   mkdir -p pl/changes
#   cp ${PL_HOME}/assets/pl/config.default.yaml pl/config.yaml
#   export PL_PROJECT="$PWD"
#   pl adapter install ...
#   git init
#   pl init <change-id>
#   ...
#
# 现在变成 1 条:
#   pl new my-project --stack nextjs
#
# 用法:
#   pl new <name> [--stack <stack>] [--here] [--no-git] [--no-init] [--first-change <id>]
#
# 选项:
#   <name>                  项目目录名（也作为 git repo 名）。--here 时为目录显示名
#   --stack <stack>         技术栈骨架，可选值:
#                             nextjs           — 单 Next.js + adapter-nextjs-web
#                             fastapi          — 单 FastAPI + adapter-python-fastapi
#                             crawler          — 单爬虫，无 adapter，自定义 build.yaml
#                             monorepo-trio    — 前端+服务端+爬虫（cp demo-monorepo-trio）
#                             bare             — 任意栈，仅装 pl-core 骨架（无 adapter）
#                           默认: bare
#   --here                  在当前目录就地初始化（不新建子目录）
#   --no-git                跳过 git init
#   --no-init               跳过创建首个 change
#   --first-change <id>     首个 change 名（默认 add-first-feature）
#   --force                 目标目录已存在时强制覆盖
#   -h, --help              显示帮助
#
# 退出码: 0 成功 / 1 失败 / 2 参数错
# =============================================================================

# shellcheck source=./_env.sh
source "$(dirname "${BASH_SOURCE[0]}")/_env.sh"
set -euo pipefail

# ---- 颜色 ----
if [[ -t 1 ]]; then
  C_RED=$'\033[0;31m'; C_GRN=$'\033[0;32m'; C_YEL=$'\033[0;33m'
  C_BLU=$'\033[0;34m'; C_BLD=$'\033[1m'; C_DIM=$'\033[2m'; C_OFF=$'\033[0m'
else
  C_RED=; C_GRN=; C_YEL=; C_BLU=; C_BLD=; C_DIM=; C_OFF=
fi
log()  { echo "${C_BLU}ℹ${C_OFF} $*"; }
ok()   { echo "${C_GRN}✓${C_OFF} $*"; }
warn() { echo "${C_YEL}⚠${C_OFF} $*" >&2; }
die()  { echo "${C_RED}✗${C_OFF} $*" >&2; exit 1; }

usage() {
  sed -n '2,40p' "$0" | sed 's/^# \{0,1\}//'
  exit "${1:-2}"
}

# ---- 参数解析 ----
NAME=""
STACK="bare"
HERE=false
NO_GIT=false
NO_INIT=false
FIRST_CHANGE="add-first-feature"
FORCE=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)        usage 0 ;;
    --stack)          STACK="$2"; shift 2 ;;
    --stack=*)        STACK="${1#*=}"; shift ;;
    --here)           HERE=true; shift ;;
    --no-git)         NO_GIT=true; shift ;;
    --no-init)        NO_INIT=true; shift ;;
    --first-change)   FIRST_CHANGE="$2"; shift 2 ;;
    --force)          FORCE=true; shift ;;
    --*)              die "未知参数: $1（用 --help 看用法）" ;;
    *)
      [[ -n "${NAME}" ]] && die "已经指定了名字 '${NAME}'，多余参数: $1"
      NAME="$1"; shift ;;
  esac
done

[[ -z "${NAME}" ]] && { warn "缺少项目名"; usage 2; }

# 校验 stack
case "${STACK}" in
  nextjs|fastapi|crawler|monorepo-trio|bare) ;;
  *) die "未知 stack: ${STACK}（可选: nextjs|fastapi|crawler|monorepo-trio|bare）" ;;
esac

# ---- 解析目标路径 ----
if $HERE; then
  TARGET="$PWD"
  log "在当前目录就地初始化: ${TARGET}（显示名: ${NAME}）"
  # --here 模式安全提示：非 bare 会从 demo 拷代码，已有项目可能不需要
  if [[ "${STACK}" != "bare" ]]; then
    warn "--here + --stack ${STACK}: 会拷示例代码到当前目录（已有同名文件会保留不动）"
    warn "如果你只想给已有项目装 pl-pipeline 接入层，推荐: pl new <any-name> --here --stack bare"
  fi
  # --here 默认不要 git init（已有项目通常已有 git）
  if [[ -d "${TARGET}/.git" ]]; then
    NO_GIT=true
  fi
else
  # 支持绝对路径和相对路径
  case "${NAME}" in
    /*) TARGET="${NAME}" ;;
    *)  TARGET="$PWD/${NAME}" ;;
  esac
  # 取目录名作为"项目显示名"，便于后续 README/打印好看
  DISPLAY_NAME="$(basename "${NAME}")"
  if [[ -e "${TARGET}" ]]; then
    if $FORCE; then
      warn "${TARGET} 已存在，--force 模式删除后重建"
      rm -rf "${TARGET}"
    else
      die "${TARGET} 已存在。指定 --force 覆盖，或换个名字"
    fi
  fi
  mkdir -p "${TARGET}"
  # 用 display name 替代后续展示
  NAME="${DISPLAY_NAME}"
fi

[[ -n "${PL_HOME:-}" && -d "${PL_HOME}/assets" ]] || die "PL_HOME 未设置或无效（尝试 source 你的 shell rc）"

log "项目名: ${C_BLD}${NAME}${C_OFF}"
log "技术栈: ${C_BLD}${STACK}${C_OFF}"
log "目标:   ${TARGET}"

# ---- 准备骨架 ----
# 在已有项目上跑 --here 时，必须保护用户已有文件不被覆盖。
# 把 pl-pipeline 关心的 ignore 规则 append 到已有 .gitignore（去重）；
# 没有则创建一份。
ensure_gitignore() {
  local gi="${TARGET}/.gitignore"
  local lines=("pipeline-output/" "node_modules/" ".next/" "__pycache__/" "*.pyc" ".venv/" ".uv/" ".DS_Store")
  if [[ ! -f "$gi" ]]; then
    printf '%s\n' "${lines[@]}" > "$gi"
    return
  fi
  # 已有 .gitignore：仅 append 缺失的行（保护用户已有规则）
  local appended=0
  local marker="# >>> pl-pipeline >>>"
  if ! grep -qF "$marker" "$gi"; then
    {
      echo ""
      echo "$marker"
      for l in "${lines[@]}"; do
        if ! grep -qxF "$l" "$gi"; then
          echo "$l"
          appended=1
        fi
      done
      echo "# <<< pl-pipeline <<<"
    } >> "$gi"
    if [[ $appended -eq 1 ]]; then
      log "已 append pl-pipeline 规则到现有 .gitignore（保留你的规则）"
    fi
  fi
}

prepare_bare() {
  mkdir -p "${TARGET}/pl/changes"
  if [[ -f "${TARGET}/pl/config.yaml" ]]; then
    log "${TARGET}/pl/config.yaml 已存在，保留不覆盖"
  else
    cp "${PL_HOME}/assets/pl/config.default.yaml" "${TARGET}/pl/config.yaml"
  fi
  ensure_gitignore
}

# tar xf 用 -k (keep-old-files) 保护已有同名文件不被覆盖
prepare_from_example() {
  local src="$1"
  local example_dir="${PL_HOME}/examples/$src"
  [[ -d "$example_dir" ]] || die "找不到示例: $example_dir（pl-pipeline 安装可能损坏）"
  log "从示例复制骨架: examples/$src/（已存在的同名文件会被保留不覆盖）"
  ( cd "$example_dir" && tar cf - --exclude='pipeline-output' --exclude='.git' . ) \
    | ( cd "${TARGET}" && tar xf - --keep-old-files 2>/dev/null || tar xkf - 2>/dev/null || true )
  # 清理 demo change（用户会起自己的）
  find "${TARGET}" -type d -name 'add-demo-feature' -exec rm -rf {} + 2>/dev/null || true
}

# 安全文件复制：仅当目标不存在时才 cp
safe_cp() {
  local s="$1" d="$2"
  if [[ -e "$d" ]]; then
    log "$(basename "$d") 已存在，保留不覆盖"
  else
    cp -R "$s" "$d"
  fi
}

case "${STACK}" in
  bare)
    log "创建 bare 骨架（仅 pl/config.yaml + .gitignore）"
    prepare_bare
    ;;
  nextjs)
    log "复制 nextjs 骨架（基于 demo-monorepo-trio/frontend）"
    prepare_bare
    src="${PL_HOME}/examples/demo-monorepo-trio/frontend"
    [[ -d "$src" ]] || die "找不到 nextjs 模板: $src"
    safe_cp "$src/app" "${TARGET}/app"
    safe_cp "$src/package.json" "${TARGET}/package.json"
    safe_cp "$src/.pl-adapter.yaml" "${TARGET}/.pl-adapter.yaml"
    ;;
  fastapi)
    log "复制 fastapi 骨架（基于 demo-monorepo-trio/api）"
    prepare_bare
    src="${PL_HOME}/examples/demo-monorepo-trio/api"
    [[ -d "$src" ]] || die "找不到 fastapi 模板: $src"
    safe_cp "$src/app" "${TARGET}/app"
    safe_cp "$src/pyproject.toml" "${TARGET}/pyproject.toml"
    safe_cp "$src/.pl-adapter.yaml" "${TARGET}/.pl-adapter.yaml"
    ;;
  crawler)
    log "复制 crawler 骨架（基于 demo-monorepo-trio/crawler，无 adapter）"
    prepare_bare
    src="${PL_HOME}/examples/demo-monorepo-trio/crawler"
    [[ -d "$src" ]] || die "找不到 crawler 模板: $src"
    safe_cp "$src/spiders" "${TARGET}/spiders"
    safe_cp "$src/tests" "${TARGET}/tests"
    safe_cp "$src/pyproject.toml" "${TARGET}/pyproject.toml"
    mkdir -p "${TARGET}/pl/adapters"
    safe_cp "$src/pl/adapters/build.yaml" "${TARGET}/pl/adapters/build.yaml"
    ;;
  monorepo-trio)
    prepare_from_example "demo-monorepo-trio"
    # demo 自己有 .gitignore，不需要再写
    ;;
esac

# ---- README ----
if [[ ! -f "${TARGET}/README.md" ]]; then
  cat > "${TARGET}/README.md" <<EOF
# ${NAME}

Bootstrapped with [\`pl new\`](https://github.com/walkertop/pl-pipeline-standalone) (stack: \`${STACK}\`).

## 快速开始

\`\`\`bash
export PL_PROJECT="\$PWD"      # 或用 direnv 自动管
pl status                       # 看所有 change
pl init my-feature --name "我的特性"
\`\`\`

参考: \`pl help\` / [pl-pipeline 官方文档](https://github.com/walkertop/pl-pipeline-standalone)。
EOF
fi

# ---- 装 adapter（仅当 stack 提供完整 .pl-adapter.yaml 占位时执行真实安装）----
ADAPTER_TO_INSTALL=""
case "${STACK}" in
  nextjs)         ADAPTER_TO_INSTALL="${PL_HOME}/adapters/adapter-nextjs-web" ;;
  fastapi)        ADAPTER_TO_INSTALL="${PL_HOME}/adapters/adapter-python-fastapi" ;;
esac

if [[ -n "${ADAPTER_TO_INSTALL}" && -d "${ADAPTER_TO_INSTALL}" ]]; then
  log "安装 adapter: $(basename "${ADAPTER_TO_INSTALL}")"
  # 删 placeholder（adapter-install 不会强行覆盖）
  rm -f "${TARGET}/.pl-adapter.yaml"
  if PL_PROJECT="${TARGET}" "${PL_HOME}/scripts/adapter-install.sh" "${ADAPTER_TO_INSTALL}" "${TARGET}" >/dev/null 2>&1; then
    ok "adapter 安装成功"
  else
    warn "adapter 安装失败（不影响 pl-core 使用，可稍后手动 \`pl adapter install\`）"
  fi
fi

# monorepo-trio：每个子模块装各自 adapter
if [[ "${STACK}" == "monorepo-trio" ]]; then
  log "为 monorepo 各子模块装 adapter..."
  for sub in frontend api; do
    [[ -d "${TARGET}/$sub" ]] || continue
    rm -f "${TARGET}/$sub/.pl-adapter.yaml"
    case "$sub" in
      frontend) ADP="${PL_HOME}/adapters/adapter-nextjs-web" ;;
      api)      ADP="${PL_HOME}/adapters/adapter-python-fastapi" ;;
    esac
    if PL_PROJECT="${TARGET}/$sub" "${PL_HOME}/scripts/adapter-install.sh" "${ADP}" "${TARGET}/$sub" >/dev/null 2>&1; then
      ok "  $sub 装上 $(basename "${ADP}")"
    else
      warn "  $sub adapter 安装失败（可稍后手动重装）"
    fi
  done
fi

# ---- git init ----
if ! $NO_GIT; then
  if [[ ! -d "${TARGET}/.git" ]]; then
    log "git init"
    ( cd "${TARGET}" && git init -q -b main 2>/dev/null || git init -q )
    ok "git 仓库已初始化"
  fi
fi

# ---- 起首个 change ----
if ! $NO_INIT; then
  if [[ "${STACK}" == "monorepo-trio" ]]; then
    log "在 monorepo 各子模块起首个 change: ${FIRST_CHANGE}"
    for sub in frontend api crawler; do
      [[ -d "${TARGET}/$sub/pl/changes" ]] || continue
      if ( cd "${TARGET}/$sub" && PL_PROJECT="$PWD" "${PL_HOME}/scripts/pl-state-init.sh" \
             "${FIRST_CHANGE}" --name "首个特性 ($sub)" --domain new ) >/dev/null 2>&1; then
        ok "  $sub: change '${FIRST_CHANGE}' 已就位"
      else
        warn "  $sub: pl init 失败"
      fi
    done
  else
    log "起首个 change: ${FIRST_CHANGE}"
    if ( cd "${TARGET}" && PL_PROJECT="$PWD" "${PL_HOME}/scripts/pl-state-init.sh" \
           "${FIRST_CHANGE}" --name "首个特性" --domain new ) >/dev/null 2>&1; then
      ok "change '${FIRST_CHANGE}' 已就位"
    else
      warn "pl init 失败（可手动 cd ${TARGET} 再 pl init ${FIRST_CHANGE}）"
    fi
  fi
fi

# ---- 完工 ----
echo ""
echo "${C_GRN}${C_BLD}╭───────────────────────────────────────────────────────────╮${C_OFF}"
echo "${C_GRN}${C_BLD}│  项目 '${NAME}' 已就绪                                        │${C_OFF}"
echo "${C_GRN}${C_BLD}╰───────────────────────────────────────────────────────────╯${C_OFF}"
echo ""
echo "${C_BLD}下一步：${C_OFF}"
echo ""
if ! $HERE; then
  echo "  ${C_DIM}cd ${NAME}${C_OFF}"
fi
case "${STACK}" in
  monorepo-trio)
    echo "  ${C_DIM}cd frontend && export PL_PROJECT=\"\$PWD\" && pl status${C_OFF}"
    echo "  ${C_DIM}# (推荐) 用 direnv 自动管 PL_PROJECT，详见 monorepo-quickstart.md${C_OFF}"
    ;;
  *)
    echo "  ${C_DIM}export PL_PROJECT=\"\$PWD\"${C_OFF}"
    echo "  ${C_DIM}pl status${C_OFF}"
    if ! $NO_INIT; then
      echo "  ${C_DIM}\$EDITOR pl/changes/${FIRST_CHANGE}/.state.md${C_OFF}    # 写 spec/plan/...${C_OFF}"
    fi
    ;;
esac
echo ""
echo "  ${C_DIM}pl help${C_OFF}                                # 全部子命令"
echo ""
