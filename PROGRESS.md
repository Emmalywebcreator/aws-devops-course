# PROGRESS.md — course rebuild tracker

Seeded from [AUDIT.md](AUDIT.md) (2026-11-17). Update at the end of every work session.
Source of truth for module rules: [CLAUDE.md](CLAUDE.md) · template: [templates/module.md](templates/module.md).

## Current position

- **Stage:** scaffolding done — no course content written yet in `/phases/`.
- **Legacy content:** `index.html` (Module 0 + Months 1–6) remains published and unchanged.
- **Exact next step:** decide the Month → Phase mapping and module list (Decision D1), then write Phase 0 Module 01 with the template.

## Scaffolding

- [x] `CLAUDE.md`
- [x] `AUDIT.md`
- [x] `templates/module.md` (10 required sections)
- [x] `/assessments/`, `/phases/phase-0` … `phase-3` (empty, `.gitkeep`)
- [x] Subagents: `.claude/agents/labs.md`, `cost.md`, `qa.md`, `voice.md`
- [ ] `/site/` build/publish path decided (GitHub Pages vs current Vercel setup — README/`deploy.ps1` disagree with CLAUDE.md)

## Open decisions

| ID | Decision | Options / notes | Status |
|---|---|---|---|
| D1 | Map legacy units to phases | AUDIT §2 proposal: M0 → Phase 0; Month 1 → Phase 1 (+ add IaC intro); Months 2–4 → Phase 2; Month 5 + multi-env + EKS + Ansible → Phase 3 | open |
| D2 | Where multi-env lives | CLAUDE.md says Phase 3; legacy Month 2 introduces dev/staging/prod | open |
| D3 | Ansible | Missing entirely; Phase 3 per CLAUDE.md | open |
| D4 | Region policy | One parameterized region, or drop the `eu-west-1` option (AUDIT §1.8) | open |
| D5 | Domain requirement | Required in legacy Month 2; add a no-domain path? (AUDIT B16) | open |
| D6 | Signposting forward refs | Allowed as navigation, or banned entirely? (AUDIT §4.3) | open |
| D7 | Answer keys location | Move to `/solutions/` and out of nav (AUDIT §2) | open |
| D8 | Course length | README "28-week" vs phase-gated structure | open |

## Module status

Legend: ⬜ not started · 🟨 drafting · 🟦 in review · ✅ done (all Definition-of-Done boxes ticked).
DoD columns: **T** full template · **H** every command run by a human · **C** cost + teardown · **D** debugging lab · **V** last-verified date · **F** no forward refs · **Q** qa passed · **S** self-check answers in /solutions.

| Phase | Module | Legacy source | Status | T | H | C | D | V | F | Q | S |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 0 | Phase 0 diagnostic gate (`/assessments/`) | Start-page self-assessment (self-reported only) | ⬜ | | | | | | | | |
| 0 | AWS account creation (new) | — none (AUDIT B2) | ⬜ | | | | | | | | |
| 0 | Workstation setup (WSL + macOS/Linux) | M0 Lesson 0.1 | ⬜ | | | | | | | | |
| 0 | Linux CLI, permissions, bash | M0 Lessons 0.2, 0.2b | ⬜ | | | | | | | | |
| 0 | Networking + troubleshooting (incl. CIDR/subnets) | M0 Lessons 0.3, 0.3b | ⬜ | | | | | | | | |
| 0 | Git and GitHub | M0 Lesson 0.4 | ⬜ | | | | | | | | |
| 0 | Python for DevOps | M0 Lesson 0.5 | ⬜ | | | | | | | | |
| 0 | Docker install | M0 Lesson 0.6 | ⬜ | | | | | | | | |
| 0 | AWS account safety: IAM basics, Identity Center, SSO login, budgets | M0 Lesson 0.7 | ⬜ | | | | | | | | |
| 1 | App + container + Compose | Month 1 Weeks 1–2 | ⬜ | | | | | | | | |
| 1 | AWS core (ECR/ECS/ALB) + IAM | Month 1 Week 3 | ⬜ | | | | | | | | |
| 1 | CI/CD with GitHub Actions + OIDC | Month 1 Week 4 | ⬜ | | | | | | | | |
| 1 | Failure, rollback, teardown | Month 1 Weeks 5–6 | ⬜ | | | | | | | | |
| 1 | IaC intro (new) | — none (AUDIT §2) | ⬜ | | | | | | | | |
| 2 | Terraform | Month 2 | ⬜ | | | | | | | | |
| 2 | Safe releases (blue/green + rollback) | Month 3 | ⬜ | | | | | | | | |
| 2 | Observability | Month 4 | ⬜ | | | | | | | | |
| 3 | DevSecOps | Month 5 | ⬜ | | | | | | | | |
| 3 | Multi-env | Month 2 (part) | ⬜ | | | | | | | | |
| 3 | Kubernetes/EKS | Month 6 note only | ⬜ | | | | | | | | |
| 3 | Ansible (new) | — none | ⬜ | | | | | | | | |
| 3 | Capstone | Month 6 | ⬜ | | | | | | | | |

*(Module list is provisional until D1 is decided.)*

## Backlog from AUDIT.md

### P1 — Learner level and hard blockers (AUDIT §5 🔴)
- [ ] B1 Remove the Solutions Architect assumption; target no-AWS learner
- [ ] B2 Add AWS account creation lesson
- [ ] B7 Identity Center step-by-step; explain root / IAM / permission sets
- [ ] B8 Teach `aws configure sso` prompts and `aws sso login`
- [ ] B10 Install `jq` before first use
- [ ] B11 VPC, subnets, AZs, CIDR, public vs private — before Month 1 AWS build
- [ ] B13 IAM policy semantics + evaluation logic, with doc citations
- [ ] B15 Every lab run against a real account once

### P2 — Verification
- [ ] Last-verified block in every module (AUDIT §1.3)
- [ ] Re-capture sample outputs (e.g. preflight `Python 3.13.18`) from real runs
- [ ] qa agent checks the 10 claims in AUDIT §6 (OIDC sub format, action versions, Trivy CVE, TLS policy, ECS-native blue/green, `use_lockfile`, SNS encryption, attestations, pricing, sample output)

### P3 — Cost and teardown (AUDIT §4.2)
- [ ] "If you skip teardown: $X/day" + pricing assumptions + pricing date, every module
- [ ] Teardown + confirmation command for every resource-creating lab
- [ ] Month 4 (SNS/alarms/dashboards) and Month 5 (secrets, 7-day recovery) teardown
- [ ] Month 1: teardown after Weeks 3–4; ARN lookup commands; SG deletion via CLI
- [ ] Final teardown commands: IAM roles, OIDC provider, hosted zone, versioned state bucket
- [ ] No ECS service left running between labs by default (CLAUDE.md rule)

### P4 — Version pins (AUDIT §4.1)
- [ ] `pip-audit`, `bandit`, `checkov` pinned (CI + local)
- [ ] Terraform CLI pinned (apt + `setup-terraform` `terraform_version`); tighten `required_version`
- [ ] Published tested versions for fastapi, uvicorn, pytest, httpx, boto3, requests, moto
- [ ] `hello-world`, AWS CLI installer, `python:3.12-slim` pinned
- [ ] Decide on `ubuntu-latest` vs pinned runner image
- [ ] Checkov result counts tied to a pinned version (B24)

### P5 — Consistency
- [ ] Region parameterized (≈20 hard-coded `us-east-1`) or option removed (D4)
- [ ] "UI as of <date>" on all ~17 Console steps; CLI alternative where possible
- [ ] Forward references removed/rephrased (AUDIT §4.3)
- [ ] Secret ARN example `-AbCdEf` contradicts "never type it" (AUDIT §3.7)
- [ ] Answer keys for Module 0 checkpoint and Month 6 review

### P6 — Friction (AUDIT §5 🟠/🟡)
- [ ] B3 non-Windows path; WSL virtualization note · B4 Linux permissions · B5 SSH prompts · B6 Docker Desktop checks · B9 ARM CLI installer
- [ ] B12 `ecsTaskExecutionRole` steps · B14 teardown ordering / `DependencyViolation`
- [ ] B16 domain alternative · B17 region · B18 HCL features explained · B19 `TFVARS_COMMON` example
- [ ] B20 versioned bucket deletion · B21 CIDR /32 · B22 drill flag steps · B23 Trivy local install · B25 GitHub UI dates

## Keep (AUDIT §7)

Network drill (M1 §1.5), 0.3b error table, M5 fail-a-gate demos, M3 failure injection + probe log, troubleshooting tables, honesty rules, no-NAT design rationale, Months 1–5 answer keys.

## Session log

| Date | What was done | Verified | Next |
|---|---|---|---|
| 2026-11-17 | CLAUDE.md saved; AUDIT.md written; template, dirs, subagents, PROGRESS.md created | Files exist; no content written | Decide D1 |
