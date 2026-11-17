# Scope · 0.5 AWS core mental model + CLI

> Planning document (Session C). Not module content, not published by the site.

**Draft front-matter**

```yaml
phase: "phase-0"
moduleId: "0.5"
title: "AWS core mental model + CLI"
goal: "Explain IAM, VPC, EC2 and S3 correctly and drive them from the CLI."
timeEstimate: "10-12h"
costEstimate: "<$1"
costAssumptions: "us-east-1, on-demand, no free tier assumed, author's prices 2026-11-17 (to be checked); NAT Gateway created, verified and deleted in the same session (target < 30 min); if you skip teardown ≈ $1.60/day, of which the NAT Gateway alone ≈ $1.10/day"
lastVerified: null
prerequisites: ["0.0", "0.1", "0.2"]
hasDebuggingLab: true
hasTeardown: true
toolsPinned: { awscli: "2.33.14", "al2023-ami": "<AMI ID recorded in the module>" }
```

**Sources:** spec "Module 0.5"; AUDIT B11 (VPC/subnets before Month 1), B13 (IAM evaluation with citations), §6; diagnostic Q12; gate-rules Gate D (E1–E3 are taught here).
**Gate to pass (spec):** explain IAM, VPC, EC2, S3; use the CLI.

## 1. Goal
Explain IAM, VPC, EC2 and S3 correctly and drive them from the CLI.

## 2. Prerequisites
0.0 (guardrails live, `aws login`), 0.1 (shell, SSH), 0.2 (CIDR, routing, NAT, firewalls as concepts).

## 3. Time estimate
10–12 h (spec). The NAT lab must fit in **one sitting**.

## 4. Cost estimate (assumptions to check before writing)

| Resource | Unit price (assumption) | Expected use |
|---|---|---|
| NAT Gateway | USD 0.045/h + USD 0.045/GB | ≤ 2 h, same session |
| Public IPv4 (NAT's Elastic IP + instance) | USD 0.005/h each | ≤ 4 h |
| EC2 `t3.micro` (not `t2.micro` — free-tier eligibility for new accounts, see 0.0) | USD 0.0104/h | ≤ 4 h |
| EBS 8 GiB gp3 | USD 0.08/GB-month | ≤ 4 h |
| S3 bucket + one object | cents | — |

Total < USD 1 with same-session teardown. **The NAT Gateway alone ≈ USD 1.10/day** (0.045 × 24 = 1.08, before any data) — stated in the lab itself, next to the create command. **If you skip all teardown ≈ USD 1.60/day** (NAT 1.08 + its IPv4 0.12 + EC2 0.25 + instance IPv4 0.12 + disk 0.02).

## 5. Concepts (applied immediately — spec)
Regions/AZs; IAM users/roles/policies and **request evaluation: explicit deny wins, then allow, then implicit deny** (doc-cited); VPC, subnets, route tables, IGW, NAT, security groups vs NACLs; EC2 vs managed services; S3, bucket policies, encryption; roles instead of long-lived keys.

## 6. Labs (spec; region `us-east-1`)
1. **VPC by CLI, as scripts:** the learner builds the VPC (public + private subnets, IGW, route tables, security groups) as **`vpc-up.sh`** and **`vpc-down.sh`** (reverse order, idempotent, tag-based lookups — no hardcoded IDs). These scripts are reused in Phase 2.1 (decision 5).
1b. **NAT Gateway — create, verify, tear down in one sitting (target < 30 minutes)** (decision 5): create the NAT Gateway and its Elastic IP with the **≈ USD 1.10/day** figure stated beside the command; launch a private-subnet instance and prove outbound `curl` works through NAT; then **delete the NAT Gateway and release the Elastic IP as a graded step**, verified with `aws ec2 describe-nat-gateways --filter Name=vpc-id,Values=<vpc> Name=state,Values=pending,available` → empty and `aws ec2 describe-addresses` → no address.
2. **EC2 in the public subnet:** launch `t3.micro`, SSH in, then tighten the security group to your IP `/32`.
3. **S3 with encryption + a bucket policy.**
4. **IAM role on EC2 reads an S3 object with no keys** (instance profile, IMDSv2).
Every lab: verification command and teardown; NAT deletion → release Elastic IP → delete VPC, each with a verification command (spec).

## 7. Debugging lab (spec)
Instance in a public subnet has no internet. Learner walks **route table → IGW → security group → NACL**, in order, and finds the missing `0.0.0.0/0 → igw` route. Diagnosis path in `solutions/`.

## 8. Self-check (spec)
- Why roles over long-lived keys?
- Security group vs NACL?
- Why is a private subnet's NAT gateway a cost trap?
- Plus: evaluate a given pair of policies (allow + explicit deny); prove with one command that no NAT Gateway exists.

## 9. Teardown
Explicit order with verification (spec): terminate instance → `delete-nat-gateway` (wait `deleted`) → `release-address` → detach/delete IGW → delete subnets, route tables, security group → delete VPC → empty + delete bucket → delete role/instance profile. Confirm: NAT, EIP, VPC, instance, bucket, role all "not found"; all-region instance sweep empty.

## 10. Last verified
`null` until a human run.

## Decisions (approved 2026-11-17)
5. **2.1 does not rebuild a VPC by hand.** It consumes the 0.5 VPC if it still exists, or recreates it with `scripts/vpc-up.sh` from this module (copied into the `aws-devops-platform` repo in 2.1). `vpc-up.sh` must therefore support a **no-NAT mode** (public subnets only), because Phase 2 never runs a NAT Gateway. See `phases/phase-2/01-ecs-fargate-by-hand/scope.md`.
5b. **NAT Gateway:** created, verified and torn down in the same session, target under 30 minutes, with the ≈ USD 1.10/day figure stated; teardown is a graded step with a verification command.
