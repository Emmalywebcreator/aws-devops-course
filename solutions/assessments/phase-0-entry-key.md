# Answer key · Phase 0 entry diagnostic

> Instructor/self-grading key for `assessments/phase-0-entry.md`. **Not linked from course navigation.**
> Grade only after every item is answered. Routing rules: `assessments/gate-rules.md`.

## Quick key

| Item | Answer / pass condition | Module |
|---|---|---|
| Q1 | **B** | 0.0 |
| Q2 | **B** | 0.0 |
| T1 | ARN `arn:aws:iam::<id>:user/<name>`; `1	0`; ≥ 1 budget with ≥ 1 notification; ≥ 1 `AWS/Billing` alarm in `us-east-1` | 0.0 |
| Q3 | Line 1 ends in `/bash` or `/zsh`; line 2 is exactly `Linux` or `Darwin` | 0.1 |
| Q4 | **B** | 0.1 |
| Q5 | **B** | 0.1 |
| T2 | `diagnostic ok: …`, `CHECK1 pass`, `CHECK2 pass`, no `sudo` / `777` | 0.1 |
| Q6 | **C** | 0.2 |
| Q7 | **C** | 0.2 |
| Q8 | **B** | 0.3 |
| Q9 | **B** | 0.3 |
| T3 | All `expect` lines match + `PUSHED pass` | 0.3 |
| Q10 | **A** | 0.4 |
| Q11 | **B** | 0.4 |
| Q12 | **B** | 0.5 |

**Placement:** score ≥ 10/12 **and** T1–T3 all pass → Phase 1. Otherwise → lowest module with a wrong question or failed task.

---

## Explanations

### Q1 — **B** (0.0)

AWS recommends MFA on root, no root access keys, and root only for tasks that require it; daily work through other identities. A/D give the most powerful credential long-lived exposure; C removes accountability and MFA protection.
Sources: https://docs.aws.amazon.com/IAM/latest/UserGuide/root-user-best-practices.html · https://docs.aws.amazon.com/IAM/latest/UserGuide/root-user-tasks.html

### Q2 — **B** (0.0)

A budget with an email alert only **notifies**; it doesn't stop, cap or delete anything. (Budget *actions* are a separate opt-in feature and still don't cap the bill.)
Sources: https://docs.aws.amazon.com/cost-management/latest/userguide/budgets-managing-costs.html · https://docs.aws.amazon.com/cost-management/latest/userguide/budgets-controls.html

### T1 — reference (0.0)

Pass requires all of:

1. ARN `arn:aws:iam::<id>:user/<admin-user>` — the IAM user from Module 0.0, signed in with `aws login` (temporary credentials). **Fail** on `arn:aws:iam::<id>:root`.
2. `1	0` — `AccountMFAEnabled` = 1 (root has MFA), `AccountAccessKeysPresent` = 0 (root has no access keys). `AccessDenied` → console alternative accepted.
3. At least one budget and one notification line; at least one alarm in namespace `AWS/Billing` in `us-east-1` (state `OK` or `INSUFFICIENT_DATA`).

Learners who set up the CLI another reasonable way (e.g. IAM Identity Center, ARN `assumed-role/AWSReservedSSO_…`) also **pass** check 1 — the requirement is "not root, no long-lived root keys". An IAM user with long-lived access keys in `~/.aws/credentials` passes T1 too, but note it as a 0.0 topic to read (`aws login` replaces them).

Sources: https://docs.aws.amazon.com/IAM/latest/APIReference/API_GetAccountSummary.html · https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-sign-in.html · https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/monitor_estimated_charges_with_cloudwatch.html (billing metrics only in `us-east-1`)

### Q3 — terminal (0.1)

Accepted: any path ending in `bash` or `zsh` **and** `Linux` (Linux, WSL 2) or `Darwin` (macOS).
Wrong: `$SHELL` printed literally or an error (PowerShell / cmd.exe); `MINGW64_NT-…` / `MSYS_NT-…` (Git Bash — the course standard on Windows is WSL 2 Ubuntu); `CYGWIN_NT-…`.

### Q4 — **B** (0.1)

`-rw-r-----` = owner `rw-`, group `r--`, others `---`. `bob` is in group `devs` → group triplet → read only.

### Q5 — **B** (0.1)

`>` truncates then writes; `>>` appends (option A).

### T2 — reference (0.1)

```bash
cd ~/p0-diag-t2
chmod u+x hello.sh      # owner execute only (→ 744)
chmod 600 secret.txt    # owner read+write, nobody else (or: chmod go-r secret.txt)
./hello.sh
```

Also accept `chmod +x` / `755` / `744` / `700` for `hello.sh`. **Fail regardless:** `chmod 777` or any `sudo`. Common miss: working under `/mnt/c/...` on WSL, where `chmod` may appear to do nothing.

Verified output (Ubuntu 24.04.1 / WSL 2, bash 5.2.21, 2026-11-17): `bash: ./hello.sh: Permission denied` before; `diagnostic ok: <you>` after; `-rwxr--r-- 744 hello.sh`; `-rw------- 600 secret.txt`.

### Q6 — **C** (0.2)

`/24` leaves 8 host bits: 2⁸ = **256** addresses. B (254) is "usable hosts on a traditional LAN", not what was asked. Source: RFC 4632 §3.1 — https://www.rfc-editor.org/rfc/rfc4632

### Q7 — **C** (0.2)

curl exit 6 = `CURLE_COULDNT_RESOLVE_HOST`: name resolution failed (typo `exmaple`). Firewall → exit 7 or timeout 28; certificate → 60. Source: https://curl.se/libcurl/c/libcurl-errors.html

### Q8 — **B** (0.3)

### Q9 — **B** (0.3)

The key stays in every earlier commit and any copy already taken. **Deactivate/rotate first**, then clean history. Source: https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository

### T3 — reference (0.3)

```bash
mkdir -p ~/p0-diag-t3 && cd ~/p0-diag-t3
git init -b main
echo "# p0 diagnostic" > README.md
echo ".env" > .gitignore
echo "API_KEY=not-a-real-key" > .env
git add README.md .gitignore && git commit -m "Add README and gitignore"
git switch -c feature/notes && echo "notes" > notes.md && git add notes.md && git commit -m "Add notes"
git switch main && git merge feature/notes
# github.com: New repository → p0-diagnostic → Private → no README/.gitignore/license
git remote add origin git@github.com:<you>/p0-diagnostic.git
git push -u origin main
```

Fail patterns: `.env` in `git ls-files`; `https://` remote (SSH required); `Permission denied (publickey)`; push rejected because the GitHub repo was created with a README. Local checks verified on git 2.43.0 (2026-11-17). `ssh -T` message: https://docs.github.com/en/authentication/connecting-to-github-with-ssh/testing-your-ssh-connection

### Q10 — **A** (0.4)

### Q11 — **B** (0.4)

Source: https://docs.python.org/3/library/venv.html

### Q12 — **B** (0.5)

IAM evaluation: an **explicit deny in any applicable policy overrides any allow**; with no explicit deny, an allow grants access; with neither, the default is **implicit deny**. Attachment order (C) and ownership (D) don't matter for an IAM user's identity-based policies.
Source: https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_evaluation-logic.html

---

## Routing self-test (for course maintainers)

| Learner profile | Wrong / failed | Score | Placement |
|---|---|---|---|
| Total beginner, no terminal, no AWS account | everything | 0–2 | **0.0** |
| Has a safe AWS account, never used a shell | Q3–Q5, T2, T3, + some of Q6–Q12 | < 10 | **0.1** |
| Junior dev, strong Linux/Git, AWS account safe, weak networking/AWS | Q6, Q12 | 10 | **Phase 1** (review 0.2, 0.5 Concepts) |
| Junior dev, strong Linux/Git, no AWS account | Q1?, T1 | ≥ 10 | **0.0** (a task failed) |
| Strong everywhere but root MFA off | T1 | 12 | **0.0** |
| Passes everything | — | 12 | **Phase 1** |

*Status: rewritten 2026-11-17 to the 0.0–0.6 spec.*
