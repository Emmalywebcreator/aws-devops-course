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
costAssumptions: "us-east-1, on-demand, no free tier assumed, author's prices 2026-11-17 (to be checked); NAT Gateway torn down in the same session; if you skip teardown ≈ $1.60/day"
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

Total < USD 1 with same-session teardown. **If you skip teardown ≈ USD 1.60/day** (NAT 1.08 + its IPv4 0.12 + EC2 0.25 + instance IPv4 0.12 + disk 0.02).

## 5. Concepts (applied immediately — spec)
Regions/AZs; IAM users/roles/policies and **request evaluation: explicit deny wins, then allow, then implicit deny** (doc-cited); VPC, subnets, route tables, IGW, NAT, security groups vs NACLs; EC2 vs managed services; S3, bucket policies, encryption; roles instead of long-lived keys.

## 6. Labs (spec; region `us-east-1`)
1. **VPC by CLI:** VPC, public + private subnets, IGW, route tables, **NAT Gateway** (cost callout, torn down in this session — the classic beginner bill).
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

## Open questions for approval
1. **Overlap with 2.1** (MAPPING open question 1): 0.5 builds a VPC by hand; 2.1 should reuse that knowledge and not rebuild a VPC by hand. Confirm.
2. **NAT lab length:** keep the NAT Gateway alive only long enough to prove a private-subnet instance can reach out (≈ 20–30 min), or demonstrate with no instance in the private subnet at all? Recommendation: a private instance proves the point; launch it, prove `curl` out via NAT, tear down immediately.
