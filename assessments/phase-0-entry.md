# Phase 0 · Entry diagnostic

## Goal

Find the **one** Phase 0 module you should start at, so you don't sit through what you already know or skip something you'll need.

## Why this exists

The course builds one app across four phases, and every later module assumes the earlier ones. If you start too late, you get stuck on something nobody explained. If you start too early, you lose weeks. This diagnostic checks each Phase 0 module with one to three items and sends you to the first gap it finds.

It is **not** a grade. Failing items is normal and useful: it tells you where to start.

## Before you begin

| | |
|---|---|
| **Time** | 45–75 minutes. Total beginners finish faster, because "I don't know" is a fine answer and they stop at Step 0. |
| **Cost** | USD 0. Nothing here creates an AWS resource. Task 3 makes only read-only AWS calls: STS `GetCallerIdentity`, IAM `GetAccountSummary` and Budgets `Describe*`. *Pricing assumptions:* IAM and STS calls have no charge, and the diagnostic creates no budget. The `cost` agent has not yet checked the Budgets read-call pricing (https://aws.amazon.com/aws-cost-management/aws-budgets/pricing/). The GitHub private repository in Task 2 is free on a personal account. **If you skip teardown: USD 0/day.** |
| **Region** | Every AWS command uses **`us-east-1`**. Set it with `export AWS_REGION=us-east-1`. |
| **What you need** | A computer. A terminal if you have one (WSL 2 Ubuntu on Windows, Terminal on macOS, or any Linux terminal). A GitHub account and an AWS account if you have them. Not having them is fine: the routing rules cover it. |
| **Rules** | No web search and no AI assistants. Built-in help (`man`, `--help`, `aws <cmd> help`) is allowed. Answer every question before you open the answer key, then grade yourself honestly. A guess you got right still sends you past something you don't know. |
| **Time limit on tasks** | Each task lists a target time. If you need **more than twice** that time, mark the task as failed. |

## How routing works (short version)

1. Every item below is labelled with the module it checks, for example **→ P0-M02**.
2. Grade every item **pass** or **fail** using the answer key.
3. **Your starting module is the lowest-numbered module that has at least one failed item.**
4. If you pass everything, you start at **P0-M09 (Phase 0 capstone)**.

Ties can't happen: there is only one lowest number. Full rules, including which later modules you may skip, are in [gate-rules.md](gate-rules.md).

### Phase 0 module IDs

These IDs are provisional until decision D1 in `PROGRESS.md` is closed. The module folders don't exist yet.

| ID | Module | Planned path |
|---|---|---|
| P0-M01 | Workstation setup (WSL 2 on Windows, macOS, Linux) | `phases/phase-0/01-workstation-setup/` |
| P0-M02 | Linux command line, permissions and bash | `phases/phase-0/02-linux-cli/` |
| P0-M03 | Networking and troubleshooting (IP, CIDR, DNS, ports) | `phases/phase-0/03-networking/` |
| P0-M04 | Git and GitHub | `phases/phase-0/04-git-github/` |
| P0-M05 | Python for DevOps | `phases/phase-0/05-python/` |
| P0-M06 | Docker install and first container | `phases/phase-0/06-docker/` |
| P0-M07 | AWS account creation | `phases/phase-0/07-aws-account/` |
| P0-M08 | AWS account safety: root MFA, IAM Identity Center, CLI SSO login, budgets | `phases/phase-0/08-aws-account-safety/` |
| P0-M09 | Phase 0 capstone (leads to the exit gate) | `phases/phase-0/09-capstone/` |

---

## Step 0: Can you open a terminal? → P0-M01

Open a terminal. On Windows, that means the **Ubuntu** app (WSL 2), not Command Prompt or PowerShell.

- **If you can't open one, or don't know what that means:** stop here. Your starting module is **P0-M01**. You're done with the diagnostic.
- **If you can:** go on to Q1.

---

## Part A: Questions (12)

For multiple-choice questions, write down **one letter**. "I don't know" always counts as a fail, but it's still better than guessing: a lucky guess sends you past a gap.

### Q1 → P0-M01 · Your terminal

Run these two commands exactly and copy what they print onto your answer sheet:

```bash
echo "$SHELL"
uname -s
```

*Pass threshold:* see the answer key. Both lines must match what the course expects.

### Q2 → P0-M02 · Reading permissions

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

*Pass threshold:* the correct letter.

### Q3 → P0-M02 · Redirection

`notes.txt` contains one line: `one`. You run:

```bash
echo two > notes.txt
```

What does `notes.txt` contain now?

- A) `one` then `two` on two lines
- B) `two` only
- C) `one` only, because the command fails
- D) It is empty
- E) I don't know

*Pass threshold:* the correct letter.

### Q4 → P0-M03 · CIDR blocks

How many IP addresses are in the block `10.0.1.0/24`?

- A) 24
- B) 254
- C) 256
- D) 65,536
- E) I don't know

*Pass threshold:* the correct letter.

### Q5 → P0-M03 · Reading a network error

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

*Pass threshold:* the correct letter.

### Q6 → P0-M04 · Git basics

You edited `app.py` and want the change on GitHub. Which order is correct?

- A) `git push` → `git commit` → `git add`
- B) `git add` → `git commit` → `git push`
- C) `git commit` → `git add` → `git push`
- D) `git clone` → `git push`
- E) I don't know

*Pass threshold:* the correct letter.

### Q7 → P0-M04 · A leaked secret

You committed a file containing an AWS access key and pushed it to a **public** GitHub repo. Ten minutes later you deleted the file in a new commit and pushed again. Which statement is true?

- A) You're safe: the file is deleted.
- B) You're not safe: the key is still in the Git history and may already have been copied. Deactivate the key first, then clean the history.
- C) You're safe if you now make the repo private.
- D) You're not safe, but rewriting the Git history fully fixes it. The key itself can stay active.
- E) I don't know

*Pass threshold:* the correct letter.

### Q8 → P0-M05 · Reading Python

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

*Pass threshold:* the correct letter.

### Q9 → P0-M05 · Virtual environments

Why do you create a virtual environment (`python3 -m venv .venv`) for each project?

- A) It makes Python run faster
- B) It keeps each project's installed packages and their versions separate from the system Python and from other projects
- C) Python can't run scripts without one
- D) It encrypts your source code
- E) I don't know

*Pass threshold:* the correct letter.

### Q10 → P0-M06 · Image tags

This course writes `FROM python:3.12.8-slim` and never `FROM python:latest`. Why?

- A) `latest` images download more slowly
- B) A pinned tag gives the same image every build. `latest` can quietly point at a new version and change or break your build.
- C) Docker Hub doesn't allow `latest`
- D) `latest` images cost money
- E) I don't know

*Pass threshold:* the correct letter.

### Q11 → P0-M07 · The root user

You've just created a brand-new AWS account. What is the right way to treat the **root user** (the email address you signed up with)?

- A) Use it for daily work, because it has every permission
- B) Turn on MFA for it, don't create access keys for it, and use it only for the few tasks that require root
- C) Share the login with teammates so everyone has access
- D) Create access keys for it so the AWS CLI works
- E) I don't know

*Pass threshold:* the correct letter.

### Q12 → P0-M08 · What a budget does

You created an AWS Budget of USD 5/month with an email alert at 100%. You forget a server running, and the month's charges reach USD 5. What happens?

- A) AWS stops the server automatically
- B) You get an email. The server keeps running and keeps billing until you stop or delete it.
- C) AWS deletes the resources in your account
- D) The budget blocks any charges above USD 5
- E) I don't know

*Pass threshold:* the correct letter.

---

## Part B: Practical tasks (3)

You get the setup commands and the checks, but **not** the commands that solve the task. Working those out is the test.

### Task 1 → P0-M02 · Fix a script that won't run *(target: 10 minutes)*

**Can't attempt it** (no terminal): mark it as a fail.

**Setup.** Run these in your Linux home directory. On WSL, **don't** use `/mnt/c/...`, because Windows folders don't keep Linux permissions.

```bash
mkdir -p ~/p0-diag-t1 && cd ~/p0-diag-t1
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

**Verification** (run all of them):

```bash
cd ~/p0-diag-t1
./hello.sh
test -x hello.sh && echo "CHECK1 pass" || echo "CHECK1 FAIL"
# Linux / WSL:
[ "$(stat -c %a secret.txt)" = "600" ] && echo "CHECK2 pass" || echo "CHECK2 FAIL"
# macOS (use instead of the line above):
# [ "$(stat -f %Lp secret.txt)" = "600" ] && echo "CHECK2 pass" || echo "CHECK2 FAIL"
```

**Pass threshold:** `./hello.sh` prints `diagnostic ok: …`, **and** you see both `CHECK1 pass` and `CHECK2 pass`, **and** you didn't use `sudo` or `chmod 777`.

**Teardown:** `rm -rf ~/p0-diag-t1`. Confirm with `ls ~/p0-diag-t1`, which should say `No such file or directory`.

### Task 2 → P0-M04 · A clean repo on GitHub *(target: 20 minutes)*

**Can't attempt it** (no terminal, no Git, or no GitHub account): mark it as a fail.

**Task.** In a new folder `~/p0-diag-t2`:

1. Create a Git repository whose default branch is `main`.
2. Add a `README.md` and a `.gitignore` that ignores `.env`.
3. Create a `.env` file containing `API_KEY=not-a-real-key`. It must **never** be committed.
4. Make at least **2 commits**. At least one of them must be made on a branch called `feature/notes` and then merged into `main`.
5. On GitHub, create an **empty, private** repo called `p0-diagnostic`. Add it as `origin` using the **SSH** URL (`git@github.com:…`), and push `main`.

**Expected result:** `main` on GitHub matches your local `main`, and `.env` exists locally but isn't in the repo.

**Verification:**

```bash
cd ~/p0-diag-t2
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
rm -rf ~/p0-diag-t2
ls ~/p0-diag-t2        # expect: No such file or directory
```

The private GitHub repo is free, so deleting it is optional. To delete it with the GitHub CLI, if you have it installed, run `gh auth refresh -h github.com -s delete_repo` and then `gh repo delete <you>/p0-diagnostic --yes`. Confirm with `gh repo view <you>/p0-diagnostic`, which should report that it can't find the repository.

### Task 3 → P0-M08 · Prove your AWS account is locked down *(target: 15 minutes)*

**Can't attempt it:**

- **You have no AWS account:** mark it as a fail and route it to **P0-M07** instead of P0-M08.
- **You have an account but no AWS CLI, or you've never run `aws configure sso`:** mark it as a fail and route it to **P0-M08**.

**Task.** Show three things:

1. You use the AWS CLI through **IAM Identity Center (SSO)**, not through root or IAM-user access keys.
2. The root user has MFA turned on and has **no** access keys.
3. At least one budget exists with at least one alert.

All of these are read-only and create nothing.

**Verification.** Replace `<your-profile>` with the profile name you chose in `aws configure sso`. Region: `us-east-1`.

```bash
export AWS_PROFILE=<your-profile>
export AWS_REGION=us-east-1
aws sso login

# 1. Who am I?
aws sts get-caller-identity --query Arn --output text
# expect: arn:aws:sts::<12-digit-account-id>:assumed-role/AWSReservedSSO_<PermissionSetName>_<suffix>/<your-username>

# 2. Root user: MFA on (1) and access keys present (0)
aws iam get-account-summary \
  --query 'SummaryMap.[AccountMFAEnabled,AccountAccessKeysPresent]' --output text
# expect: 1	0

# 3. Budgets and their alerts
ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
aws budgets describe-budgets --account-id "$ACCOUNT_ID" \
  --query 'Budgets[].[BudgetName,BudgetLimit.Amount,BudgetLimit.Unit]' --output text
# expect: at least one line, e.g.  monthly-guard  10.0  USD
aws budgets describe-notifications-for-budget --account-id "$ACCOUNT_ID" \
  --budget-name "<a-budget-name-from-the-line-above>" \
  --query 'Notifications[].[NotificationType,Threshold]' --output text
# expect: at least one line, e.g.  ACTUAL  80.0
```

**Pass threshold:** all three checks match.

- **Check 1 fails** if the ARN contains `:root` or `:user/`. That means long-lived access keys, which this course doesn't use.
- **Check 2:** if you get `AccessDenied` (your permission set may not allow `iam:GetAccountSummary`), you may sign in to the console as root instead and confirm that MFA is assigned and there are no access keys on the root user's **Security credentials** page. Record "checked in console" on your answer sheet. *(Console page name not yet verified. UI as of 2026-11-17.)*

**Teardown:** none. These checks only read. Run `unset AWS_PROFILE AWS_REGION` if you want a clean shell.

---

## Answer sheet (copy this, fill it in, then grade it)

```
Step 0  terminal opened?   yes / no   (no → stop, start at P0-M01)
Q1  P0-M01  output: ____________________   pass / fail
Q2  P0-M02  ___   pass / fail
Q3  P0-M02  ___   pass / fail
T1  P0-M02  CHECK1 ___ CHECK2 ___         pass / fail
Q4  P0-M03  ___   pass / fail
Q5  P0-M03  ___   pass / fail
Q6  P0-M04  ___   pass / fail
Q7  P0-M04  ___   pass / fail
T2  P0-M04  PUSHED ___                    pass / fail
Q8  P0-M05  ___   pass / fail
Q9  P0-M05  ___   pass / fail
Q10 P0-M06  ___   pass / fail
Q11 P0-M07  ___   pass / fail
T3  P0-M08 (or P0-M07 if no account)      pass / fail
Q12 P0-M08  ___   pass / fail

Lowest module with a fail: P0-M__   ← this is your starting module
(no fails → P0-M09)
```

The items are listed in module order, so **your starting module is the module of the first `fail` you find reading from the top.**

Then read [gate-rules.md](gate-rules.md) to see which later modules you may skip.

## Last verified

- **Drafted:** 2026-11-17.
- **Run by a human end to end:** ❌ not yet. This is required before release (CLAUDE.md Definition of Done).
- **Partly checked by the author on 2026-11-17:**
  - Task 1 setup and checks, and the Task 2 local Git checks, were dry-run on Ubuntu 24.04.1 (WSL 2) with bash 5.2.21 and git 2.43.0. The output matched the expected lines above.
  - The AWS CLI flags and output field names (`--account-id`, `--budget-name`, `SummaryMap`, `AccountMFAEnabled`, `AccountAccessKeysPresent`, `BudgetLimit`) were checked against `aws <cmd> help` in aws-cli 2.33.14.
  - No AWS calls were made against a real account.
- **Not yet checked:** macOS `stat -f %Lp` on a real Mac, the `gh repo delete` flow, and the console wording in Task 3.
