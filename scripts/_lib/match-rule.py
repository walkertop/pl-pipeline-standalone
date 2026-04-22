#!/usr/bin/env python3
"""Match a single rule against a set of candidate files.

Args:
  1  path to rule frontmatter JSON (from parse-rule-frontmatter.py)
  2  path to file list (one relative path per line, from collect-rule-files.py)
  3  host project root

Stdout: JSON array of violation entries.

Supported `detect[].kind`:
  - file_contains:      pattern (regex) matches anywhere in file
  - file_not_contains:  pattern does NOT match anywhere in file
  - line_contains:      regex matches on at least one line (records line numbers)

All detect items must be satisfied simultaneously for the file to violate.
"""
import sys
import json
import re


def check_file(file_abs, detects):
    """Return (matched: bool, evidence: list)."""
    try:
        with open(file_abs, 'r', encoding='utf-8', errors='replace') as f:
            content = f.read()
    except Exception as e:
        return False, [{'error': str(e)}]

    evidence = []
    for d in detects:
        kind = d.get('kind')
        pattern = d.get('pattern', '')
        if not pattern:
            continue
        try:
            rx = re.compile(pattern, re.MULTILINE)
        except re.error as e:
            return False, [{'error': f'invalid regex "{pattern}": {e}'}]

        if kind == 'file_contains':
            m = rx.search(content)
            if not m:
                return False, []
            # 记录行号
            line_no = content.count('\n', 0, m.start()) + 1
            evidence.append({'kind': kind, 'pattern': pattern, 'line': line_no})
        elif kind == 'file_not_contains':
            if rx.search(content):
                return False, []
            evidence.append({'kind': kind, 'pattern': pattern, 'satisfied': True})
        elif kind == 'line_contains':
            hits = []
            for idx, line in enumerate(content.splitlines(), 1):
                if rx.search(line):
                    hits.append(idx)
            if not hits:
                return False, []
            evidence.append({'kind': kind, 'pattern': pattern, 'lines': hits[:10]})
        else:
            # unknown kind — fail closed: treat as not matched to避免误报
            return False, [{'error': f'unknown detect kind: {kind}'}]

    return True, evidence


def main():
    if len(sys.argv) < 4:
        print("usage: match-rule.py <rule.json> <files.txt> <host_root>", file=sys.stderr)
        sys.exit(2)

    with open(sys.argv[1]) as f:
        rule = json.load(f)
    with open(sys.argv[2]) as f:
        files = [l.strip() for l in f if l.strip()]
    host_root = sys.argv[3]

    if not rule:
        print('[]')
        return

    detects = rule.get('detect') or []
    if not isinstance(detects, list) or not detects:
        print('[]')
        return

    rule_id = rule.get('id') or 'unknown'
    severity = rule.get('severity') or 'warn'
    message = (rule.get('message') or '').strip()
    fix_hint = (rule.get('fix_hint') or '').strip()

    import os
    violations = []
    for rel in files:
        file_abs = os.path.join(host_root, rel)
        matched, evidence = check_file(file_abs, detects)
        # 跳过 read-error 情况（evidence 里带 error）
        if evidence and any('error' in e for e in evidence):
            continue
        if matched:
            violations.append({
                'rule_id': rule_id,
                'severity': severity,
                'file': rel,
                'evidence': evidence,
                'message': message,
                'fix_hint': fix_hint,
            })

    print(json.dumps(violations, ensure_ascii=False))


if __name__ == '__main__':
    main()
