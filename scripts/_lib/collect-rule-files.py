#!/usr/bin/env python3
"""Collect files matching a set of glob patterns from a host project root.

Usage:
    python3 collect-rule-files.py <host_root> <glob1> [glob2 ...] \
                                  [--exclude <eglob1> [eglob2 ...]]

Stdout: relative paths (one per line).
"""
import sys
import os
import fnmatch


SKIP_DIRS = {'node_modules', '.git', '.next', '__pycache__', '.venv', 'venv',
             'build', 'dist', '.playwright-mcp', '.codebuddy', 'pipeline-output'}


def glob_to_regex(pat):
    """Convert a glob (with **) to a regex that matches a full relative path.

    Semantics:
      **/   -> '' 或 '<zero-or-more-segments>/'（零个或多个路径段）
      /**   -> '' 或 '/<zero-or-more-segments>'
      **    -> '.*'
      *     -> '[^/]*'
      ?     -> '[^/]'
    """
    i = 0
    out = []
    while i < len(pat):
        c = pat[i]
        if pat[i:i+3] == '**/':
            out.append('(?:.*/)?')
            i += 3
        elif pat[i:i+3] == '/**' and (i + 3 == len(pat) or pat[i+3] == '/'):
            out.append('(?:/.*)?')
            i += 3
        elif pat[i:i+2] == '**':
            out.append('.*')
            i += 2
        elif c == '*':
            out.append('[^/]*')
            i += 1
        elif c == '?':
            out.append('[^/]')
            i += 1
        elif c in '.+()|{}^$\\':
            out.append('\\' + c)
            i += 1
        elif c == '[':
            # 字符类原样保留直到 ]
            j = pat.find(']', i)
            if j == -1:
                out.append('\\[')
                i += 1
            else:
                out.append(pat[i:j+1])
                i = j + 1
        else:
            out.append(c)
            i += 1
    return '^' + ''.join(out) + '$'


def main():
    args = sys.argv[1:]
    if not args:
        print("usage: collect-rule-files.py <host_root> <glob> [...] [--exclude <eglob> ...]", file=sys.stderr)
        sys.exit(2)
    host_root = args[0]
    rest = args[1:]
    try:
        split = rest.index('--exclude')
    except ValueError:
        split = len(rest)
    include = rest[:split]
    exclude = rest[split + 1:]

    import re
    inc_regex = [re.compile(glob_to_regex(g)) for g in include]
    exc_regex = [re.compile(glob_to_regex(g)) for g in exclude]

    matched = []
    for dirpath, dirs, files in os.walk(host_root):
        dirs[:] = [d for d in dirs if d not in SKIP_DIRS and not d.startswith('.')]
        for f in files:
            full = os.path.join(dirpath, f)
            rel = os.path.relpath(full, host_root)
            if any(r.match(rel) for r in inc_regex):
                if not any(r.match(rel) for r in exc_regex):
                    matched.append(rel)
    matched.sort()
    print('\n'.join(matched))


if __name__ == '__main__':
    main()
