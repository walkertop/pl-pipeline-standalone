#!/usr/bin/env bash
# =============================================================================
# setup-hooks.sh — 安装 Git Hooks
# =============================================================================
#
# 用法:
#   ./scripts/setup-hooks.sh            # 安装所有 hooks
#   ./scripts/setup-hooks.sh --remove   # 移除 hooks
#
# =============================================================================

set -euo pipefail

# ---- 颜色定义 ----------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

log_info()    { echo -e "${BLUE}ℹ${NC} $*"; }
log_success() { echo -e "${GREEN}✅${NC} $*"; }
log_warn()    { echo -e "${YELLOW}⚠️${NC} $*"; }
log_error()   { echo -e "${RED}❌${NC} $*"; }

# ---- 配置 -------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
HOOKS_DIR="$PROJECT_ROOT/.git/hooks"

cd "$PROJECT_ROOT"

# 确认 Git 仓库
if [[ ! -d ".git" ]]; then
  log_error "当前目录不是 Git 仓库根目录"
  exit 1
fi

# ---- 参数 -------------------------------------------------------------------
REMOVE=false
[[ "${1:-}" == "--remove" ]] && REMOVE=true

if $REMOVE; then
  log_info "移除 Git hooks..."
  rm -f "$HOOKS_DIR/pre-commit"
  rm -f "$HOOKS_DIR/commit-msg"
  rm -f "$HOOKS_DIR/post-commit"
  log_success "Hooks 已移除"
  exit 0
fi

# ---- 安装 Pre-commit Hook ----------------------------------------------------
echo -e "${BOLD}🔧 安装 Git Hooks${NC}"
echo ""

mkdir -p "$HOOKS_DIR"

# Pre-commit hook
cat > "$HOOKS_DIR/pre-commit" << 'HOOK_EOF'
#!/usr/bin/env bash
# =============================================================================
# pre-commit hook — 提交前自动检查
# =============================================================================
# 由 scripts/setup-hooks.sh 自动安装
# 如需跳过: git commit --no-verify
# =============================================================================

set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "$(git rev-parse --git-dir)")"/scripts && pwd)"

# 颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${BLUE}━━━ Pre-commit 检查 ━━━${NC}"
echo ""

# 检查 staged 的 Kotlin 文件
STAGED_KT=$(git diff --cached --name-only --diff-filter=ACMR | grep -E '\.kt$' || true)

if [[ -n "$STAGED_KT" ]]; then
  echo -e "${BOLD}🔍 Kotlin 代码检查...${NC}"

  # 运行自定义规则检查（快速）
  if [[ -x "$SCRIPT_DIR/lint.sh" ]]; then
    if ! "$SCRIPT_DIR/lint.sh" --staged --custom-only; then
      echo ""
      echo -e "${RED}❌ 代码检查未通过，请修复后再提交${NC}"
      echo -e "提示: 使用 ${BOLD}git commit --no-verify${NC} 跳过检查"
      exit 1
    fi
  fi
else
  echo -e "${GREEN}没有 Kotlin 文件变更，跳过 lint${NC}"
fi

# ---- pl-pipeline 契约检查（pl-status --self-check）-------------------------
# 触发条件：staged 包含 pl/changes/** 或 pl/schemas/*.json 或 scripts/pl-*.sh
# 兜底：PL_SKIP_CONTRACT_CHECK=1 / python3 缺失 / pl-status.sh 缺失 → 优雅降级
if [[ "${PL_SKIP_CONTRACT_CHECK:-0}" != "1" ]]; then
  STAGED_PL=$(git diff --cached --name-only --diff-filter=ACMR \
    | grep -E '^(pl/changes/|pl/schemas/.*\.json$|scripts/pl-.*\.sh$)' || true)

  if [[ -n "$STAGED_PL" ]]; then
    echo ""
    echo -e "${BOLD}🔍 pl-pipeline 契约检查...${NC}"

    if [[ ! -x "$SCRIPT_DIR/pl-status.sh" ]]; then
      echo -e "${YELLOW}⚠️  未找到 scripts/pl-status.sh，跳过契约检查${NC}"
    elif ! command -v python3 >/dev/null 2>&1; then
      echo -e "${YELLOW}⚠️  未找到 python3，跳过契约检查（提示: brew install python3）${NC}"
    else
      # 运行 --self-check；只有 exit=2（契约漂移）才阻止提交
      set +e
      "$SCRIPT_DIR/pl-status.sh" --self-check >/tmp/.pl-selfcheck.$$.log 2>&1
      PL_EXIT=$?
      set -e

      case $PL_EXIT in
        0)
          echo -e "${GREEN}✅ pl-pipeline 契约 OK${NC}"
          ;;
        2)
          echo ""
          echo -e "${RED}❌ pl-pipeline 契约漂移（schema 违反）${NC}"
          cat /tmp/.pl-selfcheck.$$.log
          echo ""
          echo -e "提示: 运行 ${BOLD}./scripts/pl-status.sh --self-check${NC} 查看详情"
          echo -e "紧急跳过: ${BOLD}PL_SKIP_CONTRACT_CHECK=1 git commit${NC} 或 ${BOLD}git commit --no-verify${NC}"
          rm -f /tmp/.pl-selfcheck.$$.log
          exit 1
          ;;
        *)
          echo -e "${YELLOW}⚠️  pl-status 运行错误（exit=$PL_EXIT，降级为警告，不阻止提交）${NC}"
          sed -n '1,5p' /tmp/.pl-selfcheck.$$.log | sed 's/^/   /'
          ;;
      esac
      rm -f /tmp/.pl-selfcheck.$$.log
    fi
  fi
fi

echo ""
echo -e "${GREEN}✅ Pre-commit 检查通过${NC}"
HOOK_EOF

chmod +x "$HOOKS_DIR/pre-commit"
log_success "pre-commit hook 已安装"

# ---- 安装 Commit-msg Hook ----------------------------------------------------
cat > "$HOOKS_DIR/commit-msg" << 'HOOK_EOF'
#!/usr/bin/env bash
# =============================================================================
# commit-msg hook — 校验 Commit Message 格式
# =============================================================================
# 遵循 GIT-001-MSG: Conventional Commits 格式
# =============================================================================

set -eo pipefail

COMMIT_MSG_FILE="$1"
COMMIT_MSG=$(cat "$COMMIT_MSG_FILE")

# 颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

# 跳过 merge commits 和 revert
if echo "$COMMIT_MSG" | head -1 | grep -qE '^(Merge|Revert) '; then
  exit 0
fi

# 校验 Conventional Commits 格式
# <type>(<scope>): <subject>  或  <type>: <subject>
PATTERN='^(feat|fix|refactor|docs|test|chore|style|perf)(\([a-zA-Z0-9_-]+\))?: .+'

FIRST_LINE=$(echo "$COMMIT_MSG" | head -1)

if ! echo "$FIRST_LINE" | grep -qE "$PATTERN"; then
  echo ""
  echo -e "${RED}❌ Commit message 格式不符合 GIT-001-MSG 规范${NC}"
  echo ""
  echo -e "${BOLD}期望格式:${NC} <type>(<scope>): <subject>"
  echo ""
  echo -e "${BOLD}支持的 type:${NC}"
  echo "  feat, fix, refactor, docs, test, chore, style, perf"
  echo ""
  echo -e "${BOLD}示例:${NC}"
  echo "  feat(order): add blind box display"
  echo "  fix(payment): correct discount calculation"
  echo "  chore(build): update Gradle dependencies"
  echo ""
  echo -e "当前消息: ${YELLOW}${FIRST_LINE}${NC}"
  echo ""
  echo -e "提示: 使用 ${BOLD}./scripts/git-commit.sh${NC} 交互式生成规范消息"
  echo -e "或使用 ${BOLD}git commit --no-verify${NC} 跳过校验"
  exit 1
fi

# 检查标题长度
if [[ ${#FIRST_LINE} -gt 72 ]]; then
  echo -e "${YELLOW}⚠️ Commit 标题过长 (${#FIRST_LINE} > 72 字符)${NC}"
  # 仅警告，不阻止
fi

# 检查是否有 TAPD 关联（可选提示）
if ! echo "$COMMIT_MSG" | grep -q '\-\-story=\|\-\-bug='; then
  echo -e "${YELLOW}💡 提示: 建议关联 TAPD (--story=ID 或 --bug=ID)${NC}"
  # 仅提示，不阻止
fi
HOOK_EOF

chmod +x "$HOOKS_DIR/commit-msg"
log_success "commit-msg hook 已安装"

# ---- 安装 Post-commit Hook（Dashboard 自动刷新）-----------------------------
cat > "$HOOKS_DIR/post-commit" << 'HOOK_EOF'
#!/usr/bin/env bash
# =============================================================================
# post-commit hook — 自动刷新 pl-pipeline Dashboard
# =============================================================================
# 由 scripts/setup-hooks.sh 自动安装
# 触发条件：上一次 commit 触及 pl/changes/** 或 pl/schemas/*.json
# 兜底：PL_SKIP_DASHBOARD_REFRESH=1 / 脚本缺失 → 优雅降级（不报错）
# =============================================================================

set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "$(git rev-parse --git-dir)")"/scripts && pwd)"

# 跳过开关
[[ "${PL_SKIP_DASHBOARD_REFRESH:-0}" == "1" ]] && exit 0

# 检查上一次 commit 是否触及 pl/ 关键路径
CHANGED=$(git diff-tree --no-commit-id --name-only -r HEAD 2>/dev/null \
  | grep -E '^(pl/changes/|pl/schemas/.*\.json$)' || true)

[[ -z "$CHANGED" ]] && exit 0

# 调用 dashboard refresh（静默，失败不阻塞）
if [[ -x "$SCRIPT_DIR/pl-dashboard-refresh.sh" ]]; then
  YELLOW='\033[1;33m'
  GREEN='\033[0;32m'
  NC='\033[0m'

  set +e
  "$SCRIPT_DIR/pl-dashboard-refresh.sh" >/tmp/.pl-dashboard.$$.log 2>&1
  EXIT=$?
  set -e

  if [[ $EXIT -eq 0 ]]; then
    echo -e "${GREEN}📊 Dashboard 已自动刷新${NC}"
  else
    echo -e "${YELLOW}⚠️  Dashboard 刷新失败（exit=$EXIT，不阻塞提交）${NC}"
    sed -n '1,3p' /tmp/.pl-dashboard.$$.log | sed 's/^/   /'
  fi
  rm -f /tmp/.pl-dashboard.$$.log
fi
HOOK_EOF

chmod +x "$HOOKS_DIR/post-commit"
log_success "post-commit hook 已安装"

# ---- 完成 -------------------------------------------------------------------
echo ""
echo -e "${CYAN}═══════════════════════════════════════════${NC}"
echo -e "${BOLD}已安装的 Hooks:${NC}"
echo "  📋 pre-commit   — Kotlin 代码检查 + pl-pipeline 契约 self-check"
echo "  📋 commit-msg   — Commit message 格式校验 (GIT-001)"
echo "  📋 post-commit  — pl-pipeline Dashboard 自动刷新"
echo ""
echo -e "移除: ${BOLD}./scripts/setup-hooks.sh --remove${NC}"
echo -e "跳过全部: ${BOLD}git commit --no-verify${NC}"
echo -e "仅跳过契约检查: ${BOLD}PL_SKIP_CONTRACT_CHECK=1 git commit${NC}"
echo -e "仅跳过 Dashboard 刷新: ${BOLD}PL_SKIP_DASHBOARD_REFRESH=1 git commit${NC}"
echo -e "${CYAN}═══════════════════════════════════════════${NC}"
