#!/usr/bin/env bash
# Module 3.2 incident lab — simulates a teammate "cleaning up unused secrets"
# followed by a task restart. Learners: run it, don't read it.
set -euo pipefail
export AWS_REGION="${AWS_REGION:-us-east-1}"

aws secretsmanager delete-secret --secret-id orders/dev/api-key \
  --recovery-window-in-days 7 >/dev/null

for t in $(aws ecs list-tasks --cluster orders-dev --service-name orders-api \
             --desired-status RUNNING --query 'taskArns[]' --output text); do
  aws ecs stop-task --cluster orders-dev --task "$t" --reason "host maintenance" >/dev/null
done
echo "Incident started. Wait ~2 minutes, then check the service."
