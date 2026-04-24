#!/usr/bin/env bash
# =============================================================================
# pl-ide.sh — 把 pl/ 下的 canonical 资产同步到各 AI IDE 约定目录
# =============================================================================
#
# 用法:
#   pl ide detect                          扫描项目目录, 列出已检测到的 IDE
#   pl ide list                            列出 pl 已写入的所有受管文件
#   pl ide sync [--ide <id>] [--all] [--dry-run] [--force]
#                                          将 pl/{rules,agents,...} fan-out 到 IDE 目录
#                                          --ide 不指定时, 默认 detect 出的 IDE 全部 sync
#                                          --all 强制对所有支持的 IDE sync（即便未检测到）
#   pl ide unsync [--ide <id>] [--all] [--dry-run] [--force]
#                                          撤回 pl 写过的文件
#   pl ide help                            本帮助
#
# 设计:
#   - 单源（pl/{rules,agents,skills,commands}）, 多目标（.cursor/, .codebuddy/）
#   - 每个 IDE 由 ide-integrations/<id>/manifest.yaml 描述差异
#   - 写入文件首行/frontmatter 后插入 hash 标记, unsync 时校验, 保护用户改动
#   - root AGENTS.md 由 pl 维护一段托管区, 用于 reference-only 的 agents/skills
#
# 退出码:
#   0   成功
#   1   失败（PyYAML 缺失 / detect 异常）
#   2   参数错误
# =============================================================================
# shellcheck source=./_env.sh
source "$(dirname "${BASH_SOURCE[0]}")/_env.sh"
set -uo pipefail

LIB_PY="$PL_HOME/scripts/_lib/pl_ide_sync.py"

if [[ ! -f "$LIB_PY" ]]; then
  echo "ERROR: 缺少 $LIB_PY" >&2
  exit 1
fi

if [[ -t 1 ]]; then
  C_BLD=$'\033[1m'; C_DIM=$'\033[2m'; C_OFF=$'\033[0m'
  C_GRN=$'\033[0;32m'; C_YEL=$'\033[0;33m'; C_RED=$'\033[0;31m'
else
  C_BLD=; C_DIM=; C_OFF=; C_GRN=; C_YEL=; C_RED=
fi

_usage() {
  cat <<EOF
${C_BLD}pl ide${C_OFF} — 把 pl/ 资产同步到不同 AI IDE

用法:
  pl ide detect                                  扫描项目, 列出检测到的 IDE
  pl ide list                                    列出 pl 写过的受管文件
  pl ide sync   [--ide <id>] [--all] [选项]      同步 pl/ → IDE
  pl ide unsync [--ide <id>] [--all] [选项]      撤回同步

选项:
  --dry-run    只打印不写
  --force      覆盖被手工修改过的文件 / 删除非 pl 标记文件
  --ide <id>   只对指定 IDE 操作（cursor / codebuddy）
  --all        对所有支持的 IDE 操作（即便未检测到）

支持的 IDE:
$(_ls_supported)

文件标记:
  pl 写入的每个文件都带一行注释:
    <!-- pl-managed: hash=<12位> source=<相对路径> ide=<id> -->
  hash 校验后续 sync/unsync 是否会覆盖你的手改。
EOF
}

_ls_supported() {
  for d in "$PL_HOME"/ide-integrations/*/; do
    [[ -f "$d/manifest.yaml" ]] || continue
    local id
    id="$(basename "$d")"
    echo "  - $id"
  done
}

_detect() {
  python3 "$LIB_PY" detect --pl-home "$PL_HOME" --pl-project "$PL_PROJECT"
}

_pyrun() {
  # 带颜色透传
  python3 "$LIB_PY" "$@"
}

# 简单 arg 解析
_parse_common_args() {
  IDE=""
  ALL=0
  DRY_RUN=0
  FORCE=0
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --ide) IDE="${2:-}"; shift 2;;
      --all) ALL=1; shift;;
      --dry-run) DRY_RUN=1; shift;;
      --force) FORCE=1; shift;;
      -h|--help) _usage; exit 0;;
      *) echo "未知参数: $1" >&2; exit 2;;
    esac
  done
}

_resolve_targets() {
  # 输出待操作的 IDE 列表（每行一个）
  if [[ -n "$IDE" ]]; then
    echo "$IDE"
    return
  fi
  if [[ "$ALL" -eq 1 ]]; then
    for d in "$PL_HOME"/ide-integrations/*/; do
      [[ -f "$d/manifest.yaml" ]] || continue
      basename "$d"
    done
    return
  fi
  _detect
}

cmd="${1:-help}"
shift || true

case "$cmd" in
  help|-h|--help)
    _usage
    ;;
  detect)
    detected="$(_detect)"
    if [[ -z "$detected" ]]; then
      echo "${C_YEL}未检测到任何已知 IDE。${C_OFF}"
      echo "支持的 IDE:"
      _ls_supported
      exit 0
    fi
    echo "${C_GRN}检测到以下 IDE:${C_OFF}"
    echo "$detected" | sed 's/^/  - /'
    ;;
  list)
    _pyrun list --pl-home "$PL_HOME" --pl-project "$PL_PROJECT"
    ;;
  sync)
    _parse_common_args "$@"
    targets="$(_resolve_targets)"
    if [[ -z "$targets" ]]; then
      echo "${C_YEL}未检测到 IDE; 用 --ide <id> 指定或 --all 强制全部同步${C_OFF}" >&2
      exit 0
    fi
    args=()
    [[ "$DRY_RUN" -eq 1 ]] && args+=(--dry-run)
    [[ "$FORCE" -eq 1 ]] && args+=(--force)
    overall_rc=0
    while IFS= read -r ide; do
      [[ -z "$ide" ]] && continue
      _pyrun sync --pl-home "$PL_HOME" --pl-project "$PL_PROJECT" --ide "$ide" ${args[@]+"${args[@]}"} \
        || overall_rc=$?
    done <<< "$targets"
    exit "$overall_rc"
    ;;
  unsync)
    _parse_common_args "$@"
    targets="$(_resolve_targets)"
    if [[ -z "$targets" ]]; then
      echo "${C_YEL}未检测到 IDE; 用 --ide <id> 指定或 --all${C_OFF}" >&2
      exit 0
    fi
    args=()
    [[ "$DRY_RUN" -eq 1 ]] && args+=(--dry-run)
    [[ "$FORCE" -eq 1 ]] && args+=(--force)
    overall_rc=0
    while IFS= read -r ide; do
      [[ -z "$ide" ]] && continue
      _pyrun unsync --pl-home "$PL_HOME" --pl-project "$PL_PROJECT" --ide "$ide" ${args[@]+"${args[@]}"} \
        || overall_rc=$?
    done <<< "$targets"
    exit "$overall_rc"
    ;;
  *)
    echo "未知 ide 子命令: $cmd" >&2
    _usage
    exit 2
    ;;
esac
