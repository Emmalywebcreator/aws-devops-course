#!/usr/bin/env bash
# Simulates how a scheduler (cron, CI, systemd) runs the deploy:
# from a different working directory, by executing the file directly.
set -u
LAB="$(cd "$(dirname "$0")" && pwd)"
cd /tmp
env "$LAB/deploy.sh"
echo "exit code: $?"
