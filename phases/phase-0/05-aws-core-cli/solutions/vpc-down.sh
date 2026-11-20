#!/usr/bin/env bash
# vpc-down.sh — delete the course VPC and everything vpc-up.sh created, in reverse dependency order.
# Safe to re-run: if the VPC is already gone it says so and exits 0.
# Refuses (exit 1) if something it does not own still lives in the VPC: instances or NAT gateways.
set -euo pipefail

REGION="${AWS_REGION:-us-east-1}"
export AWS_REGION="$REGION" AWS_DEFAULT_REGION="$REGION"
NAME="${VPC_NAME:-p0-vpc}"

log() { echo "vpc-down: $*" >&2; }
first_or_empty() { head -n1 | grep -v '^None$' || true; }

VPC_ID="$(aws ec2 describe-vpcs \
  --filters "Name=tag:Name,Values=$NAME" "Name=tag:course,Values=aws-devops-platform" \
  --query 'Vpcs[0].VpcId' --output text | first_or_empty)"
if [ -z "$VPC_ID" ]; then log "no VPC named $NAME — nothing to do"; exit 0; fi

# --- Blockers: things this script does not delete ---------------------------------------
BLOCK_INST="$(aws ec2 describe-instances --filters "Name=vpc-id,Values=$VPC_ID" \
  "Name=instance-state-name,Values=pending,running,stopping,stopped,shutting-down" \
  --query 'Reservations[].Instances[].InstanceId' --output text)"
BLOCK_NAT="$(aws ec2 describe-nat-gateways --filter "Name=vpc-id,Values=$VPC_ID" \
  "Name=state,Values=pending,available,deleting" --query 'NatGateways[].NatGatewayId' --output text)"
if [ -n "$BLOCK_INST" ] || [ -n "$BLOCK_NAT" ]; then
  log "REFUSING: still in $VPC_ID -> instances: [${BLOCK_INST:-none}]  NAT gateways: [${BLOCK_NAT:-none}]"
  log "terminate the instances / delete the NAT gateway (and wait for 'deleted'), then run again."
  exit 1
fi

# --- 1. Security groups (not the VPC's default group) -------------------------------------
for sg in $(aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$VPC_ID" \
    --query "SecurityGroups[?GroupName!='default'].GroupId" --output text); do
  log "deleting security group $sg"; aws ec2 delete-security-group --group-id "$sg"
done

# --- 2. Route tables (not the main one): drop associations, then the table ------------------
for rtb in $(aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$VPC_ID" \
    --query "RouteTables[?length(Associations[?Main==\`true\`])==\`0\`].RouteTableId" --output text); do
  for assoc in $(aws ec2 describe-route-tables --route-table-ids "$rtb" \
      --query 'RouteTables[0].Associations[].RouteTableAssociationId' --output text); do
    aws ec2 disassociate-route-table --association-id "$assoc"
  done
  log "deleting route table $rtb"; aws ec2 delete-route-table --route-table-id "$rtb"
done

# --- 3. Subnets -------------------------------------------------------------------------------
for sn in $(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" \
    --query 'Subnets[].SubnetId' --output text); do
  log "deleting subnet $sn"; aws ec2 delete-subnet --subnet-id "$sn"
done

# --- 4. Internet gateway: detach, then delete -------------------------------------------------
for igw in $(aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=$VPC_ID" \
    --query 'InternetGateways[].InternetGatewayId' --output text); do
  log "detaching and deleting $igw"
  aws ec2 detach-internet-gateway --internet-gateway-id "$igw" --vpc-id "$VPC_ID"
  aws ec2 delete-internet-gateway --internet-gateway-id "$igw"
done
# an IGW that vpc-up.sh created but never attached (an interrupted run) is also ours
for igw in $(aws ec2 describe-internet-gateways \
    --filters "Name=tag:Name,Values=$NAME-igw" "Name=tag:course,Values=aws-devops-platform" \
    --query 'InternetGateways[].InternetGatewayId' --output text); do
  log "deleting unattached $igw"; aws ec2 delete-internet-gateway --internet-gateway-id "$igw"
done

# --- 5. The VPC -------------------------------------------------------------------------------
log "deleting VPC $VPC_ID"
aws ec2 delete-vpc --vpc-id "$VPC_ID"
log "done"
