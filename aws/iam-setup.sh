#!/bin/bash
# iam-setup.sh — Creates IAM role for EC2 Jenkins and IAM user for CI/CD
set -euo pipefail

REGION="ap-south-1"
PROJECT="stackforge"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

log() { echo "[$(date -u +%H:%M:%S)] $*"; }

log "=== [1/4] Creating EC2 Instance Role (Jenkins + scripts) ==="
aws iam create-role \
  --role-name "${PROJECT}-ec2-role" \
  --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": {"Service": "ec2.amazonaws.com"},
      "Action": "sts:AssumeRole"
    }]
  }'

aws iam put-role-policy \
  --role-name "${PROJECT}-ec2-role" \
  --policy-name "${PROJECT}-ec2-policy" \
  --policy-document "{
    \"Version\": \"2012-10-17\",
    \"Statement\": [
      {
        \"Effect\": \"Allow\",
        \"Action\": [\"s3:PutObject\", \"s3:GetObject\", \"s3:ListBucket\"],
        \"Resource\": [
          \"arn:aws:s3:::${PROJECT}-artifacts\",
          \"arn:aws:s3:::${PROJECT}-artifacts/*\"
        ]
      },
      {
        \"Effect\": \"Allow\",
        \"Action\": [\"cloudwatch:PutMetricData\", \"cloudwatch:GetMetricStatistics\"],
        \"Resource\": \"*\"
      },
      {
        \"Effect\": \"Allow\",
        \"Action\": [\"sns:Publish\"],
        \"Resource\": \"arn:aws:sns:${REGION}:${ACCOUNT_ID}:${PROJECT}-alerts\"
      },
      {
        \"Effect\": \"Allow\",
        \"Action\": [\"ssm:GetParameter\"],
        \"Resource\": \"arn:aws:ssm:${REGION}:${ACCOUNT_ID}:parameter/${PROJECT}/*\"
      }
    ]
  }"

aws iam create-instance-profile \
  --instance-profile-name "${PROJECT}-ec2-profile"
aws iam add-role-to-instance-profile \
  --instance-profile-name "${PROJECT}-ec2-profile" \
  --role-name "${PROJECT}-ec2-role"
log "EC2 instance profile: ${PROJECT}-ec2-profile"

log "=== [2/4] Creating Jenkins IAM User ==="
aws iam create-user --user-name "${PROJECT}-jenkins"
aws iam put-user-policy \
  --user-name "${PROJECT}-jenkins" \
  --policy-name "${PROJECT}-jenkins-policy" \
  --policy-document "{
    \"Version\": \"2012-10-17\",
    \"Statement\": [
      {
        \"Effect\": \"Allow\",
        \"Action\": [\"s3:PutObject\", \"s3:GetObject\"],
        \"Resource\": \"arn:aws:s3:::${PROJECT}-artifacts/*\"
      }
    ]
  }"

log "=== [3/4] Creating Jenkins access keys ==="
aws iam create-access-key \
  --user-name "${PROJECT}-jenkins" \
  --query 'AccessKey.{Key:AccessKeyId,Secret:SecretAccessKey}' \
  --output table
log "SAVE THESE KEYS — add to Jenkins credentials store"

log "=== [4/4] Creating SNS Topic ==="
SNS_ARN=$(aws sns create-topic \
  --name "${PROJECT}-alerts" \
  --region "$REGION" \
  --query 'TopicArn' --output text)
log "SNS Topic ARN: $SNS_ARN"
log "Add your email subscription:"
log "aws sns subscribe --topic-arn $SNS_ARN --protocol email --notification-endpoint your@email.com --region $REGION"

log "=== IAM SETUP COMPLETE ==="
