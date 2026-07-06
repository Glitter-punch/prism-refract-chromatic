#!/usr/bin/env python3
"""Sync ONLY Prism-tab content into publish/data/ for the phone app.

Published: week_NN.json files + a pruned manifest (weeks and week_NN_start keys only).
NEVER published: structure_log.json (World Bible), research/*.json, roadmap.json
(upcoming themes are spoilers), world-bible exports, responses/.
Run from anywhere: paths are resolved relative to this file.
"""
import json, shutil, sys
from pathlib import Path

HERE = Path(__file__).resolve().parent          # Prism/publish
PRISM = HERE.parent                              # Prism/
SRC = PRISM / 'data'
DST = HERE / 'data'

def main():
    man = json.loads((SRC / 'manifest.json').read_text())
    weeks = man.get('weeks', [])
    pruned = {'weeks': weeks}
    for w in weeks:
        k = w.replace('.json', '') + '_start'
        if k in man:
            pruned[k] = man[k]
    DST.mkdir(exist_ok=True)
    # remove anything stale in DST that isn't a current week file
    for f in DST.iterdir():
        if f.name != 'manifest.json' and f.name not in weeks:
            (shutil.rmtree if f.is_dir() else Path.unlink)(f)
    for w in weeks:
        src = SRC / w
        if not src.exists():
            print(f'warn: {w} listed in manifest but missing', file=sys.stderr)
            continue
        json.loads(src.read_text())  # validate before publishing
        shutil.copy2(src, DST / w)
    (DST / 'manifest.json').write_text(json.dumps(pruned, indent=2))
    # safety: assert nothing private slipped in
    published = {p.name for p in DST.iterdir()}
    forbidden = {'structure_log.json', 'roadmap.json', 'research'}
    assert not (published & forbidden), f'private files in publish/data: {published & forbidden}'
    print(f'synced {len(weeks)} week(s): {", ".join(weeks)}')

if __name__ == '__main__':
    main()
