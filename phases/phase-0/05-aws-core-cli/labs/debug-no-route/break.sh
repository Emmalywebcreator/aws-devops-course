#!/usr/bin/env bash
# Module 0.5 debugging lab — builds a small VPC and a public-subnet instance that cannot be reached, for ONE reason.
# Learners: run this, don't read it. The diagnosis is in ../../solutions/debugging-lab.md.
# Cost while it exists: about USD 0.015/hour (one t3.micro + its public IPv4). Tear it down when you are done.
set -euo pipefail

export AWS_REGION="${AWS_REGION:-us-east-1}"
export AWS_DEFAULT_REGION="$AWS_REGION"
NAME="p0-debug-vpc"
KEY="p0-debug-key"
PEM="$HOME/.ssh/$KEY.pem"
TAGS="{Key=course,Value=aws-devops-platform},{Key=phase,Value=0}"

if [ -n "$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=$NAME" --query 'Vpcs[0].VpcId' --output text | grep -v '^None$' || true)" ]; then
  echo "A VPC named $NAME already exists. Tear it down first (module section 9)." >&2; exit 1
fi

MY_IP="${MY_IP:-$(curl -s https://checkip.amazonaws.com | tr -d '[:space:]')}"
[ -n "$MY_IP" ] || { echo "Could not find your public IP address." >&2; exit 1; }

VPC_ID="$(aws ec2 create-vpc --cidr-block 10.77.0.0/16 --tag-specifications "ResourceType=vpc,Tags=[{Key=Name,Value=$NAME},$TAGS]" --query Vpc.VpcId --output text)"
IGW_ID="$(aws ec2 create-internet-gateway --tag-specifications "ResourceType=internet-gateway,Tags=[{Key=Name,Value=$NAME-igw},$TAGS]" --query InternetGateway.InternetGatewayId --output text)"
aws ec2 attach-internet-gateway --internet-gateway-id "$IGW_ID" --vpc-id "$VPC_ID"
AZ="$(aws ec2 describe-availability-zones --filters Name=state,Values=available Name=zone-type,Values=availability-zone --query 'sort_by(AvailabilityZones,&ZoneName)[0].ZoneName' --output text)"
SUBNET_ID="$(aws ec2 create-subnet --vpc-id "$VPC_ID" --cidr-block 10.77.1.0/24 --availability-zone "$AZ" --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=$NAME-public},$TAGS]" --query Subnet.SubnetId --output text)"
aws ec2 modify-subnet-attribute --subnet-id "$SUBNET_ID" --map-public-ip-on-launch
RTB_ID="$(aws ec2 create-route-table --vpc-id "$VPC_ID" --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=$NAME-rtb},$TAGS]" --query RouteTable.RouteTableId --output text)"
aws ec2 associate-route-table --route-table-id "$RTB_ID" --subnet-id "$SUBNET_ID" >/dev/null
SG_ID="$(aws ec2 create-security-group --group-name "$NAME-sg" --description "p0 debug lab: ssh from my ip" --vpc-id "$VPC_ID" --tag-specifications "ResourceType=security-group,Tags=[{Key=Name,Value=$NAME-sg},$TAGS]" --query GroupId --output text)"
aws ec2 authorize-security-group-ingress --group-id "$SG_ID" --protocol tcp --port 22 --cidr "$MY_IP/32" >/dev/null

mkdir -p "$HOME/.ssh"
aws ec2 delete-key-pair --key-name "$KEY" >/dev/null 2>&1 || true
rm -f "$PEM"
aws ec2 create-key-pair --key-name "$KEY" --key-type ed25519 --query KeyMaterial --output text > "$PEM"
chmod 600 "$PEM"

AMI_ID="$(aws ssm get-parameter --name /aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64 --query Parameter.Value --output text)"
INSTANCE_ID="$(aws ec2 run-instances --image-id "$AMI_ID" --instance-type t3.micro --count 1 --subnet-id "$SUBNET_ID" --security-group-ids "$SG_ID" --key-name "$KEY" --metadata-options HttpTokens=required \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$NAME-ec2},$TAGS]" "ResourceType=volume,Tags=[{Key=Name,Value=$NAME-ec2},$TAGS]" --query 'Instances[0].InstanceId' --output text)"
aws ec2 wait instance-running --instance-ids "$INSTANCE_ID"
PUBLIC_IP="$(aws ec2 describe-instances --instance-ids "$INSTANCE_ID" --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)"

echo
echo "Debug stack ready (VPC name: $NAME, instance: $INSTANCE_ID)."
echo "Key file : $PEM"
echo "Address  : $PUBLIC_IP"
echo "Symptom  : ssh -i $PEM -o ConnectTimeout=8 ec2-user@$PUBLIC_IP   # try it, from this computer"
