#!/usr/bin/env bash
# Runs report.py the way a scheduler (cron) does: from another folder, with an almost empty environment.
# Learners: don't edit this file.
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
cd /tmp || exit 1
env -i PATH=/usr/bin:/bin ${REPORT_ENV:+REPORT_ENV="$REPORT_ENV"} /usr/bin/env python3 "$HERE/report.py"
echo "exit code: $?"
