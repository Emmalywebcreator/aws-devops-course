# Solution · 3.2 incident — "healthy host count = 0 after secrets clean-up"

> Not linked from the module.

## Root cause

The secret `orders/dev/api-key` was **scheduled for deletion** (7-day recovery window). The running task was then stopped. To start a replacement, the ECS agent must fetch every secret in the task definition using the **task execution role**. Secrets Manager refuses `GetSecretValue` on a secret marked for deletion, so every new task fails before the container starts. No tasks → no healthy targets → ALB returns 503.

The secret wasn't "unused": the clean-up looked at *the app's code* (no secret name in it), not at *what reads the secret* (the task definition).

## Diagnosis path

1. **What does the service say?**
   ```bash
   aws ecs describe-services --cluster orders-dev --services orders-api \
     --query 'services[0].[runningCount,desiredCount,events[:5].message]' --output json
   ```
   → `runningCount 0`, `desiredCount 1`, events like *"service orders-api has started 1 tasks"* repeating — tasks start and die.
2. **Why do tasks die?**
   ```bash
   T="$(aws ecs list-tasks --cluster orders-dev --desired-status STOPPED --query 'taskArns[0]' --output text)"
   aws ecs describe-tasks --cluster orders-dev --tasks "$T" --query 'tasks[0].[stoppedReason,stopCode]' --output text
   ```
   → `ResourceInitializationError: unable to pull secrets or registry auth: … InvalidRequestException: You can't perform this operation on the secret because it was marked for deletion …` (wording may vary) · `TaskFailedToStart`.
   **Key insight:** it failed *before* the container ran, so there are **no app logs** — the log group being empty is a clue, not a dead end.
3. **Confirm the secret's state:**
   ```bash
   aws secretsmanager describe-secret --secret-id orders/dev/api-key --query '[Name,DeletedDate]' --output text
   ```
   → a `DeletedDate` is set.
4. *(Optional, real-world)* **Who did it?** CloudTrail `DeleteSecret` event:
   `aws cloudtrail lookup-events --lookup-attributes AttributeKey=EventName,AttributeValue=DeleteSecret --max-results 5`

Learners who look at IAM first (a reasonable guess for `ResourceInitializationError`) should find the execution role policy unchanged and still pointing at the right ARN — that rules out permissions and points back at the secret itself.

## Fix (no code change)

```bash
aws secretsmanager restore-secret --secret-id orders/dev/api-key
aws ecs update-service --cluster orders-dev --service orders-api --force-new-deployment >/dev/null
# (ECS would retry on its own; forcing a deployment just speeds it up)
```

Service recovers in 1–3 minutes. The value is unchanged, so the app's API key still matches. Source: https://docs.aws.amazon.com/secretsmanager/latest/userguide/manage_delete-restore-secret.html

## Prevention (accept any one, with reasoning)

- Tag secrets with the service that reads them (`used_by = orders-api`) and make "unused" mean "no task definition references it".
- Resource policy on production secrets denying `secretsmanager:DeleteSecret` except to the Terraform/CI role.
- EventBridge rule on CloudTrail `DeleteSecret` → SNS alert.
- Keep the recovery window ≥ 7 days in every non-course environment (this incident was only recoverable because of it).

## Model incident note

> **Impact:** orders-dev fully down 03:05–03:30 (ALB 503, 0 healthy targets). **Root cause:** `orders/dev/api-key` was scheduled for deletion during a manual clean-up; the next task start couldn't fetch it (`ResourceInitializationError`). **Fix / prevention:** restored the secret and redeployed; added a deny-delete resource policy and a CloudTrail→SNS alert on `DeleteSecret`.
