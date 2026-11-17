# Solution · 3.1 incident — "staging plan wants to replace the ALB"

> Not linked from the module.

## Root cause

A refactor commit renamed `resource "aws_lb" "<name>"` to `"<name>_public"` inside `infra/modules/ecs-service`. Terraform tracks objects by **address** (`module.ecs_service.aws_lb.<name>`). The old address disappeared from code while still in state, and a new address appeared with nothing in state → **destroy old + create new**. The listener references the ALB's ARN, which forces it to be replaced too. Because every env uses the same module, prod's next apply would do the same: new ALB, new DNS name, downtime.

## Diagnosis path

1. **Read the plan, not just the summary.**
   `terraform -chdir=infra/envs/staging plan -no-color | grep -E '^  # '`
   → `# module.ecs_service.aws_lb.<name> will be destroyed` and `# module.ecs_service.aws_lb.<name>_public will be created`. Same type, two names = a rename, not a real change.
2. **Confirm in state what exists:** `terraform -chdir=infra/envs/staging state list | grep aws_lb` → only the old address.
3. **Find the change:** `git diff main -- infra/modules/` (or `git log -p -1`) → the resource label changed.
4. **Ask "who else uses this module?"** → `grep -rn 'modules/ecs-service' infra/envs/` → dev, staging, prod. Impact is every env.

## Fix

Add to the module (e.g. `infra/modules/ecs-service/moved.tf`):

```hcl
moved {
  from = aws_lb.<name>
  to   = aws_lb.<name>_public
}
```

The block lives **in the module**, so it applies in every env that uses it, and travels to prod through the normal PR. Then:

```bash
terraform -chdir=infra/envs/staging plan -no-color | grep -E 'has moved to|to destroy'
# module.ecs_service.aws_lb.<name> has moved to module.ecs_service.aws_lb.<name>_public
# Plan: 0 to add, 0 to change, 0 to destroy.
```

(The listener no longer changes because the ARN it points at is the same object.)

**Why not `terraform state mv`?** It fixes one state file by hand, from one laptop. Dev and prod would still plan a replace, and nothing in code records the rename. `moved` is reviewable and repeatable. Source: https://developer.hashicorp.com/terraform/language/modules/develop/refactoring

## Model incident note

> **Impact:** none to users — caught at plan; staging/prod releases frozen 40 min. **Root cause:** renaming the ALB resource in the shared ecs-service module changed its Terraform address, so every env planned to replace the load balancer. **Fix:** added a `moved` block to the module; all three env plans now show 0 to destroy. **Follow-up:** CI fails any plan that destroys an `aws_lb` without an approval label.
