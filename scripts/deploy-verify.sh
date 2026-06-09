#!/bin/bash
# deploy-verify.sh — Run by Jenkins after ArgoCD sync completes
# Verifies rollout succeeded and pushes deployment status to CloudWatch
# Usage: bash deploy-verify.sh <image-tag>
set -euo pipefail

IMAGE_TAG="${1:-unknown}"
NAMESPACE="stackforge"
METRIC_NAMESPACE="StackForge/Deployments"
REGION="ap-south-1"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
MAX_WAIT=180

log() { echo "[$TIMESTAMP] $*"; }

log "=== Deploy Verify Started — tag: $IMAGE_TAG ==="

# Wait for frontend rollout
log "Waiting for frontend rollout..."
if kubectl rollout status deployment/frontend \
    -n "$NAMESPACE" \
    --timeout="${MAX_WAIT}s"; then
  FRONTEND_STATUS=1
  log "frontend: OK"
else
  FRONTEND_STATUS=0
  log "frontend: FAILED"
fi

# Wait for backend rollout
log "Waiting for backend rollout..."
if kubectl rollout status deployment/backend \
    -n "$NAMESPACE" \
    --timeout="${MAX_WAIT}s"; then
  BACKEND_STATUS=1
  log "backend: OK"
else
  BACKEND_STATUS=0
  log "backend: FAILED"
fi

# Get final pod status
kubectl get pods -n "$NAMESPACE" -o wide
log "Pod status captured"

# Push deployment status metric to CloudWatch
DEPLOY_SUCCESS=$(( FRONTEND_STATUS & BACKEND_STATUS ))
aws cloudwatch put-metric-data \
  --namespace "$METRIC_NAMESPACE" \
  --metric-name DeploymentSuccess \
  --value "$DEPLOY_SUCCESS" \
  --dimensions ImageTag="$IMAGE_TAG" \
  --unit Count \
  --region "$REGION"

if [ "$DEPLOY_SUCCESS" -eq 1 ]; then
  log "Deployment SUCCESSFUL — image: $IMAGE_TAG"
  exit 0
else
  log "Deployment FAILED — image: $IMAGE_TAG"
  aws sns publish \
    --topic-arn "arn:aws:sns:ap-south-1:$(aws sts get-caller-identity --query Account --output text):stackforge-alerts" \
    --message "DEPLOY FAILED: image $IMAGE_TAG failed rollout in namespace $NAMESPACE at $TIMESTAMP" \
    --subject "StackForge Deploy Failure" \
    --region "$REGION"
  exit 1
fi
