# Scope · 0.6 Capstone mini-project + Phase 0 gate

> Planning document (Session C). Not module content, not published by the site.

**Draft front-matter**

```yaml
phase: "phase-0"
moduleId: "0.6"
title: "Capstone mini-project + Phase 0 gate"
goal: "Prove readiness for Phase 1 by building and tearing down a tiny stack from a script."
timeEstimate: "4-6h"
costEstimate: "<$1"
costAssumptions: "us-east-1, on-demand, no free tier assumed, author's prices 2026-11-17 (to be checked); no NAT Gateway, no Elastic IP; if you skip teardown ≈ $0.39/day"
lastVerified: null
prerequisites: ["0.0", "0.1", "0.2", "0.3", "0.4", "0.5"]
hasDebuggingLab: true
hasTeardown: true
toolsPinned: { awscli: "2.33.14", bash: "5.2.21", "al2023-ami": "<AMI ID recorded in the module>" }
```

**Sources:** spec "Module 0.6"; `assessments/gate-rules.md` Part 2 (Gates A–D, Gate C contract); exit-gate rubric in `/solutions/assessments/`.
**Gate to pass (spec):** build + tear down a tiny stack.

## 1. Goal
Prove readiness for Phase 1 by building and tearing down a tiny stack from a script.

## 2. Prerequisites
0.0–0.5 (or a diagnostic placement that skipped some of them — gate-rules §1.4).

## 3. Time estimate
4–6 h (spec).

## 4. Cost estimate
EC2 `t3.micro` + its public IPv4 + 8 GiB gp3 + a near-empty S3 bucket, for a few hours: < USD 0.10. **No NAT Gateway and no Elastic IP** (Gate C contract). Skip-teardown ≈ USD 0.39/day (0.0104 + 0.005 per hour × 24 + disk).

## 5. Concepts
**The app is `orders-api`** — the same app Phase 1.1 builds (decision 6). In 0.6 it is the smallest possible version: a Python standard-library HTTP server with `GET /health` → `{"status":"ok"}` and `GET /version` → `{"version":"<APP_VERSION>"}`, run as a systemd service. Phase 1.1 rebuilds `orders-api` with FastAPI and tests in the `aws-devops-platform` repo, keeping the same name and the same two endpoints. Infrastructure from a script (repeatable, reviewable) as the bridge to IaC in Phase 1; idempotent-ish create/teardown scripts; tagging so teardown can be proved; why the console is only for *confirming*.

## 6. Labs (spec + Gate C contract)
1. **Build script** (`build.sh`, CLI only, `us-east-1`): VPC, one public subnet + IGW + route, security group allowing the app port from your IP `/32` only, one EC2 instance running **`orders-api`** (user data installs the 0.4-style script as a systemd service — no Docker image build), an S3 bucket for logs. Every resource tagged `course=aws-devops-platform`, `phase=0`; the script prints the bucket name.
2. **Prove it works:** `curl` the app from your IP; prove another IP can't (e.g. from CloudShell).
3. **Teardown script** (`teardown.sh`): reverse dependency order; empties the bucket (incl. versions if on) before deleting it.
4. **Verify teardown clean:** run gate-rules G1–G6 and take the G7 Tag Editor screenshot ("confirm in the console that nothing billable remains").

## 7. Debugging lab
The capstone's own break: the first teardown run fails part-way (`DependencyViolation` deleting the VPC because a security group or ENI still exists). Learner finds the blocker and fixes the script's order, then re-runs to clean. This also feeds the write-up's "what I broke".

## 8. Self-check
Gate D explanations (exit-gate rubric): IAM evaluation; a request path through the VPC; why NAT costs money — plus the 1-page write-up "what I built, what I broke, how I fixed it".

## 9. Teardown
`teardown.sh`, then gate-rules G1–G7 as the confirmation (G4 tag sweep empty, G5 direct checks "not found", G6 all-region sweep empty, G7 screenshot).

## 10. Last verified
`null` until a human run.

**Deliverables (spec):** the repo, the teardown script, the 1-page write-up, the teardown confirmation screenshot, `phase-0-exit-evidence.md`.

## Decisions (approved 2026-11-17)
6. **Dedicated `p0-capstone` repo.** Phase 1.1 still creates `aws-devops-platform`.
6b. **The app is named `orders-api` here and everywhere after.** Phase 1.1 builds the same app (FastAPI), Phase 2 deploys it as the ECS service `orders-api` (CONTRACT §4), and Phase 3 reuses it. The 0.6 version implements only `/health` and `/version`.
