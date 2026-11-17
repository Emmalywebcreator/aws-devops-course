# Solution · 3.5 incident — "host-2 flapping after a memory cap"

> Not linked from the module.

## Root cause

Someone edited `/etc/systemd/system/orders.service` on host-2 by hand to add `--memory 24m`. The Python app needs more than 24 MiB, so the kernel **OOM-kills** the container shortly after start; systemd's `Restart=always` brings it back every 5 s → health check flaps. Host-1 wasn't touched. The edit bypassed the playbook, so nothing recorded it — classic **configuration drift**.

## Diagnosis path

1. **Scope it:** one host bad, one good → look for what's *different* about host-2, not at the image or the app code (same image on both).
2. **Service state, from the laptop:**
   ```bash
   ansible orders-host-2 -b -m ansible.builtin.command -a 'systemctl show orders -p NRestarts -p ActiveState'
   ```
   → `NRestarts` climbing.
3. **Why does it die?**
   ```bash
   ansible orders-host-2 -b -m ansible.builtin.shell -a 'journalctl -u orders --since "-30min" --no-pager | tail -20'
   ansible orders-host-2 -b -m ansible.builtin.shell -a 'docker ps -a --filter name=orders; dmesg | grep -i -m3 "killed process"'
   ```
   → exits with status 137 / kernel "Out of memory: Killed process … python". (`docker inspect orders | grep -i oomkilled` → `"OOMKilled": true` if you catch the container between restarts. Avoid `--format '{{…}}'` in ad-hoc commands: Ansible tries to template the braces.)
4. **What changed vs. the declared state?**
   ```bash
   ansible-playbook site.yml --check --diff --limit orders-host-2
   ```
   → diff on `/etc/systemd/system/orders.service`: `+ … --memory 24m …`. That's the smoking gun **and** the evidence for the incident note.

## Fix (with the playbook)

```bash
ansible-playbook site.yml --limit orders-host-2
```

The template task rewrites the unit (`changed`), which notifies `Reload systemd` and `Restart orders`. Service healthy within seconds; `--check --diff` now shows `changed=0`.

If a memory limit is genuinely wanted, it belongs in the template as a variable (e.g. `orders_memory: 256m`), reviewed in a PR and rolled out with `serial: 1`.

## Prevention (accept any one, with reasoning)

- Run `ansible-playbook site.yml --check --diff` on a schedule (CI cron) and alert on any `changed>0` → drift detected within the hour.
- Remove interactive SSH for humans; changes go through the playbook (the `# Managed by Ansible` header is a warning, not a control).
- Re-apply the playbook on a schedule so drift is corrected automatically (trade-off: also "corrects" an emergency fix before it's codified).

## Model incident note

> **Impact:** orders-host-2 flapping 02:10–03:05 (OOM-kill loop); host-1 carried traffic. **Root cause:** manual edit of the systemd unit added `--memory 24m`, below the app's working set. **Fix / prevention:** re-applied the playbook (drift reverted); scheduled `--check --diff` drift detection with alerting; memory limit now a reviewed role variable.
