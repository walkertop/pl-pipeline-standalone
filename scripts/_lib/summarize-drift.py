#!/usr/bin/env python3
"""Summarize contract-drift entries and render YAML body for the artifact.

Mode 1 (summary):   python3 summarize.py <entries.json>
                    -> prints JSON {'total':N,'error':E,'warn':W,'info':I}

Mode 2 (yaml):      python3 summarize.py <entries.json> --yaml
                    -> prints YAML 'entries:' list body

Mode 3 (console):   python3 summarize.py <entries.json> --console
                    -> prints human-readable bulleted list to stdout
"""
import sys
import json


def main():
    path = sys.argv[1]
    mode = sys.argv[2] if len(sys.argv) > 2 else '--summary'
    with open(path) as f:
        entries = json.load(f)

    if mode == '--summary':
        c = {'error': 0, 'warn': 0, 'info': 0}
        for e in entries:
            sev = e.get('severity', 'warn')
            c[sev] = c.get(sev, 0) + 1
        print(json.dumps({'total': len(entries), **c}))
        return

    if mode == '--yaml':
        if not entries:
            print("  []")
            return
        for e in entries:
            print(f"  - kind: {e['kind']}")
            print(f"    id: \"{e['id']}\"")
            print(f"    severity: {e['severity']}")
            msg = (e.get('message') or '').replace('\n', ' ').replace('"', '\\"')
            if msg:
                print(f"    message: \"{msg}\"")
            print(f"    declared: {json.dumps(e['declared'], ensure_ascii=False)}")
            print(f"    actual:   {json.dumps(e['actual'], ensure_ascii=False)}")
        return

    if mode == '--console':
        for e in entries:
            icon = {'error': '✗', 'warn': '⚠', 'info': 'ℹ'}.get(e.get('severity'), '·')
            msg = (e.get('message') or '')[:120]
            print(f"  {icon} [{e['kind']}] {e['id']}: {msg}")
        return


if __name__ == '__main__':
    main()
