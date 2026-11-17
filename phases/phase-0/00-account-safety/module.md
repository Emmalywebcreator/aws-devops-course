---
phase: "phase-0"
moduleId: "0.0"
title: "Account safety & billing guardrails"
goal: "Set up an AWS account that warns you before money surprises you: root locked with MFA, a daily-use admin identity, a billing alarm, a budget and anomaly alerts \u2014 and prove it by finding and killing a forgotten server."
timeEstimate: "3-4h"
costEstimate: "<$0.10"
costAssumptions: "us-east-1, on-demand, no free tier assumed, author's unit prices as of 2026-11-17 (not yet checked against AWS pricing pages); if you skip teardown \u2248 $0.39/day"
lastVerified: null
prerequisites: []
hasDebuggingLab: true
hasTeardown: true
toolsPinned:
  "awscli": "2.33.14"
---

# Phase 0 · Module 0.0 — Account safety & billing guardrails

## 1. Goal

Set up an AWS account that warns you before money surprises you: root locked with MFA, a daily-use admin identity, a billing alarm, a budget and anomaly alerts — and prove it by finding and killing a forgotten server.

## 2. Prerequisites

- **Modules:** none. This is the first module, and you do it **before touching any AWS service**.
- **You need:**
  - An email address you can dedicate to this AWS account (a new address, or a "plus" alias like `you+aws-course@gmail.com` if your provider supports it).
  - A **password manager** (any reputable one — Bitwarden, 1Password, KeePassXC, your browser's built-in manager).
  - A **phone with an authenticator app** (for MFA — e.g. Google Authenticator, Microsoft Authenticator, or the one in your password manager).
  - A **payment card**. AWS requires one to open an account, even if you never pay anything.
  - A computer with a web browser. On Windows, macOS or Linux.
- **No Linux needed yet.** Every command here is copy-paste. When a lab runs a shell command, you can type it into **AWS CloudShell** — a terminal inside your browser that AWS provides free (Lab 2c shows you how).

## 3. Time estimate

**3–4 hours of active work**, plus a **15-minute check the next day** (billing data takes hours to arrive — you'll see why in Lab 7).

| Lab | Time |
|---|---|
| 1 — Create the account | 30–45 min (identity/phone verification can be slow) |
| 2 — Lock root, create admin user | 30–45 min |
| 3 — Install AWS CLI v2 + named profile | 30–45 min |
| 4 — Billing alarm | 20–30 min |
| 5 — Budget with 50/80/100% alerts | 15–20 min |
| 6 — Cost Anomaly Detection | 10–15 min |
| 7 — The forgotten instance (teardown lab) | 35 min (20 of it is waiting) + 5 min next day |
| Debugging lab | 20–30 min |

## 4. Cost estimate

| Resource | Billed while idle? | Unit price (assumption) | Expected use in this module | Cost |
|---|---|---|---|---|
| EC2 `t3.micro` (Lab 7) | yes, per second while running | USD 0.0104/hour | ≤ 30 min | ≤ USD 0.006 |
| EBS gp3 root volume, 8 GiB (Lab 7) | yes, while it exists | USD 0.08/GB-month | ≤ 30 min | ≤ USD 0.001 |
| Public IPv4 address (Lab 7) | yes, while attached | USD 0.005/hour | ≤ 30 min | ≤ USD 0.003 |
| CloudWatch alarms (Lab 4, `us-east-1`) | yes, monthly | USD 0.10 per alarm metric per month; free tier covers **10 alarm metrics** (a simple alarm = 1 metric; a metric-math alarm counts each metric it uses) | 1 kept (1 metric) | USD 0 (within the free 10) |
| CloudWatch alarm + SNS topic (debugging lab, **`eu-west-1`** and `us-east-1`) | alarm: monthly | Same as above; topics have no idle charge | 1–2 alarms (1 metric each) for < 1 hour, deleted in the lab's teardown | USD 0 (within the free 10) |
| SNS email notifications | per message | First 1,000 email deliveries/month free | < 20 | USD 0 |
| AWS Budgets (Lab 5) | — | Budgets without actions are free ([Budgets pricing](https://aws.amazon.com/aws-cost-management/aws-budgets/pricing/)) | 1 budget, no actions | USD 0 |
| Cost Anomaly Detection (Lab 6) | — | No charge ([Anomaly Detection FAQ](https://aws.amazon.com/aws-cost-management/aws-cost-anomaly-detection/faqs/)) | 1 monitor, 1 subscription | USD 0 |
| Cost Explorer API calls (Lab 6) | per request | USD 0.01 per paginated request ([ce-what-is](https://docs.aws.amazon.com/cost-management/latest/userguide/ce-what-is.html)); **unverified** whether anomaly calls are included — assumed yes as the worst case | ≤ 6 calls | ≤ USD 0.06 |
| CloudShell | — | No charge | a few hours | USD 0 |

- **Pricing assumptions:** Region `us-east-1` (the debugging lab briefly uses `eu-west-1`, same alarm price); on-demand Linux prices; **no free-tier credits assumed** (if your account has sign-up credits, charges come out of those first). EC2, EBS and IPv4 unit prices are the author's figures as of 2026-11-17 and are **not yet checked against the live pricing pages** — check before release at: https://aws.amazon.com/ec2/pricing/on-demand/ · https://aws.amazon.com/ebs/pricing/ · https://aws.amazon.com/vpc/pricing/ (public IPv4) · https://aws.amazon.com/cloudwatch/pricing/ · https://aws.amazon.com/sns/pricing/ · https://aws.amazon.com/aws-cost-management/aws-budgets/pricing/ · https://aws.amazon.com/aws-cost-management/aws-cost-explorer/pricing/
- **Total if you follow the teardown steps:** under **USD 0.10** (almost all of it from Lab 7 and the API calls).
- **What you keep on purpose:** the billing alarm, the budget and the anomaly subscription. They're the guardrails — they stay for the whole course and cost USD 0 within the free allowances above.
- **If you skip teardown: about USD 0.39/day** — that's the Lab 7 instance left running: (0.0104 + 0.005) × 24 h = 0.37 for compute + public IPv4, plus 8 GiB × 0.08 / 30 days = 0.02 for the disk.

## 5. Concepts

### Why one account can cost you real money

AWS bills **by the second or hour for things that exist**, not for things you use. A server you forgot about bills all night. Nothing in AWS stops by itself when you close the browser tab. Everything in this module is about *noticing* — because AWS will happily keep charging you.

### The root user

- **Problem it solves:** every account needs one identity that can't be locked out — it can close the account, change the payment method, and do anything else.
- **Why that's dangerous:** that power can't be limited by any permission policy. If someone steals the root password, they own the account and the bill. So: long random password in your password manager, MFA on, **no access keys**, and you only sign in as root for the few tasks that require it.
- **Applied in:** Labs 1–2
- **Source:** https://docs.aws.amazon.com/IAM/latest/UserGuide/root-user-best-practices.html

### MFA (multi-factor authentication)

- **Problem it solves:** passwords leak. MFA asks for a second thing — a 6-digit code from your phone — so a stolen password alone isn't enough.
- **Applied in:** Lab 2
- **Source:** https://docs.aws.amazon.com/IAM/latest/UserGuide/enable-mfa-for-root.html

### IAM user (your daily admin identity)

- **Problem it solves:** you need full access to do the course, without using root. **IAM** (Identity and Access Management) is the AWS service that decides *who* can do *what*. An **IAM user** is a named identity inside your account; you give it the `AdministratorAccess` permission, protect it with its own MFA, and use it every day instead of root. If it's ever compromised, root can still lock it out.
- **Applied in:** Lab 2
- **Source:** https://docs.aws.amazon.com/IAM/latest/UserGuide/id_users.html

### AWS CLI and named profiles

- **Problem it solves:** clicking through the web console is slow and hard to repeat. The **AWS CLI** lets you type one command instead. A **named profile** is a saved label (e.g. `p0-admin`) for "which account, which identity, which region" — so you always know who you're acting as.
- **How it gets credentials here:** `aws login` signs you in through the browser as your IAM user and gives the CLI **temporary** credentials that expire. No secret key is ever saved in a file. (Long-lived "access keys" are the classic leak — avoid them.)
- **How you check who you are:** `aws sts get-caller-identity` prints the account and identity the CLI is using right now. Run it whenever you're unsure.
- **Applied in:** Lab 3
- **Requirements:** AWS CLI **2.32.0 or later** (this course pins 2.33.14), and the IAM user needs the `SignInLocalDevelopmentAccess` managed policy or equivalent `signin:` permissions. Your admin user's `AdministratorAccess` already includes them.
- **Sources:** https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html · https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-sign-in.html · https://docs.aws.amazon.com/cli/latest/reference/sts/get-caller-identity.html

### Billing alarm vs budget vs anomaly detection

All three *notify you*. **None of them stops or deletes anything.**

| Tool | What it watches | When it tells you | Gotcha |
|---|---|---|---|
| **CloudWatch billing alarm** | One number: your *estimated charges so far this month* | When that number crosses your threshold (e.g. USD 5) | The billing metric exists **only in `us-east-1`**, and only after you turn on billing alerts. An alarm in any other region never fires. |
| **AWS Budget** | Actual (and optionally forecasted) spend against a limit you set | At each threshold you choose (50%, 80%, 100%) | Built for "am I on track this month?" — several thresholds, one place. |
| **Cost Anomaly Detection** | Your *normal* spending pattern, per service | When spend jumps unusually, even if you're nowhere near your budget | Needs some history to learn "normal"; sends a daily summary by email. |

Worked example: you leave a server running that costs about USD 0.40/day. Around day 7 the budget emails "50% of USD 5 used"; around day 11 the budget's 80% alert arrives — and once Anomaly Detection has its ~10 days of history for EC2, it can flag "EC2 spend is unusual"; around day 13 the billing alarm fires at USD 5. Each one is a chance to catch it — and the server keeps billing through all three until **you** delete it.

- **Applied in:** Labs 4–6, debugging lab
- **Sources:** https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/monitor_estimated_charges_with_cloudwatch.html · https://docs.aws.amazon.com/cost-management/latest/userguide/budgets-managing-costs.html · https://docs.aws.amazon.com/cost-management/latest/userguide/manage-ad.html (a new service needs about 10 days of history before anomalies can be detected)

### Billing data is late

- **Problem it solves (for you to understand):** billing tools show what AWS has *processed*, which lags behind what's *running* — often by hours. Cost Explorer data is refreshed at least once every 24 hours.
- **So:** to check "is anything still running?" you ask the service directly (`aws ec2 describe-instances`), never the bill.
- **Applied in:** Lab 7
- **Source:** https://docs.aws.amazon.com/cost-management/latest/userguide/ce-what-is.html

### Regions

AWS runs in many **regions** (e.g. `us-east-1` = N. Virginia). Most resources live in exactly one region, and the console only shows the region selected in the top-right corner. **This module uses `us-east-1` everywhere** — partly because billing metrics only exist there.

---

## 6. Labs

> **Console steps** below are written from AWS documentation, **UI as of 2026-11-17, not yet checked click-by-click by a human.** If a button has moved, search the console for the page name.
>
> **Where to type commands (Labs 3–7):**
> - **Option A — your own computer** after Lab 3, with `export AWS_PROFILE=p0-admin` run once per terminal.
> - **Option B — AWS CloudShell:** sign in to the console as your IAM admin user, set the region to **N. Virginia (us-east-1)**, click the CloudShell icon (a `>_` symbol in the top bar). It's already signed in as you — skip `AWS_PROFILE`. Works on any OS, including Windows. CloudShell's AWS CLI version is chosen by AWS, not pinned by this course: run `aws --version` once and write it down (it must be **2.32.0 or later** for `aws login`; any version works for the other labs).
>
> Before each lab, run: `export AWS_REGION=us-east-1`

### Lab 1 — Create the account

- **Region:** none yet (account-level).
- **Task:**
  1. In your password manager, create a new entry called **"AWS root — aws-devops-course"**. Generate a password of **at least 20 random characters**. Save the dedicated email address in the same entry.
  2. Go to https://aws.amazon.com/ and choose **Create an AWS Account** (UI as of 2026-11-17). Use the dedicated email and the generated password.
  3. Complete contact details, payment card and phone verification.
  4. AWS will ask you to choose an account plan. Read the current terms at https://aws.amazon.com/free/ before choosing. **This course's cost figures assume normal on-demand prices with no credits**, so either choice works with the course.
  5. When asked for a support plan, choose **Basic support (free)**.
  6. Sign in at https://console.aws.amazon.com/ as **Root user** with the dedicated email.
- **Expected result:** you see the AWS Console home page, signed in as root. Your password manager holds the email and password.
- **Verification command:** none yet — the CLI comes in Lab 3. Check by eye: the top-right menu shows your account name, and choosing it shows a 12-digit **Account ID**. Write the Account ID into your password manager entry.
- **Teardown command:** none. You keep this account for the whole course. (Closing an account is done as root from the Account page; don't do it now.)
- **Cost note:** USD 0. AWS may place a small temporary authorisation hold on your card to verify it.

### Lab 2 — Lock the root user and create your admin user

- **Region:** none (IAM is global). CloudShell runs in `us-east-1`.
- **Task:**

**2a. MFA on root** (console, as root — UI as of 2026-11-17)

1. Top-right account menu → **Security credentials**.
2. Under **Multi-factor authentication (MFA)** → **Assign MFA device** → **Authenticator app**.
3. Scan the QR code with your phone app, enter two consecutive codes, finish.
4. In the same page, under **Access keys**, confirm there are **none**. If any exist, delete them.

**2b. Let IAM users see billing** (console, as root — UI as of 2026-11-17)

By default even an administrator IAM user **can't see billing pages**. Only root can switch that on.

1. Top-right account menu → **Account**.
2. Find **IAM user and role access to Billing information** → **Edit** → tick **Activate IAM Access** → **Update**.

Source: https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/control-access-billing.html

**2c. Create the admin user** (CloudShell, as root — this is a one-time setup task)

Open CloudShell (region **N. Virginia / us-east-1**). Type each line; replace nothing — the `read` lines will ask you questions.

```bash
read -r -p "Admin user name (e.g. jane-admin): " ADMIN_USER
read -r -s -p "Temporary console password (paste from password manager): " ADMIN_PW; echo

aws iam create-group --group-name admins
aws iam attach-group-policy --group-name admins \
  --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
aws iam create-user --user-name "$ADMIN_USER"
aws iam add-user-to-group --group-name admins --user-name "$ADMIN_USER"
aws iam create-login-profile --user-name "$ADMIN_USER" \
  --password "$ADMIN_PW" --password-reset-required
unset ADMIN_PW

echo "Sign-in URL: https://$(aws sts get-caller-identity --query Account --output text).signin.aws.amazon.com/console"
```

What each line does: makes a group called `admins`, gives that group the AWS-managed `AdministratorAccess` policy (the `arn:aws:iam::aws:policy/...` name is the same in every account — it belongs to AWS, not to you), creates your user, puts it in the group, and gives it a console password that must be changed at first sign-in.

Before running, create a second password-manager entry **"AWS admin — <your user name>"** with a 20+ character generated password; paste it at the prompt. Save the printed sign-in URL in that entry.

**2d. MFA on the admin user, then stop using root**

1. Sign out. Open the **sign-in URL** from 2c, sign in as your admin user, set a new password (update your password manager).
2. Top-right menu → **Security credentials** → **Assign MFA device** → **Authenticator app** (UI as of 2026-11-17).
3. Sign out and sign back in as the admin user — you should now be asked for an MFA code.
4. **From here on, you never sign in as root** unless a step explicitly says so.

- **Expected result:** root has MFA and no access keys; you can sign in as the admin user with password + MFA; the admin user can open the **Billing and Cost Management** console page.
- **Verification command** (CloudShell, signed in as your **admin user**):

```bash
aws sts get-caller-identity --query Arn --output text
# expect: arn:aws:iam::<your-account-id>:user/<your-admin-user>

aws iam get-account-summary \
  --query 'SummaryMap.[AccountMFAEnabled,AccountAccessKeysPresent]' --output text
# expect: 1	0      (1 = root has MFA, 0 = root has no access keys)

aws iam list-mfa-devices --user-name "$(aws sts get-caller-identity --query Arn --output text | cut -d/ -f2)" \
  --query 'length(MFADevices)'
# expect: 1
```

- **Teardown command:** none — you keep these. (To remove the admin user later: remove its MFA device, login profile and group membership, then `aws iam delete-user`. Not now.)
- **Cost note:** USD 0. IAM has no charge.

### Lab 3 — Install AWS CLI v2 and configure a named profile

- **Region:** `us-east-1`
- **Task:** install the **pinned** AWS CLI version **2.33.14** on your own computer, then sign it in as your admin user.

**Install** (pick your OS):

| OS | Install |
|---|---|
| **Windows** | Download and run `https://awscli.amazonaws.com/AWSCLIV2-2.33.14.msi`. Then open **PowerShell**. |
| **macOS** | Download and open `https://awscli.amazonaws.com/AWSCLIV2-2.33.14.pkg`. Then open **Terminal**. |
| **Linux x86_64** | `curl -fsSLo awscliv2.zip https://awscli.amazonaws.com/awscli-exe-linux-x86_64-2.33.14.zip && unzip -q awscliv2.zip && sudo ./aws/install && rm -rf aws awscliv2.zip` |
| **Linux ARM** | Same as above with `awscli-exe-linux-aarch64-2.33.14.zip` |

Source for versioned installers: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-version.html

**Configure the profile and sign in** (same commands on every OS):

```bash
aws --version
aws configure set region us-east-1 --profile p0-admin
aws configure set output json --profile p0-admin
aws login --profile p0-admin
```

`aws login` opens your browser. Sign in as your **admin user** (with MFA) and approve. The CLI now holds temporary credentials for the profile `p0-admin`. If your terminal can't open a browser, use `aws login --profile p0-admin --remote` and follow the prompt.

- **Expected result:** `aws --version` starts with `aws-cli/2.33.14`. `aws login` finishes without an error.
- **Verification command:**

```bash
aws sts get-caller-identity --profile p0-admin
```

Expected output (your numbers will differ):

```json
{
    "UserId": "<a unique ID for your user>",
    "Account": "<your-12-digit-account-id>",
    "Arn": "arn:aws:iam::<your-12-digit-account-id>:user/<your-admin-user>"
}
```

**Fail** if `Arn` ends in `:root` — you signed in as root. Run `aws logout --profile p0-admin` and sign in again as the admin user.


From now on, in your own terminal, run this once per window so you don't have to type `--profile` every time:

```bash
export AWS_PROFILE=p0-admin     # PowerShell: $env:AWS_PROFILE = "p0-admin"
export AWS_REGION=us-east-1     # PowerShell: $env:AWS_REGION = "us-east-1"
```

> Labs 4–7 and the debugging lab use bash syntax (`$(...)`, `<<EOF`). On **Windows**, run them in **CloudShell** (Option B above) rather than PowerShell.

- **Teardown command:** `aws logout --profile p0-admin` (clears the cached temporary credentials). You'll log in again in later labs.
- **Cost note:** USD 0.

### Lab 4 — Billing alarm at USD 5

- **Region:** **`us-east-1` — required.** Billing metrics exist only here.
- **Task:**

**4a. Turn on billing alerts** (console, as admin user — UI as of 2026-11-17): **Billing and Cost Management** → **Billing preferences** → **Alert preferences** → **Edit** → tick **Receive CloudWatch billing alerts** → **Save preferences**. Once on, this can't be turned off — that's fine.

**4b. Create the email topic and the alarm** (terminal or CloudShell). Replace the email address:

```bash
export AWS_REGION=us-east-1
export ALERT_EMAIL="you+aws-course@example.com"   # ← your dedicated email

TOPIC_ARN="$(aws sns create-topic --name p0-billing-alerts --query TopicArn --output text)"
aws sns subscribe --topic-arn "$TOPIC_ARN" --protocol email --notification-endpoint "$ALERT_EMAIL"
```

**Now open your email** and click **Confirm subscription** in the message from *AWS Notifications*. Until you do, AWS sends nothing to that address.

```bash
aws cloudwatch put-metric-alarm \
  --alarm-name p0-billing-over-5usd \
  --alarm-description "Estimated charges this month > 5 USD" \
  --namespace AWS/Billing --metric-name EstimatedCharges \
  --dimensions Name=Currency,Value=USD \
  --statistic Maximum --period 21600 --evaluation-periods 1 \
  --threshold 5 --comparison-operator GreaterThanThreshold \
  --alarm-actions "$TOPIC_ARN"
```

`--period 21600` = 6 hours, the interval AWS uses for billing data.

- **Expected result:** the alarm exists in `us-east-1`; the subscription is confirmed; a test sends you an email.
- **Verification command** (works in a fresh terminal too — it looks the topic up again):

```bash
export AWS_REGION=us-east-1
TOPIC_ARN="$(aws sns list-topics --query "Topics[?ends_with(TopicArn, ':p0-billing-alerts')].TopicArn" --output text)"
aws sns list-subscriptions-by-topic --topic-arn "$TOPIC_ARN" \
  --query 'Subscriptions[].[Endpoint,SubscriptionArn]' --output text
# expect: your email followed by an ARN ending in a long ID — NOT "PendingConfirmation"

aws cloudwatch describe-alarms --alarm-names p0-billing-over-5usd \
  --query 'MetricAlarms[].[AlarmName,StateValue]' --output text
# expect: p0-billing-over-5usd  OK   (or INSUFFICIENT_DATA for the first several hours — check again tomorrow)

# Fire a test notification (doesn't change your bill):
aws cloudwatch set-alarm-state --alarm-name p0-billing-over-5usd \
  --state-value ALARM --state-reason "Lab 4 test"
# expect: within ~2 minutes, an email titled ALARM: "p0-billing-over-5usd" …
# The alarm returns to its real state at its next evaluation.
```

- **Teardown command:** none — **keep this alarm for the whole course.** (Only if you are closing the account: look up `TOPIC_ARN` as in the verification block, then `aws cloudwatch delete-alarms --alarm-names p0-billing-over-5usd && aws sns delete-topic --topic-arn "$TOPIC_ARN"`.)
- **Cost note:** USD 0 within the free tier's 10 alarm metrics (this alarm uses 1); otherwise USD 0.10/month.

### Lab 5 — AWS Budget with alerts at 50 / 80 / 100%

- **Region:** `us-east-1` (Budgets is a global service; the CLI talks to it from here).
- **Task:** create a USD 5 monthly cost budget that emails you at 50%, 80% and 100% of **actual** spend.

```bash
export AWS_REGION=us-east-1
export ALERT_EMAIL="you+aws-course@example.com"   # ← same email as Lab 4
ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"

cat > budget.json <<'EOF'
{
  "BudgetName": "p0-monthly-5usd",
  "BudgetLimit": { "Amount": "5", "Unit": "USD" },
  "TimeUnit": "MONTHLY",
  "BudgetType": "COST"
}
EOF

cat > notifications.json <<EOF
[
  {"Notification": {"NotificationType": "ACTUAL", "ComparisonOperator": "GREATER_THAN", "Threshold": 50,  "ThresholdType": "PERCENTAGE"},
   "Subscribers": [{"SubscriptionType": "EMAIL", "Address": "$ALERT_EMAIL"}]},
  {"Notification": {"NotificationType": "ACTUAL", "ComparisonOperator": "GREATER_THAN", "Threshold": 80,  "ThresholdType": "PERCENTAGE"},
   "Subscribers": [{"SubscriptionType": "EMAIL", "Address": "$ALERT_EMAIL"}]},
  {"Notification": {"NotificationType": "ACTUAL", "ComparisonOperator": "GREATER_THAN", "Threshold": 100, "ThresholdType": "PERCENTAGE"},
   "Subscribers": [{"SubscriptionType": "EMAIL", "Address": "$ALERT_EMAIL"}]}
]
EOF

aws budgets create-budget --account-id "$ACCOUNT_ID" \
  --budget file://budget.json \
  --notifications-with-subscribers file://notifications.json
rm budget.json notifications.json
```

The first `cat` uses `'EOF'` (quoted) so nothing inside changes; the second uses `EOF` (unquoted) so `$ALERT_EMAIL` is replaced by your address.

- **Expected result:** the command prints nothing (that means success). The budget appears in **Billing and Cost Management → Budgets**.
- **Verification command:**

```bash
aws budgets describe-budget --account-id "$ACCOUNT_ID" --budget-name p0-monthly-5usd \
  --query 'Budget.[BudgetName,BudgetLimit.Amount,CalculatedSpend.ActualSpend.Amount]' --output text
# expect: p0-monthly-5usd  5.0  0.0   (a brand-new budget may show None instead of 0.0 for a few hours — both are fine)

aws budgets describe-notifications-for-budget --account-id "$ACCOUNT_ID" --budget-name p0-monthly-5usd \
  --query 'Notifications[].[NotificationType,Threshold]' --output text
# expect three lines: ACTUAL 50.0 / ACTUAL 80.0 / ACTUAL 100.0
```

- **Teardown command:** none — **keep it.** (Only if closing the account: `aws budgets delete-budget --account-id "$ACCOUNT_ID" --budget-name p0-monthly-5usd`.)
- **Cost note:** USD 0 — budgets without actions are free ([Budgets pricing](https://aws.amazon.com/aws-cost-management/aws-budgets/pricing/)).

### Lab 6 — Cost Anomaly Detection

- **Region:** `us-east-1` (Cost Explorer APIs are served from here).
- **Task:** make sure a monitor watches spend **per AWS service**, and that a daily email goes to you when an anomaly's impact is USD 1 or more.

**6a. Turn on Cost Explorer** if you haven't: open **Billing and Cost Management → Cost Explorer** once in the console (UI as of 2026-11-17). On a new account, data can take up to 24 hours to appear; the next steps still work.

**6b. Check what already exists.** New Cost Explorer customers automatically get an *AWS services* monitor **and a daily email subscription** ([FAQ](https://aws.amazon.com/aws-cost-management/aws-cost-anomaly-detection/faqs/)).

```bash
export AWS_REGION=us-east-1
aws ce get-anomaly-monitors \
  --query 'AnomalyMonitors[].[MonitorName,MonitorType,MonitorDimension,MonitorArn]' --output text
aws ce get-anomaly-subscriptions \
  --query 'AnomalySubscriptions[].[SubscriptionName,Frequency]' --output text
```

- If a line shows `DIMENSIONAL  SERVICE`, **reuse that monitor**: `MONITOR_ARN=<the ARN printed at the end of that line>`
- If nothing is printed, create one:

```bash
MONITOR_ARN="$(aws ce create-anomaly-monitor \
  --anomaly-monitor '{"MonitorName":"p0-services-monitor","MonitorType":"DIMENSIONAL","MonitorDimension":"SERVICE"}' \
  --query MonitorArn --output text)"
```

**6c. Subscribe your email.** If 6b already listed a `DAILY` subscription, check its address with the verification command below (swap the name). If it already goes to your dedicated email, **skip 6c** — a second subscription would just send you duplicate emails.

```bash
export ALERT_EMAIL="you+aws-course@example.com"
aws ce create-anomaly-subscription --anomaly-subscription "{
  \"SubscriptionName\": \"p0-daily-anomalies\",
  \"MonitorArnList\": [\"$MONITOR_ARN\"],
  \"Subscribers\": [{\"Type\": \"EMAIL\", \"Address\": \"$ALERT_EMAIL\"}],
  \"Frequency\": \"DAILY\",
  \"ThresholdExpression\": {\"Dimensions\": {\"Key\": \"ANOMALY_TOTAL_IMPACT_ABSOLUTE\",
    \"MatchOptions\": [\"GREATER_THAN_OR_EQUAL\"], \"Values\": [\"1\"]}}
}"
```

Email subscriptions must be `DAILY` or `WEEKLY`; instant alerts need SNS and are out of scope here.

- **Expected result:** the command prints a `SubscriptionArn`.
- **Verification command:**

```bash
aws ce get-anomaly-subscriptions \
  --query 'AnomalySubscriptions[?SubscriptionName==`p0-daily-anomalies`].[SubscriptionName,Frequency,Subscribers[0].Address]' \
  --output text
# expect: p0-daily-anomalies  DAILY  <your email>   (or the default subscription's name, if you skipped 6c)
```

- **Teardown command:** none — **keep it.** (Only if closing the account: `aws ce delete-anomaly-subscription --subscription-arn <arn>`; delete the monitor only if *you* created it in 6b: `aws ce delete-anomaly-monitor --monitor-arn "$MONITOR_ARN"`.)
- **Cost note:** about USD 0.01 per command in this lab (Cost Explorer API pricing assumption); ≤ USD 0.06 total.

### Lab 7 — Teardown lab: the forgotten instance

This lab is **deliberately broken**: you launch a server and "forget" it, then hunt it down.

- **Region:** `us-east-1`
- **Task:**

**7a. Launch and forget.** Note the time.

```bash
export AWS_REGION=us-east-1
AMI_ID="$(aws ssm get-parameter \
  --name /aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64 \
  --query Parameter.Value --output text)"
echo "Using AMI: $AMI_ID"      # write this ID down — it's the exact image you ran

INSTANCE_ID="$(aws ec2 run-instances --image-id "$AMI_ID" --instance-type t3.micro --count 1 \
  --metadata-options HttpTokens=required \
  --tag-specifications \
    'ResourceType=instance,Tags=[{Key=Name,Value=p0-forgotten},{Key=course,Value=aws-devops-platform},{Key=module,Value=p0-0.0}]' \
    'ResourceType=volume,Tags=[{Key=Name,Value=p0-forgotten},{Key=course,Value=aws-devops-platform},{Key=module,Value=p0-0.0}]' \
  --query 'Instances[0].InstanceId' --output text)"
echo "Launched: $INSTANCE_ID"
```

The AMI (machine image) parameter always points to the current Amazon Linux 2023 image; printing it records which exact version you used. `t3.micro` is used instead of the older `t2.micro` because, for accounts created on or after 15 July 2025, `t2.micro` is not free-tier eligible and `t3.micro` is ([EC2 free tier](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-free-tier-usage.html)).

**Now close the terminal** (or CloudShell tab) and wait **20 minutes**. The variable `$INSTANCE_ID` is gone — just like a real forgotten server.

**7b. Try to find it in the bill.** Console → **Billing and Cost Management → Cost Explorer** (UI as of 2026-11-17). Set the date range to today, **Group by: Service**.
- **Expected:** EC2 does **not** show up yet, or shows USD 0.00. Billing data lags hours behind reality. **This is the lesson: the bill can't tell you what's running right now.**

**7c. Find it the reliable way** — ask EC2 directly, in every region:

```bash
export AWS_REGION=us-east-1
for r in $(aws ec2 describe-regions --query 'Regions[].RegionName' --output text); do
  aws ec2 describe-instances --region "$r" \
    --filters Name=instance-state-name,Values=pending,running,stopping,stopped \
    --query 'Reservations[].Instances[].[InstanceId,InstanceType,State.Name,Tags[?Key==`Name`]|[0].Value]' \
    --output text | sed "s/^/$r\t/"
done
# expect: one line — us-east-1  i-0…  t3.micro  running  p0-forgotten
```

**7d. Terminate it and wait until it's gone:**

```bash
INSTANCE_ID="<the i-… ID from 7c>"
VOL_ID="$(aws ec2 describe-instances --instance-ids "$INSTANCE_ID" \
  --query 'Reservations[0].Instances[0].BlockDeviceMappings[0].Ebs.VolumeId' --output text)"
echo "Disk: $VOL_ID"
aws ec2 terminate-instances --instance-ids "$INSTANCE_ID" \
  --query 'TerminatingInstances[].[InstanceId,CurrentState.Name]' --output text
aws ec2 wait instance-terminated --instance-ids "$INSTANCE_ID" && echo "terminated"
```

- **Expected result:** `terminated` is printed.
- **Verification command:**

```bash
# 1) The 7c loop again — expect: no output at all
# 2) Its disk was deleted with it — expect an error containing InvalidVolume.NotFound
#    (it can take a minute after termination; if it shows "deleting", wait and re-run)
aws ec2 describe-volumes --volume-ids "$VOL_ID" --query 'Volumes[].State'
# 3) Tomorrow: Cost Explorer, yesterday's date, Group by Service — expect EC2 at about USD 0.01 or less.
```

A terminated instance stays visible as `terminated` in the console for a while, then disappears. It no longer bills.

- **Teardown command:** step 7d *is* the teardown. Re-run the 7c loop to confirm it prints nothing.
- **Cost note:** ≤ USD 0.01 if terminated within 30 minutes. **If you skip 7d: about USD 0.39/day.**

## 7. Debugging lab

- **Scenario:** "I set up a billing alarm weeks ago. My charges went over the limit and I never got an email." A friend's setup has been recreated for you. Find why the alarm can't warn anyone, and fix it.
- **How to create the broken state:** in a terminal or CloudShell with your admin identity — **run it, don't read it first**:

```bash
export AWS_REGION=us-east-1
export ALERT_EMAIL="you+aws-course@example.com"
cd <your clone of this course repo>/phases/phase-0/00-account-safety
bash labs/debug-billing-alarm/break.sh
```

(In CloudShell, upload `labs/debug-billing-alarm/break.sh` via **Actions → Upload file**, then run `bash break.sh`.)

When an email titled *AWS Notification - Subscription Confirmation* arrives for `p0-debug-billing-alerts`, **don't click it yet.**

- **Symptom you will see:** testing the alarm does nothing useful:

```bash
aws cloudwatch set-alarm-state --alarm-name p0-debug-billing-alarm \
  --state-value ALARM --state-reason "debug test"
```

You get an error saying the alarm can't be found — yet `break.sh` said it created it — and no email arrives.

- **Your task:** **diagnose** using only `aws cloudwatch describe-alarms`, `aws sns list-topics` / `list-subscriptions-by-topic`, the `--region` option and the concepts in section 5 — find **every** reason this alarm could never warn you, then fix them (you'll need the create/subscribe/put/delete commands from Lab 4) so the alarm `p0-debug-billing-alarm` works. Write one sentence per cause explaining *why* it broke the alarm.
- **Done when:**

```bash
export AWS_REGION=us-east-1
aws cloudwatch describe-alarms --alarm-names p0-debug-billing-alarm \
  --query 'MetricAlarms[].[AlarmName,Namespace,AlarmActions[0]]' --output text
# expect: p0-debug-billing-alarm  AWS/Billing  arn:aws:sns:us-east-1:…:p0-debug-billing-alerts

DEBUG_TOPIC="$(aws sns list-topics --query "Topics[?ends_with(TopicArn, ':p0-debug-billing-alerts')].TopicArn" --output text)"
aws sns list-subscriptions-by-topic --topic-arn "$DEBUG_TOPIC" \
  --query 'Subscriptions[].SubscriptionArn' --output text
# expect: an ARN, not PendingConfirmation

aws cloudwatch set-alarm-state --alarm-name p0-debug-billing-alarm \
  --state-value ALARM --state-reason "debug test"
# expect: an ALARM email arrives within ~2 minutes
```

…and nothing named `p0-debug-*` is left in `eu-west-1`:

```bash
aws cloudwatch describe-alarms --region eu-west-1 --alarm-name-prefix p0-debug --query 'MetricAlarms[].AlarmName' --output text
aws sns list-topics --region eu-west-1 --query "Topics[?contains(TopicArn, 'p0-debug')].TopicArn" --output text
# expect: no output from either
```

- **Teardown:** (run after "Done when" passes — removes debug resources in both regions. If an alarm is already gone, `delete-alarms` may print a not-found error; that's harmless (names that do exist are still deleted — [DeleteAlarms](https://docs.aws.amazon.com/AmazonCloudWatch/latest/APIReference/API_DeleteAlarms.html)); the confirm loop is what counts.)

```bash
for r in us-east-1 eu-west-1; do
  aws cloudwatch delete-alarms --region "$r" --alarm-names p0-debug-billing-alarm
  T="$(aws sns list-topics --region "$r" --query "Topics[?ends_with(TopicArn, ':p0-debug-billing-alerts')].TopicArn" --output text)"
  [ -n "$T" ] && aws sns delete-topic --region "$r" --topic-arn "$T"
done
# confirm — expect no output from either line:
for r in us-east-1 eu-west-1; do
  aws cloudwatch describe-alarms --region "$r" --alarm-name-prefix p0-debug --query 'MetricAlarms[].AlarmName' --output text
  aws sns list-topics --region "$r" --query "Topics[?contains(TopicArn, 'p0-debug')].TopicArn" --output text
done
```

The diagnosis path is in `solutions/debugging-lab.md`.

## 8. Self-check

Answers: `solutions/self-check.md`.

1. In two sentences: what's the difference between a **CloudWatch billing alarm** and an **AWS Budget**? Name one thing *neither* of them does.
2. Why is the root user dangerous to use day to day, even with a strong password? What three things did you do to it in Lab 2?
3. Run the command that shows which identity your CLI is using. Paste the output and point to the part that proves it is **not** root.
4. Run the command that proves root has MFA and no access keys. What output proves it?
5. Your billing alarm has shown `INSUFFICIENT_DATA` for three days. Give the two most likely causes and the command or page you'd check for each.
6. You launched an instance 20 minutes ago. Why doesn't Cost Explorer show it — and what command shows it instead?
7. Your Budget email says "100% of USD 5 exceeded". Is the spending stopped? What do you do in the next 10 minutes?

## 9. Teardown

The guardrails from Labs 2–6 **stay** — they protect you for the rest of the course. Teardown here removes only the temporary things and confirms the guardrails are healthy.

> In **CloudShell**, skip every line marked `# local only` — CloudShell is already signed in and has no `p0-admin` profile.

```bash
export AWS_REGION=us-east-1
aws login --profile p0-admin; export AWS_PROFILE=p0-admin     # local only

# 1. Lab 7 — no instances, tagged disks or public IPs left in any region (expect: no output)
for r in $(aws ec2 describe-regions --query 'Regions[].RegionName' --output text); do
  aws ec2 describe-instances --region "$r" \
    --filters Name=instance-state-name,Values=pending,running,stopping,stopped \
    --query 'Reservations[].Instances[].InstanceId' --output text | sed "s/^/$r\tinstance\t/"
  aws ec2 describe-volumes --region "$r" --filters Name=tag:module,Values=p0-0.0 \
    --query 'Volumes[].VolumeId' --output text | sed "s/^/$r\tvolume\t/"
  aws ec2 describe-addresses --region "$r" \
    --query 'Addresses[].PublicIp' --output text | sed "s/^/$r\telastic-ip\t/"
done
#    If an instance prints: aws ec2 terminate-instances --region <region> --instance-ids <id>
#    If a volume prints:    aws ec2 delete-volume --region <region> --volume-id <id>
#    (This module never allocates an Elastic IP; if one prints, it isn't from this module — find out what it is.)

# 2. Debugging lab — if you haven't already, run the Teardown block in section 7.
#    The confirm step below checks both regions for anything left.
```

**Confirm nothing is left and the guardrails are OK** (the Module 0.0 gate):

```bash
export AWS_REGION=us-east-1
ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"

# Debugging lab leftovers — expect: no output
for r in us-east-1 eu-west-1; do
  aws cloudwatch describe-alarms --region "$r" --alarm-name-prefix p0-debug --query 'MetricAlarms[].AlarmName' --output text
  aws sns list-topics --region "$r" --query "Topics[?contains(TopicArn, 'p0-debug')].TopicArn" --output text
done

# Root: MFA on, no access keys — expect: 1	0
aws iam get-account-summary --query 'SummaryMap.[AccountMFAEnabled,AccountAccessKeysPresent]' --output text

# Billing alarm — expect: p0-billing-over-5usd  OK
aws cloudwatch describe-alarms --alarm-names p0-billing-over-5usd \
  --query 'MetricAlarms[].[AlarmName,StateValue]' --output text

# Budget and its three alerts — expect: p0-monthly-5usd  5.0  <spend, well under 5>
#                               then:   ACTUAL 50.0 / ACTUAL 80.0 / ACTUAL 100.0
aws budgets describe-budget --account-id "$ACCOUNT_ID" --budget-name p0-monthly-5usd \
  --query 'Budget.[BudgetName,BudgetLimit.Amount,CalculatedSpend.ActualSpend.Amount]' --output text
aws budgets describe-notifications-for-budget --account-id "$ACCOUNT_ID" --budget-name p0-monthly-5usd \
  --query 'Notifications[].[NotificationType,Threshold]' --output text

# Anomaly subscription — expect: at least one DAILY subscription to your email
aws ce get-anomaly-subscriptions \
  --query 'AnomalySubscriptions[].[SubscriptionName,Frequency,Subscribers[0].Address]' --output text

# Tag sweep — expect: []   (a just-terminated instance can linger briefly; step 1 is the authority)
aws resourcegroupstaggingapi get-resources --tag-filters Key=module,Values=p0-0.0 \
  --query 'ResourceTagMappingList[].ResourceARN' --output json

aws logout --profile p0-admin                                   # local only
```

If the alarm still shows `INSUFFICIENT_DATA` on day 1, that's normal — billing data hasn't arrived. Re-check tomorrow; if it's still not `OK`, it's the debugging lab in real life.

**Module 0.0 gate passed when:** MFA `1	0`, alarm `OK`, budget present with its three alerts, an anomaly subscription to your email, and steps 1 and the leftover check print nothing.

## 10. Last verified

- **Date:** NOT YET VERIFIED — drafted 2026-11-17.
- **Verified by:** —
- **Region:** `us-east-1` (debugging lab also touches `eu-west-1`)
- **Versions:** AWS CLI 2.33.14 (pinned) · Amazon Linux 2023 AMI resolved at run time via SSM (record the printed ID) · instance type `t3.micro`
- **Notes:** QA, labs and cost subagent reviews applied 2026-11-17. CLI command names, flags and output fields were checked against `aws <cmd> help` in aws-cli 2.33.14 on 2026-11-17, and the pinned installer URLs returned HTTP 200. No command has been run against a real account. Console steps are from documentation, not a click-through.
