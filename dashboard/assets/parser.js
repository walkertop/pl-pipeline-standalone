// =============================================================================
// parser.js — pl-pipeline events.jsonl 解析与聚合
// =============================================================================

export function parseJSONL(text) {
  return text
    .split('\n')
    .filter(l => l.trim())
    .map(l => {
      try { return JSON.parse(l); }
      catch { return null; }
    })
    .filter(Boolean);
}

/**
 * 从事件流聚合出 change 的当前状态。
 * 返回：{
 *   change_id, stage, gate_status, tasks: {added, done, blocked},
 *   violations, last_event_ts, total_events, event_types
 * }
 */
export function aggregateChange(events) {
  if (events.length === 0) return null;

  const first = events[0];
  const last = events[events.length - 1];

  // 当前 stage：从 state.transition 推（最新），或从 phase 取最后一条
  let stage = last.phase || 'UNKNOWN';
  let stage_ts = last.ts;
  for (let i = events.length - 1; i >= 0; i--) {
    const e = events[i];
    if (e.event === 'state.transition' && e.data?.to_stage) {
      stage = e.data.to_stage;
      stage_ts = e.ts;
      break;
    }
  }

  // gate_status：找最新的 gate.eval
  let gate_status = 'IN_PROGRESS';
  let blocker = null;
  for (let i = events.length - 1; i >= 0; i--) {
    const e = events[i];
    if (e.event === 'gate.eval') {
      const r = (e.data?.result || '').toUpperCase();
      if (r === 'PASSED') gate_status = 'PASSED';
      else if (r === 'BLOCKED') { gate_status = 'BLOCKED'; blocker = e; }
      else if (r === 'SKIPPED') gate_status = 'SKIPPED';
      break;
    }
  }

  // task 统计
  const taskSet = new Set();
  let tasksDone = 0;
  const blockedTasks = new Set();
  events.forEach(e => {
    if (e.event === 'plan.task.added' && e.data?.task_id) taskSet.add(e.data.task_id);
    if (e.event === 'task.done' && e.data?.task_id) tasksDone++;
  });

  // event 类型分布
  const typeCount = {};
  events.forEach(e => { typeCount[e.event] = (typeCount[e.event] || 0) + 1; });

  // violations
  const violations = events.filter(e =>
    e.event === 'pl.trace.violation.detected' ||
    (e.event === 'check.run' && e.data?.status === 'fail') ||
    e.event === 'piao.contract_drift.detected' && (e.data?.counts?.error || 0) > 0
  );

  return {
    change_id: first.change_id || 'unknown',
    stage,
    stage_ts,
    gate_status,
    blocker,
    tasks_total: taskSet.size,
    tasks_done: tasksDone,
    tasks_blocked: blockedTasks.size,
    last_event_ts: last.ts,
    first_event_ts: first.ts,
    total_events: events.length,
    event_types: typeCount,
    violation_count: violations.length,
  };
}

// 阶段定义（顺序固定）
export const STAGES = ['SPEC', 'PLAN', 'IMPLEMENT', 'VERIFY', 'SMOKE', 'OBSERVE', 'ARCHIVE'];

/**
 * 判断某阶段的状态：done / active / blocked / todo
 */
export function stageStatus(agg, stage) {
  const curIdx = STAGES.indexOf(agg.stage);
  const myIdx = STAGES.indexOf(stage);
  if (myIdx < curIdx) return 'done';
  if (myIdx > curIdx) return 'todo';
  // myIdx === curIdx
  if (agg.gate_status === 'BLOCKED') return 'blocked';
  return 'active';
}

// 事件 → {icon, colorClass, title} 的渲染映射
export function renderEvent(e) {
  const t = e.event;
  const d = e.data || {};
  let icon = '•', cls = '', title = t;

  switch (t) {
    case 'artifact.created':  icon = '＋'; cls = 'event-info'; title = `created ${d.path || ''}`; break;
    case 'artifact.modified': icon = '✎';  cls = 'event-info'; title = `modified ${d.path || ''}`; break;
    case 'artifact.deleted':  icon = '✕';  cls = 'event-warn'; title = `deleted ${d.path || ''}`; break;
    case 'plan.task.added':   icon = '◇';  cls = 'event-info'; title = `task added ${d.task_id || ''}: ${d.task_name || ''}`; break;
    case 'task.done':         icon = '✓';  cls = 'event-ok';   title = `task done ${d.task_id || ''}`; break;
    case 'state.transition':  icon = '→';  cls = 'event-info'; title = `${d.from_stage || '?'} → ${d.to_stage || '?'}`; break;
    case 'asset.promoted':    icon = '★';  cls = 'event-ok';   title = `promoted ${d.kind || 'asset'}: ${d.target_path || ''}`; break;
    case 'gate.start':        icon = '▶';  cls = '';           title = `gate ${d.gate || '?'} start (${d.from || '?'} → ${d.to || '?'})`; break;
    case 'gate.eval':
      if (d.result === 'passed')       { icon = '✓'; cls = 'event-ok';  title = `gate ${d.gate || '?'} PASSED`; }
      else if (d.result === 'blocked') { icon = '✗'; cls = 'event-bad'; title = `gate ${d.gate || '?'} BLOCKED (pass=${d.pass||0} fail=${d.fail||0})`; }
      else                              { icon = '○'; cls = 'event-warn'; title = `gate ${d.gate || '?'} ${(d.result||'?').toUpperCase()}`; }
      break;
    case 'check.run':
      if (d.status === 'pass')  { icon = '✓'; cls = 'event-ok';  title = `check ${d.checker || '?'} passed`; }
      else if (d.status === 'fail') { icon = '✗'; cls = 'event-bad'; title = `check ${d.checker || '?'} failed (${d.reason || ''})`; }
      else                       { icon = '○'; cls = 'event-warn'; title = `check ${d.checker || '?'} ${d.status || '?'}`; }
      break;
    case 'smoke.boot':       icon = '🚀'; cls = 'event-info'; title = `smoke boot (pid=${d.pid || '?'})`; break;
    case 'smoke.ready':      icon = '✓';  cls = 'event-ok';   title = `smoke ready (${d.attempts || 0} tries)`; break;
    case 'smoke.shutdown':   icon = '■';  cls = '';           title = `smoke shutdown (pid=${d.pid || '?'})`; break;
    case 'smoke.skip':       icon = '○';  cls = 'event-warn'; title = `smoke skipped (${d.reason || '?'})`; break;
    case 'piao.contract_drift.detected':
      const ec = d.counts?.error || 0;
      if (ec === 0) { icon = '✓'; cls = 'event-ok'; title = 'piao contract drift: 0 entries'; }
      else           { icon = '⚠'; cls = 'event-warn'; title = `piao contract drift: ${ec} error(s)`; }
      break;
    case 'pl.rule_scan.completed':
      const tv = d.counts?.total || 0;
      if (tv === 0) { icon = '✓'; cls = 'event-ok'; title = `rule-scan: 0 violations (${d.executable_rules || 0} rules)`; }
      else           { icon = '⚠'; cls = 'event-warn'; title = `rule-scan: ${tv} violations`; }
      break;
    default:
      icon = '•'; cls = ''; title = t;
  }
  return { icon, cls, title };
}

/**
 * 判断事件是否"关键"：blocked gate / failed check / violations
 */
export function isCritical(e) {
  if (e.event === 'gate.eval' && e.data?.result === 'blocked') return true;
  if (e.event === 'check.run' && e.data?.status === 'fail') return true;
  if (e.event === 'pl.trace.violation.detected') return true;
  if (e.event === 'piao.contract_drift.detected' && (e.data?.counts?.error || 0) > 0) return true;
  return false;
}

// 格式化 ts (ISO) → HH:MM:SS
export function fmtTs(iso) {
  try {
    const d = new Date(iso);
    return d.toLocaleTimeString('en-US', { hour12: false });
  } catch { return iso; }
}

// 格式化相对时间 "3m ago"
export function fmtRelative(iso) {
  try {
    const now = Date.now();
    const t = new Date(iso).getTime();
    const s = Math.floor((now - t) / 1000);
    if (s < 60) return `${s}s ago`;
    if (s < 3600) return `${Math.floor(s/60)}m ago`;
    if (s < 86400) return `${Math.floor(s/3600)}h ago`;
    return `${Math.floor(s/86400)}d ago`;
  } catch { return iso; }
}
