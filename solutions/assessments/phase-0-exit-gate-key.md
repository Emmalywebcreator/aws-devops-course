# Rubric · Phase 0 exit gate, Gate D written explanations

> Grading rubric for Gate D in `assessments/gate-rules.md`. **Not linked from course navigation.**
> Score each explanation 0 / 1 / 2. Pass = every explanation ≥ 1, total ≥ 5/6, and the write-up passes.
> Self-graders: quote the sentence that earns each point you award.

**General scoring:** **2** = hits every *required* point, correctly, in the learner's own words. **1** = hits at least half the required points and states nothing dangerously wrong. **0** = misses most points, **or** states anything in the "automatic 0" column.

---

## E1 — IAM evaluation (0.5)

| Required points | Automatic 0 if it says… |
|---|---|
| By default everything is **denied** (implicit deny). | "Allowed unless something denies it." |
| An **allow** in an applicable policy grants the action — if nothing denies it. | |
| An **explicit deny** anywhere overrides every allow. | An allow can override a deny, or order of attachment matters. |
| A concrete example from the capstone (e.g. the admin user is allowed `ec2:RunInstances` by `AdministratorAccess`; an explicit deny on `s3:DeleteBucket` would block deleting the logs bucket even so). | |

**Model answer (2/2):**
> AWS starts from "no": if no policy says anything about an action, it's denied. That's the implicit deny. Then it looks at every policy that applies to the request. If any of them explicitly denies the action, the answer is deny, full stop — no allow can override it. If there's no explicit deny and at least one policy allows the action, it's allowed. In my capstone my admin user has AdministratorAccess, so `ec2:RunInstances` was allowed. If I had added a policy denying `s3:DeleteBucket`, my teardown script would have failed to delete the logs bucket even though AdministratorAccess allows `s3:*`, because the explicit deny wins.

Source: https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_evaluation-logic.html (the full logic also includes SCPs, resource policies, permission boundaries and session policies — not required at Phase 0)

## E2 — A request path through a VPC (0.2, 0.5)

| Required points | Automatic 0 if it says… |
|---|---|
| DNS / the public IP routes to AWS; the **internet gateway** maps the public IP to the instance's private IP. | The instance "has the public IP on its network card" with no IGW. |
| The **public subnet's route table** has `0.0.0.0/0 → igw-…`, which is what makes it public (also for the return path). | |
| The **security group** allows inbound on the app port from the learner's IP; return traffic is allowed automatically (stateful). | Security groups need an outbound rule for replies. |
| The instance's app answers; the reply goes back the same way. | |
| Private subnet: no route to the IGW and no public IP → unreachable from the internet; to reach *out* it needs a NAT Gateway (or VPC endpoints). | |

**Model answer (2/2):**
> The browser looks up the address and sends the request to the public IP. That IP belongs to AWS, and the VPC's internet gateway translates it to my instance's private IP. The packet can get in because my subnet's route table sends 0.0.0.0/0 to the internet gateway — that route is what makes the subnet public. Next the security group checks the request: it allows TCP 80 from my IP only, so my browser gets in and anyone else is dropped. My hello-world app answers, and because security groups are stateful the reply is allowed out without a separate rule, back through the internet gateway to me. If the instance were in a private subnet, its route table would have no route to the internet gateway and it would have no public IP, so nobody on the internet could reach it. To download updates it would need a NAT Gateway in a public subnet.

Sources: https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Internet_Gateway.html · https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Route_Tables.html · https://docs.aws.amazon.com/vpc/latest/userguide/vpc-security-groups.html

## E3 — Why NAT costs money (0.5)

| Required points | Automatic 0 if it says… |
|---|---|
| A NAT Gateway lets instances in a **private** subnet start connections **out** to the internet without being reachable from it. | NAT lets the internet reach private instances. |
| Two charges: **per hour** it exists, and **per GB processed**. | "Free tier covers it" / "only charged for traffic". |
| It bills hourly **even with zero traffic** — it's a managed resource that exists until you delete it (plus its Elastic IP). | |
| The capstone avoided it: everything in a public subnet, protected by a security group; no private subnet needed outbound access. | |

**Model answer (2/2):**
> A NAT Gateway lets servers in a private subnet reach the internet (for updates, APIs) while staying unreachable from the internet. AWS charges for it two ways: an hourly charge for every hour it exists, and a charge for every gigabyte that passes through it. The hourly part is the trap — it bills around the clock even if nothing uses it, roughly a dollar a day, until you delete it. My capstone avoided it by putting the one instance in a public subnet with a public IP and a security group that only allows my IP, so nothing needed a private subnet with outbound access.

Source: https://aws.amazon.com/vpc/pricing/ (NAT Gateway: per-hour and per-GB charges) · https://docs.aws.amazon.com/vpc/latest/userguide/vpc-nat-gateway.html

## Write-up checklist (pass/fail)

- [ ] Has three parts: **what I built**, **what I broke**, **how I fixed it**.
- [ ] "What I broke" describes at least one real failure from the capstone (an error message or wrong behaviour), not a hypothetical.
- [ ] "How I fixed it" says how the learner *found* the cause, not just what they changed.
- [ ] Fits on one page.

*Status: rewritten 2026-11-17 to the 0.0–0.6 spec (Gate D = spec's three explanations + write-up).*
