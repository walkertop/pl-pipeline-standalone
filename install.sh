#!/usr/bin/env bash
# =============================================================================
# pl-pipeline 一键安装脚本
# =============================================================================
#
# 用法（任选其一）:
#
#   # 1) curl 一行 (默认装到 ~/.pl-pipeline，自动写 shell rc)
#   curl -fsSL https://raw.githubusercontent.com/walkertop/pl-pipeline-standalone/main/install.sh | bash
#
#   # 2) wget 一行 (同上)
#   wget -qO- https://raw.githubusercontent.com/walkertop/pl-pipeline-standalone/main/install.sh | bash
#
#   # 3) 已经 git clone 好了，本地跑
#   git clone https://github.com/walkertop/pl-pipeline-standalone ~/.pl-pipeline
#   bash ~/.pl-pipeline/install.sh
#
# 选项 (通过环境变量传):
#
#   PL_INSTALL_PREFIX=/custom/path   安装位置 (默认: ~/.pl-pipeline)
#   PL_INSTALL_REF=pl-v1.9.0         拉取的 git ref (默认: 最新 stable tag)
#   PL_INSTALL_NO_RC=1               不写 shell rc，仅安装本体
#   PL_INSTALL_FORCE=1               目标目录已存在时强制覆盖
#   PL_INSTALL_QUIET=1               精简输出
#
# 退出码: 0 成功 / 1 失败 / 2 用户拒绝
# =============================================================================

set -euo pipefail

# ---- 颜色 ----
if [[ -t 1 ]] && [[ -z "${PL_INSTALL_QUIET:-}" ]]; then
  C_RED=$'\033[0;31m'; C_GRN=$'\033[0;32m'; C_YEL=$'\033[0;33m'
  C_BLU=$'\033[0;34m'; C_BLD=$'\033[1m'; C_DIM=$'\033[2m'; C_OFF=$'\033[0m'
else
  C_RED=; C_GRN=; C_YEL=; C_BLU=; C_BLD=; C_DIM=; C_OFF=
fi

log()  { [[ -z "${PL_INSTALL_QUIET:-}" ]] && echo "${C_BLU}ℹ${C_OFF} $*" || true; }
ok()   { echo "${C_GRN}✓${C_OFF} $*"; }
warn() { echo "${C_YEL}⚠${C_OFF} $*" >&2; }
die()  { echo "${C_RED}✗${C_OFF} $*" >&2; exit 1; }

# ---- 0. 横幅 ----
if [[ -z "${PL_INSTALL_QUIET:-}" ]]; then
  cat <<EOF
${C_BLD}pl-pipeline installer${C_OFF}
${C_DIM}AI-First R&D 操作系统 — bash + python3 stdlib，零 npm/pip 依赖${C_OFF}

EOF
fi

# ---- 1. 必备依赖检测 ----
log "检测依赖..."
need_cmd() { command -v "$1" >/dev/null 2>&1 || die "缺少必需工具: $1（${2:-}）"; }
need_cmd bash    "macOS bash 3.2 / Linux bash 4+ 都行"
need_cmd python3 "推荐 3.11+; brew install python@3.12 或 apt install python3"
need_cmd git     "用于 clone 仓库; brew install git 或 apt install git"

# 可选但推荐
HAVE_JQ=true
command -v jq >/dev/null 2>&1 || { HAVE_JQ=false; warn "jq 未安装，部分子命令需要（brew install jq）"; }

ok "依赖检测通过"

# ---- 2. 决定安装路径与 ref ----
PREFIX="${PL_INSTALL_PREFIX:-$HOME/.pl-pipeline}"
REF="${PL_INSTALL_REF:-}"
REPO_URL="https://github.com/walkertop/pl-pipeline-standalone.git"

# 如果 install.sh 是从仓库内执行的（路径下能找到 bin/pl），直接 link 而不 clone
# 注意：curl|bash 场景下 BASH_SOURCE[0] 不存在（脚本来自 stdin），必须做 unbound 防护
LOCAL_MODE=false
if [[ "${BASH_SOURCE[0]:-}" != "" ]]; then
  SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  if [[ -f "$SELF_DIR/bin/pl" && -d "$SELF_DIR/scripts" && -d "$SELF_DIR/assets" ]]; then
    LOCAL_MODE=true
  fi
else
  SELF_DIR=""
fi

if $LOCAL_MODE && [[ "$SELF_DIR" != "$PREFIX" ]]; then
  log "检测到本地 pl-pipeline 仓库 ($SELF_DIR)，使用本地副本而非重新 clone"
  PREFIX="$SELF_DIR"
fi

# ---- 3. 安装本体 ----
if $LOCAL_MODE; then
  ok "使用本地仓库: $PREFIX"
else
  log "安装位置: $PREFIX"
  log "拉取 ref:  ${REF:-默认 main}"

  if [[ -d "$PREFIX" ]]; then
    if [[ -n "${PL_INSTALL_FORCE:-}" ]]; then
      warn "目标目录已存在，--force 模式删除后重装: $PREFIX"
      rm -rf "$PREFIX"
    elif [[ -d "$PREFIX/.git" && -f "$PREFIX/bin/pl" ]]; then
      log "目标已是 pl-pipeline 仓库，尝试 git pull 升级..."
      ( cd "$PREFIX" && git fetch --tags --quiet && \
        if [[ -n "$REF" ]]; then git checkout "$REF" --quiet; else git pull --ff-only --quiet || true; fi )
      ok "已升级到 $(cd "$PREFIX" && git describe --tags --always 2>/dev/null || echo 'unknown')"
    else
      die "目标目录已存在且非 pl-pipeline 仓库。设 PL_INSTALL_FORCE=1 强制覆盖，或指定 PL_INSTALL_PREFIX=/其他路径"
    fi
  else
    log "git clone $REPO_URL → $PREFIX"
    if [[ -n "$REF" ]]; then
      git clone --depth 1 --branch "$REF" --quiet "$REPO_URL" "$PREFIX"
    else
      git clone --depth 1 --quiet "$REPO_URL" "$PREFIX"
      # 切到最新 stable tag (pl-v* 形式)
      LATEST=$(cd "$PREFIX" && git ls-remote --tags --sort=-v:refname origin 'pl-v*' 2>/dev/null | head -1 | awk -F'/' '{print $NF}' | sed 's/\^{}$//')
      if [[ -n "$LATEST" ]]; then
        ( cd "$PREFIX" && git fetch --depth 1 origin "refs/tags/$LATEST:refs/tags/$LATEST" --quiet && git checkout "$LATEST" --quiet )
        ok "切到最新 stable tag: $LATEST"
      fi
    fi
  fi
fi

[[ -x "$PREFIX/bin/pl" ]] || chmod +x "$PREFIX/bin/pl" 2>/dev/null || die "$PREFIX/bin/pl 不可执行"

INSTALLED_VERSION="unknown"
[[ -f "$PREFIX/VERSION" ]] && INSTALLED_VERSION=$(tr -d '[:space:]' < "$PREFIX/VERSION")

ok "pl-pipeline v$INSTALLED_VERSION 已就绪: $PREFIX"

# ---- 4. 写 shell rc（除非显式拒绝）----
write_rc() {
  local rc_file="$1"
  local marker="# >>> pl-pipeline >>>"
  local end_marker="# <<< pl-pipeline <<<"

  if [[ -f "$rc_file" ]] && grep -qF "$marker" "$rc_file"; then
    log "$rc_file 已含 pl-pipeline 配置（跳过；如需更新请手动编辑）"
    return 0
  fi

  log "向 $rc_file 追加 PL_HOME 与 PATH"
  {
    echo ""
    echo "$marker"
    echo "export PL_HOME=\"$PREFIX\""
    echo "export PATH=\"\$PL_HOME/bin:\$PATH\""
    echo "$end_marker"
  } >> "$rc_file"
  ok "已写入 $rc_file"
}

if [[ -z "${PL_INSTALL_NO_RC:-}" ]]; then
  log "更新 shell rc..."
  USER_SHELL="$(basename "${SHELL:-bash}")"
  case "$USER_SHELL" in
    zsh)  RC_FILE="${ZDOTDIR:-$HOME}/.zshrc" ;;
    bash) [[ "$(uname)" == "Darwin" ]] && RC_FILE="$HOME/.bash_profile" || RC_FILE="$HOME/.bashrc" ;;
    fish) RC_FILE="$HOME/.config/fish/config.fish" ;;
    *)    RC_FILE="$HOME/.profile" ;;
  esac

  if [[ "$USER_SHELL" == "fish" ]]; then
    mkdir -p "$(dirname "$RC_FILE")"
    if ! grep -qF "# pl-pipeline" "$RC_FILE" 2>/dev/null; then
      {
        echo ""
        echo "# pl-pipeline"
        echo "set -gx PL_HOME \"$PREFIX\""
        echo "set -gx PATH \$PL_HOME/bin \$PATH"
      } >> "$RC_FILE"
      ok "已写入 $RC_FILE"
    fi
  else
    write_rc "$RC_FILE"
  fi
else
  log "PL_INSTALL_NO_RC=1：跳过 shell rc 写入。请自行 export："
  echo "    export PL_HOME=\"$PREFIX\""
  echo "    export PATH=\"\$PL_HOME/bin:\$PATH\""
fi

# ---- 5. 完工提示 ----
echo ""
echo "${C_GRN}${C_BLD}╭───────────────────────────────────────────────────────────╮${C_OFF}"
echo "${C_GRN}${C_BLD}│  pl-pipeline 安装完成 (v$INSTALLED_VERSION)                          │${C_OFF}"
echo "${C_GRN}${C_BLD}╰───────────────────────────────────────────────────────────╯${C_OFF}"
echo ""
echo "${C_BLD}下一步：${C_OFF}"
echo ""
if [[ -n "${RC_FILE:-}" ]]; then
  echo "  1) 重启 shell（或手动 source）:"
  echo "     ${C_DIM}source $RC_FILE${C_OFF}"
else
  echo "  1) 设置环境变量（已跳过 shell rc 写入）:"
  echo "     ${C_DIM}export PL_HOME=\"$PREFIX\"${C_OFF}"
  echo "     ${C_DIM}export PATH=\"\$PL_HOME/bin:\$PATH\"${C_OFF}"
fi
echo ""
echo "  2) 验证安装:"
echo "     ${C_DIM}pl --version${C_OFF}"
echo "     ${C_DIM}pl doctor${C_OFF}"
echo ""
echo "  3) 创建你的第一个项目:"
echo "     ${C_DIM}pl new my-project --stack nextjs${C_OFF}              # 单 Next.js"
echo "     ${C_DIM}pl new my-api     --stack fastapi${C_OFF}             # 单 FastAPI"
echo "     ${C_DIM}pl new my-saas    --stack monorepo-trio${C_OFF}       # 前端+服务端+爬虫"
echo "     ${C_DIM}pl new my-tool    --stack bare${C_OFF}                # 任意栈，无 adapter"
echo ""
echo "  4) 更多用法: ${C_DIM}pl help${C_OFF}"
echo ""
