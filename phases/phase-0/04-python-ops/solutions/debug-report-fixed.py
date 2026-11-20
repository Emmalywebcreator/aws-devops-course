#!/usr/bin/env python3
"""Print the servers for one environment. The environment comes from REPORT_ENV."""
import csv
import os
import sys
from pathlib import Path

# Fix 1: find the data file relative to THIS file, not to whatever folder the script was started from.
DATA = Path(__file__).resolve().parent / "data" / "servers.csv"

# Fix 2: check the environment variable explicitly and fail with a clear message, not a KeyError traceback.
env = os.environ.get("REPORT_ENV")
if not env:
    print("error: REPORT_ENV is not set (use e.g. REPORT_ENV=staging)", file=sys.stderr)
    sys.exit(2)

with open(DATA, newline="") as f:
    rows = list(csv.DictReader(f))

selected = [r for r in rows if r["env"] == env]

print(f"{env}: {len(selected)} server(s)")
for r in selected:
    print(f"  {r['name']} ({r['role']})")
