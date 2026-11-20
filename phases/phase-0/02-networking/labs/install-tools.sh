#!/usr/bin/env bash
# install-tools.sh — install the network tools INSIDE a container (never on your computer).
# Run it like:   docker exec -i <container> bash -s < install-tools.sh
# Versions are the Ubuntu 24.04 (noble) packages seen on 2026-11-18. If apt says a version "was not found",
# the archive has moved on: run `apt-cache policy <package>` inside the container and use the Candidate version.
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq --no-install-recommends \
  ca-certificates=20260816ubuntu0.24.04.2 \
  curl=8.5.0-2ubuntu10.16 \
  bind9-dnsutils=1:9.18.39-0ubuntu0.24.04.9 \
  iputils-ping=3:20240117-1ubuntu0.1 \
  traceroute=1:2.1.5-1 \
  iproute2=6.1.0-1ubuntu6.4 \
  python3=3.12.3-0ubuntu2.1 >/dev/null
echo "tools installed: $(curl --version | head -1 | cut -d' ' -f1-2), $(dig -v 2>&1), $(python3 --version)"
