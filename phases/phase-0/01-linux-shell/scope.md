# Scope · 0.1 Linux & the shell

> Planning document (Session C). Not module content, not published by the site. Implementation follows `templates/module.md` once approved.

**Draft front-matter**

```yaml
phase: "phase-0"
moduleId: "0.1"
title: "Linux & the shell"
goal: "Read, run, and debug shell commands with confidence."
timeEstimate: "8-10h"
costEstimate: "$0"
costAssumptions: "none"
lastVerified: null
prerequisites: ["0.0"]
hasDebuggingLab: true
hasTeardown: true
toolsPinned: { ubuntu: "24.04.1", bash: "5.2.21", docker: "<exact apt version, chosen in module session>", "ubuntu-image": "noble-20261110" }
```

**Sources:** spec "Module 0.1"; legacy Lessons 0.1 (WSL), 0.2 (survival kit), 0.2b (bash scripting), 0.6 (Docker install); MAPPING B-2, B-3; AUDIT B3, B4, B5, B10.
**Gate to pass (spec):** debug a broken script.

## 1. Goal
Read, run, and debug shell commands with confidence.

## 2. Prerequisites
- 0.0 (account safety). No AWS used in this module.
- A computer: Windows 10/11 with virtualization enabled (WSL 2), macOS, or Linux.

## 3. Time estimate
8–10 h (spec). Rough split: shell setup 1–1.5 h · filesystem/permissions 1.5 h · pipes/text tools 1.5 h · processes/systemctl 1 h · env vars/.bashrc 45 min · Docker install + SSH lab 1.5–2 h · debugging lab 1 h.

## 4. Cost estimate
USD 0 — everything runs locally. `costAssumptions: "none"`. Skip-teardown cost: USD 0/day (a stopped/removed local container costs nothing; only disk space).

## 5. Concepts (why before how)
- What a shell is and why DevOps work happens in one (repeatable, scriptable, remote).
- Filesystem tree, home directory, absolute vs relative paths (sets up the debugging lab).
- Users, groups, `rwx` permissions, `chmod`/`chown`, why `chmod 777` is never the fix.
- Streams: stdin/stdout/stderr, `>` vs `>>`, `|`; text tools `grep`, `awk`, `sed` on a real log.
- Processes, signals, `ps`/`kill`; services and `systemctl` (what systemd is for).
- Environment variables, `export`, shell start-up files (`.bashrc`; macOS `zsh` → `.zshrc`).
- Containers, minimally: "a packaged, isolated process" — only enough to install Docker and run one (Dockerfiles are Phase 1.2).
- SSH: key pairs, `~/.ssh` permissions, `known_hosts`, host-key prompts (AUDIT B5).
- `set -euo pipefail` and shebangs.

## 6. Labs (each: task, expected result, verification, teardown)
1. **Get a Linux shell** (legacy 0.1, B-2): WSL 2 + Ubuntu 24.04 on Windows (keep files in `~`, not `/mnt/c`); Terminal on macOS/Linux. Verify `echo "$SHELL"; uname -s` (matches diagnostic Q3).
2. **Filesystem and permissions:** navigate, create, move; a script that fails with `Permission denied` → fix with least privilege; a file owned by the wrong user → `chown` (with `sudo`, explained). Verify with `stat`.
3. **Pipes and text tools:** count error lines in a provided log, extract fields with `awk`, rewrite with `sed`; `>` vs `>>`.
4. **Processes and services:** start/inspect/kill a background process; `systemctl status/start/stop` on a real service (WSL 2 with systemd, Linux). See open question 1 for macOS.
5. **Environment and start-up files:** set/export variables, prove the difference in a child process, persist in `.bashrc`/`.zshrc`.
6. **Install Docker and SSH into a local container** (B-3): install Docker (Linux/WSL: Ubuntu's `docker.io` apt package, exact version pinned; macOS: Docker Desktop, exact version pinned — see open question 2); run a pinned `ubuntu:noble-20261110` container with `openssh-server`, generate an ed25519 key, SSH in on a mapped port, see the host-key prompt. Teardown: `docker rm -f`, `docker image rm`, remove the `known_hosts` entry.

## 7. Debugging lab (spec)
`deploy.sh` fails because (a) no shebang, (b) relative paths that break when run from another directory, (c) a variable that isn't exported to a child process. Learner fixes all three and writes one sentence per cause. Diagnosis path in `solutions/`.

## 8. Self-check (spec + additions)
- `set -euo pipefail` — what each flag does.
- `>` vs `>>`.
- Why `chmod 777` didn't fix the real problem.
- Show the command that proves a variable reaches a child process.
- Why SSH refuses a private key with permissions `0644`.

## 9. Teardown
Remove the lab container and image, the lab directory, and the SSH `known_hosts` entry. Confirm with `docker ps -a --filter name=p0-ssh` (empty) and `ls ~/p0-shell-lab` (no such directory). Docker itself stays installed (used in 0.2 and Phase 1).

## 10. Last verified
`null` until a human runs every lab on Windows (WSL 2), macOS and Linux.

## Open questions for approval
1. **macOS and `systemctl`:** macOS has no systemd. Options: (a) macOS learners do Lab 4's `systemctl` part inside a free-tier EC2 instance — costs cents and needs 0.5 material; (b) teach `launchctl` as the macOS equivalent alongside; (c) mark Lab 4's service part Linux/WSL-only and give macOS learners a reading + the self-check. Recommendation: (c), with a short `launchctl` note.
2. **Docker on Windows/macOS:** Docker Engine inside WSL 2 (free, no Desktop licence question, same commands as Linux) vs Docker Desktop. Recommendation: Engine in WSL 2 for Windows; Docker Desktop on macOS (pinned version; free for personal/education use — check current terms before writing).
3. **Diagnostic coverage:** with Docker now in 0.1, add a Docker item to the entry diagnostic later? (Would be an `/assessments` change in its own session.)
