#!/usr/bin/env python3
"""observe-apply-rules.py — 业务语义规则引擎

读 events.jsonl 里的 artifact.* 事件，按 observe-rules.yaml 做语义升级，
回写业务事件（plan.task.added / task.done / state.transition / asset.promoted 等）
到同一条 events.jsonl。

用法：
  python3 observe-apply-rules.py \\
    --project /path/to/project \\
    --change  add-todo-list \\
    --rules-file $PL_HOME/assets/pl/observe-rules.default.yaml

设计：
  - 幂等：用 trace 里的 "inferred_by" 标记已经推断过的事件，不重复触发
  - 依赖 content-cache：为了 diff，需要 observe-fs 把文件内容按 sha 存一份
"""

import argparse
import json
import re
import sys
from pathlib import Path
from datetime import datetime, timezone

# ─── 简易 YAML 解析（复用之前的手写，不依赖 PyYAML）─────────────────
def parse_yaml(text):
    """极简 YAML（仅满足本文件的用法）。"""
    lines = [l for l in text.splitlines() if l.strip() and not l.lstrip().startswith("#")]
    i = [0]

    def parse_block(indent):
        result = None
        while i[0] < len(lines):
            line = lines[i[0]]
            cur_indent = len(line) - len(line.lstrip())
            if cur_indent < indent:
                return result
            stripped = line.strip()
            if stripped.startswith("- "):
                if result is None:
                    result = []
                if isinstance(result, dict):
                    return result
                item_str = stripped[2:]
                if ":" in item_str and not item_str.startswith('"'):
                    k, _, v = item_str.partition(":")
                    obj = {}
                    v = v.strip()
                    if v:
                        obj[k.strip()] = _scalar(v)
                    i[0] += 1
                    rest = parse_block(cur_indent + 2)
                    if isinstance(rest, dict):
                        obj.update(rest)
                    result.append(obj)
                else:
                    result.append(_scalar(item_str))
                    i[0] += 1
            elif ":" in stripped:
                if result is None:
                    result = {}
                if isinstance(result, list):
                    return result
                mm = re.match(
                    r'^"([^"]+)"\s*:\s*(.*)$|^\'([^\']+)\'\s*:\s*(.*)$|^([^:]+?)\s*:\s*(.*)$',
                    stripped,
                )
                if mm:
                    k = (mm.group(1) or mm.group(3) or mm.group(5) or "").strip()
                    v = (mm.group(2) or mm.group(4) or mm.group(6) or "").strip()
                else:
                    k, _, v = stripped.partition(":")
                    k = k.strip(); v = v.strip()
                i[0] += 1
                if v == "" or v in ("|", ">"):
                    if i[0] < len(lines) and (len(lines[i[0]]) - len(lines[i[0]].lstrip())) > cur_indent:
                        sub = parse_block(cur_indent + 2)
                        result[k] = sub if sub is not None else {}
                    else:
                        result[k] = None
                else:
                    result[k] = _scalar(v)
            else:
                i[0] += 1
        return result

    return parse_block(0)


def _scalar(s):
    s = s.strip()
    if s == "{}":
        return {}
    if s == "[]":
        return []
    if s.startswith('"') and s.endswith('"'):
        return s[1:-1].encode("utf-8").decode("unicode_escape")
    if s.startswith("'") and s.endswith("'"):
        return s[1:-1].replace("''", "'")
    if s.startswith("[") and s.endswith("]"):
        inner = s[1:-1].strip()
        if not inner:
            return []
        parts = []
        cur = ""
        in_q = False
        for ch in inner:
            if ch == '"':
                in_q = not in_q
                cur += ch
            elif ch == "," and not in_q:
                parts.append(cur)
                cur = ""
            else:
                cur += ch
        if cur.strip():
            parts.append(cur)
        return [_scalar(p) for p in parts]
    if s in ("true", "false"):
        return s == "true"
    if s == "null":
        return None
    if re.match(r"^-?\d+$", s):
        return int(s)
    return s


# ─── 事件处理 ────────────────────────────────────────────────────────
def load_events(trace_file: Path):
    if not trace_file.exists():
        return []
    events = []
    for line in trace_file.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line:
            continue
        try:
            events.append(json.loads(line))
        except json.JSONDecodeError:
            continue
    return events


def append_events(trace_file: Path, new_events):
    with trace_file.open("a", encoding="utf-8") as f:
        for e in new_events:
            f.write(json.dumps(e, ensure_ascii=False) + "\n")


def path_glob_match(pattern: str, target: str) -> bool:
    """支持 ** 的 glob 匹配"""
    i = 0
    out = []
    while i < len(pattern):
        c = pattern[i]
        if pattern[i : i + 3] == "**/":
            out.append("(?:.*/)?")
            i += 3
        elif pattern[i : i + 2] == "**":
            out.append(".*")
            i += 2
        elif c == "*":
            out.append("[^/]*")
            i += 1
        elif c == "?":
            out.append("[^/]")
            i += 1
        elif c in ".+()|{}^$\\":
            out.append("\\" + c)
            i += 1
        else:
            out.append(c)
            i += 1
    regex = "^" + "".join(out) + "$"
    return bool(re.match(regex, target))


def load_content_by_sha(project: Path, sha: str):
    """从 content-cache 读按 sha 寻址的文件内容。读不到返回 None。"""
    if not sha:
        return None
    cache = project / "pipeline-output" / "observe" / "content-cache"
    candidate = cache / f"{sha}.txt"
    if candidate.exists():
        try:
            return candidate.read_text(encoding="utf-8", errors="replace")
        except Exception:
            return None
    return None


def diff_added_lines(before_text, after_text):
    """返回 after 中但不在 before 的行"""
    before_set = set(before_text.splitlines()) if before_text else set()
    after_lines = after_text.splitlines() if after_text else []
    return [l for l in after_lines if l not in before_set]


def diff_modified_lines(before_text, after_text):
    """找对照行：同首列标识但内容不同。这里简化为 after 中不在 before 的行（和 added 等价）"""
    return diff_added_lines(before_text, after_text)


def diff_line_changed(before_text, after_text, regex_before, regex_after):
    """找 before 里符合 regex_before、after 里符合 regex_after 且两者对应位置不同的行。
    简化：找每个文本中符合 regex 的第一个匹配。"""
    before_m = None
    after_m = None
    if before_text:
        for l in before_text.splitlines():
            m = re.match(regex_before, l)
            if m:
                before_m = m
                break
    if after_text:
        for l in after_text.splitlines():
            m = re.match(regex_after, l)
            if m:
                after_m = m
                break
    if before_m and after_m and before_m.group(0) != after_m.group(0):
        return before_m, after_m
    return None, None


# ─── 规则匹配 ────────────────────────────────────────────────────────
def match_rule(rule, artifact_event, project: Path):
    """对一条 artifact 事件运行一条规则，返回要 emit 的事件列表（可能多条）"""
    trigger = rule.get("trigger", {}) or {}
    event_in = trigger.get("event_in", [])
    path_glob = trigger.get("path_glob", "")

    # 1. event 类型匹配
    if event_in and artifact_event.get("event") not in event_in:
        return []

    # 2. path glob 匹配
    artifact_path = artifact_event.get("data", {}).get("path", "")
    if path_glob and not path_glob_match(path_glob, artifact_path):
        return []

    # 3. 提取数据
    extract = rule.get("extract", {}) or {}
    if not isinstance(extract, dict):
        extract = {}
    diff_kind = extract.get("diff_kind")

    data = artifact_event.get("data", {})
    sha_before = data.get("sha256_before")
    sha_after = data.get("sha256_after")
    before_text = load_content_by_sha(project, sha_before) if sha_before else None
    after_text = load_content_by_sha(project, sha_after) if sha_after else None

    # 如果 extract 为空，直接 emit 一个事件
    if not diff_kind:
        return [build_emit(rule, artifact_event, {})]

    emit_list = []

    if diff_kind in ("added_lines", "modified_lines"):
        lines = (
            diff_added_lines(before_text, after_text)
            if diff_kind == "added_lines"
            else diff_modified_lines(before_text, after_text)
        )
        line_regex = extract.get("line_regex")
        if line_regex:
            for l in lines:
                m = re.match(line_regex, l)
                if m:
                    cap = extract.get("captures", {}) or {}
                    ctx = {k: _apply_capture(v, m, None) for k, v in cap.items()}
                    emit_list.append(build_emit(rule, artifact_event, ctx))
        else:
            for _ in lines:
                emit_list.append(build_emit(rule, artifact_event, {}))

    elif diff_kind == "line_changed":
        rb = extract.get("line_regex_before")
        ra = extract.get("line_regex_after")
        before_m, after_m = diff_line_changed(before_text, after_text, rb, ra)
        if before_m and after_m:
            cap = extract.get("captures", {}) or {}
            ctx = {k: _apply_capture(v, after_m, before_m) for k, v in cap.items()}
            emit_list.append(build_emit(rule, artifact_event, ctx))

    return emit_list


def _apply_capture(spec, after_m, before_m):
    """spec 可能是整数（after 第 N 组），或 'before.N' / 'after.N' 字符串"""
    if isinstance(spec, int):
        return after_m.group(spec) if after_m else None
    if isinstance(spec, str):
        if spec.startswith("before."):
            n = int(spec.split(".", 1)[1])
            return before_m.group(n) if before_m else None
        if spec.startswith("after."):
            n = int(spec.split(".", 1)[1])
            return after_m.group(n) if after_m else None
        # 纯数字字符串
        try:
            return after_m.group(int(spec)) if after_m else None
        except ValueError:
            return None
    return None


def build_emit(rule, source_event, ctx):
    emit_spec = rule.get("emit", {}) or {}
    event_type = emit_spec.get("event", "unknown.inferred")
    data_tpl = emit_spec.get("data_template", {}) or {}

    # 模板变量替换
    def fmt(v):
        if isinstance(v, str):
            out = v
            # 支持 {key} 替换 ctx 和 artifact data
            combined = {**source_event.get("data", {}), **ctx}
            for key, val in combined.items():
                out = out.replace("{" + key + "}", str(val) if val is not None else "")
            return out
        return v

    data = {k: fmt(v) for k, v in data_tpl.items()}
    data["inferred_by"] = rule.get("id", "unknown-rule")

    return {
        "ts": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "trace_id": source_event.get("trace_id"),
        "change_id": source_event.get("change_id"),
        "phase": source_event.get("phase"),
        "actor": f"script:pl-observe-rules@1.0.0",
        "event": event_type,
        "data": data,
    }


# ─── 主 ──────────────────────────────────────────────────────────────
def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--project", required=True)
    ap.add_argument("--change", required=True)
    ap.add_argument("--rules-file", required=True)
    ap.add_argument("--verbose", action="store_true")
    args = ap.parse_args()

    project = Path(args.project).resolve()
    rules_text = Path(args.rules_file).read_text(encoding="utf-8")
    rules_doc = parse_yaml(rules_text) or {}
    rules = rules_doc.get("rules", [])

    trace_file = project / "pipeline-output" / "trace" / f"{args.change}.events.jsonl"
    events = load_events(trace_file)

    # 已经被某条规则推断过的事件（按 trace_id+path+event+关键提取字段）不再处理
    def dedup_key_of(ev):
        d = ev.get("data") or {}
        # 关键区分字段：task_id / to_stage / target_path
        sig = d.get("task_id") or d.get("to_stage") or d.get("target_path") or ""
        return (
            ev.get("trace_id"),
            d.get("source_path") or d.get("path") or "",
            ev.get("event"),
            sig,
        )

    already = set()
    for ev in events:
        if "inferred_by" in (ev.get("data") or {}):
            already.add(dedup_key_of(ev))

    new_events = []
    for ev in events:
        if not ev.get("event", "").startswith("artifact."):
            continue
        for rule in rules:
            emits = match_rule(rule, ev, project)
            for em in emits:
                dedup_key = dedup_key_of(em)
                if dedup_key in already:
                    continue
                already.add(dedup_key)
                new_events.append(em)

    if new_events:
        append_events(trace_file, new_events)

    if args.verbose:
        print(
            f"[apply-rules] artifact events={sum(1 for e in events if e.get('event','').startswith('artifact.'))} "
            f"rules={len(rules)} emitted={len(new_events)}"
        )

    print(f"[apply-rules] emitted {len(new_events)} inferred event(s)")


if __name__ == "__main__":
    main()
