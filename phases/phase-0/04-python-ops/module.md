---
phase: "phase-0"
moduleId: "0.4"
title: "Python for ops"
goal: "Automate a small, boring task and log it properly."
timeEstimate: "8-10h"
costEstimate: "<$0.01"
costAssumptions: "us-east-1, author's prices 2026-11-18 (not yet checked); the S3 ListBuckets calls in Lab 6 are a handful of requests (fractions of a cent); IAM has no charge; if you skip teardown ≈ $0/day, but a leftover IAM access key is a security risk, so teardown is graded"
lastVerified: null
prerequisites: ["0.0", "0.1", "0.3"]
hasDebuggingLab: true
hasTeardown: true
toolsPinned:
  "python3": "3.12.3-0ubuntu2.1"
  "python3-venv": "3.12.3-0ubuntu2.1"
  "requests": "2.34.2"
  "boto3": "1.44.4"
  "git-filter-repo": "2.47.0"
  "awscli": "2.33.14"
  "git": "2.43.0"
---

# Phase 0 · Module 0.4 — Python for ops

## 1. Goal

Automate a small, boring task and log it properly.

## 2. Prerequisites

- **Modules:** [0.0 Account safety & billing guardrails](../00-account-safety/module.md) (your AWS account, the admin user and `aws login`), [0.1 Linux & the shell](../01-linux-shell/module.md) (shell, environment variables, paths) and [0.3 Git & GitHub workflows](../03-git-github/module.md) (Lab 7 rewrites Git history).
- **Tools installed:** AWS CLI v2 and the `p0-admin` profile (from 0.0), `git` (from 0.3) and Python **3.12** (check: `python3 --version` prints `Python 3.12.x`). Ubuntu 24.04 and WSL ship 3.12. On macOS, if yours isn't 3.12, install it from https://www.python.org/downloads/ and use `python3.12` wherever this module says `python3`.
- **Access:** your AWS account, signed in with `export AWS_PROFILE=p0-admin` and `aws login --profile p0-admin` (from 0.0). Labs 1–5 and 7 use no AWS at all.
- Update the course clone for the lab files: `git -C ~/aws-devops-course pull`.

## 3. Time estimate

**8–10 hours.**

| Lab | Time |
|---|---|
| 1 — A small CLI (includes the setup) | 1.5 h |
| 2 — Call an API with `requests` | 1.5 h |
| 3 — Logging with levels | 1 h |
| 4 — `try/except` for real failures | 1.5 h |
| 5 — `subprocess` | 1 h |
| 6 — List S3 buckets read-only (IAM user, key, teardown) | 1.5–2 h |
| 7 — Rewrite Git history to remove a leaked secret | 1 h |
| Debugging lab | 1 h |

## 4. Cost estimate

**Under USD 0.01.** Labs 1–5 and 7 run only on your computer. Lab 6 makes a handful of S3 `ListBuckets` requests and creates one IAM user, which has no charge.

| Resource | Billed while idle? | Unit price (assumption) | Expected use | Cost |
|---|---|---|---|---|
| Python, `pip` packages, Git | no | free | all labs | USD 0 |
| S3 `ListBuckets` requests | no (per request) | fractions of a cent per 1,000 requests; not yet checked against https://aws.amazon.com/s3/pricing/ | under 20 requests | < USD 0.01 |
| IAM user `p0-readonly` + its access key | no | no charge for IAM | Lab 6 | USD 0 |

- **Pricing assumptions:** `us-east-1`; no free tier assumed; prices are the author's figures as of 2026-11-18 and not yet checked against the pricing page above.
- **Total if you follow the teardown steps:** under USD 0.01.
- **If you skip teardown: USD 0/day, but it is not safe.** A leftover access key sits in a file on your computer and is valid until you delete it. The teardown step that removes it is **graded**.

## 5. Concepts

### Virtual environments and pinned requirements

- **Problem it solves:** two projects may need different versions of the same library, and installing everything into the system Python eventually breaks something. Worse, "it works on my machine" is often just "my machine has different versions".
- **How it works:** a **virtual environment** (`python3 -m venv .venv`) is a private folder holding its own Python and its own installed packages. You *activate* it (`source .venv/bin/activate`) and `pip install` goes there, not into the system. A **`requirements.txt`** lists the packages, each **pinned** to an exact version (`requests==2.34.2`), so anyone who installs it gets the same code. One venv per project.
- **The command that shows it:** `which python` (inside the venv it points into `.venv`), `pip list`.
- **Applied in:** Lab 1.
- **Source:** https://docs.python.org/3/library/venv.html

### Scripts, functions, files and the command line

- **Problem it solves:** ops work is mostly small repeatable tasks ("read this file, call that service, report"). A script makes the task repeatable; a **command-line interface** (CLI) makes it reusable without editing the code.
- **How it works:** a function does one job (`read_inventory(path)`). `with open(path) as f:` opens a file and closes it for you. `argparse` turns `python3 tool.py inventory.csv --env prod` into values your code can use, and writes `--help` for free. The `if __name__ == "__main__":` line at the bottom means "run `main()` only when this file is run directly, not when it's imported".
- **The command that shows it:** `python3 tool.py --help`.
- **Applied in:** Lab 1.

### Calling an API with `requests`

- **Problem it solves:** services talk over HTTP (module 0.2). Your script needs to make the same request `curl` makes and act on the answer.
- **How it works:** `requests.get(url, timeout=3)` sends the request and returns a response with `.status_code`, `.text` and `.json()`. **Always set a `timeout`.** Without one, a server that never answers makes your script wait forever.
- **The command that shows it:** the same call with `curl -sS -o /dev/null -w '%{http_code}\n' <url>` (0.2).
- **Applied in:** Lab 2.
- **Source:** https://requests.readthedocs.io/en/latest/user/quickstart/

### Logging instead of printing

- **Problem it solves:** `print` has no severity, no timestamp, and goes wherever stdout goes. When a script runs at 3 a.m. from a scheduler, a log with times and severities is the only way to find out what happened.
- **How it works:** the `logging` module gives each message a **level**: `DEBUG` (detail for debugging), `INFO` (normal progress), `WARNING` (something odd but handled), `ERROR` (something failed), `CRITICAL`. You choose the minimum level to show, and send messages to several places at once (the screen and a file). Format them with a timestamp.
- **The command that shows it:** `cat ops_check.log`; and `grep ERROR ops_check.log` to find what failed.
- **Applied in:** Lab 3.
- **Source:** https://docs.python.org/3/howto/logging.html

### Exceptions: failing on purpose, and clearly

- **Problem it solves:** real systems fail: servers answer 500, files are missing, networks time out. A script that crashes with a 40-line traceback on the first problem is hard to run unattended; one that ignores errors silently is worse.
- **How it works:** `try:` runs code; `except SomeError:` handles one *specific* kind of failure. Catch the specific errors you can do something about, log them **with context** (which URL? which file?), and make the program's **exit code** tell the truth: `0` means success, anything else means failure, and schedulers and CI systems read exactly that. Reading a **traceback**: start at the *bottom* (the error type and message), then walk up to the last line that belongs to *your* file.
- **The command that shows it:** `echo $?` right after a command prints its exit code.
- **Applied in:** Lab 4.
- **Source:** https://docs.python.org/3/tutorial/errors.html

### Running other programs with `subprocess`

- **Problem it solves:** sometimes the tool you need is a command, not a Python library.
- **How it works:** `subprocess.run(["uname", "-sr"], check=True, capture_output=True, text=True)` runs the command, captures its output as text, and with `check=True` raises an error if it exits non-zero. Pass the command as a **list**, never as one string with `shell=True`: if any part of that string comes from outside, someone can inject extra commands. **When it's the wrong tool:** if a library already does the job (`requests` instead of calling `curl`, `boto3` instead of calling `aws`), use the library: you get real errors and structured data instead of text to parse.
- **The command that shows it:** run the command by hand first, and look at its exit code with `echo $?`.
- **Applied in:** Lab 5.
- **Source:** https://docs.python.org/3/library/subprocess.html

### Credentials never go in code

- **Problem it solves:** anything in a script ends up in Git (0.3) and in chat messages, screenshots and backups. A key in code is a leaked key.
- **How it works:** the AWS SDK (`boto3`) looks for credentials itself, in a fixed order: environment variables, then a named profile in `~/.aws/credentials`, then (on AWS) a role attached to the machine. Your code never mentions a key; it just creates a client. That makes the same script work on your laptop and, later, on a server with a role.
- **The command that shows it:** `aws configure list --profile <name>` shows where a profile's credentials come from, and `aws sts get-caller-identity --profile <name>` shows who you are acting as.
- **Applied in:** Lab 6.
- **Source:** https://boto3.amazonaws.com/v1/documentation/api/latest/guide/credentials.html

## 6. Labs

> **Region:** Labs 1–5 and 7 use no AWS. Lab 6 uses `us-east-1`.
>
> **Where to type commands:** your Linux shell from 0.1. Lines starting with `#` are comments. Work in your home folder (on WSL, never under `/mnt/c/...`).
>
> **Editing files:** use any editor. In the terminal, `nano <file>` works (save with Ctrl+O, Enter; quit with Ctrl+X). The finished version of every script is also in the course folder `phases/phase-0/04-python-ops/solutions/`, so you can compare, but type them yourself first.

### Lab 1 — A small CLI

- **Region:** none.
- **Task:** set up a project folder with its own virtual environment, then write a script that reads a CSV file and takes command-line options.

```bash
# Ubuntu / WSL only: Python's venv module is a separate package
sudo apt-get install -y python3-venv=3.12.3-0ubuntu2.1

mkdir -p ~/p0-python-lab
cp -r ~/aws-devops-course/phases/phase-0/04-python-ops/labs/. ~/p0-python-lab/
cd ~/p0-python-lab
ls                                   # inventory.csv  policy.json  requirements.txt  stub_api.py  urls.txt  debug-report

python3 -m venv .venv
source .venv/bin/activate            # your prompt now starts with (.venv)
python -m pip install -r requirements.txt
which python && pip list | grep -iE "^(requests|boto3) "
```

Now create `lab1_cli.py`:

```python
#!/usr/bin/env python3
"""List the servers in an inventory CSV, optionally only one environment."""
import argparse
import csv


def read_inventory(path):
    with open(path, newline="") as f:
        return list(csv.DictReader(f))


def main():
    parser = argparse.ArgumentParser(description="List servers from an inventory CSV.")
    parser.add_argument("inventory", help="path to the CSV file")
    parser.add_argument("--env", help="only show servers in this environment")
    args = parser.parse_args()

    servers = read_inventory(args.inventory)
    if args.env:
        servers = [s for s in servers if s["env"] == args.env]

    for s in servers:
        print(f'{s["name"]}\t{s["env"]}\t{s["port"]}')
    print(f"{len(servers)} server(s)")


if __name__ == "__main__":
    main()
```

Run it a few ways, and read `--help`:

```bash
python lab1_cli.py inventory.csv
python lab1_cli.py inventory.csv --env prod
python lab1_cli.py --help
```

- **Expected result:** `which python` points into `~/p0-python-lab/.venv/bin/`; `pip list` shows `requests 2.34.2` and `boto3 1.44.4`. The three runs print 4 servers, then 3 `prod` servers, then the usage text.
- **Verification command:**

```bash
cd ~/p0-python-lab && source .venv/bin/activate
python lab1_cli.py inventory.csv --env prod | tail -1       # expect: 3 server(s)
python lab1_cli.py inventory.csv --env staging | tail -1    # expect: 1 server(s)
```

- **Teardown command:** none yet (the whole folder is removed in section 9). Remember to run `source .venv/bin/activate` in every new terminal.
- **Cost note:** USD 0.

### Lab 2 — Call an API with `requests`

- **Region:** none.
- **Task:** write a script that checks a list of URLs. To make "the server returns 500" happen **every time**, the course gives you a tiny fake API, `stub_api.py`. Start it in a **second terminal** and leave it running:

```bash
# terminal 2
cd ~/p0-python-lab && source .venv/bin/activate
python stub_api.py                   # stub API on http://127.0.0.1:8000   (Ctrl+C to stop)
```

Back in terminal 1, check it with `curl` first (the tool you know from 0.2):

```bash
curl -sS -w '  [status %{http_code}]\n' http://127.0.0.1:8000/health    # {"status":"ok"}  [status 200]
curl -sS -w '  [status %{http_code}]\n' http://127.0.0.1:8000/flaky     # {"error":"boom"}  [status 500]
```

Now create `lab2_check.py`, the same requests, from Python:

```python
#!/usr/bin/env python3
"""Check a list of URLs and print the HTTP status of each."""
import argparse

import requests


def read_urls(path):
    with open(path) as f:
        return [line.strip() for line in f if line.strip() and not line.startswith("#")]


def main():
    parser = argparse.ArgumentParser(description="Print the HTTP status of each URL in a file.")
    parser.add_argument("urls_file", help="text file with one URL per line")
    parser.add_argument("--timeout", type=float, default=3.0, help="seconds to wait for each URL")
    args = parser.parse_args()

    for url in read_urls(args.urls_file):
        response = requests.get(url, timeout=args.timeout)
        print(response.status_code, url)


if __name__ == "__main__":
    main()
```

```bash
cat urls.txt
python lab2_check.py urls.txt
```

- **Expected result:** the first two lines print `200 http://127.0.0.1:8000/health` and `500 http://127.0.0.1:8000/flaky`. Then, after 3 seconds, the script **crashes** with a long traceback ending `requests.exceptions.ReadTimeout`, because `/slow` takes 5 seconds and your timeout is 3. That crash is deliberate: Lab 4 fixes it. Also try the public internet once (illustrative only; nothing is graded on it):

```bash
echo "https://checkip.amazonaws.com" > one.txt
python lab2_check.py one.txt         # 200 https://checkip.amazonaws.com
```

- **Verification command:**

```bash
python lab2_check.py urls.txt 2>&1 | grep -cE '^(200|500) '      # expect: 2
python lab2_check.py urls.txt 2>&1 | tail -1 | cut -d: -f1        # expect: requests.exceptions.ReadTimeout
```

- **Teardown command:** none yet. Leave `stub_api.py` running for Labs 3–5.
- **Cost note:** USD 0.

### Lab 3 — Logging with levels

- **Region:** none.
- **Task:** replace `print` with logging, sending messages to the screen **and** a file, with a `--verbose` switch for `DEBUG` detail. Create `lab3_check.py`:

```python
#!/usr/bin/env python3
"""Check a list of URLs and log what happened."""
import argparse
import logging
import sys

import requests

log = logging.getLogger("ops_check")


def setup_logging(log_file, verbose):
    formatter = logging.Formatter("%(asctime)s %(levelname)-7s %(message)s")
    handlers = [logging.StreamHandler(sys.stderr), logging.FileHandler(log_file)]
    for handler in handlers:
        handler.setFormatter(formatter)
        log.addHandler(handler)
    log.setLevel(logging.DEBUG if verbose else logging.INFO)


def read_urls(path):
    with open(path) as f:
        return [line.strip() for line in f if line.strip() and not line.startswith("#")]


def main():
    parser = argparse.ArgumentParser(description="Log the HTTP status of each URL in a file.")
    parser.add_argument("urls_file", help="text file with one URL per line")
    parser.add_argument("--timeout", type=float, default=3.0, help="seconds to wait for each URL")
    parser.add_argument("--log-file", default="ops_check.log", help="where to write the log")
    parser.add_argument("--verbose", action="store_true", help="also log DEBUG messages")
    args = parser.parse_args()
    setup_logging(args.log_file, args.verbose)

    urls = read_urls(args.urls_file)
    log.info("checking %d URL(s) from %s", len(urls), args.urls_file)
    for url in urls:
        log.debug("GET %s (timeout %.1fs)", url, args.timeout)
        response = requests.get(url, timeout=args.timeout)
        if response.ok:
            log.info("%s -> %d", url, response.status_code)
        else:
            log.warning("%s -> %d", url, response.status_code)


if __name__ == "__main__":
    main()
```

```bash
python lab3_check.py urls.txt --timeout 2
cat ops_check.log
python lab3_check.py urls.txt --timeout 2 --verbose 2>&1 | grep DEBUG
```

- **Expected result:** each message has a timestamp and a level: `INFO  http://127.0.0.1:8000/health -> 200`, then `WARNING http://127.0.0.1:8000/flaky -> 500`. The `/slow` URL still crashes the script (not handled yet), but everything logged before the crash is in `ops_check.log`. The `--verbose` run adds `DEBUG GET …` lines.
- **Verification command:**

```bash
grep -c INFO ops_check.log           # expect: 2 or more
grep -c WARNING ops_check.log        # expect: 1 or more
python lab3_check.py urls.txt --timeout 2 --verbose 2>&1 | grep -c DEBUG    # expect: 3 or more
```

- **Teardown command:** none yet.
- **Cost note:** USD 0.

### Lab 4 — `try/except` for real failures

- **Region:** none.
- **Task:** handle the failures you have seen so far: a timeout, a refused connection, and a missing file. Log each **with context**, and make the **exit code** truthful. Create `lab4_check.py`:

```python
#!/usr/bin/env python3
"""Check a list of URLs, log what happened, and exit non-zero if anything is wrong.

Exit codes: 0 = all healthy, 1 = at least one URL unhealthy or unreachable, 2 = couldn't read the URL file.
"""
import argparse
import logging
import os
import sys

import requests

log = logging.getLogger("ops_check")


def setup_logging(log_file, verbose):
    formatter = logging.Formatter("%(asctime)s %(levelname)-7s %(message)s")
    handlers = [logging.StreamHandler(sys.stderr), logging.FileHandler(log_file)]
    for handler in handlers:
        handler.setFormatter(formatter)
        log.addHandler(handler)
    log.setLevel(logging.DEBUG if verbose else logging.INFO)


def read_urls(path):
    with open(path) as f:
        return [line.strip() for line in f if line.strip() and not line.startswith("#")]


def check(url, timeout):
    """Return True if the URL answered with a 2xx/3xx status; log the reason if not."""
    try:
        response = requests.get(url, timeout=timeout)
    except requests.exceptions.Timeout:
        log.error("%s -> no answer within %.1fs (timeout)", url, timeout)
        return False
    except requests.exceptions.ConnectionError as exc:
        log.error("%s -> could not connect: %s", url, exc)
        return False
    if response.ok:
        log.info("%s -> %d", url, response.status_code)
        return True
    log.warning("%s -> %d (body: %s)", url, response.status_code, response.text[:80])
    return False


def main():
    parser = argparse.ArgumentParser(description="Check each URL in a file.")
    parser.add_argument("urls_file", help="text file with one URL per line")
    parser.add_argument("--timeout", type=float, default=3.0, help="seconds to wait for each URL")
    parser.add_argument("--log-file", default="ops_check.log", help="where to write the log")
    parser.add_argument("--verbose", action="store_true", help="also log DEBUG messages")
    args = parser.parse_args()
    setup_logging(args.log_file, args.verbose)

    try:
        urls = read_urls(args.urls_file)
    except FileNotFoundError:
        log.error("URL file not found: %s (current folder: %s)", args.urls_file, os.getcwd())
        return 2

    log.info("checking %d URL(s) from %s", len(urls), args.urls_file)
    failures = sum(1 for url in urls if not check(url, args.timeout))
    log.info("done: %d ok, %d failed", len(urls) - failures, failures)
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
```

```bash
python lab4_check.py urls.txt --timeout 2; echo "exit code: $?"
python lab4_check.py nope.txt;            echo "exit code: $?"
printf 'http://127.0.0.1:8000/health\n' > ok.txt
python lab4_check.py ok.txt;              echo "exit code: $?"
printf 'http://127.0.0.1:9/health\n' > refused.txt
python lab4_check.py refused.txt;         echo "exit code: $?"
```

- **Expected result:**
  - `urls.txt`: `INFO … /health -> 200`, `WARNING … /flaky -> 500 (body: {"error":"boom"})`, `ERROR … /slow -> no answer within 2.0s (timeout)`, then `done: 1 ok, 2 failed` and **exit code 1**. No traceback.
  - `nope.txt`: `ERROR URL file not found: nope.txt (current folder: …)` and **exit code 2**.
  - `ok.txt`: **exit code 0**.
  - `refused.txt`: an `ERROR … could not connect` line and **exit code 1**.
- **Verification command:**

```bash
python lab4_check.py ok.txt 2>/dev/null; echo $?                  # expect: 0
python lab4_check.py urls.txt --timeout 2 2>/dev/null; echo $?    # expect: 1
python lab4_check.py nope.txt 2>/dev/null; echo $?                # expect: 2
```

- **Teardown command:** none yet.
- **Cost note:** USD 0.

### Lab 5 — `subprocess`

- **Region:** none.
- **Task:** add a helper that runs a shell command safely, and log which machine a check ran on (useful in a log that many machines write to). Copy your Lab 4 script to `lab5_check.py` and make three changes. First add `import subprocess` next to the other imports. Then add this function just above `check(...)`:

```python
def run_command(args):
    """Run a command (a list, never a shell string), return its output, and log failures with context."""
    try:
        result = subprocess.run(args, check=True, capture_output=True, text=True)
    except FileNotFoundError:
        log.error("command not found: %s", args[0])
        return None
    except subprocess.CalledProcessError as exc:
        log.error("command %s failed with exit code %d: %s", args, exc.returncode, exc.stderr.strip())
        return None
    return result.stdout.strip()
```

And in `main()`, add this line just before the `log.info("checking …")` line:

```python
    log.info("running on: %s", run_command(["uname", "-sr"]))
```

Then try both the working and the failing paths of the helper:

```bash
python lab5_check.py ok.txt; echo "exit code: $?"
python - <<'PY'
import logging, sys
from lab5_check import run_command, log
logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")
log.addHandler(logging.StreamHandler(sys.stdout)); log.setLevel(logging.INFO)
print("works   ->", run_command(["uname", "-s"]))
print("fails   ->", run_command(["ls", "/definitely-missing"]))
print("missing ->", run_command(["no-such-command"]))
PY
```

- **Expected result:** the first run logs `running on: Linux <kernel version>` (or `Darwin …` on a Mac) and exits 0. The helper prints `works -> Linux`, then logs `ERROR command ['ls', '/definitely-missing'] failed with exit code 2: ls: cannot access …` and `fails -> None`, then `ERROR command not found: no-such-command` and `missing -> None`.
- **Verification command:**

```bash
python lab5_check.py ok.txt 2>&1 | grep -c "running on:"      # expect: 1
python lab5_check.py ok.txt >/dev/null 2>&1; echo $?            # expect: 0
```

- **Teardown command:** stop the stub API: press **Ctrl+C** in terminal 2. Confirm: `curl -s -m 2 http://127.0.0.1:8000/health || echo "stub stopped"` prints `stub stopped`.
- **Cost note:** USD 0.

### Lab 6 — List S3 buckets read-only, and log the result

- **Region:** `us-east-1`.
- **Task:** write a script that uses the AWS SDK, using an identity that can do **only** one thing: list bucket names. Then delete that identity.

> **Why a key here, when 0.0 avoided keys?** Module 0.0 avoids long-lived access keys. This lab uses one **on purpose**: it is read-only, limited to listing bucket names, and **deleted before you finish the lab**. You'll see how the SDK finds credentials without them ever appearing in code. In later modules, roles replace keys entirely.

<!-- TODO(verify) / TODO(revisit): if boto3 1.44.4 (or the version pinned at the time) is confirmed in its official docs to support the `aws login` credential provider, replace the access key with an `aws login` profile. Do not write a lab against that capability until it is verified. -->

**1. Create the identity.** Sign in as your admin (`export AWS_PROFILE=p0-admin`; `aws login --profile p0-admin` if your session has expired), then:

```bash
cd ~/p0-python-lab && source .venv/bin/activate
export AWS_PROFILE=p0-admin AWS_REGION=us-east-1
cat policy.json                      # one statement: Allow s3:ListAllMyBuckets on *

aws iam create-user --user-name p0-readonly \
  --tags Key=course,Value=aws-devops-platform Key=phase,Value=0
aws iam put-user-policy --user-name p0-readonly \
  --policy-name p0-list-buckets --policy-document file://policy.json
```

**2. Create a key and store it as a named profile**, without ever printing it:

```bash
read -r KEY_ID SECRET < <(aws iam create-access-key --user-name p0-readonly \
  --query 'AccessKey.[AccessKeyId,SecretAccessKey]' --output text)
aws configure set aws_access_key_id     "$KEY_ID" --profile p0-readonly
aws configure set aws_secret_access_key "$SECRET" --profile p0-readonly
aws configure set region us-east-1 --profile p0-readonly
unset KEY_ID SECRET
sleep 10                             # new IAM credentials can take a few seconds to work everywhere
aws sts get-caller-identity --profile p0-readonly --query Arn --output text
# expect: arn:aws:iam::<12-digit-account-id>:user/p0-readonly
```

**3. Write the script.** Create `lab6_s3_report.py`. Notice that no key appears anywhere in it:

```python
#!/usr/bin/env python3
"""Count the S3 buckets one AWS profile can see, and log the result. Credentials never appear in this file."""
import argparse
import logging
import sys

import boto3
from botocore.exceptions import BotoCoreError, ClientError

log = logging.getLogger("s3_report")


def main():
    parser = argparse.ArgumentParser(description="List S3 buckets (read-only) and log the count.")
    parser.add_argument("--profile", help="AWS CLI profile to use (default: the SDK's normal lookup)")
    args = parser.parse_args()
    logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)-7s %(message)s")

    try:
        session = boto3.Session(profile_name=args.profile)
        buckets = session.client("s3").list_buckets()["Buckets"]
    except (BotoCoreError, ClientError) as exc:
        log.error("could not list buckets: %s", exc)
        return 1

    log.info("found %d bucket(s)", len(buckets))
    for bucket in buckets:
        log.info("bucket: %s", bucket["Name"])
    return 0


if __name__ == "__main__":
    sys.exit(main())
```

```bash
unset AWS_PROFILE                    # so the script uses only what you pass it
python lab6_s3_report.py --profile p0-readonly
```

**4. Prove the identity is limited.** Each of these must be **refused**:

```bash
aws ec2 describe-vpcs --profile p0-readonly --region us-east-1 2>&1 | head -2
aws iam list-users    --profile p0-readonly 2>&1 | head -2
```

- **Expected result:** step 3 prints three or four log lines: boto's own `Found credentials in shared credentials file: ~/.aws/credentials` (that is the SDK finding the profile, with no key in your code), then `found N bucket(s)` and one `bucket: <name>` line per bucket (N may be 0 on a new account; that's fine). Step 4: `UnauthorizedOperation` for the EC2 call and `AccessDenied … is not authorized to perform: iam:ListUsers` for the IAM call.
- **Verification command:**

```bash
python lab6_s3_report.py --profile p0-readonly >/dev/null 2>&1; echo $?     # expect: 0
aws iam list-users --profile p0-readonly >/dev/null 2>&1; echo $?            # expect: 254 (AccessDenied) — non-zero is what matters
```

- **Teardown command (graded):** the key **must** be deactivated and deleted, then the policy and user, and the profile removed. Run it now, before Lab 7:

```bash
export AWS_PROFILE=p0-admin AWS_REGION=us-east-1
for k in $(aws iam list-access-keys --user-name p0-readonly --query 'AccessKeyMetadata[].AccessKeyId' --output text); do
  aws iam update-access-key --user-name p0-readonly --access-key-id "$k" --status Inactive
  aws iam delete-access-key --user-name p0-readonly --access-key-id "$k"
done
aws iam delete-user-policy --user-name p0-readonly --policy-name p0-list-buckets
aws iam delete-user --user-name p0-readonly

# remove the profile's lines from the two files the CLI wrote (Linux / WSL)
sed -i '/^\[p0-readonly\]$/,/^\[/{/^\[p0-readonly\]$/d;/^\[/!d}'             ~/.aws/credentials
sed -i '/^\[profile p0-readonly\]$/,/^\[/{/^\[profile p0-readonly\]$/d;/^\[/!d}' ~/.aws/config
# macOS: use  sed -i ''  instead of  sed -i
```

  **Graded check:**

```bash
aws iam get-user --user-name p0-readonly 2>&1 | grep -c NoSuchEntity     # expect: 1
aws configure list-profiles | grep -c p0-readonly                         # expect: 0
```

- **Cost note:** USD 0.

### Lab 7 — Rewrite Git history to remove a leaked secret

- **Region:** none.
- **Task:** in 0.3's debugging lab you found a secret in history and wrote down the remedy. Now carry out step (b) with the tool you named. In real life you would **first revoke the key**; here the key is AWS's documentation example, so skip that step, but never skip it for real.

```bash
cd ~/p0-python-lab && source .venv/bin/activate
python -m pip install git-filter-repo==2.47.0

# rebuild the 0.3 practice repo (0.3's teardown removed it)
bash ~/aws-devops-course/phases/phase-0/03-git-github/labs/debug-leaked-env/break.sh ~/p0-git-debug
```

`git filter-repo` refuses to rewrite a repository that isn't a **fresh clone**, because the rewrite can't be undone. Make one (the `--no-local` flag is needed only because this "remote" is a folder on your computer):

```bash
git clone --no-local ~/p0-git-debug/remote.git ~/p0-filter
cd ~/p0-filter
git log --all --oneline -- .env                    # 2 commits touch .env
git filter-repo --path .env --invert-paths         # rewrite every commit to leave .env out
git remote -v                                      # empty: filter-repo removes 'origin' on purpose, so you can't push by accident
git log --all --oneline -- .env                    # now empty
git grep -I AKIAIOSFODNN7EXAMPLE $(git rev-list --all)    # empty: the key is in no commit
```

Now publish the rewritten history and prove it from a brand-new clone:

```bash
git remote add origin ~/p0-git-debug/remote.git
git push --force --all origin
git clone --no-local ~/p0-git-debug/remote.git ~/p0-verify
git -C ~/p0-verify log --all --oneline -- .env                      # empty
git -C ~/p0-verify grep -I AKIAIOSFODNN7EXAMPLE $(git -C ~/p0-verify rev-list --all)   # empty
git -C ~/p0-verify rev-list --count --all                           # 4
git -C ~/p0-git-debug/work log --all --oneline -- .env | wc -l      # 2   <- the OLD clone still has it
```

- **Expected result:** the `.env` history is empty in the rewritten repo and in the fresh clone; the repository now has **4** commits (the two that only added and removed `.env` disappeared); and your **old** clone `~/p0-git-debug/work` still contains the secret. That last line is the reason everyone must **re-clone** after a rewrite, and the reason revoking the key comes first.
- **Verification command:**

```bash
git -C ~/p0-verify log --all --oneline -- .env | wc -l             # expect: 0
git -C ~/p0-verify rev-list --count --all                          # expect: 4
```

- **Teardown command:** `rm -rf ~/p0-filter ~/p0-verify ~/p0-git-debug` (also in section 9).
- **Cost note:** USD 0.

## 7. Debugging lab

- **Scenario:** a script prints a server report when you run it from its own folder, with your shell's settings. The scheduler that runs it every night fails. `run.sh` reproduces how the scheduler runs it: **from another folder, with an almost empty environment**.
- **How to create the broken state:** the files are already in your lab folder (from Lab 1):

```bash
cd ~/p0-python-lab/debug-report
ls -R                                            # report.py  run.sh  data/servers.csv
REPORT_ENV=staging python3 report.py             # works: your way of running it
./run.sh
```

- **Symptom you will see:**

```
Traceback (most recent call last):
  …
FileNotFoundError: [Errno 2] No such file or directory: 'data/servers.csv'
exit code: 1
```

- **Your task:** there are **two** bugs in `report.py`. Fix one at a time and run `./run.sh` after each fix; each fix reveals the next error. Don't change `run.sh`. For each bug write **one sentence**: what went wrong, and why it worked when you ran it yourself.
- **Done when:**

```bash
cd ~/p0-python-lab/debug-report
REPORT_ENV=staging ./run.sh
# expect:  staging: 2 server(s)
#            web-1 (web)
#            db-1 (database)
#          exit code: 0
./run.sh
# expect:  error: REPORT_ENV is not set (use e.g. REPORT_ENV=staging)
#          exit code: 2          (a clear one-line message and no traceback)
```

- **Teardown:** none (the folder is removed in section 9).

The diagnosis path and model explanations are in `solutions/debugging-lab.md`.

## 8. Self-check

Answers: `solutions/self-check.md`.

1. Why log instead of `print`? Give two concrete things logging gives you that `print` doesn't.
2. Why must credentials never be written in the script? Where did your Lab 6 script get them from?
3. When is `subprocess` the wrong choice? What does `check=True` do, and what happens without it?
4. Read this traceback and name (a) the error type, (b) the line of **your own file** that failed, and (c) what you'd check first:

```
Traceback (most recent call last):
  File "/home/ana/p0-python-lab/lab2_check.py", line 25, in <module>
    main()
  File "/home/ana/p0-python-lab/lab2_check.py", line 20, in main
    response = requests.get(url, timeout=args.timeout)
  File "/home/ana/p0-python-lab/.venv/lib/python3.12/site-packages/requests/api.py", line 73, in get
    …
requests.exceptions.ReadTimeout: HTTPConnectionPool(host='127.0.0.1', port=8000): Read timed out. (read timeout=3.0)
```

5. Why use one virtual environment per project, and what does a pinned `requirements.txt` add?
6. A script works when you run it from its own folder and fails from cron. Name the two usual causes and how you'd fix each.
7. Why did you have to run `git filter-repo` in a *fresh clone*, and why did the old clone still contain the secret afterwards?

## 9. Teardown

```bash
# 1. AWS: the read-only identity (skip any line that says NoSuchEntity: it's already gone)
export AWS_PROFILE=p0-admin AWS_REGION=us-east-1
for k in $(aws iam list-access-keys --user-name p0-readonly --query 'AccessKeyMetadata[].AccessKeyId' --output text 2>/dev/null); do
  aws iam update-access-key --user-name p0-readonly --access-key-id "$k" --status Inactive
  aws iam delete-access-key --user-name p0-readonly --access-key-id "$k"
done
aws iam delete-user-policy --user-name p0-readonly --policy-name p0-list-buckets 2>/dev/null
aws iam delete-user --user-name p0-readonly 2>/dev/null

# 2. The CLI profile (Linux / WSL; on macOS use  sed -i ''  instead of  sed -i)
sed -i '/^\[p0-readonly\]$/,/^\[/{/^\[p0-readonly\]$/d;/^\[/!d}'             ~/.aws/credentials
sed -i '/^\[profile p0-readonly\]$/,/^\[/{/^\[profile p0-readonly\]$/d;/^\[/!d}' ~/.aws/config

# 3. Stop the stub API (Ctrl+C in its terminal), leave the venv, remove all lab folders
deactivate 2>/dev/null
rm -rf ~/p0-python-lab ~/p0-filter ~/p0-verify ~/p0-git-debug
```

**Confirm nothing is left:**

```bash
aws iam get-user --user-name p0-readonly 2>&1 | grep -c NoSuchEntity        # expect: 1
aws configure list-profiles | grep -c p0-readonly                            # expect: 0
ls ~/p0-python-lab ~/p0-filter ~/p0-verify ~/p0-git-debug 2>&1 | grep -c "No such file"    # expect: 4
curl -s -m 2 http://127.0.0.1:8000/health || echo "stub stopped"            # expect: stub stopped
```

Kept on purpose: Python, `python3-venv`, Git, the AWS CLI and your `p0-admin` profile.

## 10. Last verified

- **Date:** NOT YET VERIFIED BY A HUMAN. Drafted 2026-11-18. (`lastVerified: null`; only a human who runs every command may set it.)
- **Verified by:** —
- **Region:** `us-east-1` (Lab 6 only).
- **Versions:** Python 3.12.3 (Ubuntu 24.04 package `3.12.3-0ubuntu2.1`) · `python3-venv` 3.12.3-0ubuntu2.1 · `requests` 2.34.2 · `boto3` 1.44.4 · `git-filter-repo` 2.47.0 · AWS CLI 2.33.14 · git 2.43.0. (Any Python 3.12.x is fine for these scripts.)
- **Notes (author dry-run, not a verification):** on Ubuntu 24.04.5 the pinned packages were installed into a fresh venv (all three versions exist on PyPI); Labs 1–5 were run against the stub API, including the crash on `/slow`, the log file, all four exit codes and the `subprocess` failure paths; Lab 6's script, IAM create/key/teardown commands and profile clean-up `sed` lines were run against a local **mock** of AWS (not real AWS, so IAM *denials*, IAM propagation delay and `UnauthorizedOperation` messages were not observed); Lab 7 and the debugging lab were run end to end, including `git filter-repo` refusing a non-fresh clone and removing `origin`. **Not run:** anything against real AWS, `sudo apt-get install python3-venv`, macOS, and `aws configure list-profiles` (AWS CLI v2 only; the author machine had v1).
