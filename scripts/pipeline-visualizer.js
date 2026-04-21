#!/usr/bin/env node
/**
 * Pipeline Visualizer - KMV 日志可视化诊断工具
 *
 * 功能：
 *   1. 解析 KMV Pipeline 日志（从文件或 stdin 输入）
 *   2. 生成交互式 HTML 诊断报告
 *   3. 可视化数据流各阶段：NETWORK → PARSE → DATA_UNWRAP → KEY_FIELDS → DELIVER → STATE
 *   4. 自动标记问题节点并给出诊断建议
 *
 * 使用方式：
 *   # 从文件输入
 *   node scripts/pipeline-visualizer.js --file /path/to/logcat.txt
 *
 *   # 从 stdin 管道输入（如 pbpaste）
 *   pbpaste | node scripts/pipeline-visualizer.js
 *
 *   # 指定输出目录 + 自动打开
 *   node scripts/pipeline-visualizer.js --file log.txt --output pipeline-output/diagnose/ --open
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

// ── 参数解析 ──
const args = process.argv.slice(2);
let inputFile = '';
let outputDir = path.join(__dirname, '..', 'pipeline-output', 'diagnose');
let openAfter = false;

for (let i = 0; i < args.length; i++) {
  switch (args[i]) {
    case '--file': inputFile = args[++i]; break;
    case '--output': outputDir = args[++i]; break;
    case '--open': openAfter = true; break;
    case '-h': case '--help':
      console.log(`
Usage: node pipeline-visualizer.js [OPTIONS]

OPTIONS:
  --file <path>     从文件读取日志
  --output <dir>    输出目录 (默认: pipeline-output/diagnose/)
  --open            生成后自动打开 HTML
  -h, --help        显示帮助

  不带 --file 时从 stdin 读取（可配合 pbpaste | 使用）
`);
      process.exit(0);
  }
}

// ── 读取日志 ──
let rawLog;
if (inputFile) {
  if (!fs.existsSync(inputFile)) {
    console.error(`❌ File not found: ${inputFile}`);
    process.exit(1);
  }
  rawLog = fs.readFileSync(inputFile, 'utf8');
} else {
  rawLog = fs.readFileSync(0, 'utf8'); // stdin
}

// 只保留 KMV 日志行
const kmvLines = rawLog.split('\n').filter(l => l.includes('[KMV:'));
if (kmvLines.length === 0) {
  console.error('⚠️  No KMV log lines found. Logs must contain [KMV:...] patterns.');
  process.exit(1);
}
console.log(`✅ Extracted ${kmvLines.length} KMV log lines`);

// ── 按 session 分组 ──
const sessions = {};
for (const line of kmvLines) {
  const m = line.match(/\[KMV:(\w+):(\w+)\]\s*(\w)\s*\|\s*(.*)/);
  if (!m) continue;
  const [, category, sessionId, level, message] = m;
  const tsMatch = line.match(/\|(\d{2}:\d{2}\.\d{2}\.\d{3})\|/);
  const timestamp = tsMatch ? tsMatch[1] : '';

  if (!sessions[sessionId]) {
    sessions[sessionId] = { id: sessionId, events: [], startTime: timestamp };
  }
  sessions[sessionId].events.push({ category, level, message: message.trim(), timestamp, raw: line });
}

// ── 分析每个 session ──
function analyzeSession(session) {
  const analysis = {
    id: session.id,
    events: session.events,
    stages: {},
    problems: [],
    diagnosis: '',
    overallStatus: 'success',
    service: '',
    dataSize: '',
    fetchDuration: ''
  };

  const stageNames = ['NETWORK', 'PARSE', 'DATA_UNWRAP', 'KEY_FIELDS', 'DELIVER', 'STATE'];
  for (const name of stageNames) {
    analysis.stages[name] = { status: 'pending', events: [], duration: null };
  }

  for (const evt of session.events) {
    const cat = evt.category;
    const msg = evt.message;

    if (cat === 'NETWORK') {
      analysis.stages.NETWORK.events.push(evt);
      if (msg.startsWith('START ')) {
        analysis.stages.NETWORK.status = 'running';
        analysis.service = msg.replace('START ', '').split(' ')[0];
      }
      if (msg.includes('fetch:')) {
        const durMatch = msg.match(/(\d+)ms/);
        if (durMatch) analysis.fetchDuration = durMatch[1];
      }
      if (msg.startsWith('SUCCESS')) {
        analysis.stages.NETWORK.status = 'success';
        analysis.stages.NETWORK.duration = analysis.fetchDuration + 'ms';
        const sizeMatch = msg.match(/dataSize=(\d+)/);
        if (sizeMatch) analysis.dataSize = sizeMatch[1];
      }
      if (msg.startsWith('ERROR') || msg.startsWith('FAIL')) {
        analysis.stages.NETWORK.status = 'error';
        analysis.problems.push({ stage: 'NETWORK', message: msg, severity: 'error' });
      }
    }

    if (cat === 'PARSE') {
      if (msg.includes('UNPACK')) {
        analysis.stages.PARSE.events.push(evt);
        if (msg.startsWith('SUCCESS')) analysis.stages.PARSE.status = 'success';
        if (msg.startsWith('ERROR')) {
          analysis.stages.PARSE.status = 'error';
          analysis.problems.push({ stage: 'PARSE', message: msg, severity: 'error' });
        }
      }
      if (msg.startsWith('DATA_UNWRAP')) {
        analysis.stages.DATA_UNWRAP.events.push(evt);
        if (msg.includes('extracted data layer')) {
          analysis.stages.DATA_UNWRAP.status = 'success';
          const sizeMatch = msg.match(/payloadSize=(\d+)/);
          if (sizeMatch) analysis.stages.DATA_UNWRAP.payloadSize = sizeMatch[1];
        }
        if (msg.includes("no 'data' field")) {
          analysis.stages.DATA_UNWRAP.status = 'warning';
          analysis.problems.push({ stage: 'DATA_UNWRAP', message: '响应没有 data 字段，使用原始响应', severity: 'warning' });
        }
      }
      if (msg.startsWith('KEY_FIELDS')) {
        analysis.stages.KEY_FIELDS.events.push(evt);
        analysis.stages.KEY_FIELDS.status = 'success';
        const presentMatch = msg.match(/present=\[([^\]]*)\]/);
        if (presentMatch) analysis.stages.KEY_FIELDS.present = presentMatch[1].split(', ');
      }
      if (msg.startsWith('MISSING')) {
        analysis.stages.KEY_FIELDS.events.push(evt);
        analysis.stages.KEY_FIELDS.status = 'warning';
        const fieldMatch = msg.match(/field=(\w+)/);
        if (fieldMatch) {
          if (!analysis.stages.KEY_FIELDS.missing) analysis.stages.KEY_FIELDS.missing = [];
          analysis.stages.KEY_FIELDS.missing.push(fieldMatch[1]);
          analysis.problems.push({ stage: 'KEY_FIELDS', message: '缺失业务字段: ' + fieldMatch[1], severity: 'warning' });
        }
      }
    }

    if (cat === 'STATE') {
      if (msg.startsWith('DELIVER')) {
        analysis.stages.DELIVER.events.push(evt);
        analysis.stages.DELIVER.status = msg.includes('success=true') ? 'success' : 'error';
        if (msg.includes('success=false')) {
          analysis.problems.push({ stage: 'DELIVER', message: msg, severity: 'error' });
        }
      }
      if (msg.startsWith('UI_')) {
        analysis.stages.STATE.events.push(evt);
        analysis.stages.STATE.status = 'success';

        if (msg.startsWith('UI_FINAL')) {
          const isLoading = msg.match(/isLoading=(\w+)/);
          const showError = msg.match(/showError=(\w+)/);
          const propStatus = msg.match(/propStatus=(\d+)/);
          if (isLoading && isLoading[1] === 'true') {
            analysis.problems.push({ stage: 'STATE', message: 'UI 仍在加载状态 (isLoading=true)', severity: 'error' });
            analysis.stages.STATE.status = 'error';
          }
          if (showError && showError[1] === 'true') {
            analysis.problems.push({ stage: 'STATE', message: 'UI 显示错误状态 (showError=true)', severity: 'error' });
            analysis.stages.STATE.status = 'error';
          }
          if (propStatus && propStatus[1] === '0') {
            analysis.problems.push({ stage: 'STATE', message: 'propStatus=0 (未赋值或默认值)', severity: 'warning' });
          }
        }
        if (msg.startsWith('UI_DATA')) {
          const goodsList = msg.match(/goodsList=(\d+)/);
          if (goodsList && goodsList[1] === '0') {
            analysis.problems.push({ stage: 'STATE', message: 'goodsList 为空', severity: 'warning' });
          }
        }
      }
    }
  }

  // Overall diagnosis
  const errorProblems = analysis.problems.filter(p => p.severity === 'error');
  const warnProblems = analysis.problems.filter(p => p.severity === 'warning');

  if (errorProblems.length > 0) {
    analysis.overallStatus = 'error';
    analysis.diagnosis = errorProblems.map(p => `❌ [${p.stage}] ${p.message}`).join('\n');
  } else if (warnProblems.length > 0) {
    analysis.overallStatus = 'warning';
    analysis.diagnosis = warnProblems.map(p => `⚠️ [${p.stage}] ${p.message}`).join('\n');
  } else {
    analysis.diagnosis = '✅ 所有阶段正常，数据流无问题';
  }

  return analysis;
}

const sessionAnalyses = Object.values(sessions).map(analyzeSession);

// ── 生成 HTML ──
const statusColors = { success: '#10b981', warning: '#f59e0b', error: '#ef4444', pending: '#6b7280', running: '#3b82f6' };
const statusIcons = { success: '✅', warning: '⚠️', error: '❌', pending: '⏳', running: '🔄' };
const stageLabels = {
  NETWORK: '🌐 网络请求', PARSE: '📦 解包校验', DATA_UNWRAP: '🔓 Data解包',
  KEY_FIELDS: '🔑 关键字段', DELIVER: '📮 数据分发', STATE: '🖥️ UI状态'
};
const stageNames = ['NETWORK', 'PARSE', 'DATA_UNWRAP', 'KEY_FIELDS', 'DELIVER', 'STATE'];

const now = new Date().toLocaleString('zh-CN');
const successCount = sessionAnalyses.filter(s => s.overallStatus === 'success').length;
const warnCount = sessionAnalyses.filter(s => s.overallStatus === 'warning').length;
const errCount = sessionAnalyses.filter(s => s.overallStatus === 'error').length;

function renderStage(sa, stage, idx) {
  const s = sa.stages[stage];
  const color = statusColors[s.status];
  const icon = stageLabels[stage].split(' ')[0];
  const label = stageLabels[stage].split(' ').slice(1).join(' ');
  const sIcon = statusIcons[s.status];
  let extra = '';
  if (s.duration) extra += `<div style="font-size:11px;color:${color}">${s.duration}</div>`;
  if (s.payloadSize) extra += `<div style="font-size:11px;color:#94a3b8">${s.payloadSize}b</div>`;
  const arrow = idx < 5 ? '<div class="arrow">→</div>' : '';
  return `<div class="stage">
    <div class="stage-box" style="border-color:${color}">
      <div class="stage-icon">${icon}</div>
      <div class="stage-label">${label}</div>
      <div class="stage-status">${sIcon}</div>
      ${extra}
    </div>
    ${arrow}
  </div>`;
}

function renderKeyFields(sa) {
  const kf = sa.stages.KEY_FIELDS;
  if (!kf.present && !kf.missing) return '';
  let html = '<div class="detail-grid">';
  if (kf.present) {
    html += `<div class="detail-item"><div class="key">✅ 已找到字段</div><div class="value" style="color:#10b981">${kf.present.join(', ')}</div></div>`;
  }
  if (kf.missing) {
    html += `<div class="detail-item"><div class="key">❌ 缺失字段</div><div class="value" style="color:#ef4444">${kf.missing.join(', ')}</div></div>`;
  }
  html += '</div>';
  return html;
}

function renderProblems(sa) {
  if (sa.problems.length === 0) return '';
  let html = '<div class="section-title">🔎 发现的问题</div><div class="problems">';
  for (const p of sa.problems) {
    const cls = p.severity;
    const icon = p.severity === 'error' ? '❌' : '⚠️';
    html += `<div class="problem ${cls}"><span class="icon">${icon}</span><span><strong>[${p.stage}]</strong> ${p.message}</span></div>`;
  }
  html += '</div>';
  return html;
}

function renderUIState(sa) {
  if (sa.stages.STATE.events.length === 0) return '';
  let html = '<div class="section-title">🖥️ UI 状态快照</div><div class="detail-grid">';
  for (const e of sa.stages.STATE.events) {
    const pairs = e.message.replace(/^UI_\w+\s*/, '').split(' ');
    for (const p of pairs) {
      const eqIdx = p.indexOf('=');
      if (eqIdx < 0) continue;
      const k = p.substring(0, eqIdx);
      const v = p.substring(eqIdx + 1);
      const isBad = (k === 'isLoading' && v === 'true') || (k === 'showError' && v === 'true') || (k === 'goodsList' && v === '0');
      const isGood = v === 'true' || (parseInt(v) > 0 && k !== 'propStatus');
      const color = isBad ? '#ef4444' : isGood ? '#10b981' : '#e2e8f0';
      html += `<div class="detail-item"><div class="key">${k}</div><div class="value" style="color:${color}">${v}</div></div>`;
    }
  }
  html += '</div>';
  return html;
}

function renderRawLogs(sa) {
  let html = '<div class="section-title">📝 原始日志</div><div class="raw-logs">';
  for (const e of sa.events) {
    const cls = e.level === 'W' ? 'warn' : e.level === 'E' ? 'error' : 'info';
    html += `<div class="log-line ${cls}"><span class="cat">[${e.category}]</span> ${e.level} | ${e.message}</div>`;
  }
  html += '</div>';
  return html;
}

function renderSession(sa, idx) {
  const expanded = idx === 0 ? ' expanded' : '';
  const badge = `<span class="badge ${sa.overallStatus}">${statusIcons[sa.overallStatus]} ${sa.overallStatus.toUpperCase()}</span>`;
  const meta = `Session: ${sa.id} | ${sa.fetchDuration ? sa.fetchDuration + 'ms' : 'N/A'} | ${sa.dataSize ? sa.dataSize + ' bytes' : ''}`;

  return `
<div class="session${expanded}" onclick="this.classList.toggle('expanded')">
  <div class="session-header">
    <div><span class="title">${sa.service || sa.id}</span> ${badge}</div>
    <div class="meta">${meta}</div>
  </div>
  <div class="session-body" onclick="event.stopPropagation()">
    <div class="pipeline">
      ${stageNames.map((s, i) => renderStage(sa, s, i)).join('')}
    </div>
    ${renderKeyFields(sa)}
    ${renderProblems(sa)}
    <div class="diagnosis"><h4>📋 诊断结论</h4><pre>${sa.diagnosis}</pre></div>
    ${renderUIState(sa)}
    ${renderRawLogs(sa)}
  </div>
</div>`;
}

const html = `<!DOCTYPE html>
<html lang="zh-CN">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Pipeline 诊断报告 - ${now}</title>
<style>
*{margin:0;padding:0;box-sizing:border-box}
body{font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,monospace;background:#0f172a;color:#e2e8f0;padding:20px}
.header{text-align:center;margin-bottom:30px;padding:20px;background:linear-gradient(135deg,#1e293b,#334155);border-radius:16px;border:1px solid #475569}
.header h1{font-size:24px;margin-bottom:8px}
.header .subtitle{color:#94a3b8;font-size:14px}
.summary{display:flex;gap:16px;margin-bottom:24px;flex-wrap:wrap}
.summary-card{flex:1;min-width:150px;background:#1e293b;border-radius:12px;padding:16px;border:1px solid #334155;text-align:center}
.summary-card .number{font-size:32px;font-weight:bold}
.summary-card .label{color:#94a3b8;font-size:12px;margin-top:4px}
.session{background:#1e293b;border-radius:16px;margin-bottom:20px;border:1px solid #334155;overflow:hidden}
.session-header{padding:16px 20px;display:flex;align-items:center;justify-content:space-between;cursor:pointer;transition:background .2s}
.session-header:hover{background:#334155}
.session-header .title{font-size:16px;font-weight:600;margin-right:8px}
.session-header .meta{color:#94a3b8;font-size:13px}
.session-body{padding:0 20px 20px;display:none}
.session.expanded .session-body{display:block}
.pipeline{display:flex;align-items:stretch;gap:0;margin:16px 0;overflow-x:auto}
.stage{flex:1;min-width:110px;text-align:center;position:relative}
.stage-box{background:#0f172a;border-radius:10px;padding:12px 8px;margin:0 4px;border:2px solid;transition:transform .2s}
.stage-box:hover{transform:translateY(-2px)}
.stage-icon{font-size:24px;margin-bottom:4px}
.stage-label{font-size:11px;color:#94a3b8}
.stage-status{font-size:20px;margin-top:4px}
.arrow{position:absolute;right:-8px;top:50%;transform:translateY(-50%);color:#475569;font-size:18px;z-index:1}
.problems{margin:12px 0}
.problem{padding:10px 14px;border-radius:8px;margin-bottom:6px;font-size:13px;display:flex;align-items:flex-start;gap:8px}
.problem.error{background:rgba(239,68,68,.15);border:1px solid rgba(239,68,68,.3)}
.problem.warning{background:rgba(245,158,11,.15);border:1px solid rgba(245,158,11,.3)}
.problem .icon{flex-shrink:0}
.raw-logs{background:#0f172a;border-radius:8px;padding:12px;font-size:12px;line-height:1.6;max-height:300px;overflow-y:auto;margin-top:12px;border:1px solid #334155}
.raw-logs .log-line{padding:2px 0;font-family:"JetBrains Mono","Fira Code",monospace}
.raw-logs .log-line .cat{font-weight:bold}
.raw-logs .log-line.warn{color:#f59e0b}
.raw-logs .log-line.error{color:#ef4444}
.raw-logs .log-line.info{color:#10b981}
.diagnosis{background:#0f172a;border-radius:10px;padding:14px;margin-top:12px;border:1px solid #334155}
.diagnosis h4{margin-bottom:8px;font-size:14px}
.diagnosis pre{font-size:13px;white-space:pre-wrap;line-height:1.6}
.badge{display:inline-block;padding:2px 8px;border-radius:4px;font-size:11px;font-weight:600}
.badge.success{background:rgba(16,185,129,.2);color:#10b981}
.badge.warning{background:rgba(245,158,11,.2);color:#f59e0b}
.badge.error{background:rgba(239,68,68,.2);color:#ef4444}
.section-title{font-size:14px;font-weight:600;margin:16px 0 8px;color:#94a3b8}
.detail-grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(200px,1fr));gap:8px;margin:8px 0}
.detail-item{background:#0f172a;border-radius:8px;padding:10px;border:1px solid #334155}
.detail-item .key{color:#94a3b8;font-size:11px}
.detail-item .value{font-size:14px;font-weight:600;margin-top:2px}
</style>
</head>
<body>
<div class="header">
  <h1>🔍 Pipeline 诊断报告</h1>
  <div class="subtitle">生成时间: ${now} | 会话数: ${sessionAnalyses.length}</div>
</div>
<div class="summary">
  <div class="summary-card"><div class="number" style="color:#10b981">${successCount}</div><div class="label">✅ 正常</div></div>
  <div class="summary-card"><div class="number" style="color:#f59e0b">${warnCount}</div><div class="label">⚠️ 警告</div></div>
  <div class="summary-card"><div class="number" style="color:#ef4444">${errCount}</div><div class="label">❌ 错误</div></div>
  <div class="summary-card"><div class="number" style="color:#3b82f6">${sessionAnalyses.length}</div><div class="label">📊 总会话</div></div>
</div>
${sessionAnalyses.map((sa, i) => renderSession(sa, i)).join('\n')}
<script>
document.querySelectorAll('.session').forEach(s => {
  if (s.querySelector('.badge.error')) s.classList.add('expanded');
});
</script>
</body>
</html>`;

// ── 输出 ──
fs.mkdirSync(outputDir, { recursive: true });
const timestamp = new Date().toISOString().replace(/[:.]/g, '-').slice(0, 19);
const outputPath = path.join(outputDir, `pipeline-report-${timestamp}.html`);
fs.writeFileSync(outputPath, html);
console.log(`📊 报告路径: ${outputPath}`);

if (openAfter) {
  try {
    if (process.platform === 'darwin') execSync(`open "${outputPath}"`);
    else if (process.platform === 'linux') execSync(`xdg-open "${outputPath}"`);
  } catch (e) { /* ignore */ }
}
