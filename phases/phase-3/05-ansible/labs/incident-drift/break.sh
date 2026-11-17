#!/usr/bin/env bash
# Module 3.5 incident lab — a 02:00 manual "memory cap" on one host.
# Run from your aws-devops-platform/ansible directory with the venv active.
# Learners: run it, don't read it.
set -euo pipefail
[ -f site.yml ] || { echo "Run this from your ansible/ directory." >&2; exit 1; }

ansible orders-host-2 -b -m ansible.builtin.replace \
  -a "path=/etc/systemd/system/orders.service regexp='docker run --rm --name orders ' replace='docker run --rm --name orders --memory 24m '" >/dev/null
ansible orders-host-2 -b -m ansible.builtin.shell \
  -a "systemctl daemon-reload && systemctl restart orders" >/dev/null
echo "Incident started on orders-host-2."
