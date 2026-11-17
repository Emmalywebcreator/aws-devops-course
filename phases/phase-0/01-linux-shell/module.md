---
phase: "phase-0"
moduleId: "0.1"
title: "Linux & the shell"
goal: "Read, run, and debug shell commands with confidence."
timeEstimate: "8-10h"
costEstimate: "$0"
costAssumptions: "Local only, nothing created in AWS; Docker Desktop (macOS) assumed free under Docker's personal / education / small-business terms as checked 2026-11-17; if you skip teardown ≈ $0/day"
lastVerified: null
prerequisites: ["0.0"]
hasDebuggingLab: true
hasTeardown: true
toolsPinned:
  "ubuntuWslMinorVersion": "24.04"
  "bash": "5.2.21"
  "docker.io": "29.1.3-0ubuntu3~24.04.2"
  "docker-desktop-macos": "4.99.0"
  "ubuntu-image": "noble-20261110"
  "openssh-server": "1:9.6p1-3ubuntu13.20"
---

# Phase 0 · Module 0.1 — Linux & the shell

## 1. Goal

Read, run, and debug shell commands with confidence.

## 2. Prerequisites

- **Modules:** [0.0 Account safety & billing guardrails](../00-account-safety/module.md). This module uses no AWS, but 0.0 comes first in Phase 0.
- **You need:** a computer running Windows 10/11 (with hardware virtualisation enabled — most PCs from the last 8 years), macOS, or Linux; an internet connection; about 10 GB of free disk space (for Ubuntu on Windows and Docker).
- **No experience needed.** Every command is explained the first time it appears.

## 3. Time estimate

**8–10 hours.**

| Lab | Time |
|---|---|
| 1 — Get a Linux shell | 1–1.5 h (Windows: includes a restart) |
| 2 — Files, folders and permissions | 1.5 h |
| 3 — Pipes and text tools | 1.5 h |
| 4 — Processes and services | 1 h |
| 5 — Environment variables and start-up files | 45 min |
| 6 — Install Docker and SSH into a container | 1.5–2 h |
| Debugging lab | 1 h |

## 4. Cost estimate

**USD 0.** Everything runs on your own computer. Nothing is created in AWS.

| Resource | Billed while idle? | Unit price | Expected use | Cost |
|---|---|---|---|---|
| Ubuntu on WSL 2 / your terminal | no | free | whole module | USD 0 |
| Docker Engine (Linux/WSL 2) / Docker Desktop (macOS) | no | free (Docker Desktop is free for personal use, education, non-commercial open source and small businesses — fewer than 250 employees **and** under USD 10 million annual revenue; terms as checked 2026-11-17, re-check: https://docs.docker.com/subscription/desktop-license/) | Lab 6 | USD 0 |
| Container image `ubuntu:noble-20261110` | no | free download (~30 MB) | Lab 6 | USD 0 |

- **Pricing assumptions:** no cloud resources; Docker Desktop licence terms as above (checked 2026-11-17).
- **Total if you follow the teardown steps:** USD 0.
- **If you skip teardown: USD 0/day.** A leftover container or image only uses disk space. Tear down anyway: an SSH server listening on your machine is something you should never leave behind by accident.

## 5. Concepts

### Why a shell at all?

- **Problem it solves:** clicking through windows can't be repeated exactly, can't be shared as a file, and doesn't exist on the servers you'll manage — they have no screen. A **shell** is a program that reads a command you type, runs it, and shows the result. Every DevOps tool in this course is driven from one.
- **The one used here:** **bash** on Linux and on Windows (inside Ubuntu, via WSL 2), and **zsh** on macOS. The commands in this module work in both unless a box says otherwise.
- **Applied in:** every lab.
- **Source:** https://www.gnu.org/software/bash/manual/bash.html

### Files, paths and permissions

- **Paths:** everything lives in one tree starting at `/`. Your **home directory** is `~` (for example `/home/ana`). An **absolute path** starts with `/` and means the same thing everywhere. A **relative path** (like `config/settings.env`) is relative to *the folder you're in right now* — so it breaks when a script is run from somewhere else. That's the bug in this module's debugging lab.
- **Permissions:** every file has an **owner**, a **group**, and three sets of permissions — for the owner, the group, and everyone else — each made of **r**ead, **w**rite, e**x**ecute. `ls -l` shows them as `-rwxr-x---`. You change them with `chmod` and change the owner with `chown`.
- **Why `chmod 777` is never the fix:** it gives *everyone* on the machine the right to change the file. If your problem was "the wrong person owns this file", 777 hides the problem and creates a security hole. Find who needs which permission and grant only that.
- **`sudo`:** runs one command as the administrator (`root`). Use it only when a step needs it, and read the command first.
- **Applied in:** Labs 2 and 6, debugging lab.
- **Source:** https://www.gnu.org/software/coreutils/manual/html_node/File-permissions.html

### Streams, pipes and text tools

- Every command has an input (**stdin**) and two outputs: normal output (**stdout**) and errors (**stderr**).
- `>` sends stdout to a file **and replaces its contents**. `>>` **appends**. `|` (a **pipe**) feeds one command's output into the next command's input.
- **`grep`** finds lines, **`awk`** picks out columns and does simple maths, **`sed`** edits text as it flows past. Together they answer questions like "which endpoint is failing?" from a log file in one line.
- **Applied in:** Lab 3.
- **Source:** https://www.gnu.org/software/bash/manual/bash.html#Redirections

### Processes and services

- A **process** is a running program, with a number (**PID**). You can list it (`ps`), send it a signal to stop (`kill`), and run it in the background (`&`).
- A **service** is a process the system starts for you and keeps running (a web server, a scheduler). On Linux, **systemd** manages services and you talk to it with **`systemctl`**. macOS uses a different system, `launchd` (command: `launchctl`).
- **Applied in:** Lab 4.
- **Source:** https://www.freedesktop.org/software/systemd/man/latest/systemctl.html

### Environment variables

- A **variable** set in your shell (`APP_ENV=staging`) exists only in that shell. **`export`** makes it part of the **environment** that gets copied into every program the shell starts — including scripts that script runs.
- **Start-up files** (`~/.bashrc` for bash, `~/.zshrc` for zsh) run every time you open a new terminal; put lasting settings there.
- **Applied in:** Lab 5, debugging lab.

### Scripts: the shebang and safety flags

- The first line `#!/usr/bin/env bash` (the **shebang**) tells the operating system which program runs the file. Without it, the system falls back to `/bin/sh` — which on Ubuntu is **dash**, a smaller shell that doesn't understand some bash features. The script that worked in your terminal then fails under a scheduler.
- **`set -euo pipefail`:** `-e` stops at the first failing command, `-u` treats an unset variable as an error, `-o pipefail` makes a pipeline fail if *any* command in it fails (not only the last). These turn silent wrong results into loud errors.
- **Sources:** https://www.gnu.org/software/bash/manual/bash.html#The-Set-Builtin · `man 3 execvp` (Linux man-pages: the `/bin/sh` fallback for files without a valid interpreter line)

### Containers (just enough for this module)

- **Problem it solves:** you need a second, throw-away Linux machine to practise SSH on, without paying for one or breaking your own. A **container** is an isolated set of processes with its own filesystem, started from an **image** in seconds and deleted just as fast. **Docker** is the tool that runs them.
- This module only *installs* Docker and *runs* one ready-made container.
- **Security note:** "The `docker` group grants root-level privileges to the user" (Docker docs). Only add your own user, and know how to undo it (section 9). Source: https://docs.docker.com/engine/install/linux-postinstall/

### SSH

- **SSH** gives you a shell on another machine over an encrypted connection. Instead of a password, you use a **key pair**: the **private key** stays on your machine (never share it), the **public key** goes on the server.
- SSH refuses a private key that other users can read ("UNPROTECTED PRIVATE KEY FILE") — permissions again.
- The first time you connect, SSH shows the server's **host key fingerprint** and remembers it in `~/.ssh/known_hosts`. If it ever changes, SSH warns you loudly: the server may not be the one you think.
- **Applied in:** Lab 6.
- **Source:** https://man.openbsd.org/ssh

---

## 6. Labs

> **Region:** none — this module runs entirely on your computer and creates nothing in AWS.
>
> **Where to type commands:** Windows → the **Ubuntu** app (after Lab 1). macOS → **Terminal**. Linux → your terminal. Lines starting with `#` are comments; you don't type them.
>
> **macOS:** where a command differs, the macOS version is shown as a comment under it.

### Lab 1 — Get a Linux shell

- **Region:** none.
- **Task:**

**Windows 10/11 — install Ubuntu 24.04 on WSL 2** (UI as of 2026-11-17). Open **PowerShell as Administrator** (Start → type *PowerShell* → right-click → *Run as administrator*) and run:

```powershell
wsl --install -d Ubuntu-24.04
```

Restart when asked. Ubuntu opens and asks you to create a **Linux username and password** — pick a short lowercase name; the password is for `sudo` (nothing appears while you type it — that's normal). From now on, open **Ubuntu** from the Start menu for every command in this course. Source: https://learn.microsoft.com/en-us/windows/wsl/install

> **Keep your work inside Linux.** Work in your Linux home folder (`~`), never under `/mnt/c/...`. Windows folders don't keep Linux permissions, so Lab 2 would silently not work there.

Check that systemd (used in Lab 4 and by Docker in Lab 6) is on:

```bash
cat /etc/wsl.conf
# expect a [boot] section containing: systemd=true
# If it's missing: printf '[boot]\nsystemd=true\n' | sudo tee -a /etc/wsl.conf   (-a appends, keeping anything already there)
# then in PowerShell: wsl --shutdown, and reopen Ubuntu.
```

Source: https://learn.microsoft.com/en-us/windows/wsl/systemd

**macOS:** open **Terminal** (Applications → Utilities; UI as of 2026-11-17). **Linux:** open your terminal.

**Everyone:** update the package list (Ubuntu/WSL/Linux only) and get the course's lab files. `git` comes with Ubuntu and macOS; here it's used only to download a folder.

```bash
sudo apt-get update                          # Ubuntu / WSL only
git clone --depth 1 https://github.com/Emmalywebcreator/aws-devops-course.git ~/aws-devops-course
export COURSE=~/aws-devops-course
cp -r "$COURSE/phases/phase-0/01-linux-shell/labs" ~/p0-shell-lab
ls ~/p0-shell-lab
```

- **Expected result:** a prompt like `ana@PC:~$` (Ubuntu) or `ana@Mac ~ %` (macOS); `ls` shows `debug-deploy  text-tools`.
- **Verification command:**

```bash
echo "$SHELL"; uname -s; pwd
# expect: /bin/bash (or /bin/zsh on macOS) · Linux (or Darwin) · /home/<you> (or /Users/<you>)
```

- **Teardown command:** none yet — the lab folder is removed in section 9. (Ubuntu on WSL stays installed for the whole course.)
- **Cost note:** USD 0.

### Lab 2 — Files, folders and permissions

- **Region:** none.
- **Task:**

```bash
cd ~/p0-shell-lab
pwd                                    # where am I?
mkdir -p perms && cd perms
printf '#!/usr/bin/env bash\necho "backup done"\n' > backup.sh
ls -l backup.sh                        # -rw-r--r--  : no x anywhere
./backup.sh                            # bash: ./backup.sh: Permission denied
```

1. Make `backup.sh` runnable **by you only** — the smallest change that works (no `sudo`, no `777`).
2. Now a file owned by the wrong user. Create it as root (that's what a badly written install script does), then try to write to it:

```bash
sudo touch report.txt
echo "line 1" >> report.txt            # bash: report.txt: Permission denied
ls -l report.txt                       # owner is root (Linux: group root too; macOS: group staff)
```

3. Fix it so **you** own it — with `chown` (this one needs `sudo`, because you're taking over a root-owned file). Don't change the permissions.

- **Expected result:** `./backup.sh` prints `backup done`; `echo "line 1" >> report.txt` succeeds.
- **Verification command:**

```bash
cd ~/p0-shell-lab/perms
./backup.sh                                            # backup done
stat -c '%A %U' backup.sh report.txt                   # macOS: stat -f '%Sp %Su' backup.sh report.txt
# expect: -rwxr--r-- <you>   and   -rw-r--r-- <you>
cat report.txt                                         # line 1
```

- **Teardown command:** `rm -rf ~/p0-shell-lab/perms`
- **Cost note:** USD 0.

### Lab 3 — Pipes and text tools

- **Region:** none.
- **Task:** `~/p0-shell-lab/text-tools/app.log` is a small web-server log. Each line is: time, level, method, path, status code, duration, and sometimes a message. Answer each question with **one command line**:

1. How many `ERROR` lines are there?
2. Which paths returned a 5xx status (500–599), and how many times each, most first?
3. Which requests took longer than 500 ms? Show time, path and duration.
4. Show the log with `db timeout` replaced by `database timeout` — **without changing the file**.
5. Save only the ERROR lines to `errors.txt`. Then add the WARN lines to the same file without losing the ERROR lines. Then run your first command again and explain what happened to the WARN lines.

Hints: `grep -c`, `awk '$5 >= 500 {print $4}'`, `sort`, `uniq -c`, `sort -rn`, `sed 's/old/new/'`, `>` vs `>>`. Use `man grep` (press `q` to quit) when stuck.

- **Expected result:**

```
4
      3 /orders
      1 /version
2026-11-17T09:00:09Z /orders 950ms
2026-11-17T09:00:55Z /health 610ms
```

For (4), two lines now say `database timeout` and `app.log` is unchanged. For (5), `errors.txt` has 6 lines after `>>`, and 4 again after re-running the `>` command — `>` replaced the file.

- **Verification command:**

```bash
cd ~/p0-shell-lab/text-tools
grep -c ' ERROR ' app.log                                         # 4
awk '$5 >= 500 {print $4}' app.log | sort | uniq -c | sort -rn    # 3 /orders, 1 /version
grep -c 'db timeout' app.log                                      # 2  (the file itself is unchanged)
```

- **Teardown command:** `rm -f ~/p0-shell-lab/text-tools/errors.txt`
- **Cost note:** USD 0.

### Lab 4 — Processes and services

- **Region:** none.
- **Task (all systems) — processes:**

```bash
sleep 300 &                       # start a process in the background
jobs                              # [1]+  Running   sleep 300 &
ps -o pid,stat,command -p $!      # $! is the PID of the last background process
kill %1                           # ask it to stop (signal TERM)
jobs                              # [1]+  Terminated   sleep 300
```

- **Task (Linux and WSL only) — a service with `systemctl`:** `cron` is the service that runs scheduled jobs. Check it, stop it, prove it stopped, start it again:

```bash
systemctl status cron --no-pager | head -3     # Active: active (running)
sudo systemctl stop cron
systemctl is-active cron                       # inactive
sudo systemctl start cron
systemctl is-active cron                       # active
```

> **macOS:** there's no `systemctl`. macOS manages services with **launchd**; `launchctl list | head` shows loaded services. Read the commands above and the self-check question on services — **this part isn't required to pass the module's gate**.

- **Expected result:** the background `sleep` is terminated; on Linux/WSL, `cron` goes `inactive` then `active`.
- **Verification command:** `pgrep -x sleep || echo "no sleep running"` → `no sleep running`; Linux/WSL: `systemctl is-active cron` → `active`.
- **Teardown command:** none — `cron` is running again, as it was. (If you stopped it and forgot: `sudo systemctl start cron`.)
- **Cost note:** USD 0.

### Lab 5 — Environment variables and start-up files

- **Region:** none.
- **Task:**

```bash
GREETING=hello
echo "$GREETING"                                  # hello — the shell knows it
bash -c 'echo "child sees: ${GREETING:-nothing}"' # child sees: nothing
export GREETING
bash -c 'echo "child sees: ${GREETING:-nothing}"' # child sees: hello
```

Now make a setting that survives closing the terminal. Add one line to your start-up file, marked so you can find and remove it later:

```bash
echo 'export COURSE_HOME="$HOME/aws-devops-course"  # p0-shell-lab' >> ~/.bashrc
# macOS (zsh): echo 'export COURSE_HOME="$HOME/aws-devops-course"  # p0-shell-lab' >> ~/.zshrc
```

Open a **new** terminal window and run `echo "$COURSE_HOME"`.

- **Expected result:** the child process sees `GREETING` only after `export`; the new terminal prints `/home/<you>/aws-devops-course` (macOS: `/Users/<you>/…`).
- **Verification command:**

```bash
bash -ic 'echo "$COURSE_HOME"'          # macOS: zsh -ic 'echo "$COURSE_HOME"'
# expect: the path above
```

- **Teardown command:** section 9 removes the marked line (`sed -i '/# p0-shell-lab/d' ~/.bashrc`).
- **Cost note:** USD 0.

### Lab 6 — Install Docker and SSH into a container

- **Region:** none.
- **Task:**

**6a. Install Docker.**

**Linux and Windows (inside Ubuntu/WSL 2):** install **Docker Engine** natively in Ubuntu — not Docker Desktop. The course pins Ubuntu's `docker.io` package version:

```bash
sudo apt-get install -y docker.io=29.1.3-0ubuntu3~24.04.2
sudo usermod -aG docker "$USER"     # let your user run docker without sudo (see the security note in Concepts)
newgrp docker                       # apply the new group in this terminal (or open a new one)
docker version --format 'client {{.Client.Version}} / server {{.Server.Version}}'
# expect: client 29.1.3 / server 29.1.3
```

If `apt` says that exact version isn't available (Ubuntu replaces older builds over time), run `apt-cache policy docker.io`, install the version it lists, and **write that version down** in your notes.

**macOS:** install **Docker Desktop 4.99.0** — download that exact version from its entry in the release notes, https://docs.docker.com/desktop/release-notes/ (the main install page only offers the newest build). Choose Apple silicon or Intel, open the `.dmg`, drag Docker to Applications, start it once and accept the terms (UI as of 2026-11-17), then run `docker version` in Terminal. Install steps: https://docs.docker.com/desktop/setup/install/mac-install/

> **macOS note:** Docker Desktop runs containers inside a small Linux virtual machine. Containers behave the same, but some networking output (`docker network inspect`, host networking, IP addresses you see from macOS) differs from Linux. This course's labs are written against Linux behaviour; callouts like this one mark the differences.

**6b. Make an SSH key just for this lab.**

```bash
mkdir -p ~/.ssh && chmod 700 ~/.ssh
ssh-keygen -t ed25519 -N "" -C "p0-lab" -f ~/.ssh/p0_lab_ed25519
ls -l ~/.ssh/p0_lab_ed25519 ~/.ssh/p0_lab_ed25519.pub
# expect: -rw------- for the private key, -rw-r--r-- for the .pub
```

(`-N ""` means no passphrase — acceptable only for a throw-away lab key. Keys you keep should have one.)

**6c. Start a throw-away Ubuntu container with an SSH server.**

```bash
docker run -d --name p0-ssh -p 127.0.0.1:2222:22 ubuntu:noble-20261110 sleep infinity
docker exec p0-ssh bash -c 'apt-get update -qq && DEBIAN_FRONTEND=noninteractive apt-get install -y -qq --no-install-recommends openssh-server=1:9.6p1-3ubuntu13.20 && mkdir -p /run/sshd /root/.ssh && chmod 700 /root/.ssh'
docker cp ~/.ssh/p0_lab_ed25519.pub p0-ssh:/root/.ssh/authorized_keys
docker exec p0-ssh bash -c 'chown root:root /root/.ssh/authorized_keys && chmod 600 /root/.ssh/authorized_keys && /usr/sbin/sshd'
```

What this does: starts the container in the background (`-d`), publishes its SSH port 22 on **your machine's port 2222, reachable only from your machine** (`127.0.0.1:`), installs the SSH server inside it (pinned version — if `apt` says it isn't available, Ubuntu has replaced it: run `docker exec p0-ssh apt-cache policy openssh-server`, use the listed version and write it down), installs your **public** key, and starts the server. The image tag `noble-20261110` is an exact, dated Ubuntu 24.04 build — never `latest`.

**6d. See SSH refuse a badly protected key, then connect.**

```bash
chmod 644 ~/.ssh/p0_lab_ed25519
ssh -i ~/.ssh/p0_lab_ed25519 -p 2222 root@127.0.0.1
# 1st time: SSH shows the host key fingerprint and asks "Are you sure you want to continue connecting (yes/no)?" → type yes
# then: WARNING: UNPROTECTED PRIVATE KEY FILE! … and it asks for a password → press Ctrl+C
chmod 600 ~/.ssh/p0_lab_ed25519
ssh -i ~/.ssh/p0_lab_ed25519 -p 2222 root@127.0.0.1 'hostname; grep PRETTY_NAME /etc/os-release'
```

- **Expected result:** with `644`, SSH warns `UNPROTECTED PRIVATE KEY FILE!` and ignores the key; with `600`, you're in. The last command prints the container's ID as its hostname and `PRETTY_NAME="Ubuntu 24.04.5 LTS"`.
- **Verification command:**

```bash
docker ps --filter name=p0-ssh --format '{{.Names}} {{.Status}}'   # p0-ssh Up …
ssh-keygen -F '[127.0.0.1]:2222' | head -1                          # # Host [127.0.0.1]:2222 found: line N
# (Ubuntu stores known_hosts entries hashed — HashKnownHosts yes — so grep can't find them; ssh-keygen -F can.)
```

- **Teardown command:**

```bash
docker rm -f p0-ssh
docker image rm ubuntu:noble-20261110
ssh-keygen -R '[127.0.0.1]:2222'              # forget the throw-away container's host key
rm -f ~/.ssh/known_hosts.old                  # -R keeps a backup that still contains the removed entry
rm -f ~/.ssh/p0_lab_ed25519 ~/.ssh/p0_lab_ed25519.pub
docker ps -a --filter name=p0-ssh --format '{{.Names}}'   # expect: no output
ssh-keygen -F '[127.0.0.1]:2222' || echo "host key removed"   # expect: host key removed
```

Docker itself stays installed — don't remove it.

- **Cost note:** USD 0.

## 7. Debugging lab

- **Scenario:** a teammate's `deploy.sh` "works on my machine" when they `cd` into its folder and run it. The scheduler that runs it every night fails. `run.sh` reproduces exactly how the scheduler calls it: **from another folder, by executing the file directly.**
- **How to create the broken state:** the files are already in your lab folder (from Lab 1):

```bash
cd ~/p0-shell-lab/debug-deploy
ls -R                                  # deploy.sh  run.sh  config/settings.env  scripts/render.sh
./run.sh
```

- **Symptom you will see** (Ubuntu / WSL / Linux):

```
/home/<you>/p0-shell-lab/debug-deploy/deploy.sh: 1: set: Illegal option -o pipefail
exit code: 2
```

> **macOS:** there, `/bin/sh` is a version of bash, so this first error doesn't appear — you go straight to the second problem. Fix the first one anyway: on any Linux server, it would fail.

- **Your task:** there are **three** separate bugs in `deploy.sh`. Fix one at a time, running `./run.sh` after each fix — each fix reveals the next error. Don't change `run.sh` or `scripts/render.sh`. For each bug, write **one sentence** explaining *why* it broke: (a) what the system did, (b) why it worked when your teammate ran it by hand.
- **Done when:**

```bash
cd ~/p0-shell-lab/debug-deploy
./run.sh
# expect:
#   rendered for staging
#   deploy finished for staging (orders-api)
#   exit code: 0
cat out/config.txt                     # rendered for staging
head -1 deploy.sh                      # #!/usr/bin/env bash
```

- **Teardown:** `rm -rf ~/p0-shell-lab/debug-deploy/out` (the whole lab folder goes in section 9).

The diagnosis path and model explanations are in `solutions/debugging-lab.md`.

## 8. Self-check

Answers: `solutions/self-check.md`.

1. `set -euo pipefail`: what does each of `-e`, `-u` and `-o pipefail` do? Give one bug each one catches.
2. What's the difference between `>` and `>>`? Which one did you use to build `errors.txt` in Lab 3, and why did the WARN lines disappear?
3. In Lab 2, why would `chmod 777 report.txt` *not* have fixed the real problem, and what did?
4. Run the command that proves a variable reaches a child process. What does `export` change?
5. Why did SSH refuse your private key at `644` but accept it at `600`?
6. A script works when you `cd` into its folder, but fails from cron. Name two likely causes.
7. *(Linux/WSL)* Show the command that tells you whether a service is running, and the one that stops it. Why do you need `sudo` for one and not the other?

## 9. Teardown

```bash
# Lab 6 (if not done already)
docker rm -f p0-ssh 2>/dev/null
docker image rm ubuntu:noble-20261110 2>/dev/null
ssh-keygen -R '[127.0.0.1]:2222' 2>/dev/null
rm -f ~/.ssh/known_hosts.old ~/.ssh/p0_lab_ed25519 ~/.ssh/p0_lab_ed25519.pub

# Lab 5: remove the marked start-up line
sed -i '/# p0-shell-lab/d' ~/.bashrc
# macOS: sed -i '' '/# p0-shell-lab/d' ~/.zshrc

# Everything else
rm -rf ~/p0-shell-lab
```

**Confirm nothing is left:**

```bash
docker ps -a --filter name=p0-ssh --format '{{.Names}}'          # expect: no output
docker image ls ubuntu:noble-20261110 --format '{{.Tag}}'        # expect: no output
ls ~/p0-shell-lab 2>&1                                            # expect: No such file or directory
ls ~/.ssh/p0_lab_ed25519 ~/.ssh/p0_lab_ed25519.pub 2>&1          # expect: No such file or directory (twice)
ssh-keygen -F '[127.0.0.1]:2222' || echo "host key removed"      # expect: host key removed
grep -c '# p0-shell-lab' ~/.bashrc                                # expect: 0   (macOS: ~/.zshrc)
```

Kept on purpose: Ubuntu on WSL, Docker, your membership of the `docker` group, and the `~/aws-devops-course` clone — keep them installed.

If you're stopping the course here, undo the `docker` group membership (it grants root-level access): `sudo gpasswd -d "$USER" docker`, then open a new terminal; `id -nG | grep -cw docker` → `0`.

## 10. Last verified

- **Date:** NOT YET VERIFIED BY A HUMAN — drafted 2026-11-17. (`lastVerified: null`; only a human who runs every command may set it.)
- **Verified by:** —
- **Region:** none (no AWS resources).
- **Versions:** Ubuntu 24.04 on WSL 2 (`wsl --install -d Ubuntu-24.04` installs the current 24.04.x point release, so front-matter uses the minor-version exception `ubuntuWslMinorVersion`; **record the point release** from `grep VERSION= /etc/os-release` on the verification run — the author's machine shows 24.04.1) · bash 5.2.21 · `docker.io` 29.1.3-0ubuntu3~24.04.2 · Docker Desktop 4.99.0 (macOS) · image `ubuntu:noble-20261110` (digest `sha256:73b999393d07f2bf65a40373778a44dc9a6d54ad7718d29247d8ff9413c4d6a8`) · `openssh-server` 1:9.6p1-3ubuntu13.20 (inside the container, pinned).
- **Notes (author and review-agent dry-runs, not a verification):** the labs review agent also re-ran Labs 3, 5, 6d and the debugging lab and confirmed the outputs. Earlier: on Ubuntu 24.04.1 / WSL 2 on 2026-11-17, the author ran Lab 3's commands against `app.log`, Lab 6c–6d with a scratch key (the `UNPROTECTED PRIVATE KEY FILE` warning at 644, a successful login at 600, `Ubuntu 24.04.5 LTS`, clean teardown), and the debugging lab's three failures and fixed run. `cron` was confirmed active under systemd. Not run: the WSL install itself, Lab 2's `sudo` steps, Lab 5, macOS, Docker Desktop.
