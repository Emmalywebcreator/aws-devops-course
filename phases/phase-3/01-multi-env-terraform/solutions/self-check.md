# Solution · 3.1 self-check

> Not linked from the module.

1. `aws s3 ls "s3://tfstate-<acct>-us-east-1/envs/" --recursive` → `envs/dev/terraform.tfstate` and `envs/staging/terraform.tfstate`. Same key → both directories think they own the same resources: a staging apply would "correct" dev's resources to staging's values, and a staging destroy would delete dev.
2. `.terraform/` caches the backend configuration. With dev's cache and staging's new `backend.tf`, `init` detects a backend change and offers to **copy existing state to the new backend** — i.e. dev's state into the staging key.
3. The `digest_of_env` comparison in Lab 3 (ECS task `imageDigest` vs `aws ecr describe-images … imageDigest`). On a mutable repo the same tag can be re-pushed with different content between deploys; the digest identifies the bits.
4. Reason: the env is explicit in the path and backend key, so you can't apply to the wrong env by forgetting `terraform workspace select`; also allows different backends/credentials per env (HashiCorp workspace docs). Cost: small duplicated `envs/<env>/*.tf` that must be kept identical (Lab 2's `diff` check).
5. The `terraform.yml` matrix plans **prod** (and dev/staging) on every PR that touches `infra/**`, including module-only changes.
6. A `moved` block is code: it's reviewed, and applies to *every* state that uses the module (dev, staging, prod) on their next plan/apply. `state mv` is a manual, one-state, unrecorded operation.
7. Exit `2` = changes pending in dev. A staging-only change shouldn't do that → something shared changed: look first at `git diff` under `infra/modules/` (or a shared file), then at the dev plan's resource list.
