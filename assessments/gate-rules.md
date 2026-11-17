# Phase 0 · Gate rules

This file is the rulebook for two things:

1. **Entry placement:** how the [entry diagnostic](phase-0-entry.md) sends you either straight to Phase 1 or to exactly one starting module, and which later modules you may skip.
2. **The Phase 0 exit gate** (module 0.6): what you must show before Phase 1 unlocks.

Module IDs 0.0–0.6 are listed in [phase-0-entry.md](phase-0-entry.md#phase-0-modules).

---

## Part 1: Entry placement

### 1.1 Grading items

| Item type | Counts as right / pass when… |
|---|---|
| Multiple choice (Q1, Q2, Q4–Q12) | You chose the single correct letter. "I don't know", a blank, or more than one letter is **wrong**. |
| Output check (Q3) | Both printed lines match the accepted values in the answer key. |
| Practical task (T1–T3) | **Every** verification check matches. If you couldn't attempt it, it **fails**. If you took more than 2× the target time, it **fails**. |

**Anything you didn't answer is wrong / failed.** Grade with the answer key only after answering everything, and don't change an answer once you've seen the key.

### 1.2 Routing table

Every item belongs to exactly one module.

| Item | Checks | Module |
|---|---|---|
| Q1 | Root user handling | 0.0 |
| Q2 | A budget alerts; it doesn't stop spending | 0.0 |
| T1 | CLI as IAM user, root MFA + no root keys, budget + billing alarm | 0.0 |
| Q3 | You have a working Linux/macOS shell | 0.1 |
| Q4 | Reading `rwx` permissions | 0.1 |
| Q5 | `>` overwrites a file | 0.1 |
| T2 | `chmod` with least privilege | 0.1 |
| Q6 | CIDR block size | 0.2 |
| Q7 | DNS failure vs other network failures | 0.2 |
| Q8 | add → commit → push | 0.3 |
| Q9 | Leaked secrets live on in Git history | 0.3 |
| T3 | Branch, merge, `.gitignore`, SSH push | 0.3 |
| Q10 | Reading a Python list comprehension | 0.4 |
| Q11 | Why virtual environments exist | 0.4 |
| Q12 | IAM evaluation: explicit deny wins | 0.5 |

### 1.3 The placement rule

> **1. Skip Phase 0** if your score is **at least 10 out of 12** and **all three tasks pass**. Start Phase 1.
> **2. Otherwise**, your starting module is the **lowest-numbered module with at least one wrong question or failed task.**

This always gives exactly one answer:

- Rule 1 is a yes/no test, so it either applies or it doesn't.
- If it doesn't, at least one item is wrong or failed (otherwise you'd have 12/12 and three passes). Every item maps to one module (table 1.2), and module numbers are distinct, so the set of failed modules has exactly one lowest member.

**Worked examples.**

- **Sam:** score 9/12 (wrong: Q7, Q9, Q12), all tasks pass → rule 1 doesn't apply (9 < 10). Failed modules {0.2, 0.3, 0.5} → **start at 0.2**.
- **Priya:** score 11/12 (wrong: Q6), all tasks pass → rule 1 applies → **Phase 1**. Her wrong answer is still useful: read the Concepts section of 0.2 before Phase 1.
- **Lee:** score 12/12, but T1 fails (root has no MFA) → rule 1 doesn't apply → failed modules {0.0} → **start at 0.0**. Tasks are hard requirements because they prove you can *do* it, and T1 is your account's safety.

### 1.4 Your path after the starting module

Go through Phase 0 **in number order**, from your starting module to 0.6.

| Module | What you do |
|---|---|
| Lower than your starting module | **Skip.** You passed every item for it. |
| Your starting module | **Do the whole module.** |
| Higher, with at least one wrong/failed item | **Do the whole module.** |
| Higher, all items passed | **Skip the lessons, but do the module's debugging lab** — the exit gate requires every debugging lab from 0.1–0.5 (Part 2, Gate B). 0.0's debugging lab is optional if you skip 0.0. |
| 0.6 Capstone | **Never skipped.** It is the exit gate. |

Sam's path: **0.2 → 0.3 → 0.4 (debugging lab only) → 0.5 → 0.6**. He skips 0.0 and 0.1 entirely.

### 1.5 Changing your mind

- **Never re-take the diagnostic to skip ahead.** Your path is set; go forward through it.
- **Want to skip a module the diagnostic told you to do?** Take that module's **Self-check** cold. If you get every item right, treat the module as "all items passed" in table 1.4. If you miss one, do the module.
- **Skipped a module and now feel lost?** Do it. Skipping is a convenience, not a promise.

---

## Part 2: The Phase 0 exit gate (module 0.6)

Phase 1 unlocks only when **all four** parts pass: **A** diagnostic or path, **B** debugging labs, **C** capstone teardown verified, **D** written explanations.

Learners who skipped Phase 0 under rule 1.3(1) start Phase 1 directly; this gate doesn't apply to them.

### Gate A: Diagnostic score or path complete

Either your entry diagnostic score was **≥ 10/12**, **or** you completed every module on your path (1.4) and passed its Self-check.

### Gate B: Debugging labs 0.1–0.5 completed

For each of modules 0.1, 0.2, 0.3, 0.4 and 0.5, paste the debugging lab's **"Done when"** commands and their output into `phase-0-exit-evidence.md` (in your own capstone repo), plus one sentence per cause explaining why it broke.

### Gate C: Capstone teardown verified clean

The 0.6 capstone builds, with the CLI and a shell script, in **`us-east-1`**: a VPC, one public EC2 instance running a hello-world app, a security group scoped to your IP, and an S3 bucket for logs. Then a teardown script removes it all.

**Contract the 0.6 module must follow** (so these checks work):

- Every resource it creates carries the tags `course=aws-devops-platform` and `phase=0`.
- It prints the **bucket name** it created, and the teardown script deletes the bucket's objects (and object versions if versioning is on) before the bucket.
- It creates **no NAT Gateway and no Elastic IP** (the instance gets an auto-assigned public IP).

**Evidence.** Run every command below **after** your teardown script, on the same day, and paste commands *and* output into `phase-0-exit-evidence.md`.

```bash
export AWS_PROFILE=<your-profile>
export AWS_REGION=us-east-1
aws login --profile "$AWS_PROFILE"

# G1 — still an IAM user, not root
aws sts get-caller-identity --query Arn --output text
# expect: arn:aws:iam::<account-id>:user/<your-admin-user>

# G2 — root still has MFA and no access keys
aws iam get-account-summary --query 'SummaryMap.[AccountMFAEnabled,AccountAccessKeysPresent]' --output text
# expect: 1	0

# G3 — the 0.0 guardrails are still there
ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
aws budgets describe-budgets --account-id "$ACCOUNT_ID" --query 'Budgets[].BudgetName' --output text
aws cloudwatch describe-alarms --query "MetricAlarms[?Namespace=='AWS/Billing'].AlarmName" --output text
# expect: at least one budget name, and at least one billing alarm name

# G4 — no tagged capstone resources left in us-east-1
aws resourcegroupstaggingapi get-resources \
  --tag-filters Key=course,Values=aws-devops-platform Key=phase,Values=0 \
  --query 'ResourceTagMappingList[].ResourceARN' --output json
# expect: []

# G5 — direct "is it gone?" checks, untagged leftovers included
aws ec2 describe-vpcs --filters Name=tag:phase,Values=0 --query 'Vpcs[].VpcId' --output text           # expect: no output
aws s3api head-bucket --bucket "<your capstone bucket name>"                                              # expect: an error with 404 / Not Found
aws ec2 describe-nat-gateways --filter Name=state,Values=pending,available \
  --query 'NatGateways[].NatGatewayId' --output text                                                       # expect: no output
aws ec2 describe-volumes --filters Name=status,Values=available --query 'Volumes[].VolumeId' --output text  # expect: no output (unattached disks)

# G6 — nothing running and no Elastic IPs in ANY region
for r in $(aws ec2 describe-regions --query 'Regions[].RegionName' --output text); do
  aws ec2 describe-instances --region "$r" \
    --filters Name=instance-state-name,Values=pending,running,stopping,stopped \
    --query 'Reservations[].Instances[].InstanceId' --output text | sed "s/^/$r\tinstance\t/"
  aws ec2 describe-addresses --region "$r" --query 'Addresses[].PublicIp' --output text | sed "s/^/$r\telastic-ip\t/"
done
# expect: no output
```

**G7 — console confirmation (the spec asks for it).** Take a screenshot of **Resource Groups & Tag Editor → Tag Editor**, Regions: *All regions*, Resource types: *All supported resource types*, Tags: `phase` = `0`, showing **no resources** (UI as of 2026-11-17 — not yet click-checked). Save it in your capstone repo as `docs/teardown-confirmation.png`.

**If G4 still lists an ARN you've already deleted:** wait 15 minutes and re-run. If it's still there, run that resource's G5/G6 direct check. **The direct checks decide.** Note the delay in your evidence.

**Gate C pass threshold:** G1–G6 all match their `expect` lines, and the G7 screenshot exists.

### Gate D: Written explanations

In `phase-0-exit-evidence.md`, **in your own words** (notes allowed; copied or AI-written text is not), write:

| # | Prompt | Maps to |
|---|---|---|
| E1 | **IAM evaluation.** A request arrives. Walk through how AWS decides allow or deny when there's an allow, an explicit deny, or neither. Give one example from your capstone. (100–200 words) | 0.5 |
| E2 | **A request path through a VPC.** Someone types your capstone instance's public address into a browser. Trace the request from the internet to your app and back: internet gateway, route table, subnet, security group, instance. Then say what would change if the instance were in a private subnet. (150–250 words) | 0.2, 0.5 |
| E3 | **Why NAT costs money.** What does a NAT Gateway do, what are its two charges, why does it bill even when idle, and how did your capstone avoid needing one? (80–150 words) | 0.5 |

Plus the **1-page write-up** the capstone asks for: *what I built, what I broke, how I fixed it*.

**Scoring:** E1–E3 each score **0, 1 or 2** against the rubric in `/solutions` (not linked here). Self-grading is allowed if you quote the sentence that earns each point; a mentor grades instead if you have one. The write-up passes if it has all three parts and describes at least one real failure and its fix.

**Gate D pass threshold:** every explanation scores at least **1**, the total is at least **5 out of 6**, and the write-up passes.

**Routing on failure:** for each explanation below threshold, re-read the Concepts of the module(s) in its "Maps to" column and rewrite only that explanation after at least 24 hours. Parts that already passed still count.

### Gate result

| A | B | C | D | Result |
|---|---|---|---|---|
| ✅ | ✅ | ✅ | ✅ | **Phase 0 passed. Phase 1 unlocked.** Record the date in your evidence file. |
| any ❌ | | | | Fix only the failing part, then re-check that part. Gate C failures: re-run your teardown script, then all of G1–G7. |

**Deliverables (the spec's list):** the capstone repo, the teardown script, the 1-page write-up, the teardown confirmation screenshot — plus `phase-0-exit-evidence.md`.

---

## Last verified

- **Drafted:** 2026-11-17; rewritten to the 0.0–0.6 spec on 2026-11-17.
- **Run by a human end to end:** ❌ not yet.
- **AWS CLI commands:** names, flags and output fields checked against `aws <cmd> help` in aws-cli 2.33.14. No AWS calls made against a real account. Tag Editor console path not yet click-checked.
- **Depends on:** module 0.6 (not yet written) following the Gate C contract.
