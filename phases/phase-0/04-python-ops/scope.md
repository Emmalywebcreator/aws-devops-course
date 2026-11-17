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
costAssumptions: "us-east-1; S3 ListBuckets calls from the lab are a handful of requests (fractions of a cent); IAM has no charge; if you skip teardown ≈ $0/day (a leftover IAM user costs nothing but is a security risk)"
lastVerified: null
prerequisites: ["0.0", "0.1"]
hasDebuggingLab: true
hasTeardown: true
toolsPinned: { python: "3.12.16", requests: "2.34.2", boto3: "1.44.4", awscli: "2.33.14" }
```

**Sources:** spec "Module 0.4"; legacy Lesson 0.5; diagnostic Q10, Q11; contract §4 (Python 3.12.16).
**Gate to pass (spec):** write a script that parses + logs.

## 1. Goal
Automate a small, boring task and log it properly.

## 2. Prerequisites
0.0 (AWS account, admin user, `aws login`), 0.1 (shell, env vars, paths).

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
6. **List S3 buckets read-only and log the result:** a dedicated IAM user `p0-readonly` allowed only `s3:ListAllMyBuckets`; boto3 script logs the bucket count. Teardown deletes the user (spec).

## 7. Debugging lab (spec)
Script works from its own folder but fails with `python3 script.py` from another directory: **relative path** + **missing environment variable**. Fix (paths relative to `__file__`, explicit env check with a clear error) and explain. Diagnosis path in `solutions/`.

## 8. Self-check (spec)
- Why log instead of print?
- Why not put credentials in the script?
- When is `subprocess` the wrong choice?
- Plus: read a traceback and name the failing line; why a venv per project.

## 9. Teardown
Delete the `p0-readonly` IAM user (and any keys/login profile), remove the venv and lab folder. Confirm with `aws iam get-user --user-name p0-readonly` → `NoSuchEntity`.

## 10. Last verified
`null` until a human run.

## Open questions for approval
1. **Credentials for the read-only identity.** The spec says "delete the read-only IAM user/keys". Long-lived access keys contradict 0.0's `aws login` approach. Proposal: the read-only user signs in via `aws login --profile p0-readonly` and boto3 uses that profile — **TODO(verify) boto3 1.44.4 supports the `aws login` credential provider**; if not, fall back to an access key created and deleted in the same session, with the teardown proving it's gone.
2. **Public API for Lab 2:** pick one with a stable, unauthenticated, rate-limit-friendly endpoint, or keep the lab fully local. Recommendation: local stub only for graded checks.
