#!/bin/bash
# Runs once, at first boot, on the PRIVATE instance in Lab 5.
# It proves outbound internet works through the NAT gateway: it asks the internet "what address am I?",
# then writes the answer to S3 using the instance's role (no keys). Replace __BUCKET__ before use (the lab shows how).
BUCKET="__BUCKET__"
for _ in $(seq 1 30); do
  IP="$(curl -sS -m 10 https://checkip.amazonaws.com 2>/dev/null | tr -d '[:space:]')"
  if [ -n "$IP" ]; then
    echo "$IP" > /tmp/egress-ip.txt
    aws s3 cp /tmp/egress-ip.txt "s3://$BUCKET/nat-proof/egress-ip.txt" --region us-east-1 && exit 0
  fi
  sleep 10
done
exit 1
