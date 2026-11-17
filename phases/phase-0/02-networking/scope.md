# Scope · 0.2 Networking fundamentals

> Planning document (Session C). Not module content, not published by the site.

**Draft front-matter**

```yaml
phase: "phase-0"
moduleId: "0.2"
title: "Networking fundamentals"
goal: "Explain, on a whiteboard, how a request reaches an app."
timeEstimate: "6-8h"
costEstimate: "$0"
costAssumptions: "none"
lastVerified: null
prerequisites: ["0.1"]
hasDebuggingLab: true
hasTeardown: true
toolsPinned: { docker: "<as 0.1>", "ubuntu-image": "noble-20261110", curl: "<Ubuntu 24.04 package version>", dig: "<bind9-dnsutils version>", traceroute: "<version>" }
```

**Sources:** spec "Module 0.2"; legacy Lessons 0.3, 0.3b (keep the 0.3b error table — AUDIT §7); AUDIT B11 (subnets/CIDR before AWS).
**Gate to pass (spec):** explain a VPC/subnet/route table — at **concept level** here; the AWS objects themselves are built in 0.5.

## 1. Goal
Explain, on a whiteboard, how a request reaches an app.

## 2. Prerequisites
0.1 (shell, Docker installed). No AWS.

## 3. Time estimate
6–8 h (spec).

## 4. Cost estimate
USD 0 — local containers and public diagnostic targets only. Skip-teardown: USD 0/day.

## 5. Concepts (concept level; AWS-applied in 0.5)
IP addresses and CIDR (worked /16 → /24 split); ports; DNS resolution chain; TCP vs UDP; HTTP/HTTPS and TLS at a glance; NAT (why private addresses need translation); routing and default routes; subnets; firewalls / security groups as allow-lists (stateful vs stateless named, not deep-dived). Every concept ends with "the command that shows it".

## 6. Labs (spec)
1. **Probe real targets:** `ping`, `traceroute`, `dig`, `curl -v` against stable public targets (choose ones that allow ICMP/HTTP; record expected output shapes, not exact IPs).
2. **Subnetting practice:** split `10.0.0.0/16` into `/24`s; verify answers with a one-line calculator command (no Python lesson needed; Python is 0.4).
3. **Two containers, one network:** two pinned containers on separate user-defined Docker networks can't reach each other; connect them → they can. Verify with `curl`/`ping` by container name.
4. **Read an HTTP exchange:** `curl -v` request/response headers, status codes, TLS handshake lines.
Teardown per lab: `docker rm -f …`, `docker network rm …`; confirm with `docker network ls --filter name=p0-net` (empty).

## 7. Debugging lab (spec)
"A container can't reach the internet." Break script picks a cause (candidate set: bogus DNS server via `--dns 192.0.2.53`; `--network` set to an `--internal` network; missing default route). Learner isolates **DNS vs routing vs egress block** with `dig`, `curl`, `ip route`, in that order. Diagnosis path in `solutions/`.

## 8. Self-check (spec)
- What does a security group's default-deny actually block (inbound vs outbound, stateful replies)?
- Why does a private subnet need a NAT gateway to reach the internet?
- Walk through what happens when you type a URL and press enter.
- Plus: given `curl: (6)` vs `curl: (7)`, the first thing you'd check.

## 9. Teardown
Remove all `p0-net*` containers and networks. Confirm `docker ps -a` and `docker network ls` show none.

## 10. Last verified
`null` until a human run.

## Open questions for approval
1. **macOS Docker networking** behaves differently (containers run in a VM; `ip route` inside the container is still Linux). Keep all commands *inside* containers so output matches on every OS? Recommendation: yes.
2. **ICMP targets:** some networks block `ping`/`traceroute`; the lab must say so and accept "timeout" as an explained outcome.
