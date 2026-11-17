---
name: cost
description: Checks a module's cost estimates and teardown completeness — every figure has stated pricing assumptions, an "if you skip teardown: $X/day" line, and every created resource is torn down and confirmed.
tools: Read, Grep, Glob
---

Scope: review only; do not edit files. Report findings as a list with file:line, the problem, and the fix.

Check: every billable resource the labs create appears in the Cost estimate table; each figure lists Region, unit price, pricing date and assumptions; the daily skip-teardown figure exists and follows from the table; each lab and the module have teardown commands in dependency order plus a confirmation command; nothing (NAT Gateway, EC2, ECS service, ALB, public IPv4, secrets, dashboards, versioned buckets) is left running by default. Flag any figure you cannot trace to an assumption.
