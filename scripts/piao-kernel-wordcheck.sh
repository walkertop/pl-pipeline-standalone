#!/usr/bin/env bash
# =============================================================================
# piao-kernel-wordcheck.sh — piao-pipeline kernel 场景词检查
# =============================================================================
#
# 本脚本由宿主 KuiklyPolyCity `scripts/kernel-wordcheck.sh` 抽离而来，
# 接入 pl-pipeline 独立仓 _env.sh 路径体系。
#
# 依据（迁移后路径）：
#   ${PL_ASSETS}/piao/docs/kernel/scenario-wordlist.md
#   ${PL_ASSETS}/piao/docs/kernel/07-extensibility.md §1 边界 1
#   ${PL_ASSETS}/piao/docs/kernel/_review/M1-final-decisions.md §1 决议 4
#
# 功能：
#   扫描 kernel 受管控目录下的 markdown 文件，命中强禁用词或
#   错位使用的受限词时报告行号 + 命中词 + 推荐改写。
#
# 用法（默认扫描独立仓内置 piao kernel 文档）：
#   piao-kernel-wordcheck.sh              # 默认：扫描 $PL_ASSETS/piao/docs，人工自查模式
#   piao-kernel-wordcheck.sh --ci         # CI 模式：命中即以非零退出码失败
#   piao-kernel-wordcheck.sh --file FILE  # 只扫单个文件
#   piao-kernel-wordcheck.sh --list       # 打印当前词表（不扫描）
#   piao-kernel-wordcheck.sh --help       # 帮助
#
# 用户自定义扫描目录（例如扫描 adapter 仓库的 kernel 引用）：
#   PIAO_SCAN_ROOT=/path/to/other/docs piao-kernel-wordcheck.sh
#
# 退出码：
#   0 = 无违规
#   1 = 发现违规（仅在 --ci 下）
#   2 = 参数错误
#
# 版本：v0.1（M1 交付）— 人工自查模式为主，--ci 提供 hook 接入预留
#      v0.2 将接入 git pre-commit hook + inline escape 机制
#
# =============================================================================

# shellcheck source=./_env.sh
source "$(dirname "${BASH_SOURCE[0]}")/_env.sh"
set -euo pipefail

# ---- 颜色 -------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

log_info()    { echo -e "${BLUE}ℹ${NC} $*"; }
log_success() { echo -e "${GREEN}✅${NC} $*"; }
log_warn()    { echo -e "${YELLOW}⚠️${NC} $*"; }
log_error()   { echo -e "${RED}❌${NC} $*"; }

# ---- 路径 -------------------------------------------------------------------
# PIAO_SCAN_ROOT: 扫描的根目录（覆盖 $PL_ASSETS/piao/docs 默认值）
# 允许用户把本脚本指向任意目录（例如 adapter 仓库里引用的 kernel 文档）
PIAO_SCAN_ROOT="${PIAO_SCAN_ROOT:-${PL_ASSETS}/piao/docs}"

# ---- 配置：受管控目录 --------------------------------------------------------
# 与 scenario-wordlist.md §1.1 一致
# 迁移后：路径相对 $PIAO_SCAN_ROOT，而非相对 PROJECT_ROOT
MANAGED_GLOBS=(
  "${PIAO_SCAN_ROOT}/00-overview.md"
  "${PIAO_SCAN_ROOT}/kernel"
)

# 豁免路径（在受管控目录下也跳过）
# - _review/ 存放评审历史，允许引用旧决策
# - scenario-wordlist.md 是词表文档本身，整篇都在讨论禁用词
EXEMPT_PATTERNS=(
  "/kernel/_review/"
  "/kernel/scenario-wordlist.md"
)

# 文件级豁免标记：front-matter 含 `wordcheck_exempt: true` 的文件整体跳过
# （v0.1：用于词表/规则讨论类元文档；v0.2 会换成 inline escape 段落粒度）
has_file_level_exemption() {
  local file="$1"
  # 只读前 20 行的 front-matter 范围
  head -20 "$file" 2>/dev/null | grep -q '^wordcheck_exempt:[[:space:]]*true[[:space:]]*$'
}

# ---- 词表 -------------------------------------------------------------------
# 强禁用词：kernel 文档出现即违规
# 格式：word|推荐改写
STRONG_BAN=(
  "kuikly|adapter.<name> / 某个 adapter"
  "weex|legacy source / migration source adapter"
  "vue|source framework"
  "compose|UI DSL / declarative UI runtime"
  "kotlin|host language / adapter implementation language"
  "swift|host language"
  "objective-c|host language"
  "android|target platform"
  "ios|target platform"
  "gradle|build tool"
  "cocoapods|build tool"
  "detekt|static analyzer"
  "ktlint|static analyzer"
  "swiftlint|static analyzer"
  "tapd|task tracker"
  "logcat|runtime log source"
  "adb|device bridge"
  "screenshot|visual verification signal"
  "miniapp|target application bundle"
  "page_id|unit_id（M1 决议 2：page kind 已合并到 unit）"
)

# 受限使用词：需上下文判断，默认命中后给 warning 而非 error
# 格式：word|允许使用场景
RESTRICTED=(
  "page|仅在迁移路径/历史追述段落允许；kernel 一律用 unit"
  "card|仅作 adapter 的 task 类型示例"
  "viewmodel|仅作 adapter 的 task 类型示例"
  "migration|仅作 adapter 的 task 类型示例；kernel 层应用 rewrite / transform"
)

# ---- 参数解析 ---------------------------------------------------------------
MODE="scan"              # scan | ci | list
SINGLE_FILE=""

print_help() {
  sed -n '2,38p' "$0" | sed 's/^# \{0,1\}//'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --ci)         MODE="ci"; shift ;;
    --file)       MODE="scan"; SINGLE_FILE="${2:-}"; shift 2 ;;
    --list)       MODE="list"; shift ;;
    -h|--help)    print_help; exit 0 ;;
    *)            log_error "未知参数: $1"; print_help; exit 2 ;;
  esac
done

# ---- 词表打印 ---------------------------------------------------------------
if [[ "$MODE" == "list" ]]; then
  echo -e "${BOLD}kernel 场景词白名单 v0.1${NC}"
  echo ""
  echo -e "${RED}【强禁用】（出现即违规）${NC}"
  for entry in "${STRONG_BAN[@]}"; do
    word="${entry%%|*}"; replace="${entry#*|}"
    printf "  %-20s ← 建议改为：%s\n" "$word" "$replace"
  done
  echo ""
  echo -e "${YELLOW}【受限使用】（需上下文判断）${NC}"
  for entry in "${RESTRICTED[@]}"; do
    word="${entry%%|*}"; context="${entry#*|}"
    printf "  %-20s %s\n" "$word" "$context"
  done
  echo ""
  echo -e "${DIM}扫描根目录：${PIAO_SCAN_ROOT}${NC}"
  echo -e "${DIM}受管控目录：${MANAGED_GLOBS[*]}${NC}"
  exit 0
fi

# ---- 扫描根目录合法性校验 ---------------------------------------------------
if [[ ! -d "$PIAO_SCAN_ROOT" ]]; then
  log_warn "扫描根目录不存在: $PIAO_SCAN_ROOT"
  log_info "提示：可通过 PIAO_SCAN_ROOT 环境变量指定，或先运行 Phase P1-3 迁移 piao docs"
  # 允许目录不存在时以 0 退出（MVP 阶段 docs 还未迁移的情况下不应阻断）
  exit 0
fi

# ---- 目标文件收集 -----------------------------------------------------------
# 统一的豁免判定：路径豁免 + front-matter 豁免
# 返回值：0 = 豁免（跳过扫描），非 0 = 需要扫描
is_exempt() {
  local f="$1"
  # 路径级豁免
  for pat in "${EXEMPT_PATTERNS[@]}"; do
    [[ "$f" == *"$pat"* ]] && return 0
  done
  # 文件级 front-matter 豁免
  has_file_level_exemption "$f" && return 0
  return 1
}

collect_files() {
  if [[ -n "$SINGLE_FILE" ]]; then
    [[ -f "$SINGLE_FILE" ]] || { log_error "文件不存在: $SINGLE_FILE"; exit 2; }
    # --file 模式也走豁免过滤，保持与批量扫描一致
    if is_exempt "$SINGLE_FILE"; then
      log_info "文件已豁免: $SINGLE_FILE" >&2
      return
    fi
    echo "$SINGLE_FILE"
    return
  fi

  for path in "${MANAGED_GLOBS[@]}"; do
    if [[ -f "$path" ]]; then
      echo "$path"
    elif [[ -d "$path" ]]; then
      find "$path" -type f -name "*.md"
    fi
  done | sort -u | while read -r f; do
    is_exempt "$f" || echo "$f"
  done
}

# ---- 扫描核心 ---------------------------------------------------------------
# grep 输出格式化成：FILE:LINE:LEVEL:WORD:MATCH_TEXT
# LEVEL: BAN | WARN

scan_file() {
  local file="$1"
  local findings=""

  # 强禁用：大小写不敏感；用 \b 锚定词边界避免子串误伤
  for entry in "${STRONG_BAN[@]}"; do
    local word="${entry%%|*}"
    local replace="${entry#*|}"
    # 构造词边界正则；对含特殊字符（如 objective-c）转义
    local pattern
    pattern="$(printf '%s' "$word" | sed 's/[.[\*^$()+?{|]/\\&/g')"
    # \b 在 BSD grep 上行为一致，用 -w 更稳妥
    while IFS=: read -r lineno matchline; do
      [[ -n "$lineno" ]] || continue
      findings+="${file}|${lineno}|BAN|${word}|${matchline}|${replace}"$'\n'
    done < <(grep -niwE "${pattern}" "$file" 2>/dev/null || true)
  done

  # 受限使用：与强禁用同机制，但级别为 WARN
  for entry in "${RESTRICTED[@]}"; do
    local word="${entry%%|*}"
    local ctx="${entry#*|}"
    local pattern
    pattern="$(printf '%s' "$word" | sed 's/[.[\*^$()+?{|]/\\&/g')"
    while IFS=: read -r lineno matchline; do
      [[ -n "$lineno" ]] || continue
      findings+="${file}|${lineno}|WARN|${word}|${matchline}|${ctx}"$'\n'
    done < <(grep -niwE "${pattern}" "$file" 2>/dev/null || true)
  done

  # 过滤显然合法的行（启发式，v0.1 粗糙版）：
  # 以下命中视为合法引用，不报告：
  #   1. URN/路径字符串：含 `adapters/<name>/` 路径或 `adapter.<name>` 前缀
  #   2. 元引用段：行内出现"禁用|强禁用|受限|推荐改写|场景词|本表"等元讨论关键词
  #   3. 命中词出现在某对反引号内（inline code mention）：
  #      形如 `...<word>...` 的 markdown inline code；所有命中词实例都在某段反引号内才豁免
  #   4. 词表行模式：整行由 " / " 分隔多个词（典型禁用词枚举行）
  # v0.2 将替换为显式 inline escape 机制 `<!-- kernel-wordcheck: allow -->`
  if [[ -n "$findings" ]]; then
    echo "$findings" | awk -F'|' '
      # 判断命中词的每一处都处于某对反引号内
      # 做法：移除所有成对反引号内的内容后，若原命中词消失，则说明全部在反引号内
      function all_in_backticks(text, word) {
        # 将反引号配对内容（非贪婪）替换为占位符
        stripped = text
        gsub(/`[^`]*`/, "", stripped)
        # 若去除反引号区域后命中词不再出现（大小写不敏感），则视为全部 mention
        return index(tolower(stripped), tolower(word)) == 0
      }
      NF >= 5 {
        line=$5
        word=$4
        # 1. URN 身份字符串 / adapter 路径
        if (line ~ /adapters\/[a-z_]+\//) next
        if (line ~ /adapter\.[a-z_]+/) next
        # 2. 元引用：行内出现禁止词讨论关键词
        if (line ~ /(强?禁用|受限|推荐改写|场景词|禁止词|white[- ]?list|白名单|本表|本词表|见 §)/) next
        # 3. 命中词完全处于反引号 inline code 区域
        if (all_in_backticks(line, word)) next
        # 4. 词表行模式：行内有 3+ 个 " / " 分隔（禁用词枚举风格）
        slash_count = gsub(/ \/ /, " / ", line)
        if (slash_count >= 3) next
        print
      }
    '
  fi
}

# ---- 主扫描循环 -------------------------------------------------------------
declare -i total_files=0
declare -i ban_count=0
declare -i warn_count=0
all_findings=""

while read -r file; do
  [[ -z "$file" ]] && continue
  total_files+=1
  result="$(scan_file "$file")"
  if [[ -n "$result" ]]; then
    all_findings+="${result}"$'\n'
  fi
done < <(collect_files)

# ---- 结果输出 ---------------------------------------------------------------
if [[ -z "$all_findings" || "$all_findings" == $'\n' ]]; then
  log_success "kernel 场景词检查通过（共扫描 ${total_files} 个文件 · root=${PIAO_SCAN_ROOT}）"
  exit 0
fi

echo ""
echo -e "${BOLD}piao-kernel-wordcheck 报告${NC}"
echo -e "${DIM}──────────────────────────────────────────────────${NC}"

# 按 BAN / WARN 分组输出
echo "$all_findings" | awk -F'|' -v RED="$(printf '\033[0;31m')" -v YEL="$(printf '\033[1;33m')" -v NC="$(printf '\033[0m')" -v DIM="$(printf '\033[2m')" '
NF < 5 { next }
{
  label = ($3 == "BAN") ? RED "✗ BAN " NC : YEL "⚠ WARN" NC
  printf "%s  %s:%s\n", label, $1, $2
  printf "       %s词:%s %s\n", DIM, NC, $4
  printf "       %s命中行:%s %s\n", DIM, NC, substr($5, 1, 120)
  printf "       %s建议:%s %s\n\n", DIM, NC, $6
}
'

ban_count=$(echo "$all_findings" | awk -F'|' '$3=="BAN"{n++} END{print n+0}')
warn_count=$(echo "$all_findings" | awk -F'|' '$3=="WARN"{n++} END{print n+0}')

echo -e "${DIM}──────────────────────────────────────────────────${NC}"
echo -e "扫描文件数: ${total_files}    违规(BAN): ${RED}${ban_count}${NC}    警告(WARN): ${YELLOW}${warn_count}${NC}"
echo ""
echo -e "${DIM}提示：查看完整词表与例外规则请运行 $0 --list${NC}"
echo -e "${DIM}      或阅读 \${PL_ASSETS}/piao/docs/kernel/scenario-wordlist.md${NC}"

# ---- 退出码决策 --------------------------------------------------------------
if [[ "$MODE" == "ci" ]]; then
  if (( ban_count > 0 )); then
    echo ""
    log_error "CI 模式：发现 ${ban_count} 条强禁用词违规，退出码 1"
    exit 1
  fi
  # WARN 在 CI 模式下不阻断（受限词需上下文判断，交人类审查）
  log_success "CI 模式：无强禁用词违规（${warn_count} 条警告仅供参考）"
  exit 0
fi

# 非 CI 模式始终返回 0，仅作信息展示
exit 0
