#!/usr/bin/env bash
# Module 0.3 debugging lab — builds a practice repo whose history contains a secret that was later "deleted".
# Learners: run this, don't read it. The diagnosis is in ../../solutions/debugging-lab.md.
#
#   bash break.sh                 builds ~/p0-git-debug  (remote.git = the "GitHub" copy, work = your clone)
#   bash break.sh /some/folder    builds it somewhere else (module 0.4 uses this to rebuild the repo)
#
# The "secret" is AWS's own documentation example key. It is not a real credential.
set -euo pipefail

TARGET="${1:-$HOME/p0-git-debug}"
rm -rf "$TARGET"
mkdir -p "$TARGET"

git init -q --bare -b main "$TARGET/remote.git"
git clone -q "$TARGET/remote.git" "$TARGET/work" 2>/dev/null
cd "$TARGET/work"
git config user.name "Practice Dev"
git config user.email "dev@example.com"

printf '# orders tool\n' > README.md
git add README.md && git commit -q -m "Add README"

printf 'print("orders tool v1")\n' > app.py
git add app.py && git commit -q -m "Add app"

printf 'AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE\nAWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY\n' > .env
git add .env && git commit -q -m "Add config"

printf 'print("orders tool v2")\n' > app.py
git commit -q -am "Update app to v2"

git rm -q .env
git commit -q -m "Remove env file"

printf '.env\n' > .gitignore
git add .gitignore && git commit -q -m "Add .gitignore"

git push -q origin main 2>/dev/null

echo "Practice repo ready:"
echo "  your clone : $TARGET/work"
echo "  the remote : $TARGET/remote.git   (this plays the part of GitHub)"
echo "Look at the latest commit's files, then decide: is anything secret in this repo?"
