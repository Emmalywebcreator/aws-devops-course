---
phase: "phase-3"
moduleId: "3.1"
title: "Multi-environment Terraform"
goal: "Run `dev` and `staging` from the same Terraform modules with fully separate state, promote one exact image from dev to staging, and keep `prod` as a reviewed plan \u2014 then prove a change to one environment can't silently hit another."
timeEstimate: "5-7h"
costEstimate: "<$0.80"
costAssumptions: "us-east-1, on-demand, no free tier assumed, author's unit prices as of 2026-11-17 (not yet checked against AWS pricing pages); if you skip teardown \u2248 $2.85/day"
lastVerified: null
prerequisites: ["0.6", "2.9"]
hasDebuggingLab: true
hasTeardown: true
toolsPinned:
  "terraform": "1.17.2"
  "aws-provider": "6.73.0"
  "awscli": "2.33.14"
  "runner": "ubuntu-24.04"
  "actions/checkout": "v7"
  "aws-actions/configure-aws-credentials": "v6"
  "hashicorp/setup-terraform": "v4"
---

# Phase 3 · Module 3.1 — Multi-environment Terraform

## 1. Goal

Run `dev` and `staging` from the same Terraform modules with fully separate state, promote one exact image from dev to staging, and keep `prod` as a reviewed plan — then prove a change to one environment can't silently hit another.

## 2. Prerequisites

- **Gates:** [Phase 0 exit gate](../../../assessments/gate-rules.md#part-2-the-phase-0-exit-gate-module-06) passed **and Phase 2 complete** (Phase 2 gate passed; your repo matches [the Phase 2 exit contract](../../phase-2/CONTRACT.md)).
- **You must already be able to:** `terraform init/plan/apply/destroy` the `dev` env, read a plan, and use the remote S3 state backend (Phase 2).
- **Tools:** Terraform **1.17.2**, AWS CLI **2.33.14**, Git, a GitHub repo `aws-devops-platform` with the `gha-deploy` OIDC role (Phase 2 contract §2).
- **Access:** your AWS admin profile; the repo secret `AWS_DEPLOY_ROLE_ARN` set to the `gha-deploy` role ARN (Phase 1).

## 3. Time estimate

**5–7 hours** (Lab 1: 1–1.5 h · Lab 2: 45 min · Lab 3: 1–1.5 h · Lab 4: 1–1.5 h · Incident lab: 45–60 min · teardown 20 min). Most of the waiting is ALB/ECS creation (≈ 5 min per env apply).

## 4. Cost estimate

| Resource | Billed while idle? | Unit price (assumption) | Expected use | Cost |
|---|---|---|---|---|
| `dev` env (ALB + 1 Fargate task 0.25 vCPU/0.5 GB + 3 public IPv4) | yes | ≈ USD 0.055/hour (Phase 2 contract §6) | ≤ 7 h | ≤ USD 0.39 |
| `staging` env (same shape) | yes | ≈ USD 0.055/hour | ≤ 5 h | ≤ USD 0.28 |
| `prod` env | — | **never applied** in this module (plan only) | 0 | USD 0 |
| Monitoring per env (1 dashboard + 2 alarms, Phase 2 contract §6) | yes, monthly | USD 3/month dashboard + USD 0.10/month per alarm metric; **free tier not assumed** | 2 envs | ≈ USD 0.21/day while both exist |
| S3 state + ECR storage (bootstrap, kept) | yes | ≈ USD 0.15/month (Phase 2 contract §2) | existing | ≈ USD 0.01 |
| GitHub Actions minutes | — | free for public repos / within free minutes for private | ~10 min | USD 0 |

- **Pricing assumptions:** Region `us-east-1`; on-demand; no free tier; per-env figure from the Phase 2 contract §6 (author's figures as of 2026-11-17), **not yet checked** against https://aws.amazon.com/fargate/pricing/, https://aws.amazon.com/elasticloadbalancing/pricing/, https://aws.amazon.com/vpc/pricing/, https://aws.amazon.com/cloudwatch/pricing/.
- **Total if you follow teardown:** under **USD 0.80**.
- **If you skip teardown: ≈ USD 2.85/day** (dev + staging: 2 × 0.055 × 24 = 2.64, plus 2 × USD 3.20/month monitoring ÷ 30 = 0.21). With the CloudWatch free tier covering dashboards/alarms: ≈ USD 2.64/day.

## 5. Concepts

### Why more than one environment

A change you've only tested on your laptop or in `dev` can still break production. A **staging** environment is a copy of production's *shape* where a release is proven first. **Production** is where real users are. The rule this module teaches: **every environment is built from the same code; only a few values differ** (size, count, name). If staging and prod drift apart in *code*, staging stops proving anything.

### Directory-per-environment (and why not workspaces here)

Terraform offers *workspaces* (one directory, many states) or *one directory per env* (`infra/envs/dev`, `infra/envs/staging`, `infra/envs/prod`), each with its own backend key.

- **This course uses directories:** the environment is visible in the path you type and in the PR diff, each has its own `backend.tf` key, and there's no hidden "which workspace am I in?" state that lets you apply to the wrong env.
- **Trade-off:** a little duplication in each `envs/<env>/main.tf` — kept tiny because all real logic lives in `infra/modules/`.
- **Source:** https://developer.hashicorp.com/terraform/language/state/workspaces (HashiCorp notes workspaces are not suitable for strong separation between environments that need separate credentials/access controls).

### State isolation

Each env's state is a separate object in the bootstrap bucket: `envs/dev/terraform.tfstate`, `envs/staging/terraform.tfstate`, `envs/prod/terraform.tfstate`. A `destroy` in one directory **can only touch resources in that state**. That's the blast-radius boundary.

### Promotion: the same artifact, not "the same code rebuilt"

Staging must run **the exact image** dev ran — same digest, not a rebuild. Each env records its image in `infra/envs/<env>/release.auto.tfvars`; promoting is a pull request that copies dev's tag into staging's file. Because ECR is `IMMUTABLE` (Phase 2), a tag can't be re-pointed to different bits.

### Prod as a plan

Running a third environment 24/7 costs money this course doesn't need to spend. Instead, CI runs `terraform plan` for prod on every infrastructure PR. You review what *would* happen to prod — that's the skill — without paying for it.

### `moved` blocks

Renaming a resource or module in code changes its **address**. Without help, Terraform sees "old address gone, new address present" and plans **destroy + create** — on a load balancer, that's an outage and a new DNS name. A `moved { from = … to = … }` block tells Terraform it's the same object.
**Source:** https://developer.hashicorp.com/terraform/language/modules/develop/refactoring

---

## 6. Labs

> **Region for every lab:** `us-east-1`. Run `export AWS_REGION=us-east-1` and `export AWS_PROFILE=<your-admin-profile>` in each new terminal (`aws login --profile <your-admin-profile>` first if your session expired). All commands run from the root of your `aws-devops-platform` repo on a new branch: `git switch -c phase3/multi-env`.

### Lab 1 — Create `staging` from the same modules

- **Region:** `us-east-1`
- **Task:**

```bash
# Copy only the configuration files — NOT the .terraform/ directory.
mkdir -p infra/envs/staging
cp infra/envs/dev/*.tf infra/envs/dev/.terraform.lock.hcl infra/envs/staging/

# Point staging at its own state object and name.
sed -i 's#envs/dev/terraform.tfstate#envs/staging/terraform.tfstate#' infra/envs/staging/backend.tf
grep -n 'key' infra/envs/staging/backend.tf          # must show envs/staging/terraform.tfstate
grep -rn '"dev"' infra/envs/staging/                  # change every env = "dev" to env = "staging"
```

Edit the line(s) found by the last `grep` so staging passes `env = "staging"` to every module. (macOS `sed` needs `sed -i ''`.)

**Why not `cp -r`?** `infra/envs/dev/.terraform/` remembers dev's backend. Copy it and `terraform init` in staging would offer to **migrate dev's state into staging** — two directories now "own" the same ALB.

```bash
terraform -chdir=infra/envs/staging init -input=false
DEV_TAG="$(terraform -chdir=infra/envs/dev output -raw image_tag)"   # Phase 2 contract §4: dev exports image_tag
echo "Deploying '$DEV_TAG' to staging"     # must print a sha-… tag, not ''
[ -n "$DEV_TAG" ] && terraform -chdir=infra/envs/staging apply -var "image_tag=$DEV_TAG"
```

If your dev env predates the `image_tag` output, add it (`output "image_tag" { value = var.image_tag }` in `infra/envs/dev/outputs.tf`) and `terraform -chdir=infra/envs/dev apply` before continuing.

- **Expected result:** `Apply complete!` with resources named `orders-staging…`. `curl` to the staging ALB returns `{"status":"ok"}`.
- **Verification command:**

```bash
STATE_BUCKET="tfstate-$(aws sts get-caller-identity --query Account --output text)-us-east-1"
aws s3 ls "s3://$STATE_BUCKET/envs/" --recursive | grep terraform.tfstate
# expect two lines: envs/dev/terraform.tfstate and envs/staging/terraform.tfstate

curl -fsS "http://$(terraform -chdir=infra/envs/staging output -raw alb_dns_name)/health"
# expect: {"status":"ok"}

terraform -chdir=infra/envs/dev plan -detailed-exitcode -var "image_tag=$DEV_TAG" >/dev/null; echo "dev plan exit: $?"
# expect: dev plan exit: 0   (creating staging changed nothing in dev)
```

- **Teardown command:** `./scripts/teardown.sh staging` (at module end — Lab 3 needs staging).
- **Cost note:** staging bills ≈ USD 0.055/hour while up.

### Lab 2 — Per-environment values, shared code

- **Region:** `us-east-1`
- **Task:** move the values that differ between envs into one small file per env, so `main.tf` is identical across envs except for `env`.

```bash
cat > infra/envs/dev/terraform.tfvars <<'EOF'
desired_count = 1
cpu           = 256
memory        = 512
EOF
cat > infra/envs/staging/terraform.tfvars <<'EOF'
desired_count = 1
cpu           = 256
memory        = 512
EOF
```

In each env's `variables.tf`, declare `desired_count`, `cpu`, `memory` (type `number`, no default) and pass them to `module "ecs_service"`. Then:

```bash
diff <(sed 's/"staging"/"ENV"/g' infra/envs/staging/main.tf) <(sed 's/"dev"/"ENV"/g' infra/envs/dev/main.tf) && echo "main.tf identical apart from env name"
```

- **Expected result:** the `diff` prints `main.tf identical apart from env name`; both plans show **no changes** (values are the same as before).
- **Verification command:**

```bash
for e in dev staging; do
  terraform -chdir=infra/envs/$e plan -detailed-exitcode -var "image_tag=<that env's tag>" >/dev/null; echo "$e: $?"
done
# expect: dev: 0   staging: 0
```

Now set `desired_count = 2` in **staging only**, run both plans again: expect `dev: 0`, `staging: 2` (2 = changes pending). Revert to `1`.

- **Teardown command:** none (code only). `git diff` should show only the new tfvars/variables changes.
- **Cost note:** USD 0 (plans only).

### Lab 3 — Promote one exact image from dev to staging

- **Region:** `us-east-1`
- **Task:** record each env's image tag in a file and promote by copying it.

```bash
DEV_TAG="<the sha-… tag dev is running>"
echo "image_tag = \"$DEV_TAG\"" > infra/envs/dev/release.auto.tfvars
echo "image_tag = \"$DEV_TAG\"" > infra/envs/staging/release.auto.tfvars
git add infra/envs/*/release.auto.tfvars && git commit -m "Promote $DEV_TAG to staging"
terraform -chdir=infra/envs/staging apply
```

`*.auto.tfvars` files are loaded automatically, so you no longer pass `-var image_tag=…` (a `-var` on the command line still overrides them).

- **Expected result:** staging's `/version` returns the same version as dev's.
- **Verification command:** prove the **digests** match, not just the tags:

```bash
digest_of_env () {
  local task; task="$(aws ecs list-tasks --cluster "orders-$1" --service-name orders-api --query 'taskArns[0]' --output text)"
  aws ecs describe-tasks --cluster "orders-$1" --tasks "$task" --query 'tasks[0].containers[0].imageDigest' --output text
}
echo "dev:     $(digest_of_env dev)"
echo "staging: $(digest_of_env staging)"
aws ecr describe-images --repository-name aws-devops-platform --image-ids imageTag="$DEV_TAG" \
  --query 'imageDetails[0].imageDigest' --output text
# expect: three identical sha256:… values
```

- **Teardown command:** none until module teardown.
- **Cost note:** no extra cost beyond the two running envs.

### Lab 4 — Prod as a plan in CI

- **Region:** `us-east-1`
- **Task:**
  1. Create `infra/envs/prod` exactly as in Lab 1 (backend key `envs/prod/terraform.tfstate`, `env = "prod"`), with `terraform.tfvars` `desired_count = 2` and `release.auto.tfvars` = staging's tag. **Do not apply it.**
  2. Replace the `plan` job in `.github/workflows/terraform.yml` with a matrix over all three envs:

```yaml
name: terraform
on:
  pull_request:
    paths: ["infra/**"]
permissions:
  id-token: write
  contents: read
jobs:
  plan:
    runs-on: ubuntu-24.04
    strategy:
      fail-fast: false
      matrix:
        env: [dev, staging, prod]
    concurrency: tfplan-${{ matrix.env }}
    steps:
      - uses: actions/checkout@v7
      - uses: aws-actions/configure-aws-credentials@v6
        with:
          role-to-assume: ${{ secrets.AWS_DEPLOY_ROLE_ARN }}
          aws-region: us-east-1
      - uses: hashicorp/setup-terraform@v4
        with:
          terraform_version: 1.17.2
      - run: terraform -chdir=infra/envs/${{ matrix.env }} fmt -check
      - run: terraform -chdir=infra/envs/${{ matrix.env }} init -input=false
      - run: terraform -chdir=infra/envs/${{ matrix.env }} validate
      - run: terraform -chdir=infra/envs/${{ matrix.env }} plan -input=false -no-color | tee plan.txt
      - run: tail -n 3 plan.txt >> "$GITHUB_STEP_SUMMARY"
```

  3. Push the branch and open a PR.

- **Expected result:** three `plan` jobs run. `dev` and `staging` summaries say `No changes.`; `prod` says `Plan: <N> to add, 0 to change, 0 to destroy.` (everything new, because prod was never applied).
- **Verification command:** in the PR → **Checks** tab (UI as of 2026-11-17), all three `plan (…)` jobs are green and each job summary shows its last plan line. Locally:

```bash
STATE_BUCKET="tfstate-$(aws sts get-caller-identity --query Account --output text)-us-east-1"
aws s3 ls "s3://$STATE_BUCKET/envs/prod/"
# expect: no terraform.tfstate (plan never writes state)
```

- **Teardown command:** none — prod has nothing to destroy.
- **Cost note:** USD 0 on AWS; a few GitHub Actions minutes.

## 7. Debugging lab (incident)

- **Scenario — the page you get:**

> 🔔 **#releases — 10:42** · *terraform / plan (staging)* on PR #31 "tidy ecs-service module": `Plan: 2 to add, 0 to change, 2 to destroy.` — and one of the destroys is the **load balancer**. Release freeze declared: the same module feeds prod. Nobody meant to touch the ALB. **You're on call — find out why, fix it so the plan is clean, and explain it in the incident note.**

- **How to create the broken state:** on a fresh branch, run the script (don't read it first):

```bash
export COURSE=<path to your clone of this course repo>     # e.g. ~/aws-devops-course
git switch main && git pull && git switch -c incident/3-1   # in your aws-devops-platform repo
bash "$COURSE/phases/phase-3/01-multi-env-terraform/labs/incident-alb-replace/break.sh" "$PWD"
terraform -chdir=infra/envs/staging plan
```

- **Symptom you will see:** the staging plan shows the ALB (`aws_lb`) **destroyed and created**, its listener replaced with it, and a summary with destroys in it (exact counts depend on your module).
- **Your task:** find the root cause using `terraform plan` output, `git diff main`, and `terraform state list`. Fix it **without** reverting the commit (the rename is wanted) and **without** `terraform state mv` by hand (the fix must travel to prod in code). Write a 3-line incident note: impact, root cause, fix.
- **Done when:**

```bash
terraform -chdir=infra/envs/staging plan -detailed-exitcode >/dev/null; echo "exit: $?"
# expect: exit: 0 — or exit 2 with a plan that shows only "has moved to" lines and 0 to destroy:
terraform -chdir=infra/envs/staging plan -no-color | grep -E 'to destroy|has moved to'
# expect: "...has moved to..." and "0 to destroy"
```

- **Teardown:** `git switch phase3/multi-env && git branch -D incident/3-1` (the fix is learning; you don't need to keep the rename). If you applied staging on the incident branch, run `terraform -chdir=infra/envs/staging apply` from `phase3/multi-env` to return to the main shape.

Diagnosis path: `solutions/incident.md`.

## 8. Self-check

Answers: `solutions/self-check.md`.

1. Show, with one command, that dev and staging have separate state objects. What would break if both pointed at the same key?
2. Why did Lab 1 forbid `cp -r infra/envs/dev infra/envs/staging`? What exactly would `terraform init` have offered to do?
3. Run the command that proves staging runs the *same bits* as dev. Why is matching tags not enough on a mutable repository?
4. Give one reason this course prefers directory-per-env over workspaces, and one cost of that choice.
5. A module change is merged and applied to dev. What in your CI guarantees you'll see its effect on prod before anyone applies prod?
6. What does a `moved` block do that `terraform state mv` doesn't, in a multi-env setup?
7. `terraform plan -detailed-exitcode` returned `2` for dev after a staging-only change. What does that tell you, and where do you look first?

## 9. Teardown

```bash
export AWS_REGION=us-east-1
./scripts/teardown.sh staging
./scripts/teardown.sh dev
```

**Confirm nothing is left:**

```bash
for e in dev staging prod; do
  echo "$e:"; aws resourcegroupstaggingapi get-resources --tag-filters Key=env,Values=$e \
    --query 'ResourceTagMappingList[].ResourceARN' --output text
done
# expect: each env name followed by no ARNs
aws elbv2 describe-load-balancers --query 'LoadBalancers[?starts_with(LoadBalancerName, `orders-`)].LoadBalancerName' --output text
aws ecs list-clusters --query 'clusterArns[?contains(@, `orders-`)]' --output text
# expect: no output from either
```

The bootstrap layer (ECR, OIDC role, state bucket) stays, per the Phase 2 contract. Commit and merge the `phase3/multi-env` branch so later modules start from three env directories.

## 10. Last verified

- **Date:** NOT YET VERIFIED — drafted 2026-11-17.
- **Verified by:** —
- **Region:** `us-east-1`
- **Versions:** Terraform 1.17.2 · AWS provider ~> 6.73 (6.73.0) · AWS CLI 2.33.14 · runner `ubuntu-24.04` · `actions/checkout@v7` · `aws-actions/configure-aws-credentials@v6` · `hashicorp/setup-terraform@v4`
- **Notes:** written against `phases/phase-2/CONTRACT.md` before Phase 2 was rewritten. Versions read from the Terraform checkpoint API and Terraform Registry on 2026-11-17. No command has been run against AWS.
