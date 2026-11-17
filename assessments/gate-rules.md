# Phase 0 · Gate rules

This file is the rulebook for two things:

1. **Entry placement:** how the [entry diagnostic](phase-0-entry.md) gives you exactly one starting module, and which later modules you may skip.
2. **The Phase 0 exit gate:** what you must show before Phase 1 unlocks.

Module IDs (P0-M01 … P0-M09) are defined in [phase-0-entry.md](phase-0-entry.md#phase-0-module-ids).

---

## Part 1: Entry placement

### 1.1 Grading items

| Item type | Pass threshold |
|---|---|
| Multiple choice (Q2–Q12) | The single correct letter. "I don't know", a blank, or more than one letter counts as a **fail**. |
| Output check (Q1) | Both printed lines match the accepted values in the answer key. |
| Practical task (T1–T3) | **Every** verification check matches. If you couldn't attempt the task, it's a **fail**. If you took more than 2× the target time, it's a **fail**. |

**Any item you didn't answer counts as a fail.** That includes every item after Step 0 if you stopped there. So a learner who stops at Step 0 does every Phase 0 module.

Grade with the answer key **after** you've answered every item. Don't change an answer once you've seen the key.

### 1.2 Routing table

Every item routes to exactly one module.

| Item | Checks | Fail this → module |
|---|---|---|
| Step 0 | You can open a Linux/macOS terminal | **P0-M01** (stop the diagnostic here) |
| Q1 | Shell and OS are what the course expects | P0-M01 |
| Q2 | Reading `rwx` permissions | P0-M02 |
| Q3 | `>` overwrites a file | P0-M02 |
| T1 | `chmod` with least privilege | P0-M02 |
| Q4 | CIDR block size | P0-M03 |
| Q5 | DNS failure vs other network failures | P0-M03 |
| Q6 | add → commit → push | P0-M04 |
| Q7 | Leaked secrets live on in Git history | P0-M04 |
| T2 | Branch, merge, `.gitignore`, SSH push | P0-M04 |
| Q8 | Reading a Python list comprehension | P0-M05 |
| Q9 | Why virtual environments exist | P0-M05 |
| Q10 | Why images are pinned | P0-M06 |
| Q11 | Root user handling | P0-M07 |
| T3, no AWS account | — | **P0-M07** |
| T3, any other failure | SSO identity, root MFA, no root keys, budget alert | P0-M08 |
| Q12 | A budget alerts; it doesn't stop spending | P0-M08 |

### 1.3 The starting-module rule

> **Your starting module = the lowest-numbered module with at least one failed item.**
> **If no item failed, your starting module is P0-M09 (the Phase 0 capstone).**

This always gives you **exactly one** module:

- Every item maps to exactly one module (table 1.2).
- Module numbers are distinct whole numbers, so a set of failed modules always has exactly one lowest member.
- The "no fails" case has its own fixed answer (P0-M09).
- Step 0 is P0-M01, the lowest possible number, so stopping there early can't change the result.

**Worked example.** Sam fails Q5 (P0-M03), Q7 (P0-M04) and T3 because Sam has no AWS account (P0-M07). The failed set is {03, 04, 07}, so the lowest is **03**. Sam starts at **P0-M03**.

### 1.4 Your path after the starting module

You go through Phase 0 **in number order**, starting at your starting module.

| Module | What you do |
|---|---|
| Lower than your starting module | **Skip.** You passed every item for it. |
| Your starting module | **Do the whole module.** You can't skip your starting module. |
| Higher, with at least one failed item | **Do the whole module.** |
| Higher, with all items passed | **Skip it.** If any module you do refers back to it, read just that section. |
| P0-M09 capstone | **Never skipped.** It leads to the exit gate. |

Sam's path: **M03 → M04 → M07 → M08 → M09**. Sam skips M05 and M06 (passed) and does M08 because M08 builds on M07. See 1.5.

### 1.5 Dependency override

Some modules can't be done without one before them. If you do one of these, you must also do its dependant, even if you passed the dependant's diagnostic items:

| If you do… | …you must also do | Why |
|---|---|---|
| P0-M07 | P0-M08 | A new account is unsafe until root MFA, Identity Center and a budget are set up. A passing Q12 doesn't secure an account you've only just created. |

This changes your **path**, never your **starting module**.

### 1.6 Already have an AWS account that failed T3?

If you own an AWS account that failed T3 check 1 (root MFA off, or root access keys present), or check 3 (no budget), your starting module **doesn't change**. Before you begin it, though, spend 10 minutes on these two steps from the official docs:

- Turn on MFA for the root user: https://docs.aws.amazon.com/IAM/latest/UserGuide/enable-mfa-for-root.html
- Create a monthly cost budget with an email alert: https://docs.aws.amazon.com/cost-management/latest/userguide/budgets-create.html

A forgotten account with no MFA and no alert is the most common way beginners get a surprise bill. You'll set it up properly in P0-M08.

### 1.7 Changing your mind

- **Finished your path faster than expected?** Go straight on. Never re-take the diagnostic to skip ahead.
- **Want to skip a module the diagnostic told you to do?** Take that module's **Self-check** cold. If you pass every item, mark it skipped. If you miss one, do the module. *(This needs the module to exist, with its self-check answers in `/solutions`.)*
- **Skipped a module and now feel lost?** Do it. Skipping is a convenience, not a promise you understand it.

---

## Part 2: The Phase 0 exit gate

Phase 1 unlocks only when **all three** parts below pass: **A** path complete, **B** teardown verified, **C** written explanations.

### Gate A: Path complete

Every module on your path (1.4 + 1.5) is marked complete, and you passed its Self-check. P0-M09 is complete.

### Gate B: Capstone teardown verified

The capstone creates a small amount of AWS and local resources and then tears them down. Gate B proves the teardown happened.

**Contract the capstone module must follow** (so these checks work):

- Every AWS resource it creates carries the tags `course=aws-devops-platform` and `phase=0`, in **`us-east-1`**.
- Every local Docker container or image it creates carries the label `course-phase=0`.
- It lists **one direct "is it gone?" command per resource type it creates**, for example `aws s3api head-bucket` returning a 404.

**Evidence.** Run every command below **after** your teardown, on the same day. Paste the commands *and* their output into `phase-0-exit-evidence.md` in your own `devops-sandbox` repository.

```bash
export AWS_PROFILE=<your-profile>
export AWS_REGION=us-east-1
aws sso login

# G1 — identity is still SSO, not root or IAM-user keys
aws sts get-caller-identity --query Arn --output text
# expect: arn:aws:sts::<account-id>:assumed-role/AWSReservedSSO_<PermissionSetName>_<suffix>/<you>

# G2 — root user still has MFA and no access keys
aws iam get-account-summary \
  --query 'SummaryMap.[AccountMFAEnabled,AccountAccessKeysPresent]' --output text
# expect: 1	0

# G3 — budget with an alert still exists
ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
aws budgets describe-budgets --account-id "$ACCOUNT_ID" \
  --query 'Budgets[].BudgetName' --output text
# expect: at least one name

# G4 — no tagged capstone resources left in us-east-1
aws resourcegroupstaggingapi get-resources \
  --tag-filters Key=course,Values=aws-devops-platform Key=phase,Values=0 \
  --query 'ResourceTagMappingList[].ResourceARN' --output json
# expect: []

# G5 — every direct "is it gone?" command from the capstone module
# expect: each one reports not found (paste them all)

# G6 — no capstone containers or images left locally
docker ps -a --filter "label=course-phase=0" --format '{{.Names}}'
docker images --filter "label=course-phase=0" --format '{{.Repository}}:{{.Tag}}'
# expect: no output from either command
```

**If G4 still lists an ARN you've already deleted:** wait 15 minutes and run it again. If the ARN is still there, run that resource's G5 direct check. **G5 decides.** A resource that G5 says is gone counts as gone. Write down that you saw the delay.

**Gate B pass threshold:** G1–G6 all match their `expect` lines.

**Routing on failure:**

| Fails | Do this, then re-run all of Gate B |
|---|---|
| G1 or G2 | Redo the P0-M08 labs for SSO login / root MFA. |
| G3 | Redo the P0-M08 budget lab. |
| G4, G5 or G6 | Redo the P0-M09 teardown section, then re-run all of Gate B. |

### Gate C: Written explanations

Write **6 short explanations**, 80–200 words each, **in your own words**, in the same `phase-0-exit-evidence.md`. Write all six before you open the rubric in `/solutions`. Notes and course text are allowed while you write. Copied text and AI-written text are not.

| # | Prompt | Maps to |
|---|---|---|
| E1 | Why don't you use the AWS root user for daily work? What do you sign in with instead, and how does the CLI get credentials without you storing a key? | P0-M07, P0-M08 |
| E2 | What does your AWS Budget do, and what does it **not** do? What will you do in the first 10 minutes after a budget alert email arrives? | P0-M08 |
| E3 | Walk through your capstone teardown. What did you delete, in what order, and how did you **prove** each thing was gone? | P0-M09 |
| E4 | A colleague's `curl` fails with `(6) Could not resolve host`, and another fails with `(7) Failed to connect`. Explain the difference and the first thing you'd check for each. | P0-M03 |
| E5 | You pushed a real secret to GitHub. List what you do, in order, and explain why deleting the file isn't enough. | P0-M04 |
| E6 | Why does this course pin every version (image tags, packages)? Give one concrete thing that breaks without pinning. | P0-M05, P0-M06 |

**Scoring:** each explanation scores **0, 1 or 2** against the rubric (in `/solutions`, not linked here).

- Self-grading is allowed. For every rubric point you award yourself, quote the sentence that earns it.
- If you have a mentor or cohort, they grade instead.

**Gate C pass threshold, all three must hold:**

1. Total of **at least 10 out of 12**.
2. **E1, E2 and E3 each score 2.** These three are account safety and cost. A partial answer isn't good enough.
3. No explanation scores 0.

**Routing on failure:** for each explanation below the threshold, re-read the Concepts section of the module(s) in its "Maps to" column. Rewrite **only those explanations** after at least 24 hours. Gate A and Gate B passes still count; you don't redo them.

### Gate result

| A | B | C | Result |
|---|---|---|---|
| ✅ | ✅ | ✅ | **Phase 0 passed. Phase 1 unlocked.** Record the date in your evidence file. |
| any ❌ | | | Follow the routing for the failing part only, then re-check that part. |

---

## Last verified

- **Drafted:** 2026-11-17.
- **Run by a human end to end:** ❌ not yet.
- **AWS CLI commands:**
  - The G1–G3 command names, flags and output fields were checked against `aws <cmd> help` in aws-cli 2.33.14 on 2026-11-17.
  - `resourcegroupstaggingapi get-resources --tag-filters` comes from the CLI reference and hasn't been run yet.
  - The doc links in 1.6 haven't been checked by the `qa` agent yet.
- **Depends on:** the P0-M09 capstone, which must follow the tag/label contract in Gate B. It hasn't been written yet.
