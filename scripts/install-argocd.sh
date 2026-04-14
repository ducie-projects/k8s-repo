#!/bin/bash

# ArgoCD Installation Script

set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KUBECONFIG_PATH="$REPO_DIR/cluster/kubeconfig"

# Check if kubeconfig exists
if [ ! -f "$KUBECONFIG_PATH" ]; then
  echo "❌ Kubeconfig not found at $KUBECONFIG_PATH"
  echo "Please run ./scripts/setup.sh first to create the cluster"
  exit 1
fi

export KUBECONFIG="$KUBECONFIG_PATH"

echo "📦 Installing ArgoCD..."
echo "Repository: $REPO_DIR"

# Install ArgoCD using Kustomize
echo "Applying ArgoCD manifests..."
kubectl apply -k "$REPO_DIR/argocd/install"

# Wait for ArgoCD to be ready
echo ""
echo "⏳ Waiting for ArgoCD to be ready..."
kubectl rollout status deployment/argocd-server -n argocd --timeout=300s

echo ""
echo "✅ ArgoCD installed successfully!"
echo ""
echo "🎯 Access ArgoCD:"
echo "   kubectl port-forward -n argocd svc/argocd-server 8080:443"
echo "   Then visit: https://localhost:8080"
echo ""
echo "📝 Get initial admin password:"
echo "   kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath=\"{.data.password}\" | base64 -d"
echo ""
echo "Username: admin"
