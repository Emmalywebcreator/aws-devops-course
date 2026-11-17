# Solution · 3.3 self-check

> Not linked from the module.

1. Error ratio 50/2000 = 0.025; burn = 0.025 / 0.005 = **5**. Fast-burn page needs > 14.4 → **no page**. Slow-burn ticket needs > 6 → **no ticket either**, though it's close: sustained at burn 5, the 30-day budget would be gone in 6 days.
2. Long window = "this is significant, not a blip". Short window = "and it's still happening now", so the alert resets quickly after a fix. Long only: keeps paging for up to an hour after the problem is fixed. Short only: pages on brief spikes that cost almost no budget.
3. So drills finish in minutes instead of hours. Staging/prod need the real windows; tiny windows on real traffic page on noise (low precision) and the burn-rate thresholds no longer correspond to "2% of budget".
4. `ALARM("orders-<env>-burn-fast_long") AND ALARM("orders-<env>-burn-fast_short")`. The children use `treat_missing_data = notBreaching`, so a child with no data is `OK` (not `ALARM`) → the composite stays `OK`. (Low traffic means few data points — another reason SLO alerts need real volume.)
5. `requests` = sum of `RequestCount` over the window; `errors` = target + ELB 5xx; `allowed` = requests × (1 − SLO); `budget_remaining` = 1 − errors/allowed (negative = overspent). Exit 1 when ≤ 0.
6. The causal path and timing across components for that one request (which span was slow/failed, parent/child relationships, propagation across services). A log line is one component's view at one moment.
7. The **task role** — the app's sidecar sends spans at runtime with the task's credentials. The execution role is only used by the ECS agent to pull images, fetch secrets and set up logging before the containers start.
8. Users are being hurt (and budget spent) every minute. A rollback to a known-good revision is fast and low-risk; root-cause analysis can take hours and is safer without the pressure.
