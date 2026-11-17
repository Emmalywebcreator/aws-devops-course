# Phase 0 · Entry diagnostic

## Goal

Find out whether you can skip Phase 0 entirely, and if not, the **one** Phase 0 module you should start at.

## Why this exists

The course builds one app across four phases, and every later module assumes the earlier ones. Start too late and you get stuck on something nobody explained; start too early and you lose weeks. This diagnostic checks every Phase 0 module (0.0–0.5) with one to four items and sends you to the first gap it finds.

It is **not** a grade. Failing items is normal and useful: it tells you where to start.

## Before you begin

| | |
|---|---|
| **Time** | 45–75 minutes. Total beginners finish faster, because "I don't know" is a fine answer. |
| **Cost** | USD 0. Nothing here creates an AWS resource. Task 1 makes only read-only AWS calls (STS `GetCallerIdentity`, IAM `GetAccountSummary`, Budgets `Describe*`, CloudWatch `DescribeAlarms`). *Pricing assumptions:* IAM and STS calls have no charge; budgets without actions are free ([Budgets pricing](https://aws.amazon.com/aws-cost-management/aws-budgets/pricing/)); CloudWatch `DescribeAlarms` — TODO(verify) against https://aws.amazon.com/cloudwatch/pricing/ (a handful of calls in any case). The private GitHub repo in Task 3 is free on a personal account. **If you skip teardown: USD 0/day.** |
| **Region** | Every AWS command uses **`us-east-1`**. Set it with `export AWS_REGION=us-east-1`. |
| **What you need** | A computer. A terminal if you have one (WSL 2 Ubuntu on Windows, Terminal on macOS, or any Linux terminal). A GitHub account and an AWS account if you have them. Not having them is fine: the routing rules cover it. |
| **Rules** | No web search and no AI assistants. Built-in help (`man`, `--help`, `aws <cmd> help`) is allowed. Answer every question before you open the answer key, then grade yourself honestly. A guess you got right still sends you past something you don't know. |
| **Time limit on tasks** | Each task lists a target time. If you need **more than twice** that time, mark the task as failed. |

## How routing works (short version)

1. **Score** = how many of the 12 questions you got right. Each task is **pass** or **fail**.
2. **Score ≥ 10 and all 3 tasks pass → skip Phase 0. Start Phase 1.**
3. **Otherwise:** your starting module is the **lowest-numbered module that has at least one failed item** (question *or* task).

The items are listed in module order, so rule 3 means: **your starting module is the module of the first `fail` you find reading the answer sheet from the top.** Full rules, including which later modules you may skip, are in [gate-rules.md](gate-rules.md).

### Phase 0 modules

| ID | Module | Path |
|---|---|---|
| 0.0 | Account safety & billing guardrails | `phases/phase-0/00-account-safety/` |
| 0.1 | Linux & the shell | `phases/phase-0/01-linux-shell/` (planned) |
| 0.2 | Networking fundamentals | `phases/phase-0/02-networking/` (planned) |
| 0.3 | Git & GitHub workflows | `phases/phase-0/03-git-github/` (planned) |
| 0.4 | Python for ops | `phases/phase-0/04-python-ops/` (planned) |
| 0.5 | AWS core mental model + CLI | `phases/phase-0/05-aws-core-cli/` (planned) |
| 0.6 | Capstone mini-project + Phase 0 gate | `phases/phase-0/06-capstone/` (planned) |

0.6 isn't tested here: it *is* the exit gate.

---

## Part A: Questions (12)

For multiple-choice questions, write down **one letter**. "I don't know" always counts as wrong, but it's still better than guessing.

### Q1 → 0.0 · The root user

You've just created a brand-new AWS account. What is the right way to treat the **root user** (the email address you signed up with)?

- A) Use it for daily work, because it has every permission
- B) Turn on MFA for it, don't create access keys for it, and use it only for the few tasks that require root
- C) Share the login with teammates so everyone has access
- D) Create access keys for it so the AWS CLI works
- E) I don't know

### Q2 → 0.0 · What a budget does

You created an AWS Budget of USD 5/month with an email alert at 100%. You forget a server running, and the month's charges reach USD 5. What happens?

- A) AWS stops the server automatically
- B) You get an email. The server keeps running and keeps billing until you stop or delete it.
- C) AWS deletes the resources in your account
- D) The budget blocks any charges above USD 5
- E) I don't know

### Q3 → 0.1 · Your terminal

If you can open a terminal (on Windows: the **Ubuntu** app under WSL 2, not PowerShell or Command Prompt), run these two commands and copy what they print onto your answer sheet:

```bash
echo "$SHELL"
uname -s
```

If you can't open a terminal, mark Q3 wrong (and Tasks 2 and 3 as failed).

### Q4 → 0.1 · Reading permissions

`ls -l` shows:

```
-rw-r----- 1 ana devs 512 Nov 17 09:00 notes.txt
```

User `bob` is **not** `ana`, but he **is** in the group `devs`. What can `bob` do with `notes.txt`?

- A) Read and write it
- B) Read it only
- C) Nothing at all
- D) Read, write and execute it
- E) I don't know

### Q5 → 0.1 · Redirection

`notes.txt` contains one line: `one`. You run `echo two > notes.txt`. What does `notes.txt` contain now?

- A) `one` then `two` on two lines
- B) `two` only
- C) `one` only, because the command fails
- D) It is empty
- E) I don't know

### Q6 → 0.2 · CIDR blocks

How many IP addresses are in the block `10.0.1.0/24`?

- A) 24
- B) 254
- C) 256
- D) 65,536
- E) I don't know

### Q7 → 0.2 · Reading a network error

You run `curl https://api.exmaple.com/health` and get:

```
curl: (6) Could not resolve host: api.exmaple.com
```

What is the most likely cause?

- A) The server is running but returned an error
- B) A firewall is blocking port 443
- C) The name couldn't be turned into an IP address. Check the spelling and DNS.
- D) The TLS certificate has expired
- E) I don't know

### Q8 → 0.3 · Git basics

You edited `app.py` and want the change on GitHub. Which order is correct?

- A) `git push` → `git commit` → `git add`
- B) `git add` → `git commit` → `git push`
- C) `git commit` → `git add` → `git push`
- D) `git clone` → `git push`
- E) I don't know

### Q9 → 0.3 · A leaked secret

You committed a file containing an AWS access key and pushed it to a **public** GitHub repo. Ten minutes later you deleted the file in a new commit and pushed again. Which statement is true?

- A) You're safe: the file is deleted.
- B) You're not safe: the key is still in the Git history and may already have been copied. Deactivate the key first, then clean the history.
- C) You're safe if you now make the repo private.
- D) You're not safe, but rewriting the Git history fully fixes it. The key itself can stay active.
- E) I don't know

### Q10 → 0.4 · Reading Python

What does this print?

```python
servers = ["web-1", "web-2", "db-1"]
print([s for s in servers if s.startswith("web")])
```

- A) `['web-1', 'web-2']`
- B) `['db-1']`
- C) `2`
- D) It raises an error
- E) I don't know

### Q11 → 0.4 · Virtual environments

Why do you create a virtual environment (`python3 -m venv .venv`) for each project?

- A) It makes Python run faster
- B) It keeps each project's installed packages and their versions separate from the system Python and from other projects
- C) Python can't run scripts without one
- D) It encrypts your source code
- E) I don't know

### Q12 → 0.5 · How AWS decides "allowed or denied"

An IAM user has two policies attached. Policy 1 **allows** `s3:*` on all resources. Policy 2 **denies** `s3:DeleteBucket` on all resources. The user runs `aws s3 rb s3://their-bucket`. What happens?

- A) The bucket is deleted: `s3:*` includes `DeleteBucket`
- B) Access denied: an explicit deny overrides any allow
- C) It depends on which policy was attached first
- D) The bucket is deleted, because the user owns it
- E) I don't know

---

## Part B: Practical tasks (3)

You get the setup commands and the checks, but **not** the commands that solve the task. Working those out is the test.

### Task 1 → 0.0 · Prove your AWS account is locked down *(target: 15 minutes)*

**Can't attempt it** (no AWS account, or no AWS CLI): mark it as failed.

**Task.** Show that:

1. The CLI is signed in as an **IAM user** (not root), using temporary credentials from `aws login`.
2. The root user has MFA on and **no** access keys.
3. At least one budget exists with at least one alert, and a billing alarm exists in `us-east-1`.

All of these are read-only and create nothing.

**Verification.** Replace `<your-profile>` with your CLI profile name. Region: `us-east-1`.

```bash
export AWS_PROFILE=<your-profile>
export AWS_REGION=us-east-1
aws login --profile "$AWS_PROFILE"

# 1. Who am I?
aws sts get-caller-identity --query Arn --output text
# expect: arn:aws:iam::<12-digit-account-id>:user/<your-admin-user>

# 2. Root user: MFA on (1) and no access keys (0)
aws iam get-account-summary \
  --query 'SummaryMap.[AccountMFAEnabled,AccountAccessKeysPresent]' --output text
# expect: 1	0

# 3a. Budgets and their alerts
ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
aws budgets describe-budgets --account-id "$ACCOUNT_ID" \
  --query 'Budgets[].[BudgetName,BudgetLimit.Amount,BudgetLimit.Unit]' --output text
# expect: at least one line, e.g.  p0-monthly-5usd  5.0  USD
aws budgets describe-notifications-for-budget --account-id "$ACCOUNT_ID" \
  --budget-name "<a-budget-name-from-the-line-above>" \
  --query 'Notifications[].[NotificationType,Threshold]' --output text
# expect: at least one line, e.g.  ACTUAL  50.0

# 3b. A billing alarm in us-east-1
aws cloudwatch describe-alarms --region us-east-1 \
  --query "MetricAlarms[?Namespace=='AWS/Billing'].[AlarmName,StateValue]" --output text
# expect: at least one line (state OK, or INSUFFICIENT_DATA on a brand-new account)
```

**Pass threshold:** all checks match.

- **Check 1 fails** if the ARN ends in `:root`.
- **Check 2:** if you get `AccessDenied`, sign in to the console as root and confirm on the root user's **Security credentials** page that MFA is assigned and there are no access keys (UI as of 2026-11-17). Record "checked in console".

**Teardown:** none — read-only. Run `aws logout --profile "$AWS_PROFILE"` if you like.

### Task 2 → 0.1 · Fix a script that won't run *(target: 10 minutes)*

**Can't attempt it** (no terminal): mark it as failed.

**Setup.** Run these in your Linux home directory. On WSL, **don't** use `/mnt/c/...`, because Windows folders don't keep Linux permissions.

```bash
mkdir -p ~/p0-diag-t2 && cd ~/p0-diag-t2
printf '#!/usr/bin/env bash\necho "diagnostic ok: $(whoami)"\n' > hello.sh
echo 'not-a-real-password' > secret.txt
chmod 644 hello.sh secret.txt
./hello.sh
```

The last line fails with `bash: ./hello.sh: Permission denied`. That is expected.

**Task.** Without `sudo`, and without running it as `bash hello.sh`:

1. Make `./hello.sh` run.
2. Make `secret.txt` readable and writable by **you only**, with no access for anyone else.

Use the smallest permission change that works.

**Expected result:** `./hello.sh` prints `diagnostic ok: <your-username>`.

**Verification:**

```bash
cd ~/p0-diag-t2
./hello.sh
test -x hello.sh && echo "CHECK1 pass" || echo "CHECK1 FAIL"
# Linux / WSL:
[ "$(stat -c %a secret.txt)" = "600" ] && echo "CHECK2 pass" || echo "CHECK2 FAIL"
# macOS (use instead of the line above):
# [ "$(stat -f %Lp secret.txt)" = "600" ] && echo "CHECK2 pass" || echo "CHECK2 FAIL"
```

**Pass threshold:** `./hello.sh` prints `diagnostic ok: …`, **and** you see `CHECK1 pass` and `CHECK2 pass`, **and** you didn't use `sudo` or `chmod 777`.

**Teardown:** `rm -rf ~/p0-diag-t2`. Confirm with `ls ~/p0-diag-t2`, which should say `No such file or directory`.

### Task 3 → 0.3 · A clean repo on GitHub *(target: 20 minutes)*

**Can't attempt it** (no terminal, no Git, or no GitHub account): mark it as failed.

**Task.** In a new folder `~/p0-diag-t3`:

1. Create a Git repository whose default branch is `main`.
2. Add a `README.md` and a `.gitignore` that ignores `.env`.
3. Create a `.env` file containing `API_KEY=not-a-real-key`. It must **never** be committed.
4. Make at least **2 commits**. At least one of them must be made on a branch called `feature/notes` and then merged into `main`.
5. On GitHub, create an **empty, private** repo called `p0-diagnostic`. Add it as `origin` using the **SSH** URL (`git@github.com:…`), and push `main`.

**Expected result:** `main` on GitHub matches your local `main`, and `.env` exists locally but isn't in the repo.

**Verification:**

```bash
cd ~/p0-diag-t3
git branch --show-current                      # expect: main
git log --oneline | wc -l                      # expect: 2 or more
git branch --merged main | grep feature/notes  # expect: a line containing feature/notes
git ls-files | grep -cxF '.env'                # expect: 0
git check-ignore .env                          # expect: .env
git status --porcelain                         # expect: no output
git remote get-url origin                      # expect: git@github.com:<you>/p0-diagnostic.git
[ "$(git rev-parse main)" = "$(git ls-remote origin refs/heads/main | cut -f1)" ] \
  && echo "PUSHED pass" || echo "PUSHED FAIL"
ssh -T git@github.com                          # expect: Hi <you>! You've successfully authenticated, but GitHub does not provide shell access.
```

`ssh -T` exits with code 1 even when it works. That's normal. Only the message matters.

**Pass threshold:** every line matches its `expect` comment, and you see `PUSHED pass`.

**Teardown:**

```bash
rm -rf ~/p0-diag-t3
ls ~/p0-diag-t3        # expect: No such file or directory
```

The private GitHub repo is free, so deleting it is optional. With the GitHub CLI: `gh auth refresh -h github.com -s delete_repo`, then `gh repo delete <you>/p0-diagnostic --yes`; confirm with `gh repo view <you>/p0-diagnostic` (it should report it can't find the repository).

---

## Answer sheet (copy this, fill it in, then grade it)

```
                                                    right/wrong   pass/fail
Q1  0.0  ___                                        ____
Q2  0.0  ___                                        ____
T1  0.0  identity ___  MFA/keys ___  budget/alarm ___             ____
Q3  0.1  output: ________________________           ____
Q4  0.1  ___                                        ____
Q5  0.1  ___                                        ____
T2  0.1  CHECK1 ___ CHECK2 ___                                    ____
Q6  0.2  ___                                        ____
Q7  0.2  ___                                        ____
Q8  0.3  ___                                        ____
Q9  0.3  ___                                        ____
T3  0.3  PUSHED ___                                               ____
Q10 0.4  ___                                        ____
Q11 0.4  ___                                        ____
Q12 0.5  ___                                        ____

Score (questions right, out of 12): ____
All three tasks passed?  yes / no

Score ≥ 10 AND all tasks passed  → start Phase 1
Otherwise → first module (from the top) with a wrong question or a failed task: 0.__
```

Then read [gate-rules.md](gate-rules.md) to see which later modules you may skip.

## Last verified

- **Drafted:** 2026-11-17; renumbered to the 0.0–0.6 spec and the spec's skip rule on 2026-11-17.
- **Run by a human end to end:** ❌ not yet. This is required before release (CLAUDE.md Definition of Done).
- **Partly checked by the author on 2026-11-17:** Task 2 setup and checks, and the Task 3 local Git checks, were dry-run on Ubuntu 24.04.1 (WSL 2) with bash 5.2.21 and git 2.43.0; output matched. AWS CLI flags and output fields in Task 1 checked against `aws <cmd> help` (aws-cli 2.33.14). No AWS calls made against a real account.
- **Not yet checked:** macOS `stat -f %Lp` on a real Mac, the `gh repo delete` flow, and the console wording in Task 1.
