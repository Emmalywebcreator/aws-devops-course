# Scope · 0.3 Git & GitHub workflows

> Planning document (Session C). Not module content, not published by the site.

**Draft front-matter**

```yaml
phase: "phase-0"
moduleId: "0.3"
title: "Git & GitHub workflows"
goal: "Work on a team repo without breaking it."
timeEstimate: "5-6h"
costEstimate: "$0"
costAssumptions: "none"
lastVerified: null
prerequisites: ["0.1"]
hasDebuggingLab: true
hasTeardown: true
toolsPinned: { git: "2.43.0" }
```

**Sources:** spec "Module 0.3"; legacy Lesson 0.4; diagnostic T3 (SSH push), Q8, Q9; AUDIT B5 (SSH prompts).
**Gate to pass (spec):** branch, resolve a conflict, open a PR.

## 1. Goal
Work on a team repo without breaking it.

## 2. Prerequisites
0.1 (shell, SSH keys). A GitHub account (created in Lab 1 if needed).

## 3. Time estimate
5–6 h (spec).

## 4. Cost estimate
USD 0 — GitHub free personal account, private practice repo. Skip-teardown: USD 0/day.

## 5. Concepts
Snapshots and commits (not diffs), the staging area, branches as pointers, merge vs rebase (one sentence each — spec), remotes, pull requests and review, `.gitignore`, history is permanent (why secrets must be rotated), undo tools: `restore` / `reset` (`--soft` / `--mixed` / `--hard`) / `revert` and when each is right.

## 6. Labs (spec)
1. **init → commit → branch → merge** in a practice repo `p0-git-practice`.
2. **Create and resolve a real merge conflict** (two branches edit the same line).
3. **PR against your own repo + self-review** on GitHub (SSH remote; `ssh -T git@github.com`). Console steps dated "UI as of".
4. **`.gitignore` correctly:** prove a secret file is ignored (`git check-ignore -v`, `git ls-files`).
5. **Undo mistakes:** `restore`, `reset --soft/--hard`, `revert` on a pushed commit — with "which tool, and why".
Teardown: delete the local repo; deleting the GitHub repo is optional (free).

## 7. Debugging lab (spec, adapted — decision 3)
A practice repo (provided by a break script) has a fake `.env` committed several commits ago and "deleted" in a later commit. The learner:
1. **Finds** the secret in history without executing any rewrite: `git log --all --diff-filter=A -- .env`, `git log -p -S 'API_KEY'`, `git show <commit>:.env`.
2. **Proves** it's still reachable on the remote (clone fresh, `git show`).
3. **Explains the remedy in writing, in order:** (a) revoke/rotate the secret first — rewriting history can't recall copies already taken; (b) then rewrite history (name the tool, `git filter-repo`, and what it does — **not executed here**); (c) force-push and have collaborators re-clone; (d) prevent it (`.gitignore`, secret scanning).
No tool is installed in 0.3. The actual history-rewrite lab is in **0.4** (installed via `pip`). Diagnosis path and model answer in `solutions/`.

## 8. Self-check (spec)
- Merge vs rebase, one sentence each.
- What does `git reset --hard` destroy that `--soft` doesn't?
- Plus: prove a file is ignored; when to `revert` instead of `reset`; the command that shows which commit introduced a file.

## 9. Teardown
`rm -rf ~/p0-git-practice`; optional GitHub repo deletion (CLI or UI, "UI as of"). Confirm locally with `ls`.

## 10. Last verified
`null` until a human run.

## Decisions (approved 2026-11-17)
3. **`git-filter-repo` is not installed in 0.3.** The debugging lab is identify-and-explain only (above). The rewrite itself is a 0.4 lab.

## Still open (not blocking)
- **macOS git version** varies (Apple's git vs Homebrew). Proposal: require git ≥ 2.43 and record the version used, rather than forcing an install.
