#!/usr/bin/env python3
"""Collect host project file tree (non-recursive at deep level)."""
import os
import sys

SKIP = {'node_modules', '.git', '.next', '__pycache__', '.venv', 'venv', 'build', 'dist', '.playwright-mcp'}


def main():
    root = sys.argv[1]
    out = set()
    for dirpath, dirs, files in os.walk(root):
        dirs[:] = [d for d in dirs if d not in SKIP and not d.startswith('.')]
        rel_dir = os.path.relpath(dirpath, root)
        if rel_dir == '.':
            rel_dir = ''
        for f in files:
            rel = os.path.join(rel_dir, f) if rel_dir else f
            out.add(rel)
        if rel_dir:
            out.add(rel_dir)
    for entry in os.listdir(root):
        out.add(entry)
    print('\n'.join(sorted(out)))


if __name__ == '__main__':
    main()
