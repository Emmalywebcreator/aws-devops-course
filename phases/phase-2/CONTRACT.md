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
├── Dockerfile                # FROM python:3.12.16-slim (exact), non-root, listens on 8000
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
| IAM role (CI) | `gha-deploy` | trust limited to the learner's repo (`sub` format per AUDIT §6). **Must trust both** `…:ref:refs/heads/main` (deploys) **and** `…:pull_request` (PR plans — Phase 3.1 matrix, 3.2 `policy` job). Permissions must include read on every `envs/*/terraform.tfstate` key and read/write/delete on `envs/*/*.tflock` (S3 native locking writes a lock object even for `plan`), plus read-only describe on the services Terraform manages. |
| S3 bucket (Terraform state) | `tfstate-<account-id>-<region>` | versioned, encrypted, public access blocked; backend uses `use_lockfile = true`; **lifecycle rule expires noncurrent object versions after 30 days** |

Ongoing cost (`us-east-1`, author's figures as of 2026-11-17, not yet checked against https://aws.amazon.com/ecr/pricing/ and https://aws.amazon.com/s3/pricing/): ECR storage USD 0.10/GB-month × (≈ 150 MB image × 10 kept ≈ 1.5 GB) ≈ **USD 0.15/month**; S3 state (a few MB, versions expire after 30 days) < **USD 0.01/month**. Phase 3 assumes these exist.

## 3. The app

| Item | Contract |
|---|---|
| Port | `8000` |
| Python | 3.12.16 (Docker `python:3.12.16-slim`; CI `actions/setup-python` `python-version: "3.12.16"`) |
| Endpoints | `GET /health` → `200 {"status":"ok"}` · `GET /orders` · `POST /orders` · `GET /version` → `{"version": "<APP_VERSION>"}` |
| Env vars | `APP_VERSION` · `LOG_LEVEL` (default `INFO`) · `FAIL_HEALTH` (`1` → `/health` returns 503) · `SLOW_MS` (adds latency to `/orders`) · `ERROR_RATE` (`0.0`–`1.0`: fraction of `/orders` requests that return 500; default `0`) · `ORDERS_API_KEY` (optional; if set, `POST /orders` requires header `x-api-key`) |
| Logs | one JSON object per line on stdout with keys `ts`, `level`, `msg`, `request_id`, `method`, `path`, `status`, `latency_ms` |
| Image tags | `sha-<first 12 chars of git SHA>`; never `latest` |

> **New vs legacy:** `ERROR_RATE`, `GET /version` and `ORDERS_API_KEY` are required by Phase 3 (3.2 secrets, 3.3 SLO drills, 3.4/3.5 version checks). **`GET /version` and `APP_VERSION` are built in Phase 1.1** (decision M-8a, MAPPING.md); Phase 2.6 (failure flags) adds `ERROR_RATE` and `ORDERS_API_KEY`.

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
**Deployment controller: `ECS`** (rolling updates in 2.3; **ECS-native blue/green** in 2.6 — closes decision D11). Phase 3 relies on this: `aws ecs update-service --task-definition …` and Terraform task-definition changes must work, which they don't under the CodeDeploy controller.
Creates: cluster `orders-<env>`, service `orders-api`, task family `orders-<env>`, ALB `orders-<env>-alb` (HTTP :80 default; HTTPS optional per M-5), target group `orders-<env>-tg` health-checking `/health`, security groups, log group `/ecs/orders-<env>`, task execution role `orders-<env>-task-exec`, task role `orders-<env>-task`.
Outputs: `alb_dns_name`, `alb_arn_suffix`, `target_group_arn_suffix`, `cluster_name`, `service_name`, `task_exec_role_name`, `task_role_name`, `log_group_name`.

### `modules/monitoring`
Inputs: `env`, `alb_arn_suffix`, `target_group_arn_suffix`, `alert_email`.
Creates: SNS topic `orders-<env>-alerts` (+ email subscription), **two** alarms (ALB 5xx, target health), one dashboard `orders-<env>`.
Outputs: `alerts_topic_arn`.

### `envs/dev`
Calls the three modules with `env = "dev"`. Variable `image_tag` (required). Outputs re-export all module outputs above **plus `image_tag`** (the tag currently deployed).

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

Region `us-east-1`, on-demand, author's figures as of 2026-11-17, **not yet checked** against https://aws.amazon.com/elasticloadbalancing/pricing/, https://aws.amazon.com/fargate/pricing/, https://aws.amazon.com/vpc/pricing/, https://aws.amazon.com/cloudwatch/pricing/.

| Item | Unit price (assumption) | Per hour |
|---|---|---|
| ALB | USD 0.0225/h + ≈ USD 0.008/h LCU at lab traffic | 0.0225–0.0305 |
| Fargate task 0.25 vCPU / 0.5 GB | USD 0.04048/vCPU-h, USD 0.004445/GB-h | 0.0123 |
| 3 public IPv4 (2 ALB, 1 task) | USD 0.005/h each | 0.015 |
| **Running env** | | **≈ USD 0.050–0.058/h → USD 1.20–1.39/day** |
| Monitoring module: 1 dashboard + 2 alarms | dashboard USD 3/month (first 3 free); alarm metric USD 0.10/month (first 10 free) | with free tier: 0 · without: USD 3.20/month ≈ **USD 0.11/day** |
| CloudWatch Logs ingestion | USD 0.50/GB (first 5 GB/month free) | lab traffic: < 10 MB/day ≈ 0 |

Phase 3 modules use **USD 0.055/h (USD 1.32/day)** as the per-env figure and add the monitoring line when they state "no free tier".
