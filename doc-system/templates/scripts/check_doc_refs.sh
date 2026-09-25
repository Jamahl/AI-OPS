#!/usr/bin/env bash
# Documentation drift guard. Fails when the docs' cross-reference contract breaks:
#   1. every internal anchor link in PROJECT_OVERVIEW.md resolves to a real heading
#   2. every docs/*.md path referenced from PROJECT_OVERVIEW.md / CLAUDE.md / README.md
#      (and from within docs/*.md, where links are relative) exists
#   3. gotcha numbering in docs/GOTCHAS.md is contiguous 1..N with no duplicates
#      (numbers are a frozen contract — code references them by #N)
# Wired into check_all.sh; cheap enough to run on every checkpoint.
set -u
cd "$(dirname "$0")/.."

python3 - <<'PY'
import re, sys, glob, os

fail = []

def slugify(h):
    s = h.strip().lower()
    s = re.sub(r'[^\w\- ]', '', s)
    return s.replace(' ', '-')

DOCS = sorted(glob.glob('docs/*.md'))
ROOTS = ['PROJECT_OVERVIEW.md', 'CLAUDE.md', 'README.md']

# 1. internal anchors within each file that uses them
for src in ROOTS + DOCS:
    if not os.path.exists(src):
        continue
    body = open(src).read()
    slugs = {slugify(h) for h in re.findall(r'^#{1,4} (.+)$', body, re.M)}
    for target in re.findall(r'\]\(#([^)]+)\)', body):
        if target not in slugs:
            fail.append(f"anchor: {src} links (#{target}) but no heading slugs to it")

# 2. referenced doc paths exist (root files use docs/X.md, docs files link X.md or ../Y.md)
for src in ROOTS:
    if not os.path.exists(src):
        continue
    body = open(src).read()
    refs = set(re.findall(r'\]\((docs/[\w\-./]+\.md)\)', body)) | set(re.findall(r'`(docs/[\w\-./]+\.md)`', body))
    for p in refs:
        if not os.path.exists(p):
            fail.append(f"path: {src} references {p} which does not exist")

for src in DOCS:
    body = open(src).read()
    for p in set(re.findall(r'\]\(((?:\.\./)?[\w\-]+\.md)\)', body)):
        resolved = os.path.normpath(os.path.join('docs', p))
        if not os.path.exists(resolved):
            fail.append(f"path: {src} references {p} ({resolved}) which does not exist")

# 3. gotcha numbering lives in docs/GOTCHAS.md now
G = 'docs/GOTCHAS.md'
nums = []
if not os.path.exists(G):
    fail.append(f"gotchas: {G} not found")
else:
    g = open(G).read()
    nums = [int(n) for n in re.findall(r'^(\d+)\. \*\*', g, re.M)]
    if not nums:
        fail.append("gotchas: no numbered entries found")
    dupes = {n for n in nums if nums.count(n) > 1}
    if dupes:
        fail.append(f"gotchas: duplicate numbers {sorted(dupes)}")
    if nums != sorted(nums):
        fail.append("gotchas: numbers out of order (numbering is frozen — append only)")
    expected = list(range(1, max(nums) + 1)) if nums else []
    missing = sorted(set(expected) - set(nums))
    if missing:
        fail.append(f"gotchas: missing numbers {missing} (never delete — supersede in place)")

if fail:
    print("check_doc_refs: FAIL")
    for f in fail:
        print(f"  - {f}")
    sys.exit(1)
print(f"check_doc_refs: ok ({len(DOCS)} docs, gotchas 1..{max(nums) if nums else 0})")
PY
