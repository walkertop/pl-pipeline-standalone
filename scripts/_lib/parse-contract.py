#!/usr/bin/env python3
"""YAML contract block parser for adapter.yaml.

Stdin: adapter.yaml content. Stdout: JSON of `contract:` block (or {}).

Used by scripts/piao-contract-drift-compute.sh. Extracted to a file to
side-step bash 3.2's buggy `$(cmd <<'EOF' ... EOF)` heredoc nesting
when the heredoc body contains many `)` chars.
"""
import sys
import json
import re


def _scalar(s):
    s = s.strip()
    if (s.startswith('"') and s.endswith('"')) or (s.startswith("'") and s.endswith("'")):
        return s[1:-1]
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
    if re.match(r'^-?\d+\.\d+$', s):
        return float(s)
    return s


def parse(text):
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


def main():
    if len(sys.argv) < 2:
        print("usage: parse-contract.py <adapter.yaml>", file=sys.stderr)
        sys.exit(2)
    with open(sys.argv[1]) as f:
        data = parse(f.read()) or {}
    contract = data.get('contract') or {}
    print(json.dumps(contract, ensure_ascii=False))


if __name__ == '__main__':
    main()
