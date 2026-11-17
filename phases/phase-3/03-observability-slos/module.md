---
phase: "phase-3"
moduleId: "3.3"
title: "Advanced observability: burn-rate alerting, error budgets and tracing"
goal: "Page a human only when the orders API is burning its error budget fast enough to matter, block releases when the budget is spent, and follow one failing request end to end with a distributed trace."
timeEstimate: "6-8h"
costEstimate: "<$0.60"
costAssumptions: "us-east-1, on-demand, no free tier assumed, author's unit prices as of 2026-11-17 (not yet checked against AWS pricing pages); if you skip teardown \u2248 $1.68/day"
lastVerified: null
prerequisites: ["0.6", "2.9", "3.1"]
hasDebuggingLab: true
hasTeardown: true
toolsPinned:
  "terraform": "1.17.2"
  "aws-provider": "6.73.0"
  "awscli": "2.33.14"
  "python": "3.12.16"
  "boto3": "1.44.4"
  "opentelemetry-sdk": "1.45.2"
  "opentelemetry-exporter-otlp": "1.45.2"
  "opentelemetry-instrumentation-fastapi": "0.66b2"
  "opentelemetry-sdk-extension-aws": "2.1.0"
  "opentelemetry-propagator-aws-xray": "1.0.2"
  "aws-otel-collector": "v0.51.0"
---

# Phase 3 · Module 3.3 — Advanced observability: burn-rate alerting, error budgets and tracing

## 1. Goal

Page a human only when the orders API is burning its error budget fast enough to matter, block releases when the budget is spent, and follow one failing request end to end with a distributed trace.

## 2. Prerequisites

- **Gates:** [Phase 0 exit gate](../../../assessments/gate-rules.md#part-2-the-phase-0-exit-gate-module-06) passed **and Phase 2 complete** (repo matches [the Phase 2 exit contract](../../phase-2/CONTRACT.md)). Phase 2 already taught you: structured logs, ALB metrics, defining an SLI/SLO, threshold alarms, dashboards and an incident drill. This module does **not** repeat them.
- **Modules:** [3.1 Multi-environment Terraform](../01-multi-env-terraform/module.md).
- **Tools:** Terraform 1.17.2, AWS CLI 2.33.14, Python 3.12 venv, Docker.
- **Access:** admin profile; the `orders-dev-alerts` SNS email subscription confirmed (Phase 2 monitoring module).

## 3. Time estimate

**6–8 hours** (Lab 1: 1–1.5 h · Lab 2: 1.5–2 h incl. alarm wait · Lab 3: 1 h · Lab 4: 1.5–2 h · Incident lab: 1 h · teardown 15 min).

## 4. Cost estimate

| Resource | Billed while idle? | Unit price (assumption) | Expected use | Cost |
|---|---|---|---|---|
| `dev` env (ALB + task + 3 public IPv4) | yes | ≈ USD 0.055/hour (Phase 2 contract §6) | ≤ 8 h | ≤ USD 0.44 |
| Task size raised to 0.5 vCPU / 1 GB for the tracing sidecar (Lab 4) | yes | Fargate ≈ USD 0.04048/vCPU-h + 0.004445/GB-h → +≈ USD 0.012/h | ≤ 4 h | ≤ USD 0.05 |
| Metric-math alarms (4) | yes, monthly | USD 0.10 per metric per alarm-month; 3 metrics each → USD 1.20/month | ≤ 1 day | ≤ USD 0.04 |
| Composite alarms (2) | yes, monthly | USD 0.50 per composite alarm-month → USD 1.00/month | ≤ 1 day | ≤ USD 0.04 |
| CloudWatch Logs ingestion (app logs; DEBUG during the incident; ADOT collector logs) | per GB | USD 0.50/GB ingested (assumption: first 5 GB/month free not counted) | < 50 MB | < USD 0.03 |
| Secrets Manager | — | **none created**: `enable_api_key_secret` stays `false` (module 3.2) | 0 | USD 0 |
| X-Ray traces | per trace | first 100,000 traces recorded/month free; then USD 5.00/million | < 10,000 | USD 0 |
| `GetMetricData` (error-budget script) | per request | USD 0.01 per 1,000 metrics requested | < 500 | < USD 0.01 |

- **Pricing assumptions:** Region `us-east-1`; on-demand; no free tier except the X-Ray allowance stated (so alarm metrics are counted even though the CloudWatch free tier covers 10 alarm metrics). Author's figures as of 2026-11-17, **not yet checked** against https://aws.amazon.com/cloudwatch/pricing/, https://aws.amazon.com/xray/pricing/, https://aws.amazon.com/fargate/pricing/.
- **Total if you follow teardown:** under **USD 0.60**.
- **If you skip teardown: ≈ USD 1.68/day** (env with sidecar (0.055 + 0.012) × 24 = 1.61 + alarms ≈ 0.07/day).

## 5. Concepts

### The problem with threshold alarms

Phase 2's alarm said "page if 5xx > N in 5 minutes". That pages for a 30-second blip at 3 a.m. *and* stays silent for a slow leak of 1% errors all week — which can spend your whole monthly budget. What you actually care about is: **"at this rate, will we break the SLO?"**

### Burn rate (building on Phase 2's SLO)

Phase 2 (modules 2.7–2.8) defined the SLI (successful requests ÷ all requests, from ALB metrics), the SLO (99.5% over 30 days) and the error budget (0.5% of requests may fail). This module uses those definitions unchanged and adds one idea:

- **Burn rate** = current error ratio ÷ budget ratio. Error ratio 0.5% → burn 1 (budget lasts exactly 30 days). Error ratio 7.2% → burn 14.4 → **2% of the month's budget gone in 1 hour**.
- Worked example: 1,000 requests/hour, 72 failing → ratio 0.072 → burn 0.072 / 0.005 = **14.4**.

### Multi-window, multi-burn-rate alerts

Page only when a high burn rate is **sustained** (long window) **and still happening** (short window), so you neither miss real problems nor get paged for ones that already stopped:

| Severity | Long window | Short window | Burn rate | Budget spent if it continues for the long window |
|---|---|---|---|---|
| **Page** (fast burn) | 1 h | 5 min | > 14.4 | 2% |
| **Ticket** (slow burn) | 6 h | 30 min | > 6 | 5% |

Each row = two CloudWatch metric-math alarms combined by a **composite alarm** (`ALARM(long) AND ALARM(short)`).
Source: Google SRE Workbook, "Alerting on SLOs" — https://sre.google/workbook/alerting-on-slos/ · CloudWatch metric math: https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/using-metric-math.html · composite alarms: https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Create_Composite_Alarm.html

### Error budget as a release policy

If the budget for the window is spent, **feature releases stop** until reliability work earns it back. Encoded as a pipeline step, that's a rule people can't forget at 5 p.m. on a Friday.

### Distributed tracing

Logs tell you *what* one component saw; metrics tell you *how much*. A **trace** follows **one request** through every component, as a tree of timed **spans**. **OpenTelemetry** (OTel) is the vendor-neutral standard for producing them; the **AWS Distro for OpenTelemetry (ADOT) collector** runs next to the app as a **sidecar** container and forwards spans to **AWS X-Ray**.
Sources: https://opentelemetry.io/docs/concepts/signals/traces/ · https://aws-otel.github.io/docs/setup/ecs

---

## 6. Labs

> **Region:** `us-east-1`. `export AWS_REGION=us-east-1 AWS_PROFILE=<your-admin-profile>`. Repo branch: `git switch -c phase3/slo`. Bring up dev: `terraform -chdir=infra/envs/dev apply` (image tag from `release.auto.tfvars`, module 3.1).

### Lab 1 — Compute the burn rate with metric math

- **Region:** `us-east-1`
- **Task:** generate traffic, then compute the error ratio with metric math from the CLI.

```bash
ALB="http://$(terraform -chdir=infra/envs/dev output -raw alb_dns_name)"
LB="$(terraform -chdir=infra/envs/dev output -raw alb_arn_suffix)"
for i in $(seq 1 600); do curl -s -o /dev/null "$ALB/orders"; sleep 0.5; done &   # ~5 min of traffic

cat > /tmp/sli.json <<EOF
[
  {"Id":"req","MetricStat":{"Metric":{"Namespace":"AWS/ApplicationELB","MetricName":"RequestCount","Dimensions":[{"Name":"LoadBalancer","Value":"$LB"}]},"Period":300,"Stat":"Sum"},"ReturnData":false},
  {"Id":"t5xx","MetricStat":{"Metric":{"Namespace":"AWS/ApplicationELB","MetricName":"HTTPCode_Target_5XX_Count","Dimensions":[{"Name":"LoadBalancer","Value":"$LB"}]},"Period":300,"Stat":"Sum"},"ReturnData":false},
  {"Id":"e5xx","MetricStat":{"Metric":{"Namespace":"AWS/ApplicationELB","MetricName":"HTTPCode_ELB_5XX_Count","Dimensions":[{"Name":"LoadBalancer","Value":"$LB"}]},"Period":300,"Stat":"Sum"},"ReturnData":false},
  {"Id":"burn","Expression":"((FILL(t5xx,0)+FILL(e5xx,0))/FILL(req,1))/0.005","Label":"burn rate (SLO 99.5%)"}
]
EOF
sleep 360
aws cloudwatch get-metric-data --metric-data-queries file:///tmp/sli.json \
  --start-time "$(date -u -d '-15 min' +%Y-%m-%dT%H:%M:%SZ)" --end-time "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --query 'MetricDataResults[0].[Label,Values]' --output json
```

(macOS: replace `date -u -d '-15 min'` with `date -u -v-15M`.)

- **Expected result:** the `burn rate` values are `0.0` (healthy app, no 5xx).
- **Verification command:** the `get-metric-data` command above returns at least one value and every value is `0.0`.
- **Teardown command:** `kill %1 2>/dev/null; rm -f /tmp/sli.json`
- **Cost note:** a few `GetMetricData` metrics — < USD 0.01.

### Lab 2 — Multi-window burn-rate alarms in Terraform

- **Region:** `us-east-1`
- **Task:** create `infra/modules/slo/` and call it from `infra/envs/dev`.

`infra/modules/slo/variables.tf`:

```hcl
variable "env" { type = string }
variable "alb_arn_suffix" { type = string }
variable "alerts_topic_arn" { type = string }

variable "slo_target" {
  type    = number
  default = 0.995
}

# Window lengths in seconds. Defaults are the SRE-workbook values.
variable "fast_long_seconds" {
  type    = number
  default = 3600 # 1 h
}
variable "fast_short_seconds" {
  type    = number
  default = 300 # 5 min
}
variable "slow_long_seconds" {
  type    = number
  default = 21600 # 6 h
}
variable "slow_short_seconds" {
  type    = number
  default = 1800 # 30 min
}
```

`infra/modules/slo/main.tf`:

```hcl
locals {
  budget = 1 - var.slo_target
  windows = {
    fast_long  = { seconds = var.fast_long_seconds,  burn = 14.4 }
    fast_short = { seconds = var.fast_short_seconds, burn = 14.4 }
    slow_long  = { seconds = var.slow_long_seconds,  burn = 6 }
    slow_short = { seconds = var.slow_short_seconds, burn = 6 }
  }
  dims = { LoadBalancer = var.alb_arn_suffix }
}

resource "aws_cloudwatch_metric_alarm" "burn" {
  for_each            = local.windows
  alarm_name          = "orders-${var.env}-burn-${each.key}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  threshold           = each.value.burn
  treat_missing_data  = "notBreaching"

  metric_query {
    id = "req"
    metric {
      namespace   = "AWS/ApplicationELB"
      metric_name = "RequestCount"
      dimensions  = local.dims
      period      = each.value.seconds
      stat        = "Sum"
    }
  }
  metric_query {
    id = "t5xx"
    metric {
      namespace   = "AWS/ApplicationELB"
      metric_name = "HTTPCode_Target_5XX_Count"
      dimensions  = local.dims
      period      = each.value.seconds
      stat        = "Sum"
    }
  }
  metric_query {
    id = "e5xx"
    metric {
      namespace   = "AWS/ApplicationELB"
      metric_name = "HTTPCode_ELB_5XX_Count"
      dimensions  = local.dims
      period      = each.value.seconds
      stat        = "Sum"
    }
  }
  metric_query {
    id          = "burn"
    expression  = "((FILL(t5xx,0)+FILL(e5xx,0))/FILL(req,1))/${local.budget}"
    label       = "burn rate"
    return_data = true
  }
}

resource "aws_cloudwatch_composite_alarm" "page" {
  alarm_name    = "orders-${var.env}-slo-fast-burn"
  alarm_rule    = "ALARM(\"${aws_cloudwatch_metric_alarm.burn["fast_long"].alarm_name}\") AND ALARM(\"${aws_cloudwatch_metric_alarm.burn["fast_short"].alarm_name}\")"
  alarm_actions = [var.alerts_topic_arn]
  ok_actions    = [var.alerts_topic_arn]
}

resource "aws_cloudwatch_composite_alarm" "ticket" {
  alarm_name    = "orders-${var.env}-slo-slow-burn"
  alarm_rule    = "ALARM(\"${aws_cloudwatch_metric_alarm.burn["slow_long"].alarm_name}\") AND ALARM(\"${aws_cloudwatch_metric_alarm.burn["slow_short"].alarm_name}\")"
  alarm_actions = [var.alerts_topic_arn]
}
```

In `infra/envs/dev/main.tf`, add the module. For **dev only**, shrink the windows so drills finish in minutes (a "lab mode" — staging and prod keep the defaults):

```hcl
module "slo" {
  source             = "../../modules/slo"
  env                = "dev"
  alb_arn_suffix     = module.ecs_service.alb_arn_suffix
  alerts_topic_arn   = module.monitoring.alerts_topic_arn
  fast_long_seconds  = 600   # lab mode: 10 min instead of 1 h
  fast_short_seconds = 60    # lab mode: 1 min instead of 5 min
}
```

Apply, then **drill**: set `ERROR_RATE = "0.2"` in dev's `container_env`, apply, and send traffic for 15 minutes (`for i in $(seq 1 1800); do curl -s -o /dev/null "$ALB/orders"; sleep 0.5; done`).

- **Expected result:** 20% errors ÷ 0.5% budget = burn 40 > 14.4. Within roughly 10–15 minutes, `orders-dev-slo-fast-burn` goes to `ALARM` and you get an email. The slow-burn composite stays `OK` until its 6 h window catches up. (TODO(verify): exact time-to-alarm for long-period metric-math alarms on a real run.)
- **Verification command:**

```bash
aws cloudwatch describe-alarms --alarm-names orders-dev-slo-fast-burn orders-dev-slo-slow-burn \
  --alarm-types CompositeAlarm --query 'CompositeAlarms[].[AlarmName,StateValue]' --output text
# during the drill: orders-dev-slo-fast-burn ALARM · orders-dev-slo-slow-burn OK
```

Then set `ERROR_RATE` back to `"0"`, apply, keep traffic going: the composite returns to `OK` once the short window clears (that's the point of the short window).

- **Teardown command:** `terraform -chdir=infra/envs/dev destroy -target=module.slo` if you stop here; otherwise section 9.
- **Cost note:** 4 metric-math alarms × 3 metrics × USD 0.10 + 2 composites × USD 0.50 = USD 2.20/month, prorated ≈ USD 0.07/day while they exist.

### Lab 3 — Error budget as a release gate

- **Region:** `us-east-1`
- **Task:** add `scripts/error_budget.py`, which reads the last N days of ALB metrics and exits non-zero when the budget is spent.

```python
"""Exit 1 if the error budget for the window is exhausted. Usage: error_budget.py <alb_arn_suffix> [days] [slo]"""
import sys
from datetime import datetime, timedelta, timezone

import boto3

lb, days, slo = sys.argv[1], int(sys.argv[2]) if len(sys.argv) > 2 else 7, float(sys.argv[3]) if len(sys.argv) > 3 else 0.995
end = datetime.now(timezone.utc)
start = end - timedelta(days=days)
dims = [{"Name": "LoadBalancer", "Value": lb}]


def q(i, name):
    return {"Id": i, "MetricStat": {"Metric": {"Namespace": "AWS/ApplicationELB", "MetricName": name, "Dimensions": dims},
                                     "Period": 86400, "Stat": "Sum"}}


cw = boto3.client("cloudwatch")
res = cw.get_metric_data(MetricDataQueries=[q("req", "RequestCount"), q("t5", "HTTPCode_Target_5XX_Count"),
                                            q("e5", "HTTPCode_ELB_5XX_Count")], StartTime=start, EndTime=end)
tot = {r["Id"]: sum(r["Values"]) for r in res["MetricDataResults"]}
req, bad = tot["req"], tot["t5"] + tot["e5"]
allowed = req * (1 - slo)
if req == 0:
    # No data is NOT "budget fine": wrong ALB suffix, rebuilt ALB, or no traffic. Fail loudly.
    print(f"window={days}d no RequestCount data for {lb} — check the ALB ARN suffix")
    sys.exit(2)
allowed = req * (1 - slo)
remaining = 1 - bad / allowed
print(f"window={days}d requests={req:.0f} errors={bad:.0f} allowed={allowed:.1f} budget_remaining={remaining:.1%}")
sys.exit(0 if remaining > 0 else 1)
```

Pin `boto3==1.44.4` in `requirements-ops.txt`.

In module 3.1 you promote by opening a PR that changes `infra/envs/staging/release.auto.tfvars`. Gate exactly that PR with `.github/workflows/promotion-gate.yml`:

```yaml
name: promotion-gate
on:
  pull_request:
    paths:
      - "infra/envs/staging/release.auto.tfvars"
      - "infra/envs/prod/release.auto.tfvars"
permissions:
  id-token: write
  contents: read
jobs:
  error-budget:
    runs-on: ubuntu-24.04
    if: ${{ !contains(github.event.pull_request.labels.*.name, 'budget-override') }}
    steps:
      - uses: actions/checkout@v7
      - uses: actions/setup-python@v7
        with: { python-version: "3.12.16" }
      - uses: aws-actions/configure-aws-credentials@v6
        with:
          role-to-assume: ${{ secrets.AWS_DEPLOY_ROLE_ARN }}
          aws-region: us-east-1
      - run: pip install -r requirements-ops.txt
      - run: python scripts/error_budget.py "${{ vars.DEV_ALB_ARN_SUFFIX }}" 7 0.995
```

Store the dev ALB suffix as a repository variable (re-run this whenever dev's ALB is rebuilt — the suffix changes, and the script then exits `2` instead of silently passing):

```bash
gh variable set DEV_ALB_ARN_SUFFIX --body "$(terraform -chdir=infra/envs/dev output -raw alb_arn_suffix)"
```

The `gha-deploy` role needs `cloudwatch:GetMetricData` (read-only) for this job. The `budget-override` PR label is the documented, reviewable way to ship a reliability fix while the budget is spent.

- **Expected result:** after the Lab 2 drill (20% errors on a few thousand requests), the budget for dev's last 7 days is spent and the script exits `1`. With a wrong suffix it exits `2`. A promotion PR shows the `promotion-gate / error-budget` check failing until you add the `budget-override` label.
- **Verification command:**

```bash
pip install boto3==1.44.4
python scripts/error_budget.py "$(terraform -chdir=infra/envs/dev output -raw alb_arn_suffix)" 1; echo "exit: $?"
# expect after the drill: budget_remaining=<negative %> and exit: 1
python scripts/error_budget.py "app/wrong-suffix/0000000000000000" 1; echo "exit: $?"
# expect: no RequestCount data … and exit: 2
```

- **Teardown command:** none (code only).
- **Cost note:** 3 metrics per run — < USD 0.01.

### Lab 4 — Trace a request with OpenTelemetry and X-Ray

- **Region:** `us-east-1`
- **Task:**

**4a. Instrument the app.** Add to `app/requirements.txt`:

```
opentelemetry-sdk==1.45.2
opentelemetry-exporter-otlp==1.45.2
opentelemetry-instrumentation-fastapi==0.66b2
opentelemetry-sdk-extension-aws==2.1.0
opentelemetry-propagator-aws-xray==1.0.2
```

Add `app/tracing.py` and call `setup_tracing(app)` right after `app = FastAPI()` in `app/main.py`:

```python
import os

from opentelemetry import trace
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor
from opentelemetry.propagate import set_global_textmap
from opentelemetry.propagators.aws import AwsXRayPropagator
from opentelemetry.sdk.extension.aws.trace import AwsXRayIdGenerator
from opentelemetry.sdk.resources import Resource
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor


def setup_tracing(app):
    if os.getenv("OTEL_ENABLED") != "1":
        return  # off by default: local runs and tests need no collector
    provider = TracerProvider(
        resource=Resource.create({"service.name": "orders-api", "deployment.environment": os.getenv("ENV", "dev")}),
        id_generator=AwsXRayIdGenerator(),
    )
    provider.add_span_processor(BatchSpanProcessor(OTLPSpanExporter(endpoint="http://localhost:4317", insecure=True)))
    trace.set_tracer_provider(provider)
    set_global_textmap(AwsXRayPropagator())
    FastAPIInstrumentor.instrument_app(app)
```

**4b. Add the collector sidecar.** In `infra/modules/ecs-service`, add an `enable_tracing` variable (`type = bool`, `default = false`). When true: append a second container to the task definition, attach `arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess` to the **task role**, and set `OTEL_ENABLED=1`:

```hcl
  # inside the container_definitions list, only when var.enable_tracing:
  {
    name      = "adot-collector"
    image     = "public.ecr.aws/aws-observability/aws-otel-collector:v0.51.0"
    essential = false
    command   = ["--config=/etc/ecs/ecs-default-config.yaml"]
    logConfiguration = { logDriver = "awslogs", options = {
      awslogs-group = aws_cloudwatch_log_group.this.name, awslogs-region = data.aws_region.current.region, awslogs-stream-prefix = "adot" } }
    # (adjust the log group reference to your module's name; add `data "aws_region" "current" {}` if the module lacks it — in provider 6.x the attribute is `region`; `name` is deprecated)
  }
```

Raise `cpu = 512`, `memory = 1024` for dev (`terraform.tfvars`), set `enable_tracing = true`, build/push the new image (Phase 2 pipeline), apply.

- **Expected result:** after ~20 requests, X-Ray shows traces for `orders-api` with a span per request; a request with `ERROR_RATE=0.2` shows `http.status_code = 500` on its span.
- **Verification command:**

```bash
for i in $(seq 1 20); do curl -s -o /dev/null "$ALB/orders"; done; sleep 60
aws xray get-trace-summaries --start-time "$(date -u -d '-10 min' +%s)" --end-time "$(date -u +%s)" \
  --query 'length(TraceSummaries)'
# expect: a number > 0
aws xray get-trace-summaries --start-time "$(date -u -d '-10 min' +%s)" --end-time "$(date -u +%s)" \
  --filter-expression 'service("orders-api") AND http.status = 500' --query 'length(TraceSummaries)'
# expect: > 0 while ERROR_RATE > 0; 0 when it's 0
```

(The v0.51.0 `ecs-default-config.yaml` sends the OTLP traces pipeline to the `awsxray` exporter, and X-Ray names the segment from `service.name`, so traces appear as `orders-api` — https://aws-otel.github.io/docs/setup/ecs.)

- **Teardown command:** section 9. To keep tracing code but stop paying for the sidecar: `enable_tracing = false`, `cpu = 256`, `memory = 512`, apply.
- **Cost note:** +≈ USD 0.012/hour for the bigger task; traces within the free 100,000/month.

## 7. Debugging lab (incident)

- **Scenario — the page you get:**

> 🚨 **PagerDuty — 14:07 — ALARM: `orders-dev-slo-fast-burn`.** Burn rate > 14.4 on both windows. Dashboard: request rate normal, p99 latency normal, 5xx rising. Nobody has merged anything today. **You're on call: stop the burn, find what changed and who/what changed it, and make Terraform agree with reality again.**

- **How to create the broken state** (dev up with Labs 2 + 4 applied, `ERROR_RATE` = `"0"`):

```bash
export COURSE=<path to your clone of this course repo>
bash "$COURSE/phases/phase-3/03-observability-slos/labs/incident-burn/break.sh"
# then generate normal traffic for 15 min in a second terminal:
ALB="http://$(terraform -chdir=infra/envs/dev output -raw alb_dns_name)"
for i in $(seq 1 1800); do curl -s -o /dev/null "$ALB/orders"; sleep 0.5; done
```

- **Symptom you will see:** within ~10–15 min the fast-burn composite alarm fires and the alert email arrives. `/health` still returns 200 — the service is "up" but failing a share of real requests.
- **Your task:** use X-Ray (`get-trace-summaries` with a `http.status = 500` filter, then `batch-get-traces` on one ID), the app's JSON logs (`aws logs tail /ecs/orders-dev --since 20m --filter-pattern '{ $.status = 500 }'`), `aws ecs describe-services` (deployments/events) and `aws ecs describe-task-definition` (diff revisions) to find the change. **Stop the burn first**, then fix it properly so `terraform plan` shows no drift. Write a 3-line incident note including budget spent.
- **Done when:**

```bash
aws cloudwatch describe-alarms --alarm-names orders-dev-slo-fast-burn --alarm-types CompositeAlarm \
  --query 'CompositeAlarms[0].StateValue' --output text                          # OK
terraform -chdir=infra/envs/dev plan -detailed-exitcode >/dev/null; echo "plan exit: $?"   # plan exit: 0
```

- **Teardown:** none beyond section 9.

Diagnosis path: `solutions/incident.md`.

## 8. Self-check

Answers: `solutions/self-check.md`.

1. SLO 99.5%. In one hour you served 2,000 requests and 50 failed. What's the burn rate, and would the fast-burn page fire?
2. Why does each alert pair a long window with a short one? What goes wrong with only the long one? Only the short one?
3. Why does dev use 10 min / 1 min windows, and why must staging and prod not?
4. Show the composite alarm rule for the fast-burn page. What happens if one of the two child alarms is missing data?
5. Run `scripts/error_budget.py` for dev. Explain each number it prints.
6. What can a trace tell you that the JSON log line for the same request can't?
7. Which IAM role needs `AWSXRayDaemonWriteAccess` — the task role or the execution role — and why?
8. During an incident, why do you roll back *before* you start debugging the root cause?

## 9. Teardown

```bash
export AWS_REGION=us-east-1
./scripts/teardown.sh dev      # removes env, its alarms (module.slo), composites and sidecar
```

**Confirm nothing is left:**

```bash
aws cloudwatch describe-alarms --alarm-name-prefix orders-dev --alarm-types MetricAlarm CompositeAlarm \
  --query '[MetricAlarms[].AlarmName, CompositeAlarms[].AlarmName][]' --output text
# expect: no output
aws resourcegroupstaggingapi get-resources --tag-filters Key=env,Values=dev \
  --query 'ResourceTagMappingList[].ResourceARN' --output text
# expect: no output
aws secretsmanager list-secrets --include-planned-deletion \
  --query "SecretList[?starts_with(Name, 'orders/')].Name" --output text
# expect: no output (enable_api_key_secret = false — module 3.2)
```

X-Ray traces expire on their own (30-day retention) and aren't billed for storage.

Before merging `phase3/slo`, put dev back to the size later modules assume: `enable_tracing = false`, `cpu = 256`, `memory = 512` in `infra/envs/dev/terraform.tfvars`. (Left at 512/1024, every later dev session costs ≈ USD 0.067/h instead of 0.055/h.)

## 10. Last verified

- **Date:** NOT YET VERIFIED — drafted 2026-11-17.
- **Verified by:** —
- **Region:** `us-east-1`
- **Versions:** Terraform 1.17.2 · AWS provider ~> 6.73 · AWS CLI 2.33.14 · Python 3.12 · boto3 1.44.4 · opentelemetry-sdk / exporter-otlp 1.45.2 · opentelemetry-instrumentation-fastapi 0.66b2 · opentelemetry-sdk-extension-aws 2.1.0 · opentelemetry-propagator-aws-xray 1.0.2 · ADOT collector `v0.51.0`
- **Notes:** versions read from PyPI and GitHub release APIs on 2026-11-17. No command run against AWS. Composite-alarm timing marked `TODO(verify)`; ADOT default config and `aws_region.region` confirmed by the qa agent on 2026-11-17. Written against `phases/phase-2/CONTRACT.md`; the `enable_tracing` input is added to the contract's ecs-service module by Lab 4.
