# Solution · Module 0.0 self-check

> Not linked from the module.

**1. Billing alarm vs budget.**
A CloudWatch billing alarm watches one number — estimated month-to-date charges, published only in `us-east-1` — and notifies when it crosses one threshold. An AWS Budget tracks actual (or forecasted) spend against a limit and can alert at several thresholds (here 50/80/100%). **Neither stops, caps or deletes anything** — charges keep accruing until you remove the resource.
Sources: https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/monitor_estimated_charges_with_cloudwatch.html · https://docs.aws.amazon.com/cost-management/latest/userguide/budgets-managing-costs.html

**2. Why root is dangerous.**
Root has unrestricted access that no IAM policy can limit — including billing, payment method and closing the account. A stolen root credential means the attacker owns the account and its bill. Lab 2: MFA on root, confirmed no root access keys, and stopped using it (daily work via the admin IAM user).
Source: https://docs.aws.amazon.com/IAM/latest/UserGuide/root-user-best-practices.html

**3. Which identity is the CLI using?**
`aws sts get-caller-identity` (with `--profile p0-admin` or `AWS_PROFILE` set). Proof it's not root: `Arn` is `arn:aws:iam::<id>:user/<admin-user>`, not `arn:aws:iam::<id>:root`.

**4. Root MFA and no keys.**
`aws iam get-account-summary --query 'SummaryMap.[AccountMFAEnabled,AccountAccessKeysPresent]' --output text` → `1	0`.
Source: https://docs.aws.amazon.com/IAM/latest/APIReference/API_GetAccountSummary.html

**5. Alarm stuck in `INSUFFICIENT_DATA`.**
(a) Alarm is not in `us-east-1` — check `aws cloudwatch describe-alarms --region us-east-1 --alarm-names <name>`. (b) Billing alerts were never turned on — check **Billing preferences → Alert preferences → Receive CloudWatch billing alerts**. (Also accept: metric/dimension typo, e.g. missing `Currency=USD`.) Note: an *unconfirmed SNS subscription* doesn't cause `INSUFFICIENT_DATA` — it causes a silent `ALARM`.

**6. Cost Explorer doesn't show a 20-minute-old instance.**
Billing data is processed with a delay; Cost Explorer refreshes at least every 24 hours. Use `aws ec2 describe-instances` (looped over every region from `aws ec2 describe-regions`) to see what's running now.
Source: https://docs.aws.amazon.com/cost-management/latest/userguide/ce-what-is.html

**7. "100% of USD 5 exceeded".**
No — nothing has stopped. Next 10 minutes: sign in as the admin user; open Cost Explorer / Bills and group by **service** and **region** to find the source; run the all-region instance sweep; terminate/delete what you don't need; re-run the sweep to prove it's gone. If you see a service or region you never used, treat it as a possible compromise: change passwords, check IAM users/access keys, and contact AWS Support.
