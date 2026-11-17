# Solution · 0.1 debugging lab — "deploy.sh works on my machine"

> Not linked from the module. Try it first.

## The three bugs (in the order the errors appear)

| # | Bug | Error you see | Why it broke | Why it worked by hand |
|---|---|---|---|---|
| 1 | **No shebang** (`#!/usr/bin/env bash` missing) | `deploy.sh: 1: set: Illegal option -o pipefail` | `run.sh` executes the file directly. With no interpreter line, the system falls back to `/bin/sh`, which on Ubuntu is **dash**; dash doesn't support `pipefail`. | Typed into a bash terminal as `./deploy.sh`, bash itself ran the file, so bash features worked. |
| 2 | **Relative paths** (`config/settings.env`, `out`, `./scripts/render.sh`) | `deploy.sh: line 5: config/settings.env: No such file or directory` | Relative paths are resolved from the **current folder**, and `run.sh` runs from `/tmp`. | The teammate always `cd`'d into the script's folder first. |
| 3 | **Variable not exported** (`APP_ENV=staging`) | `scripts/render.sh: line 4: APP_ENV: unbound variable` | A plain assignment exists only in `deploy.sh`'s shell. `render.sh` is a **child process** and only receives *exported* variables. `set -u` in `render.sh` turns "empty" into a loud error. | It never worked: without `set -u`, `render.sh` would have written `rendered for ` — a silent wrong config, which is worse. |

## Diagnosis path

1. Run `./run.sh` and read the **first line** of the error: it names the file and line (`deploy.sh: 1:`). "Illegal option" for a bash option means "this isn't bash". Check with `head -1 deploy.sh` (no `#!`).
2. After adding the shebang, the error is a missing file whose path doesn't start with `/` → relative path. `run.sh` shows `cd /tmp`, so `config/` is being looked for in `/tmp/config/`.
3. After fixing paths, the error comes from `render.sh` (a different file) about `APP_ENV`. `grep -n APP_ENV deploy.sh` shows it's set but never exported. Test the idea directly: `APP_ENV=x; bash -c 'echo ${APP_ENV:-unset}'` → `unset`.

## Reference fix

```bash
#!/usr/bin/env bash
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"      # the folder this script lives in, as an absolute path

export APP_ENV=staging
source "$here/config/settings.env"
mkdir -p "$here/out"
"$here/scripts/render.sh"
echo "deploy finished for $APP_ENV ($APP_NAME)"
```

Also accepted: `cd "$(dirname "$0")"` at the top instead of prefixing every path (simpler, but then the script changes the caller's working directory assumptions — fine here). Using `bash deploy.sh` in `run.sh` is **not** accepted: the task says don't change `run.sh`, and real schedulers execute the file.

Verified output after the fix (author dry-run, Ubuntu 24.04 / WSL 2, 2026-11-17):

```
rendered for staging
deploy finished for staging (orders-api)
exit code: 0
```

## Model explanations

1. Without a shebang, the system ran the file with `/bin/sh` (dash on Ubuntu), which doesn't understand `pipefail`; it worked by hand because my bash terminal ran it with bash.
2. The script opened `config/settings.env` relative to the current folder, and the scheduler runs it from `/tmp`; it worked by hand because I always `cd`'d into the script's folder first.
3. `APP_ENV` wasn't exported, so the child script `render.sh` never received it and `set -u` stopped it; by hand it "worked" only in the sense that nothing complained — without `set -u` it would have written an empty environment name.

Sources: `man 3 execvp` (ENOEXEC → `/bin/sh` fallback) · https://www.gnu.org/software/bash/manual/bash.html#The-Set-Builtin · https://www.gnu.org/software/bash/manual/bash.html#Environment
