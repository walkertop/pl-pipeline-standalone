#!/usr/bin/env python3
"""Summarize rule-scan violations and render YAML / console.

Mode 1 (summary):   python3 summarize-rules.py <violations.json>
                    -> prints JSON {'total':N,'error':E,'warn':W,'info':I}

Mode 2 (yaml):      python3 summarize-rules.py <violations.json> --yaml
                    -> prints YAML 'violations:' list body

Mode 3 (console):   python3 summarize-rules.py <violations.json> --console
                    -> prints human-readable list to stdout
"""
import sys
import json


def main():
    path = sys.argv[1]
    mode = sys.argv[2] if len(sys.argv) > 2 else '--summary'
    with open(path) as f:
        violations = json.load(f)

    if mode == '--summary':
        c = {'error': 0, 'warn': 0, 'info': 0}
        for v in violations:
            sev = v.get('severity', 'warn')
            c[sev] = c.get(sev, 0) + 1
        print(json.dumps({'total': len(violations), **c}))
        return

    if mode == '--yaml':
        if not violations:
            print("  []")
            return
        for v in violations:
            print(f"  - rule_id: \"{v['rule_id']}\"")
            print(f"    severity: {v['severity']}")
            print(f"    file: \"{v['file']}\"")
            msg = (v.get('message') or '').replace('\n', ' ').replace('"', '\\"')[:300]
            if msg:
                print(f"    message: \"{msg}\"")
            fix = (v.get('fix_hint') or '').replace('"', '\\"')
            if fix:
                print(f"    fix_hint: \"{fix}\"")
            print(f"    evidence: {json.dumps(v.get('evidence') or [], ensure_ascii=False)}")
        return

    if mode == '--console':
        for v in violations:
            icon = {'error': '✗', 'warn': '⚠', 'info': 'ℹ'}.get(v.get('severity'), '·')
            lines = ''
            for e in (v.get('evidence') or []):
                if 'line' in e:
                    lines = f" :line {e['line']}"
                    break
                if 'lines' in e and e['lines']:
                    lines = f" :lines {','.join(map(str, e['lines'][:3]))}"
                    break
            msg = (v.get('message') or '').splitlines()[0][:100] if v.get('message') else ''
            print(f"  {icon} [{v['rule_id']}] {v['file']}{lines}")
            if msg:
                print(f"      → {msg}")
            if v.get('fix_hint'):
                print(f"      fix: {v['fix_hint']}")
        return


if __name__ == '__main__':
    main()
