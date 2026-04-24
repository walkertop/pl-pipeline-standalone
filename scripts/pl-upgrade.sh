#!/usr/bin/env bash
# =============================================================================
# pl-upgrade.sh — 把 PL_HOME 切到最新 stable tag（或指定 ref）
# =============================================================================
#
# 用法:
#   pl upgrade                    升级到最新 stable tag (pl-vX.Y.Z, 过滤 pre-release)
#   pl upgrade --check            只检查不升级
#                                   exit 0  = 已是最新 stable
#                                   exit 10 = 有新版本可升级
#                                   exit 1  = 检查失败（网络 / 非 git）
#   pl upgrade --ref pl-v1.10.0   升级到指定 tag / branch / commit
#   pl upgrade --no-fetch         跳过 git fetch（用本地已有 ref，离线场景）
#
# 行为:
#   - 仅当 PL_HOME 是 git 仓库时可用（vendor / submodule 模式请走宿主仓 PR 升级）
#   - 拒绝在 PL_HOME 有未提交修改时切换（避免吞掉本地改动）
#   - 默认 fetch + checkout；--check 模式纯只读
#
# 退出码:
#   0   成功（已升级 / 已是最新）
#   1   失败（网络 / 非 git / 有未提交修改 / 目标 ref 不存在）
#   2   参数错误
#   10  --check 模式下：有新版本可升级
#
# =============================================================================

# shellcheck source=./_env.sh
source "$(dirname "${BASH_SOURCE[0]}")/_env.sh"
# 允许 git 命令失败被 case 处理，不要 set -e 把整个脚本挂掉
set +e
set -u
set -o pipefail

# ---- 颜色 ----
if [[ -t 1 ]]; then
  C_RED=$'\033[0;31m'; C_GRN=$'\033[0;32m'; C_YEL=$'\033[0;33m'
  C_BLU=$'\033[0;34m'; C_BLD=$'\033[1m'; C_DIM=$'\033[2m'; C_OFF=$'\033[0m'
else
  C_RED=; C_GRN=; C_YEL=; C_BLU=; C_BLD=; C_DIM=; C_OFF=
fi

usage() {
  cat <<EOF
用法: pl upgrade [--check] [--ref <ref>] [--no-fetch]

把 PL_HOME (${PL_HOME}) 切到最新 stable tag（或指定 ref）。

选项:
  --check          只检查，不实际升级
                     exit 0  = 已是最新
                     exit 10 = 有新版本
                     exit 1  = 检查失败
  --ref <ref>      升级到指定 tag/branch/commit（默认：最新 stable pl-v* tag）
  --no-fetch       跳过 git fetch（离线 / 用本地已有 ref）
  -h, --help       本帮助

约束:
  - PL_HOME 必须是 git 仓库（vendor / submodule 模式请走宿主仓 PR）
  - PL_HOME 不能有未提交修改（避免吞掉本地改动）

示例:
  pl upgrade                       # 升到最新 stable
  pl upgrade --check               # 只看一眼有没有新版
  pl upgrade --ref pl-v1.10.0      # 锁到指定版本
  pl upgrade --ref main            # 切到主干（开发场景）
EOF
}

# ---- 解析参数 ----
CHECK_ONLY=false
NO_FETCH=false
REF=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --check)        CHECK_ONLY=true; shift ;;
    --no-fetch)     NO_FETCH=true; shift ;;
    --ref)
      [[ $# -ge 2 ]] || { echo "${C_RED}✗${C_OFF} --ref 缺少参数" >&2; exit 2; }
      REF="$2"; shift 2 ;;
    --ref=*)        REF="${1#*=}"; shift ;;
    -h|--help)      usage; exit 0 ;;
    *)              echo "${C_RED}✗${C_OFF} 未知参数: $1（用 --help 看用法）" >&2; exit 2 ;;
  esac
done

# ---- 校验 PL_HOME ----
if [[ ! -d "$PL_HOME/.git" ]]; then
  cat >&2 <<EOF
${C_RED}✗${C_OFF} PL_HOME 不是 git 仓库: $PL_HOME

可能的原因：
  1) 通过 vendor / 拷贝方式安装 → 请重新拷贝 / 解压新版
  2) 通过 git submodule 嵌入宿主仓 → 在宿主仓内：
       cd <submodule-path> && git fetch && git checkout pl-vX.Y.Z
       cd .. && git add <submodule-path> && git commit
  3) 通过 install.sh 装到 \$HOME/.pl-pipeline → 重跑 install.sh 即可：
       bash "\$PL_HOME/install.sh"
EOF
  exit 1
fi

# ---- 拿本地版本 ----
LOCAL_VERSION="unknown"
[[ -f "$PL_HOME/VERSION" ]] && LOCAL_VERSION=$(tr -d '[:space:]' < "$PL_HOME/VERSION")

# ---- 拉远端 tags ----
if ! $NO_FETCH; then
  echo "${C_BLU}ℹ${C_OFF} 拉取远端 tags..."
  if ! ( cd "$PL_HOME" && git fetch --tags --quiet 2>/dev/null ); then
    echo "${C_YEL}⚠${C_OFF} git fetch 失败（网络 / 权限），改用本地已 fetch 的 ref" >&2
  fi
fi

# ---- 计算最新 stable ----
# 必须显式过滤 -alpha/-beta/-rc/-pre/-dev 后缀（否则 1.10.0 会被字典序排在 1.2.0 后面是另一回事，sort -V 解决；但 pre-release 必须排除）
LATEST_TAG=$(cd "$PL_HOME" && git tag --list 'pl-v*' --sort=-v:refname 2>/dev/null \
  | grep -Ev -- '-(alpha|beta|rc|pre|dev)([.-]|$)' \
  | head -1)

if [[ -z "$LATEST_TAG" ]]; then
  echo "${C_RED}✗${C_OFF} 找不到任何 stable pl-v* tag（仓库可能损坏 / 网络问题）" >&2
  exit 1
fi
LATEST_VERSION="${LATEST_TAG#pl-v}"

# ---- 决定目标 ref ----
TARGET="${REF:-$LATEST_TAG}"

# ---- 计算 local vs remote 关系（使用 sort -V 做 semver 比较）----
# 输出: equal | local-ahead | local-behind
_pl_version_cmp() {
  local a="$1" b="$2"
  if [[ "$a" == "$b" ]]; then echo equal; return; fi
  local newest
  newest=$(printf '%s\n%s\n' "$a" "$b" | sort -V | tail -1)
  if [[ "$newest" == "$a" ]]; then echo local-ahead; else echo local-behind; fi
}
REL=$(_pl_version_cmp "$LOCAL_VERSION" "$LATEST_VERSION")

# ---- 检查模式 ----
if $CHECK_ONLY; then
  case "$REL" in
    equal)
      echo "${C_GRN}✓${C_OFF} 已是最新 stable: ${C_BLD}v${LOCAL_VERSION}${C_OFF}"
      exit 0 ;;
    local-ahead)
      echo "${C_BLU}ℹ${C_OFF} 本地 ${C_BLD}v${LOCAL_VERSION}${C_OFF} 领先远端 stable ${C_BLD}v${LATEST_VERSION}${C_OFF}（开发/未发布版本）"
      exit 0 ;;
    local-behind)
      echo "${C_YEL}↑${C_OFF} 本地 ${C_BLD}v${LOCAL_VERSION}${C_OFF} → 远端 ${C_BLD}v${LATEST_VERSION}${C_OFF} (${LATEST_TAG})"
      echo "  运行 ${C_BLD}pl upgrade${C_OFF} 升级"
      exit 10 ;;
  esac
fi

# ---- 未指定 --ref 时，按 REL 决定是否真升级 ----
if [[ -z "$REF" ]]; then
  case "$REL" in
    equal)
      echo "${C_GRN}✓${C_OFF} 已是最新 stable: ${C_BLD}v${LOCAL_VERSION}${C_OFF}（无需升级）"
      exit 0 ;;
    local-ahead)
      echo "${C_BLU}ℹ${C_OFF} 本地 ${C_BLD}v${LOCAL_VERSION}${C_OFF} 领先远端 stable ${C_BLD}v${LATEST_VERSION}${C_OFF}（开发/未发布版本）"
      echo "  无需升级；如要切到具体版本用 ${C_BLD}--ref pl-vX.Y.Z${C_OFF}"
      exit 0 ;;
    local-behind)
      ;;  # 落到下面执行 checkout
  esac
fi

# ---- 安全检查：禁止吞掉本地未提交修改 ----
if ! ( cd "$PL_HOME" && git diff-index --quiet HEAD -- 2>/dev/null ); then
  cat >&2 <<EOF
${C_RED}✗${C_OFF} PL_HOME 有未提交修改，拒绝 checkout（避免吞掉本地改动）

  路径: $PL_HOME

  请先处理（任选其一）：
    cd $PL_HOME
    git status                              # 看一眼改了什么
    git stash                               # 暂存
    # 或 git commit -am "..." 后再升
EOF
  exit 1
fi

# 同样防止 untracked 但 staged 的状态
if ! ( cd "$PL_HOME" && git diff --cached --quiet 2>/dev/null ); then
  echo "${C_RED}✗${C_OFF} PL_HOME 有 staged 但未 commit 的修改，拒绝 checkout" >&2
  exit 1
fi

# ---- 执行切换 ----
echo "${C_BLU}ℹ${C_OFF} 升级 ${C_BLD}v${LOCAL_VERSION}${C_OFF} → ${C_BLD}${TARGET}${C_OFF}"
if ! ( cd "$PL_HOME" && git checkout "$TARGET" --quiet 2>&1 ); then
  echo "${C_RED}✗${C_OFF} git checkout $TARGET 失败（ref 不存在 / 仓库状态异常）" >&2
  exit 1
fi

# ---- 报告新版本 ----
NEW_VERSION="unknown"
[[ -f "$PL_HOME/VERSION" ]] && NEW_VERSION=$(tr -d '[:space:]' < "$PL_HOME/VERSION")
NEW_DESC=$(cd "$PL_HOME" && git describe --tags --always 2>/dev/null || echo "$TARGET")

echo ""
echo "${C_GRN}✓${C_OFF} pl-pipeline 已切到 ${C_BLD}${NEW_DESC}${C_OFF} (VERSION=${NEW_VERSION})"
echo ""
echo "${C_DIM}下一步建议：${C_OFF}"
echo "  pl --version"
echo "  pl doctor"
echo "  cat $PL_HOME/CHANGELOG.md | head -50    # 看新版改了什么"
exit 0
