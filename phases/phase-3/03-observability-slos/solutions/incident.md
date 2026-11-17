# Solution · 3.3 incident — "fast burn, nobody merged anything"

> Not linked from the module.

## Root cause

A new task-definition revision was registered and deployed **outside Terraform** (a manual "hotfix"). It added `ERROR_RATE=0.3` (and `LOG_LEVEL=DEBUG`, a red herring). 30% of `/orders` requests return 500 → burn rate 0.3 / 0.005 = **60**, far above 14.4. `/health` is unaffected, so the ALB keeps the task healthy and nothing "looks down".

## Diagnosis path

1. **Confirm it's real and how bad:** the composite is `ALARM`; Lab 1's metric-math query shows burn ≈ 60. At burn 60, a 30-day budget lasts ~12 hours.
2. **Which requests fail?** X-Ray:
   ```bash
   aws xray get-trace-summaries --start-time "$(date -u -d '-20 min' +%s)" --end-time "$(date -u +%s)" \
     --filter-expression 'service("orders-api") AND http.status = 500' --query 'TraceSummaries[:3].Id' --output text
   aws xray batch-get-traces --trace-ids <one id> --query 'Traces[0].Segments[].Document' --output text
   ```
   → only `GET/POST /orders`, failing inside the app span (not a downstream call, not the ALB). Logs agree: `aws logs tail /ecs/orders-dev --since 20m --filter-pattern '{ $.status = 500 }'`.
3. **What changed?** "Nobody merged" ≠ "nothing changed":
   ```bash
   aws ecs describe-services --cluster orders-dev --services orders-api \
     --query 'services[0].[taskDefinition,deployments[].[taskDefinition,createdAt,rolloutState]]' --output json
   ```
   → a revision newer than the one Terraform last applied, deployed minutes before the alarm.
4. **Diff the revisions:**
   ```bash
   for r in <N-1> <N>; do aws ecs describe-task-definition --task-definition orders-dev:$r \
     --query 'taskDefinition.containerDefinitions[0].environment' --output json > /tmp/env-$r.json; done
   diff /tmp/env-<N-1>.json /tmp/env-<N>.json
   ```
   → `ERROR_RATE` = `0.3` added. `registeredBy` on revision N names the identity that did it (`aws ecs describe-task-definition --task-definition orders-dev:<N> --query 'taskDefinition.registeredBy'`).
5. **Confirm drift:** `terraform -chdir=infra/envs/dev plan` wants to change the service's task definition back.

## Fix — two steps, in order

1. **Stop the burn (mitigate first, minutes matter):**
   ```bash
   aws ecs update-service --cluster orders-dev --service orders-api --task-definition orders-dev:<N-1>
   ```
2. **Make code and reality agree:** `terraform -chdir=infra/envs/dev apply` (re-asserts the Terraform-managed revision; plan then exits 0). If the hotfix had been *wanted*, the right fix is a PR changing `container_env`, not a console/CLI edit.

Alarm returns to `OK` once the short window (1 min in lab mode) has no breaching data.

## Budget spent (example)

Burning at 60 for 20 minutes = 60 × 20 / (30 × 24 × 60) ≈ **2.8%** of the 30-day budget.

## Model incident note

> **Impact:** ~30% of /orders requests failed for 22 min (burn ≈ 60, ≈ 3% of monthly budget); /health stayed green. **Root cause:** a task-definition revision registered outside Terraform set `ERROR_RATE=0.3`. **Fix / prevention:** rolled back to revision N-1, re-applied Terraform (no drift); removed `ecs:RegisterTaskDefinition` from human roles in non-dev envs so changes go through PRs.
