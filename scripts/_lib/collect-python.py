#!/usr/bin/env python3
"""Collect python dependency versions from uv.lock or pyproject.toml."""
import sys
import re
import subprocess


def main():
    path = sys.argv[1]
    if path.endswith('uv.lock'):
        with open(path) as f:
            content = f.read()
        blocks = re.split(r'\[\[package\]\]', content)
        for b in blocks[1:]:
            m_name = re.search(r'^name\s*=\s*"([^"]+)"', b, re.M)
            m_ver = re.search(r'^version\s*=\s*"([^"]+)"', b, re.M)
            if m_name and m_ver:
                print(f"{m_name.group(1)}={m_ver.group(1)}")
        # also record the python interpreter version itself
        try:
            py = subprocess.check_output(['python3', '--version'], text=True).strip().split()[-1]
            print(f"python={py}")
        except Exception:
            pass
    elif path.endswith('pyproject.toml'):
        with open(path) as f:
            content = f.read()
        m = re.search(r'dependencies\s*=\s*\[(.*?)\]', content, re.S)
        if m:
            for line in m.group(1).splitlines():
                mm = re.search(r'"([a-zA-Z0-9_.\-\[\]]+?)\s*([<>=~!]+[^"]*)?"', line)
                if mm:
                    name = mm.group(1)
                    name = re.sub(r'\[.*\]', '', name)
                    ver = mm.group(2) or ''
                    ver = re.sub(r'^[<>=~!,\s]+', '', ver) or '*'
                    print(f"{name}={ver}")
        m_py = re.search(r'requires-python\s*=\s*"([^"]+)"', content)
        if m_py:
            ver = re.sub(r'^[<>=~!,\s]+', '', m_py.group(1))
            print(f"python={ver}")


if __name__ == '__main__':
    main()
