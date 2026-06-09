#!/bin/bash
# vpc-setup.sh — Creates full StackForge VPC, subnets, IGW, NAT, route tables
# Run once from AWS CLI on any machine with correct IAM permissions
set -euo pipefail

REGION="ap-south-1"
VPC_CIDR="10.0.0.0/16"
PUBLIC_CIDR="10.0.1.0/24"
PRIVATE_A_CIDR="10.0.2.0/24"
PRIVATE_B_CIDR="10.0.3.0/24"
PROJECT="stackforge"

log() { echo "[$(date -u +%H:%M:%S)] $*"; }

log "=== [1/8] Creating VPC ==="
VPC_ID=$(aws ec2 create-vpc \
  --cidr-block "$VPC_CIDR" \
  --region "$REGION" \
  --query 'Vpc.VpcId' --output text)
aws ec2 create-tags --resources "$VPC_ID" \
  --tags Key=Name,Value="${PROJECT}-vpc" --region "$REGION"
aws ec2 modify-vpc-attribute --vpc-id "$VPC_ID" \
  --enable-dns-hostnames --region "$REGION"
log "VPC: $VPC_ID"

log "=== [2/8] Creating Subnets ==="
PUBLB�C_SUBNET =$(aws ec2 create-subnet \
  --vpc-id "$VPC_ID" --cidr-block "$PUBLIC_CIDR" \
  --availability-zone "${REGION}a" \
  --region "$REGION" --query 'Subnet.SubnetId' --output text)
aws ec2 create-tags --resources "$PUBLIC_SUBNET" \
  --tags Key=Name,Value="${PROJECT}-public-subnet" --region "$REGION"

PRIVATE_A=$(aws ec2 create-subnet \
  --vpc-id "$VPC_ID" --cidr-block "$PRIVATE_A_CIDR" \
  --availability-zone "${REGION}a" \
  --region "$REGION" --query 'Subnet.SubnetId' --output text)
aws ec2 create-tags --resources "$PRIVATE_A" \
  --tags Key=Name,Value="${PROJECT}-private-subnet-a" --region "$REGION"

PRIVATE_B=$(aws ec2 create-subnet \
  --vpc-id "$VPC_ID" --cidr-block "$PRIVATE_B_CIDR" \
  --availability-zone "${REGION}b" \
  --region "$REGION" --query 'Subnet.SubnetId' --output text)
aws ec2 create-tags --resources "$PRIVATE_B" \
  --tags Key=Name,Value="${PROJECT}-private-subnet-b" --region "$REGION"
log "Public: $PUBLIC_SUBNET | Private-A: $PRIVATE_A | Private-B: $PRIVATE_B"

log "=== [3/8] Creating Internet Gateway ==="
IGW_ID=$(aws ec2 create-internet-gateway \
  --region "$REGION" --query 'InternetGateway.InternetGatewayId' --output text)
aws ec2 attach-internet-gateway \
  --internet-gateway-id "$IGW_ID" --vpc-id "$VPC_ID" --region "$REGION"
aws ec2 create-tags --resources "$IGW_ID" \
  --tags Key=Name,Value="${PROJECT}-igw" --region "$REGION"
log "IGW: $IGW_ID"

log "=== [4/8] Creating NAT Gateway ==="
EIP_ALLOC=$(aws ec2 allocate-address \
  --domain vpc --region "$REGION" --query 'AllocationId' --output text)
NAT_GW=$(aws ec2 create-nat-gateway \
  --subnet-id "$PUBLIC_SUBNET" \
  --allocation-id "$EIP_ALLOC" \
  --region "$REGION" --query 'NatGateway.NatGatewayId' --output text)
aws ec2 create-tags --resources "$NAT_GW" \
  --tags Key=Name,Value="${PROJECT}-nat" --region "$REGION"
log "NAT: $NAT_GW — waiting for available state..."
aws ec2 wait nat-gateway-available \
  --nat-gateway-ids "$NAT_GW" --region "$REGION"

log "=== [5/8] Creating Route Tables ==="
PUBLIC_RT=$(aws ec2 create-route-table \
  --vpc-id "$VPC_ID" --region "$REGION" \
  --query 'RouteTable.RouteTableId' --output text)
aws ec2 create-route \
  --route-table-id "$PUBLIC_RT" \
  --destination-cidr-block 0.0.0.0/0 \
  --gateway-id "$IGW_ID" --region "$REGION"
aws ec2 associate-route-table \
  --route-table-id "$PUBLIC_RT" \
  --subnet-id "$PUBLIC_SUBNET" --region "$REGION"

PRIVATE_RT=$(aws ec2 create-route-table \
  --vpc-id "$VPC_ID" --region "$REGION" \
  --query 'RouteTable.RouteTableId' --output text)
aws ec2 create-route \
  --route-table-id "$PRIVATE_RT" \
  --destination-cidr-block 0.0.0.0/0 \
  --nat-gateway-id "$NAT_GW" --region "$REGION"
aws ec2 associate-route-table \
  --route-table-id "$PRIVATE_RT" \
  --subnet-id "$PRIVATE_A" --region "$REGION"
aws ec2 associate-route-table \
  --route-table-id "$PRIVATE_RT" \
  --subnet-id "$PRIVATE_B" --region "$REGION"

log "=== [6/8] Creating Security Groups ==="
SG_ALB=$(aws ec2 create-security-group \
  --group-name "${PROJECT}-sg-alb" \
  --description "ALB - public HTTP/HTTPS" \
  --vpc-id "$VPC_ID" --region "$REGION" \
  --query 'GroupId' --output text)
aws ec2 authorize-security-group-ingress \
  --group-id "$SG_ALB" --protocol tcp --port 80 --cidr 0.0.0.0/0 --region "$REGION"
aws ec2 authorize-security-group-ingress \
  --group-id "$SG_ALB" --protocol tcp --port 443 --cidr 0.0.0.0/0 --region "$REGION"

SG_EC2=$(aws ec2 create-security-group \
  --group-name "${PROJECT}-sg-ec2" \
  --description "EC2 Jenkins - port 8080 from ALB, SSH restricted" \
  --vpc-id "$VPC_ID" --region "$REGION" \
  --query 'GroupId' --output text)
aws ec2 authorize-security-group-ingress \
  --group-id "$SG_EC2" --protocol tcp --port 8080 \
  --source-group "$SG_ALB" --region "$REGION"
aws ec2 authorize-security-group-ingress \
  --group-id "$SG_EC2" --protocol tcp --port 22 --cidr 0.0.0.0/0 --region "$REGION"

SG_RDS=$(aws ec2 create-security-group \
  --group-name "${PROJECT}-sg-rds" \
  --description "RDS PostgreSQL - only from EC2" \
  --vpc-id "$VPC_ID" --region "$REGION" \
  --query 'GroupId' --output text)
aws ec2 authorize-security-group-ingress \
  --group-id "$SG_RDS" --protocol tcp --port 5432 \
  --source-group "$SG_EC2" --region "$REGION"

log "SG ALB: $SG_ALB | EC2: $SG_EC2 | RDS: $SG_RDS"

log "=== [7/8] Creating RDS PostgreSQL ==="
acws rds create-db-subnet-group \
  --db-subnet-group-name "${PROJECT}-subnet-group" \
  --db-subnet-group-description "StackForge RDS subnet group" \
  --subnet-ids "$PRIVATE_A" "$PRIVATE_B" \
  --region "$REGION"

aws rds create-db-instance \
  --db-instance-identifier "${PROJECT}-postgres" \
  --db-instance-class db.t3.micro \
  --engine postgres \
  --engine-version "14.10" \
  --master-username stackforge \
  --master-user-password stackforge_pass \
  --db-name stackforge \
  --allocated-storage 20 \
  --no-publicly-accessible \
  --vpc-security-group-ids "$SG_RDS" \
  --db-subnet-group-name "${PROJECT}-subnet-group" \
  --backup-retention-period 7 \
  --region "$REGION"
log "RDS creation started (takes ~5 min)..."

log "=== [8/8] Creating S3 Bucket ==="
aws s3api create-bucket \
  --bucket "${PROJECT}-artifacts" \
  --region "$REGION" \
  --create-bucket-configuration LocationConstraint="$REGION"

aws s3api put-bucket-lifecycle-configuration \
  --bucket "${PROJECT}-artifacts" \
  --lifecycle-configuration '{
    "Rules": [{
      "ID": "archive-logs",
      "Status": "Enabled",
      "Filter": {"Prefix": "app-logs/"},
      "Transitions": [{"Days": 30, "StorageClass": "GLACIER"}],
      "Expiration": {"Days": 365}
    }]
  }'

log "=== VPC SETUP COMPLETE ==="
log "VPC: $VPC_ID | Public: $PUBLIC_SUBNET | Private-A: $PRIVATE_A | Private-B: $PRIVATE_B"
log "Save these IDs for EC2 launch"
