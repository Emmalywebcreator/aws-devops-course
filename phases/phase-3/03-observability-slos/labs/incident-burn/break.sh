#!/usr/bin/env bash
# Module 3.3 incident lab — a "config hotfix" made outside Terraform.
# Learners: run it, don't read it.
set -euo pipefail
export AWS_REGION="${AWS_REGION:-us-east-1}"
CLUSTER=orders-dev SERVICE=orders-api

CUR="$(aws ecs describe-services --cluster "$CLUSTER" --services "$SERVICE" \
        --query 'services[0].taskDefinition' --output text)"
aws ecs describe-task-definition --task-definition "$CUR" --query taskDefinition --output json > /tmp/td.json

python3 - /tmp/td.json <<'PY'
import json, sys
p = sys.argv[1]
td = json.load(open(p))
for k in ["taskDefinitionArn", "revision", "status", "requiresAttributes", "compatibilities",
          "registeredAt", "registeredBy", "deregisteredAt"]:
    td.pop(k, None)
app = td["containerDefinitions"][0]
env = [e for e in app.get("environment", []) if e["name"] not in ("ERROR_RATE", "LOG_LEVEL")]
env += [{"name": "ERROR_RATE", "value": "0.3"}, {"name": "LOG_LEVEL", "value": "DEBUG"}]
app["environment"] = env
json.dump(td, open(p, "w"))
PY

NEW="$(aws ecs register-task-definition --cli-input-json file:///tmp/td.json \
        --query 'taskDefinition.taskDefinitionArn' --output text)"
aws ecs update-service --cluster "$CLUSTER" --service "$SERVICE" --task-definition "$NEW" >/dev/null
rm -f /tmp/td.json
echo "Done. Start the traffic loop now."
