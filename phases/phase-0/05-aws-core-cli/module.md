---
phase: "phase-0"
moduleId: "0.5"
title: "AWS core mental model + CLI"
goal: "Explain IAM, VPC, EC2 and S3 correctly and drive them from the CLI."
timeEstimate: "10-12h"
costEstimate: "<$1"
costAssumptions: "us-east-1, on-demand, no free tier assumed, author's prices 2026-11-19 (not yet checked against the pricing pages); NAT Gateway created, verified and deleted in the same session (target < 30 min); if you skip teardown ≈ $1.60/day, of which the NAT Gateway alone ≈ $1.10/day"
lastVerified: null
prerequisites: ["0.0", "0.1", "0.2"]
hasDebuggingLab: true
hasTeardown: true
toolsPinned:
  "awscli": "2.33.14"
---

# Phase 0 · Module 0.5 — AWS core mental model + CLI

## 1. Goal

Explain IAM, VPC, EC2 and S3 correctly and drive them from the CLI.

## 2. Prerequisites

- **Modules:** [0.0 Account safety & billing guardrails](../00-account-safety/module.md) (a safe account, `aws login`), [0.1 Linux & the shell](../01-linux-shell/module.md) (shell, SSH keys) and [0.2 Networking fundamentals](../02-networking/module.md) (CIDR, routing, NAT, firewalls).
- **Tools installed:** AWS CLI v2 with the `p0-admin` profile (0.0). `ssh` and `curl`.
- **Access:** your AWS account and admin user. In every terminal: `export AWS_PROFILE=p0-admin AWS_REGION=us-east-1`, and `aws login --profile p0-admin` if your session has expired.
- Update the course clone for the lab files: `git -C ~/aws-devops-course pull`.

## 3. Time estimate

**10–12 hours.** Do the NAT lab (Lab 5) in **one sitting**: it must be created, proven and deleted in under about 30 minutes.

| Lab | Time |
|---|---|
| 1 — The VPC, by hand and then as two scripts | 3–4 h |
| 2 — EC2 in the public subnet | 1.5 h |
| 3 — S3 with encryption and a bucket policy | 1 h |
| 4 — An IAM role instead of keys | 1.5–2 h |
| 5 — NAT Gateway: create, prove, delete | 1 h |
| Debugging lab | 1 h |
| Reading the concepts | 1.5 h |

## 4. Cost estimate

**Under USD 1** if you follow the teardown steps, with the NAT lab done in one sitting. All prices are the author's figures for `us-east-1` on 2026-11-19, **not yet checked** against the pricing pages (TODO(verify): https://aws.amazon.com/ec2/pricing/on-demand/, https://aws.amazon.com/vpc/pricing/, https://aws.amazon.com/s3/pricing/).

| Resource | Billed while idle? | Unit price (assumption) | Expected use | Cost |
|---|---|---|---|---|
| NAT Gateway | **yes, every hour it exists** | USD 0.045/h + USD 0.045/GB processed | under 1 h (Lab 5) | ≈ USD 0.05 |
| Public IPv4 address (the NAT's Elastic IP, and each instance's public address) | **yes, every hour** | USD 0.005/h each | ≤ 4 h | ≈ USD 0.05 |
| EC2 `t3.micro` (Linux, on-demand) | while it exists | USD 0.0104/h | ≤ 3 instances, ≤ 4 h | ≈ USD 0.10 |
| EBS 8 GiB gp3 root volume per instance | while it exists | USD 0.08/GB-month | ≤ 4 h | < USD 0.01 |
| S3 bucket + one small object | no (storage is cents) | USD 0.023/GB-month, negligible requests | a few KB | < USD 0.01 |
| VPC, subnets, route tables, internet gateway, security groups, IAM roles | no | no charge | all labs | USD 0 |

- **Total if you follow the teardown steps:** under USD 1 (the table adds to about USD 0.25).
- **If you skip teardown: about USD 1.60/day.** The NAT Gateway alone is about **USD 1.10/day** (0.045 × 24 = 1.08, before any data), its Elastic IP about 0.12, one instance about 0.25 plus its public address about 0.12, and the disk about 0.02. Leave three instances running and it is closer to USD 2.20/day. The NAT Gateway is the usual surprise: it is a small box that bills every hour even when nothing uses it.
- **Free tier:** not assumed. New accounts may have credits or an allowance that changes these numbers (see 0.0); this module's figures are the plain on-demand ones.

## 5. Concepts

> Each concept ends with **the command that shows it**, and is used in a lab straight away.

### Regions, availability zones and the CLI

- **Problem it solves:** resources have to live somewhere physical, and you need to say exactly *which* account, *which identity* and *which region* a command acts on.
- **How it works:** a **region** (`us-east-1`) is a geographic area; an **availability zone** (AZ, `us-east-1a`) is one or more data centres inside it, isolated from the others' failures. Most resources are **regional**: a VPC in `us-east-1` doesn't exist in `eu-west-1`. IAM is **global**. Every CLI command runs as the profile in `AWS_PROFILE`, in the region in `AWS_REGION`. `--query` (a JMESPath expression) picks the fields you want from the JSON, and `--output text` prints them without quotes, which is what makes the CLI scriptable.
- **The command that shows it:** `aws sts get-caller-identity` (who), `aws configure get region` and `echo $AWS_REGION` (where), `aws ec2 describe-availability-zones --query 'AvailabilityZones[].ZoneName' --output text`.
- **Applied in:** all labs.

### IAM: identities, policies, and how a request is decided

- **Problem it solves:** every AWS call has to be allowed or refused, per person, per program, per action, per resource.
- **How it works:** an **identity** is a **user** (a person; long-lived credentials) or a **role** (assumed temporarily by a person, a service or a program; no long-lived keys). A **policy** is a JSON document of statements: `Effect` (Allow/Deny), `Action` (`s3:GetObject`), `Resource` (an ARN) and optional `Condition`. An **identity policy** is attached to a user or role; a **resource policy** (such as an S3 bucket policy) is attached to the thing being accessed. A role has two kinds of policy: the **trust policy** (who may assume it) and the **permissions policy** (what it may do). An EC2 instance gets a role through an **instance profile**.

  **How a request is decided** (the order that matters):
  1. Everything is denied by default (**implicit deny**).
  2. If any applicable policy says **Allow**, the request can pass.
  3. If any applicable policy says **Deny** (an **explicit deny**), the request is **refused, and nothing overrides it**.

  So: **explicit deny wins over allow; allow wins over the default deny.** Worked example: policy A allows `s3:*` on everything; policy B denies `s3:DeleteBucket`. Deleting a bucket is refused (explicit deny); listing a bucket is allowed. Source: https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_evaluation-logic.html

  **Why roles instead of keys.** A key is a password that sits in a file, never expires, and gets copied into chats and Git (0.3). A role hands out **temporary** credentials that expire in hours, rotate by themselves, and exist only on the machine the role is attached to. There is nothing to leak or forget to delete.
- **The command that shows it:** `aws iam get-role --role-name <name>`, `aws iam list-role-policies --role-name <name>`, and `aws iam simulate-custom-policy` (Lab 4) to ask "would this be allowed?".
- **Applied in:** Labs 3 and 4.

### VPC: your own private network

- **Problem it solves:** you need a network of your own, with addresses you choose and rules about who can talk to what (0.2).
- **How it works:** a **VPC** is a private network with a CIDR block (here `10.0.0.0/16`). **Subnets** are slices of it, each in one AZ. A **route table** says where traffic for each destination goes (0.2). An **internet gateway (IGW)** connects a VPC to the internet. What makes a subnet **public** is not its name: it is a route table with `0.0.0.0/0 → igw-…`. A **private** subnet has no such route. A **NAT gateway**, placed in a *public* subnet, lets a private subnet make *outbound* connections (updates, APIs) while staying unreachable from outside; the private subnet's route table sends `0.0.0.0/0` to it. **Security groups** are stateful allow-lists on the instance's network interface (a new one allows nothing inbound); **network ACLs** are stateless allow/deny lists on the subnet (the default one allows everything). Sources: https://docs.aws.amazon.com/vpc/latest/userguide/how-it-works.html and https://docs.aws.amazon.com/vpc/latest/userguide/vpc-nat-gateway.html
- **The command that shows it:** `aws ec2 describe-route-tables`, `aws ec2 describe-security-groups`, `aws ec2 describe-network-acls`.
- **Applied in:** Labs 1, 2 and 5, and the debugging lab.

### EC2: a server you rent by the hour

- **Problem it solves:** you need a computer with an operating system, now, and you pay only while it exists.
- **How it works:** an **AMI** is the disk image it starts from (here Amazon Linux 2023). The **instance type** (`t3.micro`) sets CPU and memory. The root disk is an **EBS volume**. A **key pair** lets you SSH in (AWS keeps the public half; you keep the private file). Instances bill while **running and stopped-with-disks**, not only while running; **terminate** to stop paying. **IMDSv2** protects the instance's metadata endpoint (`169.254.169.254`, where its role credentials live): requests must first fetch a session token, so a simple "SSRF" bug in an app can't read the credentials. This course always launches with `HttpTokens=required`. **EC2 vs managed services:** with EC2 *you* patch, secure and scale the machine; managed services (later in the course) take most of that on in return for flexibility.
- **The command that shows it:** `aws ec2 describe-instances --query 'Reservations[].Instances[].[InstanceId,State.Name,PublicIpAddress]' --output text`.
- **Applied in:** Labs 2, 4 and 5.
- **Source:** https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/configuring-instance-metadata-service.html

### S3: object storage

- **Problem it solves:** durable storage for files of any size, reachable by name over HTTPS, with no disk to manage.
- **How it works:** a **bucket** (a globally unique name) holds **objects** (a key like `nat-proof/egress-ip.txt` plus data). There are no real folders: the `/` in a key is just a character that tools display as a folder. **Block Public Access** switches off public exposure at the bucket level (on by default for new buckets). New objects are **encrypted at rest** with S3-managed keys (SSE-S3) by default. A **bucket policy** is a resource policy: it can allow or deny requests to the bucket, for example denying any request not made over TLS.
- **The command that shows it:** `aws s3api get-public-access-block --bucket <b>`, `get-bucket-encryption`, `get-bucket-policy`, and `aws s3api head-bucket --bucket <b>` (exit code 0 = exists and yours; a 404 = not found).
- **Applied in:** Labs 3, 4 and 5.
- **Source:** https://docs.aws.amazon.com/AmazonS3/latest/userguide/Welcome.html

## 6. Labs

> **Region:** `us-east-1`. Run `export AWS_PROFILE=p0-admin AWS_REGION=us-east-1` in every new terminal.
>
> **Names and tags:** every resource this module creates carries `Name`, `course=aws-devops-platform` and `phase=0` tags, and lives under a name starting `p0-`. The teardown relies on that.
>
> **Working folder:** all labs run from `~/p0-aws-core`. Create it once: `mkdir -p ~/p0-aws-core && cd ~/p0-aws-core`. Lab files from the course are referenced as `$LABS`:
>
> ```bash
> export LABS=~/aws-devops-course/phases/phase-0/05-aws-core-cli/labs
> ```

### Lab 1 — The VPC, by hand and then as two scripts

- **Region:** `us-east-1`.
- **Task:** (A) build a VPC step by step so you see every piece, (B) delete it by hand in the right order, (C) write the same thing as two **idempotent scripts**, `vpc-up.sh` and `vpc-down.sh`, that the course reuses later.

**A. Build it by hand** (a throwaway VPC called `p0-hand`):

```bash
cd ~/p0-aws-core
TAGS='{Key=course,Value=aws-devops-platform},{Key=phase,Value=0}'

VPC_ID="$(aws ec2 create-vpc --cidr-block 10.50.0.0/16 \
  --tag-specifications "ResourceType=vpc,Tags=[{Key=Name,Value=p0-hand},$TAGS]" \
  --query Vpc.VpcId --output text)"

AZ="$(aws ec2 describe-availability-zones --query 'AvailabilityZones[0].ZoneName' --output text)"
SUBNET_ID="$(aws ec2 create-subnet --vpc-id "$VPC_ID" --cidr-block 10.50.1.0/24 --availability-zone "$AZ" \
  --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=p0-hand-public},$TAGS]" \
  --query Subnet.SubnetId --output text)"

IGW_ID="$(aws ec2 create-internet-gateway \
  --tag-specifications "ResourceType=internet-gateway,Tags=[{Key=Name,Value=p0-hand-igw},$TAGS]" \
  --query InternetGateway.InternetGatewayId --output text)"
aws ec2 attach-internet-gateway --internet-gateway-id "$IGW_ID" --vpc-id "$VPC_ID"

RTB_ID="$(aws ec2 create-route-table --vpc-id "$VPC_ID" \
  --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=p0-hand-rtb},$TAGS]" \
  --query RouteTable.RouteTableId --output text)"
aws ec2 create-route --route-table-id "$RTB_ID" --destination-cidr-block 0.0.0.0/0 --gateway-id "$IGW_ID"
ASSOC_ID="$(aws ec2 associate-route-table --route-table-id "$RTB_ID" --subnet-id "$SUBNET_ID" \
  --query AssociationId --output text)"

SG_ID="$(aws ec2 create-security-group --group-name p0-hand-sg --description "p0 hand-built" --vpc-id "$VPC_ID" \
  --tag-specifications "ResourceType=security-group,Tags=[{Key=Name,Value=p0-hand-sg},$TAGS]" \
  --query GroupId --output text)"

# the picture: this is what makes the subnet "public"
aws ec2 describe-route-tables --route-table-ids "$RTB_ID" \
  --query 'RouteTables[0].Routes[].[DestinationCidrBlock,GatewayId]' --output text
```

Expected: two lines, `10.50.0.0/16  local` and `0.0.0.0/0  igw-…`. The first is automatic (traffic inside the VPC); the second is the line that makes the subnet public.

**B. Delete it by hand, in dependency order.** First try the *wrong* order and read the error:

```bash
aws ec2 delete-vpc --vpc-id "$VPC_ID"
# An error occurred (DependencyViolation) when calling the DeleteVpc operation: The vpc 'vpc-…' has dependencies and cannot be deleted.
```

A VPC can't go while anything lives in it. Reverse the order of building:

```bash
aws ec2 delete-security-group --group-id "$SG_ID"
aws ec2 disassociate-route-table --association-id "$ASSOC_ID"
aws ec2 delete-route-table --route-table-id "$RTB_ID"
aws ec2 delete-subnet --subnet-id "$SUBNET_ID"
aws ec2 detach-internet-gateway --internet-gateway-id "$IGW_ID" --vpc-id "$VPC_ID"
aws ec2 delete-internet-gateway --internet-gateway-id "$IGW_ID"
aws ec2 delete-vpc --vpc-id "$VPC_ID"
aws ec2 describe-vpcs --vpc-ids "$VPC_ID" 2>&1 | grep -c NotFound          # expect: 1
```

**C. Write the scripts.** Create `vpc-up.sh` and `vpc-down.sh` in `~/p0-aws-core` that meet this **contract**. Reuse the commands from A and B.

`vpc-up.sh`:

1. Settings from environment variables with defaults: `AWS_REGION` (`us-east-1`), `VPC_NAME` (`p0-vpc`), `VPC_CIDR` (`10.0.0.0/16`).
2. It builds: the VPC (DNS hostnames on), an internet gateway attached to it, **two public subnets in two different AZs** (`10.0.1.0/24` and `10.0.2.0/24`, auto-assigning public IPs), **one private subnet** (`10.0.11.0/24`), a public route table (`0.0.0.0/0 → IGW`) associated with both public subnets, a **private route table with no default route** associated with the private subnet, and a security group `$VPC_NAME-sg` with **no inbound rules**.
3. `./vpc-up.sh --public-only` skips the private subnet and private route table (a "no-NAT mode"; a later module needs it).
4. **Every** resource is tagged `Name` (`$VPC_NAME`, or `$VPC_NAME-<part>`), `course=aws-devops-platform`, `phase=0`.
5. **Idempotent:** before creating anything, look it up by its tags; running the script twice must create nothing the second time and print the same IDs.
6. **No hard-coded IDs.** On success print `VPC_ID=…`, `IGW_ID=…`, `PUBLIC_SUBNET_A=…`, `PUBLIC_SUBNET_B=…`, `PRIVATE_SUBNET_A=…`, `PUBLIC_RTB=…`, `PRIVATE_RTB=…`, `SG_ID=…` on **stdout**, and progress messages on **stderr**.

`vpc-down.sh`:

1. Finds the VPC by its `Name` tag (and `course` tag); if it doesn't exist, says so and exits 0 (so it can be re-run).
2. **Refuses** (exit 1, with a message naming what blocks it) if instances or NAT gateways still exist in the VPC.
3. Deletes in reverse order: security groups (not the VPC's default one), route tables (not the main one; remove their associations first), subnets, the internet gateway (detach, then delete), the VPC.

Three things that trip people up: `--output text` prints the word `None` when a query finds nothing, so compare against that; `set -euo pipefail` at the top makes a failed command stop the script instead of carrying on; and every lookup must filter on the **VPC ID too**, so a second VPC doesn't confuse it.

Stuck? Compare with `solutions/vpc-up.sh` and `solutions/vpc-down.sh` after you've had a real try. Then run:

```bash
chmod +x vpc-up.sh vpc-down.sh
./vpc-up.sh                      # first run: creates everything, prints KEY=VALUE lines
./vpc-up.sh                      # second run: creates nothing, prints the same IDs
```

- **Expected result:** the second run prints the same `VPC_ID` as the first and no "creating …" lines.
- **Verification command:**

```bash
aws ec2 describe-vpcs --filters Name=tag:Name,Values=p0-vpc Name=tag:course,Values=aws-devops-platform --query 'length(Vpcs)'      # expect: 1
aws ec2 describe-subnets --filters Name=tag:course,Values=aws-devops-platform Name=tag:Name,Values='p0-vpc-*' --query 'length(Subnets)'   # expect: 3
aws ec2 describe-route-tables --filters Name=tag:Name,Values=p0-vpc-public-rtb --query 'RouteTables[0].Routes[].GatewayId' --output text # expect: local igw-…
./vpc-down.sh                    # deletes everything
./vpc-down.sh                    # prints "nothing to do", exits 0
aws ec2 describe-vpcs --filters Name=tag:Name,Values=p0-vpc --query 'length(Vpcs)'        # expect: 0
./vpc-up.sh --public-only | grep PRIVATE_SUBNET_A                                         # expect: PRIVATE_SUBNET_A=   (empty)
./vpc-down.sh
```

- **Teardown command:** `./vpc-down.sh` (as above). The `p0-vpc` network is rebuilt at the start of Lab 2 and stays until section 9.
- **Cost note:** USD 0. VPCs, subnets, route tables and internet gateways are free.

### Lab 2 — EC2 in the public subnet

- **Region:** `us-east-1`.
- **Task:** launch a small server in the public subnet, SSH into it, and lock its firewall to your own IP.

```bash
cd ~/p0-aws-core
eval "$(./vpc-up.sh)"            # sets VPC_ID, PUBLIC_SUBNET_A, SG_ID, … in this terminal

# an Amazon Linux 2023 image ID for this region, from AWS's own public parameter
AMI_ID="$(aws ssm get-parameter --name /aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64 \
  --query Parameter.Value --output text)"
echo "AMI: $AMI_ID"               # write this ID down: it is part of "last verified"

# a key pair; the private half is saved to a file only you can read
aws ec2 create-key-pair --key-name p0-core-key --key-type ed25519 --query KeyMaterial --output text > ~/.ssh/p0-core-key.pem
chmod 600 ~/.ssh/p0-core-key.pem

# the firewall: SSH (port 22) only from YOUR public address
MY_IP="$(curl -s https://checkip.amazonaws.com | tr -d '[:space:]')"
echo "my address: $MY_IP"        # must look like 203.0.113.7 (IPv4); if it is empty or an IPv6 address, stop and ask for help
aws ec2 authorize-security-group-ingress --group-id "$SG_ID" --protocol tcp --port 22 --cidr "$MY_IP/32"

INSTANCE_ID="$(aws ec2 run-instances --image-id "$AMI_ID" --instance-type t3.micro --count 1 \
  --subnet-id "$PUBLIC_SUBNET_A" --security-group-ids "$SG_ID" --key-name p0-core-key \
  --metadata-options HttpTokens=required \
  --tag-specifications \
    'ResourceType=instance,Tags=[{Key=Name,Value=p0-core-ec2},{Key=course,Value=aws-devops-platform},{Key=phase,Value=0}]' \
    'ResourceType=volume,Tags=[{Key=Name,Value=p0-core-ec2},{Key=course,Value=aws-devops-platform},{Key=phase,Value=0}]' \
  --query 'Instances[0].InstanceId' --output text)"
echo "instance: $INSTANCE_ID"
aws ec2 wait instance-status-ok --instance-ids "$INSTANCE_ID"      # waits for the 2/2 status checks (a minute or two)
PUBLIC_IP="$(aws ec2 describe-instances --instance-ids "$INSTANCE_ID" \
  --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)"
echo "public address: $PUBLIC_IP"

ssh -i ~/.ssh/p0-core-key.pem -o StrictHostKeyChecking=accept-new ec2-user@"$PUBLIC_IP" 'hostname; uname -r; whoami'
```

The security group allows exactly one source: your `/32`. A `/32` is a block of one address (0.2). Prove the rule really is that narrow, and prove the firewall works from a **different** address using AWS CloudShell (0.0 shows how to open it; it has a different public IP from your computer):

```bash
aws ec2 describe-security-groups --group-ids "$SG_ID" \
  --query 'SecurityGroups[0].IpPermissions[].IpRanges[].CidrIp' --output text       # expect: <your address>/32
# in CloudShell, with your instance's public address typed in:
timeout 5 bash -c 'echo > /dev/tcp/<PUBLIC_IP>/22' && echo REACHABLE || echo BLOCKED     # expect: BLOCKED
```

- **Expected result:** the `ssh` command prints a hostname like `ip-10-0-1-…`, a kernel version, and `ec2-user`. CloudShell prints `BLOCKED` after 5 seconds: the packets are silently dropped (a timeout, as in 0.2, not a "refused"). If your own address changes (new Wi-Fi), SSH starts timing out: re-run the `authorize-security-group-ingress` line with the new address after revoking the old one.
- **Verification command:**

```bash
aws ec2 describe-instances --instance-ids "$INSTANCE_ID" --query 'Reservations[0].Instances[0].State.Name' --output text    # expect: running
aws ec2 describe-instances --instance-ids "$INSTANCE_ID" --query 'Reservations[0].Instances[0].MetadataOptions.HttpTokens' --output text   # expect: required
ssh -i ~/.ssh/p0-core-key.pem ec2-user@"$PUBLIC_IP" 'echo reachable'                                                       # expect: reachable
```

- **Teardown command:** none yet: the instance is reused in Lab 4 and everything is removed in section 9. (It costs about USD 0.015/hour while it exists.)
- **Cost note:** ≈ USD 0.0154/h (instance 0.0104 + public address 0.005) plus a few cents a month for the disk. Terminate it within the session.

### Lab 3 — S3 with encryption and a bucket policy

- **Region:** `us-east-1`.
- **Task:** create a locked-down bucket, upload a file, and add a bucket policy that refuses any request not made over TLS.

```bash
cd ~/p0-aws-core
ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
BUCKET="p0-core-${ACCOUNT_ID}-us-east-1"      # bucket names are global; the account ID makes it unique
echo "$BUCKET"

aws s3api create-bucket --bucket "$BUCKET" --region us-east-1      # (us-east-1 needs no LocationConstraint)
aws s3api put-bucket-tagging --bucket "$BUCKET" \
  --tagging 'TagSet=[{Key=course,Value=aws-devops-platform},{Key=phase,Value=0}]'

# 1. make "no public access" explicit, even though it is the default
aws s3api put-public-access-block --bucket "$BUCKET" --public-access-block-configuration \
  BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

# 2. make the encryption setting explicit too (S3-managed keys)
aws s3api put-bucket-encryption --bucket "$BUCKET" --server-side-encryption-configuration \
  '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'

# 3. upload a file
echo "hello from p0" > hello.txt
aws s3api put-object --bucket "$BUCKET" --key hello.txt --body hello.txt

# 4. a bucket policy: DENY every request that is not over TLS (an explicit deny, which wins over any allow)
cat > bucket-policy.json <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [{
    "Sid": "DenyInsecureTransport",
    "Effect": "Deny",
    "Principal": "*",
    "Action": "s3:*",
    "Resource": ["arn:aws:s3:::$BUCKET", "arn:aws:s3:::$BUCKET/*"],
    "Condition": { "Bool": { "aws:SecureTransport": "false" } }
  }]
}
POLICY
aws s3api put-bucket-policy --bucket "$BUCKET" --policy file://bucket-policy.json
```

- **Expected result:** every command succeeds silently or prints a small JSON block. The CLI talks HTTPS, so your own requests still work; only a plain-HTTP request would hit the deny.
- **Verification command:**

```bash
aws s3api get-public-access-block --bucket "$BUCKET" --query 'PublicAccessBlockConfiguration.[BlockPublicAcls,BlockPublicPolicy]' --output text   # expect: True  True
aws s3api get-bucket-encryption --bucket "$BUCKET" --query 'ServerSideEncryptionConfiguration.Rules[0].ApplyServerSideEncryptionByDefault.SSEAlgorithm' --output text   # expect: AES256
aws s3api get-bucket-policy --bucket "$BUCKET" --query Policy --output text | grep -c DenyInsecureTransport      # expect: 1
aws s3 cp "s3://$BUCKET/hello.txt" -                                                                               # expect: hello from p0
```

- **Teardown command:** removed in section 9 (the object, then the bucket). The bucket is used in Labs 4 and 5.
- **Cost note:** USD 0 for a few bytes.

### Lab 4 — An IAM role instead of keys

- **Region:** `us-east-1`.
- **Task:** let the Lab 2 instance read one S3 object **with no access keys on it**, then show what it still can't do.

First, **predict, then check** (this is the policy evaluation from the concepts). Two policies, an allow and a deny:

```bash
cat > allow-s3.json <<'EOF'
{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":"s3:*","Resource":"*"}]}
EOF
cat > deny-delete.json <<'EOF'
{"Version":"2012-10-17","Statement":[{"Effect":"Deny","Action":"s3:DeleteBucket","Resource":"*"}]}
EOF
```

Before running anything, write down: with *both* attached to one user, is `s3:DeleteBucket` allowed? Is `s3:ListBucket`? Then ask AWS's simulator:

```bash
aws iam simulate-custom-policy --policy-input-list file://allow-s3.json file://deny-delete.json \
  --action-names s3:DeleteBucket s3:ListBucket --resource-arns arn:aws:s3:::example-bucket \
  --query 'EvaluationResults[].[EvalActionName,EvalDecision]' --output text
# expect: s3:DeleteBucket  explicitDeny
#         s3:ListBucket    allowed
```

Now the role. A role needs a **trust policy** (EC2 may assume it) and a **permissions policy** (read exactly one object):

```bash
cat > trust.json <<'EOF'
{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"ec2.amazonaws.com"},"Action":"sts:AssumeRole"}]}
EOF
cat > role-policy.json <<POLICY
{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":"s3:GetObject","Resource":"arn:aws:s3:::$BUCKET/hello.txt"}]}
POLICY

aws iam create-role --role-name p0-ec2-s3-read --assume-role-policy-document file://trust.json \
  --tags Key=course,Value=aws-devops-platform Key=phase,Value=0
aws iam put-role-policy --role-name p0-ec2-s3-read --policy-name p0-s3-access --policy-document file://role-policy.json
aws iam create-instance-profile --instance-profile-name p0-ec2-s3-read
aws iam add-role-to-instance-profile --instance-profile-name p0-ec2-s3-read --role-name p0-ec2-s3-read
aws iam wait instance-profile-exists --instance-profile-name p0-ec2-s3-read
sleep 10                         # IAM changes can take a few seconds to be visible to EC2

# attach it to the RUNNING instance from Lab 2
aws ec2 associate-iam-instance-profile --instance-id "$INSTANCE_ID" --iam-instance-profile Name=p0-ec2-s3-read
sleep 15
```

Now use it **from the instance**, over SSH. There are no keys on that machine:

```bash
SSH="ssh -i $HOME/.ssh/p0-core-key.pem ec2-user@$PUBLIC_IP"
$SSH 'ls ~/.aws 2>&1; aws configure list | grep -E "access_key|secret_key"'     # no ~/.aws folder; credentials come from "iam-role"
$SSH "aws s3 cp s3://$BUCKET/hello.txt -"                                         # the one thing the role allows
$SSH 'aws s3 ls 2>&1 | head -2'                                                   # not allowed: implicit deny
$SSH "aws s3api put-object --bucket $BUCKET --key x.txt --body /etc/hostname 2>&1 | head -2"   # not allowed either
```

And look at how the instance gets its temporary credentials: the metadata service, with IMDSv2's token step:

```bash
$SSH 'curl -s -o /dev/null -w "without token: %{http_code}\n" http://169.254.169.254/latest/meta-data/'
$SSH 'TOKEN=$(curl -s -X PUT http://169.254.169.254/latest/api/token -H "X-aws-ec2-metadata-token-ttl-seconds: 60"); curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/iam/security-credentials/; echo'
```

- **Expected result:** the policy test prints `explicitDeny` for `DeleteBucket` and `allowed` for `ListBucket`. On the instance: `ls ~/.aws` says `No such file or directory`; `aws configure list` shows the credential type `iam-role`; the `cp` prints `hello from p0`; `aws s3 ls` and `put-object` fail with `AccessDenied` (the role was only allowed `GetObject` on one key). Without a token the metadata request returns `401` (IMDSv2 is enforced); with one it prints the role name `p0-ec2-s3-read`.
- **Verification command:**

```bash
aws ec2 describe-iam-instance-profile-associations --filters Name=instance-id,Values="$INSTANCE_ID" \
  --query 'IamInstanceProfileAssociations[0].State' --output text                 # expect: associated
$SSH "aws s3 cp s3://$BUCKET/hello.txt -"                                           # expect: hello from p0
```

- **Teardown command:** removed in section 9 (role and instance profile).
- **Cost note:** USD 0 (IAM has no charge).

### Lab 5 — NAT Gateway: create, prove, delete, in one sitting

- **Region:** `us-east-1`.
- **Task:** give a **private** instance (no public address, no inbound access) outbound internet through a NAT gateway; prove it; then delete the NAT gateway and release its address. Target: under 30 minutes in total.

> **⚠ Cost warning, read before you run the create command.** A NAT gateway bills about **USD 0.045 per hour (≈ USD 1.10 per day) from the moment it is created**, plus about USD 0.005/h for its Elastic IP, even if nothing uses it. This lab creates it, proves it works, and deletes it in one sitting. **Do not stop halfway.** If you must stop, run the "Delete it" block now.

**1. Let the role write one proof file** (the private instance will report its internet address to your bucket). Re-use the same policy name so it *replaces* the Lab 4 version:

```bash
cd ~/p0-aws-core
eval "$(./vpc-up.sh)"            # PRIVATE_SUBNET_A, PRIVATE_RTB, PUBLIC_SUBNET_A, SG_ID
cat > role-policy.json <<POLICY
{"Version":"2012-10-17","Statement":[
  {"Effect":"Allow","Action":"s3:GetObject","Resource":"arn:aws:s3:::$BUCKET/hello.txt"},
  {"Effect":"Allow","Action":"s3:PutObject","Resource":"arn:aws:s3:::$BUCKET/nat-proof/*"}]}
POLICY
aws iam put-role-policy --role-name p0-ec2-s3-read --policy-name p0-s3-access --policy-document file://role-policy.json
```

**2. Create the NAT gateway** (**billing starts now**) in a *public* subnet, with its own Elastic IP, and point the private route table at it:

```bash
ALLOC_ID="$(aws ec2 allocate-address --domain vpc \
  --tag-specifications 'ResourceType=elastic-ip,Tags=[{Key=Name,Value=p0-core-nat-eip},{Key=course,Value=aws-devops-platform},{Key=phase,Value=0}]' \
  --query AllocationId --output text)"
NAT_ID="$(aws ec2 create-nat-gateway --subnet-id "$PUBLIC_SUBNET_A" --allocation-id "$ALLOC_ID" \
  --tag-specifications 'ResourceType=natgateway,Tags=[{Key=Name,Value=p0-core-nat},{Key=course,Value=aws-devops-platform},{Key=phase,Value=0}]' \
  --query NatGateway.NatGatewayId --output text)"
aws ec2 wait nat-gateway-available --nat-gateway-ids "$NAT_ID"        # about 1–2 minutes
aws ec2 create-route --route-table-id "$PRIVATE_RTB" --destination-cidr-block 0.0.0.0/0 --nat-gateway-id "$NAT_ID"
```

**3. Launch the private instance.** No public address, no key, a security group with no inbound rules, and a start-up script that reports its internet address:

```bash
sed "s/__BUCKET__/$BUCKET/" "$LABS/nat-proof/userdata.sh" > nat-userdata.sh
AMI_ID="$(aws ssm get-parameter --name /aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64 --query Parameter.Value --output text)"
PRIV_ID="$(aws ec2 run-instances --image-id "$AMI_ID" --instance-type t3.micro --count 1 \
  --subnet-id "$PRIVATE_SUBNET_A" --security-group-ids "$SG_ID" \
  --iam-instance-profile Name=p0-ec2-s3-read --metadata-options HttpTokens=required \
  --user-data file://nat-userdata.sh \
  --tag-specifications \
    'ResourceType=instance,Tags=[{Key=Name,Value=p0-core-private},{Key=course,Value=aws-devops-platform},{Key=phase,Value=0}]' \
    'ResourceType=volume,Tags=[{Key=Name,Value=p0-core-private},{Key=course,Value=aws-devops-platform},{Key=phase,Value=0}]' \
  --query 'Instances[0].InstanceId' --output text)"
echo "private instance: $PRIV_ID (it has no public address)"
```

**4. Prove outbound works through NAT.** Wait for the proof file (up to about 5 minutes), then compare the address it saw with the NAT's Elastic IP:

```bash
for i in $(seq 1 30); do
  aws s3api head-object --bucket "$BUCKET" --key nat-proof/egress-ip.txt >/dev/null 2>&1 && break
  sleep 10
done
aws s3 cp "s3://$BUCKET/nat-proof/egress-ip.txt" -                                          # the address the internet saw
aws ec2 describe-addresses --allocation-ids "$ALLOC_ID" --query 'Addresses[0].PublicIp' --output text   # the NAT's Elastic IP
```

**5. Delete it, now.** Terminate the private instance, then the NAT gateway, remove the route, and release the address, in that order:

```bash
aws ec2 terminate-instances --instance-ids "$PRIV_ID" >/dev/null
aws ec2 wait instance-terminated --instance-ids "$PRIV_ID"
aws ec2 delete-route --route-table-id "$PRIVATE_RTB" --destination-cidr-block 0.0.0.0/0
aws ec2 delete-nat-gateway --nat-gateway-id "$NAT_ID" >/dev/null
aws ec2 wait nat-gateway-deleted --nat-gateway-ids "$NAT_ID"
aws ec2 release-address --allocation-id "$ALLOC_ID"
```

- **Expected result:** the two addresses printed in step 4 are **identical**: the private instance (which has no public address of its own) reached the internet through the NAT gateway's Elastic IP. Without the NAT, the start-up script would have kept retrying and the file would never appear.
- **Verification command (graded):** no NAT gateway and no Elastic IP may remain.

```bash
aws ec2 describe-nat-gateways --filter Name=vpc-id,Values="$VPC_ID" Name=state,Values=pending,available \
  --query 'NatGateways[].NatGatewayId' --output text                                    # expect: no output
aws ec2 describe-addresses --query 'Addresses[].PublicIp' --output text                  # expect: no output
```

- **Teardown command:** step 5 above *is* the teardown. Don't skip it.
- **Cost note:** ≈ USD 0.05 for the NAT gateway and its address if you finish within the hour; **≈ USD 1.10/day if left running**.

## 7. Debugging lab

- **Scenario:** an instance in a public subnet "has no internet". Nobody can SSH to it. A security group rule for your address exists. The person who built it says "I added the internet gateway".
- **How to create the broken state:**

```bash
bash "$LABS/debug-no-route/break.sh"
```

This builds a separate small VPC (`p0-debug-vpc`) and an instance (≈ USD 0.015/h). It prints the instance's address and a key file under `~/.ssh/`.

- **Symptom you will see:**

```bash
ssh -i ~/.ssh/p0-debug-key.pem -o ConnectTimeout=8 ec2-user@<address-it-printed>
# ssh: connect to host … port 22: Connection timed out
```

- **Your task:** a timeout means packets are being dropped or have nowhere to go (0.2). Walk the path **in this order**, one command per layer: **(1) the subnet's route table, (2) the internet gateway, (3) the security group, (4) the network ACL**. For each layer, note what you checked and whether it was fine. Find the single cause, fix it with **one** CLI command, and write one sentence about what was wrong and which command proved it. Don't recreate anything.

  Start from the instance: `aws ec2 describe-instances --filters Name=tag:Name,Values=p0-debug-vpc-ec2 --query 'Reservations[0].Instances[0].[InstanceId,SubnetId,VpcId,PublicIpAddress,State.Name]' --output text`. Then use `describe-route-tables`, `describe-internet-gateways`, `describe-security-groups` and `describe-network-acls` with `--filters` on the subnet or VPC ID.
- **Done when:**

```bash
ssh -i ~/.ssh/p0-debug-key.pem -o ConnectTimeout=8 -o StrictHostKeyChecking=accept-new ec2-user@<address> 'echo reachable'
# expect: reachable      (sshd needs about a minute after boot; if it times out right after your fix, wait and retry once)
```

- **Teardown:** in section 9 (it includes the debug stack).

The diagnosis path and model explanations are in `solutions/debugging-lab.md`.

## 8. Self-check

Answers: `solutions/self-check.md`.

1. Why use roles instead of long-lived access keys?
2. Security group vs network ACL: name three differences.
3. Two policies apply to a request: one `Allow s3:*`, one `Deny s3:DeleteBucket`. Is a `DeleteBucket` request allowed? A `ListBucket`? State the rule that decides.
4. What is the one thing that makes a subnet *public*? Which command shows it?
5. Why is a NAT gateway called a cost trap, and what two commands prove none is left?
6. Why must a NAT gateway sit in a *public* subnet, and what does the *private* subnet's route table contain?
7. In Lab 2, why did CloudShell time out instead of getting "connection refused"?
8. What does IMDSv2 add, and what would the `401` in Lab 4 have been with it turned off?

## 9. Teardown

Run in this order, from `~/p0-aws-core`, with `AWS_PROFILE=p0-admin AWS_REGION=us-east-1`. Each step is safe to run when its resource is already gone.

```bash
cd ~/p0-aws-core
export AWS_PROFILE=p0-admin AWS_REGION=us-east-1
ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
BUCKET="p0-core-${ACCOUNT_ID}-us-east-1"

# 1. Instances (Lab 2, Lab 5, the debugging lab): terminate and wait
IDS="$(aws ec2 describe-instances --filters Name=tag:course,Values=aws-devops-platform \
  Name=instance-state-name,Values=pending,running,stopping,stopped --query 'Reservations[].Instances[].InstanceId' --output text)"
if [ -n "$IDS" ]; then aws ec2 terminate-instances --instance-ids $IDS >/dev/null; aws ec2 wait instance-terminated --instance-ids $IDS; fi

# 2. NAT gateways: delete and wait until "deleted" (Lab 5 should already have done this)
for n in $(aws ec2 describe-nat-gateways --filter Name=tag:course,Values=aws-devops-platform Name=state,Values=pending,available \
    --query 'NatGateways[].NatGatewayId' --output text); do
  aws ec2 delete-nat-gateway --nat-gateway-id "$n" >/dev/null
  aws ec2 wait nat-gateway-deleted --nat-gateway-ids "$n"
done

# 3. Elastic IPs: release (only possible after the NAT gateway is deleted)
for a in $(aws ec2 describe-addresses --filters Name=tag:course,Values=aws-devops-platform --query 'Addresses[].AllocationId' --output text); do
  aws ec2 release-address --allocation-id "$a"
done

# 4. Key pairs and their files
aws ec2 delete-key-pair --key-name p0-core-key  >/dev/null 2>&1
aws ec2 delete-key-pair --key-name p0-debug-key >/dev/null 2>&1
rm -f ~/.ssh/p0-core-key.pem ~/.ssh/p0-debug-key.pem

# 5. Networks: security groups, route tables, subnets, internet gateway, VPC (your scripts)
./vpc-down.sh
VPC_NAME=p0-debug-vpc ./vpc-down.sh
VPC_NAME=p0-hand ./vpc-down.sh

# 6. The bucket: empty it, then delete it
aws s3 rm "s3://$BUCKET" --recursive >/dev/null 2>&1
aws s3api delete-bucket --bucket "$BUCKET" 2>/dev/null

# 7. The role and instance profile (remove the role from the profile first)
aws iam remove-role-from-instance-profile --instance-profile-name p0-ec2-s3-read --role-name p0-ec2-s3-read 2>/dev/null
aws iam delete-instance-profile --instance-profile-name p0-ec2-s3-read 2>/dev/null
aws iam delete-role-policy --role-name p0-ec2-s3-read --policy-name p0-s3-access 2>/dev/null
aws iam delete-role --role-name p0-ec2-s3-read 2>/dev/null
```

If `vpc-down.sh` refuses, it names what is still inside: deal with that first (step 1 or 2), then run it again.

**Confirm nothing is left** (each expectation is "nothing found"):

```bash
aws ec2 describe-nat-gateways --filter Name=state,Values=pending,available Name=tag:course,Values=aws-devops-platform --query 'NatGateways[].NatGatewayId' --output text   # expect: no output
aws ec2 describe-addresses --query 'Addresses[].PublicIp' --output text                                                                                                   # expect: no output
aws ec2 describe-vpcs --filters Name=tag:course,Values=aws-devops-platform --query 'Vpcs[].VpcId' --output text                                                            # expect: no output
aws s3api head-bucket --bucket "$BUCKET" 2>&1 | grep -c "Not Found"                                                                                                        # expect: 1
aws iam get-role --role-name p0-ec2-s3-read 2>&1 | grep -c NoSuchEntity                                                                                                    # expect: 1
aws iam get-instance-profile --instance-profile-name p0-ec2-s3-read 2>&1 | grep -c NoSuchEntity                                                                            # expect: 1

# all-region sweep for instances (expect: no output)
for r in $(aws ec2 describe-regions --query 'Regions[].RegionName' --output text); do
  aws ec2 describe-instances --region "$r" --filters Name=instance-state-name,Values=pending,running,stopping,stopped \
    --query 'Reservations[].Instances[].InstanceId' --output text | sed "s/^/$r\t/"
done
```

Kept on purpose: the AWS CLI profile, the `p0-` guardrails from 0.0 (budget, alarms), your `vpc-up.sh` and `vpc-down.sh` scripts in `~/p0-aws-core` (a later module reuses them), and the course clone.

## 10. Last verified

- **Date:** NOT YET VERIFIED BY A HUMAN. Drafted 2026-11-19. (`lastVerified: null`; only a human who runs every command may set it.)
- **Verified by:** —
- **Region:** `us-east-1`.
- **Versions:** AWS CLI 2.33.14. The Amazon Linux 2023 image ID is resolved from AWS's public parameter at run time: **write down the ID Lab 2 prints** when you run it. Prices in section 4 are the author's, not yet checked.
- **Notes (author dry-run, not a verification):** `vpc-up.sh` and `vpc-down.sh` (the reference versions in `solutions/`), the S3, IAM role and instance-profile commands, the Elastic IP / NAT gateway / route / waiter / delete sequence, the teardown loops and the debugging-lab `break.sh` were run against a local **mock** of AWS, which found and fixed a real tagging bug in `vpc-up.sh`. A mock proves the command syntax and the script logic, **not** real AWS behaviour. **Not run against real AWS:** all of it. In particular not observed: NAT gateway and instance timings, the `DependencyViolation` message text, `AccessDenied` / `UnauthorizedOperation` wording, the IMDSv2 `401`, `aws iam simulate-custom-policy` output (the mock doesn't support it, so the `explicitDeny` / `allowed` lines come from AWS's documentation), whether Amazon Linux 2023 ships the AWS CLI by default (the lab assumes it does), and CloudShell behaviour.
