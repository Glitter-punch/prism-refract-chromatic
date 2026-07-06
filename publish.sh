#!/bin/bash
# Publish the Prism phone app (publish/ only — never the World Bible, research, or roadmap).
# Needs:  Prism/secrets/github.json  →  {"owner":"<github username>","repo":"prism-app","branch":"main"}
#         Prism/secrets/github_token.txt  →  a fine-grained PAT with Contents: read/write on that repo
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"   # Prism/publish
PRISM="$(dirname "$HERE")"

CFG="$PRISM/secrets/github.json"
TOK="$PRISM/secrets/github_token.txt"
[ -f "$CFG" ] || { echo "missing $CFG"; exit 1; }
[ -f "$TOK" ] || { echo "missing $TOK"; exit 1; }
OWNER=$(python3 -c "import json;print(json.load(open('$CFG'))['owner'])")
REPO=$(python3 -c "import json;print(json.load(open('$CFG'))['repo'])")
BRANCH=$(python3 -c "import json;print(json.load(open('$CFG')).get('branch','main'))")
TOKEN=$(tr -d '[:space:]' < "$TOK")

cd "$HERE"
python3 sync_data.py

# safety net: refuse to publish private files
for f in structure_log.json roadmap.json; do
  [ -e "data/$f" ] && { echo "PRIVATE FILE data/$f present — aborting"; exit 1; }
done
[ -d "data/research" ] && { echo "PRIVATE DIR data/research present — aborting"; exit 1; }

if [ ! -d .git ]; then
  git init -b "$BRANCH" >/dev/null
  git config user.email "prism@local"
  git config user.name "Prism pipeline"
fi
cat > .gitignore <<'EOF'
.DS_Store
EOF
git add -A
if git diff --cached --quiet; then
  echo "nothing new to publish"
else
  git commit -m "Prism update $(date +%F)" >/dev/null
fi
# token passed per-invocation; never stored in git config
git push "https://x-access-token:${TOKEN}@github.com/${OWNER}/${REPO}.git" "$BRANCH:$BRANCH" --force-with-lease 2>&1 | sed "s/${TOKEN}/***/g" || \
git push "https://x-access-token:${TOKEN}@github.com/${OWNER}/${REPO}.git" "$BRANCH:$BRANCH" --force 2>&1 | sed "s/${TOKEN}/***/g"
echo "published → https://${OWNER}.github.io/${REPO}/"
