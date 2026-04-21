#!/usr/bin/env bash
# ============================================================================
# pl-migrate-legacy.sh — openspec/changes/<id> → pl/changes/<id> 幂等迁移
# ----------------------------------------------------------------------------
# Usage:
#   scripts/pl-migrate-legacy.sh --change <id>              # 迁移单个
#   scripts/pl-migrate-legacy.sh --change <id> --force      # 覆盖已存在目标
#   scripts/pl-migrate-legacy.sh --change <id> --dry-run    # 只打印计划
#   scripts/pl-migrate-legacy.sh --all                      # 迁移所有 legacy change
#   scripts/pl-migrate-legacy.sh --all --dry-run
#
# 语义：
#   - 迁移即 COPY，不修改源文件（legacy 原目录保持不动，等 deprecation-date 后整体删）
#   - 幂等：重复运行不破坏已迁内容；--force 才覆盖
#   - 文件映射见下方 MAPPING 表（也记录在 docs/pl-pipeline/README.md §7）
#
# Exit code:
#   0 = OK（迁移成功 / --dry-run 正常）
#   1 = 参数错误 / 源目录不存在 / 目标已存在且未 --force
# ============================================================================
set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/_env.sh"
REPO_ROOT="$PL_PROJECT"
LEGACY_ROOT="$PL_PROJECT/openspec/changes"
PL_ROOT="$PL_CHANGES"

if [[ -t 1 ]]; then
  RED=$'\033[0;31m'; GREEN=$'\033[0;32m'; YELLOW=$'\033[0;33m'
  BLUE=$'\033[0;34m'; BOLD=$'\033[1m'; DIM=$'\033[2m'; NC=$'\033[0m'
else
  RED=; GREEN=; YELLOW=; BLUE=; BOLD=; DIM=; NC=
fi

CHANGE_ID=""
FORCE=0
DRY_RUN=0
ALL=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --change)   CHANGE_ID="${2:-}"; shift 2 ;;
    --all)      ALL=1; shift ;;
    --force)    FORCE=1; shift ;;
    --dry-run)  DRY_RUN=1; shift ;;
    -h|--help)
      sed -n '3,20p' "$0" | sed 's/^# \{0,1\}//'
      exit 0 ;;
    *)
      echo "${RED}未知参数: $1${NC}" >&2
      exit 1 ;;
  esac
done

if [[ "$ALL" -eq 0 && -z "$CHANGE_ID" ]]; then
  echo "${RED}必须指定 --change <id> 或 --all${NC}" >&2
  exit 1
fi

# ─── 文件映射规则（按优先级）───────────────────────────────────────────
# 从 legacy 目录挑一个文件 → 映射到 pl 目标文件名
# 使用 bash 4+ 的 case 就够了（此处我们手动实现优先级）

# 映射单个字段：从候选文件中选第一个存在的 → dest
# 参数：$1 = legacy_dir  $2 = dest_filename  $3... = 候选文件名（按优先级）
# 返回：stdout 打印 "<src_file>" 或空
pick_file() {
  local dir="$1"; shift
  local _dest="$1"; shift   # unused（仅用于可读性；上层 map 时会告诉用户）
  for cand in "$@"; do
    if [[ -f "$dir/$cand" ]]; then
      echo "$cand"
      return 0
    fi
  done
  return 1
}

# 找版本化文件中最高版本：优先无版本号的 `base.md`（认定为 canonical 最新版），
# 其次选 base.vN.md 的 N 最大者。
# 参数：$1 = dir  $2 = base 名（如 Plan / TaskDAG）
pick_versioned() {
  local dir="$1" base="$2"
  # 1. 无版本号的 base.md 视为 canonical 最新
  if [[ -f "$dir/$base.md" ]]; then
    echo "$base.md"
    return 0
  fi
  # 2. fallback 到 base.vN.md 中 N 最大者
  local best="" bestn=0
  for f in "$dir/$base".v[0-9]*.md; do
    [[ -f "$f" ]] || continue
    local n
    n=$(basename "$f" | sed -E "s/^$base\.v([0-9]+)\.md$/\1/")
    if [[ -n "$n" && "$n" -gt "$bestn" ]]; then
      bestn="$n"; best="$(basename "$f")"
    fi
  done
  if [[ -n "$best" ]]; then
    echo "$best"
    return 0
  fi
  return 1
}

# 列出单个 change 的迁移计划 —— 以 "<src>\t<dst>" 行格式输出
# 未命中的 dst 会被跳过（用户用 /pl:plan 等命令补齐）
build_plan() {
  local dir="$1"

  # 1. spec.md ← StructuredSpec.md | proposal.md
  local src
  if src=$(pick_file "$dir" "spec.md" "StructuredSpec.md" "proposal.md"); then
    printf '%s\tspec.md\n' "$src"
  fi

  # 2. plan.md ← Plan.vN.md（最高）| design.md
  if src=$(pick_versioned "$dir" "Plan"); then
    printf '%s\tplan.md\n' "$src"
  elif src=$(pick_file "$dir" "plan.md" "design.md"); then
    printf '%s\tplan.md\n' "$src"
  fi

  # 3. taskdag.md ← TaskDAG.vN.md（最高）| TaskDAG.md | tasks.md
  if src=$(pick_versioned "$dir" "TaskDAG"); then
    printf '%s\ttaskdag.md\n' "$src"
  elif src=$(pick_file "$dir" "taskdag.md" "tasks.md"); then
    printf '%s\ttaskdag.md\n' "$src"
  fi

  # 4. api.md ← APIContract.md
  if src=$(pick_file "$dir" "api.md" "APIContract.md"); then
    printf '%s\tapi.md\n' "$src"
  fi

  # 5. testmatrix.md ← TestMatrix.md
  if src=$(pick_file "$dir" "testmatrix.md" "TestMatrix.md"); then
    printf '%s\ttestmatrix.md\n' "$src"
  fi

  # 6. deps.md ← DependencyAnalysis.md
  if src=$(pick_file "$dir" "deps.md" "DependencyAnalysis.md"); then
    printf '%s\tdeps.md\n' "$src"
  fi

  # 7. .state.md ← <anything>.state.md（典型 order_detail.state.md）
  local state_src=""
  for f in "$dir"/*.state.md "$dir"/.state.md; do
    if [[ -f "$f" ]]; then
      state_src=$(basename "$f")
      break
    fi
  done
  if [[ -n "$state_src" ]]; then
    printf '%s\t.state.md\n' "$state_src"
  fi

  # 8. specs/ 目录（整目录保留）
  if [[ -d "$dir/specs" ]]; then
    printf 'specs\tspecs\n'
  fi
}

# ─── 比较两文件是否内容等价（忽略末尾多余换行）──────────────────────
files_equal() {
  if [[ ! -f "$1" || ! -f "$2" ]]; then return 1; fi
  # 采用 cmp 更严格，但允许末尾 \n 差异：两次 tr / cmp
  diff -q "$1" "$2" >/dev/null 2>&1
}

# ─── 迁移单个 change ──────────────────────────────────────────────────
migrate_one() {
  local id="$1"
  local src_dir="$LEGACY_ROOT/$id"
  local dst_dir="$PL_ROOT/$id"

  if [[ ! -d "$src_dir" ]]; then
    echo "${RED}[$id] 源目录不存在: $src_dir${NC}" >&2
    return 1
  fi

  echo "${BOLD}[$id]${NC}"
  echo "  源: ${DIM}$src_dir${NC}"
  echo "  目标: ${DIM}$dst_dir${NC}"

  # 构造迁移计划
  local plan
  plan=$(build_plan "$src_dir")
  if [[ -z "$plan" ]]; then
    echo "  ${YELLOW}⚠️ 无可识别的 legacy 产物，跳过${NC}"
    return 0
  fi

  # dry-run：只打印
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "  ${DIM}迁移计划（dry-run）:${NC}"
    while IFS=$'\t' read -r src dst; do
      if [[ "$src" == "specs" ]]; then
        echo "    DIR   specs/ → specs/"
      else
        local status=""
        if [[ -e "$dst_dir/$dst" ]]; then
          if files_equal "$src_dir/$src" "$dst_dir/$dst"; then
            status=" ${GREEN}(= already same, skip)${NC}"
          else
            status=" ${YELLOW}(EXISTS, need --force)${NC}"
          fi
        fi
        echo "    FILE  $src → $dst$status"
      fi
    done <<< "$plan"
    return 0
  fi

  # 创建目标目录
  mkdir -p "$dst_dir"

  # 执行迁移
  local n_new=0 n_same=0 n_over=0 n_skip=0
  while IFS=$'\t' read -r src dst; do
    if [[ "$src" == "specs" ]]; then
      # 整目录 rsync 式复制；保留已有（除非 --force 覆盖）
      if [[ -d "$dst_dir/specs" && "$FORCE" -eq 0 ]]; then
        echo "    ${YELLOW}- skip${NC} specs/（已存在，--force 覆盖）"
        n_skip=$((n_skip + 1))
      else
        [[ -d "$dst_dir/specs" && "$FORCE" -eq 1 ]] && rm -rf "$dst_dir/specs"
        cp -R "$src_dir/specs" "$dst_dir/specs"
        echo "    ${GREEN}+ dir${NC}   specs/"
        n_new=$((n_new + 1))
      fi
      continue
    fi

    local src_path="$src_dir/$src"
    local dst_path="$dst_dir/$dst"

    if [[ ! -e "$dst_path" ]]; then
      cp "$src_path" "$dst_path"
      echo "    ${GREEN}+ new${NC}   $src → $dst"
      n_new=$((n_new + 1))
      continue
    fi

    if files_equal "$src_path" "$dst_path"; then
      echo "    ${DIM}= same${NC}  $src → $dst"
      n_same=$((n_same + 1))
      continue
    fi

    if [[ "$FORCE" -eq 1 ]]; then
      # 备份后覆盖
      local bak="$dst_path.bak-$(date +%Y%m%d-%H%M%S)"
      cp "$dst_path" "$bak"
      cp "$src_path" "$dst_path"
      echo "    ${YELLOW}~ over${NC}  $src → $dst  ${DIM}(backup: $(basename "$bak"))${NC}"
      n_over=$((n_over + 1))
    else
      echo "    ${RED}x skip${NC}  $src → $dst  ${DIM}(目标已存在且不同；--force 覆盖)${NC}"
      n_skip=$((n_skip + 1))
    fi
  done <<< "$plan"

  echo "  ${BOLD}结果: +new=$n_new, =same=$n_same, ~over=$n_over, x skip=$n_skip${NC}"

  # 若有 skip 且非 --force → exit 1（让 CI 可明确感知）
  if [[ "$n_skip" -gt 0 && "$FORCE" -eq 0 ]]; then
    return 1
  fi
  return 0
}

# ─── 主流程 ────────────────────────────────────────────────────────────
if [[ "$ALL" -eq 1 ]]; then
  if [[ ! -d "$LEGACY_ROOT" ]]; then
    echo "${RED}$LEGACY_ROOT 不存在${NC}" >&2
    exit 1
  fi
  any_fail=0
  for d in "$LEGACY_ROOT"/*/; do
    [[ -d "$d" ]] || continue
    id=$(basename "$d")
    if ! migrate_one "$id"; then
      any_fail=1
    fi
    echo ""
  done
  exit "$any_fail"
else
  migrate_one "$CHANGE_ID"
fi
