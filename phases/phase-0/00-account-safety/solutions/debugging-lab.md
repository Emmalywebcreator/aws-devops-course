# Solution · Module 0.0 debugging lab — "the billing alarm never fired"

> Not linked from the module. Read after you've tried.

## The two causes

| # | Cause | Why it breaks the alarm |
|---|---|---|
| 1 | The alarm and its topic are in **`eu-west-1`**, not `us-east-1`. | AWS publishes the `AWS/Billing` `EstimatedCharges` metric **only in `us-east-1`**. An alarm in any other region watches a metric that never gets data, so it sits in `INSUFFICIENT_DATA` forever and can never go to `ALARM`. |
| 2 | The email subscription is **unconfirmed** (`PendingConfirmation`). | SNS sends nothing to an email address until its owner clicks the confirmation link. Even a correctly placed alarm would notify nobody. |

Source for 1: https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/monitor_estimated_charges_with_cloudwatch.html
Source for 2: https://docs.aws.amazon.com/sns/latest/dg/sns-email-notifications.html

## Diagnosis path

**Step 1 — Does the alarm exist where I'm looking?**

```bash
export AWS_REGION=us-east-1
aws cloudwatch describe-alarms --alarm-names p0-debug-billing-alarm \
  --query 'MetricAlarms[].AlarmName' --output text
```

Prints nothing → the alarm isn't in `us-east-1`. That's why `set-alarm-state` said it couldn't be found. Most resources belong to **one region**, and the CLI only looks in the region you give it.

**Step 2 — Where is it, then?**

```bash
for r in $(aws ec2 describe-regions --query 'Regions[].RegionName' --output text); do
  aws cloudwatch describe-alarms --region "$r" --alarm-names p0-debug-billing-alarm \
    --query 'MetricAlarms[].[AlarmName,StateValue]' --output text | sed "s/^/$r\t/"
done
```

→ `eu-west-1  p0-debug-billing-alarm  INSUFFICIENT_DATA`. `INSUFFICIENT_DATA` + a billing metric outside `us-east-1` = cause 1. (Learners who remember the Concepts table may jump straight to `--region eu-west-1` — also fine.)

**Step 3 — Would anyone receive the notification?**

```bash
T="$(aws sns list-topics --region eu-west-1 \
  --query "Topics[?ends_with(TopicArn, ':p0-debug-billing-alerts')].TopicArn" --output text)"
aws sns list-subscriptions-by-topic --region eu-west-1 --topic-arn "$T" \
  --query 'Subscriptions[].[Endpoint,SubscriptionArn]' --output text
```

→ `you@…  PendingConfirmation` = cause 2.

A learner who finds only cause 1 and moves the alarm will see the test still produce no email — which should send them to step 3. **Finding only one cause is not done.**

## Fix

```bash
export AWS_REGION=us-east-1

# Remove the broken copies in eu-west-1
aws cloudwatch delete-alarms --region eu-west-1 --alarm-names p0-debug-billing-alarm
aws sns delete-topic --region eu-west-1 --topic-arn "$T"

# Recreate in us-east-1
TOPIC_ARN="$(aws sns create-topic --name p0-debug-billing-alerts --query TopicArn --output text)"
aws sns subscribe --topic-arn "$TOPIC_ARN" --protocol email --notification-endpoint "$ALERT_EMAIL"
#   → click "Confirm subscription" in the new email, then check:
aws sns list-subscriptions-by-topic --topic-arn "$TOPIC_ARN" \
  --query 'Subscriptions[].SubscriptionArn' --output text        # an ARN, not PendingConfirmation

aws cloudwatch put-metric-alarm \
  --alarm-name p0-debug-billing-alarm \
  --namespace AWS/Billing --metric-name EstimatedCharges \
  --dimensions Name=Currency,Value=USD \
  --statistic Maximum --period 21600 --evaluation-periods 1 \
  --threshold 5 --comparison-operator GreaterThanThreshold \
  --alarm-actions "$TOPIC_ARN"

aws cloudwatch set-alarm-state --alarm-name p0-debug-billing-alarm \
  --state-value ALARM --state-reason "debug test"                 # email arrives
```

Keep the alarm and its topic together in `us-east-1` — the "Done when" checks expect the topic there. Accept any fix where those checks pass.

## Model explanation (what the learner should write)

> The alarm was in eu-west-1, but AWS only publishes billing data in us-east-1, so the alarm had nothing to watch and could never trigger. The email subscription had never been confirmed, so even a working alarm would have sent nothing to me. I moved the topic and alarm to us-east-1, confirmed the subscription, and proved it with a test notification.

## Then: teardown

Run the Teardown block in section 7 of the module. It removes `p0-debug-*` in both regions.
