#!/usr/bin/env bash
# ============================================================
# _env.sh - pl-pipeline 路径解析 & 环境变量规范
# ============================================================
#
# 本脚本提供 pl-pipeline 所有脚本共享的环境变量解析，让脚本可以：
#   1. 独立于宿主项目存在（脚本可以放在任何位置）
#   2. 对任意项目的 pl/changes/ 生效（通过 PL_PROJECT 指定）
#
# 任何 pl-pipeline 脚本在 shebang 之后的第一行建议：
#
#     source "$(dirname "${BASH_SOURCE[0]}")/_env.sh"
#
# ============================================================
# 导出的变量:
# ------------------------------------------------------------
#   PL_HOME      pl-pipeline 独立项目的根目录（即包含 scripts/、assets/ 的目录）
#                自动探测：取当前脚本所在目录的父目录
#                也可由环境变量显式指定
#
#   PL_PROJECT   宿主项目根目录（需含 pl/changes/ 结构）
#                优先级：环境变量 > 当前工作目录（$PWD）
#
#   PL_ASSETS    pl-pipeline 内置资产目录（$PL_HOME/assets）
#   PL_CHANGES   宿主项目的 changes 目录（$PL_PROJECT/pl/changes）
#   PL_OUTPUT    宿主项目的运行时输出目录（$PL_PROJECT/pipeline-output）
#
#   PL_VERSION   pl-pipeline 版本号（从 $PL_HOME/VERSION 读取）
#
# ============================================================
# 用法示例:
# ------------------------------------------------------------
#
#   # 在宿主项目根目录调用（默认）
#   cd /path/to/host-project
#   /path/to/pl-pipeline/scripts/pl-status.sh
#
#   # 显式指定宿主项目
#   PL_PROJECT=/path/to/host-project bash /path/to/pl-pipeline/scripts/pl-status.sh
#
#   # 或通过 alias / symlink
#   alias pl-status="PL_HOME=/path/to/pl-pipeline bash \$PL_HOME/scripts/pl-status.sh"
#
# ============================================================

set -euo pipefail

# ---- PL_HOME: pl-pipeline 独立项目根 ----
if [[ -z "${PL_HOME:-}" ]]; then
  # 取 _env.sh 所在目录的父目录
  _env_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  PL_HOME="$(cd "$_env_dir/.." && pwd)"
  export PL_HOME
  unset _env_dir
fi

# ---- PL_PROJECT: 宿主项目根 ----
if [[ -z "${PL_PROJECT:-}" ]]; then
  PL_PROJECT="$PWD"
  export PL_PROJECT
fi

# ---- 规范路径 ----
export PL_ASSETS="$PL_HOME/assets"
export PL_CHANGES="$PL_PROJECT/pl/changes"
export PL_OUTPUT="$PL_PROJECT/pipeline-output"

# ---- 版本号 ----
if [[ -z "${PL_VERSION:-}" ]]; then
  if [[ -f "$PL_HOME/VERSION" ]]; then
    PL_VERSION="$(cat "$PL_HOME/VERSION" | tr -d '[:space:]')"
  else
    PL_VERSION="0.1.0-dev"
  fi
  export PL_VERSION
fi

# ---- 基础校验 ----
_pl_env_check() {
  if [[ ! -d "$PL_ASSETS" ]]; then
    echo "ERROR: PL_ASSETS 不存在: $PL_ASSETS" >&2
    echo "请确认 PL_HOME 指向正确的 pl-pipeline 安装目录。当前 PL_HOME=$PL_HOME" >&2
    return 1
  fi
  return 0
}

# 调用方可以在需要时 _pl_env_check，不强制自动执行（某些脚本如 --help 不需要 PL_ASSETS）

# ---- 调试辅助 ----
pl_env_dump() {
  cat <<EOF
[pl-pipeline env]
  PL_HOME     = $PL_HOME
  PL_PROJECT  = $PL_PROJECT
  PL_ASSETS   = $PL_ASSETS
  PL_CHANGES  = $PL_CHANGES
  PL_OUTPUT   = $PL_OUTPUT
  PL_VERSION  = $PL_VERSION
EOF
}

# 供其他脚本使用的工具函数

# 解析宿主项目中的 change 目录绝对路径
# 用法: change_dir="$(pl_resolve_change_dir my-change)"
pl_resolve_change_dir() {
  local change_id="$1"
  echo "$PL_CHANGES/$change_id"
}

# 检查宿主项目是否已初始化 pl/ 结构
pl_is_initialized() {
  [[ -d "$PL_CHANGES" ]] && [[ -f "$PL_PROJECT/pl/config.yaml" ]]
}
