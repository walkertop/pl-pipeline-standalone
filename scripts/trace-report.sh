#!/usr/bin/env bash
# =============================================================================
# trace-report.sh — Pipeline Trace HTML 报告生成器
# =============================================================================
#
# 从 build/trace/{page_id}.events.jsonl 读取事件，生成交互式 HTML 报告。
#
# 用法:
#   ./scripts/trace-report.sh --page order_detail
#   ./scripts/trace-report.sh --page order_detail --trace-id order_detail_20260410_220000
#   ./scripts/trace-report.sh --page order_detail --open
#
# 输出: pipeline-output/trace/{page_id}-report.html
#
# =============================================================================

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TRACE_DIR="$PROJECT_ROOT/build/trace"

# ---- 颜色 -------------------------------------------------------------------
RED='\033[0;31m'; GREEN='\033[0;32m'; BLUE='\033[0;34m'; NC='\033[0m'

# ---- 参数解析 ----------------------------------------------------------------
PAGE_ID=""
TRACE_ID_FILTER=""
OPEN_AFTER=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --page)     PAGE_ID="$2"; shift 2 ;;
    --trace-id) TRACE_ID_FILTER="$2"; shift 2 ;;
    --open)     OPEN_AFTER=true; shift ;;
    -h|--help)
      echo "用法: ./scripts/trace-report.sh --page <page_id> [--trace-id <id>] [--open]"
      exit 0 ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

[[ -z "$PAGE_ID" ]] && { echo -e "${RED}Error: --page required${NC}"; exit 1; }

EVENTS_FILE="$TRACE_DIR/${PAGE_ID}.events.jsonl"
OUTPUT_FILE="$TRACE_DIR/${PAGE_ID}-report.html"

if [[ ! -f "$EVENTS_FILE" ]]; then
  echo -e "${RED}No events found at $EVENTS_FILE${NC}"
  exit 1
fi

# ---- 准备事件数据 -------------------------------------------------------------

# 过滤 trace_id (如果指定)
if [[ -n "$TRACE_ID_FILTER" ]]; then
  EVENTS_JSON=$(jq -s "[.[] | select(.trace_id == \"$TRACE_ID_FILTER\")]" "$EVENTS_FILE")
else
  EVENTS_JSON=$(jq -s '.' "$EVENTS_FILE")
fi

EVENT_COUNT=$(echo "$EVENTS_JSON" | jq 'length')
if [[ "$EVENT_COUNT" -eq 0 ]]; then
  echo -e "${RED}No events match the filter${NC}"
  exit 1
fi

# 提取摘要
ERROR_COUNT=$(echo "$EVENTS_JSON" | jq '[.[] | select(.event == "error" or (.event == "check.run" and .data.status == "fail") or (.event == "phase.end" and .data.status == "fail"))] | length')
WARN_COUNT=$(echo "$EVENTS_JSON" | jq '[.[] | select(.event == "check.run" and .data.status == "warn") or (.event == "phase.end" and .data.status == "warn")] | length')
PHASE_COUNT=$(echo "$EVENTS_JSON" | jq '[.[].phase] | unique | length')
FIRST_TS=$(echo "$EVENTS_JSON" | jq -r '.[0].ts // "N/A"')
LAST_TS=$(echo "$EVENTS_JSON" | jq -r '.[-1].ts // "N/A"')
TRACE_IDS=$(echo "$EVENTS_JSON" | jq -r '[.[].trace_id] | unique | join(", ")')

# 阶段状态（使用 jq 计算，避免 bash 3.x 不支持关联数组）
ALL_STAGES="SPEC PLAN IMPLEMENT VERIFY OBSERVE ARCHIVE"

# 用 jq 一次性计算所有阶段状态
STAGE_STATUS_JSON=$(echo "$EVENTS_JSON" | jq -c '
  # 收集所有 phase.start 和 phase.end 事件
  reduce .[] as $e (
    {"SPEC":"pending","PLAN":"pending","IMPLEMENT":"pending","VERIFY":"pending","OBSERVE":"pending","ARCHIVE":"pending"};
    if $e.event == "phase.start" then
      # 提取纯阶段名（去掉 VERIFY:LINT 等子阶段前缀）
      ($e.phase | split(":")[0]) as $phase |
      if .[$phase] == "pending" then .[$phase] = "active" else . end
    elif $e.event == "phase.end" then
      ($e.phase | split(":")[0]) as $phase |
      if $e.data.status then .[$phase] = $e.data.status else . end
    else . end
  )
')

# 获取单个阶段状态的辅助函数
get_stage_status() {
  echo "$STAGE_STATUS_JSON" | jq -r --arg s "$1" '.[$s] // "pending"'
}

# ---- 生成 HTML ---------------------------------------------------------------

# 将事件 JSON 转义后嵌入 HTML（让 JS 端处理渲染）
EVENTS_JSON_ESCAPED=$(echo "$EVENTS_JSON" | jq -c '.')

cat > "$OUTPUT_FILE" << 'HTMLHEAD'
<!DOCTYPE html>
<html lang="zh-CN">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Pipeline Trace Report</title>
<style>
:root {
  --bg: #0d1117; --bg2: #161b22; --bg3: #1c2129;
  --border: #30363d; --border-light: #484f58;
  --text: #e6edf3; --text-dim: #8b949e; --text-dimmer: #656d76;
  --accent: #58a6ff; --green: #3fb950; --yellow: #d29922;
  --red: #f85149; --purple: #bc8cff; --cyan: #39d2c0;
  --orange: #f0883e;
  --radius: 8px; --radius-sm: 4px;
}
* { box-sizing: border-box; margin: 0; padding: 0; }
body {
  font-family: -apple-system, 'SF Pro Text', 'Helvetica Neue', system-ui, sans-serif;
  background: var(--bg); color: var(--text);
  line-height: 1.5; padding: 0;
}
a { color: var(--accent); text-decoration: none; }
a:hover { text-decoration: underline; }

/* Layout */
.container { max-width: 1200px; margin: 0 auto; padding: 24px; }

/* Header */
.header {
  background: linear-gradient(135deg, #161b22 0%, #1a2332 100%);
  border-bottom: 1px solid var(--border);
  padding: 32px 24px;
  margin-bottom: 0;
}
.header-inner { max-width: 1200px; margin: 0 auto; }
.header h1 { font-size: 22px; font-weight: 600; margin-bottom: 6px; display: flex; align-items: center; gap: 10px; }
.header .meta { color: var(--text-dim); font-size: 13px; display: flex; gap: 16px; flex-wrap: wrap; }
.header .meta span { display: flex; align-items: center; gap: 4px; }

/* Summary Cards */
.summary {
  display: grid; grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
  gap: 12px; padding: 20px 0;
}
.card {
  background: var(--bg2); border: 1px solid var(--border);
  border-radius: var(--radius); padding: 16px;
  transition: border-color 0.15s;
}
.card:hover { border-color: var(--border-light); }
.card .label { font-size: 11px; color: var(--text-dim); text-transform: uppercase; letter-spacing: 0.5px; margin-bottom: 6px; }
.card .value { font-size: 32px; font-weight: 700; line-height: 1; }
.card .value.ok { color: var(--green); }
.card .value.warn { color: var(--yellow); }
.card .value.fail { color: var(--red); }
.card .value.neutral { color: var(--text); }

/* Pipeline Progress */
.pipeline-section { padding: 20px 0; }
.pipeline-section h2 { font-size: 15px; font-weight: 600; margin-bottom: 12px; color: var(--text-dim); }
.pipeline {
  display: flex; gap: 6px; align-items: center; flex-wrap: wrap;
  padding: 16px; background: var(--bg2); border: 1px solid var(--border);
  border-radius: var(--radius);
}
.stage {
  padding: 8px 20px; border-radius: 6px;
  font-size: 12px; font-weight: 600; letter-spacing: 0.3px;
  position: relative; transition: all 0.15s;
}
.stage.pass  { background: var(--green); color: #000; }
.stage.active { background: var(--accent); color: #000; animation: pulse 2s ease-in-out infinite; }
.stage.fail, .stage.blocked { background: var(--red); color: #fff; }
.stage.warn  { background: var(--yellow); color: #000; }
.stage.skip  { background: var(--bg3); color: var(--text-dimmer); border: 1px solid var(--border); }
.stage.pending { background: var(--bg3); color: var(--text-dimmer); border: 1px dashed var(--border); }
.stage.awaiting_agent { background: var(--purple); color: #000; animation: pulse 2s ease-in-out infinite; }
.arrow { color: var(--text-dimmer); font-size: 14px; }

@keyframes pulse {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.7; }
}

/* Tabs */
.tabs { display: flex; gap: 0; border-bottom: 1px solid var(--border); margin-top: 8px; }
.tab {
  padding: 10px 20px; font-size: 13px; font-weight: 500;
  color: var(--text-dim); cursor: pointer; border-bottom: 2px solid transparent;
  transition: all 0.15s; background: none; border-top: none; border-left: none; border-right: none;
}
.tab:hover { color: var(--text); }
.tab.active { color: var(--accent); border-bottom-color: var(--accent); }
.tab-panel { display: none; padding: 20px 0; }
.tab-panel.active { display: block; }

/* Timeline */
.timeline { position: relative; padding-left: 28px; }
.timeline::before {
  content: ''; position: absolute; left: 11px; top: 0; bottom: 0;
  width: 2px; background: var(--border);
}
.evt {
  position: relative; margin-bottom: 8px; padding: 10px 14px;
  background: var(--bg2); border: 1px solid var(--border);
  border-radius: var(--radius); transition: border-color 0.15s;
  cursor: pointer;
}
.evt:hover { border-color: var(--border-light); }
.evt::before {
  content: ''; position: absolute; left: -22px; top: 14px;
  width: 8px; height: 8px; border-radius: 50%;
}
.evt.phase-evt::before { background: var(--accent); }
.evt.gate-evt::before  { background: var(--purple); }
.evt.task-evt::before   { background: var(--green); }
.evt.check-evt::before  { background: var(--yellow); }
.evt.error-evt::before  { background: var(--red); }
.evt.runtime-evt::before { background: var(--text-dimmer); }
.evt.artifact-evt::before { background: var(--cyan); }
.evt.workflow-evt::before { background: var(--orange); }

.evt-header { display: flex; justify-content: space-between; align-items: center; gap: 8px; }
.evt-type {
  font-size: 10px; font-weight: 700; text-transform: uppercase;
  padding: 2px 6px; border-radius: var(--radius-sm); letter-spacing: 0.5px;
  white-space: nowrap;
}
.evt-type.phase    { background: rgba(88,166,255,0.15); color: var(--accent); }
.evt-type.gate     { background: rgba(188,140,255,0.15); color: var(--purple); }
.evt-type.task     { background: rgba(63,185,80,0.15); color: var(--green); }
.evt-type.check    { background: rgba(210,153,34,0.15); color: var(--yellow); }
.evt-type.error    { background: rgba(248,81,73,0.15); color: var(--red); }
.evt-type.runtime  { background: rgba(139,148,158,0.12); color: var(--text-dim); }
.evt-type.artifact { background: rgba(57,210,192,0.15); color: var(--cyan); }
.evt-type.workflow { background: rgba(240,136,62,0.15); color: var(--orange); }

.evt-ts { color: var(--text-dimmer); font-size: 11px; font-family: 'SF Mono', monospace; white-space: nowrap; }
.evt-actor { color: var(--text-dim); font-size: 11px; margin-top: 2px; }
.evt-data {
  display: none; font-family: 'SF Mono', monospace; font-size: 11px;
  color: var(--text-dim); background: var(--bg); padding: 8px 10px;
  border-radius: var(--radius-sm); margin-top: 8px; white-space: pre-wrap; word-break: break-all;
  border: 1px solid var(--border);
}
.evt.expanded .evt-data { display: block; }

/* Phase filter pills */
.filters { display: flex; gap: 6px; flex-wrap: wrap; padding: 12px 0; }
.pill {
  padding: 4px 12px; border-radius: 20px; font-size: 11px; font-weight: 500;
  background: var(--bg2); border: 1px solid var(--border); color: var(--text-dim);
  cursor: pointer; transition: all 0.15s;
}
.pill:hover { border-color: var(--border-light); color: var(--text); }
.pill.active { background: var(--accent); color: #000; border-color: var(--accent); }

/* Check Results Table */
.checks-table {
  width: 100%; border-collapse: collapse;
  background: var(--bg2); border-radius: var(--radius); overflow: hidden;
  border: 1px solid var(--border);
}
.checks-table th {
  text-align: left; padding: 10px 14px; font-size: 11px;
  text-transform: uppercase; color: var(--text-dim); background: var(--bg3);
  border-bottom: 1px solid var(--border); letter-spacing: 0.5px;
}
.checks-table td {
  padding: 10px 14px; font-size: 13px;
  border-bottom: 1px solid var(--border);
}
.checks-table tr:last-child td { border-bottom: none; }
.status-badge {
  display: inline-block; padding: 2px 8px; border-radius: var(--radius-sm);
  font-size: 11px; font-weight: 600;
}
.status-badge.pass { background: rgba(63,185,80,0.15); color: var(--green); }
.status-badge.fail { background: rgba(248,81,73,0.15); color: var(--red); }
.status-badge.warn { background: rgba(210,153,34,0.15); color: var(--yellow); }
.status-badge.skip { background: rgba(139,148,158,0.12); color: var(--text-dim); }

/* No data */
.empty { text-align: center; padding: 40px; color: var(--text-dimmer); font-size: 14px; }

/* Footer */
.footer { text-align: center; padding: 24px 0; color: var(--text-dimmer); font-size: 12px; border-top: 1px solid var(--border); margin-top: 32px; }
</style>
</head>
<body>
HTMLHEAD

# ---- Header ----
cat >> "$OUTPUT_FILE" << EOF
<div class="header">
  <div class="header-inner">
    <h1>🔍 Pipeline Trace Report</h1>
    <div class="meta">
      <span>📄 Page: <strong>${PAGE_ID}</strong></span>
      <span>🏷 Trace: ${TRACE_IDS}</span>
      <span>📊 Events: ${EVENT_COUNT}</span>
      <span>🕐 ${FIRST_TS} → ${LAST_TS}</span>
    </div>
  </div>
</div>

<div class="container">
EOF

# ---- Summary Cards ----
OVERALL_CLASS="ok"
if [[ "$ERROR_COUNT" -gt 0 ]]; then
  OVERALL_CLASS="fail"
elif [[ "$WARN_COUNT" -gt 0 ]]; then
  OVERALL_CLASS="warn"
fi

cat >> "$OUTPUT_FILE" << EOF
<div class="summary">
  <div class="card">
    <div class="label">总事件数</div>
    <div class="value neutral">${EVENT_COUNT}</div>
  </div>
  <div class="card">
    <div class="label">覆盖阶段</div>
    <div class="value neutral">${PHASE_COUNT}</div>
  </div>
  <div class="card">
    <div class="label">错误</div>
    <div class="value ${OVERALL_CLASS}">${ERROR_COUNT}</div>
  </div>
  <div class="card">
    <div class="label">警告</div>
    <div class="value $([[ "$WARN_COUNT" -gt 0 ]] && echo "warn" || echo "ok")">${WARN_COUNT}</div>
  </div>
  <div class="card">
    <div class="label">整体状态</div>
    <div class="value ${OVERALL_CLASS}">$(
      if [[ "$ERROR_COUNT" -gt 0 ]]; then echo "FAIL"
      elif [[ "$WARN_COUNT" -gt 0 ]]; then echo "WARN"
      else echo "PASS"
      fi
    )</div>
  </div>
</div>
EOF

# ---- Pipeline Progress Bar ----
echo '<div class="pipeline-section">' >> "$OUTPUT_FILE"
echo '<h2>PIPELINE PROGRESS</h2>' >> "$OUTPUT_FILE"
echo '<div class="pipeline">' >> "$OUTPUT_FILE"

idx=0
for s in $ALL_STAGES; do
  cls=$(get_stage_status "$s")
  [[ $idx -gt 0 ]] && echo '<span class="arrow">→</span>' >> "$OUTPUT_FILE"
  echo "<span class=\"stage ${cls}\">${s}</span>" >> "$OUTPUT_FILE"
  idx=$((idx + 1))
done

echo '</div></div>' >> "$OUTPUT_FILE"

# ---- Tabs ----
cat >> "$OUTPUT_FILE" << 'TABS'
<div class="tabs">
  <button class="tab active" data-tab="timeline">📋 时间线</button>
  <button class="tab" data-tab="checks">✅ 检查结果</button>
  <button class="tab" data-tab="raw">{ } 原始数据</button>
</div>
TABS

# ---- Tab: Timeline ----
echo '<div class="tab-panel active" id="panel-timeline">' >> "$OUTPUT_FILE"

# Phase filter pills
echo '<div class="filters">' >> "$OUTPUT_FILE"
echo '<span class="pill active" data-filter="all">全部</span>' >> "$OUTPUT_FILE"
for s in $ALL_STAGES; do
  has_events=$(echo "$EVENTS_JSON" | jq "[.[] | select(.phase | startswith(\"$s\"))] | length")
  if [[ "$has_events" -gt 0 ]]; then
    echo "<span class=\"pill\" data-filter=\"${s}\">${s} (${has_events})</span>" >> "$OUTPUT_FILE"
  fi
done
echo '</div>' >> "$OUTPUT_FILE"

# Timeline events
echo '<div class="timeline" id="event-timeline">' >> "$OUTPUT_FILE"

echo "$EVENTS_JSON" | jq -c '.[]' | while IFS= read -r evt; do
  evt_type=$(echo "$evt" | jq -r '.event')
  ts=$(echo "$evt" | jq -r '.ts')
  actor=$(echo "$evt" | jq -r '.actor')
  phase=$(echo "$evt" | jq -r '.phase')
  data_str=$(echo "$evt" | jq -c '.data')
  data_pretty=$(echo "$evt" | jq '.data')

  # CSS class
  case "$evt_type" in
    phase.*)    evt_class="phase-evt"; type_class="phase" ;;
    gate.*)     evt_class="gate-evt"; type_class="gate" ;;
    task.*)     evt_class="task-evt"; type_class="task" ;;
    check.*)    evt_class="check-evt"; type_class="check" ;;
    error)      evt_class="error-evt"; type_class="error" ;;
    runtime.*)  evt_class="runtime-evt"; type_class="runtime" ;;
    artifact.*) evt_class="artifact-evt"; type_class="artifact" ;;
    workflow.*) evt_class="workflow-evt"; type_class="workflow" ;;
    *)          evt_class="runtime-evt"; type_class="runtime" ;;
  esac

  # Escape HTML in data
  data_html=$(echo "$data_pretty" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')

  cat >> "$OUTPUT_FILE" << EVTEOF
<div class="evt ${evt_class}" data-phase="${phase}">
  <div class="evt-header">
    <div style="display:flex;align-items:center;gap:8px;">
      <span class="evt-type ${type_class}">${evt_type}</span>
      <span class="evt-actor">${phase} · ${actor}</span>
    </div>
    <span class="evt-ts">${ts}</span>
  </div>
  <div class="evt-data"><pre>${data_html}</pre></div>
</div>
EVTEOF
done

echo '</div></div>' >> "$OUTPUT_FILE"

# ---- Tab: Checks ----
echo '<div class="tab-panel" id="panel-checks">' >> "$OUTPUT_FILE"

CHECK_EVENTS=$(echo "$EVENTS_JSON" | jq -c '[.[] | select(.event == "check.run")]')
CHECK_COUNT=$(echo "$CHECK_EVENTS" | jq 'length')

if [[ "$CHECK_COUNT" -gt 0 ]]; then
  cat >> "$OUTPUT_FILE" << 'TBLHEAD'
<table class="checks-table">
  <thead><tr><th>检查项</th><th>状态</th><th>阶段</th><th>执行者</th><th>详情</th></tr></thead>
  <tbody>
TBLHEAD

  echo "$CHECK_EVENTS" | jq -c '.[]' | while IFS= read -r chk; do
    checker=$(echo "$chk" | jq -r '.data.checker // "unknown"')
    status=$(echo "$chk" | jq -r '.data.status // "unknown"')
    phase=$(echo "$chk" | jq -r '.phase')
    actor=$(echo "$chk" | jq -r '.actor')
    details=$(echo "$chk" | jq -c 'del(.data.checker, .data.status) | .data' | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')

    cat >> "$OUTPUT_FILE" << ROWEOF
    <tr>
      <td><strong>${checker}</strong></td>
      <td><span class="status-badge ${status}">${status}</span></td>
      <td>${phase}</td>
      <td style="color:var(--text-dim)">${actor}</td>
      <td style="font-family:monospace;font-size:11px;color:var(--text-dim)">${details}</td>
    </tr>
ROWEOF
  done

  echo '</tbody></table>' >> "$OUTPUT_FILE"
else
  echo '<div class="empty">暂无检查结果事件</div>' >> "$OUTPUT_FILE"
fi

echo '</div>' >> "$OUTPUT_FILE"

# ---- Tab: Raw Data ----
RAW_HTML=$(echo "$EVENTS_JSON" | jq '.' | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')
cat >> "$OUTPUT_FILE" << RAWEOF
<div class="tab-panel" id="panel-raw">
  <div style="background:var(--bg2);border:1px solid var(--border);border-radius:var(--radius);padding:16px;overflow-x:auto;">
    <pre style="font-family:'SF Mono',monospace;font-size:12px;color:var(--text-dim);white-space:pre-wrap;">${RAW_HTML}</pre>
  </div>
</div>
RAWEOF

# ---- Footer ----
cat >> "$OUTPUT_FILE" << EOF
<div class="footer">
  Pipeline Trace System · Generated $(date '+%Y-%m-%d %H:%M:%S') · ${EVENT_COUNT} events
</div>
</div>
EOF

# ---- JavaScript ----
cat >> "$OUTPUT_FILE" << 'JSEOF'
<script>
// Tab switching
document.querySelectorAll('.tab').forEach(tab => {
  tab.addEventListener('click', () => {
    document.querySelectorAll('.tab').forEach(t => t.classList.remove('active'));
    document.querySelectorAll('.tab-panel').forEach(p => p.classList.remove('active'));
    tab.classList.add('active');
    document.getElementById('panel-' + tab.dataset.tab).classList.add('active');
  });
});

// Event expand/collapse
document.querySelectorAll('.evt').forEach(evt => {
  evt.addEventListener('click', () => {
    evt.classList.toggle('expanded');
  });
});

// Phase filter
document.querySelectorAll('.pill').forEach(pill => {
  pill.addEventListener('click', () => {
    document.querySelectorAll('.pill').forEach(p => p.classList.remove('active'));
    pill.classList.add('active');
    const filter = pill.dataset.filter;
    document.querySelectorAll('.evt').forEach(evt => {
      if (filter === 'all' || evt.dataset.phase === filter) {
        evt.style.display = '';
      } else {
        evt.style.display = 'none';
      }
    });
  });
});
</script>
JSEOF

echo '</body></html>' >> "$OUTPUT_FILE"

echo -e "${GREEN}✅${NC} 报告已生成: ${OUTPUT_FILE}"

# 自动打开
if $OPEN_AFTER; then
  if command -v open &>/dev/null; then
    open "$OUTPUT_FILE"
  elif command -v xdg-open &>/dev/null; then
    xdg-open "$OUTPUT_FILE"
  fi
fi
