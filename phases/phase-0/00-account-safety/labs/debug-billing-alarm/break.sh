#!/usr/bin/env bash
# Module 0.0 debugging lab — creates a deliberately broken billing alarm.
# Learners: run this, don't read it. The diagnosis is in ../../solutions/debugging-lab.md.
set -euo pipefail

: "${ALERT_EMAIL:?Set ALERT_EMAIL to your email address first: export ALERT_EMAIL=you@example.com}"

BROKEN_REGION="eu-west-1"   # deliberately wrong — billing metrics only exist in us-east-1

TOPIC_ARN="$(aws sns create-topic --region "$BROKEN_REGION" \
  --name p0-debug-billing-alerts --query TopicArn --output text)"

aws sns subscribe --region "$BROKEN_REGION" --topic-arn "$TOPIC_ARN" \
  --protocol email --notification-endpoint "$ALERT_EMAIL" >/dev/null

aws cloudwatch put-metric-alarm --region "$BROKEN_REGION" \
  --alarm-name p0-debug-billing-alarm \
  --alarm-description "Debug lab: estimated charges > 5 USD" \
  --namespace AWS/Billing --metric-name EstimatedCharges \
  --dimensions Name=Currency,Value=USD \
  --statistic Maximum --period 21600 --evaluation-periods 1 \
  --threshold 5 --comparison-operator GreaterThanThreshold \
  --alarm-actions "$TOPIC_ARN"

echo "Created billing alarm p0-debug-billing-alarm with email alerts to $ALERT_EMAIL."
echo "Do NOT click the subscription confirmation email yet."
