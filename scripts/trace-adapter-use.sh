#!/usr/bin/env bash
# =============================================================================
# trace-adapter-use.sh — Consumer→Adapter 能力消费记录 CLI
# =============================================================================
#
# 给 agent / 脚本 / hook 提供一个无须 source 的命令行入口，把"本次 change
# 实际使用了 adapter 哪个资产"作为事实事件写入 trace。
#
# 这是 v1.6 引入的最小观测层：只记录、不阻塞、不校验。
# 后续可由 broker 脚本（如 pl-contract-aggregate.sh）聚合产 consumer pact。
#
# 用法:
#   trace-adapter-use.sh --change <id> --kind <asset_kind> --id <asset_id> \
#                        [--phase <STAGE>] [--by <actor>] [--note <text>]
#
# 参数:
#   --change   change-id（必填，对应 pl/changes/<id>/）
#   --kind     资产类型（必填）：skill | rule | template | agent | build_command | capability
#   --id       资产标识（必填，如 "react-server-components"）
#   --phase    当前阶段（可选）：SPEC | PLAN | IMPLEMENT | VERIFY | SMOKE | OBSERVE | ARCHIVE
#   --by       事件产生者（可选，默认 "agent:unknown"）
#   --note     可选附加说明（写入 data.note）
#
# 示例（agent 在 IMPLEMENT 阶段调用 react-server-components skill 后）:
#   bash $PL_HOME/scripts/trace-adapter-use.sh \
#     --change add-user-login \
#     --kind skill \
#     --id react-server-components \
#     --phase IMPLEMENT \
#     --by "agent:nextjs-architect"
#
# 退出码:
#   0 = 已写入
#   2 = 参数错误
# =============================================================================

# shellcheck source=./_env.sh
source "$(dirname "${BASH_SOURCE[0]}")/_env.sh"
# shellcheck source=./trace-emit.sh
source "$(dirname "${BASH_SOURCE[0]}")/trace-emit.sh"
set -uo pipefail

CHANGE=""
KIND=""
ASSET_ID=""
PHASE=""
BY=""
NOTE=""

usage() {
  sed -n '2,32p' "$0" | sed 's/^# \{0,1\}//'
  exit 2
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --change) CHANGE="$2"; shift 2 ;;
    --kind)   KIND="$2"; shift 2 ;;
    --id)     ASSET_ID="$2"; shift 2 ;;
    --phase)  PHASE="$2"; shift 2 ;;
    --by)     BY="$2"; shift 2 ;;
    --note)   NOTE="$2"; shift 2 ;;
    -h|--help) usage ;;
    *) echo "Unknown option: $1" >&2; usage ;;
  esac
done

[[ -z "$CHANGE" ]]   && { echo "Missing --change <id>" >&2; usage; }
[[ -z "$KIND" ]]     && { echo "Missing --kind <asset_kind>" >&2; usage; }
[[ -z "$ASSET_ID" ]] && { echo "Missing --id <asset_id>" >&2; usage; }

case "$KIND" in
  skill|rule|template|agent|build_command|capability) ;;
  *) echo "Invalid --kind '$KIND' (allowed: skill|rule|template|agent|build_command|capability)" >&2; exit 2 ;;
esac

trace_init "$CHANGE" "${PHASE:-}" "${BY:-agent:unknown}"

extra='{}'
if [[ -n "$NOTE" ]]; then
  extra=$(jq -cn --arg n "$NOTE" '{note:$n}')
fi

trace_adapter_use "$KIND" "$ASSET_ID" "$extra"
echo "ok: adapter.use recorded → $(trace_file)"
