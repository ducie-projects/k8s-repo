# ArgoCD Configuration

This directory contains ArgoCD installation and application configuration for GitOps-based continuous delivery.

## Structure

```
argocd/
├── install/           # ArgoCD installation manifests
│   ├── namespace.yaml
│   └── kustomization.yaml
├── applications/      # ArgoCD Application definitions
│   └── example-app.yaml
├── config/            # ArgoCD configuration
│   └── argocd-cm.yaml
└── README.md
```

## Installation

```bash
./scripts/install-argocd.sh
```

## Access ArgoCD UI

```bash
# Port-forward to ArgoCD server
kubectl port-forward -n argocd svc/argocd-server 8080:443

# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

Then visit: `https://localhost:8080`

**Username**: `admin`
**Password**: (from command above)

## Creating Applications

Create new `Application` manifests in the `applications/` directory following the pattern in `example-app.yaml`.

Each Application syncs resources from a Git repository to your cluster, enabling full GitOps workflows.

## Documentation

- [ArgoCD Official Docs](https://argo-cd.readthedocs.io/)
- [Application Spec](https://argo-cd.readthedocs.io/en/stable/operator-manual/declarative-setup/)
