#!/usr/bin/env bash
set -euo pipefail
here="$(cd "$(dirname "$0")/.." && pwd)"
echo "rendered for ${APP_ENV}" > "$here/out/config.txt"
cat "$here/out/config.txt"
