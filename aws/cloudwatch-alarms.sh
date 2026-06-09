#!/bin/bash
# cloudwatch-alarms.sh — Creates CloudWatch alarms for EC2 and deployment health
set -euo pipefail

REGION="ap-south-1"
PROJECT="stackforge"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
SNS_ARN="arn:aws:sns:${REGION}:${ACCOUNT_ID}:${PROJECT}-alerts"
EC2_INSTANCE_ID="${1:-REPLACE_WITH_INSTANCE_ID}"

log() { echo "[$(date -u +%H:%M:%S)] $*"; }

log "=== Creating CloudWatch Alarms ==="

# EC2 CPU high alarm
aws cloudwatch put-metric-alarm \
  --alarm-name "${PROJECT}-ec2-cpu-high" \
  --alarm-description "EC2 Jenkins CPU > 80% for 5 minutes" \
  --metric-name CPUUtilization \
  --namespace AWS/EC2 \
  --statistic Average \
  --period 300 \
  --threshold 80 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 2 \
  --dimensions Name=InstanceId,Value="$EC2_INSTANCE_ID" \
  --alarm-actions "$SNS_ARN" \
  --region "$REGION"
log "Alarm: EC2 CPU high"

# Pod CrashLoopBackOff alarm
aws cloudwatch put-metric-alarm \
  --alarm-name "${PROJECT}-pod-crashloop" \
  --alarm-description "Pods in CrashLoopBackOff detected" \
  --metric-name CrashLoopBackOffCount \
  --namespace "StackForge/Health" \
  --statistic Maximum \
  --period 300 \
  --threshold 0 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 1 \
  --alarm-actions "$SNS_ARN" \
  --treat-missing-data notBreaching \
  --region "$REGION"
log "Alarm: Pod CrashLoopBackOff"

# Deployment failure alarm
aws cloudwatch put-metric-alarm \
  --alarm-name "${PROJECT}-deploy-failed" \
  --alarm-description "Deployment failed (success metric = 0)" \
  --metric-name DeploymentSuccess \
  --namespace "StackForge/Deployments" \
  --statistic Minimum \
  --period 300 \
  --threshold 1 \
  --comparison-operator LessThanThreshold \
  --evaluation-periods 1 \
  --alarm-actions "$SNS_ARN" \
  --treat-missing-data notBreaching \
  --region "$REGION"
log "Alarm: Deployment failure"

log "=== CLOUDWATCH ALARMS CREATED ==="
