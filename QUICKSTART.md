# Quick Start Guide

Get your Kubernetes cluster with ArgoCD up and running in minutes!

## Prerequisites

- [Kind](https://kind.sigs.k8s.io/docs/user/quick-start/) installed
- [kubectl](https://kubernetes.io/docs/tasks/tools/) installed
- Docker running

## Installation

### Option 1: Automatic Setup (Recommended)

Run the initialization script to set up everything automatically:

```bash
cd ~/Desktop/k8s-repo
./scripts/init.sh
```

This will:
✓ Create a local Kubernetes cluster with Kind  
✓ Install ArgoCD  
✓ Apply all configurations  
✓ Deploy sample applications  
✓ Display access credentials  

### Option 2: Manual Setup

If you prefer manual setup:

```bash
# 1. Create cluster
./scripts/setup.sh

# 2. Install ArgoCD
./scripts/install-argocd.sh

# 3. Apply configurations
kubectl apply -f argocd/config/argocd-rbac-cm.yaml
kubectl apply -f argocd/config/argocd-cm.yaml
kubectl apply -f argocd/config/argocd-accounts.yaml

# 4. Deploy applications
kubectl apply -f argocd/applications/web-app.yaml
kubectl apply -f argocd/applications/api-service.yaml
```

## Access ArgoCD

After initialization:

```bash
# Set kubeconfig
export KUBECONFIG=$(pwd)/cluster/kubeconfig

# Port-forward to ArgoCD
kubectl port-forward -n argocd svc/argocd-server 8080:443 &

# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

Then visit: **https://localhost:8080**

- **Username**: `admin`
- **Password**: (from command above)

## What's Included

### Cluster
- 1 control-plane node
- 2 worker nodes
- Local kubeconfig in `cluster/kubeconfig`

### ArgoCD
- Full GitOps deployment platform
- RBAC configuration (admin, developer, viewer roles)
- Notification system ready
- Multiple application definitions

### Applications
- **web-app**: Sample web application
- **api-service**: Sample API service
- Each with separate values configuration

## Project Structure

```
k8s-repo/
├── cluster/              # Cluster config & kubeconfig
├── argocd/              # ArgoCD setup & config
│   ├── install/         # Installation manifests
│   ├── applications/    # App definitions & values
│   └── config/          # ArgoCD configuration
├── manifests/           # Kubernetes resources
├── scripts/             # Automation scripts
│   ├── init.sh         # Full initialization
│   ├── setup.sh        # Cluster setup
│   └── install-argocd.sh
└── README.md
```

## Troubleshooting

### ArgoCD not starting?
```bash
kubectl logs -n argocd deployment/argocd-server
```

### Port-forward not working?
```bash
# Kill existing port-forwards
killall kubectl

# Try again
kubectl port-forward -n argocd svc/argocd-server 8080:443
```

### Reset everything?
```bash
kind delete cluster --name my-cluster
rm cluster/kubeconfig
./scripts/init.sh
```

## Next Steps

1. Modify `argocd/applications/values/` to customize your applications
2. Create new Applications in `argocd/applications/`
3. Update manifest files in `manifests/`
4. Push to GitHub and ArgoCD will sync automatically

## Documentation

- [Kind Docs](https://kind.sigs.k8s.io/)
- [ArgoCD Docs](https://argo-cd.readthedocs.io/)
- [Kubernetes Docs](https://kubernetes.io/docs/)

## Support

For issues or questions, check the README files in each directory.
