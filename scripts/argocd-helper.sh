#!/bin/bash

# ArgoCD Helper Script
# Utility functions for managing ArgoCD installation and configuration

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

# Default ArgoCD namespace
ARGOCD_NAMESPACE="argocd"
ARGOCD_VERSION="latest"

# Functions

# Print usage
usage() {
  cat << USAGE
${BLUE}ArgoCD Helper Script${NC}

Usage: ./scripts/argocd-helper.sh <command> [options]

Commands:
  install-cli           Install ArgoCD CLI binary
  get-password          Get ArgoCD admin password
  get-token             Get ArgoCD API token
  port-forward          Start port-forward to ArgoCD server
  login                 Login to ArgoCD server
  list-apps             List all ArgoCD applications
  get-app               Get application details
  create-user           Create a new ArgoCD user account
  delete-user           Delete an ArgoCD user account
  change-password       Change admin password
  export-config         Export ArgoCD configuration
  health                Check ArgoCD health status
  help                  Show this help message

Examples:
  ./scripts/argocd-helper.sh install-cli
  ./scripts/argocd-helper.sh get-password
  ./scripts/argocd-helper.sh port-forward
  ./scripts/argocd-helper.sh login
  ./scripts/argocd-helper.sh list-apps
  ./scripts/argocd-helper.sh get-app myapp
  ./scripts/argocd-helper.sh create-user developer
  ./scripts/argocd-helper.sh change-password

USAGE
}

# Check if kubeconfig exists
check_kubeconfig() {
  if [ ! -f "$KUBECONFIG_PATH" ]; then
    echo -e "${RED}❌ Kubeconfig not found at $KUBECONFIG_PATH${NC}"
    echo -e "${YELLOW}Please run: ./scripts/init.sh${NC}"
    exit 1
  fi
  export KUBECONFIG="$KUBECONFIG_PATH"
}

# Check if ArgoCD is installed
check_argocd_installed() {
  if ! kubectl get deployment argocd-server -n "$ARGOCD_NAMESPACE" &> /dev/null; then
    echo -e "${RED}❌ ArgoCD is not installed${NC}"
    echo -e "${YELLOW}Please run: ./scripts/init.sh${NC}"
    exit 1
  fi
}

# Install ArgoCD CLI
install_cli() {
  echo -e "${YELLOW}Installing ArgoCD CLI...${NC}"
  
  if command -v argocd &> /dev/null; then
    echo -e "${GREEN}✓ ArgoCD CLI already installed${NC}"
    argocd version --client
    return
  fi
  
  OS=$(uname -s)
  ARCH=$(uname -m)
  
  case "$OS" in
    Darwin)
      echo -e "${BLUE}Installing for macOS...${NC}"
      if command -v brew &> /dev/null; then
        brew install argocd
      else
        echo -e "${YELLOW}Homebrew not found. Installing from source...${NC}"
        curl -sSL -o argocd https://github.com/argoproj/argo-cd/releases/download/v2.10.0/argocd-darwin-amd64
        chmod +x argocd
        sudo mv argocd /usr/local/bin/argocd
      fi
      ;;
    Linux)
      echo -e "${BLUE}Installing for Linux...${NC}"
      curl -sSL -o argocd https://github.com/argoproj/argo-cd/releases/download/v2.10.0/argocd-linux-amd64
      chmod +x argocd
      sudo mv argocd /usr/local/bin/argocd
      ;;
    *)
      echo -e "${RED}❌ Unsupported operating system: $OS${NC}"
      exit 1
      ;;
  esac
  
  echo -e "${GREEN}✓ ArgoCD CLI installed${NC}"
  argocd version --client
}

# Get ArgoCD admin password
get_password() {
  echo -e "${BLUE}Getting ArgoCD admin password...${NC}"
  check_kubeconfig
  check_argocd_installed
  
  PASSWORD=$(kubectl -n "$ARGOCD_NAMESPACE" get secret argocd-initial-admin-secret \
    -o jsonpath="{.data.password}" 2>/dev/null | base64 -d || echo "ERROR")
  
  if [ "$PASSWORD" = "ERROR" ]; then
    echo -e "${RED}❌ Could not retrieve password${NC}"
    echo -e "${YELLOW}The secret may have been deleted. Use 'argocd account update-password' instead.${NC}"
    exit 1
  fi
  
  echo ""
  echo -e "${GREEN}✓ ArgoCD Credentials:${NC}"
  echo -e "  ${BLUE}Username:${NC} admin"
  echo -e "  ${BLUE}Password:${NC} $PASSWORD"
  echo ""
}

# Get ArgoCD API token
get_token() {
  echo -e "${BLUE}Getting ArgoCD API token...${NC}"
  check_kubeconfig
  check_argocd_installed
  
  # Check if argocd CLI is installed
  if ! command -v argocd &> /dev/null; then
    echo -e "${RED}❌ ArgoCD CLI is required${NC}"
    echo -e "${YELLOW}Please run: ./scripts/argocd-helper.sh install-cli${NC}"
    exit 1
  fi
  
  # Get password first
  PASSWORD=$(kubectl -n "$ARGOCD_NAMESPACE" get secret argocd-initial-admin-secret \
    -o jsonpath="{.data.password}" 2>/dev/null | base64 -d)
  
  ARGOCD_SERVER=$(kubectl get svc -n "$ARGOCD_NAMESPACE" argocd-server -o jsonpath='{.spec.clusterIP}')
  
  echo -e "${YELLOW}Generating token...${NC}"
  TOKEN=$(argocd account generate-token --account admin --server "$ARGOCD_SERVER:443" --insecure || echo "ERROR")
  
  if [ "$TOKEN" = "ERROR" ]; then
    echo -e "${YELLOW}Note: Token generation requires port-forward. Starting port-forward...${NC}"
    kubectl port-forward -n "$ARGOCD_NAMESPACE" svc/argocd-server 8080:443 &
    sleep 2
    TOKEN=$(argocd account generate-token --account admin --server localhost:8080 --insecure --grpc-web)
    kill %1 2>/dev/null || true
  fi
  
  echo ""
  echo -e "${GREEN}✓ ArgoCD API Token:${NC}"
  echo -e "  ${BLUE}$TOKEN${NC}"
  echo ""
  echo -e "${YELLOW}Use this token for:${NC}"
  echo "  - ArgoCD API calls"
  echo "  - CI/CD pipelines"
  echo "  - Automation scripts"
  echo ""
}

# Start port-forward
port_forward() {
  echo -e "${BLUE}Starting port-forward to ArgoCD server...${NC}"
  check_kubeconfig
  check_argocd_installed
  
  LOCAL_PORT="${1:-8080}"
  
  echo -e "${GREEN}✓ Port-forward started${NC}"
  echo ""
  echo -e "  ${BLUE}Local Port:${NC}   $LOCAL_PORT"
  echo -e "  ${BLUE}Remote Port:${NC}  443"
  echo -e "  ${BLUE}Service:${NC}      argocd-server"
  echo ""
  echo -e "${YELLOW}Access ArgoCD:${NC}"
  echo -e "  ${BLUE}https://localhost:$LOCAL_PORT${NC}"
  echo ""
  echo -e "${YELLOW}To get credentials:${NC}"
  echo -e "  ${BLUE}./scripts/argocd-helper.sh get-password${NC}"
  echo ""
  echo -e "${YELLOW}Press Ctrl+C to stop port-forward${NC}"
  echo ""
  
  kubectl port-forward -n "$ARGOCD_NAMESPACE" svc/argocd-server "$LOCAL_PORT:443"
}

# Login to ArgoCD
login() {
  echo -e "${BLUE}Logging in to ArgoCD...${NC}"
  check_kubeconfig
  check_argocd_installed
  
  if ! command -v argocd &> /dev/null; then
    echo -e "${RED}❌ ArgoCD CLI is required${NC}"
    echo -e "${YELLOW}Please run: ./scripts/argocd-helper.sh install-cli${NC}"
    exit 1
  fi
  
  # Get password
  PASSWORD=$(kubectl -n "$ARGOCD_NAMESPACE" get secret argocd-initial-admin-secret \
    -o jsonpath="{.data.password}" 2>/dev/null | base64 -d)
  
  ARGOCD_SERVER="localhost:8080"
  
  echo -e "${YELLOW}Starting port-forward...${NC}"
  kubectl port-forward -n "$ARGOCD_NAMESPACE" svc/argocd-server 8080:443 &
  PF_PID=$!
  sleep 2
  
  echo -e "${YELLOW}Logging in...${NC}"
  argocd login "$ARGOCD_SERVER" --username admin --password "$PASSWORD" --insecure --grpc-web
  
  kill $PF_PID 2>/dev/null || true
  
  echo -e "${GREEN}✓ Logged in successfully${NC}"
}

# List ArgoCD applications
list_apps() {
  echo -e "${BLUE}Listing ArgoCD applications...${NC}"
  check_kubeconfig
  check_argocd_installed
  
  kubectl get applications -n "$ARGOCD_NAMESPACE" -o wide
}

# Get application details
get_app() {
  APP_NAME="$1"
  
  if [ -z "$APP_NAME" ]; then
    echo -e "${RED}❌ Application name required${NC}"
    echo "Usage: ./scripts/argocd-helper.sh get-app <app-name>"
    exit 1
  fi
  
  echo -e "${BLUE}Getting application details for: $APP_NAME${NC}"
  check_kubeconfig
  check_argocd_installed
  
  kubectl get application "$APP_NAME" -n "$ARGOCD_NAMESPACE" -o yaml
}

# Create a new ArgoCD user
create_user() {
  USERNAME="$1"
  
  if [ -z "$USERNAME" ]; then
    echo -e "${RED}❌ Username required${NC}"
    echo "Usage: ./scripts/argocd-helper.sh create-user <username>"
    exit 1
  fi
  
  echo -e "${BLUE}Creating ArgoCD user: $USERNAME${NC}"
  check_kubeconfig
  check_argocd_installed
  
  if ! command -v argocd &> /dev/null; then
    echo -e "${RED}❌ ArgoCD CLI is required${NC}"
    echo -e "${YELLOW}Please run: ./scripts/argocd-helper.sh install-cli${NC}"
    exit 1
  fi
  
  # Start port-forward
  kubectl port-forward -n "$ARGOCD_NAMESPACE" svc/argocd-server 8080:443 &
  PF_PID=$!
  sleep 2
  
  # Create user
  argocd account create "$USERNAME" --insecure --grpc-web --server localhost:8080 || true
  
  # Generate password
  TEMP_PASSWORD=$(openssl rand -base64 12)
  argocd account update-password --account "$USERNAME" --new-password "$TEMP_PASSWORD" \
    --insecure --grpc-web --server localhost:8080 || true
  
  kill $PF_PID 2>/dev/null || true
  
  echo ""
  echo -e "${GREEN}✓ User created successfully${NC}"
  echo -e "  ${BLUE}Username:${NC} $USERNAME"
  echo -e "  ${BLUE}Temporary Password:${NC} $TEMP_PASSWORD"
  echo ""
  echo -e "${YELLOW}User must change password on first login${NC}"
}

# Delete an ArgoCD user
delete_user() {
  USERNAME="$1"
  
  if [ -z "$USERNAME" ]; then
    echo -e "${RED}❌ Username required${NC}"
    echo "Usage: ./scripts/argocd-helper.sh delete-user <username>"
    exit 1
  fi
  
  echo -e "${YELLOW}Deleting ArgoCD user: $USERNAME${NC}"
  check_kubeconfig
  check_argocd_installed
  
  # Confirm deletion
  read -p "Are you sure? (y/N) " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Cancelled${NC}"
    exit 0
  fi
  
  if ! command -v argocd &> /dev/null; then
    echo -e "${RED}❌ ArgoCD CLI is required${NC}"
    echo -e "${YELLOW}Please run: ./scripts/argocd-helper.sh install-cli${NC}"
    exit 1
  fi
  
  # Start port-forward
  kubectl port-forward -n "$ARGOCD_NAMESPACE" svc/argocd-server 8080:443 &
  PF_PID=$!
  sleep 2
  
  # Delete user
  argocd account delete "$USERNAME" --insecure --grpc-web --server localhost:8080 || true
  
  kill $PF_PID 2>/dev/null || true
  
  echo -e "${GREEN}✓ User deleted${NC}"
}

# Change admin password
change_password() {
  echo -e "${BLUE}Changing ArgoCD admin password${NC}"
  check_kubeconfig
  check_argocd_installed
  
  if ! command -v argocd &> /dev/null; then
    echo -e "${RED}❌ ArgoCD CLI is required${NC}"
    echo -e "${YELLOW}Please run: ./scripts/argocd-helper.sh install-cli${NC}"
    exit 1
  fi
  
  # Get current password
  CURRENT_PASSWORD=$(kubectl -n "$ARGOCD_NAMESPACE" get secret argocd-initial-admin-secret \
    -o jsonpath="{.data.password}" 2>/dev/null | base64 -d)
  
  # Start port-forward
  kubectl port-forward -n "$ARGOCD_NAMESPACE" svc/argocd-server 8080:443 &
  PF_PID=$!
  sleep 2
  
  # Change password
  read -s -p "Enter new password: " NEW_PASSWORD
  echo
  read -s -p "Confirm password: " NEW_PASSWORD_CONFIRM
  echo
  
  if [ "$NEW_PASSWORD" != "$NEW_PASSWORD_CONFIRM" ]; then
    echo -e "${RED}❌ Passwords do not match${NC}"
    kill $PF_PID 2>/dev/null || true
    exit 1
  fi
  
  argocd account update-password --account admin --current-password "$CURRENT_PASSWORD" \
    --new-password "$NEW_PASSWORD" --insecure --grpc-web --server localhost:8080
  
  kill $PF_PID 2>/dev/null || true
  
  echo -e "${GREEN}✓ Password changed successfully${NC}"
}

# Export ArgoCD configuration
export_config() {
  echo -e "${BLUE}Exporting ArgoCD configuration...${NC}"
  check_kubeconfig
  check_argocd_installed
  
  EXPORT_DIR="$REPO_DIR/argocd/backups/$(date +%Y%m%d_%H%M%S)"
  mkdir -p "$EXPORT_DIR"
  
  echo "Exporting ConfigMaps..."
  kubectl get configmap -n "$ARGOCD_NAMESPACE" -o yaml > "$EXPORT_DIR/configmaps.yaml"
  
  echo "Exporting Secrets..."
  kubectl get secret -n "$ARGOCD_NAMESPACE" -o yaml > "$EXPORT_DIR/secrets.yaml"
  
  echo "Exporting Applications..."
  kubectl get applications -n "$ARGOCD_NAMESPACE" -o yaml > "$EXPORT_DIR/applications.yaml"
  
  echo "Exporting RBAC..."
  kubectl get rolebinding -n "$ARGOCD_NAMESPACE" -o yaml > "$EXPORT_DIR/rolebindings.yaml"
  
  echo -e "${GREEN}✓ Configuration exported${NC}"
  echo -e "  ${BLUE}Location: $EXPORT_DIR${NC}"
  ls -la "$EXPORT_DIR"
}

# Check ArgoCD health
health() {
  echo -e "${BLUE}Checking ArgoCD health...${NC}"
  check_kubeconfig
  check_argocd_installed
  
  echo ""
  echo -e "${BLUE}ArgoCD Server Status:${NC}"
  kubectl get deployment argocd-server -n "$ARGOCD_NAMESPACE" -o wide
  
  echo ""
  echo -e "${BLUE}ArgoCD Repo Server Status:${NC}"
  kubectl get deployment argocd-repo-server -n "$ARGOCD_NAMESPACE" -o wide
  
  echo ""
  echo -e "${BLUE}ArgoCD Controller Status:${NC}"
  kubectl get deployment argocd-application-controller -n "$ARGOCD_NAMESPACE" -o wide
  
  echo ""
  echo -e "${BLUE}ArgoCD Pods:${NC}"
  kubectl get pods -n "$ARGOCD_NAMESPACE"
  
  echo ""
  echo -e "${BLUE}ArgoCD Services:${NC}"
  kubectl get svc -n "$ARGOCD_NAMESPACE"
}

# Main script logic
COMMAND="${1:-help}"

case "$COMMAND" in
  install-cli)
    install_cli
    ;;
  get-password)
    get_password
    ;;
  get-token)
    get_token
    ;;
  port-forward)
    port_forward "${2:-8080}"
    ;;
  login)
    login
    ;;
  list-apps)
    list_apps
    ;;
  get-app)
    get_app "$2"
    ;;
  create-user)
    create_user "$2"
    ;;
  delete-user)
    delete_user "$2"
    ;;
  change-password)
    change_password
    ;;
  export-config)
    export_config
    ;;
  health)
    health
    ;;
  help)
    usage
    ;;
  *)
    echo -e "${RED}Unknown command: $COMMAND${NC}"
    echo ""
    usage
    exit 1
    ;;
esac
