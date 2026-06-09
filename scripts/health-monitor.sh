#!/bin/bash
# health-monitor.sh — Runs on EC2 via cron every 5 minutes
# Checks pod health and pushes custom metric to CloudWatch
# Cron: */5 * * * * /home/ec2-user/scripts/health-monitor.sh >> /var/log/health-monitor.log 2>&1
set -euo pipefail

NAMESPACE="stackforge"
METRIC_NAMESPACE="StackForge/Health"
REGION="ap-south-1"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

log() { echo "[$TIMESTAMP] $*"; }

log "=== Health Monitor Started ==="

# Check for CrashLoopBackOff pods
CRASH_PODS=$(kubectl get pods -n "$NAMESPACE" \
  --field-selector=status.phase!=Running \
  -o jsonpath='{.items[*].metadata.name}' 2>/dev/null || echo "")

CRASH_COUNT=$(kubectl get pods -n "$NAMESPACE" 2>/dev/null \
  | grep -c "CrashLoopBackOff" || echo "0")

# Count healthy pods
HEALTHY_PODS=$(kubectl get pods -n "$NAMESPACE" \
  --field-selector=status.phase=Running \
  -o jsonpath='{.items[*].metadata.name}' 2>/dev/null | wc -w | tr -d ' ')

log "Healthy pods: $HEALTHY_PODS | CrashLoopBackOff: $CRASH_COUNT"

# Push healthy pod count to CloudWatch
aws cloudwatch put-metric-data \
  --namespace "$METRIC_NAMESPACE" \
  --metric-name HealthyPodCount \
  --value "$HEALTHY_PODS" \
  --unit Count \
  --region "$REGION"

# Push crash count to CloudWatch
aws cloudwatch put-metric-data \
  --namespace "$METRIC_NAMESPACE" \
  --metric-name CrashLoopBackOffCount \
  --value "$CRASH_COUNT" \
  --unit Count \
  --region "$REGION"

# Alert via SNS if any pod is CrashLoopBackOff
if [ "$CRASH_COUNT" -gt 0 ]; then
  log "ALERT: $CRASH_COUNT pod(s) in CrashLoopBackOff — sending SNS alert"
  aws sns publish \
    --topic-arn "arn:aws:sns:ap-south-1:$(aws sts get-caller-identity --query Account --output text):stackforge-alerts" \
    --message "ALERT: $CRASH_COUNT pod(s) in CrashLoopBackOff in namespace $NAMESPACE at $TIMESTAMP. Pods: $CRASH_PODS" \
    --subject "StackForge CrashLoopBackOff Alert" \
    --region "$REGION"
fi

log "=== Health Monitor Done ==="
