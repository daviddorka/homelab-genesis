#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="$REPO_ROOT/.env"

if [[ -f "$ENV_FILE" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  set +a
fi

PROJECT_ID="${PROJECT_ID:-}"
CLUSTER_NAME="${CLUSTER_NAME:-homelab-genesis}"
ZONE="${ZONE:-europe-west4-a}"
ARGOCD_NAMESPACE="${ARGOCD_NAMESPACE:-argocd}"
REPO_URL="${REPO_URL:-https://github.com/your-org/homelab-genesis.git}"
BRANCH="${BRANCH:-main}"

if [[ -z "$PROJECT_ID" ]]; then
  echo "Set PROJECT_ID first, for example: export PROJECT_ID=your-gcp-project-id"
  exit 1
fi

echo "Fetching credentials for $CLUSTER_NAME..."
gcloud container clusters get-credentials "$CLUSTER_NAME" --zone "$ZONE" --project "$PROJECT_ID"

echo "Creating Argo CD namespace..."
kubectl create namespace "$ARGOCD_NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

echo "Installing Argo CD..."
kubectl apply -n "$ARGOCD_NAMESPACE" --server-side=true --force-conflicts -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl -n "$ARGOCD_NAMESPACE" rollout status deployment/argocd-server --timeout=600s

echo "Waiting for Argo CD API server..."
kubectl wait --namespace "$ARGOCD_NAMESPACE" --for=condition=available deployment/argocd-server --timeout=600s

ARGOCD_ADMIN_PASSWORD="$(kubectl -n "$ARGOCD_NAMESPACE" get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d)"

echo "Argo CD admin password: $ARGOCD_ADMIN_PASSWORD"

echo "Port-forward Argo CD with: kubectl port-forward svc/argocd-server -n $ARGOCD_NAMESPACE 8080:443"

echo "Login with username admin and the password above"

echo "Applying Argo CD application for the DNS manifests..."

cat <<EOF | kubectl apply -f -
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: netbird-dns
  namespace: $ARGOCD_NAMESPACE
spec:
  project: default
  source:
    repoURL: $REPO_URL
    targetRevision: $BRANCH
    path: manifests/netbird-dns
  destination:
    server: https://kubernetes.default.svc
    namespace: netbird-dns
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
EOF

echo "Bootstrap complete."
