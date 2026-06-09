#!/bin/bash
# register-repo.sh — Register StackForge GitHub repo with ArgoCD
# Run after install-argocd.sh
# Usage: GITHUB_TOKEN=<token> bash register-repo.sh
set -euo pipefail

REPO_URL="https://github.com/Anuj8215/StackForge.git"
GITHUB_USER="Anuj8215"

if [ -z "${GITHUB_TOKEN:-}" ]; then
  echo "ERROR: GITHUB_TOKEN env var is required"
  echo "Usage: GITHUB_TOKEN=<your-token> bash register-repo.sh"
  exit 1
fi

echo "=== [1/2] Logging into ArgoCD CLI ==="
ARGOCD_SERVER=$(kubectl get svc argocd-server -n argocd \
  -o jsonpath="{.status.loadBalancer.ingress[0].hostname}")

ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d)

argocd login "$ARGOCD_SERVER" \
  --username admin \
  --password "$ARGOCD_PASSWORD" \
  --insecure

echo "=== [2/2] Registering StackForge repo ==="
argocd repo add "$REPO_URL" \
  --username "$GITHUB_USER" \
  --password "$GITHUB_TOKEN"

echo ""
echo "Repo registered. Applying ArgoCD app manifest..."
kubectl apply -f argocd/argocd-app.yaml

echo ""
echo "ArgoCD is now watching: $REPO_URL"
echo "Path: k8s/ | Branch: main | Namespace: stackforge"
echo "Auto-sync: ON | Self-heal: ON | Prune: ON"
