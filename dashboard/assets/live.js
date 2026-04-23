// =============================================================================
// live.js — SSE 客户端 + 能力探测 + 降级
// =============================================================================
//
// 核心 API：
//   probeLiveReload()  → Promise<boolean>
//     HEAD /_events/ping；返回 true/false 判断是否启用 live-reload
//
//   subscribeChange(changeId, handlers) → () => void
//     订阅某 change 的 events.jsonl tail 流
//     handlers: { onSnapshot, onAppend, onReset, onMissing, onStatus }
//     返回 unsubscribe 函数
//
//   subscribeIndex(handlers) → () => void
//     订阅 trace 目录变化
//     handlers: { onUpdated, onStatus }
//
// 降级：
//   当 probe 失败（server 不支持或被停），应用层应显示 "static mode" 并保持 v1.3.0 原逻辑
// =============================================================================

/**
 * 通过 HEAD /_events/ping 探测 live-reload 可用性。
 * 超时 2s。
 */
export async function probeLiveReload() {
  try {
    const ctrl = new AbortController();
    const timer = setTimeout(() => ctrl.abort(), 2000);
    const resp = await fetch('/_events/ping', {
      method: 'HEAD',
      signal: ctrl.signal,
    });
    clearTimeout(timer);
    // 自写 server 对 HEAD 返回 200 text/event-stream
    // python3 -m http.server 也会 200 但 Content-Type 不是 event-stream
    const ct = resp.headers.get('Content-Type') || '';
    return resp.ok && ct.includes('event-stream');
  } catch {
    return false;
  }
}

/**
 * 订阅单个 change 的 tail 流。
 *
 * @param {string} changeId
 * @param {object} handlers
 *   onSnapshot(events, changeId)  — 首次订阅时收到全量历史
 *   onAppend(events, changeId)    — 新事件追加
 *   onReset()                     — jsonl 被截断/rotate
 *   onMissing()                   — jsonl 文件不存在
 *   onStatus(s)                   — 'connecting' | 'open' | 'error' | 'closed'
 * @returns {() => void} unsubscribe
 */
export function subscribeChange(changeId, handlers = {}) {
  const url = `/_events/stream?change=${encodeURIComponent(changeId)}`;
  return _subscribe(url, {
    hello:    () => handlers.onStatus?.('open'),
    snapshot: (d) => handlers.onSnapshot?.(d.events || [], d.change_id),
    append:   (d) => handlers.onAppend?.(d.events || [], d.change_id),
    reset:    () => handlers.onReset?.(),
    missing:  () => handlers.onMissing?.(),
  }, handlers.onStatus);
}

/**
 * 订阅 trace 目录的整体变化（哪些 change 有更新）。
 */
export function subscribeIndex(handlers = {}) {
  return _subscribe('/_events/index', {
    hello:   () => handlers.onStatus?.('open'),
    updated: (d) => handlers.onUpdated?.(d.changes || []),
  }, handlers.onStatus);
}

// ─────────────────────────────────────────────────────────────────────────────
// 内部：通用 EventSource 包装 + 自动重连
// ─────────────────────────────────────────────────────────────────────────────
function _subscribe(url, eventHandlers, onStatus) {
  let closed = false;
  let es = null;
  let retryTimer = null;
  let retryDelay = 1000;  // exponential backoff, max 15s

  const connect = () => {
    if (closed) return;
    onStatus?.('connecting');
    try {
      es = new EventSource(url);
    } catch (e) {
      scheduleReconnect();
      return;
    }

    es.onopen = () => {
      retryDelay = 1000;  // reset backoff
      onStatus?.('open');
    };
    es.onerror = () => {
      onStatus?.('error');
      es?.close();
      es = null;
      scheduleReconnect();
    };

    // 注册命名事件
    for (const [name, fn] of Object.entries(eventHandlers)) {
      es.addEventListener(name, (ev) => {
        try {
          const data = JSON.parse(ev.data);
          fn(data);
        } catch (e) {
          console.warn('bad SSE payload', ev.data);
        }
      });
    }
  };

  const scheduleReconnect = () => {
    if (closed) return;
    retryTimer = setTimeout(() => {
      retryDelay = Math.min(retryDelay * 1.8, 15000);
      connect();
    }, retryDelay);
  };

  connect();

  return () => {
    closed = true;
    if (retryTimer) clearTimeout(retryTimer);
    if (es) {
      es.close();
      onStatus?.('closed');
    }
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// UI helper：连接状态徽章
// ─────────────────────────────────────────────────────────────────────────────
export function mountStatusBadge(parent) {
  const el = document.createElement('span');
  el.className = 'live-badge live-badge-off';
  el.innerHTML = '<span class="live-dot"></span><span class="live-text">static</span>';
  parent.appendChild(el);
  return {
    set(status) {
      const map = {
        on:         ['live-badge-on',        '● live'],
        connecting: ['live-badge-connecting','◐ connecting'],
        off:        ['live-badge-off',       '○ static'],
        error:      ['live-badge-error',     '✕ reconnect'],
      };
      const [cls, text] = map[status] || map.off;
      el.className = `live-badge ${cls}`;
      el.querySelector('.live-text').textContent = text.replace(/^. /, '');
      el.querySelector('.live-dot').textContent = text.slice(0, 1);
    },
  };
}
