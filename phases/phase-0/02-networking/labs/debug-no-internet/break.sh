#!/usr/bin/env bash
# Module 0.2 debugging lab — creates a container that "can't reach the internet", for two separate reasons.
# Learners: run this, don't read it. The diagnosis is in ../../solutions/debugging-lab.md.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
NAME="p0-net-broken"

docker rm -f "$NAME" >/dev/null 2>&1 || true
docker run -d --name "$NAME" --cap-add NET_ADMIN ubuntu:noble-20261110 sleep infinity >/dev/null
docker exec -i "$NAME" bash -s < "$HERE/../install-tools.sh"

# Break 1: point the container at a DNS server that does not exist (192.0.2.0/24 is reserved for documentation, RFC 5737).
docker exec "$NAME" bash -c 'echo "nameserver 192.0.2.53" > /etc/resolv.conf'
# Break 2: remove the default route.
docker exec "$NAME" ip route del default

echo
echo "Container $NAME is running and 'broken'. Symptom: docker exec $NAME curl -sS -m 5 https://example.com"
