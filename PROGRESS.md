# PROGRESS.md — course rebuild tracker

Seeded from [AUDIT.md](AUDIT.md) (2026-11-17). Update at the end of every work session.
Source of truth for module rules: [CLAUDE.md](CLAUDE.md) · template: [templates/module.md](templates/module.md).

## Current position

- **Stage:** Phase 0 diagnostic + gate drafted; Module 0.0 drafted and reviewed (labs/cost/qa fixes applied); Stage 4 mapping approved (MAPPING.md); Phase 2 exit contract + Phase 3 modules 3.1–3.5 drafted. Nothing run against AWS yet.
- **Legacy content:** `index.html` (Module 0 + Months 1–6) remains published and unchanged.
- **Exact next step:** your approval of Sessions A, B and C (below); then session 1 = module 0.1.

## Session order (revised 2026-11-17, confirmed)

| # | Session | Status |
|---|---|---|
| A | Backfill `lastVerified` (0.0, 3.1–3.5); EKS minor-version pin; `/version` → 1.1 | 🟨 done except the backfill — **needs a human run** (see below) · `be8ff20` |
| B | Close MAPPING gaps: ADRs → 2.9, WSL → 0.1, Docker → 0.1, new 3.6 capstone | 🟨 awaiting approval · `e439c9c` |
| C | Scope drafts for 0.1–0.6 (`phases/phase-0/*/scope.md`, not published by the site) | 🟨 awaiting approval |
| — | **Gate: A, B, C approved** | |
| 1–6 | Phase 0 modules 0.1 → 0.6 (one session each; labs/cost/qa agents; commit) | ⬜ |
| 7–12 | Phase 1 modules 1.1 → 1.6 (1.4 may run before 1.3; 1.5 needs 1.3 + 1.4) | ⬜ |
| 13–21 | Phase 2 modules 2.1 → 2.9 (2.4 after 2.2; 2.7 after 2.3) | ⬜ |
| 22 | Contract reconciliation (Phase 2 output vs `phases/phase-2/CONTRACT.md`) | ⬜ |
| 23 | Phase 3 fix-up (dangling Phase 1/2 references, re-run qa on 3.1–3.5) | ⬜ |
| 24 | 3.6 Phase 3 capstone | ⬜ |

**Session A backfill not done:** `lastVerified` can only be set by a human who ran *every* command. 0.0 needs account creation (card, phone) and phone-based MFA in the console; 3.1–3.5 need the Phase 2 infrastructure that sessions 13–21 build. All six stay `lastVerified: null` until then (fix list #25).

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
| D1 | Map legacy units to phases | Phase 0 = spec modules 0.0–0.6; Phase 1–2 per MAPPING.md (M-1…M-8) | **decided 2026-11-17** (MAPPING.md approved) |
| D2 | Where multi-env lives | Phase 3 (module 3.1); single `dev` env through Phase 2 (M-3) | **decided 2026-11-17** |
| D3 | Ansible | Phase 3 module 3.5 (EC2 hosts + systemd, dynamic inventory) | **decided 2026-11-17** |
| D4 | Region policy | One parameterized region, or drop the `eu-west-1` option (AUDIT §1.8) | open |
| D5 | Domain requirement | HTTPS/domain = optional track; default HTTP on ALB DNS name (M-5) | **decided 2026-11-17** |
| D6 | Signposting forward refs | Allowed as navigation, or banned entirely? (AUDIT §4.3) | open |
| D7 | Answer keys location | `/solutions/assessments/` + per-module `solutions/`, not linked from nav | **decided 2026-11-17** |
| D8 | Course length | README "28-week" vs phase-gated structure | open |
| D9 | Phase 3 written before Phase 2 | Phase 3 targets `phases/phase-2/CONTRACT.md`; Phase 2 rewrite must satisfy it or update both together | **decided 2026-11-17** |
| D10 | Workstation/WSL setup | First lab of 0.1 (MAPPING B-2) | **decided 2026-11-17** |
| D11 | Blue/green mechanism (2.6) | ECS-native blue/green; deployment controller `ECS` (Phase 2 contract §4) | **decided 2026-11-17** |

## Module status

Legend: ⬜ not started · 🟨 drafting · 🟦 in review · ✅ done (all Definition-of-Done boxes ticked).
DoD columns: **T** full template · **H** every command run by a human · **C** cost + teardown · **D** debugging lab · **V** last-verified date · **F** no forward refs · **Q** qa passed · **S** self-check answers in /solutions.

| Phase | Module | Legacy source | Status | T | H | C | D | V | F | Q | S |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 0 | Phase 0 diagnostic + gate rules (`/assessments/`; keys in `/solutions/assessments/`) — 0.0–0.6 spec numbering | Start-page self-assessment (self-reported only) | 🟨 | n/a | | ✅ | n/a | ✅ | ✅ | ✅ (qa A, fixed in fa25779) | ✅ |
| 0 | 0.0 Account safety & billing guardrails (`phases/phase-0/00-account-safety`) | M0 Lesson 0.7 + new (AUDIT B2) | 🟦 | ✅ | | ✅ | ✅ | ✅ | ✅ | ✅* | ✅ |
| 0 | 0.1 Linux & the shell (`01-linux-shell`, scope.md drafted) | M0 Lessons 0.1, 0.2, 0.2b, 0.6 | 🟨 scope | | | | | | | | |
| 0 | 0.2 Networking fundamentals (`02-networking`, scope.md drafted) | M0 Lessons 0.3, 0.3b | 🟨 scope | | | | | | | | |
| 0 | 0.3 Git & GitHub workflows (`03-git-github`, scope.md drafted) | M0 Lesson 0.4 | 🟨 scope | | | | | | | | |
| 0 | 0.4 Python for ops (`04-python-ops`, scope.md drafted) | M0 Lesson 0.5 | 🟨 scope | | | | | | | | |
| 0 | 0.5 AWS core mental model + CLI (`05-aws-core-cli`, scope.md drafted) | new (AUDIT B11, B13) | 🟨 scope | | | | | | | | |
| 0 | 0.6 Capstone mini-project + Phase 0 gate (`06-capstone`, scope.md drafted) | new (must meet gate-rules.md Gate C contract) | 🟨 scope | | | | | | | | |
| 1 | 1.1 The app: build and test locally | M1 W1 | ⬜ | | | | | | | | |
| 1 | 1.2 Containers: Dockerfile and Compose (install moved to 0.1, B-3) | M1 W2 | ⬜ | | | | | | | | |
| 1 | 1.3 CI with GitHub Actions | M1 W4 (CI half) | ⬜ | | | | | | | | |
| 1 | 1.4 IaC intro (Terraform, local state) | M2 W1 concepts + new | ⬜ | | | | | | | | |
| 1 | 1.5 CI publishes to ECR via OIDC | M1 W3 (ECR) + W4 (OIDC) | ⬜ | | | | | | | | |
| 1 | 1.6 Phase 1 gate | M1 W6 + new | ⬜ | | | | | | | | |
| 2 | 2.1 ECS on Fargate by hand | M1 W3 | ⬜ | | | | | | | | |
| 2 | 2.2 Terraform for real: remote state, modules, network + ECS | M2 W1–W2, W4 | ⬜ | | | | | | | | |
| 2 | 2.3 Continuous deployment + rollback basics | M1 W4 (CD) + W5 | ⬜ | | | | | | | | |
| 2 | 2.4 Terraform in CI + drift (HTTPS optional) | M2 W3 | ⬜ | | | | | | | | |
| 2 | 2.5 Safe releases I: versioned, immutable artifacts | M3 W1–W2 | ⬜ | | | | | | | | |
| 2 | 2.6 Safe releases II: ECS-native blue/green, approval, rollback | M3 W3–W4 | ⬜ | | | | | | | | |
| 2 | 2.7 Observability I: logs, metrics, SLOs | M4 W1–W2 | ⬜ | | | | | | | | |
| 2 | 2.8 Observability II: alarms, dashboards, incident drill | M4 W3–W4 | ⬜ | | | | | | | | |
| 2 | 2.9 Phase 2 gate | M2 W4 + M6 W2 + new | ⬜ | | | | | | | | |
| 2 | Phase 2 exit contract (`phases/phase-2/CONTRACT.md`) | derived from MAPPING | 🟨 | n/a | | ✅ | n/a | n/a | ✅ | ✅ (qa B, fixed in 53ddbe7) | n/a |
| 3 | 3.1 Multi-env Terraform (`phases/phase-3/01-multi-env-terraform`) | Month 2 W2–W3 (part) | 🟨 | ✅ | | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| 3 | 3.2 DevSecOps (`02-devsecops`) | Month 5 | 🟨 | ✅ | | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| 3 | 3.3 Advanced observability / SLOs (`03-observability-slos`) | Month 4 (advanced parts) + new | 🟨 | ✅ | | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| 3 | 3.4 Kubernetes/EKS (`04-kubernetes-eks`) | Month 6 note only + new | 🟨 | ✅ | | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| 3 | 3.5 Ansible (`05-ansible`) | — new | 🟨 | ✅ | | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| 3 | 3.6 Phase 3 capstone (`06-capstone`, planned — MAPPING B-1b) | Month 6 W1 (audit), W3, W4 | ⬜ | | | | | | | | |

*Rows follow the Phase 0 spec (0.0–0.6) and MAPPING.md. \*0.0 QA: review findings applied 2026-11-17; Last-verified still pending a human run. "V" = Last-verified block present (not yet verified). Phase 3 modules: qa + cost agents run 2026-11-17, findings fixed (see Fix list).*

## Fix list — course-wide qa + cost review (2026-11-17)

Source: `qa` (part A: assessments + Phase 0; part B: Phase 3 + contract) and `cost` agents, run 2026-11-17 on commit `ca5e60f`. Priority: **P1** = wrong, unsafe, leaves money running or blocks a learner · **P2** = CLAUDE.md rule violation · **P3** = polish. Each fix group = one commit.

### P1

| # | Where | Problem | Fix | Commit |
|---|---|---|---|---|
| 1 | `assessments/*`, `solutions/assessments/*` | T3/G1/E1 require Identity Center (`AWSReservedSSO_`) + `aws sso login`; Module 0.0 teaches IAM user + `aws login` → every 0.0 graduate fails | Accept `:user/<name>` via `aws login`; fail only on `:root` / root keys | A |
| 2 | `assessments/*` | Routing uses P0-M01…M09; account safety placed last; spec skip rule (≥ 10/12 + all tasks → Phase 1) missing | Renumber to 0.0–0.6; Q11/Q12/T3 → 0.0; add spec rule; lowest failed module otherwise | A |
| 3 | `assessments/*` | Forward refs to Docker (Q10, G6, E6 — Docker is Phase 1.2 per M-6); "workstation" module doesn't exist; no item tests 0.5 | Drop Docker items; Step 0/Q1 → 0.1; replace Q10 with an IAM-evaluation item for 0.5 | A |
| 4 | `assessments/gate-rules.md` | Exit gate doesn't match spec 0.6 (capstone = VPC + EC2 + SG + S3; explanations = IAM evaluation, VPC request path, NAT cost; debugging labs 0.1–0.5) | Rewrite Part 2 to the spec; teardown checks cover EC2, VPC, S3, EIP, NAT, volumes | A |
| 5 | `phase-2/CONTRACT.md` | Deployment controller unspecified; if CodeDeploy, `update-service --task-definition` and TF task-def changes in 3.2/3.3 break | Contract: deployment controller `ECS` (ECS-native blue/green, closes D11) | C |
| 6 | `phase-2/CONTRACT.md` §6 | Daily figure wrong (1.45) and has no assumptions | List unit prices/region/date; USD 0.058/h → ≈ USD 1.20–1.39/day | C |
| 7 | `3.2` teardown | Secret force-deleted while service references it; merged `secrets.tf` recreates an empty secret in 3.3 (bills, tasks fail) | Teardown env first, then secret; secret behind `enable_api_key_secret` (default false); 3.3 confirm checks secrets | E, F |
| 8 | `3.2` Lab 2 | `bandit -ll` won't report B602 for a string literal (LOW severity) | Use a non-literal shell command (HIGH) | E |
| 9 | `3.3` Lab 3 | Error-budget gate passes silently (unset var → `allowed == 0` → exit 0); referenced deploy job doesn't exist | Exit 2 on no data; set variable via `gh variable set`; write the job | F |
| 10 | `3.4` | `kubectl apply -f k8s/` hits eksctl `cluster.yaml` and literal `IMAGE_URI` | Move cluster config to `infra/eks/cluster.yaml`; fix via sed pipeline | G |
| 11 | `3.4` teardown | LB wait loop gives up and deletes the cluster anyway → orphaned CLB ≈ USD 0.84/day; no LB check in confirm; empty `$VPC_ID` | Hard-stop if LB remains; LB check in confirm; guard `$VPC_ID` | G |
| 12 | `3.5` Lab 1 | `output "ami_id"` from sensitive `aws_ssm_parameter.value` fails at plan | `var.ami_id` pinned to a recorded ID; lookup via `insecure_value` only to discover it | H |

### P2

| # | Where | Problem | Fix | Commit |
|---|---|---|---|---|
| 13 | `gate-rules.md` | 1.6 duplicates 0.0 Labs 2/5; "check 1" should be "check 2"; Identity Center wording | Link to 0.0; correct wording | A |
| 14 | 0.0 | Free tier is "10 alarm **metrics**", not 10 alarms | Reword (0.0 cost table + Lab 4 note) | B |
| 15 | 0.0 | CloudShell CLI version unpinned (`aws login` needs ≥ 2.32.0) | Learner records `aws --version` in CloudShell; must be ≥ 2.32.0 | B |
| 16 | CONTRACT | Bootstrap cost lacks region/date/ECR size; no lifecycle on state-bucket noncurrent versions; `gha-deploy` trust/state access for PR plans unstated; dev has no `image_tag` output | State all four in contract | C |
| 17 | CONTRACT + 3.1/3.2/3.3 tables | Monitoring dashboard (USD 3/month beyond 3 free), 2 alarms/env, CloudWatch Logs ingestion not costed | Add rows / state free-tier assumption; 3.1 skip ≈ USD 2.85/day | C–F |
| 18 | 3.1 | `|| echo REPLACE_ME` fallback; `sed s/dev/ENV/` corrupts `aws-devops-platform`; `$STATE_BUCKET` unset in new terminal | Use contract `image_tag` output; quote-anchored sed; re-derive bucket | D |
| 19 | 3.2 | `requests==2.19.1` conflicts with FastAPI's `idna` → resolve error not CVE; checkov pins boto3 → shared venv conflict; `python-version: "3.12"` floats; Rego misses `ip_protocol = "-1"`; Trivy CVE uncited | `pip-audit --no-deps` on a one-line file; separate security venv; pin `3.12.12`*; Rego rule for all-protocol; cite OSV | E |
| 20 | 3.3 | `pip install` without `setup-python`; dev left at 512/1024 after merge; re-teaches SLI/error-budget basics from 2.7 | Add setup step; revert sizes; link to 2.7, keep only burn-rate material | F |
| 21 | 3.4 | AZs not pinned (IP/cost count); volume/instance confirm filters miss node volumes; stack filter misses states; NAT row has no price | `availabilityZones`; filter `tag:eks:cluster-name`; exclude `DELETE_COMPLETE`; NAT ≈ USD 0.045/h | G |
| 22 | 3.5 | AMI floats via `ami-amazon-linux-latest`; default tags don't reach root volumes (confirm can't detect leftovers) | Pinned `var.ami_id`; `volume_tags`; confirm checks `status=available` | H |
| 23 | All Phase 3 cost sections | No pricing date | "author's figures as of 2026-11-17, not yet checked" | D–H |
| 24 | MAPPING / PROGRESS | "0.5 now teaches" (not written); approval question still open; diagnostic marked "no forward refs"; superseded Phase 0 rows | "will teach (planned)"; remove question; correct rows | I |
| 25 | All modules | Unit prices not checked live; Last verified = NOT YET VERIFIED | **Needs a human run + live pricing check — not fixable in this pass** | — |

### P3

| # | Where | Fix | Commit |
|---|---|---|---|
| 26 | 0.0 | Drop resolved `TODO(verify)` on `delete-alarms` (DeleteAlarms docs); section 9 references section 7 teardown instead of repeating it | B |
| 27 | solutions key | Remove open "qa: confirm" note | A |
| 28 | 3.2 / 3.3 / 3.4 / 3.5 | Resolve answered `TODO(verify)`s (gitleaks prints `8.30.1`; requests 2.19.1 has CVEs; secret deletion is async → retry; `data.aws_region.current.region` correct; ADOT default config routes traces to X-Ray as `orders-api`; EKS default CLB confirmed; group `role_orders_host`; ansible-core 2.21 targets Python 3.9–3.14) | E–H |
| 29 | 3.4 | Stack-status and instance filters (see 21) | G |
| 30 | 3.5 | Drop unused `community.docker`; `mkdir -p ansible/inventory` | H |

\* exact patch chosen to match the Phase 1 Docker base image once 1.2 is written; until then the contract states it.

**Commit plan:** A assessments · B Module 0.0 · C Phase 2 contract · D 3.1 · E 3.2 · F 3.3 · G 3.4 · H 3.5 · I MAPPING/PROGRESS.

**Status (2026-11-17):** A `fa25779` · B `d9a6e80` · C `53ddbe7` · D `c453419` · E `956788f` · F `86aa1df` · G `169416b` · H `63d297f` · I (this commit) — all items done **except #25** (live pricing check + human run of every module), which stays open. Remaining `TODO(verify)`: 3.3 time-to-alarm; assessments `DescribeAlarms` pricing.

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

## Moved to Phase 3

Logged as each Phase 1–2 module is rewritten (MAPPING.md). Planned moves:

| From (legacy) | Content | → Phase 3 home | Logged |
|---|---|---|---|
| M2 W2–W3 | Separate env dirs, staging, prod-as-plan, promotion | 3.1 Multi-env Terraform (already written) | 2026-11-17 (planned) |
| M3 W3 | Production-environment approvals | 3.1 / Phase 3 capstone | planned |
| M5 W1–W4 | Threat model, secrets, scanners + gates, Checkov, fail-a-gate | 3.2 DevSecOps (already written) | 2026-11-17 (planned) |
| M6 W1–W4 | Hardening, failure matrix, multi-env rebuild, EKS note, full `cost_report.py` | Phase 3 capstone (not yet written) | planned |

## Keep (AUDIT §7)

Network drill (M1 §1.5), 0.3b error table, M5 fail-a-gate demos, M3 failure injection + probe log, troubleshooting tables, honesty rules, no-NAT design rationale, Months 1–5 answer keys.

## Session log

| Date | What was done | Verified | Next |
|---|---|---|---|
| 2026-11-17 | CLAUDE.md saved; AUDIT.md written; template, dirs, subagents, PROGRESS.md created | Files exist; no content written | Decide D1 |
| 2026-11-17 | Phase 0 entry diagnostic (12 Q + 3 tasks), gate rules (placement + exit gate), answer keys in `/solutions/assessments/`. Proposed P0-M01…M09 numbering (feeds D1). | T1 + T2 local steps dry-run on WSL 2; AWS CLI flags checked via `aws help`; no real-account run | Human run of diagnostic; qa pass on citations; confirm module order in D1 |
| 2026-11-17 | Module 0.0 written + labs/cost/qa reviews applied; MAPPING.md (Stage 4) approved; Phase 2 exit contract; Phase 3 modules 3.1–3.5 with incident labs + solutions | bash -n on all scripts; CLI flags via `aws help`; tool versions from registries; scanner binaries NOT run (download blocked) | Human run of 0.0; assessment renumbering; qa/labs/cost agents on Phase 3 |
| 2026-11-17 | Course-wide qa (×2) + cost review; prioritized fix list; fixes A–I committed module by module | All bash blocks `bash -n`; versions from registries; no AWS calls | Fix list #25 (human run + live prices) |
