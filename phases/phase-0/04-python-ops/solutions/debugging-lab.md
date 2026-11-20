# Solution · 0.4 debugging lab — "works for me, fails from the scheduler"

> Not linked from the module. Try it first. The fixed script is `debug-report-fixed.py` in this folder.

## The two bugs

| # | Bug | Why it worked when *you* ran it | The fix |
|---|---|---|---|
| 1 | **Relative path.** `open("data/servers.csv")` is resolved against the **current folder**, not against the script's folder. | You ran it from `debug-report/`, so `data/servers.csv` existed relative to where you stood. `run.sh` does `cd /tmp` first, the way a scheduler starts jobs from some other folder, so the file isn't found. | Build the path from the script's own location: `Path(__file__).resolve().parent / "data" / "servers.csv"`. |
| 2 | **Missing environment variable.** `os.environ["REPORT_ENV"]` raises `KeyError` when the variable isn't set. | Your shell had `REPORT_ENV=staging` (you set it on the command line). `run.sh` starts the script with `env -i`, an almost empty environment, like cron. | Check explicitly: `os.environ.get("REPORT_ENV")`; if it's missing, print a clear one-line message to stderr and exit with a non-zero code (`2`), with no traceback. |

## Diagnosis path

1. **Read the traceback from the bottom.** `FileNotFoundError: [Errno 2] No such file or directory: 'data/servers.csv'`. The path has no leading `/`, so it's **relative**: relative to *where the program was started*. `run.sh` shows the program starts in `/tmp`.
2. **Prove it.** `cd /tmp && python3 ~/p0-python-lab/debug-report/report.py` fails the same way; `cd ~/p0-python-lab/debug-report && REPORT_ENV=staging python3 report.py` works. Same file, different current folder.
3. **Fix bug 1** with `Path(__file__)…`, then run `./run.sh` again. The file is now found, and a **new** error appears: `KeyError: 'REPORT_ENV'`. Bug 2 was hidden behind bug 1: the script never got far enough to hit it.
4. **Prove bug 2.** `REPORT_ENV=staging ./run.sh` passes the variable through and succeeds, so the code is fine *when the variable exists*. `env -i PATH=/usr/bin:/bin python3 report.py` shows what a bare environment looks like: no variables except the ones you list.
5. **Fix bug 2** with an explicit check and a readable message. Missing configuration is an expected condition, so it deserves an error message and an exit code, not a stack trace.

## Model explanations

1. The script opened `data/servers.csv` relative to the current folder. It worked from its own folder and failed from `/tmp`. Fixed by building the path from `__file__`.
2. The script needed `REPORT_ENV` but the scheduler's environment doesn't have your shell's variables. The raw `KeyError` hid the cause. Fixed by checking for it, printing `error: REPORT_ENV is not set …` and exiting with code 2.

## The general rule

Anything a script depends on (files, folders, environment variables, installed tools, the user it runs as, the `PATH`) must either be **found relative to the script itself**, or be **checked up front with a clear message**. "Works on my machine" usually means "my machine had something the scheduler doesn't".
