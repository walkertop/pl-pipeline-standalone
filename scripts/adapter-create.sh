#!/usr/bin/env bash
# =============================================================================
# adapter-create.sh — pl-pipeline Adapter 脚手架
# =============================================================================
#
# 用法:
#   bash scripts/adapter-create.sh <adapter-id> [--dest <dir>] [--minimal|--full]
#
#   adapter-id     机器 ID，kebab-case，如 rust-axum / go-gin / ios-app
#   --dest <dir>   生成目录，默认 $PL_HOME/adapters/adapter-<id>
#   --minimal      只生成 adapter.yaml + README + 空目录（默认）
#   --full         额外生成占位 templates/agents/skills/rules/scripts
#   --force        目标目录已存在时覆盖
#   -h | --help    打印帮助
#
# 行为:
#   1. 校验 id 合法性（^[a-z][a-z0-9-]*$）
#   2. 生成目录骨架
#   3. 用 pl-core assets 里的 7 件产物模板填充 templates/
#   4. 产出一个可被 adapter-validate.sh 通过的最小 adapter
#   5. 给出 next steps 指引
#
# 退出码: 0 成功 / 1 失败 / 2 参数错误
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

log_info()  { echo "${BLUE}ℹ${NC} $*"; }
log_ok()    { echo "${GREEN}✅${NC} $*"; }
log_warn()  { echo "${YELLOW}⚠${NC}  $*"; }
log_error() { echo "${RED}✗${NC}  $*" >&2; }

# ---- 参数 ----
ADAPTER_ID=""
DEST=""
MODE="minimal"
FORCE=false

usage() {
  sed -n '2,25p' "$0" | sed 's/^# \{0,1\}//'
  exit 2
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dest)     DEST="$2"; shift 2 ;;
    --minimal)  MODE="minimal"; shift ;;
    --full)     MODE="full"; shift ;;
    --force)    FORCE=true; shift ;;
    -h|--help)  usage ;;
    --*)        log_error "Unknown option: $1"; usage ;;
    *)
      if [[ -z "$ADAPTER_ID" ]]; then
        ADAPTER_ID="$1"; shift
      else
        log_error "Too many positional arguments"; usage
      fi
      ;;
  esac
done

[[ -z "$ADAPTER_ID" ]] && { log_error "Missing <adapter-id>"; usage; }

# ---- 校验 id ----
if ! [[ "$ADAPTER_ID" =~ ^[a-z][a-z0-9-]*$ ]]; then
  log_error "Invalid adapter id: '$ADAPTER_ID'"
  log_error "  Must match: ^[a-z][a-z0-9-]*\$  (kebab-case, 小写开头)"
  exit 2
fi

# ---- 决定目标目录 ----
if [[ -z "$DEST" ]]; then
  DEST="$PL_HOME/adapters/adapter-$ADAPTER_ID"
fi

# 转绝对路径（父目录必须存在）
parent_dir="$(dirname "$DEST")"
if [[ ! -d "$parent_dir" ]]; then
  mkdir -p "$parent_dir"
fi
DEST="$(cd "$parent_dir" && pwd)/$(basename "$DEST")"

# ---- 冲突检查 ----
if [[ -d "$DEST" ]]; then
  if $FORCE; then
    log_warn "Destination exists, --force given, removing: $DEST"
    rm -rf "$DEST"
  else
    log_error "Destination already exists: $DEST"
    log_error "Use --force to overwrite, or specify different --dest"
    exit 1
  fi
fi

# ---- 前置资产检查 ----
if [[ ! -d "$PL_ASSETS/pl/templates" ]]; then
  log_error "pl-core templates not found at \$PL_ASSETS/pl/templates"
  log_error "PL_ASSETS=$PL_ASSETS"
  exit 1
fi

today="$(date -u +'%Y-%m-%d')"

echo "${BOLD}━━━ Creating adapter ━━━${NC}"
echo "  id:   $ADAPTER_ID"
echo "  dir:  $DEST"
echo "  mode: $MODE"
echo ""

# ---- 目录骨架 ----
mkdir -p "$DEST"/{templates,agents,skills,rules,scripts,docs}

# ---- 核心：adapter.yaml ----
# minimal: provides 只声明 templates，其他以注释形式留样例
# full:    provides 启用 agents/skills/rules/scripts 指向 stub 文件

if [[ "$MODE" == "full" ]]; then
cat > "$DEST/adapter.yaml" <<EOF
apiVersion: pl.dev/v1
kind: Adapter

metadata:
  id: $ADAPTER_ID
  name: "$ADAPTER_ID adapter (TODO: 填写人类可读名)"
  description: >
    TODO: 一段话描述这个 adapter 覆盖什么技术栈 / 场景。
    建议 2-3 句，说明目标语言、框架、典型项目形态。
  version: 0.1.0
  compatible_pl: ">=0.1.0-mvp <1.0.0"
  license: Apache-2.0
  authors:
    - name: walker
      email: bin5211bin@gmail.com
  # TODO: 添加 auto-detect 规则
  # detect:
  #   - file_exists: "<marker-file>"

provides:
  templates:
    spec: "templates/spec.md"
    plan: "templates/plan.md"
    taskdag: "templates/taskdag.md"
  agents:
    - path: "agents/${ADAPTER_ID}-architect.md"
      id: ${ADAPTER_ID}-architect
      description: "TODO: 架构师描述"
  skills:
    - id: ${ADAPTER_ID}-basics
      path: "skills/${ADAPTER_ID}-basics.md"
      triggers: ["TODO-keyword"]
      description: "TODO: skill 描述"
  rules:
    - id: ${ADAPTER_ID}-conventions
      path: "rules/${ADAPTER_ID}-conventions.md"
      scope: always
      description: "TODO: 编码规范"
  scripts:
    build: "scripts/build.sh"
    verify: "scripts/verify.sh"
    lint: "scripts/lint.sh"
  # TODO: 填写 build_adapter 配置，给 pl-core 的 \$PL_BUILD_CHECK_CMD 注入值
  # build_adapter:
  #   type: custom
  #   commands:
  #     compile_check: "<fast typecheck command>"
  #     lint: "<lint command>"
  #     test: "<test command>"

# requires:
#   tools:
#     - name: <executable>
#       min_version: "x.y"
#   files:
#     - <required-file-in-host>

# piao_emit:
#   on_stages: [VERIFY, ARCHIVE]
#   urn_namespace: "urn:piao:artifact:pl:$ADAPTER_ID"
EOF
else
cat > "$DEST/adapter.yaml" <<EOF
apiVersion: pl.dev/v1
kind: Adapter

metadata:
  id: $ADAPTER_ID
  name: "$ADAPTER_ID adapter (TODO: 填写人类可读名)"
  description: >
    TODO: 一段话描述这个 adapter 覆盖什么技术栈 / 场景。
    建议 2-3 句，说明目标语言、框架、典型项目形态。
  version: 0.1.0
  compatible_pl: ">=0.1.0-mvp <1.0.0"
  license: Apache-2.0
  authors:
    - name: walker
      email: bin5211bin@gmail.com
  # TODO: 添加 auto-detect 规则，支持 pl init --smart 自动匹配
  # detect:
  #   - file_exists: "<marker-file>"
  #   - package_json_has: "<dep-name>"

provides:
  templates:
    spec: "templates/spec.md"
    plan: "templates/plan.md"
    taskdag: "templates/taskdag.md"
  # 建议按需启用以下节：
  # agents:
  #   - path: "agents/${ADAPTER_ID}-architect.md"
  #     description: "架构师"
  # skills:
  #   - id: <skill-id>
  #     path: "skills/<skill-id>.md"
  #     triggers: ["keyword1", "keyword2"]
  # rules:
  #   - path: "rules/<rule-id>.md"
  #     scope: always
  # scripts:
  #   build: "scripts/build.sh"
  #   verify: "scripts/verify.sh"
  #   lint: "scripts/lint.sh"
  # build_adapter:
  #   type: <npm|pnpm|yarn|gradle|maven|cargo|go|uv|pip|poetry|make|xcodebuild|custom>
  #   commands:
  #     compile_check: "<fast typecheck command>"
  #     lint: "<lint command>"
  #     test: "<test command>"

# requires:
#   tools:
#     - name: <executable>
#       min_version: "x.y"
#   files:
#     - <required-file-in-host>

# piao_emit:
#   on_stages: [VERIFY, ARCHIVE]
#   urn_namespace: "urn:piao:artifact:pl:$ADAPTER_ID"
EOF
fi
log_ok "adapter.yaml"

# ---- README.md ----
cat > "$DEST/README.md" <<EOF
# adapter-$ADAPTER_ID

> TODO: 一段话描述本 adapter 的定位与适用场景。

## 适用场景

- TODO: 列出典型技术栈 / 框架 / 版本范围
- TODO: 适合什么项目形态（Web / 后端 / 移动 / 命令行 ...）

## 一键安装

\`\`\`bash
# 到你的宿主项目根目录
cd /path/to/my-project

# 初始化 pl 结构（若还没做过）
mkdir -p pl/{changes,templates} .codebuddy/{agents,skills,rules} scripts
cp \$PL_ASSETS/pl/config.default.yaml pl/config.yaml

# 安装本 adapter
pl adapter install \\
  \$PL_HOME/adapters/adapter-$ADAPTER_ID \\
  .
\`\`\`

## 提供什么

| 资产类 | 数量 | 亮点 |
|---|---|---|
| Templates | 3 | spec / plan / taskdag |
| Agents | 0 | TODO |
| Skills | 0 | TODO |
| Rules | 0 | TODO |
| Scripts | 0 | TODO |

## 校验

\`\`\`bash
pl adapter validate \$PL_HOME/adapters/adapter-$ADAPTER_ID
\`\`\`

## 案例

见 \`docs/case-study.md\`。

## 版本

| 版本 | 日期 | 变化 |
|---|---|---|
| 0.1.0 | $today | 首版（骨架） |
EOF
log_ok "README.md"

# ---- templates（从 pl-core 复制基线 3 个） ----
for tpl in spec plan taskdag; do
  src="$PL_ASSETS/pl/templates/${tpl}.md"
  dst="$DEST/templates/${tpl}.md"
  if [[ -f "$src" ]]; then
    cp "$src" "$dst"
    log_ok "templates/${tpl}.md (copied from pl-core baseline)"
  else
    log_warn "pl-core template not found: $src"
    echo "# $tpl template — TODO: fill in" > "$dst"
  fi
done

# ---- case-study 占位 ----
cat > "$DEST/docs/case-study.md" <<EOF
# Case Study: 在 <demo-project> 中接入 adapter-$ADAPTER_ID

> TODO: 用一个示例工程说明从 \`/pl:proposal\` 到 \`/pl:archive\` 的全流程。

## 0. 前置

TODO

## 1. SPEC — /pl:proposal

TODO

## 2. PLAN — /pl:plan

TODO

## 3. IMPLEMENT — /pl:implement

TODO

## 4. VERIFY — /pl:verify

TODO

## 5. ARCHIVE — /pl:archive

TODO
EOF
log_ok "docs/case-study.md (stub)"

# ---- full 模式下的占位文件 ----
if [[ "$MODE" == "full" ]]; then
  cat > "$DEST/agents/${ADAPTER_ID}-architect.md" <<EOF
---
name: ${ADAPTER_ID}-architect
description: TODO: 本 adapter 场景的架构师描述。
ide_support: [codebuddy, cursor, claude-code]
---

# ${ADAPTER_ID} 架构师

你是 **${ADAPTER_ID} 架构师**。在 \`/pl:plan\` 阶段协助团队做出决策。

## 你必须回答的 N 个问题

TODO: 列出在此技术栈下 PLAN 必答的核心问题。

## 输出格式

TODO

## 禁忌

TODO
EOF
  log_ok "agents/${ADAPTER_ID}-architect.md (stub)"

  cat > "$DEST/skills/${ADAPTER_ID}-basics.md" <<EOF
---
name: ${ADAPTER_ID}-basics
triggers: ["TODO-keyword1", "TODO-keyword2"]
description: TODO: 本 skill 解决的问题。
---

# ${ADAPTER_ID} 基础

TODO: 该 skill 提供的知识点 / 示例代码 / 常见坑位。
EOF
  log_ok "skills/${ADAPTER_ID}-basics.md (stub)"

  cat > "$DEST/rules/${ADAPTER_ID}-conventions.md" <<EOF
# Rule: ${ADAPTER_ID} 约定

> **Scope**: always

TODO: 本 adapter 对编码规范的硬性要求。
EOF
  log_ok "rules/${ADAPTER_ID}-conventions.md (stub)"

  for s in build verify lint; do
    cat > "$DEST/scripts/${s}.sh" <<EOF
#!/usr/bin/env bash
# adapter-${ADAPTER_ID} ${s}.sh
set -euo pipefail

SCRIPT_DIR="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="\$(cd "\$SCRIPT_DIR/.." && pwd)"
cd "\$PROJECT_ROOT"

echo "▶ ${ADAPTER_ID} ${s} @ \$PROJECT_ROOT"

# TODO: 实现 ${s} 逻辑
echo "TODO: implement ${s}"
exit 0
EOF
    chmod +x "$DEST/scripts/${s}.sh"
    log_ok "scripts/${s}.sh (stub, executable)"
  done
fi

# ---- 自检 ----
echo ""
echo "${BOLD}━━━ Self-check ━━━${NC}"
if bash "$(dirname "${BASH_SOURCE[0]}")/adapter-validate.sh" "$DEST" >/dev/null 2>&1; then
  log_ok "adapter-validate passed"
else
  log_warn "adapter-validate reports issues (expected for --full stubs)"
  log_info "  run: pl adapter validate $DEST"
fi

# ---- 总结 ----
echo ""
echo "${BOLD}━━━ Next steps ━━━${NC}"
cat <<EOF
  1. 编辑 ${DIM}$DEST/adapter.yaml${NC}
     - 填写 metadata.name / description
     - 启用 detect 规则让 pl init --smart 能识别
     - 按需启用 provides.{agents,skills,rules,scripts,build_adapter}

  2. 定制 ${DIM}$DEST/templates/{spec,plan,taskdag}.md${NC}
     基线来自 pl-core，按本技术栈场景调整字段和示例

  3. 扩展资产
     - 为架构决策点编写 ${DIM}agents/*.md${NC}（RSC/事务/缓存…之类）
     - 为易错点编写 ${DIM}skills/*.md${NC}
     - 为编码规范编写 ${DIM}rules/*.md${NC}
     - 为 build/verify/lint 编写 ${DIM}scripts/*.sh${NC}

  4. 校验
     ${BOLD}pl adapter validate $DEST${NC}

  5. 在空项目试装
     ${BOLD}pl adapter install --dry-run $DEST <target-project>${NC}

  6. 写 docs/case-study.md 用真实工程跑一次端到端
EOF

echo ""
log_ok "adapter-$ADAPTER_ID v0.1.0 scaffold ready at $DEST"
