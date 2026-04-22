#!/usr/bin/env python3
"""Collect npm dependency versions from package-lock.json or package.json."""
import sys
import json
import re


def main():
    path = sys.argv[1]
    if path.endswith('package-lock.json'):
        with open(path) as f:
            try:
                data = json.load(f)
            except Exception:
                data = {}
        pkgs = data.get('packages') or {}
        for k, v in pkgs.items():
            if not k.startswith('node_modules/'):
                continue
            name = k[len('node_modules/'):]
            if '/' in name and not name.startswith('@'):
                continue
            if v.get('version'):
                print(f"{name}={v['version']}")
    elif path.endswith('package.json'):
        with open(path) as f:
            data = json.load(f)
        merged = {}
        for key in ('dependencies', 'devDependencies', 'peerDependencies'):
            merged.update(data.get(key) or {})
        for k, v in merged.items():
            cleaned = re.sub(r'^[\^~><=]+', '', v)
            print(f"{k}={cleaned}")


if __name__ == '__main__':
    main()
