# Solution · 0.2 debugging lab — "a container can't reach the internet"

> Not linked from the module. Try it first.

## The two causes

| # | Cause | Layer | The command that proves it | Fix |
|---|---|---|---|---|
| 1 | **No default route.** `break.sh` ran `ip route del default`. | Routing | `ping -c 2 -W 3 1.1.1.1` → `ping: connect: Network is unreachable` (instant, not a timeout). `ip route` shows only the local `172.x.x.x/16` block, no `default via …` line. | Add the default route back, pointing at Docker's gateway (below). |
| 2 | **Bogus DNS server.** `break.sh` set `nameserver 192.0.2.53` (a documentation-only address, RFC 5737, that nothing answers). | DNS | `dig +time=2 +tries=1 example.com` → `communications error to 192.0.2.53#53: timed out` / `no servers could be reached`. `cat /etc/resolv.conf` shows the address. `dig +short example.com @1.1.1.1` **works**, which proves the network is fine and only the configured resolver is wrong. | Point `/etc/resolv.conf` at a working resolver. |

## Diagnosis path (bottom up)

1. **Reproduce the symptom.** `docker exec p0-net-broken curl -sS -m 5 https://example.com` → `curl: (6) Could not resolve host`. That *looks* like a DNS problem, but `(6)` can only tell you the name failed; it can't tell you why. Before blaming DNS, check whether packets can leave at all.
2. **Test without a name.** `docker exec p0-net-broken ping -c 2 -W 3 1.1.1.1`. An address needs no DNS. `Network is unreachable` appears instantly, which means the kernel has no route for that address: not a firewall (that would time out), not DNS. `docker exec p0-net-broken ip route` confirms there is no `default` line.
3. **Fix the route.** Find the gateway the container should use. From your **host**: `docker network inspect bridge --format '{{(index .IPAM.Config 0).Gateway}}'` (typically `172.17.0.1`). Then:
   ```bash
   GW="$(docker network inspect bridge --format '{{(index .IPAM.Config 0).Gateway}}')"
   docker exec p0-net-broken ip route add default via "$GW"
   docker exec p0-net-broken ping -c 2 -W 3 1.1.1.1      # 0% packet loss now
   ```
4. **Test a name.** `curl` still gives `(6)`. Now the evidence points at DNS for real: `dig +time=2 +tries=1 example.com` times out talking to `192.0.2.53`. Ask a known-good resolver directly: `dig +short example.com @1.1.1.1` returns an address. Network fine, resolver wrong.
5. **Fix DNS.** `docker exec p0-net-broken bash -c 'echo "nameserver 1.1.1.1" > /etc/resolv.conf'`.
6. **Test the application.** `docker exec p0-net-broken curl -sS -m 10 -o /dev/null -w '%{http_code}\n' https://example.com` → `200`.

## The third suspect that was *not* the problem

An **egress block** (for example a container attached only to an `--internal` Docker network) would also stop traffic, but it looks different: `ip route` would show no default route *by design*, and `docker network inspect <network> --format '{{.Internal}}'` would print `true`. Here the container is on the normal `bridge` network, so that suspect is ruled out by `docker inspect p0-net-broken --format '{{json .NetworkSettings.Networks}}'` (network name `bridge`). Ruling a suspect *out* with a command is part of the skill.

## Model explanations

1. The container had no default route, so the kernel had nowhere to send traffic for any address outside its own block (`ip route` showed no `default` line; `ping 1.1.1.1` failed instantly with "Network is unreachable").
2. Its DNS server was set to an address that doesn't answer, so names never resolved even once packets could leave (`dig` timed out against `192.0.2.53`, while `dig @1.1.1.1` worked).

## Why this order matters

`curl: (6)` was the *first* thing you saw but the *second* thing broken. If you had fixed DNS first, `curl` would have moved on to `(7)` or `(28)`, with no sign that DNS had been the lesser problem. Testing the lowest layer first (address → name → application) finds the real order every time.

Sources: https://curl.se/libcurl/c/libcurl-errors.html · https://www.rfc-editor.org/rfc/rfc5737 · https://docs.docker.com/engine/network/
