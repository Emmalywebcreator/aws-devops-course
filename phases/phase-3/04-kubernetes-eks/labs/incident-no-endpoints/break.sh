#!/usr/bin/env bash
# Module 3.4 incident lab — a "label tidy-up and probe fix" done live with kubectl.
# Learners: run it, don't read it.
set -euo pipefail
kubectl -n orders patch service orders-api -p '{"spec":{"selector":{"app":"orders"}}}' >/dev/null
kubectl -n orders patch deployment orders-api --type=json \
  -p '[{"op":"replace","path":"/spec/template/spec/containers/0/readinessProbe/httpGet/path","value":"/healthz"}]' >/dev/null
echo "Change applied at $(date +%H:%M). Check the synthetic: curl http://\$LB_HOST/health"
