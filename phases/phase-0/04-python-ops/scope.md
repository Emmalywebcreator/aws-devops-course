# Scope · 0.4 Python for ops

> Planning document (Session C). Not module content, not published by the site.

**Draft front-matter**

```yaml
phase: "phase-0"
moduleId: "0.4"
title: "Python for ops"
goal: "Automate a small, boring task and log it properly."
timeEstimate: "8-10h"
costEstimate: "$0"
costAssumptions: "us-east-1; S3 ListBuckets calls from the lab are a handful of requests (fractions of a cent); IAM has no charge; if you skip teardown ≈ $0/day (a leftover IAM user or access key costs nothing but is a security risk — teardown is graded)"
lastVerified: null
prerequisites: ["0.0", "0.1", "0.3"]
hasDebuggingLab: true
hasTeardown: true
toolsPinned: { python: "3.12.16", requests: "2.34.2", boto3: "1.44.4", awscli: "2.33.14", "git-filter-repo": "2.47.0" }
```

**Sources:** spec "Module 0.4"; legacy Lesson 0.5; diagnostic Q10, Q11; contract §4 (Python 3.12.16).
**Gate to pass (spec):** write a script that parses + logs.

## 1. Goal
Automate a small, boring task and log it properly.

## 2. Prerequisites
0.0 (AWS account, admin user, `aws login`), 0.1 (shell, env vars, paths), 0.3 (Git history — needed for Lab 7).

## 3. Time estimate
8–10 h (spec).

## 4. Cost estimate
≈ USD 0 (a few S3 `ListBuckets` requests). Region `us-east-1`. Skip-teardown: USD 0/day, but the read-only IAM identity must still be removed (security, not cost).

## 5. Concepts
venv and pinned `requirements.txt` (why); types, functions, files; `argparse` CLIs; HTTP with `requests`; `logging` levels vs `print`; exceptions and `try/except` on real failures; `subprocess` (and when it's the wrong choice); credentials never in code — the SDK finds them (profile / environment).

## 6. Labs (spec)
1. **A small CLI:** read a file, parse it, `argparse` options.
2. **Call an API with `requests`:** against a **local** stdlib `http.server` stub the lab provides (so the "API returns 500" case is deterministic), plus one public endpoint.
3. **Logging with levels**, to a file and stderr.
4. **`try/except` for real failures:** API 500, missing file — each logged with context, exit code non-zero.
5. **`subprocess`** wrapping a shell command, with `check=True` and captured output.
6. **List S3 buckets read-only and log the result:** a dedicated IAM user `p0-readonly` allowed **only** `s3:ListAllMyBuckets`, with an **access key** (decision 4) stored as a named CLI profile — never in the script. boto3 script logs the bucket count. Teardown deactivates and deletes the key, then deletes the user (spec), and is a **graded step** with a verification command (`aws iam list-access-keys --user-name p0-readonly` → `NoSuchEntity`).
   - **Justification note shown to learners** (decision 4): "Module 0.0 avoids long-lived keys. This lab uses one on purpose: it's read-only, limited to listing bucket names, and deleted before you finish the lab. You'll see how the SDK finds credentials without them ever appearing in code. In later phases, roles replace keys entirely."
   - **TODO(revisit):** if boto3 1.44.4 (or the version pinned when this module is written) is confirmed in its official docs to support the `aws login` credential provider, replace the access key with an `aws login` profile. **Do not write a lab against that capability until it's verified.**
7. **Rewrite Git history to remove a leaked secret** (moved from 0.3 — decision 3): `pip install git-filter-repo==2.47.0` into the lab venv; re-create the 0.3 debugging-lab repo with its break script (0.3's teardown deleted it), which has the fake `.env` in history; run `git filter-repo --path .env --invert-paths`; prove it's gone from every commit (`git log --all -- .env` empty); force-push; re-state why the secret still had to be rotated first. Teardown: delete the practice repo copy and the venv.

## 7. Debugging lab (spec)
Script works from its own folder but fails with `python3 script.py` from another directory: **relative path** + **missing environment variable**. Fix (paths relative to `__file__`, explicit env check with a clear error) and explain. Diagnosis path in `solutions/`.

## 8. Self-check (spec)
- Why log instead of print?
- Why not put credentials in the script?
- When is `subprocess` the wrong choice?
- Plus: read a traceback and name the failing line; why a venv per project.

## 9. Teardown
Delete the `p0-readonly` access key, then the user; remove the CLI profile, the venv, the lab folder and the Lab 7 practice repo copy. Confirm with `aws iam get-user --user-name p0-readonly` → `NoSuchEntity` and `aws configure list-profiles` (no `p0-readonly`).

## 10. Last verified
`null` until a human run.

## Decisions (approved 2026-11-17)
3. **History rewrite lives here** (Lab 7), with `git-filter-repo` installed via `pip`, pinned 2.47.0.
4. **Read-only user uses an access key for now**, with the justification note above. The key is read-only, limited to S3 List, and deleted at the end of the lab; deletion is graded. A TODO tracks revisiting `aws login` support in boto3, and no lab is written against that unverified capability.

## Still open (not blocking)
- **Public API for Lab 2:** keep graded checks on the local stub; the public endpoint is illustrative only.
