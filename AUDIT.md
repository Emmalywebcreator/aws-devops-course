# AUDIT.md — aws_devops_course content audit

**Audit date:** 2026-11-17
**Audited source:** `index.html` (528 KB, 8,785 lines). This is the only course content in the repo.
**Measured against:** `CLAUDE.md` (the module template, technical rules, content rules and target learner).
**Scope:** read-only. Course content was not changed at this stage.

## How this audit was done

- I extracted the text of `index.html` and read every prose section from start to finish: Start page, Module 0, Months 1–6, Reference and Answer keys.
- I did **not** read every line of the "Complete code for Month N" listings. For those I ran pattern scans: `uses:`, `FROM`, `pip install`, `version =`, `required_version`, `runs-on`, region strings, 12-digit account IDs and teardown keywords.
- Nothing was run against AWS. I did **not** check version numbers against the live registries or GitHub Marketplace. Section 6 lists the claims the `qa` agent still has to verify against official docs.
- Locations are given as course section numbers (for example "M1 §1.6"). Where it helps, I add the `index.html` line number (for example `index.html:1188`).

---

## 1. Headline findings

1. **The course is written for a different learner than CLAUDE.md describes.** The opening paragraph says *"You already know AWS architecture from your Solutions Architect certification"* (`index.html:297`). CLAUDE.md's Phase 0–1 learner has **no AWS experience**. That one assumption explains most of the beginner blockers in section 5: Module 0 and Month 1 skip IAM, VPC/subnet and Console basics that a certified architect would already know.
2. **No code has been run against a real AWS account.** Months 2, 3 and 5 each say so plainly (`index.html:3947, 5705, 6687`). This fails the Definition-of-Done item "every command run by a human once". A beginner has no way to tell a course bug from their own mistake.
3. **No module has a "Last verified" section.** The only date in the course is the version table ("checked 16 November 2026") in Reference.
4. **The course structure doesn't match CLAUDE.md.** The content is Module 0 plus Months 1–6. CLAUDE.md describes Phases 0–3 with hard gates. Section 2 maps one onto the other.
5. **Months 4 and 5 have no teardown section at all.** Months 1–3 have teardown commands, but none ends with a confirmation step.
6. **The cost estimates never give "if you skip teardown: $X/day".** Every cost figure is per month, and in-month cost notes only exist in Month 1 (§1.6) and partly in Months 2, 4 and 5.
7. **There is no structural debugging lab.** Months 1, 3, 4 and 5 do contain good "break it on purpose" exercises (§1.5 network drill, §3.6, §4.6, §5.5), but no module has a section in the required template shape.
8. **Region handling contradicts itself.** Lesson 0.7 says you can pick `us-east-1` *or* `eu-west-1`, but about 20 places hard-code `us-east-1`: backend blocks, bucket names, variable defaults and scripts. A learner who picks `eu-west-1` breaks Month 2.
9. **No Console instruction says "UI as of <date>".** There are 0 occurrences, and the Console is used in at least 17 places.

---

## 2. Course structure vs CLAUDE.md phases

| CLAUDE.md phase | What CLAUDE.md says it contains | Existing unit(s) | Gap |
|---|---|---|---|
| Phase 0: prerequisites and account safety. Gate: a diagnostic assessment | Setup, account safety | Module 0 (Lessons 0.1–0.7) plus the Start-page "15-minute self-assessment" | The self-assessment is **self-reported** (yes/no), not a diagnostic. There is no `/assessments/` folder and no pass/fail gate. The Module 0 checkpoint is a checklist with no scoring and no answers. |
| Phase 1: Docker, Git-based CI, IaC intro | | Month 1 | Month 1 has **no IaC intro**: Terraform starts in Month 2, and Month 1 is click-ops. Month 1 also covers ECS, ALB, IAM and OIDC, which CLAUDE.md places in Phase 2 (ECS). |
| Phase 2: Terraform, ECS, blue/green plus rollback, observability | | Months 2, 3, 4 | Month 2 brings in **multi-env (dev/staging/prod)**, which CLAUDE.md places in Phase 3. |
| Phase 3: Kubernetes/EKS, Ansible, DevSecOps, multi-env | | Month 5 (DevSecOps), Month 6 (capstone) | **Ansible is missing entirely.** EKS appears only as an optional "if time remains" note (M6 §6.4). Kubernetes is correctly kept out of earlier months. |

Repo layout: CLAUDE.md expects `/phases/phase-N/…/module.md`, `labs/`, `solutions/`, `/site/` and `/assessments/`. None of these exist. Everything is in one built `index.html`.

Answer keys: CLAUDE.md says solutions are "not linked from lesson nav". The existing "Answer keys" page **is** in the main nav (Start page table, `index.html:8280`).

---

## 3. Module inventory and template coverage

Legend: ✅ present · ◐ partial · ❌ missing.
Template columns: **G** goal · **P** prerequisites (linked) · **T** time · **$** cost (with assumptions and $/day) · **C** concepts · **L** labs (task / expected / verify / teardown) · **D** debugging lab · **S** self-check (5–8) · **TD** teardown with confirmation · **LV** last verified.

| Unit | G | P | T | $ | C | L | D | S | TD | LV |
|---|---|---|---|---|---|---|---|---|---|---|
| Start page (not a module) | – | – | – | ◐ | – | – | – | – | – | ❌ |
| Module 0: Foundations | ◐ | ❌ | ◐ | ◐ | ✅ | ◐ | ◐ | ◐ | n/a | ❌ |
| Month 1: CI/CD to ECS | ✅ | ❌ | ✅ | ◐ | ✅ | ◐ | ✅ | ✅ | ◐ | ❌ |
| Month 2: Terraform | ✅ | ❌ | ✅ | ◐ | ✅ | ◐ | ◐ | ✅ | ◐ | ❌ |
| Month 3: Safe releases | ✅ | ❌ | ✅ | ❌ | ✅ | ◐ | ✅ | ✅ | ◐ | ❌ |
| Month 4: Observability | ✅ | ❌ | ✅ | ◐ | ✅ | ◐ | ✅ | ✅ | ❌ | ❌ |
| Month 5: DevSecOps | ✅ | ❌ | ✅ | ◐ | ✅ | ◐ | ✅ | ✅ | ❌ | ❌ |
| Month 6: Capstone | ✅ | ❌ | ✅ | ◐ | ✅ | ◐ | ✅ | ◐ | ◐ | ❌ |
| Reference (not a module) | – | – | – | – | – | – | – | – | – | ◐ (versions only) |
| Answer keys (not a module) | – | – | – | – | – | – | – | – | – | ❌ |

Gaps that apply to every unit:
- **Prerequisites (P):** no unit links to the exact earlier modules it depends on. The only thing close is "Work through them in order".
- **Labs (L):** labs are week-sized. Verification is usually there. Per-lab teardown is not: teardown is batched at the end of a month, or missing.
- **Cost ($):** no unit gives "if you skip teardown: $X/day". The course's own figure of USD 0.05–0.06 per hour for one environment works out to **about USD 1.20–1.45 per day for one environment, or about USD 2.40–2.90 per day for dev plus staging**. That is my arithmetic from the course's numbers, not a verified price.
- **Last verified (LV):** missing everywhere.

### 3.1 Start page

Sections: How this course is organised · Your schedule · What the course costs · One repository · What DevOps means · Guiding principle · 15-minute self-assessment · Make the schedule yours · Weekly rhythm · 8-step workflow.

- **Beginner-hostile:** the opening paragraph assumes a Solutions Architect certification (`index.html:297`).
- **Cost:** a whole-course table with assumptions ("approximate us-east-1 prices", "60–90 running hours a month", "one ALB, one small task, three public IPv4"). This is good, but it is the only place most months' costs appear.
- **Forward references:** the roadmap tables mention every month. That is fine as orientation, but the cost paragraph points learners to `scripts/cost_report.py`, which isn't built until Month 6.

### 3.2 Module 0: Foundations (Weeks 0–2)

Sections: 0.1 WSL · 0.2 Linux survival kit · 0.2b Bash scripting · 0.3 Networking · 0.3b Network troubleshooting · 0.4 Git and GitHub · 0.5 Python · 0.6 Docker install · 0.7 AWS account safety · Module 0 checkpoint.

What's missing against the template:
- No goal, time or cost for each lesson. The module as a whole gets "two weeks".
- Exercises in 0.2, 0.3, 0.4 and 0.5 have no expected result and no verification command. 0.1, 0.2b and 0.3b do.
- No debugging lab. 0.3b has a table of error types, but nothing broken to fix.
- The checkpoint has 10 items but **no answers in solutions**.
- No last-verified date. Lesson 0.7 is Console-only with no "UI as of".

Forward references (inside the module):
- 0.2b `preflight.sh` requires `docker` and `aws`, which are installed in 0.6 and 0.7. The text admits this ("Run it again after Lesson 0.7").
- 0.5 says "you will use the same idea in Month 3".

Unpinned versions:
- `docker run --rm hello-world` uses the implicit `:latest` (`index.html:1182`).
- The AWS CLI installer URL always downloads the latest v2 build (`index.html:1193`).
- `apt install git curl … python3` installs whatever the distro ships. No Ubuntu version is stated.
- Docker Desktop version is not stated.
- The sample preflight output shows `Python 3.13.18` (`index.html:1013`), but the Dockerfile and CI use 3.12. That patch number also looks unlikely; re-capture this output from a real run.

Teardown/cost: Module 0 creates only free things (an Identity Center user, budgets, the `devops-sandbox` repo). Even so, "Nothing here costs money" needs a doc citation for AWS Budgets pricing.

### 3.3 Month 1: Cloud Deployment Pipeline (6 weeks)

Sections: What changes · 1.1 Concepts · 1.2 Architecture · 1.3 Repo structure · 1.4 Week 1 app · 1.5 Week 2 container plus Compose plus network drill · 1.6 Week 3 AWS by hand · 1.7 Week 4 GitHub Actions plus OIDC · 1.8 Week 5 failure, rollback, teardown, `ecs_status.py` · 1.9 Week 6 docs · Troubleshooting · Pass criteria · 1.10 Review (7 questions, with answers in Answer keys).

What's missing against the template:
- Prerequisites are not linked.
- The cost table (§1.6) has assumptions but no $/day.
- Weeks 3 and 4 create billable resources (ALB, Fargate, public IPv4) with **no teardown until Week 5**.
- No "UI as of" on the Console steps in §1.6 Step 2 and Step 5, §1.7 Steps 1 and 4, or the teardown (security groups).
- No last-verified date.

Teardown (§1.8):
- `<ALB_ARN>` and `<TG_ARN>` are placeholders, with no command to look them up (`aws elbv2 describe-load-balancers --names …`).
- Security groups are deleted "in the Console".
- The confirmation step is "check Billing and Tag Editor". There is no command that proves nothing is left.

Forward references:
- `compose.yaml` already contains `FAIL_HEALTH`, `SLOW_MS` and `ENABLE_ERROR_ENDPOINT` for "Months 3 and 4". It is documented as inert, but it is still forward material.
- The healthcheck comment mentions "Month 3".
- `ecs_status.py` docstring uses `orders-dev`, the Month 2 name.
- "tested in Month 2 with a fake AWS" and "Month 3 turns [immutability] on".

Unpinned versions:
- `pip install fastapi uvicorn` and `pip install pytest httpx` are unpinned at install time (`index.html:1310`). The learner then freezes whatever they got, and the course **never says which versions it tested**.
- `boto3==...` and `requests==...` are left as `...` for the learner to fill in.
- `FROM python:3.12-slim` is a floating minor tag until Month 5.
- `runs-on: ubuntu-latest` everywhere.
- Actions are pinned by major tag (`@v7`, `@v6`, `@v2`, `@v1`). That meets CLAUDE.md's `@v4` rule.

CLAUDE.md rule "No lab may leave … ECS service running by default": **violated**. The service created in Week 3 is meant to keep running through Weeks 4–5.

Hard-coded values:
- Placeholders like `<ACCOUNT_ID>` are used, which is good.
- But `task-definition.json` and the IAM JSON make the learner type in the account ID and region by hand. The Week 3 shell block already derives `ACCOUNT_ID` from `aws sts get-caller-identity`, so the JSON could use the same lookup.

### 3.4 Month 2: Infrastructure as Code (4 weeks)

Sections: What changes · 2.1 Why IaC · 2.2 Concepts · 2.3 Install Terraform · 2.4 Repo structure · 2.5 Domain plus state bucket · 2.6 Global layer, modules, dev · 2.7 HTTPS, staging, prod-as-plan, CI, drift · 2.8 Cost, teardown, docs · 2.9 Bring-up order · 2.10 Complete code (17 files) · `check_tags.py` plus moto tests · Troubleshooting · Pass criteria · 2.11 Review (8 questions, with key).

What's missing against the template:
- No in-month cost table. §2.8 says "use the Pricing Calculator". The figures (about USD 80 a month for dev plus staging) are only on the Start page, and there's no $/day.
- No last-verified date. The code is explicitly "not run against a real AWS account" (`index.html:3947`).
- Debugging is partial: the drift exercise is a deliberate break.

Teardown (§2.8): `terraform destroy` per environment is described in prose, with a Console and Billing check. There's no command block and no confirmation command (for example `aws resourcegroupstaggingapi get-resources --tag-filters Key=Environment,Values=dev`, or the `check_tags.py` already built this month).

Unpinned versions:
- Terraform CLI comes from `apt install terraform` with no version (`index.html:1965`).
- `required_version = ">= 1.10"` is a lower bound only.
- `hashicorp/setup-terraform@v4` has **no `terraform_version` input**, so CI runs whatever is newest.
- `moto[all]==...` is left to the learner.
- Provider pin `~> 6.0` is acceptable.

Region: `us-east-1` is hard-coded in `backend.tf` (dev, staging, prod, global), the bucket name `tfstate-<ACCOUNT_ID>-us-east-1`, `variables.tf` defaults, `tfvars.example`, `ecr get-login-password --region us-east-1` and `check_tags.py` (`REGION = "us-east-1"`). This conflicts with the "pick eu-west-1" option in Lesson 0.7.

Cost note: a domain purchase (USD 10–15 a year) and a hosted zone (USD 0.50 a month) are **required**, with no free path. This is a money and payment-card blocker for some learners (see B12).

Forward references:
- `outputs.tf` describes an output as "Used … in CloudWatch alarms (Month 4)".
- The ECS module comment reads "see Month 4 before enabling".
- The ECR module comment reads "Month 3 changes this to IMMUTABLE".

### 3.5 Month 3: Safe Releases (4 weeks)

Sections: What changes · 3.1 Concepts · 3.2 Choosing blue/green · 3.3 Release flow · 3.4 Versioned artifacts and tests · 3.5 Blue/green, approval, rollback · 3.6 Failure injection · 3.7 Runbook and trade-offs · 3.8 Bring-up · 3.9 Complete code · `release_info.py` · Troubleshooting · Pass criteria · 3.10 Review (7 questions, with key).

What's missing against the template:
- **No cost section in the month.** Blue/green briefly doubles tasks, and there's a second target group and an 8443 listener, but the cost is only called "About the same / Briefly double".
- Teardown is one sentence: "terraform destroy per environment".
- No last-verified date. The code is explicitly not run against AWS (`index.html:5705`).

Accuracy note: the course says AWS now recommends ECS-native blue/green for new projects (since July 2025), yet teaches CodeDeploy. That's a reasonable choice, but CLAUDE.md requires a doc citation for it. The course links none.

Forward references:
- The monitoring module is described as "Month 4 extends it".
- "Stretch goal after Month 6".

Pins: same as Month 2 (actions by major tag, `ubuntu-latest`, Terraform CLI unpinned in CI).

### 3.6 Month 4: Observability (4 weeks)

Sections: What changes · 4.1 Concepts · 4.2 Reliability maths · 4.3 What to watch · 4.4 Structured logs · 4.5 Dashboards, alarms, SNS · 4.6 Failure drills · 4.7 Incident write-up · 4.8 Bring-up · 4.9 Complete code · Practise drills locally · `error_budget.py` · Troubleshooting · Pass criteria · 4.10 Review (6 questions, with key).

What's missing against the template:
- **No teardown section at all.** This month adds SNS topics, subscriptions, alarms and dashboards. Dashboards cost about USD 3 a month each and are billed even with no traffic.
- The costs in §4.5 have no assumptions about how many alarms or dashboards there are, and no $/day.
- No last-verified date.

Drill steps (§4.8) tell the learner to switch failure flags "in the Console: Update service → new task definition revision" with no click path and no "UI as of".

Forward references: none found that point to Months 5–6.

### 3.7 Month 5: DevSecOps (4 weeks)

Sections: What changes · 5.1 Concepts · 5.2 Threat model · 5.3 Identity, secrets, repo protection · 5.4 Scanners and gates · 5.5 Fail-a-gate demonstration · 5.6 Checklist · 5.7 First Checkov scan · 5.8 Bring-up · 5.9 Complete code · `scan-local.sh` · `iam_wildcards.py` · Troubleshooting · Pass criteria · 5.10 Review (6 questions, with key).

What's missing against the template:
- **No teardown section.** Secrets Manager secrets bill about USD 0.40 a month each and sit in a 7-day recovery window after deletion. That is only mentioned in *Month 6* troubleshooting.
- GuardDuty and Security Hub "trial" costs are mentioned with no figures.
- No last-verified date. The code is explicitly not run against AWS (`index.html:6687`).

Unpinned versions:
- **`pip install pip-audit bandit checkov` is unpinned in CI** (`security.yml`, `index.html:6534`) and locally (`index.html:6458, 7278`). This is the course's own security gate.
- §5.7 quotes exact Checkov results ("246 passed, 17 failed", then "259 passed, 0 failed, 37 skipped"). Those counts will change whenever Checkov is updated, so a learner's numbers won't match.
- Trivy is correctly pinned (`trivy=0.76.2`, `aquasec/trivy:0.76.2`).
- Base image pinning by digest is introduced here.

Hard-coded ARN: the example secret ARN ends in `-AbCdEf` (`index.html:6445`), while troubleshooting says "never type it: Secrets Manager adds a random suffix". The two contradict each other.

Local Trivy install is "use the instructions in its official documentation", with no command.

### 3.8 Month 6: Capstone (4 weeks)

Sections: What changes · 6.1 Requirements · 6.2 Audit, ADRs · 6.3 Clean-room rebuild · 6.4 Harden, failure matrix, costs · 6.5 Present · `cost_report.py` · Troubleshooting · Pass criteria · 6.6 Final practical review.

What's missing against the template:
- The self-check is a "30-minute mock review" with **no answer key**.
- Final teardown is prose only: "destroy every environment… destroy infra/global… empty and delete the state bucket". No commands. The `prevent_destroy` hosted zone and the `force_delete` ECR are only covered in troubleshooting.
- No last-verified date.

Cost:
- DynamoDB is optional with no figure ("costs very little").
- EKS is about USD 70+ a month, which is good to state.
- Cost allocation tags take up to 24 hours. This is noted, but activation is placed in Month 6, when it would be more useful in Month 2.

### 3.9 Reference and Answer keys

- Reference has a **version table dated 16 Nov 2026**. This is the only "verified" date in the course, and it has no matching log of tested tool versions (`terraform version`, `aws --version`, `docker version`).
- Answer keys cover Months 1–5 and the end-of-milestone questions. **Module 0 and Month 6 have no keys.**

---

## 4. Cross-cutting issue lists

### 4.1 Unpinned or loosely pinned versions

| Item | Where | Status | CLAUDE.md rule |
|---|---|---|---|
| `hello-world` image (implicit `:latest`) | Lesson 0.6, Module 0 checkpoint | ❌ unpinned | Never `:latest` |
| `python:3.12-slim` | Dockerfile, M1–M4 | ◐ floating minor tag; pinned by digest only in M5 | Pin image tags |
| AWS CLI v2 installer | Lesson 0.7 | ❌ always latest | Pin every version |
| `apt install terraform` | M2 §2.3 | ❌ unpinned | Pin every version |
| `required_version = ">= 1.10"` | All `backend.tf` | ◐ lower bound only | — |
| `hashicorp/setup-terraform@v4` with no `terraform_version` | `terraform.yml`, `drift.yml` | ❌ CI Terraform floats | Pin every version |
| `runs-on: ubuntu-latest` (19 places) | All workflows | ◐ runner image floats | — |
| `pip install fastapi uvicorn` / `pytest httpx` | M1 §1.4 | ❌ no tested versions published | Pin Python deps |
| `boto3==...`, `requests==...`, `moto[all]==...` | M1 §1.8, M2 | ❌ left blank for the learner | Pin Python deps |
| `pip install pip-audit bandit checkov` | M5 CI and local | ❌ unpinned | Pin Python deps |
| Docker Desktop, Ubuntu release, VS Code | Module 0 | ❌ not stated | Last verified |
| GitHub Actions `@v7/@v6/@v2/@v1/@v4` | All workflows | ✅ major-tag pins (SHA pins come in M5) | ✅ |
| Terraform AWS provider `~> 6.0` | All roots | ✅ | ✅ |
| Trivy `0.76.2` | M5 | ✅ | ✅ |

### 4.2 Missing teardown or cost notes

| Unit | Creates billable resources | Teardown in unit | Confirmation step | Cost in unit | $/day if skipped |
|---|---|---|---|---|---|
| M0 | No | n/a | n/a | "free" (uncited) | n/a |
| M1 | ALB, Fargate, public IPv4, ECR, logs | Week 5 only (not after Weeks 3–4) | ❌ ("check Billing") | ✅ table | ❌ |
| M2 | Two envs, domain, hosted zone, ACM, Route 53 | Prose only | ❌ | ❌ (Start page only) | ❌ |
| M3 | Blue/green (double tasks), extra listener | One sentence | ❌ | ❌ | ❌ |
| M4 | SNS, alarms, dashboards | **❌ none** | ❌ | ◐ | ❌ |
| M5 | Secrets Manager secrets | **❌ none** | ❌ | ◐ | ❌ |
| M6 | Optional DynamoDB, rebuild | Prose, no commands | ◐ (`cost_report.py --leftovers`) | ◐ | ❌ |

Teardown gaps that apply across months:
- IAM roles and the OIDC provider are kept on purpose ("cost nothing"). That's correct, but their **final** deletion is never shown as commands.
- The S3 state bucket is versioned, so deleting it needs every object *version* deleted first. That step isn't given, and a beginner gets stuck on `BucketNotEmpty`.

### 4.3 Forward references

CLAUDE.md says a module may reference earlier modules but **never** later ones. These are the violations, grouped:

**Dependency forward references** (the learner needs something taught later). These must be fixed:
- Lesson 0.2b `preflight.sh` requires `docker` and `aws`, from 0.6 and 0.7.
- M1 §1.7 uses `jq`, which is **never installed anywhere in the course** (see B8).
- The Start page cost section depends on `scripts/cost_report.py` from Month 6.

**Signposting forward references** (mentions only). These break the letter of the rule:
- M0 §0.5 ("Month 3").
- M1 `compose.yaml` failure flags and comments ("Months 3 and 4").
- M1 notes: "Month 3 turns it on", "replaced in Month 3", "tested in Month 2", `orders-dev`.
- M2 code comments ("Month 3", "Month 4").
- M3 ("Month 4 extends it", "after Month 6").
- The Start page roadmap tables. These are probably acceptable as navigation; decide on a policy.

### 4.4 Console steps without "UI as of <date>"

0 of about 17 Console steps are dated:
- 0.4 GitHub SSH keys
- 0.6 Docker Desktop WSL integration
- 0.7 root MFA, Identity Center, Budgets, Free tier page
- M1 §1.6 Step 2 (7 resources) and Step 5 (ECS service)
- M1 §1.7 IAM identity provider; GitHub variables
- M1 teardown (security groups, Billing, Tag Editor)
- M2 §2.9 detach policy; hosted zone ID lookup
- M3 §3.5 and §3.8 GitHub Environments
- M4 §4.8 Update service; SNS confirmation
- M5 §5.3 branch rules and secret scanning
- M6 cost allocation tags

---

## 5. Where a beginner (no AWS, no Linux) gets blocked

These are ordered by where the learner hits them. **Severity:** 🔴 hard block (the learner cannot continue without outside help) · 🟠 likely block · 🟡 friction.

| # | Where | Blocker | Sev |
|---|---|---|---|
| B1 | Start page (`index.html:297`) | Assumes a Solutions Architect certification. Every later section is pitched at that level. | 🔴 |
| B2 | Start page and Module 0 | **There is no "create an AWS account" lesson.** The self-assessment asks "Do I have my own account?", but sign-up (card, phone verification, support plan choice, root email) is never taught. | 🔴 |
| B3 | Lesson 0.1 | Windows only. There's no path for macOS or Linux learners. WSL needs hardware virtualization (BIOS) and a recent Windows build; neither is mentioned, and there's no troubleshooting. | 🟠 |
| B4 | Lessons 0.2, 0.2b | **Linux permissions are never explained:** `sudo`, `chmod +x`, users and groups, why `~/.ssh` must be private, why `/mnt/c` causes "permission problems". CLAUDE.md says this must never be assumed. | 🟠 |
| B5 | Lesson 0.4 | `ssh-keygen` prompts (file location, passphrase), the first-connect fingerprint prompt and ssh-agent aren't explained. "Test with `ssh -T`" has no expected output. | 🟡 |
| B6 | Lesson 0.6 | Docker Desktop install is one sentence: no license note, no WSL 2 backend check, no "what if `docker version` shows only Client". | 🟠 |
| B7 | Lesson 0.7 (`index.html:1188`) | **IAM Identity Center is one sentence** for a multi-step process: enable Identity Center (and Organizations), create a user, accept the invite email, create a permission set, assign it to the account, find the start URL. Root MFA and Budgets also have no steps. There is no explanation of *what* root, IAM, Identity Center or a permission set are. | 🔴 |
| B8 | Lesson 0.7 | The prompts for `aws configure sso` (session name, start URL, SSO region, scopes, default region) aren't explained. **`aws sso login` is never taught**, yet sessions expire and every later lab needs it. It is only mentioned in a script docstring in Month 1. | 🔴 |
| B9 | Lesson 0.7 | The AWS CLI installer is x86_64 only. ARM laptops (for example Windows on ARM) fail with no note. | 🟡 |
| B10 | M1 §1.7 | **`jq` is used but never installed.** `preflight.sh` lists it as "installed later", and it never is. The OIDC sub IDs, which the deploy depends on, come from this command. | 🔴 |
| B11 | M1 §1.6 Step 2 | Seven AWS resources are each created from one line of description, with no click paths. Never explained: **default VPC, subnets, AZs, CIDR, what makes a subnet "public"**, how to tell which subnets are public, security-group references (source = another SG), and creation order (the target group must exist before the ALB listener). | 🔴 |
| B12 | M1 §1.6 | Creating `ecsTaskExecutionRole` gives no steps and doesn't explain its trust policy (`ecs-tasks.amazonaws.com`). Some accounts already have it; that case isn't covered. | 🟠 |
| B13 | M1 §1.7 | **IAM semantics** (policy document structure, Principal, Action, Resource, Condition, trust policy vs permission policy, `iam:PassRole`, how evaluation works) arrive at once as JSON with a few sentences of explanation. No IAM docs are cited, against CLAUDE.md's rule for IAM evaluation logic. | 🔴 |
| B14 | M1 §1.8 | Teardown needs `<ALB_ARN>` and `<TG_ARN>` with no lookup command. Security-group deletion is "in the Console". Deleting out of order gives `DependencyViolation`, which isn't covered until Month 6. | 🟠 |
| B15 | M1–M5 | **The code has never run against AWS.** When something fails, the learner can't tell whether the course is wrong. | 🔴 |
| B16 | M2 §2.5 | A domain purchase is **required**: money, a payment card, and for outside registrars a manual name-server change with propagation delay. There's no free alternative (for example, staying on the ALB DNS name over HTTP). | 🟠 |
| B17 | M2 §2.5 and §2.6 | Choosing `eu-west-1` (offered in 0.7) means editing about 20 hard-coded `us-east-1` values, and `create-bucket` needs extra flags. | 🟠 |
| B18 | M2 §2.6 and §2.7 | HCL language features (`for_each`, `for` expressions, `jsonencode`, `import` blocks, `-chdir`, `${VAR%%/*}` shell expansion) are used with little explanation. | 🟠 |
| B19 | M2 §2.9 | `TFVARS_COMMON` is a multi-line GitHub variable built from `terraform.tfvars`, with no example of its exact contents. | 🟡 |
| B20 | M2 teardown | Deleting the versioned state bucket at course end needs all object versions removed first. Not shown. | 🟡 |
| B21 | M3 §3.8 | `test_listener_cidr = "<IP>/32"`: the CIDR/32 notation isn't explained (subnetting, again). Home IPs change, which silently breaks the 8443 check. | 🟡 |
| B22 | M4 §4.8 | Failure flags are switched "in the Console: Update service → new task definition revision" with no steps. | 🟠 |
| B23 | M5 §5.4 | Local Trivy install is just "see official docs", although CI shows a working apt recipe. | 🟡 |
| B24 | M5 §5.7 | The quoted Checkov pass/fail counts won't match the learner's run (Checkov is unpinned), so a learner may think they made a mistake. | 🟡 |
| B25 | Throughout | GitHub UI paths (Settings → Environments, Rules, Variables) aren't dated, and GitHub moves these often. | 🟡 |

---

## 6. Claims the `qa` agent needs to check against official docs

I didn't verify these. They're high-impact if wrong, and CLAUDE.md requires a citation for anything non-obvious:

1. GitHub OIDC `sub` format `repo:OWNER@OWNER_ID/REPO@REPO_ID:…` for repos created after **15 July 2026**, and "immutable subject claims" for older repos. Every trust policy depends on this. The course links "GitHub's OIDC reference" but no specific page or section.
2. Action major versions: `actions/checkout@v7`, `setup-python@v7`, `upload-artifact@v7`, `configure-aws-credentials@v6`, `setup-terraform@v4`, `attest-build-provenance@v4`, and "all run on Node 24".
3. Trivy supply-chain incident **CVE-2026-33634**, the malicious range 0.69.4–0.69.6, and 0.76.2 being safe.
4. ALB policy `ELBSecurityPolicy-TLS13-1-2-Res-PQ-2025-09` being AWS's recommended policy.
5. ECS-native blue/green (July 2025) and "AWS now recommends the ECS-native option".
6. Terraform S3 backend `use_lockfile` (1.10+) replacing DynamoDB locking.
7. CloudWatch alarms can't publish to an SNS topic encrypted with the AWS-managed key (M5 §5.7 CKV_AWS_26 reasoning).
8. Artifact attestations need GitHub Enterprise Cloud for private repos.
9. Pricing figures: ALB USD 16–20 a month, Fargate 0.25 vCPU/0.5 GB about USD 9 a month, public IPv4 USD 3.60 a month each, dashboards about USD 3, secrets USD 0.40, EKS USD 70+, hosted zone USD 0.50. Assumptions are partly stated (us-east-1) but no pricing date is given.
10. The sample preflight output (`Python 3.13.18`, `Docker version 29.9.3`). Re-capture it from a real machine.

---

## 7. What already meets the bar (keep it)

- The Month 1 network drill (§1.5) and the 0.3b error-type table are excellent debugging material and the right shape for the template's debugging lab.
- The Month 5 fail-a-gate demonstrations (§5.5) and the Month 3 failure injection with a probe log (§3.6) are model "failure and the fix" labs.
- Troubleshooting tables in every month follow symptom → cause → confirm → fix.
- Honesty rules: "never claim zero downtime unless the log shows it", and "not run against a real AWS account" is stated openly.
- The no-NAT-Gateway design (§1.2) is explained, with its cost and trade-off.
- Answer keys exist for Months 1–5, with the key ideas in bold.
- Placeholders (`<ACCOUNT_ID>`) are used everywhere. I found no real account IDs or credentials (a scan for 12-digit numbers came back empty).

---

## 8. Suggested fix order (for the next stage, not done here)

1. **Decide the learner.** Rewrite the opening paragraph for "no AWS experience". Then add the missing foundations: an AWS account sign-up lesson; Identity Center step by step, with `aws sso login`; Linux permissions; IAM basics with citations; VPC, subnets and CIDR basics; and installing `jq`. This fixes B1, B2, B4, B7, B8, B10, B11 and B13.
2. **Run every lab once against a real account** and record a "Last verified" block (date, region, `aws --version`, `terraform version`, `docker version`, Python, action versions) in every unit.
3. **Add per-lab teardown and confirmation commands**, especially for Months 4 and 5 and after Month 1 Weeks 3–4. Add "if you skip teardown: $X/day" with pricing assumptions and a pricing date.
4. **Pin the gaps in 4.1**: scanners, the Terraform CLI in CI, Python deps (publish tested versions), `hello-world`, the base image.
5. **Parameterize the region** (one variable, plus `-backend-config` for the bucket and region), or drop the `eu-west-1` option.
6. **Restructure to the CLAUDE.md layout** (`/phases`, `/assessments`, `/solutions`). Map Months to Phases (section 2), build a real Phase 0 diagnostic gate, move answer keys out of the nav, and decide on Ansible and multi-env placement.
7. Add "UI as of <date>" to every Console step, and give a CLI alternative where one exists.
8. Remove or rephrase the forward references in 4.3.
