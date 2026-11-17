# Scope (stub) · 2.1 ECS on Fargate by hand

> Planning stub, created only to record the approved 0.5 → 2.1 decision (2026-11-17, decision 5). The full scope will be drafted in the Phase 2 planning pass. Not module content, not published by the site.

**Source weeks:** M1 W3 (ECS/ALB by hand) — MAPPING.md.
**Planned title:** ECS on Fargate by hand: task vs service, ALB.

## Network: no hand-built VPC in this module (decision 5)
- 2.1 **does not rebuild a VPC by hand.** That skill was taught and graded in 0.5.
- It either **consumes the 0.5 VPC** (if the learner kept it — found by tag, never by hardcoded ID), or **recreates it with `scripts/vpc-up.sh`**, the script the learner wrote in 0.5, copied into the `aws-devops-platform` repo here.
- `vpc-up.sh` runs in **no-NAT mode** (public subnets only, tasks with public IPs behind security groups), matching the Phase 2 no-NAT design (CONTRACT §4 `modules/network`). **No NAT Gateway is ever created in Phase 2.**
- Teardown: the ECS service, ALB and target group are deleted in the same session (CLAUDE.md: no ECS service left running); the VPC is removed with `scripts/vpc-down.sh`, with a verification command.

## Still to scope
Goal, prerequisites (1.6 Phase 1 gate), time, cost table with assumptions, labs (task vs service; ALB + target group health checks; task execution role; teardown), debugging lab, self-check, last verified.
