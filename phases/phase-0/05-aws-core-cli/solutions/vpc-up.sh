#!/usr/bin/env bash
# vpc-up.sh — create (or find) the course VPC. Idempotent: run it twice, get the same VPC.
#
#   ./vpc-up.sh                 two public subnets (two AZs) + one private subnet
#   ./vpc-up.sh --public-only   two public subnets only (no private subnet; "no-NAT mode")
#
# Everything is found by tags, never by hard-coded IDs. Prints KEY=VALUE lines on success.
set -euo pipefail

REGION="${AWS_REGION:-us-east-1}"
export AWS_REGION="$REGION" AWS_DEFAULT_REGION="$REGION"
NAME="${VPC_NAME:-p0-vpc}"
CIDR="${VPC_CIDR:-10.0.0.0/16}"
PHASE="${COURSE_PHASE:-0}"
PUBLIC_ONLY=0
[ "${1:-}" = "--public-only" ] && PUBLIC_ONLY=1

log() { echo "vpc-up: $*" >&2; }

# Tag string used on every create call. The VPC is named "$NAME"; other resources "$NAME-<part>".
tags() { # tags <resource-type> [part]
  echo "ResourceType=$1,Tags=[{Key=Name,Value=$NAME${2:+-$2}},{Key=course,Value=aws-devops-platform},{Key=phase,Value=$PHASE}]"
}

# first_or_empty: print the first line of stdin unless it is the CLI's "None"; never fails.
first_or_empty() { head -n1 | grep -v '^None$' || true; }

# --- 1. VPC ----------------------------------------------------------------
VPC_ID="$(aws ec2 describe-vpcs \
  --filters "Name=tag:Name,Values=$NAME" "Name=tag:course,Values=aws-devops-platform" \
  --query 'Vpcs[0].VpcId' --output text | first_or_empty)"
if [ -z "$VPC_ID" ]; then
  log "creating VPC $NAME ($CIDR)"
  VPC_ID="$(aws ec2 create-vpc --cidr-block "$CIDR" \
    --tag-specifications "$(tags vpc)" --query 'Vpc.VpcId' --output text)"
  aws ec2 modify-vpc-attribute --vpc-id "$VPC_ID" --enable-dns-hostnames '{"Value":true}'
else
  log "VPC $NAME already exists: $VPC_ID"
fi

# --- 2. Internet gateway -----------------------------------------------------
IGW_ID="$(aws ec2 describe-internet-gateways \
  --filters "Name=tag:Name,Values=$NAME-igw" "Name=tag:course,Values=aws-devops-platform" \
  --query 'InternetGateways[0].InternetGatewayId' --output text | first_or_empty)"
if [ -z "$IGW_ID" ]; then
  log "creating internet gateway"
  IGW_ID="$(aws ec2 create-internet-gateway \
    --tag-specifications "$(tags internet-gateway igw)" \
    --query 'InternetGateway.InternetGatewayId' --output text)"
fi
ATTACHED="$(aws ec2 describe-internet-gateways --internet-gateway-ids "$IGW_ID" \
  --query 'InternetGateways[0].Attachments[0].VpcId' --output text | first_or_empty)"
if [ "$ATTACHED" != "$VPC_ID" ]; then
  log "attaching $IGW_ID to $VPC_ID"
  aws ec2 attach-internet-gateway --internet-gateway-id "$IGW_ID" --vpc-id "$VPC_ID"
fi

# --- 3. Subnets ---------------------------------------------------------------
read -r AZ_A AZ_B < <(aws ec2 describe-availability-zones \
  --filters Name=state,Values=available Name=zone-type,Values=availability-zone \
  --query 'sort_by(AvailabilityZones,&ZoneName)[0:2].ZoneName' --output text)

# ensure_subnet <part> <cidr> <az> <public:yes|no>  -> prints the subnet ID
ensure_subnet() {
  local part="$1" cidr="$2" az="$3" public="$4" id
  id="$(aws ec2 describe-subnets \
    --filters "Name=vpc-id,Values=$VPC_ID" "Name=tag:Name,Values=$NAME-$part" \
    --query 'Subnets[0].SubnetId' --output text | first_or_empty)"
  if [ -z "$id" ]; then
    log "creating subnet $NAME-$part ($cidr, $az)"
    id="$(aws ec2 create-subnet --vpc-id "$VPC_ID" --cidr-block "$cidr" --availability-zone "$az" \
      --tag-specifications "$(tags subnet "$part")" --query 'Subnet.SubnetId' --output text)"
  fi
  if [ "$public" = yes ]; then
    aws ec2 modify-subnet-attribute --subnet-id "$id" --map-public-ip-on-launch
  fi
  echo "$id"
}
PUB_A="$(ensure_subnet public-a 10.0.1.0/24 "$AZ_A" yes)"
PUB_B="$(ensure_subnet public-b 10.0.2.0/24 "$AZ_B" yes)"
PRIV_A=""
[ "$PUBLIC_ONLY" = 0 ] && PRIV_A="$(ensure_subnet private-a 10.0.11.0/24 "$AZ_A" no)"

# --- 4. Route tables -------------------------------------------------------------
# ensure_rtb <part> -> prints the route table ID
ensure_rtb() {
  local part="$1" id
  id="$(aws ec2 describe-route-tables \
    --filters "Name=vpc-id,Values=$VPC_ID" "Name=tag:Name,Values=$NAME-$part" \
    --query 'RouteTables[0].RouteTableId' --output text | first_or_empty)"
  if [ -z "$id" ]; then
    log "creating route table $NAME-$part"
    id="$(aws ec2 create-route-table --vpc-id "$VPC_ID" \
      --tag-specifications "$(tags route-table "$part")" --query 'RouteTable.RouteTableId' --output text)"
  fi
  echo "$id"
}
# associate <rtb> <subnet>: skip if that subnet is already associated with that table
associate() {
  local rtb="$1" subnet="$2" have
  have="$(aws ec2 describe-route-tables --route-table-ids "$rtb" \
    --query "RouteTables[0].Associations[?SubnetId=='$subnet'].RouteTableAssociationId" --output text | first_or_empty)"
  [ -n "$have" ] || aws ec2 associate-route-table --route-table-id "$rtb" --subnet-id "$subnet" >/dev/null
}

PUB_RTB="$(ensure_rtb public-rtb)"
HAS_DEFAULT="$(aws ec2 describe-route-tables --route-table-ids "$PUB_RTB" \
  --query "RouteTables[0].Routes[?DestinationCidrBlock=='0.0.0.0/0'].GatewayId" --output text | first_or_empty)"
if [ -z "$HAS_DEFAULT" ]; then
  log "adding 0.0.0.0/0 -> $IGW_ID to the public route table"
  aws ec2 create-route --route-table-id "$PUB_RTB" --destination-cidr-block 0.0.0.0/0 --gateway-id "$IGW_ID" >/dev/null
fi
associate "$PUB_RTB" "$PUB_A"
associate "$PUB_RTB" "$PUB_B"

PRIV_RTB=""
if [ "$PUBLIC_ONLY" = 0 ]; then
  PRIV_RTB="$(ensure_rtb private-rtb)"      # deliberately NO default route (Lab 5 adds one, then removes it)
  associate "$PRIV_RTB" "$PRIV_A"
fi

# --- 5. Security group (no inbound rules yet) -----------------------------------
SG_ID="$(aws ec2 describe-security-groups \
  --filters "Name=vpc-id,Values=$VPC_ID" "Name=group-name,Values=$NAME-sg" \
  --query 'SecurityGroups[0].GroupId' --output text | first_or_empty)"
if [ -z "$SG_ID" ]; then
  log "creating security group $NAME-sg"
  SG_ID="$(aws ec2 create-security-group --group-name "$NAME-sg" --description "p0 course: no inbound until you add a rule" \
    --vpc-id "$VPC_ID" --tag-specifications "$(tags security-group sg)" --query 'GroupId' --output text)"
fi

echo "VPC_ID=$VPC_ID"
echo "IGW_ID=$IGW_ID"
echo "PUBLIC_SUBNET_A=$PUB_A"
echo "PUBLIC_SUBNET_B=$PUB_B"
echo "PRIVATE_SUBNET_A=$PRIV_A"
echo "PUBLIC_RTB=$PUB_RTB"
echo "PRIVATE_RTB=$PRIV_RTB"
echo "SG_ID=$SG_ID"
