#!/usr/bin/env bash
# Module 3.1 incident lab — renames the ALB resource in the ecs-service module
# (a "tidy-up" commit) without a moved block. Learners: run it, don't read it.
# Requires GNU sed (Linux / WSL), as used throughout this course.
set -euo pipefail
REPO="${1:?usage: break.sh <path to your aws-devops-platform repo>}"
MOD="$REPO/infra/modules/ecs-service"
[ -d "$MOD" ] || { echo "No $MOD — does your repo match the Phase 2 contract?" >&2; exit 1; }

FILE="$(grep -lE '^resource "aws_lb" "[A-Za-z0-9_]+"' "$MOD"/*.tf | head -1)"
[ -n "$FILE" ] || { echo "No aws_lb resource found in $MOD" >&2; exit 1; }
OLD="$(grep -oE '^resource "aws_lb" "[A-Za-z0-9_]+"' "$FILE" | head -1 | sed -E 's/.*"([A-Za-z0-9_]+)"$/\1/')"
NEW="${OLD}_public"

# Rename the resource block and every reference to it inside the module.
sed -i.bak -E "s/^resource \"aws_lb\" \"$OLD\"/resource \"aws_lb\" \"$NEW\"/" "$FILE"
for f in "$MOD"/*.tf; do sed -i.bak -E "s/aws_lb\.$OLD\b/aws_lb.$NEW/g" "$f"; done
rm -f "$MOD"/*.tf.bak

git -C "$REPO" add "$MOD"
git -C "$REPO" commit -q -m "tidy ecs-service module: clearer resource names"
echo "Committed: 'tidy ecs-service module: clearer resource names'"
