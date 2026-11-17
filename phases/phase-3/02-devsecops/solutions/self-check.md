# Solution · 3.2 self-check

> Not linked from the module.

1. gitleaks — secrets in Git history; pip-audit — known-vulnerable Python dependencies; bandit — risky patterns in *your* code; Trivy — vulnerable OS/library packages inside the built image (things not in `requirements.txt`, like `openssl` in the base image); Checkov — insecure Terraform settings against built-in rules. (conftest = *your team's* rules on the plan.)
2. It skips CVEs with no released fix, so the gate only fails on things you can act on (bump a package/base image). Risk: a serious unfixed CVE passes silently — mitigate by reviewing the full report periodically and tracking unfixed criticals.
3. Any `#checkov:skip=CKV_…:<reason>`. The reason is the audit trail: a reviewer can tell an accepted risk from a lazy silence, and it can be revisited when the context (e.g. "dev only") changes.
4. Rule 1 in `policy/terraform.rego`. Prove: remove the `env` default tag in a test resource (or temporarily add `tags_all` without `env` via a provider-level override), re-plan, `conftest test plan.json --policy policy/` → `FAIL - <address> has no 'env' tag`.
5. `terraform state pull | grep -c "<value>"` → `0`. Terraform created only the secret resource; the value was written with `put-secret-value`, so it never passed through Terraform. If Terraform had set it (`aws_secretsmanager_secret_version`), the value would be in state in plain text.
6. The **task execution role** (used by the ECS agent before the container starts). Error: task stops with `ResourceInitializationError: unable to pull secrets or registry auth …`. The task role is what the app code uses at runtime.
7. Yes — `aws secretsmanager restore-secret --secret-id <name>` any time within the recovery window (7–30 days, default 30 if not specified; 7 in this module's Terraform). With `--force-delete-without-recovery` it's gone immediately and can't be restored.
8. Trivy releases 0.69.4–0.69.6 were malicious after the March 2026 supply-chain attack (CVE-2026-33634). A security scanner runs with access to your code and CI credentials, so an unpinned scanner is a supply-chain attack path; pin and bump deliberately.
