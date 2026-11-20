---
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
toolsPinned:
  "git": "2.43.0"
---

# Phase 0 · Module 0.3 — Git & GitHub workflows

## 1. Goal

Work on a team repo without breaking it.

## 2. Prerequisites

- **Modules:** [0.1 Linux & the shell](../01-linux-shell/module.md) (a shell, files, and SSH keys).
- **Tools installed:** `git` 2.43.0 or newer (Ubuntu 24.04 ships 2.43.0; check with `git --version`), `ssh` and `ssh-keygen` (from 0.1).
- **Access:** a GitHub account. If you don't have one, create it at https://github.com/signup (UI as of 2026-11-18) and turn on two-factor authentication. A free personal account is enough: private repositories are free.
- Update the course clone for the lab files: `git -C ~/aws-devops-course pull`.

## 3. Time estimate

**5–6 hours.**

| Lab | Time |
|---|---|
| 1 — init, commit, branch, merge | 1 h |
| 2 — Create and resolve a merge conflict | 45 min |
| 3 — SSH to GitHub and a pull request | 1.5 h (includes creating the account if needed) |
| 4 — `.gitignore` | 30 min |
| 5 — Undo mistakes | 1 h |
| Debugging lab | 45 min |

## 4. Cost estimate

**USD 0.** Git is free; GitHub's free personal plan includes unlimited private repositories (checked 2026-11-18, re-check: https://docs.github.com/en/get-started/learning-about-github/githubs-plans).

| Resource | Billed while idle? | Unit price | Expected use | Cost |
|---|---|---|---|---|
| Git (local) | no | free | all labs | USD 0 |
| GitHub private repository `p0-git-practice` | no | free on a personal account | Labs 3–5 | USD 0 |

- **Pricing assumptions:** a free GitHub personal account; no paid GitHub features used.
- **Total if you follow the teardown steps:** USD 0.
- **If you skip teardown: USD 0/day.** A leftover repository costs nothing, but a leftover SSH key on your GitHub account that you no longer control is a security risk. Remove it (section 9).

## 5. Concepts

### Why Git, and what a commit is

- **Problem it solves:** without version control, "what changed, when and why?" and "put it back how it was" have no answer, and two people editing the same files overwrite each other.
- **How it works:** a **commit** is a **snapshot** of every tracked file at one moment, plus who made it, when, and a message. (It is a snapshot, not a list of changes; Git computes the changes by comparing snapshots.) Each commit points to its parent, so history is a chain. Commits are saved in two steps: `git add` puts changes in the **staging area** (the next snapshot, being assembled), then `git commit` records it. The staging area lets you commit *part* of your work.
- **The command that shows it:** `git status` (what's changed and what's staged), `git log --oneline --graph --all` (the chain).
- **Applied in:** Lab 1.
- **Source:** https://git-scm.com/book/en/v2/Getting-Started-What-is-Git%3F

### Branches, merging and rebasing

- **Problem it solves:** you want to work on something without disturbing the stable line, and combine the work later.
- **How it works:** a **branch** is just a movable label pointing at a commit. `main` is the usual stable line. **Merge:** combine another branch's work into the current one, keeping both histories and adding a merge commit if they diverged. **Rebase:** replay your commits on top of another branch, so history looks like one straight line (and your commits get new IDs). Rule of thumb: never rebase commits that other people already have. This course uses merges.
  When two branches change the *same lines*, Git can't choose, and stops with a **merge conflict**. You pick the result, mark it resolved, and commit.
- **The command that shows it:** `git branch`, `git log --graph`, and the `<<<<<<<` markers Git puts in a conflicted file.
- **Applied in:** Labs 1 and 2.

### Remotes, SSH and pull requests

- **Problem it solves:** a team needs one shared copy, and a way to review changes before they reach `main`.
- **How it works:** a **remote** is another copy of the repository, usually on GitHub. `origin` is the default name for the one you cloned from. `git push` sends your commits there; `git pull` fetches and merges new ones. GitHub checks who you are with an **SSH key**: you keep the private half and give GitHub the public half (the same idea as 0.1). A **pull request (PR)** is a request to merge one branch into another, with a place to review the changes and discuss them first. In a team, nobody pushes straight to `main`.
- **The command that shows it:** `git remote -v`, `git ls-remote origin` (what GitHub has) and `ssh -T git@github.com` (does GitHub recognise your key).
- **Applied in:** Lab 3.
- **Source:** https://docs.github.com/en/pull-requests

### `.gitignore` and why history is permanent

- **Problem it solves:** some files must never be in the repository: passwords, keys, `.env` files, build output.
- **How it works:** a `.gitignore` file lists patterns Git should ignore. Two things to understand. First, it only affects files Git is **not already tracking**. Second, and more important, **Git history is permanent**: every commit is a snapshot that stays reachable, so deleting a file in a *later* commit doesn't remove it from the *earlier* ones, and every clone carries them. A secret that has ever been pushed must be treated as **leaked**: revoke it first, clean up second. (Debugging lab.)
- **The command that shows it:** `git check-ignore -v <file>` (which rule ignores it), `git ls-files` (what is tracked), `git log --all --diff-filter=A -- <file>` (which commit added it).
- **Applied in:** Lab 4 and the debugging lab.
- **Source:** https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository

### Undoing things: pick the right tool

| Situation | Tool | What it does | Safe on shared history? |
|---|---|---|---|
| Edited a file; want the last committed version back | `git restore <file>` | discards uncommitted changes in that file | n/a (local only) |
| Committed too soon; not pushed; want to redo the commit | `git reset --soft HEAD~1` | moves the branch back one commit, **keeps** your changes staged | local only |
| Same, but also unstage | `git reset HEAD~1` (mixed, the default) | moves back, keeps changes in your files, unstaged | local only |
| Committed junk; not pushed; throw it away completely | `git reset --hard HEAD~1` | moves back **and deletes** the changes from your files | local only, **destroys work** |
| A bad commit is **already pushed** or shared | `git revert <commit>` | adds a *new* commit that undoes it; history stays intact | **yes** |

`reset` rewrites where a branch points, so it is for commits nobody else has. `revert` adds history, so it is safe on shared branches.
Source: https://git-scm.com/docs/git-reset and https://git-scm.com/docs/git-revert

## 6. Labs

> **Region:** none. This module creates nothing in AWS.
>
> **Where to type commands:** your Linux shell (Ubuntu on WSL, Terminal on macOS, or a Linux terminal). Lines starting with `#` are comments. Work in your home folder, not under `/mnt/c/...` on WSL.
>
> **Names:** replace `<you>` with your GitHub username and use your own name and email where shown.

### Lab 1 — init, commit, branch, merge

- **Region:** none.
- **Task:** tell Git who you are, then build a small history.

```bash
git config --global user.name  "Your Name"
git config --global user.email "you@example.com"
git config --global init.defaultBranch main

mkdir -p ~/p0-git-practice && cd ~/p0-git-practice
git init
printf '# p0 git practice\n' > README.md
printf 'Menu\nsoup: 3\nrice: 5\n' > menu.txt
git status                                   # two untracked files
git add README.md menu.txt
git commit -m "Add README and menu"

git switch -c feature/dessert                # create and move to a branch
echo 'cake: 4' >> menu.txt
git commit -am "Add dessert"                 # -a: stage changes to tracked files, then commit
git switch main
git merge feature/dessert                    # main hasn't moved, so Git just moves the label: "Fast-forward"
git branch -d feature/dessert
git log --oneline --graph --all
```

Your email is stored in every commit you make, and public repositories show it. GitHub offers a private `…@users.noreply.github.com` address for this (Settings → Emails; UI as of 2026-11-18); use that if you prefer.

- **Expected result:** `git merge` prints `Fast-forward`; the log shows two commits, `Add dessert` above `Add README and menu`.
- **Verification command:**

```bash
cd ~/p0-git-practice
git log --oneline | wc -l          # expect: 2
git branch --show-current          # expect: main
git status --porcelain | wc -l     # expect: 0
git branch --list feature/dessert | wc -l   # expect: 0
```

- **Teardown command:** none yet (the repo is removed in section 9).
- **Cost note:** USD 0.

### Lab 2 — Create and resolve a merge conflict

- **Region:** none.
- **Task:** make two branches change the **same line**, merge both, and fix the conflict.

```bash
cd ~/p0-git-practice
git switch -c feature/a
printf 'Menu\nsoup: 4\nrice: 5\ncake: 4\n' > menu.txt
git commit -am "Soup to 4"

git switch main
git switch -c feature/b
printf 'Menu\nsoup: 6\nrice: 5\ncake: 4\n' > menu.txt
git commit -am "Soup to 6"

git switch main
git merge feature/a        # fast-forward: no conflict
git merge feature/b        # same line changed on both branches: CONFLICT
git status --short         # UU menu.txt   ("both modified")
cat menu.txt               # see the <<<<<<< HEAD / ======= / >>>>>>> feature/b markers
```

Resolve it: decide the result (we'll say `soup: 5`), write the *whole file without markers*, then tell Git it's resolved:

```bash
printf 'Menu\nsoup: 5\nrice: 5\ncake: 4\n' > menu.txt
git add menu.txt
git commit --no-edit       # accepts Git's ready-made "Merge branch 'feature/b'" message
git branch -d feature/a feature/b
git log --oneline --graph
```

- **Expected result:** the second merge prints `CONFLICT (content): Merge conflict in menu.txt` and `Automatic merge failed`. After the fix, the graph shows a merge commit with two parents.
- **Verification command:**

```bash
cd ~/p0-git-practice
grep -c '<<<<<<<' menu.txt         # expect: 0   (no markers left)
git log --merges --oneline | wc -l # expect: 1
git status --porcelain | wc -l     # expect: 0
```

- **Teardown command:** none yet.
- **Cost note:** USD 0.

### Lab 3 — SSH to GitHub and a pull request against your own repo

- **Region:** none.
- **Task:** (1) make an SSH key for GitHub, (2) give GitHub the public half, (3) push your repo, (4) open and merge a pull request, reviewing your own change.

**1. Make a key** (separate from your 0.1 key; deleted at the end). For a throwaway practice key we skip the passphrase; for real work use one and an `ssh-agent`.

```bash
ssh-keygen -t ed25519 -C "p0-git" -N "" -f ~/.ssh/p0_github_ed25519
cat ~/.ssh/p0_github_ed25519.pub        # one line starting ssh-ed25519; this half is safe to share
```

**2. Give GitHub the public half** (UI as of 2026-11-18): on github.com click your profile picture → **Settings** → **SSH and GPG keys** → **New SSH key**. Title: `p0-git`. Key type: **Authentication Key**. Paste the line from `cat` and click **Add SSH key** (GitHub may ask you to confirm your password).

**3. Test the connection.** The first time, SSH shows GitHub's key fingerprint and asks to continue. Compare it with GitHub's published fingerprint (https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/githubs-ssh-key-fingerprints); the **Ed25519** one is `SHA256:+DiY3wvvV6TuJJhbpZisF/zLDA0zPMSvHdkr4UvCOqU`. If it matches, type `yes`.

```bash
ssh -i ~/.ssh/p0_github_ed25519 -o IdentitiesOnly=yes -T git@github.com
# expect: Hi <you>! You've successfully authenticated, but GitHub does not provide shell access.
# (the command exits with code 1 even when it works; only the message matters)
```

**4. Create the empty GitHub repo** (UI as of 2026-11-18): **+** (top right) → **New repository**. Name: `p0-git-practice`. Choose **Private**. Leave *Add a README*, *.gitignore* and *license* all **off** (empty). **Create repository**. Then tell your local repo to use your key, and push:

```bash
cd ~/p0-git-practice
git config core.sshCommand "ssh -i $HOME/.ssh/p0_github_ed25519 -o IdentitiesOnly=yes"
git remote add origin git@github.com:<you>/p0-git-practice.git
git push -u origin main
```

**5. A pull request.** Make a change on a branch and push the branch (not `main`):

```bash
git switch -c feature/readme-tweak
printf '\nThis repo is for practising Git.\n' >> README.md
git commit -am "Explain the repo in README"
git push -u origin feature/readme-tweak
```

On GitHub (UI as of 2026-11-18; wording may differ slightly): open your repo; a banner offers **Compare & pull request**; click it, then **Create pull request**. Open the **Files changed** tab, hover over the added line, click the blue **+** and leave a comment; then **Review changes** → **Comment** → **Submit review**. (GitHub doesn't let you *approve* your own PR, but you can review it.) Back on the **Conversation** tab: **Merge pull request** → **Confirm merge** → **Delete branch**. Then bring the merged result home:

```bash
git switch main
git pull
git log --oneline --graph | head -5
```

- **Expected result:** `ssh -T` greets you by username. After the merge, `git pull` fast-forwards or merges, and the log shows a `Merge pull request #1 from <you>/feature/readme-tweak` commit.
- **Verification command:**

```bash
cd ~/p0-git-practice
git remote get-url origin                   # expect: git@github.com:<you>/p0-git-practice.git
git log --merges --oneline | head -3        # expect: a line "Merge pull request #1 from <you>/feature/readme-tweak"
[ "$(git rev-parse main)" = "$(git ls-remote origin refs/heads/main | cut -f1)" ] && echo "main matches GitHub" || echo "MISMATCH"
# expect: main matches GitHub
```

- **Teardown command:** removed in section 9 (key, repo, GitHub-side key and repo).
- **Cost note:** USD 0.

### Lab 4 — `.gitignore`, correctly

- **Region:** none.
- **Task:** keep a secret file out of Git, and prove it.

```bash
cd ~/p0-git-practice
printf 'API_KEY=not-a-real-key\n' > .env
git status --short                          # .env shows up as untracked: dangerous
printf '.env\n' > .gitignore
git status --short                          # now only .gitignore shows
git check-ignore -v .env                    # which rule is hiding it
git add .env                                # Git refuses and says why
git add .gitignore && git commit -m "Ignore .env"
git ls-files                                # .env is NOT in the list
git push
```

`.gitignore` only affects files Git isn't tracking yet. If a file was committed *before* you ignored it, ignoring it later does nothing; `git rm --cached <file>` stops tracking it (the old commits still contain it, see the debugging lab).

- **Expected result:** `git check-ignore -v .env` prints `.gitignore:1:.env	.env`. `git add .env` prints `The following paths are ignored by one of your .gitignore files`. `git ls-files` lists `.gitignore`, `README.md` and `menu.txt` only.
- **Verification command:**

```bash
cd ~/p0-git-practice
git check-ignore .env                       # expect: .env
git ls-files | grep -cx '\.env'             # expect: 0
git status --porcelain | wc -l              # expect: 0
```

- **Teardown command:** none yet.
- **Cost note:** USD 0.

### Lab 5 — Undo mistakes, and say which tool and why

- **Region:** none.
- **Task:** use each undo tool once, in the situation it is made for.

```bash
cd ~/p0-git-practice

# (a) Edited a file by mistake: restore it.
echo "junk" >> README.md
git restore README.md
git diff --quiet && echo "README is clean again"

# (b) Committed too soon, not pushed: reset --soft keeps the work; reset --hard destroys it.
echo "first" > notes.txt
git add notes.txt && git commit -m "Add notes"
git reset --soft HEAD~1
git status --short                          # A  notes.txt  (the work is still staged)
git reset --hard HEAD                       # now it is gone for good
ls notes.txt                                # No such file or directory

# (c) A bad commit that is already pushed: revert it.
echo "bad line" >> menu.txt
git commit -am "Add bad line"
git push
git revert --no-edit HEAD
git push
grep -c 'bad line' menu.txt                 # expect: 0
git log --oneline | head -3
```

Write one sentence for each of (a), (b) and (c): *which tool did I use, and why that one and not the others?* Then answer: which of these three would have been **wrong** to use on a commit your teammate had already pulled?

- **Expected result:** (a) prints `README is clean again`. (b) shows `A  notes.txt`, then `ls` fails. (c) leaves `Revert "Add bad line"` on top of `Add bad line`, and the line is gone from the file.
- **Verification command:**

```bash
cd ~/p0-git-practice
git log --oneline | head -2         # expect: Revert "Add bad line" above Add bad line
grep -c 'bad line' menu.txt         # expect: 0
git status --porcelain | wc -l      # expect: 0
[ "$(git rev-parse main)" = "$(git ls-remote origin refs/heads/main | cut -f1)" ] && echo "in sync with GitHub"
```

- **Teardown command:** none yet.
- **Cost note:** USD 0.

## 7. Debugging lab

- **Scenario:** a teammate tells you: "I committed a `.env` file with a key in it a few commits ago. I deleted it right after, so it's fine, right?" You have the repo. Your job is to find out whether anything secret is still in it, and to write down what to do about it, in the right order.
- **How to create the broken state:**

```bash
bash ~/aws-devops-course/phases/phase-0/03-git-github/labs/debug-leaked-env/break.sh
cd ~/p0-git-debug/work
```

The script builds two folders: `work` (your clone) and `remote.git` (a local stand-in for GitHub). The "secret" is the example key from AWS's own documentation; it is not real.

- **Symptom you will see:** the latest commit looks clean: `ls -a` shows no `.env`, and `.gitignore` already ignores it.
- **Your task:** without changing history (**do not rewrite anything in this lab**):
  1. **Find** the commit that *added* `.env` and the commit that *removed* it, and read the secret out of history.
  2. **Prove** it is still on the "remote": clone `remote.git` fresh into `~/p0-git-debug/fresh` and read the secret from that clone.
  3. **Write** `~/p0-git-debug/answer.md`: the commit that introduced the file, and the **ordered** steps you would take to deal with it: (a) what to do with the key first, (b) how the history is cleaned (name the tool), (c) what happens to the shared copy and to everyone who already cloned, (d) how to stop it happening again.

  Tools from this module: `git log --all --diff-filter=A -- .env`, `git log -p -S '<text>'`, `git show <commit>:<path>`, `git clone`.
- **Done when:**

```bash
bash ~/aws-devops-course/phases/phase-0/03-git-github/labs/debug-leaked-env/check.sh
# expect: seven PASS lines and "7 passed, 0 failed"
```

- **Teardown:** `rm -rf ~/p0-git-debug` (also in section 9).

The diagnosis path and a model answer are in `solutions/debugging-lab.md`. **Module 0.4 Lab 7 does the actual history rewrite** with the tool you name here.

## 8. Self-check

Answers: `solutions/self-check.md`.

1. Merge vs rebase: say what each does in one sentence.
2. What does `git reset --hard` destroy that `git reset --soft` doesn't?
3. Show the command that proves a file is ignored, and the one that proves it isn't tracked.
4. When do you use `git revert` instead of `git reset`?
5. Which command shows which commit first added a file?
6. A secret was pushed to GitHub ten minutes ago. List the response steps in the right order, and say why the order matters.
7. `git status` shows `both modified: menu.txt` in the middle of a merge. What state is the repo in, and what are the three commands that finish the job?

## 9. Teardown

```bash
# 1. Local folders
rm -rf ~/p0-git-practice ~/p0-git-debug

# 2. The practice SSH key
rm -f ~/.ssh/p0_github_ed25519 ~/.ssh/p0_github_ed25519.pub
```

**On GitHub** (UI as of 2026-11-18):

1. **Remove the key (required):** profile picture → **Settings** → **SSH and GPG keys** → next to `p0-git` click **Delete** → confirm.
2. **Delete the repository (optional, free either way):** open `p0-git-practice` → **Settings** → scroll to **Danger Zone** → **Delete this repository** → follow the prompts.

**Confirm nothing is left:**

```bash
ls ~/p0-git-practice ~/p0-git-debug 2>&1       # expect: "No such file or directory" twice
ls ~/.ssh/p0_github_ed25519* 2>&1              # expect: No such file or directory
```

On GitHub, the SSH keys page should no longer list `p0-git`.

Kept on purpose: `git`, your global `user.name`, `user.email` and `init.defaultBranch`, the `github.com` line in `~/.ssh/known_hosts`, and the `~/aws-devops-course` clone.

## 10. Last verified

- **Date:** NOT YET VERIFIED BY A HUMAN. Drafted 2026-11-18. (`lastVerified: null`; only a human who runs every command may set it.)
- **Verified by:** —
- **Region:** none (no AWS resources).
- **Versions:** git 2.43.0 · OpenSSH as installed by 0.1.
- **Notes (author dry-run, not a verification):** on Ubuntu 24.04.5 with git 2.43.0, Labs 1, 2, 4 and 5 and the whole debugging lab (`break.sh`, the history searches, the fresh clone, and `check.sh` with both a failing and a passing answer) were run end to end, with a local bare repository standing in for GitHub; every output matches what the text says. GitHub's Ed25519 fingerprint was checked against GitHub's published page on 2026-11-18. **Not run:** everything that needs a real GitHub account (Lab 3's key upload, `ssh -T`, push, and the pull request, and the Teardown clicks), and macOS. GitHub's menu wording ("UI as of 2026-11-18") was written from GitHub's documentation, not clicked through.
