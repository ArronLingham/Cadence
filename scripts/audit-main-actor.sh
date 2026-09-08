#!/bin/bash
# Finds `@Published` mutated from a bare `Task {}` with no hop to the main
# actor.
#
# This is not a style rule. `MusicManager` is an `ObservableObject` that is not
# itself `@MainActor`, so a bare `Task {}` inside it runs on the cooperative
# pool. Writing a `@Published` there makes Combine take its publisher lock and
# then makes SwiftUI try to sync onto the main thread to invalidate the
# attribute. If the main thread is inside its own publish at that moment, it is
# already blocked waiting for that same lock, and the two deadlock with no
# timeout and no crash — the app simply stops, and a menu-bar agent cannot be
# force-quit from the UI because it is not in that list.
#
# That is not hypothetical: it happened on 2026-09-07 at
# `MusicManager.updateIdleState`, and `hang-sample-2026-09-07.txt` is the
# sample. The app had to be killed by pid.
set -euo pipefail
cd "$(dirname "$0")/.."

python3 - "$@" <<'PY'
import re, sys, glob

bad = []
scanned = 0
for path in sorted(glob.glob('Sources/**/*.swift', recursive=True)):
    src = open(path).read()
    # Only types that actually publish can hit this.
    if '@Published' not in src:
        continue
    scanned += 1
    lines = src.split('\n')
    published = set(re.findall(r'@Published(?:\s+private\(set\))?\s+var\s+(\w+)', src))
    if not published:
        continue

    # A type annotated @MainActor as a whole isolates its bare Tasks already.
    if re.search(r'@MainActor\s*\n\s*(final\s+)?class', src):
        continue

    starts = [i for i, l in enumerate(lines)
              if re.search(r'Task(\(priority[^)]*\))?\s*\{', l) and '@MainActor' not in l]
    for s in starts:
        depth = 0
        started = False
        end = s
        for i in range(s, min(s + 200, len(lines))):
            depth += lines[i].count('{') - lines[i].count('}')
            if '{' in lines[i]:
                started = True
            if started and depth <= 0:
                end = i
                break
        body = '\n'.join(lines[s:end + 1])
        hops = any(h in body for h in
                   ('MainActor.run', '@MainActor', 'MainActor.assumeIsolated',
                    'DispatchQueue.main'))
        if hops:
            continue
        writes = sorted(p for p in published
                        if re.search(r'(self\.)?\b' + p + r'\s*=[^=]', body))
        if writes:
            bad.append((path, s + 1, writes))

print(f"Scanned {scanned} file(s) that publish")
if bad:
    print()
    for path, line, writes in bad:
        print(f"  {path}:{line}  writes {', '.join(writes)} off the main actor")
    print()
    print(f"FAIL: {len(bad)} bare Task(s) mutating @Published with no main-actor hop.")
    print("Add `@MainActor` to the Task, or hop explicitly before the write.")
    sys.exit(1)

print()
print("OK — every @Published write from a bare Task hops to the main actor")
PY
