#!/bin/bash

# Kubernetes Cluster Setup Script

set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KUBECONFIG_PATH="$REPO_DIR/cluster/kubeconfig"
CLUSTER_CONFIG="$REPO_DIR/cluster/config/kind-cluster.yaml"

echo "📦 Setting up Kubernetes cluster..."
echo "Repository: $REPO_DIR"

# Create cluster
echo "Creating Kind cluster..."
kind create cluster --config "$CLUSTER_CONFIG" --kubeconfig "$KUBECONFIG_PATH"

# Set kubeconfig
export KUBECONFIG="$KUBECONFIG_PATH"

# Verify
echo ""
echo "✅ Cluster created successfully!"
echo ""
kubectl cluster-info
echo ""
echo "Nodes:"
kubectl get nodes
echo ""
echo "🎯 To use this cluster, run:"
echo "export KUBECONFIG=$KUBECONFIG_PATH"
