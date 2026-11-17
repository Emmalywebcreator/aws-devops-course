# Answer key · Phase 0 entry diagnostic

> Instructor/self-grading key for `assessments/phase-0-entry.md`. **Not linked from course navigation.**
> Grade only after every item is answered. Routing rules: `assessments/gate-rules.md`.

## Quick key

| Item | Answer / pass condition | Fail → |
|---|---|---|
| Step 0 | Terminal opened | P0-M01 (stop) |
| Q1 | Line 1 ends in `/bash` or `/zsh`; line 2 is exactly `Linux` or `Darwin` | P0-M01 |
| Q2 | **B** | P0-M02 |
| Q3 | **B** | P0-M02 |
| T1 | `diagnostic ok: …`, `CHECK1 pass`, `CHECK2 pass`, no `sudo`/`777` | P0-M02 |
| Q4 | **C** | P0-M03 |
| Q5 | **C** | P0-M03 |
| Q6 | **B** | P0-M04 |
| Q7 | **B** | P0-M04 |
| T2 | All `expect` lines match + `PUSHED pass` | P0-M04 |
| Q8 | **A** | P0-M05 |
| Q9 | **B** | P0-M05 |
| Q10 | **B** | P0-M06 |
| Q11 | **B** | P0-M07 |
| T3 | ARN is `assumed-role/AWSReservedSSO_…`; `1	0`; ≥1 budget with ≥1 notification | P0-M08 (no account → P0-M07) |
| Q12 | **B** | P0-M08 |

---

## Explanations

### Q1 — terminal (P0-M01)

Accepted: `/bin/bash`, `/usr/bin/bash`, `/bin/zsh`, `/usr/bin/zsh` (any path ending in `bash` or `zsh`) **and** `Linux` (Linux, WSL 2) or `Darwin` (macOS).

Fails, with what it means:
- `$SHELL` printed literally, or an error → PowerShell or cmd.exe, not a Linux shell.
- `MINGW64_NT-…` / `MSYS_NT-…` → Git Bash. Works for some things, but the course standard on Windows is WSL 2 Ubuntu, and later labs (Docker, file permissions) behave differently in Git Bash.
- `CYGWIN_NT-…` → Cygwin; same reason.

### Q2 — **B** (P0-M02)

`-rw-r-----` splits into owner `rw-`, group `r--`, others `---`. `bob` is not the owner but is in group `devs`, so the **group** triplet applies: read only.
A confuses group with owner; C applies the "others" triplet; D invents an `x` that isn't there.

### Q3 — **B** (P0-M02)

`>` truncates the file then writes; `>>` appends. A is what `>>` would do. This matters because `>` on a config file silently destroys it.

### T1 — reference solution (P0-M02)

```bash
cd ~/p0-diag-t1
chmod u+x hello.sh      # add execute for the owner only (→ 744)
chmod 600 secret.txt    # owner read+write, nobody else (or: chmod go-r secret.txt)
./hello.sh              # diagnostic ok: <you>
```

Also accept for `hello.sh`: `chmod +x` (→ 755) or `chmod 755`/`744`/`700`. `CHECK1` only requires owner-execute.
**Fail regardless of checks:** `chmod 777` (world-writable — anyone could change what the script does) or any use of `sudo` (not needed for files you own; reaching for it is the habit being tested).
Common miss: running it from `/mnt/c/...` on WSL, where `chmod` may appear to do nothing. That's a P0-M02 topic, so the fail routing is correct.

Verified output (Ubuntu 24.04.1 / WSL 2, bash 5.2.21, 2026-11-17):

```
bash: ./hello.sh: Permission denied        # before
diagnostic ok: <you>                        # after
-rwxr--r-- 744 hello.sh
-rw------- 600 secret.txt
```

### Q4 — **C** (P0-M03)

`/24` fixes the first 24 of 32 bits, leaving 8 bits: 2⁸ = **256** addresses (`10.0.1.0`–`10.0.1.255`).
B (254) is the classic "usable hosts on a traditional LAN" answer — wrong for the question asked ("how many addresses are in the block"). D is a `/16`.
Source: RFC 4632 §3.1 — https://www.rfc-editor.org/rfc/rfc4632

### Q5 — **C** (P0-M03)

curl exit code 6 is `CURLE_COULDNT_RESOLVE_HOST`: name resolution failed before any connection was attempted. Here it's a typo (`exmaple`). A firewall (B) would show as exit 7 (failed to connect) or a timeout (28); a cert problem (D) is exit 60; A means you got an HTTP response, so DNS worked.
Source: https://curl.se/libcurl/c/libcurl-errors.html

### Q6 — **B** (P0-M04)

`add` stages, `commit` records locally, `push` sends to the remote.

### Q7 — **B** (P0-M04)

Deleting a file in a new commit leaves it in every earlier commit; anyone who cloned or scraped the repo has it. **Treat the key as compromised: deactivate/rotate it first** (that's what actually stops misuse), then remove it from history.
A and C leave the key live; D gets the order and priority wrong — history rewriting cannot recall copies already taken.
Source: GitHub Docs, "Removing sensitive data from a repository" — https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository

### T2 — reference solution (P0-M04)

```bash
mkdir -p ~/p0-diag-t2 && cd ~/p0-diag-t2
git init -b main
echo "# p0 diagnostic" > README.md
echo ".env" > .gitignore
echo "API_KEY=not-a-real-key" > .env
git add README.md .gitignore            # NOT `git add .env`
git commit -m "Add README and gitignore"
git switch -c feature/notes
echo "notes" > notes.md
git add notes.md && git commit -m "Add notes"
git switch main
git merge feature/notes
# on github.com: New repository → name p0-diagnostic → Private → do NOT add README/.gitignore/license
git remote add origin git@github.com:<you>/p0-diagnostic.git
git push -u origin main
```

(`git init -b` needs Git ≥ 2.28; on older Git: `git init && git checkout -b main`.)

Fail patterns and what they reveal:
- `.env` in `git ls-files` → committed the secret (core P0-M04 lesson).
- Remote URL starts `https://` → SSH not set up (task requires SSH).
- `ssh -T` prints `Permission denied (publickey)` → no key registered on GitHub.
- `git push` rejected `fetch first` → GitHub repo was created with a README; learner must pull/rebase — still a fail if it took them past 2× time.

Local checks verified on git 2.43.0, 2026-11-17 (`git log --oneline | wc -l` → `2`, `git check-ignore -v .env` → `.gitignore:1:.env	.env`, `git status --porcelain` empty). GitHub push and `ssh -T` message not yet human-verified for this key; message text from https://docs.github.com/en/authentication/connecting-to-github-with-ssh/testing-your-ssh-connection

### Q8 — **A** (P0-M05)

List comprehension keeps items whose string starts with `"web"`. C would be `len(...)`.

### Q9 — **B** (P0-M05)

A venv is a separate directory with its own `site-packages`, so `pip install` in one project can't break another or the OS's Python.
Source: https://docs.python.org/3/library/venv.html

### Q10 — **B** (P0-M06)

`latest` is just a tag a publisher can move at any time; two builds a week apart can get different base images. Pinning gives reproducible builds and makes upgrades a deliberate, reviewable change. (Course rule: CLAUDE.md "Pin every version".)
Source: Docker build best practices, "Pin base image versions" — https://docs.docker.com/build/building/best-practices/

### Q11 — **B** (P0-M07)

AWS recommends: MFA on root, no root access keys, root used only for tasks that require it (e.g. changing account settings, closing the account); daily work through other identities.
A/D give the most powerful credential long-lived exposure; C removes accountability and MFA protection.
Sources:
- https://docs.aws.amazon.com/IAM/latest/UserGuide/root-user-best-practices.html
- Tasks that require root: https://docs.aws.amazon.com/IAM/latest/UserGuide/root-user-tasks.html

### T3 — reference solution (P0-M08)

Pass requires all three:

1. ARN shape `arn:aws:sts::<id>:assumed-role/AWSReservedSSO_<PermissionSet>_<suffix>/<user>` — IAM Identity Center provisions roles named `AWSReservedSSO_…` in each assigned account. **Fail** on `arn:aws:iam::<id>:root` (root access keys exist and are being used — fix immediately) or `arn:aws:iam::<id>:user/<name>` (long-lived IAM-user keys; not the course standard).
2. `1	0` — `AccountMFAEnabled` = 1 means root has MFA; `AccountAccessKeysPresent` = 0 means root has no access keys. `AccessDenied` → console alternative accepted (see task text).
3. At least one budget line and at least one notification line.

Learner-side fix path is P0-M08 (and P0-M07 first if they had no account).

Sources:
- `GetAccountSummary` (fields `AccountMFAEnabled`, `AccountAccessKeysPresent`): https://docs.aws.amazon.com/IAM/latest/APIReference/API_GetAccountSummary.html
- CLI SSO setup: https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-sso.html
- Identity Center–provisioned roles (`AWSReservedSSO_` prefix): https://docs.aws.amazon.com/singlesignon/latest/userguide/permissionsetsconcept.html *(qa: confirm this is the page that states the prefix)*
- `describe-budgets`: https://docs.aws.amazon.com/cli/latest/reference/budgets/describe-budgets.html

### Q12 — **B** (P0-M08)

A budget with an email/SNS alert only **notifies**. It does not stop, cap or delete anything; charges keep accruing. (AWS Budgets *actions* can be configured separately to apply IAM/SCP policies or stop specific EC2/RDS instances — that is an opt-in feature the learner did not set up in the question, and it still doesn't cap the bill.)
A/C/D describe a spending cap AWS does not provide via a plain budget.
Sources:
- https://docs.aws.amazon.com/cost-management/latest/userguide/budgets-managing-costs.html
- Budget actions: https://docs.aws.amazon.com/cost-management/latest/userguide/budgets-controls.html

---

## Routing self-test (for course maintainers)

Use these to confirm the rules in `gate-rules.md` give exactly one start:

| Learner profile | Failed items | Start | Path |
|---|---|---|---|
| Total beginner, no terminal | Step 0 (all others unanswered → fail) | P0-M01 | M01→M02→…→M09 |
| Windows user on Git Bash, otherwise strong, no AWS | Q1, Q11, T3 (no account) | P0-M01 | M01→M07→M08→M09 |
| Junior dev, good Linux/Git, never used AWS | Q4, Q11, T3 (no account), Q12 | P0-M03 | M03→M07→M08→M09 |
| Has AWS account, root MFA off, else strong | T3 | P0-M08 | M08→M09 |
| Passes everything | — | P0-M09 | M09 |

*Status: drafted 2026-11-17; citations not yet checked by the `qa` agent.*
