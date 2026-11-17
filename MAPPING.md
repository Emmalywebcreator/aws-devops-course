# MAPPING.md — legacy weeks → Phase 1 / Phase 2 (Stage 4, step 1)

**Status:** **approved 2026-11-17** (decisions M-1…M-8). No Phase 1–2 content has been rewritten yet. Phase 3 is written against `phases/phase-2/CONTRACT.md`.
**Source:** `index.html` (Module 0 + Months 1–6, 28 weeks), section structure per AUDIT.md §3.
**Rules applied:** CLAUDE.md phase scope:
- Phase 1 = Docker, Git-based CI, IaC intro.
- Phase 2 = Terraform, ECS, blue/green + rollback, observability.
- Phase 3 = EKS, Ansible, DevSecOps, multi-env.

Phase 0 scope follows the 0.0–0.6 spec.

## Phase boundary decisions this table depends on

| # | Decision | Proposed | Why |
|---|---|---|---|
| M-1 | Where ECS first appears | **Phase 2** (moved out of Month 1 Week 3) | CLAUDE.md puts ECS in Phase 2. Phase 1 deploys stop at "image pushed to ECR". |
| M-2 | What "IaC intro" in Phase 1 is | **Terraform basics on small, cheap resources**: ECR repo + GitHub OIDC role, local state | Phase 2 then adds remote state, modules and the ECS stack. One tool, two depths, no throwaway CloudFormation. |
| M-3 | Multi-env (dev/staging/prod, prod-as-plan) | **Phase 3** | CLAUDE.md. Phase 1–2 use **one environment** (`dev`) throughout. |
| M-4 | Approval gates (Month 3) | **Keep in Phase 2** as a manual approval before blue/green traffic shift in the single env. Prod-environment approvals → Phase 3. | Approval-before-shift is part of safe releases. Environment promotion is multi-env. |
| M-5 | HTTPS + custom domain (Month 2 Week 3) | **Phase 2, optional track.** The default path is HTTP on the ALB DNS name, with no domain purchase. | Resolves AUDIT B16 / D5. A domain is a money and card blocker. |
| M-6 | Docker install (legacy Lesson 0.6) | **Phase 1, module 1.2** | It isn't in the Phase 0 spec, and Phase 1 is the first place Docker is used. |
| M-7 | AWS fundamentals duplicated in Month 1 §1.1–1.2 (IAM, VPC, regions) | **Strip from Phase 1–2.** Link back to Phase 0 module 0.5. | Phase 0.5 will teach IAM evaluation, VPC and CLI (planned — not yet written). |
| M-8 | Phase gates | New **1.6** and **2.9** gate modules, each with teardown verification + written explanations, mirroring the 0.6 gate | CLAUDE.md requires hard gates between phases. The legacy course has none. |
| M-8a | `GET /version` + `APP_VERSION` (decided 2026-11-17, Session A) | Built in **1.1** (was 2.6). 2.6 still adds `ERROR_RATE` and `ORDERS_API_KEY`. | Trivial to build with the app; every later phase uses it to prove which build is running (gates 1.6/2.9, Phase 3.4/3.5). `CONTRACT.md` §3 updated. |

## Week-by-week mapping

Legend: **→** where it goes · ⤴ moved to Phase 3 (to be logged in PROGRESS.md "moved to Phase 3" when the module is rewritten) · ✂ stripped from this module (a forward reference, or a duplicate of earlier material).

| Legacy week | Legacy content (§) | → New home | ⤴ Moved to Phase 3 | ✂ Stripped / changed |
|---|---|---|---|---|
| M0 W0–2 | Lessons 0.1–0.7 | Phase 0 (0.0–0.4), already re-specced. 0.6 Docker install → **1.2** | — | WSL setup (0.1) has no home in the Phase 0 spec. **Open gap**, see below. |
| M1 W1 | §1.4 Design + build the FastAPI app locally, pytest | **1.1 The app: build and test locally** | — | ✂ "Month 2/3" mentions. Pin `fastapi`, `uvicorn`, `pytest`, `httpx` to tested versions. |
| M1 W2 | §1.5 Dockerfile, Compose, network drill | **1.2 Containers: install, Dockerfile, Compose** (+ legacy 0.6) | — | ✂ `FAIL_HEALTH`, `SLOW_MS`, `ENABLE_ERROR_ENDPOINT` in `compose.yaml` and the "Month 3" healthcheck comment → introduced in **2.5** instead. `python:3.12-slim` → patch-pinned tag. |
| M1 W3 | §1.6 ECR + ECS + ALB + IAM by hand | **ECR part → 1.5.** **ECS/ALB by hand → 2.1** | — | Remove the "service keeps running through W4–5" pattern. Every lab tears down the same session. |
| M1 W4 | §1.7 GitHub Actions + OIDC | **CI (lint/test/build on PR) → 1.3.** **OIDC + push to ECR → 1.5.** **Deploy to ECS → 2.3** | — | `ubuntu-latest` → pinned runner image. Actions stay `@vN`. |
| M1 W5 | §1.8 Failure testing, rollback, teardown, `ecs_status.py` | **2.3 Continuous deployment + rollback basics** | — | ✂ `ecs_status.py` docstring's `orders-dev`, a Month 2 name. Add ARN lookups instead of `<ALB_ARN>` placeholders. CLI teardown for security groups. |
| M1 W6 | §1.9 Docs, evidence, review | **1.6 Phase 1 gate** (evidence + review) | — | Review answers → `/solutions/`, out of nav. |
| M2 W1 | §2.1–2.5 Why IaC, concepts, install, domain + remote state bucket | **Concepts + install → 1.4 IaC intro.** **Remote state bucket → 2.2** | — | Pin the Terraform CLI version (apt + `setup-terraform` `terraform_version`). Domain → optional track (M-5). |
| M2 W2 | §2.6 Global layer, modules, dev env | **2.2 Terraform for real: remote state, modules, network + ECS stack** | Separate env directories / `TFVARS_COMMON` → ⤴ multi-env | Single env only. ✂ "Month 3 sets ECR IMMUTABLE" / "see Month 4" comments. |
| M2 W3 | §2.7 HTTPS, staging, prod-as-plan, CI, drift | **Terraform CI (fmt/validate/plan on PR) + drift exercise → 2.4.** **HTTPS → 2.4 optional track** | Staging, prod-as-plan, promotion → ⤴ multi-env | — |
| M2 W4 | §2.8 Cost, teardown, docs | Folded into **2.2** (teardown) and **2.9** (cost report, docs) | — | Replace prose teardown with commands + a `check_tags.py` confirmation. Activate cost-allocation tags here, not in Month 6. |
| M3 W1 | §3.1–3.3 Release flow design, blue/green choice | **2.5 Safe releases I: versioned, immutable artifacts** | — | Cite the AWS doc for "ECS-native blue/green recommended for new projects" (AUDIT §6). |
| M3 W2 | §3.4 Versioned artifacts, better tests | **2.5** | — | ECR `IMMUTABLE` is introduced here, in its own module. |
| M3 W3 | §3.5–3.6 Blue/green, approval gate, rollback, failure injection | **2.6 Safe releases II: blue/green, approval, automatic rollback** | Prod-environment approvals → ⤴ multi-env | Failure flags (`FAIL_HEALTH`…) are first introduced here (moved from 1.2). Cost note: doubled tasks during the shift. |
| M3 W4 | §3.7 Runbook, trade-offs, presentation | **Runbook → 2.6.** **Presentation → 2.9 gate** | — | ✂ "stretch goal after Month 6". |
| M4 W1 | §4.1–4.3 Concepts, reliability maths, what to watch | **2.7 Observability I: logs, metrics, SLOs** | — | — |
| M4 W2 | §4.4 Structured logs + metrics | **2.7** | — | — |
| M4 W3 | §4.5–4.6 Dashboards, alarms, SNS in Terraform; incident drill | **2.8 Observability II: alarms, dashboards, incident drill** | — | Add teardown (dashboards bill about USD 3/month each, even idle). Replace the Console flag-flip with a CLI/Terraform step. |
| M4 W4 | §4.7 Incident write-up, runbooks | **2.8** (write-up) + **2.9** gate (evidence) | — | — |
| M5 W1–W4 | §5.1–5.9 Threat model, identity/secrets, scanners + gates, Checkov, fail-a-gate demo | — | **All of Month 5 → ⤴ Phase 3 DevSecOps** | Not needed by Phase 1–2. OIDC (Phase 1) and least-privilege task roles (Phase 2) stay where they are. |
| M6 W1–W4 | §6.1–6.6 Audit, clean-room rebuild, harden, present | **Clean-room rebuild + teardown script → 2.9 gate** (single env) | Hardening, failure matrix, multi-env rebuild, EKS note, `cost_report.py` full version → ⤴ Phase 3 capstone | — |

## Resulting Phase 1–2 module list (provisional)

| # | Module | Built from | Adds to the one repo |
|---|---|---|---|
| 1.1 | The app: build and test locally | M1 W1 | `app/` (incl. `GET /version`, `APP_VERSION` — M-8a), `tests/`, `requirements.txt` (pinned) |
| 1.2 | Containers: Docker install, Dockerfile, Compose | M0 L0.6 + M1 W2 | `Dockerfile`, `compose.yaml` |
| 1.3 | Continuous integration with GitHub Actions | M1 W4 (CI half) | `.github/workflows/ci.yml` |
| 1.4 | Infrastructure as Code intro (Terraform, local state) | M2 W1 concepts + **new** | `infra/bootstrap/` (ECR repo, OIDC role) |
| 1.5 | CI publishes images to ECR via OIDC | M1 W3 (ECR) + M1 W4 (OIDC) | `ci.yml` push job |
| 1.6 | Phase 1 gate | M1 W6 + **new** gate | `docs/phase-1-evidence.md` |
| 2.1 | ECS on Fargate by hand (CLI): task vs service, ALB | M1 W3 | — (torn down same session) |
| 2.2 | Terraform for real: remote state, modules, network + ECS | M2 W1–W2, W4 | `infra/` modules + `envs/dev` |
| 2.3 | Continuous deployment to ECS + rollback basics | M1 W4 (CD) + M1 W5 | `deploy.yml`, `scripts/ecs_status.py` |
| 2.4 | Terraform in CI + drift (HTTPS optional track) | M2 W3 | `terraform.yml` |
| 2.5 | Safe releases I: versioned, immutable artifacts | M3 W1–W2 | tagging scheme, ECR immutability |
| 2.6 | Safe releases II: blue/green, approval, auto-rollback | M3 W3–W4 | CodeDeploy (or ECS-native) config, runbook |
| 2.7 | Observability I: structured logs, metrics, SLOs | M4 W1–W2 | logging middleware, metrics |
| 2.8 | Observability II: alarms, dashboards, incident drill | M4 W3–W4 | `infra/modules/monitoring` |
| 2.9 | Phase 2 gate: clean-room rebuild, teardown, cost report | M2 W4 + M6 W2 + **new** gate | `scripts/teardown.sh`, `docs/phase-2-evidence.md` |

**Repo continuity:** every module extends the same `aws-devops-platform` repo that 1.1 creates. Nothing forks into a separate project. Module 2.1 is the only exception: its by-hand ECS resources are created with the CLI and destroyed in the same session, so it adds nothing to the repo.

## Open questions

*(M-1 … M-8 approved 2026-11-17.)*

1. **WSL/workstation setup:** the Phase 0 spec has no home for legacy Lesson 0.1. Add it to 0.1 "Linux & the shell", or make it a 0.1 prerequisite page?
2. **Phase 0.5 vs Phase 2.1 overlap:** 0.5 will launch EC2 in a hand-built VPC (planned). 2.1 reuses that VPC knowledge and adds only ECS/ALB. Confirm 2.1 should not rebuild a VPC by hand.
3. ~~Blue/green mechanism~~ — **decided 2026-11-17: ECS-native blue/green** (Phase 2 contract §4: deployment controller `ECS`; Phase 3 depends on it). Cite the AWS doc when 2.6 is written (AUDIT §6).
