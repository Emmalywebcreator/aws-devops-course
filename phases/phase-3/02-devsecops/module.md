# Phase 3 · Module 3.2 — DevSecOps: scanning, secrets and policy-as-code

## 1. Goal

Make the `aws-devops-platform` pipeline refuse leaked secrets, vulnerable dependencies and images, and unsafe infrastructure — then move the app's API key into AWS Secrets Manager and recover from a real secrets outage.

## 2. Prerequisites

- **Gates:** [Phase 0 exit gate](../../../assessments/gate-rules.md#part-2-the-phase-0-exit-gate) passed **and Phase 2 complete** (repo matches [the Phase 2 exit contract](../../phase-2/CONTRACT.md)).
- **Modules:** [3.1 Multi-environment Terraform](../01-multi-env-terraform/module.md) (this module uses `infra/envs/dev` and the `terraform.yml` matrix).
- **Tools:** Python 3.12 venv (Phase 1), Docker (Phase 1), Terraform 1.17.2, AWS CLI 2.33.14.
- **Access:** admin profile; repo secret `AWS_DEPLOY_ROLE_ARN`.

## 3. Time estimate

**6–8 hours** (Lab 1: 45 min · Lab 2: 45 min · Lab 3: 1 h · Lab 4: 1 h · Lab 5: 1–1.5 h · Lab 6: 1–1.5 h · Incident lab: 1 h · teardown 15 min).

## 4. Cost estimate

| Resource | Billed while idle? | Unit price (assumption) | Expected use | Cost |
|---|---|---|---|---|
| `dev` env (Labs 6 + incident) | yes | ≈ USD 0.055/hour (Phase 2 contract §6) | ≤ 3 h | ≤ USD 0.17 |
| Secrets Manager secret `orders/dev/api-key` | yes, prorated monthly | USD 0.40 per secret-month; USD 0.05 per 10,000 API calls | ≤ 1 day | ≤ USD 0.02 |
| GitHub Actions minutes | — | free for public repos / within the free allowance for private | ~30 min | USD 0 |
| Scanners (gitleaks, pip-audit, bandit, Trivy, Checkov, conftest) | — | open source, run locally/CI | — | USD 0 |

- **Pricing assumptions:** Region `us-east-1`; on-demand; no free trial assumed (new secrets may get a 30-day trial, see pricing page). **Not re-checked** against https://aws.amazon.com/secrets-manager/pricing/ (checked: not yet). Env figure from the Phase 2 contract.
- **Total if you follow teardown:** under **USD 0.25**.
- **If you skip teardown: ≈ USD 1.33/day** (dev env 0.055 × 24 = 1.32 + secret 0.40 / 30 = 0.013).

## 5. Concepts

### Why "shift left"

Every security problem is cheaper to stop before it's deployed. A leaked key found in a pull request costs one rotation; found by an attacker, it costs your account. DevSecOps means the **pipeline** checks, every time, so security doesn't depend on someone remembering.

### Five checks, five different problems

| Check | Problem it catches | Tool (pinned) |
|---|---|---|
| **Secret scanning** | Keys/tokens committed to Git | gitleaks **8.30.1** |
| **Dependency audit** | Python packages with known vulnerabilities (CVEs) | pip-audit **2.10.1** |
| **Static analysis (SAST)** | Risky code patterns (e.g. `subprocess(shell=True)`, hard-coded passwords) | bandit **1.9.4** |
| **Image scanning** | Vulnerable OS packages and libraries inside the built image | Trivy **0.76.2** — pinned on purpose: 0.69.4–0.69.6 were malicious after the March 2026 supply-chain attack (CVE-2026-33634) |
| **IaC scanning** | Insecure Terraform (open security groups, unencrypted storage) against hundreds of built-in rules | Checkov **3.4.5** |

### Policy-as-code

Scanners know *general* best practice. Your team also has **its own rules** — "every resource must carry an `env` tag", "nothing opens port 22 to the internet". **Policy-as-code** writes those rules in a language a tool can test, so they're reviewed like code and enforced on every plan. Here: **conftest 0.71.1** runs **Rego** policies (the Open Policy Agent language) against `terraform show -json` output.
Source: https://www.conftest.dev/ · https://www.openpolicyagent.org/docs/policy-language

### Where secrets live

An environment variable typed into a task definition is visible to anyone who can read the task definition. **AWS Secrets Manager** stores the value encrypted; ECS fetches it **at task start** using the **task execution role**, and injects it as an env var. Two consequences you'll use in the incident lab:

1. If the execution role can't read the secret, or the secret is gone, **new tasks can't start** (`ResourceInitializationError`).
2. Deleting a secret is **not instant** by default — it's *scheduled* with a 7–30 day recovery window, during which you can **restore** it.

Sources: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/secrets-envvar-secrets-manager.html · https://docs.aws.amazon.com/secretsmanager/latest/userguide/manage_delete-restore-secret.html

### Keeping the value out of Terraform state

If Terraform sets a secret's value, the value is stored in Terraform state. This module has Terraform create the secret **container** only, and you set the value with the CLI — so the state file never holds it.

---

## 6. Labs

> **Region:** `us-east-1` everywhere. `export AWS_REGION=us-east-1 AWS_PROFILE=<your-admin-profile>`. Work in your `aws-devops-platform` repo on a branch: `git switch -c phase3/devsecops`. Install scanner tools into the project venv:
>
> ```bash
> source .venv/bin/activate
> pip install pip-audit==2.10.1 bandit==1.9.4 checkov==3.4.5
> printf 'pip-audit==2.10.1\nbandit==1.9.4\ncheckov==3.4.5\n' > requirements-security.txt
> ```
>
> Binary tools (Linux x86_64 / WSL; macOS: pick the `darwin` asset from the same release page):
>
> ```bash
> mkdir -p ~/.local/bin
> curl -fsSL https://github.com/gitleaks/gitleaks/releases/download/v8.30.1/gitleaks_8.30.1_linux_x64.tar.gz | tar xz -C ~/.local/bin gitleaks
> curl -fsSL https://github.com/open-policy-agent/conftest/releases/download/v0.71.1/conftest_0.71.1_Linux_x86_64.tar.gz | tar xz -C ~/.local/bin conftest
> gitleaks version      # expect: 8.30.1  (TODO(verify): exact output format)
> conftest --version    # expect: Conftest: 0.71.1 …
> ```
>
> Trivy runs from its pinned container image, so there's nothing to install: `docker run --rm aquasec/trivy:0.76.2 --version`.

### Lab 1 — Catch a leaked token before it's pushed

- **Region:** none (local Git).
- **Task:**

```bash
gitleaks git . --redact -v                       # scan full history — expect: no leaks found
git switch -c leak-test
FAKE="ghp_$(LC_ALL=C tr -dc 'A-Za-z0-9' </dev/urandom | head -c 36)"   # random, not a real token
echo "GITHUB_TOKEN=$FAKE" > leaked.env && git add -f leaked.env && git commit -qm "oops"
gitleaks git . --redact -v; echo "exit: $?"
```

- **Expected result:** the second scan reports **1 leak** (rule `github-pat`, file `leaked.env`, secret shown as `REDACTED`) and exits non-zero.
- **Verification command:** `gitleaks git . --redact --log-opts="main..leak-test"; echo $?` → non-zero, and `gitleaks git . --redact --log-opts="main"; echo $?` → `0`.
- **Teardown command:** `git switch phase3/devsecops && git branch -D leak-test` (never pushed — nothing to rotate. If you *had* pushed it: revoke first, then clean history — Phase 0 Git module).
- **Cost note:** USD 0.

### Lab 2 — Dependency audit and static analysis

- **Region:** none.
- **Task:**

```bash
pip-audit -r app/requirements.txt --strict
bandit -r app -ll
```

Then prove the gate works: temporarily add a known-vulnerable pin to `app/requirements.txt` — `requests==2.19.1` (TODO(verify): confirm it still reports a CVE in the current advisory DB) — and add this line to `app/main.py`: `import subprocess; subprocess.call("echo hi", shell=True)`.

- **Expected result:** both commands pass on the clean code; with the bad pin, `pip-audit` lists at least one vulnerability for `requests` and exits non-zero; with the bad line, `bandit` reports **B602** (`subprocess_popen_with_shell_equals_true`) and exits non-zero.
- **Verification command:** `pip-audit -r app/requirements.txt --strict; echo "pip-audit: $?"; bandit -r app -ll -q; echo "bandit: $?"` → both `0` after you revert.
- **Teardown command:** `git checkout -- app/requirements.txt app/main.py`
- **Cost note:** USD 0.

### Lab 3 — Scan the image

- **Region:** none (local Docker).
- **Task:**

```bash
docker build -t aws-devops-platform:scan .
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy:0.76.2 \
  image --severity HIGH,CRITICAL --ignore-unfixed --exit-code 1 aws-devops-platform:scan
echo "trivy exit: $?"
```

`--ignore-unfixed` skips CVEs with no fix available yet — you can't act on those, and failing on them trains people to ignore the gate.

- **Expected result:** a table per target (OS packages, Python packages). Exit `0` if no fixable HIGH/CRITICAL; exit `1` otherwise.
- **If it fails:** rebuild on the newest patch of your pinned base image (e.g. bump `python:3.12.<patch>-slim`), rebuild, rescan. Record any finding you accept in `.trivyignore` **with a comment and an expiry date**.
- **Verification command:** the command above prints `trivy exit: 0`.
- **Teardown command:** `docker image rm aws-devops-platform:scan`
- **Cost note:** USD 0.

### Lab 4 — Scan the Terraform

- **Region:** none.
- **Task:** `checkov -d infra --framework terraform --compact --quiet`
- **Expected result:** a list of `FAILED` checks (counts depend on your Phase 2 code and Checkov's rule set — don't compare with anyone else's numbers). For each failure, either **fix it** or **suppress it in code with a reason**, e.g. inside the resource:

```hcl
  #checkov:skip=CKV_AWS_2:HTTP listener is intentional in dev; HTTPS is the optional track (MAPPING M-5)
```

- **Verification command:** `checkov -d infra --framework terraform --compact --quiet; echo "checkov: $?"` → `checkov: 0`, and `grep -rnE 'checkov:skip=[A-Z0-9_]+[[:space:]]*$' infra` → no output (no skip without a reason).
- **Teardown command:** none (code changes kept).
- **Cost note:** USD 0.

### Lab 5 — Your team's rules as policy-as-code, and all gates in CI

- **Region:** `us-east-1` (plan reads the dev state).
- **Task:**

**5a. Write the policy** in `policy/terraform.rego`:

```rego
package main

import rego.v1

# Rule 1: every taggable resource being created or updated carries an env tag.
deny contains msg if {
  some rc in input.resource_changes
  some action in rc.change.actions
  action in {"create", "update"}
  tags := object.get(rc.change.after, "tags_all", null)
  tags != null
  not tags.env
  msg := sprintf("%s has no 'env' tag", [rc.address])
}

# Rule 2: nothing opens SSH (22) to the whole internet.
deny contains msg if {
  some rc in input.resource_changes
  rc.type == "aws_vpc_security_group_ingress_rule"
  rc.change.after.cidr_ipv4 == "0.0.0.0/0"
  rc.change.after.from_port <= 22
  rc.change.after.to_port >= 22
  msg := sprintf("%s opens port 22 to 0.0.0.0/0", [rc.address])
}

deny contains msg if {
  some rc in input.resource_changes
  rc.type == "aws_security_group"
  some rule in object.get(rc.change.after, "ingress", [])
  "0.0.0.0/0" in rule.cidr_blocks
  rule.from_port <= 22
  rule.to_port >= 22
  msg := sprintf("%s opens port 22 to 0.0.0.0/0", [rc.address])
}
```

**5b. Test it against a real plan:**

```bash
terraform -chdir=infra/envs/dev plan -out=tfplan.bin
terraform -chdir=infra/envs/dev show -json tfplan.bin > plan.json
conftest test plan.json --policy policy/
```

Then break it on purpose: add an SG ingress rule for port 22 from `0.0.0.0/0` to the ecs-service module, re-plan, re-test.

**5c. Gate the pipeline.** Add `.github/workflows/security.yml`:

```yaml
name: security
on:
  pull_request:
permissions:
  contents: read
  id-token: write
jobs:
  secrets:
    runs-on: ubuntu-24.04
    steps:
      - uses: actions/checkout@v7
        with: { fetch-depth: 0 }
      - run: |
          curl -fsSL https://github.com/gitleaks/gitleaks/releases/download/v8.30.1/gitleaks_8.30.1_linux_x64.tar.gz | tar xz gitleaks
          ./gitleaks git . --redact -v --log-opts="origin/${{ github.base_ref }}..HEAD"
  python:
    runs-on: ubuntu-24.04
    steps:
      - uses: actions/checkout@v7
      - uses: actions/setup-python@v7
        with: { python-version: "3.12" }
      - run: pip install -r requirements-security.txt
      - run: pip-audit -r app/requirements.txt --strict
      - run: bandit -r app -ll
      - run: checkov -d infra --framework terraform --compact --quiet
  image:
    runs-on: ubuntu-24.04
    steps:
      - uses: actions/checkout@v7
      - run: docker build -t app:ci .
      - run: >
          docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy:0.76.2
          image --severity HIGH,CRITICAL --ignore-unfixed --exit-code 1 app:ci
  policy:
    runs-on: ubuntu-24.04
    steps:
      - uses: actions/checkout@v7
      - uses: aws-actions/configure-aws-credentials@v6
        with:
          role-to-assume: ${{ secrets.AWS_DEPLOY_ROLE_ARN }}
          aws-region: us-east-1
      - uses: hashicorp/setup-terraform@v4
        with: { terraform_version: 1.17.2, terraform_wrapper: false }
      - run: |
          curl -fsSL https://github.com/open-policy-agent/conftest/releases/download/v0.71.1/conftest_0.71.1_Linux_x86_64.tar.gz | tar xz conftest
          terraform -chdir=infra/envs/dev init -input=false
          terraform -chdir=infra/envs/dev plan -input=false -out=tfplan.bin
          terraform -chdir=infra/envs/dev show -json tfplan.bin > plan.json
          ./conftest test plan.json --policy policy/
```

(`terraform_wrapper: false` stops the setup action's wrapper from adding text to `show -json` output.)

- **Expected result:** clean code → `conftest` prints `N tests, N passed, 0 failures`; with the port-22 rule → `FAIL - … opens port 22 to 0.0.0.0/0` and non-zero exit. On the PR, the four `security` jobs are green.
- **Verification command:** `conftest test plan.json --policy policy/; echo "conftest: $?"` → `0` on clean code, `1` with the bad rule. In the PR's **Checks** tab (UI as of 2026-11-17), `security / secrets`, `python`, `image`, `policy` all pass.
- **Teardown command:** `rm -f plan.json infra/envs/dev/tfplan.bin` and remove the port-22 rule. Add `plan.json` and `*.bin` to `.gitignore`.
- **Cost note:** USD 0 (plan only).

### Lab 6 — Move the API key into Secrets Manager

- **Region:** `us-east-1`
- **Task:**

**6a. Terraform creates the secret (no value)** — in `infra/envs/dev/secrets.tf`:

```hcl
resource "aws_secretsmanager_secret" "api_key" {
  name                    = "orders/dev/api-key"
  recovery_window_in_days = 7   # deletes are recoverable for 7 days
}
```

and pass it to the service: `container_secrets = { ORDERS_API_KEY = aws_secretsmanager_secret.api_key.arn }` (the Phase 2 module grants the task execution role `secretsmanager:GetSecretValue` on exactly the ARNs in this map — contract §4).

```bash
terraform -chdir=infra/envs/dev apply -target=aws_secretsmanager_secret.api_key
```

**6b. Set the value from the CLI** so it never touches Terraform state:

```bash
aws secretsmanager put-secret-value --secret-id orders/dev/api-key \
  --secret-string "$(aws secretsmanager get-random-password --password-length 32 --exclude-punctuation --query RandomPassword --output text)"
terraform -chdir=infra/envs/dev apply
```

- **Expected result:** the service rolls to a new task definition revision; `POST /orders` without the header returns `401`/`403`; with the header it succeeds.
- **Verification command:**

```bash
ALB="http://$(terraform -chdir=infra/envs/dev output -raw alb_dns_name)"
KEY="$(aws secretsmanager get-secret-value --secret-id orders/dev/api-key --query SecretString --output text)"
curl -s -o /dev/null -w '%{http_code}\n' -X POST "$ALB/orders" -H 'content-type: application/json' -d '{"item":"x"}'
# expect: 401 or 403
curl -s -o /dev/null -w '%{http_code}\n' -X POST "$ALB/orders" -H 'content-type: application/json' -H "x-api-key: $KEY" -d '{"item":"x"}'
# expect: 200 or 201
unset KEY
aws ecs describe-task-definition --task-definition orders-dev \
  --query 'taskDefinition.containerDefinitions[0].secrets' --output table
# expect: ORDERS_API_KEY → the secret ARN (not the value)
terraform -chdir=infra/envs/dev state pull | grep -c "$(aws secretsmanager get-secret-value --secret-id orders/dev/api-key --query SecretString --output text)"
# expect: 0   (the value is not in state)
```

- **Teardown command:** at module end (section 9).
- **Cost note:** ≈ USD 0.013/day for the secret + the dev env while up.

## 7. Debugging lab (incident)

- **Scenario — the page you get:**

> 🚨 **PagerDuty — 03:12 — orders-dev: ALB healthy host count = 0 (5 min).** Synthetic check `GET /health` → **503**. Last deploy: none in 14 hours. A teammate posted in #ops at 02:50: *"cleaning up unused secrets in the account 🧹"*. **You're on call. Restore service, find the root cause, and propose one prevention.**

- **How to create the broken state** (dev env from Lab 6 must be up):

```bash
export COURSE=<path to your clone of this course repo>
bash "$COURSE/phases/phase-3/02-devsecops/labs/incident-secret-outage/break.sh"
```

Wait ~2 minutes, then check the symptom.

- **Symptom you will see:** `curl http://<alb>/health` → `503 Service Temporarily Unavailable`. The ECS service shows `runningCount: 0` and keeps trying to start tasks.
- **Your task:** using `aws ecs describe-services` (events), `aws ecs list-tasks --desired-status STOPPED` + `describe-tasks` (`stoppedReason`), and `aws secretsmanager describe-secret`, find the cause, **restore service without changing Terraform code**, and write a 3-line incident note (impact, root cause, prevention).
- **Done when:**

```bash
curl -fsS "http://$(terraform -chdir=infra/envs/dev output -raw alb_dns_name)/health"   # {"status":"ok"}
aws ecs describe-services --cluster orders-dev --services orders-api \
  --query 'services[0].[runningCount,desiredCount]' --output text                       # 1	1
aws secretsmanager describe-secret --secret-id orders/dev/api-key --query DeletedDate --output text   # None
```

- **Teardown:** nothing extra — section 9 removes the env and secret.

Diagnosis path: `solutions/incident.md`.

## 8. Self-check

Answers: `solutions/self-check.md`.

1. Name the five scanners in `security.yml` and the one problem each catches that the others can't.
2. Why does Lab 3 use `--ignore-unfixed`, and what's the risk of using it?
3. Show a `checkov:skip` from your repo and explain why the reason text matters.
4. Write (or point to) the Rego rule that would fail a plan creating an untagged resource. Run `conftest` to prove it fires.
5. Prove the API key value is not in Terraform state, and explain why Lab 6 set it with the CLI.
6. Which IAM role reads the secret at task start — the task role or the task execution role? What error do you get if it can't?
7. A secret was deleted 2 days ago with the default recovery window. Can you get it back? With which command? What if it was deleted with `--force-delete-without-recovery`?
8. Why is Trivy pinned to an exact version in this course, more than any other tool?

## 9. Teardown

```bash
export AWS_REGION=us-east-1
# Delete the secret immediately (course only — in production you'd keep the recovery window)
aws secretsmanager delete-secret --secret-id orders/dev/api-key --force-delete-without-recovery
terraform -chdir=infra/envs/dev state rm aws_secretsmanager_secret.api_key
./scripts/teardown.sh dev
docker image rm aws-devops-platform:scan 2>/dev/null || true
```

**Confirm nothing is left:**

```bash
aws secretsmanager list-secrets --include-planned-deletion \
  --query "SecretList[?starts_with(Name, 'orders/')].[Name,DeletedDate]" --output text
# expect: no output (TODO(verify): a force-deleted secret may appear briefly)
aws resourcegroupstaggingapi get-resources --tag-filters Key=env,Values=dev \
  --query 'ResourceTagMappingList[].ResourceARN' --output text
# expect: no output
```

Merge `phase3/devsecops`: the security workflow, `policy/`, `requirements-security.txt` and `secrets.tf` stay in the repo for later modules.

## 10. Last verified

- **Date:** NOT YET VERIFIED — drafted 2026-11-17.
- **Verified by:** —
- **Region:** `us-east-1`
- **Versions:** gitleaks 8.30.1 · pip-audit 2.10.1 · bandit 1.9.4 · Trivy 0.76.2 (`aquasec/trivy:0.76.2`) · Checkov 3.4.5 · conftest 0.71.1 · Terraform 1.17.2 · AWS CLI 2.33.14 · Python 3.12 · runner `ubuntu-24.04` · `actions/checkout@v7` · `actions/setup-python@v7` · `aws-actions/configure-aws-credentials@v6` · `hashicorp/setup-terraform@v4`
- **Notes:** versions read from PyPI and GitHub release APIs on 2026-11-17. **Scanner CLI flags were not run** (downloading binaries was not permitted in the authoring session) — they follow each tool's documented interface; `TODO(verify)` marks the uncertain ones. Written against `phases/phase-2/CONTRACT.md`.
