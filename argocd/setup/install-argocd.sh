#!/bin/bash
# install-argocd.sh — Run once on K8s cluster to install ArgoCD
set -euo pipefail

echo "=== [1/5] Creating argocd namespace ==="
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

echo "=== [2/5] Installing ArgoCD ==="
kubectl apply -n argocd \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "=== [3/5] Waiting for ArgoCD server to be ready ==="
kubectl wait --for=condition=available \
  --timeout=300s \
  deployment/argocd-server \
  -n argocd

echo "=== [4/5] Exposing ArgoCD server via LoadBalancer ==="
kubectl patch svc argocd-server \
  -n argocd \
  -p '{"spec": {"type": "LoadBalancer"}}'

echo "=== [5/5] Fetching initial admin password ==="
echo ""
echo "ArgoCD admin password:"
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d
echo ""
echo ""
echo "ArgoCD server URL:"
kubectl get svc argocd-server -n argocd \
  -o jsonpath="{.status.loadBalancer.ingress[0].hostname}"
echo ""
