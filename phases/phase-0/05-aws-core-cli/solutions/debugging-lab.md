# Solution · 0.5 debugging lab — "the public-subnet instance can't be reached"

> Not linked from the module. Try it first.

## The cause

The subnet's route table has **no `0.0.0.0/0 → igw-…` route**. The internet gateway exists and is attached, the security group is correct, and the network ACL allows everything, but without that one route the subnet is not actually *public*: the instance's replies to your SSH request have nowhere to go, so the connection times out.

## Diagnosis path (in the order the module asks)

Start from the instance and get its subnet and VPC:

```bash
aws ec2 describe-instances --filters Name=tag:Name,Values=p0-debug-vpc-ec2 \
  --query 'Reservations[0].Instances[0].[InstanceId,SubnetId,VpcId,PublicIpAddress,State.Name]' --output text
SUBNET_ID=<subnet from the line above>;  VPC_ID=<vpc from the line above>
```

| # | Layer | Command | What you find |
|---|---|---|---|
| 1 | **Route table** of the subnet | `aws ec2 describe-route-tables --filters Name=association.subnet-id,Values=$SUBNET_ID --query 'RouteTables[].Routes[].[DestinationCidrBlock,GatewayId]' --output text` | Only `10.77.0.0/16  local`. **There is no `0.0.0.0/0` line.** This is the cause. |
| 2 | **Internet gateway** | `aws ec2 describe-internet-gateways --filters Name=attachment.vpc-id,Values=$VPC_ID --query 'InternetGateways[].[InternetGatewayId,Attachments[0].State]' --output text` | An `igw-…` in state `available` and attached. Fine, but an attached gateway does nothing until a route points at it. |
| 3 | **Security group** | `aws ec2 describe-security-groups --filters Name=vpc-id,Values=$VPC_ID Name=group-name,Values=p0-debug-vpc-sg --query 'SecurityGroups[0].IpPermissions[].IpRanges[].CidrIp' --output text` | Your address `/32` on port 22. Fine. |
| 4 | **Network ACL** | `aws ec2 describe-network-acls --filters Name=association.subnet-id,Values=$SUBNET_ID --query 'NetworkAcls[].Entries[].[RuleNumber,Egress,RuleAction,CidrBlock]' --output text` | The default ACL: rule 100 allow `0.0.0.0/0` both directions, then the final deny rule (`32767`). Fine. |

Checking layers 2–4 *after* finding the cause in layer 1 is still useful: it proves each of them is **not** the problem, and it's the habit that finds the cause when it isn't the first thing you check.

## The fix: one command

```bash
RTB_ID=<route table ID from check 1>      # aws ec2 describe-route-tables --filters Name=association.subnet-id,Values=$SUBNET_ID --query 'RouteTables[0].RouteTableId' --output text
IGW_ID=<igw ID from check 2>
aws ec2 create-route --route-table-id "$RTB_ID" --destination-cidr-block 0.0.0.0/0 --gateway-id "$IGW_ID"
```

Then `ssh -i ~/.ssh/p0-debug-key.pem -o ConnectTimeout=8 -o StrictHostKeyChecking=accept-new ec2-user@<address> 'echo reachable'` prints `reachable` (allow about a minute after boot for `sshd`).

## Model explanation

The subnet's route table was missing the default route `0.0.0.0/0 → igw-…`, so traffic couldn't leave through the internet gateway (check 1: the table listed only the local route). The gateway was attached, the security group allowed my address and the network ACL allowed everything, so those weren't at fault.

## Why "I added the internet gateway" wasn't enough

Creating and attaching an internet gateway makes the VPC *capable* of reaching the internet. A subnet is only *public* if its **route table** says so. This is the most common first-day VPC mistake.

Sources: https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Internet_Gateway.html · https://docs.aws.amazon.com/vpc/latest/userguide/vpc-network-acls.html
