#!/usr/bin/env python3
# =============================================================================
# dashboard-server.py — pl-pipeline Dashboard Live Reload HTTP server
# =============================================================================
#
# 职责：
#   1. 静态文件托管（等价于 python3 -m http.server --bind 127.0.0.1）
#   2. SSE 端点：
#        GET /_events/stream?change=<id>  — tail 单个 change 的 events.jsonl
#        GET /_events/index               — 推送 _data.json / trace 目录的任何变化
#        GET /_events/ping                — 5 秒一次心跳，用于前端连通性探测
#   3. 自动降级：当 trace 目录不存在时仍能托管静态文件
#
# 设计：
#   - 零第三方依赖：仅用 Python stdlib（http.server + threading）
#   - 轮询式 tail（与 observe-fs.py 同策略）：每 0.5s 检查 mtime + 文件大小
#   - 心跳 :keepalive 每 15s 发送一次防止中间件断连
#   - 自然退出：SIGINT / SIGTERM 关闭所有 SSE 订阅
#
# 用法（被 pl-dashboard.sh 调起）：
#   python3 dashboard-server.py \
#       --dash-dir /path/to/dashboard \
#       --trace-dir /path/to/pipeline-output/trace \
#       --data-file /path/to/dashboard/_data.json \
#       --port 8889
# =============================================================================

import argparse
import json
import mimetypes
import os
import queue
import signal
import subprocess
import sys
import threading
import time
import traceback
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import parse_qs, urlparse

# ─────────────────────────────────────────────────────────────────────────────
# 全局状态
# ─────────────────────────────────────────────────────────────────────────────
STATE = {
    "dash_dir": None,     # Path: 静态文件根
    "trace_dir": None,    # Path | None
    "data_file": None,    # Path: _data.json
    "pl_home": None,      # Path | None: pl-pipeline 安装根（用于跑 pl-contract-verify.sh）
    "pl_project": None,   # Path | None: 宿主项目根（PL_PROJECT）
    "contracts_dir": None,  # Path | None: <project>/pl/contracts，contracts 不存在则 endpoint 直接返回空报告
}

# /_data/contracts.json 的轻量缓存（避免每帧都跑 verify）
CONTRACTS_CACHE = {
    "ts": 0.0,
    "payload": None,
    "lock": threading.Lock(),
    "ttl_sec": 3.0,
}

# /_data/contract-detail.json?change=<id> 的 per-change 缓存（v1.7.3 新增）
# 单 change 跑 verify 比 all 还便宜（pact 少一半），但前端 drill-down 时若同时打开
# 多个 tab 也别让每个 tab 都触发一次 yaml 解析
CONTRACT_DETAIL_CACHE = {
    "by_change": {},   # change_id -> {"ts": float, "payload": dict}
    "lock": threading.Lock(),
    "ttl_sec": 3.0,
}

# 每个 change 一个 Broadcaster，index 视图也有一个
# key: "change:<id>" | "index"
# value: Broadcaster 实例
BROADCASTERS = {}
BROADCASTERS_LOCK = threading.Lock()

# 全局退出标志
SHUTDOWN = threading.Event()


# ─────────────────────────────────────────────────────────────────────────────
# Broadcaster — 多订阅者事件分发
# ─────────────────────────────────────────────────────────────────────────────
class Broadcaster:
    """每个 Broadcaster 对应一个被观察的资源（一个 jsonl 或 _data.json）。

    订阅者通过 subscribe() 拿到一个 queue，watcher 线程把新事件 put 进所有 queue。
    订阅者关闭连接时调用 unsubscribe()，最后一个订阅者离开后 watcher 自动停。

    Snapshot 协议（v1.3.2 fix #1）：
      - 每个新订阅者在 subscribe() 时都要收到一次当前全量 snapshot
      - 因此 Broadcaster 需要一个 snapshot_fn 可被随时调用生成当前快照
      - watcher 只负责 publish "append/reset/missing"，不再发 snapshot
    """

    def __init__(self, name, watcher_fn, snapshot_fn=None):
        self.name = name
        self.watcher_fn = watcher_fn
        self.snapshot_fn = snapshot_fn  # Optional[Callable[[], dict | None]]
        self.subscribers = []        # list[queue.Queue]
        self.lock = threading.Lock()
        self.thread = None
        self.stop_flag = threading.Event()

    def subscribe(self):
        q = queue.Queue(maxsize=1024)
        # 先把本订阅者加到订阅列表，再给 ta 推一次初始 snapshot（仅对这个 queue），
        # 这样既不会错过初始状态，也不会错过后续 watcher 的 append。
        with self.lock:
            self.subscribers.append(q)
            need_start = self.thread is None or not self.thread.is_alive()
        # 给新订阅者独家推 snapshot（仅在有 snapshot_fn 的 Broadcaster 上）
        if self.snapshot_fn is not None:
            try:
                snap = self.snapshot_fn()
                if snap is not None:
                    try:
                        q.put_nowait(snap)
                    except queue.Full:
                        pass
            except Exception:
                traceback.print_exc()
        if need_start:
            self.stop_flag.clear()
            self.thread = threading.Thread(
                target=self._run_watcher, name=f"watch-{self.name}", daemon=True
            )
            self.thread.start()
        return q

    def unsubscribe(self, q):
        with self.lock:
            if q in self.subscribers:
                self.subscribers.remove(q)
            no_more = len(self.subscribers) == 0
        if no_more:
            self.stop_flag.set()  # watcher 线程退出

    def publish(self, payload):
        """把 payload 广播给所有订阅者（单条 dict）。"""
        with self.lock:
            dead = []
            for q in self.subscribers:
                try:
                    q.put_nowait(payload)
                except queue.Full:
                    dead.append(q)
            for d in dead:
                self.subscribers.remove(d)

    def _run_watcher(self):
        try:
            self.watcher_fn(self, self.stop_flag)
        except Exception:
            traceback.print_exc()


# ─────────────────────────────────────────────────────────────────────────────
# Watcher 函数
# ─────────────────────────────────────────────────────────────────────────────
def _read_jsonl_events(path):
    """把文件全量读为 (events: list, size_bytes: int)；读不到返回 (None, 0)。"""
    if not path.exists():
        return None, 0
    try:
        raw = path.read_bytes()
    except Exception:
        return None, 0
    events = []
    for line in raw.splitlines():
        line = line.strip()
        if not line:
            continue
        try:
            events.append(json.loads(line.decode("utf-8")))
        except (json.JSONDecodeError, UnicodeDecodeError):
            pass
    return events, len(raw)


def make_tail_snapshot_fn(path, change_id):
    """为单个 change 构造 snapshot 生成函数；供 Broadcaster.snapshot_fn 使用。

    返回 None 表示文件不存在 / 空（订阅者会只等 append）。
    """
    def snapshot():
        events, size = _read_jsonl_events(path)
        if events is None:
            return {"event": "missing", "change_id": change_id}
        return {
            "event": "snapshot",
            "change_id": change_id,
            "events": events,
            "pos": size,
        }
    return snapshot


def tail_jsonl_watcher(bcast, stop_flag, path, change_id):
    """轮询式 tail — 只管 publish append / reset / missing。

    snapshot 由 Broadcaster.snapshot_fn 在订阅时针对单个订阅者推送（v1.3.2 fix #1）。
    """
    # 轮询起点：以文件当前 size 为 pos，避免把"已经被 snapshot 覆盖的历史" 再当 append 重发
    pos = 0
    last_size = -1
    last_mtime = 0
    missing_announced = False

    # 初始化：记录当前 size（如果文件存在）
    if path.exists():
        try:
            st = path.stat()
            pos = st.st_size
            last_size = st.st_size
            last_mtime = st.st_mtime
        except Exception:
            pass

    while not stop_flag.is_set() and not SHUTDOWN.is_set():
        try:
            if not path.exists():
                if not missing_announced and last_size != -1:
                    bcast.publish({"event": "missing", "change_id": change_id})
                    missing_announced = True
                    pos = 0
                    last_size = -1
                time.sleep(0.5)
                continue
            # 文件（重新）出现
            if missing_announced:
                # 重置并让客户端重拉 snapshot
                bcast.publish({"event": "reset", "change_id": change_id})
                missing_announced = False
                pos = 0
                last_size = -1

            st = path.stat()
            size = st.st_size
            mtime = st.st_mtime

            # 首次进入（last_size == -1，但文件此刻存在）：从 0 开始读并推 reset + 全量
            if last_size < 0:
                bcast.publish({"event": "reset", "change_id": change_id})
                pos = 0
                last_size = 0

            # 被截断 / rotate
            if size < last_size:
                bcast.publish({"event": "reset", "change_id": change_id})
                pos = 0
                last_size = 0

            # 有新内容
            if size > last_size or mtime != last_mtime:
                with path.open("rb") as f:
                    f.seek(pos)
                    new_raw = f.read()
                new_events = []
                for line in new_raw.splitlines():
                    line = line.strip()
                    if not line:
                        continue
                    try:
                        new_events.append(json.loads(line.decode("utf-8")))
                    except (json.JSONDecodeError, UnicodeDecodeError):
                        pass
                if new_events:
                    bcast.publish({
                        "event": "append",
                        "change_id": change_id,
                        "events": new_events,
                    })
                pos = size
                last_size = size
                last_mtime = mtime
        except Exception:
            traceback.print_exc()
        time.sleep(0.5)


def _read_index_changes():
    """读当前 trace 目录下所有 *.events.jsonl 的 (id, mtime, size)。"""
    trace_dir = STATE["trace_dir"]
    out = []
    if trace_dir and trace_dir.exists():
        for p in sorted(trace_dir.glob("*.events.jsonl")):
            try:
                st = p.stat()
                out.append({
                    "id": p.name.replace(".events.jsonl", ""),
                    "mtime": st.st_mtime,
                    "size": st.st_size,
                })
            except Exception:
                pass
    return out


def _compute_index_sig(data_file):
    sig = [(c["id"], c["mtime"], c["size"]) for c in _read_index_changes()]
    if data_file and data_file.exists():
        try:
            st = data_file.stat()
            sig.append(("__data__", st.st_mtime, st.st_size))
        except Exception:
            pass
    return tuple(sig)


def make_index_snapshot_fn():
    def snapshot():
        return {"event": "updated", "changes": _read_index_changes()}
    return snapshot


def index_watcher(bcast, stop_flag):
    """监视 trace_dir 下所有 *.events.jsonl 的文件列表与 mtime。

    任何变化（新 change 出现 / 现有 change 追加）就 publish
    {event:'updated', changes:[{id, mtime, size}, ...]}

    初始 snapshot 由 make_index_snapshot_fn 负责（v1.3.2 fix #1），
    这里初始化 last_sig 为当前状态，避免启动多发一条相同内容的 updated。
    """
    data_file = STATE["data_file"]
    last_sig = _compute_index_sig(data_file)

    while not stop_flag.is_set() and not SHUTDOWN.is_set():
        try:
            sig = _compute_index_sig(data_file)
            if sig != last_sig:
                bcast.publish({"event": "updated", "changes": _read_index_changes()})
                last_sig = sig
        except Exception:
            traceback.print_exc()
        time.sleep(1.0)


# ─────────────────────────────────────────────────────────────────────────────
# Broadcaster 注册表
# ─────────────────────────────────────────────────────────────────────────────
def get_change_broadcaster(change_id):
    key = f"change:{change_id}"
    with BROADCASTERS_LOCK:
        bc = BROADCASTERS.get(key)
        if bc is None:
            trace_dir = STATE["trace_dir"]
            if trace_dir is None:
                return None
            path = trace_dir / f"{change_id}.events.jsonl"
            bc = Broadcaster(
                name=key,
                watcher_fn=lambda b, s: tail_jsonl_watcher(b, s, path, change_id),
                snapshot_fn=make_tail_snapshot_fn(path, change_id),
            )
            BROADCASTERS[key] = bc
        return bc


def get_index_broadcaster():
    key = "index"
    with BROADCASTERS_LOCK:
        bc = BROADCASTERS.get(key)
        if bc is None:
            bc = Broadcaster(
                name=key,
                watcher_fn=index_watcher,
                snapshot_fn=make_index_snapshot_fn(),
            )
            BROADCASTERS[key] = bc
        return bc


# ─────────────────────────────────────────────────────────────────────────────
# Contracts 视图（/_data/contracts.json）
# ─────────────────────────────────────────────────────────────────────────────
def _empty_contracts_payload(reason=""):
    """contracts dir 不存在 / pl_home 缺失等情况下返回的最小 payload。"""
    return {
        "apiVersion": "piao.dev/v1",
        "kind": "ContractStatusForDashboard",
        "available": False,
        "reason": reason or "contracts not initialized",
        "summary": {"total": 0, "satisfied": 0, "warn": 0, "broken": 0},
        "by_change": {},
    }


def _compute_contracts_payload():
    """跑 pl-contract-verify.sh --json，把结果削减成 dashboard 需要的形态。

    削减规则（前端只需要"卡片角标"够用，不要把 violations 全表都喂上）：
      by_change[<id>] = {
        status:           'satisfied' | 'warn' | 'broken',
        adapter:          'adapter-id',
        adapter_version:  '0.1.0',
        warn_count:       int,
        broken_count:     int,
        # 前 3 条简短摘要给 tooltip 用
        broken_examples:  ['skill/foo missing', ...],
        warn_examples:    ['capability/bar deprecated_in 0.2.0', ...],
      }
    """
    pl_home = STATE.get("pl_home")
    pl_project = STATE.get("pl_project")
    contracts_dir = STATE.get("contracts_dir")

    if pl_home is None or pl_project is None:
        return _empty_contracts_payload("dashboard server 没拿到 --pl-home / --pl-project")

    # contracts 目录不存在：合法的"还没产生 pact"状态，前端不应该报错
    if contracts_dir is None or not contracts_dir.exists():
        return _empty_contracts_payload("no pacts yet (run pl-runner.sh through ARCHIVE)")

    verify_script = pl_home / "scripts" / "pl-contract-verify.sh"
    if not verify_script.exists():
        return _empty_contracts_payload(f"pl-contract-verify.sh not found at {verify_script}")

    env = dict(os.environ)
    env["PL_HOME"] = str(pl_home)
    env["PL_PROJECT"] = str(pl_project)

    try:
        proc = subprocess.run(
            ["bash", str(verify_script), "--json"],
            env=env,
            capture_output=True,
            text=True,
            timeout=15,
        )
    except subprocess.TimeoutExpired:
        return _empty_contracts_payload("pl-contract-verify.sh timeout (>15s)")
    except Exception as e:  # pragma: no cover - 防御
        return _empty_contracts_payload(f"failed to run verify: {e}")

    # exit 2 = 解析错误；exit 0/1 都是合法 JSON（1=有 broken）
    if proc.returncode == 2:
        return _empty_contracts_payload(
            f"verify returned exit 2: {(proc.stderr or '').strip()[:200]}"
        )

    try:
        report = json.loads(proc.stdout)
    except json.JSONDecodeError as e:
        return _empty_contracts_payload(f"verify output not JSON: {e}")

    by_change = {}
    for r in report.get("reports", []):
        cid = r.get("change_id")
        if not cid:
            continue
        violations = r.get("violations", []) or []
        warnings = r.get("warnings", []) or []
        by_change[cid] = {
            "status": r.get("status", "satisfied"),
            "adapter": r.get("adapter") or "",
            "adapter_version": r.get("adapter_version") or "",
            "broken_count": len(violations),
            "warn_count": len(warnings),
            "broken_examples": [
                f"{v.get('kind','?')}/{v.get('id','?')}"
                for v in violations[:3]
            ],
            "warn_examples": [
                f"{w.get('kind','?')}/{w.get('id','?')}"
                for w in warnings[:3]
            ],
        }

    return {
        "apiVersion": "piao.dev/v1",
        "kind": "ContractStatusForDashboard",
        "available": True,
        "reason": "",
        "summary": report.get("summary") or {
            "total": len(by_change),
            "satisfied": sum(1 for v in by_change.values() if v["status"] == "satisfied"),
            "warn": sum(1 for v in by_change.values() if v["status"] == "warn"),
            "broken": sum(1 for v in by_change.values() if v["status"] == "broken"),
        },
        "by_change": by_change,
    }


def get_contracts_payload(force=False):
    """带 TTL 缓存的入口。dashboard 拉得很频繁，verify 串 yaml 解析又不便宜，必须缓存。"""
    now = time.time()
    with CONTRACTS_CACHE["lock"]:
        if (
            not force
            and CONTRACTS_CACHE["payload"] is not None
            and (now - CONTRACTS_CACHE["ts"]) < CONTRACTS_CACHE["ttl_sec"]
        ):
            return CONTRACTS_CACHE["payload"]
        payload = _compute_contracts_payload()
        CONTRACTS_CACHE["payload"] = payload
        CONTRACTS_CACHE["ts"] = now
        return payload


# ─────────────────────────────────────────────────────────────────────────────
# Contract drill-down 详情（/_data/contract-detail.json?change=<id>） · v1.7.3
# ─────────────────────────────────────────────────────────────────────────────
# adapter.yaml 里 metadata.id 不一定等于目录名，所以 source_path 解析需要一次扫描
# 把 adapter_id -> 目录路径 的映射缓存起来。adapters 目录变化频率极低，扫一次够用。
ADAPTER_DIR_INDEX = {
    "by_id": None,   # dict | None: adapter_id -> Path(adapter dir)
    "lock": threading.Lock(),
    "scanned_ts": 0.0,
    "ttl_sec": 30.0,
}


def _scan_adapter_dirs():
    """扫 $PL_HOME/adapters/*/adapter.yaml，建立 metadata.id 到目录的映射。

    注意：这里**只读 metadata.id 这一行**，不解析整个 yaml，避免依赖 PyYAML。
    （dashboard-server 自身保持零第三方依赖，PyYAML 只是被 verify 子进程间接需要）
    """
    pl_home = STATE.get("pl_home")
    if pl_home is None:
        return {}
    adapters_dir = pl_home / "adapters"
    if not adapters_dir.exists():
        return {}
    out = {}
    for entry in sorted(adapters_dir.iterdir()):
        if not entry.is_dir():
            continue
        ayml = entry / "adapter.yaml"
        if not ayml.exists():
            continue
        # 极轻量解析：找 metadata: 块下首个 id: 行；找不到时 fallback 到目录名
        try:
            text = ayml.read_text(encoding="utf-8", errors="replace")
        except Exception:
            text = ""
        adapter_id = None
        in_metadata = False
        for raw_line in text.splitlines():
            line = raw_line.rstrip()
            if not line.startswith(" ") and not line.startswith("\t"):
                # 顶层 key 切换
                if line.startswith("metadata:"):
                    in_metadata = True
                else:
                    in_metadata = False
                continue
            if in_metadata:
                stripped = line.strip()
                if stripped.startswith("id:"):
                    val = stripped[3:].strip().strip('"').strip("'")
                    if val:
                        adapter_id = val
                    break
        if not adapter_id:
            adapter_id = entry.name
        out[adapter_id] = entry
    return out


def get_adapter_dir(adapter_id):
    """带 30s 缓存的 adapter 目录解析。"""
    now = time.time()
    with ADAPTER_DIR_INDEX["lock"]:
        if (
            ADAPTER_DIR_INDEX["by_id"] is None
            or (now - ADAPTER_DIR_INDEX["scanned_ts"]) > ADAPTER_DIR_INDEX["ttl_sec"]
        ):
            ADAPTER_DIR_INDEX["by_id"] = _scan_adapter_dirs()
            ADAPTER_DIR_INDEX["scanned_ts"] = now
        return ADAPTER_DIR_INDEX["by_id"].get(adapter_id)


def _resolve_source_path(adapter_id, kind, item_id):
    """根据 violation/warning/satisfied 的 kind+id 给出绝对源文件路径。

    解析规则（命中第一个就返回）：
      - skill   : adapters/<dir>/skills/<id>.{md,yaml,yml}
      - rule    : adapters/<dir>/rules/<id>.{md,yaml,yml}
      - agent   : adapters/<dir>/agents/<id>.{md,yaml,yml}
      - template: adapters/<dir>/templates/<id>.{md,yaml,yml}
      - build_command / capability / adapter / 其它 : adapters/<dir>/adapter.yaml

    解析失败返回 ""（前端拿到空串就不渲染"复制路径"按钮）。
    """
    adir = get_adapter_dir(adapter_id)
    if adir is None:
        return ""
    asset_dir_map = {
        "skill": "skills",
        "rule": "rules",
        "agent": "agents",
        "template": "templates",
    }
    sub = asset_dir_map.get(kind)
    if sub is None:
        # 落到 adapter.yaml 自身
        ayml = adir / "adapter.yaml"
        return str(ayml) if ayml.exists() else ""
    for ext in (".md", ".yaml", ".yml"):
        candidate = adir / sub / f"{item_id}{ext}"
        if candidate.exists():
            return str(candidate)
    return ""


def _empty_detail_payload(change_id, reason):
    return {
        "apiVersion": "piao.dev/v1",
        "kind": "ContractDetail",
        "available": False,
        "change_id": change_id,
        "reason": reason,
    }


def _compute_contract_detail(change_id):
    pl_home = STATE.get("pl_home")
    pl_project = STATE.get("pl_project")
    contracts_dir = STATE.get("contracts_dir")

    if pl_home is None or pl_project is None:
        return _empty_detail_payload(change_id, "dashboard server 没拿到 --pl-home / --pl-project")
    if contracts_dir is None or not contracts_dir.exists():
        return _empty_detail_payload(change_id, "no pacts yet")

    pact_file = contracts_dir / f"{change_id}.consumed.yaml"
    if not pact_file.exists():
        return _empty_detail_payload(change_id, f"no pact for change '{change_id}'")

    verify_script = pl_home / "scripts" / "pl-contract-verify.sh"
    if not verify_script.exists():
        return _empty_detail_payload(change_id, f"pl-contract-verify.sh not found at {verify_script}")

    env = dict(os.environ)
    env["PL_HOME"] = str(pl_home)
    env["PL_PROJECT"] = str(pl_project)

    try:
        proc = subprocess.run(
            ["bash", str(verify_script), "--change", change_id, "--json"],
            env=env,
            capture_output=True,
            text=True,
            timeout=15,
        )
    except subprocess.TimeoutExpired:
        return _empty_detail_payload(change_id, "verify timeout (>15s)")
    except Exception as e:  # pragma: no cover
        return _empty_detail_payload(change_id, f"failed to run verify: {e}")

    if proc.returncode == 2:
        return _empty_detail_payload(
            change_id, f"verify returned exit 2: {(proc.stderr or '').strip()[:200]}"
        )

    try:
        report = json.loads(proc.stdout)
    except json.JSONDecodeError as e:
        return _empty_detail_payload(change_id, f"verify output not JSON: {e}")

    reports = report.get("reports") or []
    if not reports:
        return _empty_detail_payload(change_id, "verify returned 0 reports")

    r = reports[0]
    adapter_id = r.get("adapter") or ""
    adir = get_adapter_dir(adapter_id) if adapter_id else None
    adapter_path = str(adir / "adapter.yaml") if (adir and (adir / "adapter.yaml").exists()) else ""

    def enrich(items):
        out = []
        for it in items or []:
            kind = it.get("kind", "")
            iid = it.get("id", "")
            entry = dict(it)
            entry["source_path"] = _resolve_source_path(adapter_id, kind, iid) if adapter_id else ""
            out.append(entry)
        return out

    return {
        "apiVersion": "piao.dev/v1",
        "kind": "ContractDetail",
        "available": True,
        "change_id": r.get("change_id") or change_id,
        "adapter": adapter_id,
        "adapter_version": r.get("adapter_version") or "",
        "adapter_path": adapter_path,
        "status": r.get("status", "satisfied"),
        "summary": {
            "violations": len(r.get("violations") or []),
            "warnings": len(r.get("warnings") or []),
            "satisfied": len(r.get("satisfied") or []),
        },
        "violations": enrich(r.get("violations")),
        "warnings": enrich(r.get("warnings")),
        "satisfied": enrich(r.get("satisfied")),
        "versions_seen": r.get("versions_seen") or [],
    }


def get_contract_detail(change_id, force=False):
    now = time.time()
    with CONTRACT_DETAIL_CACHE["lock"]:
        ent = CONTRACT_DETAIL_CACHE["by_change"].get(change_id)
        if (
            not force
            and ent is not None
            and (now - ent["ts"]) < CONTRACT_DETAIL_CACHE["ttl_sec"]
        ):
            return ent["payload"]
        payload = _compute_contract_detail(change_id)
        CONTRACT_DETAIL_CACHE["by_change"][change_id] = {"ts": now, "payload": payload}
        return payload


# ─────────────────────────────────────────────────────────────────────────────
# HTTP handler
# ─────────────────────────────────────────────────────────────────────────────
class Handler(BaseHTTPRequestHandler):
    # 静音默认日志（太吵），关键日志我们自己打
    def log_message(self, format, *args):
        if os.environ.get("PL_DASHBOARD_VERBOSE"):
            super().log_message(format, *args)

    # ---- utilities -----------------------------------------------------------

    def _write_sse_headers(self):
        self.send_response(200)
        self.send_header("Content-Type", "text/event-stream; charset=utf-8")
        self.send_header("Cache-Control", "no-cache")
        self.send_header("Connection", "keep-alive")
        self.send_header("X-Accel-Buffering", "no")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.end_headers()

    def _send_sse(self, data_obj, event=None):
        buf = []
        if event:
            buf.append(f"event: {event}\n")
        buf.append("data: " + json.dumps(data_obj, ensure_ascii=False) + "\n\n")
        self.wfile.write("".join(buf).encode("utf-8"))
        self.wfile.flush()

    def _send_static(self, path):
        """静态文件托管。支持 dashboard/ 根 + trace/ 子目录。"""
        # 规范化；禁止跳出 dash_dir 或 trace_dir
        dash_dir = STATE["dash_dir"]
        trace_dir = STATE["trace_dir"]

        rel = path.lstrip("/")
        if rel == "" or rel.endswith("/"):
            rel = rel + "index.html"

        # /trace/* 映射到 trace_dir（避免依赖 symlink）
        if rel.startswith("trace/") and trace_dir is not None:
            sub = rel[len("trace/"):]
            target = (trace_dir / sub).resolve()
            try:
                target.relative_to(trace_dir.resolve())
            except ValueError:
                self.send_error(403, "Forbidden")
                return
        else:
            target = (dash_dir / rel).resolve()
            try:
                target.relative_to(dash_dir.resolve())
            except ValueError:
                self.send_error(403, "Forbidden")
                return

        if not target.exists() or not target.is_file():
            self.send_error(404, "Not Found")
            return

        ctype, _ = mimetypes.guess_type(str(target))
        if ctype is None:
            ctype = "application/octet-stream"
        data = target.read_bytes()
        self.send_response(200)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(data)))
        self.send_header("Cache-Control", "no-cache")
        self.end_headers()
        self.wfile.write(data)

    # ---- routing -------------------------------------------------------------

    def do_HEAD(self):
        # 前端探测 /_events/stream 用 HEAD
        pu = urlparse(self.path)
        if pu.path.startswith("/_events/"):
            self.send_response(200)
            self.send_header("Content-Type", "text/event-stream")
            self.end_headers()
        else:
            self.send_response(200)
            self.end_headers()

    def do_GET(self):
        pu = urlparse(self.path)
        p = pu.path

        try:
            if p == "/_events/ping":
                self._handle_ping()
                return
            if p == "/_events/stream":
                qs = parse_qs(pu.query)
                change_id = qs.get("change", [""])[0]
                if not change_id:
                    self.send_error(400, "missing change param")
                    return
                self._handle_stream_change(change_id)
                return
            if p == "/_events/index":
                self._handle_stream_index()
                return
            if p == "/_data/contracts.json":
                self._handle_contracts_json()
                return
            if p == "/_data/contract-detail.json":
                qs = parse_qs(pu.query)
                change_id = qs.get("change", [""])[0]
                if not change_id:
                    self.send_error(400, "missing change param")
                    return
                self._handle_contract_detail_json(change_id)
                return

            # 默认：静态文件
            self._send_static(p)
        except (BrokenPipeError, ConnectionResetError):
            # 客户端关闭连接，正常
            return
        except Exception:
            traceback.print_exc()

    # ---- handlers ------------------------------------------------------------

    def _handle_ping(self):
        """一次性 SSE：回一个 ok 然后关闭。前端用来探测 SSE 能力。"""
        self._write_sse_headers()
        self._send_sse({"ok": True, "ts": time.time()}, event="ping")

    def _handle_contracts_json(self):
        """普通 JSON 端点（不是 SSE）。前端 fetch 一次或定期 poll。"""
        try:
            payload = get_contracts_payload()
        except Exception as e:  # pragma: no cover - 防御
            payload = _empty_contracts_payload(f"server error: {e}")
        self._send_json(payload)

    def _handle_contract_detail_json(self, change_id):
        """v1.7.3：单 change 的完整 verify report，附 source_path。drill-down 用。"""
        try:
            payload = get_contract_detail(change_id)
        except Exception as e:  # pragma: no cover - 防御
            payload = _empty_detail_payload(change_id, f"server error: {e}")
        self._send_json(payload)

    def _send_json(self, payload):
        body = json.dumps(payload, ensure_ascii=False).encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-cache, no-store, must-revalidate")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.end_headers()
        self.wfile.write(body)

    def _handle_stream_change(self, change_id):
        bc = get_change_broadcaster(change_id)
        if bc is None:
            self.send_error(503, "trace dir not available")
            return
        self._write_sse_headers()
        self._send_sse({"ts": time.time(), "change_id": change_id}, event="hello")

        q = bc.subscribe()
        try:
            last_keepalive = time.time()
            while not SHUTDOWN.is_set():
                try:
                    msg = q.get(timeout=1.0)
                    self._send_sse(msg, event=msg.get("event", "message"))
                except queue.Empty:
                    pass
                # 心跳
                if time.time() - last_keepalive > 15:
                    self.wfile.write(b": keepalive\n\n")
                    self.wfile.flush()
                    last_keepalive = time.time()
        finally:
            bc.unsubscribe(q)

    def _handle_stream_index(self):
        bc = get_index_broadcaster()
        self._write_sse_headers()
        self._send_sse({"ts": time.time()}, event="hello")

        q = bc.subscribe()
        try:
            last_keepalive = time.time()
            while not SHUTDOWN.is_set():
                try:
                    msg = q.get(timeout=1.0)
                    self._send_sse(msg, event=msg.get("event", "message"))
                except queue.Empty:
                    pass
                if time.time() - last_keepalive > 15:
                    self.wfile.write(b": keepalive\n\n")
                    self.wfile.flush()
                    last_keepalive = time.time()
        finally:
            bc.unsubscribe(q)


# ─────────────────────────────────────────────────────────────────────────────
# main
# ─────────────────────────────────────────────────────────────────────────────
def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dash-dir", required=True)
    ap.add_argument("--trace-dir", default="")
    ap.add_argument("--data-file", required=True)
    ap.add_argument("--port", type=int, default=8889)
    ap.add_argument("--bind", default="127.0.0.1")
    # v1.7.2 新增：用于 /_data/contracts.json 跑 pl-contract-verify.sh
    # 缺省时 contracts 端点降级返回 available:false（不影响其它功能）
    ap.add_argument("--pl-home", default="")
    ap.add_argument("--pl-project", default="")
    ap.add_argument("--contracts-dir", default="")
    args = ap.parse_args()

    STATE["dash_dir"] = Path(args.dash_dir).resolve()
    STATE["trace_dir"] = Path(args.trace_dir).resolve() if args.trace_dir else None
    STATE["data_file"] = Path(args.data_file).resolve()
    STATE["pl_home"] = Path(args.pl_home).resolve() if args.pl_home else None
    STATE["pl_project"] = Path(args.pl_project).resolve() if args.pl_project else None
    STATE["contracts_dir"] = (
        Path(args.contracts_dir).resolve() if args.contracts_dir else None
    )

    def on_sig(signum, frame):
        SHUTDOWN.set()
        # 让 server 停
        try:
            server.shutdown()
        except Exception:
            pass

    signal.signal(signal.SIGINT, on_sig)
    signal.signal(signal.SIGTERM, on_sig)

    server = ThreadingHTTPServer((args.bind, args.port), Handler)
    # ThreadingHTTPServer 默认 allow_reuse_address=True；显式写一下以防回退
    server.allow_reuse_address = True
    server.daemon_threads = True

    # 静音 ConnectionResetError / BrokenPipeError 之类的无害日志（SSE 断连很正常）
    _orig_handle_error = server.handle_error
    def _quiet_handle_error(request, client_address):
        exc = sys.exc_info()[1]
        if isinstance(exc, (ConnectionResetError, BrokenPipeError)):
            return  # 正常断连，不打印
        if os.environ.get("PL_DASHBOARD_VERBOSE"):
            _orig_handle_error(request, client_address)
    server.handle_error = _quiet_handle_error
    print(f"[dashboard-server] http://{args.bind}:{args.port} (live reload via SSE)",
          file=sys.stderr, flush=True)
    print(f"[dashboard-server]   dash_dir     : {STATE['dash_dir']}", file=sys.stderr)
    print(f"[dashboard-server]   trace_dir    : {STATE['trace_dir']}", file=sys.stderr)
    print(f"[dashboard-server]   pl_home      : {STATE['pl_home']}", file=sys.stderr)
    print(f"[dashboard-server]   pl_project   : {STATE['pl_project']}", file=sys.stderr)
    print(f"[dashboard-server]   contracts_dir: {STATE['contracts_dir']}", file=sys.stderr)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        SHUTDOWN.set()


if __name__ == "__main__":
    main()
