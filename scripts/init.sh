#!/bin/bash

# K8s Repository Initialization Script
# This script sets up the entire Kubernetes cluster with ArgoCD and all configurations

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get repository root directory
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KUBECONFIG_PATH="$REPO_DIR/cluster/kubeconfig"
CLUSTER_CONFIG="$REPO_DIR/cluster/config/kind-cluster.yaml"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  K8s Repository Initialization${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${YELLOW}Repository: $REPO_DIR${NC}"
echo ""

# Step 1: Check prerequisites
echo -e "${YELLOW}[1/5] Checking prerequisites...${NC}"
command -v kind &> /dev/null || { echo -e "${RED}❌ kind is not installed${NC}"; exit 1; }
command -v kubectl &> /dev/null || { echo -e "${RED}❌ kubectl is not installed${NC}"; exit 1; }
echo -e "${GREEN}✓ Prerequisites OK${NC}"
echo ""

# Step 2: Create Kind Cluster
echo -e "${YELLOW}[2/5] Creating Kind cluster...${NC}"
if [ -f "$KUBECONFIG_PATH" ]; then
  echo -e "${BLUE}ℹ Kubeconfig already exists, skipping cluster creation${NC}"
else
  kind create cluster --config "$CLUSTER_CONFIG" --kubeconfig "$KUBECONFIG_PATH"
  echo -e "${GREEN}✓ Cluster created${NC}"
fi
export KUBECONFIG="$KUBECONFIG_PATH"
echo ""

# Step 3: Install ArgoCD
echo -e "${YELLOW}[3/5] Installing ArgoCD...${NC}"
echo "Creating argocd namespace..."
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

echo "Installing ArgoCD from official manifests..."
kubectl apply -k "$REPO_DIR/argocd/install" > /dev/null

echo "Waiting for ArgoCD to be ready..."
kubectl rollout status deployment/argocd-server -n argocd --timeout=300s > /dev/null 2>&1 || true
sleep 10

echo -e "${GREEN}✓ ArgoCD installed${NC}"
echo ""

# Step 4: Apply ArgoCD Configuration
echo -e "${YELLOW}[4/5] Applying ArgoCD configuration...${NC}"
echo "Applying RBAC configuration..."
kubectl apply -f "$REPO_DIR/argocd/config/argocd-rbac-cm.yaml" > /dev/null

echo "Applying main configuration..."
kubectl apply -f "$REPO_DIR/argocd/config/argocd-cm.yaml" > /dev/null

echo "Applying accounts configuration..."
kubectl apply -f "$REPO_DIR/argocd/config/argocd-accounts.yaml" > /dev/null

echo "Applying notification configuration..."
kubectl apply -f "$REPO_DIR/argocd/config/argocd-notifications.yaml" > /dev/null

echo -e "${GREEN}✓ Configuration applied${NC}"
echo ""

# Step 5: Deploy Applications
echo -e "${YELLOW}[5/5] Deploying ArgoCD Applications...${NC}"
echo "Applying web-app application..."
kubectl apply -f "$REPO_DIR/argocd/applications/web-app.yaml" > /dev/null

echo "Applying api-service application..."
kubectl apply -f "$REPO_DIR/argocd/applications/api-service.yaml" > /dev/null

echo -e "${GREEN}✓ Applications deployed${NC}"
echo ""

# Get initial password
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}✓ Initialization Complete!${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

echo -e "${YELLOW}📝 Access Information:${NC}"
echo ""
echo "1. Set kubeconfig environment:"
echo -e "   ${BLUE}export KUBECONFIG=$KUBECONFIG_PATH${NC}"
echo ""

echo "2. Port-forward to ArgoCD server:"
echo -e "   ${BLUE}kubectl port-forward -n argocd svc/argocd-server 8080:443${NC}"
echo ""

echo "3. Get ArgoCD admin password:"
ADMIN_PASS=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" 2>/dev/null | base64 -d || echo "ERROR")
if [ "$ADMIN_PASS" != "ERROR" ]; then
  echo -e "   ${BLUE}Username: admin${NC}"
  echo -e "   ${BLUE}Password: $ADMIN_PASS${NC}"
else
  echo -e "   ${BLUE}kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath=\"{.data.password}\" | base64 -d${NC}"
fi
echo ""

echo "4. Access ArgoCD UI:"
echo -e "   ${BLUE}https://localhost:8080${NC}"
echo ""

echo -e "${YELLOW}📊 Cluster Status:${NC}"
echo ""
echo "Nodes:"
kubectl get nodes
echo ""

echo "ArgoCD Status:"
kubectl get pods -n argocd
echo ""

echo "ArgoCD Applications:"
kubectl get applications -n argocd
echo ""

echo -e "${GREEN}🎯 Next Steps:${NC}"
echo "1. Run: export KUBECONFIG=$KUBECONFIG_PATH"
echo "2. Run: kubectl port-forward -n argocd svc/argocd-server 8080:443"
echo "3. Visit: https://localhost:8080"
echo "4. Login with credentials above"
echo "5. View your applications in the ArgoCD UI"
echo ""

echo -e "${YELLOW}📚 Documentation:${NC}"
echo "- Cluster: $REPO_DIR/README.md"
echo "- ArgoCD: $REPO_DIR/argocd/README.md"
echo "- Applications: $REPO_DIR/argocd/applications/README.md"
echo ""

echo -e "${GREEN}✓ Setup complete!${NC}"
