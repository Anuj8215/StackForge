#!/bin/bash
# log-archiver.sh — Runs on EC2 via cron daily at 2am
# Archives pod logs and Jenkins build logs to S3
# Cron: 0 2 * * * /home/ec2-user/scripts/log-archiver.sh >> /var/log/log-archiver.log 2>&1
set -euo pipefail

NAMESPACE="stackforge"
S3_BUCKET="stackforge-artifacts"
REGION="ap-south-1"
DATE=$(date +"%Y-%m-%d")
LOG_DIR="/tmp/stackforge-logs-$DATE"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Trap to clean up temp dir on exit
trap 'rm -rf "$LOG_DIR"' EXIT

log() { echo "[$TIMESTAMP] $*"; }

log "=== Log Archiver Started ==="

mkdir -p "$LOG_DIR/pods" "$LOG_DIR/jenkins"

# Archive logs for each running pod
for POD in $(kubectl get pods -n "$NAMESPACE" -o jsonpath='{.items[*].metadata.name}'); do
  log "Archiving logs for pod: $POD"
  kubectl logs "$POD" -n "$NAMESPACE" --previous=false \
    > "$LOG_DIR/pods/${POD}.log" 2>/dev/null || true
  kubectl logs "$POD" -n "$NAMESPACE" --previous=true \
    > "$LOG_DIR/pods/${POD}-previous.log" 2>/dev/null || true
done

# Archive Jenkins build logs (last 10 builds)
if [ -d "/var/lib/jenkins/jobs" ]; then
  log "Archiving Jenkins build logs"
  find /var/lib/jenkins/jobs -name "log" -newer /tmp/.last-archive \
    -exec cp --parents {} "$LOG_DIR/jenkins/" \; 2>/dev/null || true
  touch /tmp/.last-archive
fi

# Compress and upload to S3
ARCHIVE="stackforge-logs-$DATE.tar.gz"
tar -czf "/tmp/$ARCHIVE" -C /tmp "stackforge-logs-$DATE"

log "Uploading $ARCHIVE to s3://$S3_BUCKET/app-logs/$DATE/"
aws s3 cp "/tmp/$ARCHIVE" \
  "s3://$S3_BUCKET/app-logs/$DATE/$ARCHIVE" \
  --region "$REGION" \
  --storage-class STANDARD_IA

rm -f "/tmp/$ARCHIVE"

log "=== Log Archiver Done — archived to s3://$S3_BUCKET/app-logs/$DATE/ ==="
