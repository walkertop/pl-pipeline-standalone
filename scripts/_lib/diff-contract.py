#!/usr/bin/env python3
"""Contract drift diff engine.

Args:
  1  path to contract.json    (parsed adapter contract block)
  2  path to exists.txt       (one file/dir path per line)
  3  path to npm-versions.txt (KEY=VERSION per line)
  4  path to py-versions.txt  (KEY=VERSION per line)
  5  host root path

Stdout: JSON array of drift entries.
"""
import sys
import json
import re
import os


def semver_check(spec, actual):
    """Loose semver check. Supports '>=X.Y.Z', '>=X.Y,<W', 'X.Y.Z', '*'."""
    if spec == '*' or spec == '' or actual in ('', '*'):
        return True, ''
    actual_parts = re.findall(r'\d+', actual)
    if not actual_parts:
        return True, f"actual version unparseable: {actual}"
    actual_t = tuple(int(x) for x in actual_parts[:3])
    # 支持 "," 或空格分隔多个 constraint（npm / pip 两派都兼容）
    # ">=18.0.0 <19.0.0" 等价于 ">=18.0.0,<19.0.0"
    normalized = re.sub(r'\s*,\s*', ',', spec.strip())
    normalized = re.sub(r'(\s+)(?=[<>=])', ',', normalized)
    constraints = [c.strip() for c in normalized.split(',') if c.strip()]
    for c in constraints:
        m = re.match(r'^(>=|<=|>|<|==|=)?\s*(\d+(?:\.\d+){0,2})', c)
        if not m:
            continue
        op = m.group(1) or '=='
        need = tuple(int(x) for x in m.group(2).split('.'))
        while len(need) < 3:
            need = need + (0,)
        a = actual_t + (0,) * (3 - len(actual_t))
        if op == '>=' and not (a >= need):
            return False, f"{actual} < {c}"
        if op == '>' and not (a > need):
            return False, f"{actual} not > {c}"
        if op == '<=' and not (a <= need):
            return False, f"{actual} > {c}"
        if op == '<' and not (a < need):
            return False, f"{actual} not < {c}"
        if op in ('==', '=') and a[:len(need)] != need:
            return False, f"{actual} != {c}"
    return True, ''


def main():
    if len(sys.argv) < 6:
        print("usage: diff-contract.py <contract.json> <exists.txt> <npm.txt> <py.txt> <host_root>", file=sys.stderr)
        sys.exit(2)

    with open(sys.argv[1]) as f:
        contract = json.load(f)
    with open(sys.argv[2]) as f:
        exists_raw = f.read()
    with open(sys.argv[3]) as f:
        npm_raw = f.read()
    with open(sys.argv[4]) as f:
        py_raw = f.read()
    host_root = sys.argv[5]

    existing = set(l.strip() for l in exists_raw.splitlines() if l.strip())
    npm_map = {}
    for l in npm_raw.splitlines():
        if '=' in l:
            k, v = l.split('=', 1)
            npm_map[k.strip()] = v.strip()
    py_map = {}
    for l in py_raw.splitlines():
        if '=' in l:
            k, v = l.split('=', 1)
            py_map[k.strip()] = v.strip()

    entries = []

    # 1. expected_files
    for ef in (contract.get('expected_files') or []):
        if not isinstance(ef, dict):
            continue
        path = ef.get('path')
        if not path:
            continue
        alts = ef.get('alt_paths') or []
        if not isinstance(alts, list):
            alts = [alts]
        all_paths = [path] + alts
        hit = False
        for p in all_paths:
            if p in existing:
                hit = True
                break
            if os.path.exists(os.path.join(host_root, p)):
                hit = True
                break
        severity = ef.get('severity') or 'warn'
        if not hit:
            entries.append({
                'kind': 'missing_file',
                'id': path,
                'declared': {'path': path, 'alt_paths': alts, 'kind': ef.get('kind', 'file')},
                'actual': {'exists': False},
                'severity': severity,
                'message': ef.get('note') or f"expected file/dir '{path}' not found in host",
            })

    # 2. peer_versions
    pv_namespaces = contract.get('peer_versions') or {}
    for ns, deps in pv_namespaces.items():
        if not isinstance(deps, dict):
            continue
        host_map = npm_map if ns == 'npm' else (py_map if ns == 'python' else {})
        for pkg, spec in deps.items():
            actual = host_map.get(pkg, '')
            if not actual:
                entries.append({
                    'kind': 'peer_missing',
                    'id': f"{ns}:{pkg}",
                    'declared': {'namespace': ns, 'name': pkg, 'spec': spec},
                    'actual': {'installed': False},
                    'severity': 'error',
                    'message': f"declared peer {ns}:{pkg} {spec} not installed in host",
                })
                continue
            ok, why = semver_check(spec, actual)
            if not ok:
                entries.append({
                    'kind': 'peer_version_violation',
                    'id': f"{ns}:{pkg}",
                    'declared': {'namespace': ns, 'name': pkg, 'spec': spec},
                    'actual': {'namespace': ns, 'name': pkg, 'version': actual},
                    'severity': 'error',
                    'message': f"{ns}:{pkg} actual={actual} violates declared {spec} ({why})",
                })

    # 3. known_bad_combos
    for combo in (contract.get('known_bad_combos') or []):
        if not isinstance(combo, dict):
            continue
        cid = combo.get('id') or 'unknown'
        when = combo.get('when') or {}
        matched_all = True
        matches = []
        for ns, deps in when.items():
            host_map = npm_map if ns == 'npm' else (py_map if ns == 'python' else {})
            for pkg, spec in (deps or {}).items():
                actual = host_map.get(pkg)
                if actual is None:
                    matched_all = False
                    break
                ok, _ = semver_check(spec if spec != '*' else '>=0', actual)
                if not ok:
                    matched_all = False
                    break
                matches.append({'namespace': ns, 'name': pkg, 'actual': actual, 'spec': spec})
            if not matched_all:
                break
        if matched_all and matches:
            entries.append({
                'kind': 'bad_combo_hit',
                'id': cid,
                'declared': {'when': when, 'rule_id': cid},
                'actual': {'matches': matches},
                'severity': combo.get('severity') or 'warn',
                'message': (combo.get('message') or '').strip(),
            })

    print(json.dumps(entries, ensure_ascii=False))


if __name__ == '__main__':
    main()
