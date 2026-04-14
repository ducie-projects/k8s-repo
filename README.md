# Kubernetes Local Development Environment

A local Kubernetes cluster setup using Kind with organized project structure.

## Table of Contents

- [Quick Start](#quick-start)
- [Setup Scripts](#setup-scripts)
- [ArgoCD](#argocd)
- [Configuration](#configuration)
- [Documentation](#documentation)
- [Ports Reference](#ports-reference)

## Structure

```
k8s-repo/
├── cluster/           # Kind cluster configuration and kubeconfig
│   ├── config/
│   │   └── kind-cluster.yaml
│   └── kubeconfig
├── argocd/            # ArgoCD GitOps configuration
│   ├── install/       # ArgoCD installation manifests
│   ├── applications/  # ArgoCD Applications
│   └── config/        # ArgoCD configuration
├── manifests/         # Kubernetes resources
│   ├── deployments/
│   ├── services/
│   └── configmaps/
├── projects/          # Application projects
└── scripts/           # Automation scripts
```

## Quick Start

```bash
# Create cluster
kind create cluster --config ./cluster/config/kind-cluster.yaml --kubeconfig ./cluster/kubeconfig

# Set kubeconfig
export KUBECONFIG=$(pwd)/cluster/kubeconfig

# Verify cluster
kubectl cluster-info
kubectl get nodes
```

## Setup Scripts

### 1. Create Cluster

```bash
./scripts/setup.sh
```

This creates a local Kind cluster with kubeconfig saved to `cluster/kubeconfig`.

### 2. Install ArgoCD

```bash
./scripts/install-argocd.sh
```

This installs ArgoCD in the cluster and displays access instructions.

## ArgoCD

This repository is configured for GitOps-based deployments using ArgoCD.

- **Install**: See `./scripts/install-argocd.sh`
- **Configuration**: See `./argocd/README.md`
- **Applications**: Define in `argocd/applications/`

Access ArgoCD UI after installation:
```bash
kubectl port-forward -n argocd svc/argocd-server 8080:443
```

Then visit: `https://localhost:8080`

## Configuration

- **Cluster Name**: my-cluster
- **Nodes**: 1 control-plane + 2 workers
- **Kubeconfig**: `./cluster/kubeconfig`
- **GitOps Tool**: ArgoCD

## Documentation

- **[QUICKSTART.md](QUICKSTART.md)** — Get started in minutes
- **[PORTS.md](PORTS.md)** — Complete ports reference and networking guide
- **[argocd/README.md](argocd/README.md)** — ArgoCD configuration details
- **[argocd/applications/README.md](argocd/applications/README.md)** — Application definitions

## Ports Reference

### Quick Port Summary

| Service | Local Port | Remote Port | Namespace | URL |
|---------|-----------|------------|-----------|-----|
| ArgoCD UI | 8080 | 443 | argocd | https://localhost:8080 |
| Web App | 8081 | 80 | production | http://localhost:8081 |
| API Service | 3000 | 3000 | production | http://localhost:3000 |

### Common Port-Forward Commands

```bash
# ArgoCD Web UI
kubectl port-forward -n argocd svc/argocd-server 8080:443

# Web App
kubectl port-forward -n production svc/web-app 8081:80

# API Service
kubectl port-forward -n production svc/api-service 3000:3000
```

**For complete port reference and networking details, see [PORTS.md](PORTS.md)**
