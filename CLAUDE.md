# CLAUDE.md — aws-devops-platform course

## What this repo is
A phased, project-based DevOps course. Learners build one app (`aws-devops-platform`)
across four phases, from zero AWS knowledge to a deployable, observable, secured system.
Deployed at https://emmalywebcreator.github.io/aws_devops_course/

## Target learner
Phase 0–1: career-switcher or junior dev with basic IT literacy, NO AWS experience.
Phase 2–3: someone who passed the Phase 0 gate and Phase 1 build.
Never assume a learner knows: Linux permissions, subnetting, IAM semantics, cost traps.

## Course structure (hard gates between phases)
- Phase 0 — Prerequisites & account safety. Gate: diagnostic assessment passes.
- Phase 1 — Foundations: Docker, Git-based CI, IaC intro.
- Phase 2 — Core DevOps: Terraform, ECS, blue/green + rollback, observability.
- Phase 3 — Pro breadth: Kubernetes/EKS, Ansible, DevSecOps, multi-env.
A module may reference earlier modules but NEVER later ones.

## Required module template — every module MUST have all sections
1. **Goal** (one sentence)
2. **Prerequisites** (links to exact prior modules)
3. **Time estimate** (range, honest)
4. **Cost estimate** — with the pricing assumptions stated, and "if you skip teardown: $X/day"
5. **Concepts** (short, then immediately applied)
6. **Labs** — each lab has: task, expected result, verification command, teardown command
7. **Debugging lab** — a deliberately broken scenario the learner must fix
8. **Self-check** — 5–8 questions or commands that prove mastery
9. **Teardown** — exact commands, and confirmation step
10. **Last verified** — date + tool/AWS versions tested

## Non-negotiable technical rules
- Pin every version: Terraform provider versions, Docker image tags (never `:latest`),
  GitHub Action versions (`@v4`, not `@main`), Python deps.
- Never hardcode account IDs, ARNs, or credentials. Use variables, `aws sts get-caller-identity`,
  or environment lookups.
- Default region must be stated explicitly in every lab.
- Every resource-creating lab ships with a teardown command and a cost note.
- Console instructions must say "UI as of <date>" — console changes often; prefer CLI/CLI-first.
- No lab may leave a NAT Gateway, idle EC2, or ECS service running by default.

## Content quality rules
- Explain WHY a tool exists before HOW to use it. No tool appears without a problem it solves.
- Prefer one worked example over five bullet points.
- Cut any tool the learner will not use in an interview in Phases 0–2.
- Every claim about AWS behavior must be checkable in official docs; cite the doc page
  for anything non-obvious (IAM evaluation logic, ECS task vs service, VPC routing).

## Never do this
- Never generate a module without the full template.
- Never invent CLI flags or console paths — verify against docs or existing lab output.
- Never write only the happy path; include the failure and the fix.
- Never add a tool to Phase 0–2 scope without checking it's justified (K8s stays in Phase 3).
- Never claim a cost figure without listing the pricing assumptions.

## Repo conventions
- `/phases/phase-0/…/module.md` — lesson content
- `/phases/phase-0/…/labs/` — runnable labs, one dir per lab
- `/phases/phase-0/…/solutions/` — reference solutions, not linked from lesson nav
- `/site/` — the published site (GitHub Pages)
- Diagnostics and gates live in `/assessments/`

## Subagents (use these, not one mega-prompt)
- `labs` — writes runnable lab steps + verification + teardown
- `cost` — checks cost estimates and teardown completeness
- `qa` — version pins, accuracy vs docs, template completeness
- `voice` — consistency of tone and reading level

## Definition of done for a module
[ ] Full template      [ ] Every command run by a human once
[ ] Cost + teardown    [ ] Debugging lab included
[ ] Last-verified date [ ] No forward references
[ ] QA agent passed    [ ] Self-check answers exist in /solutions
