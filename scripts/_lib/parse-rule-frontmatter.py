#!/usr/bin/env python3
"""Parse YAML frontmatter from rule markdown files.

A rule file is recognized as "executable" if it starts with a YAML
frontmatter block:

    ---
    id: my-rule
    ...
    ---
    (markdown body)

Usage:
    python3 parse-rule-frontmatter.py <rule.md>
      -> prints JSON of frontmatter, or '{}' if none.

Empty output means "this rule is doc-only, not executable".

Implementation note: reuses the same minimal YAML subset parser as
scripts/_lib/parse-contract.py (bash 3.2 heredoc safe).
"""
import sys
import json
import re


def _scalar(s):
    s = s.strip()
    if s.startswith('"') and s.endswith('"'):
        inner = s[1:-1]
        # YAML double-quoted: 解释转义
        return inner.encode('utf-8').decode('unicode_escape')
    if s.startswith("'") and s.endswith("'"):
        # YAML single-quoted: '' 转义为 '，其他字符字面
        return s[1:-1].replace("''", "'")
    if s.startswith('[') and s.endswith(']'):
        inner = s[1:-1].strip()
        if not inner:
            return []
        parts = []
        cur = ''
        in_q = False
        for ch in inner:
            if ch == '"':
                in_q = not in_q
                cur += ch
            elif ch == ',' and not in_q:
                parts.append(cur)
                cur = ''
            else:
                cur += ch
        if cur.strip():
            parts.append(cur)
        return [_scalar(p) for p in parts]
    if s in ('true', 'false'):
        return s == 'true'
    if s == 'null':
        return None
    if re.match(r'^-?\d+$', s):
        return int(s)
    return s


def parse_yaml(text):
    """Minimal YAML parser. Supports: nested maps, list of strings,
    list of objects, flow-style lists, quoted keys, block scalars (|, >)."""
    lines = [l for l in text.splitlines() if l.strip() and not l.lstrip().startswith('#')]
    i = [0]

    def parse_block(indent):
        result = None
        while i[0] < len(lines):
            line = lines[i[0]]
            cur_indent = len(line) - len(line.lstrip())
            if cur_indent < indent:
                return result
            stripped = line.strip()
            if stripped.startswith('- '):
                if result is None:
                    result = []
                if isinstance(result, dict):
                    return result
                item_str = stripped[2:]
                if ':' in item_str and not item_str.startswith('"'):
                    k, v = item_str.split(':', 1)
                    obj = {}
                    v = v.strip()
                    if v:
                        obj[k.strip()] = _scalar(v)
                    else:
                        obj[k.strip()] = None
                    i[0] += 1
                    rest = parse_block(cur_indent + 2)
                    if isinstance(rest, dict):
                        for rk, rv in rest.items():
                            obj[rk] = rv
                    result.append(obj)
                else:
                    result.append(_scalar(item_str))
                    i[0] += 1
            elif ':' in stripped:
                if result is None:
                    result = {}
                if isinstance(result, list):
                    return result
                mm = re.match(
                    r'^"([^"]+)"\s*:\s*(.*)$|^\'([^\']+)\'\s*:\s*(.*)$|^([^:]+)\s*:\s*(.*)$',
                    stripped,
                )
                if mm:
                    k = (mm.group(1) or mm.group(3) or mm.group(5) or '').strip()
                    v = (mm.group(2) or mm.group(4) or mm.group(6) or '').strip()
                else:
                    k, v = stripped.split(':', 1)
                    k = k.strip()
                    v = v.strip()
                i[0] += 1
                if v == '' or v == '|' or v == '>':
                    # block scalar or nested block
                    if i[0] < len(lines) and (len(lines[i[0]]) - len(lines[i[0]].lstrip())) > cur_indent:
                        if v in ('|', '>'):
                            # collect indented lines as literal string
                            sub_indent = len(lines[i[0]]) - len(lines[i[0]].lstrip())
                            buf = []
                            while i[0] < len(lines):
                                ln = lines[i[0]]
                                ci = len(ln) - len(ln.lstrip())
                                if ci < sub_indent:
                                    break
                                buf.append(ln[sub_indent:])
                                i[0] += 1
                            joiner = '\n' if v == '|' else ' '
                            result[k] = joiner.join(buf)
                        else:
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


def extract_frontmatter(path):
    with open(path) as f:
        text = f.read()
    # 匹配 ^---\n ... \n---\n
    m = re.match(r'^---\s*\n(.*?)\n---\s*\n', text, re.S)
    if not m:
        return {}
    body = m.group(1)
    return parse_yaml(body) or {}


def main():
    if len(sys.argv) < 2:
        print("usage: parse-rule-frontmatter.py <rule.md>", file=sys.stderr)
        sys.exit(2)
    fm = extract_frontmatter(sys.argv[1])
    print(json.dumps(fm, ensure_ascii=False))


if __name__ == '__main__':
    main()
