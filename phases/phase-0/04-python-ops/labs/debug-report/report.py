#!/usr/bin/env python3
"""Print the servers for one environment. The environment comes from REPORT_ENV."""
import csv
import os

with open("data/servers.csv", newline="") as f:
    rows = list(csv.DictReader(f))

env = os.environ["REPORT_ENV"]
selected = [r for r in rows if r["env"] == env]

print(f"{env}: {len(selected)} server(s)")
for r in selected:
    print(f"  {r['name']} ({r['role']})")
