---
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
toolsPinned:
  "docker.io": "29.1.3-0ubuntu3~24.04.2"
  "docker-desktop-macos": "4.99.0"
  "ubuntu-image": "noble-20261110"
  "ca-certificates": "20260816ubuntu0.24.04.2"
  "curl": "8.5.0-2ubuntu10.16"
  "bind9-dnsutils": "1:9.18.39-0ubuntu0.24.04.9"
  "iputils-ping": "3:20240117-1ubuntu0.1"
  "traceroute": "1:2.1.5-1"
  "iproute2": "6.1.0-1ubuntu6.4"
  "python3": "3.12.3-0ubuntu2.1"
---

# Phase 0 · Module 0.2 — Networking fundamentals

## 1. Goal

Explain, on a whiteboard, how a request reaches an app.

## 2. Prerequisites

- **Modules:** [0.1 Linux & the shell](../01-linux-shell/module.md).
- **Tools installed:** a Linux shell and Docker (both from 0.1), and the `~/aws-devops-course` clone from 0.1 Lab 1. Update it first: `git -C ~/aws-devops-course pull`.
- **Access:** none. No AWS and no accounts in this module. The AWS versions of these ideas (VPC, subnet, route table, security group) are built in 0.5; here you learn the ideas on your own computer.

## 3. Time estimate

**6–8 hours.**

| Lab | Time |
|---|---|
| 1 — Probe real targets | 1.5 h |
| 2 — Subnetting by hand | 1–1.5 h |
| 3 — Two containers, two networks | 1.5–2 h |
| 4 — Read an HTTP exchange | 1 h |
| Debugging lab | 1 h |
| Reading the concepts | 1 h |

## 4. Cost estimate

**USD 0.** Everything runs in containers on your computer. The only outside traffic is a few requests to public test targets.

| Resource | Billed while idle? | Unit price | Expected use | Cost |
|---|---|---|---|---|
| Docker containers and networks | no | free | Labs 1–4 | USD 0 |
| Image `ubuntu:noble-20261110` (~30 MB) and `apt` packages | no | free | all labs | USD 0 |
| Public targets (`1.1.1.1`, `example.com`, `checkip.amazonaws.com`) | no | free, a handful of requests | Labs 1 and 4 | USD 0 |

- **Pricing assumptions:** no cloud resources are created. Docker licence terms are as in 0.1.
- **Total if you follow the teardown steps:** USD 0.
- **If you skip teardown: USD 0/day.** Leftover containers only use disk and memory. Tear down anyway: the debugging lab leaves a container with a deliberately broken network.

## 5. Concepts

Every concept ends with **the command that shows it**. When a network problem happens later (and it will), these commands are how you find out which layer is broken.

> **Linux first.** The commands run *inside* Linux containers, so the output looks the same on Windows (WSL 2), Linux and macOS. On a Mac, Docker Desktop runs those containers in a small hidden Linux VM, so a few host-side details differ. Where that matters, there's a callout.

### Addresses, CIDR and subnets

- **Problem it solves:** computers need a unique, routable name for "where" they are, and you need to carve one big address range into smaller pieces (for different tiers, different zones, different security rules).
- **How it works:** an IPv4 address is 32 bits, written as four numbers (`10.0.1.25`). A **CIDR block** such as `10.0.1.0/24` means "the first 24 bits are fixed; the remaining 8 bits can vary". Number of addresses = 2^(32 − prefix). So `/24` = 2^8 = **256** addresses, `/16` = 2^16 = **65,536**, `/28` = 2^4 = **16**. A **subnet** is one such slice of a bigger block.

  Worked example. Split `10.0.0.0/16` into `/24` blocks. A `/16` fixes the first two numbers (`10.0`); a `/24` fixes the first three, so the third number now chooses the block: `10.0.0.0/24`, `10.0.1.0/24`, `10.0.2.0/24`, … `10.0.255.0/24` — 2^(24−16) = **256 blocks** of 256 addresses each.

  **Private ranges.** Three ranges are reserved for private networks and are never routed on the public internet: `10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16` (RFC 1918). Your home router, Docker and AWS VPCs all use them.

  **AWS adds one rule.** In every AWS subnet, 5 addresses are reserved (the first four and the last), so a `/24` gives **251** usable addresses, not 256. A VPC's block must be between `/16` and `/28`. Source: https://docs.aws.amazon.com/vpc/latest/userguide/subnet-sizing.html and https://docs.aws.amazon.com/vpc/latest/userguide/vpc-cidr-blocks.html
- **The command that shows it:** `ip -4 addr` (your addresses, with their `/prefix`) and, in Lab 2, `subnet-calc.sh <block>`.
- **Applied in:** Labs 1 and 2.

### Ports and TCP vs UDP

- **Problem it solves:** one computer runs many network programs at once. The address gets a packet to the right computer; the **port** (0–65535) gets it to the right program.
- **How it works:** well-known ports: `22` SSH, `53` DNS, `80` HTTP, `443` HTTPS. A program that waits for connections *listens* on a port; the client uses a random high port for its side. **TCP** sets up a connection and guarantees delivery in order (web pages, SSH, databases). **UDP** just sends packets with no connection or delivery guarantee (DNS lookups, video calls; HTTP/3 also uses UDP).
- **The command that shows it:** `ss -tln` lists the TCP ports a machine is listening on.
- **Applied in:** Lab 3.

### DNS: turning a name into an address

- **Problem it solves:** people use names (`example.com`); networks route addresses.
- **How it works:** your computer asks a **resolver** (a DNS server it's configured with). If the resolver doesn't already have the answer cached, it asks the **root** servers, which point to the `.com` servers, which point to the servers that are **authoritative** for `example.com`, which give the answer. The answer carries a **TTL** (how many seconds it may be cached). "Could not resolve host" means this step failed, before any connection was tried.
- **The command that shows it:** `dig example.com` shows the answer and the TTL; `dig +trace example.com` shows the walk from the root; `cat /etc/resolv.conf` shows which resolver this machine uses.
- **Applied in:** Lab 1 and the debugging lab.
- **Source:** https://www.rfc-editor.org/rfc/rfc1035

### Routing, default routes and NAT

- **Problem it solves:** a packet for an address that is not on your local network must be handed to *something* that knows the way.
- **How it works:** a **route table** is a list of "destination block → next hop". The most specific match wins. The entry `0.0.0.0/0` matches everything, so it is the **default route**: "if nothing more specific matches, send it here" (usually your router). No default route means "Network is unreachable" for anything outside your own network.

  **NAT** (network address translation) solves a different problem: private addresses (`10.x`, `172.16.x`, `192.168.x`) can't be used on the internet. A NAT device rewrites the *source* address of outgoing packets to its own public address, remembers the mapping, and rewrites the replies on the way back. That's why many devices at home share one public IP, and why a private AWS subnet needs a NAT gateway to reach the internet (0.5). The internet can't start a connection *to* a NATed device, only answer one it started.
- **The command that shows it:** `ip route` (the route table) and `curl -s https://checkip.amazonaws.com` (the public address the internet sees; compare it with `ip -4 addr`).
- **Applied in:** Lab 1 and the debugging lab.

### Firewalls and security groups

- **Problem it solves:** by default anything that can reach a port can talk to the program behind it. A firewall decides which traffic is allowed.
- **How it works:** an **allow-list** firewall permits only what you list and drops the rest. AWS **security groups** work that way: a new security group has *no* inbound rules (everything inbound is dropped) and allows all outbound. They are **stateful**: if you allow a request in, the reply is allowed out automatically, with no separate rule. The other AWS firewall, the **network ACL**, is **stateless** and checks each direction separately. (Named here; built in 0.5.) Source: https://docs.aws.amazon.com/vpc/latest/userguide/vpc-security-groups.html
- **The command that shows it:** you'll see a blocked connection as a *timeout* (the packet is silently dropped), unlike a closed port, which fails *immediately* with "connection refused". That difference (Lab 3) tells you which one you're fighting.
- **Applied in:** Lab 3; built for real in 0.5.

### HTTP and TLS at a glance

- **Problem it solves:** two programs need an agreed way to ask for things and answer, and to do it privately.
- **How it works:** an **HTTP request** is a method and path (`GET /`), headers, and sometimes a body. The **response** has a **status code** (`200` ok, `301` moved, `403` forbidden, `404` not found, `500` the server crashed, `502`/`503`/`504` a proxy or load balancer couldn't get an answer from the server), headers and a body. **HTTPS** is HTTP inside **TLS**: before any HTTP is sent, the two sides agree on encryption keys and the server proves its identity with a **certificate** signed by an authority your computer trusts.
- **The command that shows it:** `curl -v <url>`. Lines starting `*` are curl's own notes, `>` is the request you sent, `<` is the response.
- **Applied in:** Lab 4.

### What happens when you type a URL and press Enter

You need to be able to say this out loud:

1. The browser asks a **DNS** resolver for the address of the name.
2. It opens a **TCP** connection to that address on port 443 (80 for plain HTTP). Packets cross your network's **default route**, and (if you're on a private address) a **NAT** device.
3. On the way in, a **firewall** (security group) allows or drops the traffic.
4. **TLS** handshake: certificate checked, keys agreed.
5. The browser sends the **HTTP request**; the server answers with a status code and a body.

### The most common error messages (keep this table)

| You see | Layer | It usually means | First thing to check |
|---|---|---|---|
| `curl: (6) Could not resolve host` | DNS | the name couldn't be turned into an address | spelling; `dig <name>`; `cat /etc/resolv.conf` |
| `ping: connect: Network is unreachable` | routing | no route (often no default route) | `ip route` |
| `curl: (7) Failed to connect … Connection refused` | TCP | the machine answered; nothing is listening on that port | `ss -tln` on the server; the port number |
| `curl: (28) … timed out` | firewall / routing | packets are being dropped or going nowhere | security group, route table, firewall |
| `curl: (60)` certificate problem | TLS | certificate expired, wrong name or untrusted | `curl -v` and read the certificate lines |
| `HTTP 404` | application | the server is fine; that path doesn't exist | the URL path |
| `HTTP 502 / 503 / 504` | proxy / load balancer | it couldn't get a good answer from the server behind it | the server's health and logs |

Source for curl's exit codes: https://curl.se/libcurl/c/libcurl-errors.html

## 6. Labs

> **Region:** none. Nothing here touches AWS.
>
> **Where to type commands:** your Linux shell from 0.1 (Ubuntu on WSL, Terminal on macOS, or your Linux terminal). Lines starting with `#` are comments.
>
> **Network note:** some networks (offices, schools, some mobile data plans) block `ping` and `traceroute`. If a probe times out, that is an *explained outcome*, not a failure of the lab: write down what you saw and why.

Set up two helpers once per terminal:

```bash
export COURSE=~/aws-devops-course
export LABS="$COURSE/phases/phase-0/02-networking/labs"
d() { docker exec p0-net-tools "$@"; }      # "run this inside the toolbox container"
```

### Lab 1 — Probe real targets

- **Region:** none.
- **Task:** start a throwaway Linux container as a **toolbox**, install the network tools in it (so your own computer stays untouched), then probe the network as a program would.

```bash
docker run -d --name p0-net-tools ubuntu:noble-20261110 sleep infinity
docker exec -i p0-net-tools bash -s < "$LABS/install-tools.sh"
```

Now look at the container's own network, then probe outwards:

```bash
d ip -4 addr show eth0                        # your container's private address
d ip route                                    # the route table
d cat /etc/resolv.conf                        # which DNS resolver it uses
d dig +noall +answer example.com              # DNS: name -> address, with TTL
d dig +trace example.com | head -20           # DNS: the walk from the root servers
d ping -c 3 1.1.1.1                           # reachability (ICMP)
d traceroute -n -w 2 -m 10 1.1.1.1            # the hops between you and the target
d curl -sS -o /dev/null -w 'status=%{http_code} ip=%{remote_ip} time=%{time_total}s\n' https://example.com
d curl -s https://checkip.amazonaws.com       # the PUBLIC address the internet sees
```

- **Expected result** (shapes, not exact values):
  - `ip -4 addr`: an `inet 172.x.x.x/16` line, a private address.
  - `ip route`: a line starting `default via 172.…` and one for the local `172.…/16` block.
  - `dig`: a line like `example.com.  <ttl>  IN  A  <address>`.
  - `ping`: `3 packets transmitted, 3 received, 0% packet loss` (or `100% packet loss` on a network that blocks ICMP).
  - `traceroute`: numbered hops; rows of `* * *` are routers that don't answer and are normal.
  - `curl`: `status=200 ip=<address> time=<seconds>s`.
  - `checkip`: a public address that is **different** from the `172.x` address above. That difference is NAT, made visible.
- **Verification command:**

```bash
d curl -sS -o /dev/null -w '%{http_code}\n' https://example.com      # expect: 200
```

Write one line each: which of your outputs shows DNS working, which shows a default route, and which shows NAT?

- **Teardown command:** none yet. The toolbox container is reused in Lab 4 and removed in section 9.
- **Cost note:** USD 0.

### Lab 2 — Subnetting by hand

- **Region:** none.
- **Task:** do the arithmetic **first on paper**, then check yourself with the calculator.

Answer these without any tool:

1. How many addresses are in `10.0.0.0/16`, `10.0.1.0/24` and `10.0.0.0/28`?
2. How many are *usable* in an AWS subnet of each size?
3. Write the first four `/24` blocks inside `10.0.0.0/16`.
4. What is the last address of `10.0.1.0/24`? Which `/24` block contains `10.0.7.200`?
5. A VPC is `10.0.0.0/16`. Plan three subnets: two public (in two availability zones) and one private. Pick non-overlapping `/24` blocks.

Now check:

```bash
"$LABS/subnet-calc.sh" 10.0.1.0/24
"$LABS/subnet-calc.sh" 10.0.0.0/28
"$LABS/subnet-calc.sh" --split 10.0.0.0/16 24 4
"$LABS/subnet-calc.sh" 10.0.7.200/24            # it tells you which block that address belongs to
```

The calculator is plain `bash` integer arithmetic, so it runs on any OS with no setup.

- **Expected result:** `10.0.1.0/24` → 256 addresses, 251 usable, last address `10.0.1.255`. `10.0.0.0/28` → 16 addresses, 11 usable. The split lists `10.0.0.0/24` … `10.0.3.0/24`. For question 5, the course uses `10.0.1.0/24` and `10.0.2.0/24` (public) and `10.0.11.0/24` (private); any three that don't overlap are correct.
- **Verification command:**

```bash
"$LABS/subnet-calc.sh" --split 10.0.0.0/16 24 1 | head -1
# expect: 10.0.0.0/16 splits into 256 blocks of /24 (each 256 addresses). First 1:
```

- **Teardown command:** none (nothing was created).
- **Cost note:** USD 0.

### Lab 3 — Two containers, two networks

- **Region:** none.
- **Task:** build two isolated networks, put a tiny web server on one and a client on the other, and watch them fail to talk, then succeed once you connect them. A Docker **user-defined network** behaves like a small VPC: its own address block, its own DNS, isolated from other networks.

```bash
docker network create p0-net-a
docker network create p0-net-b
docker run -d --name p0-net-web    --network p0-net-a ubuntu:noble-20261110 sleep infinity
docker run -d --name p0-net-client --network p0-net-b ubuntu:noble-20261110 sleep infinity
for c in p0-net-web p0-net-client; do docker exec -i "$c" bash -s < "$LABS/install-tools.sh"; done

# start a web server in p0-net-web, on port 8080
docker exec p0-net-web bash -c 'mkdir -p /srv/www && echo "hello from p0-net-web" > /srv/www/index.html'
docker exec -d p0-net-web python3 -m http.server 8080 --directory /srv/www
sleep 1
docker exec p0-net-web ss -tln                 # which ports is it listening on?
docker exec p0-net-web curl -sS http://localhost:8080
```

Now try from the **client**, which is on a different network:

```bash
WEB_IP="$(docker inspect -f '{{(index .NetworkSettings.Networks "p0-net-a").IPAddress}}' p0-net-web)"
echo "web server address: $WEB_IP"
docker exec p0-net-client curl -sS -m 5 http://p0-net-web:8080     # by NAME
docker exec p0-net-client curl -sS -m 5 "http://$WEB_IP:8080"      # by ADDRESS
```

- **Expected result (before connecting):** the by-name request fails with `curl: (6) Could not resolve host: p0-net-web` (Docker's DNS only knows names on networks a container is attached to). The by-address request hangs for 5 seconds, then fails with a `curl: (28)` timeout (the networks are isolated, so the packets are silently dropped). *Two different errors, two different layers. Write down which is which.*

Now connect the client to the web server's network:

```bash
docker network connect p0-net-a p0-net-client
docker exec p0-net-client ip -br -4 addr                           # two network cards now
docker exec p0-net-client curl -sS -m 5 http://p0-net-web:8080    # by name
docker exec p0-net-client ping -c 2 p0-net-web
```

- **Expected result (after connecting):** `hello from p0-net-web`; `ping` shows `0% packet loss`; `ip -br -4 addr` lists two interfaces (`eth0` on one network, a second one on the other). A container on two networks is like a server with a network card in two subnets.
- **Verification command:**

```bash
docker network inspect p0-net-a --format '{{range .Containers}}{{.Name}} {{end}}'
# expect both names, in any order: p0-net-web p0-net-client
```

> **macOS (Docker Desktop):** every command above runs *inside* containers, so the output matches. What does differ: you can't reach a container's private address from your Mac itself, because the containers live inside Docker Desktop's VM. That is not tested here.

- **Teardown command:** removed together with everything else in section 9. Keep both containers and both networks for Lab 4.
- **Cost note:** USD 0.

### Lab 4 — Read an HTTP exchange

- **Region:** none.
- **Task:** read the full conversation between a client and two servers: a real HTTPS site, and your plain-HTTP server from Lab 3.

```bash
# 1. The HTTPS exchange: only curl's notes (*), your request (>) and the response (<)
d bash -c "curl -sS -v -o /dev/null https://example.com 2>&1 | grep -E '^[*<>]' | head -60"

# 2. The plain-HTTP exchange against your own server
docker exec p0-net-client curl -sS -v -o /dev/null http://p0-net-web:8080/ 2>&1 | grep -E '^[*<>]'

# 3. A path that doesn't exist
docker exec p0-net-client curl -sS -o /dev/null -w 'status=%{http_code}\n' http://p0-net-web:8080/nope
```

Find and write down, from the output of command 1:

- **(a)** the address curl connected to (a `Connected to … port 443` line);
- **(b)** the TLS version (a `SSL connection using TLSv…` line);
- **(c)** who issued the certificate and when it expires (`issuer:` and `expire date:` lines);
- **(d)** the request line you sent (`> GET / …`) and the status line you got back (`< HTTP/… 200`).

From command 2: what is different about the request and response lines compared with HTTPS? (No TLS lines at all: anyone on the path could read it.)

- **Expected result:** (a)–(d) all found. Command 2 shows `> GET / HTTP/1.1`, a `Host: p0-net-web:8080` header and `< HTTP/1.0 200 OK`. Command 3 shows `status=404`. The exact wording of curl's notes can vary a little between curl versions; look for the pieces named above rather than exact lines.
- **Verification command:**

```bash
docker exec p0-net-client curl -sS -o /dev/null -w '%{http_code}\n' http://p0-net-web:8080/       # expect: 200
docker exec p0-net-client curl -sS -o /dev/null -w '%{http_code}\n' http://p0-net-web:8080/nope   # expect: 404
```

- **Teardown command:** none yet. Everything is removed in section 9.
- **Cost note:** USD 0.

## 7. Debugging lab

- **Scenario:** a container "can't reach the internet". Nothing was changed on purpose, and the person who built it has gone home. You have a shell and the tools from this module.
- **How to create the broken state:**

```bash
bash "$LABS/debug-no-internet/break.sh"
```

- **Symptom you will see:**

```bash
docker exec p0-net-broken curl -sS -m 5 https://example.com
# curl: (6) Could not resolve host: example.com
```

- **Your task:** there are **two separate causes**. Find them with the tools from this module, working **from the bottom up**: first test whether packets can leave at all *without* using a name, then test names, then test the application. Fix one at a time and re-test after each fix. For each cause, write **one sentence**: which layer was broken, and which command proved it. Don't recreate the container; fix it in place. You can read and change its network settings from the host with `docker exec p0-net-broken <command>` (the container has `ip`, `ping`, `dig` and `curl`, and was started with permission to change its own routes).

  Hints that don't give it away: `ping` takes an *address*, so it works even when naming is broken; `dig <name> @<resolver-address>` lets you ask a specific resolver; a route you need can be added with `ip route add`, and the gateway address of Docker's default network is shown by `docker network inspect bridge`.
- **Done when:**

```bash
docker exec p0-net-broken curl -sS -m 10 -o /dev/null -w '%{http_code}\n' https://example.com    # expect: 200
docker exec p0-net-broken ip route | head -1                                                      # expect: a line starting "default via"
docker exec p0-net-broken cat /etc/resolv.conf                                                    # expect: a nameserver line that is NOT 192.0.2.53
```

- **Teardown:** `docker rm -f p0-net-broken` (also in section 9).

The diagnosis path and model explanations are in `solutions/debugging-lab.md`.

## 8. Self-check

Answers: `solutions/self-check.md`.

1. Without notes, walk through what happens between typing a URL and seeing the page. Name at least DNS, TCP, TLS and HTTP, and where a default route, NAT and a firewall appear.
2. How many addresses are in `10.0.0.0/20`? How many are usable in an AWS subnet? What is its last address? (Check with the calculator after answering.)
3. `curl` fails with `(6)`, then `(7)`, then `(28)` on three different days. What is the first thing you check for each?
4. What does a security group's default-deny block, inbound or outbound? Why don't you need a rule for the *reply* to an allowed request?
5. Why does a server in a private subnet need a NAT gateway to download software updates, and why can't the internet use that NAT gateway to reach the server?
6. In Lab 3, why did the by-name request fail with `(6)` and the by-address request with `(28)`?
7. Name the command that shows: your default route; which DNS server you use; what address a name resolves to; which ports a machine is listening on.

## 9. Teardown

```bash
# 1. Containers (all four, whether or not you finished every lab)
docker rm -f p0-net-tools p0-net-web p0-net-client p0-net-broken 2>/dev/null

# 2. Networks (after the containers that use them are gone)
docker network rm p0-net-a p0-net-b 2>/dev/null
```

**Confirm nothing is left:**

```bash
docker ps -a --filter name=p0-net --format '{{.Names}}'            # expect: no output
docker network ls --filter name=p0-net --format '{{.Name}}'         # expect: no output
```

Kept on purpose: Docker itself, the `ubuntu:noble-20261110` image (later modules reuse it) and the `~/aws-devops-course` clone.

## 10. Last verified

- **Date:** NOT YET VERIFIED BY A HUMAN. Drafted 2026-11-18. (`lastVerified: null`; only a human who runs every command may set it.)
- **Verified by:** —
- **Region:** none (no AWS resources).
- **Versions:** Ubuntu 24.04 · Docker `docker.io` 29.1.3-0ubuntu3~24.04.2 · Docker Desktop (macOS) 4.99.0 · image `ubuntu:noble-20261110` · in the container: `ca-certificates` 20260816ubuntu0.24.04.2 · `curl` 8.5.0-2ubuntu10.16 · `bind9-dnsutils` 1:9.18.39-0ubuntu0.24.04.9 · `iputils-ping` 3:20240117-1ubuntu0.1 · `traceroute` 1:2.1.5-1 · `iproute2` 6.1.0-1ubuntu6.4 · `python3` 3.12.3-0ubuntu2.1.
- **Notes (author dry-run, not a verification):** the apt versions above were read from the Ubuntu 24.04 archive on 2026-11-18. `subnet-calc.sh` was run on Ubuntu 24.04 (bash 5.2) for all the examples in Lab 2, and its error cases were checked; `install-tools.sh` and `break.sh` were syntax-checked and linted with `shellcheck`. `curl` 8.5.0's `-v` output shapes (the `*`, `>`, `<` lines, the `Host … was resolved`, `ALPN` and `SSL connection using TLSv1.3` notes) and exit codes 6 and 7 were observed against local test servers. **Not run:** every Docker command (Docker was not available where this was drafted), `dig`, `ping`, `traceroute`, anything that needs the public internet, and macOS. The `(28)` timeout between isolated Docker networks in Lab 3 is the documented isolation behaviour and has not been observed here.
