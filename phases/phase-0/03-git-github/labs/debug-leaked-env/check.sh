#!/usr/bin/env bash
# Module 0.3 debugging lab — checks your written answer. Usage: bash check.sh [folder]   (default ~/p0-git-debug)
# It looks for: the commit that introduced the secret, and the four remedy steps in your answer.md.
set -uo pipefail

TARGET="${1:-$HOME/p0-git-debug}"
ANSWER="$TARGET/answer.md"
pass=0; fail=0
ok()  { echo "PASS  $*"; pass=$((pass+1)); }
bad() { echo "FAIL  $*"; fail=$((fail+1)); }

[ -d "$TARGET/work/.git" ] || { echo "No practice repo at $TARGET/work — run break.sh first."; exit 2; }
[ -f "$ANSWER" ] || { echo "Write your answer to $ANSWER first."; exit 2; }

CULPRIT="$(git -C "$TARGET/work" log --all --diff-filter=A --format=%h -- .env | tail -1)"
if grep -qi "$CULPRIT" "$ANSWER"; then ok "names the commit that introduced .env ($CULPRIT)"; else bad "does not name the commit that introduced .env (find it with: git log --all --diff-filter=A -- .env)"; fi

grep -Eqi 'revoke|rotate|deactivate|invalidate' "$ANSWER" && ok "says to revoke/rotate the key" || bad "does not say to revoke/rotate the key"
grep -qi 'filter-repo' "$ANSWER" && ok "names the history-rewrite tool (git filter-repo)" || bad "does not name git filter-repo"
grep -Eqi 'force[- ]push|push --force|push -f' "$ANSWER" && ok "mentions force-pushing the rewritten history" || bad "does not mention force-pushing"
grep -Eqi 're-?clone|fresh clone|everyone|collaborator' "$ANSWER" && ok "says collaborators must re-clone" || bad "does not say collaborators must re-clone"
grep -Eqi 'gitignore|secret scanning|pre-commit|push protection' "$ANSWER" && ok "says how to prevent a repeat" || bad "does not say how to prevent a repeat"

# order: the revoke/rotate step must come before the filter-repo step
r="$(grep -Eni 'revoke|rotate|deactivate|invalidate' "$ANSWER" | head -1 | cut -d: -f1)"
f="$(grep -ni 'filter-repo' "$ANSWER" | head -1 | cut -d: -f1)"
if [ -n "$r" ] && [ -n "$f" ] && [ "$r" -lt "$f" ]; then ok "revoke/rotate comes BEFORE rewriting history"; else bad "revoke/rotate must come before rewriting history"; fi

echo; echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
