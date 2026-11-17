# Phase 2 exit contract

**What this is:** the exact repo layout, names, inputs and outputs that **Phase 3 relies on**. Phase 3 modules were written against this contract before Phase 2 was rewritten (decision 2026-11-17). When Phase 2 modules 2.1–2.9 are rewritten (MAPPING.md), they **must** produce everything below — or this file and the Phase 3 modules that depend on it must be updated in the same change.

**Status:** draft 2026-11-17. Derived from MAPPING.md (decisions M-1…M-8, approved 2026-11-17) and the legacy Months 1–4 design.

## 1. One repo

The learner's GitHub repo **`aws-devops-platform`**, created in Phase 1.1 and extended by every module. Phase 3 adds to it; it never forks it.

```
aws-devops-platform/
├── app/
│   ├── main.py               # FastAPI app — see §3
│   └── requirements.txt      # every dependency pinned with ==
├── tests/                    # pytest
├── Dockerfile                # python:3.12.<patch>-slim, non-root, listens on 8000
├── compose.yaml
├── .github/workflows/
│   ├── ci.yml                # on pull_request: pytest + docker build
│   ├── deploy.yml            # on push to main: build → push ECR sha tag → deploy dev
│   └── terraform.yml         # on pull_request: fmt, validate, plan (dev)
├── infra/
│   ├── bootstrap/            # long-lived, see §2 — NOT destroyed by Phase 2 teardown
│   ├── modules/
│   │   ├── network/
│   │   ├── ecs-service/
│   │   └── monitoring/
│   └── envs/
│       └── dev/              # the only environment in Phases 1–2 (M-3)
├── scripts/
│   ├── teardown.sh           # ./scripts/teardown.sh <env>  — destroys envs/<env>, then verifies
│   ├── check_tags.py         # lists tagged resources still present; exit 1 if any
│   └── ecs_status.py
└── docs/
    └── runbook.md
```

## 2. Long-lived bootstrap (`infra/bootstrap/`, local or S3 state)

Created in Phase 1.4–1.5 / 2.2 and kept through Phase 3 because it's cheap and everything depends on it.

| Resource | Name | Notes |
|---|---|---|
| ECR repository | `aws-devops-platform` | `image_tag_mutability = "IMMUTABLE"` (from 2.5); lifecycle keeps last 10 images |
| IAM OIDC provider | `token.actions.githubusercontent.com` | |
| IAM role (CI) | `gha-deploy` | trust limited to the learner's repo, `sub` format per AUDIT §6 |
| S3 bucket (Terraform state) | `tfstate-<account-id>-<region>` | versioned, encrypted, public access blocked; backend uses `use_lockfile = true` |

Ongoing cost: ECR storage (≈ USD 0.10/GB-month) + S3 state (cents). Phase 3 assumes these exist.

## 3. The app

| Item | Contract |
|---|---|
| Port | `8000` |
| Endpoints | `GET /health` → `200 {"status":"ok"}` · `GET /orders` · `POST /orders` · `GET /version` → `{"version": "<APP_VERSION>"}` |
| Env vars | `APP_VERSION` · `LOG_LEVEL` (default `INFO`) · `FAIL_HEALTH` (`1` → `/health` returns 503) · `SLOW_MS` (adds latency to `/orders`) · `ERROR_RATE` (`0.0`–`1.0`: fraction of `/orders` requests that return 500; default `0`) · `ORDERS_API_KEY` (optional; if set, `POST /orders` requires header `x-api-key`) |
| Logs | one JSON object per line on stdout with keys `ts`, `level`, `msg`, `request_id`, `method`, `path`, `status`, `latency_ms` |
| Image tags | `sha-<first 12 chars of git SHA>`; never `latest` |

> **New vs legacy:** `ERROR_RATE`, `GET /version` and `ORDERS_API_KEY` are required by Phase 3 (3.2 secrets, 3.3 SLO drills). Phase 2.6 (failure flags) must add them.

## 4. Terraform

| Item | Contract |
|---|---|
| Terraform CLI | **1.17.2** (exact, in `setup-terraform` `terraform_version` and local install); `required_version = "~> 1.17.0"` |
| AWS provider | `~> 6.73` with `.terraform.lock.hcl` committed (6.73.0 at time of writing) |
| Region | `var.region`, default `us-east-1` |
| Default tags | `course = "aws-devops-platform"`, `phase = "<n>"`, `env = var.env`, `managed_by = "terraform"` |
| Backend key | `envs/<env>/terraform.tfstate` in the bootstrap state bucket |

### `modules/network`
Inputs: `env`, `cidr_block` (default `10.0.0.0/16`). Creates VPC, IGW, **two public subnets in two AZs**, public route table. **No NAT Gateway** (legacy no-NAT design; tasks get public IPs, protected by security groups).
Outputs: `vpc_id`, `public_subnet_ids`.

### `modules/ecs-service`
Inputs: `env`, `image_uri`, `desired_count` (default 1), `cpu` (default 256), `memory` (default 512), `container_env` (map(string), default `{}`), **`container_secrets`** (map(string) of env-var name → Secrets Manager ARN, default `{}`), `vpc_id`, `public_subnet_ids`.
The task execution role is granted `secretsmanager:GetSecretValue` on **exactly** the ARNs in `container_secrets` (none if empty).
Creates: cluster `orders-<env>`, service `orders-api`, task family `orders-<env>`, ALB `orders-<env>-alb` (HTTP :80 default; HTTPS optional per M-5), target group `orders-<env>-tg` health-checking `/health`, security groups, log group `/ecs/orders-<env>`, task execution role `orders-<env>-task-exec`, task role `orders-<env>-task`.
Outputs: `alb_dns_name`, `alb_arn_suffix`, `target_group_arn_suffix`, `cluster_name`, `service_name`, `task_exec_role_name`, `task_role_name`, `log_group_name`.

### `modules/monitoring`
Inputs: `env`, `alb_arn_suffix`, `target_group_arn_suffix`, `alert_email`.
Creates: SNS topic `orders-<env>-alerts` (+ email subscription), ALB 5xx and target-health alarms, one dashboard `orders-<env>`.
Outputs: `alerts_topic_arn`.

### `envs/dev`
Calls the three modules with `env = "dev"`. Variable `image_tag` (required). Outputs re-export all module outputs above.

## 5. Bring-up and teardown commands Phase 3 uses

```bash
export AWS_REGION=us-east-1
IMAGE_TAG="sha-$(git rev-parse --short=12 HEAD)"     # an image that exists in ECR
terraform -chdir=infra/envs/dev init
terraform -chdir=infra/envs/dev apply -var "image_tag=$IMAGE_TAG"
curl -fsS "http://$(terraform -chdir=infra/envs/dev output -raw alb_dns_name)/health"   # {"status":"ok"}

./scripts/teardown.sh dev       # destroy + check_tags.py; exit 0 only when nothing tagged env=dev remains
```

## 6. Cost baseline Phase 3 assumes for one running env

About **USD 0.05–0.06/hour** (ALB + one 0.25 vCPU / 0.5 GB Fargate task + 3 public IPv4), i.e. **≈ USD 1.20–1.45/day** if left up. Source: legacy course figures (AUDIT §3); re-check when Phase 2 is rewritten.
