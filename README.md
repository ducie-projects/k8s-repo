# Kubernetes Local Development Environment

A local Kubernetes cluster setup using Kind with organized project structure.

## Structure

```
k8s-repo/
├── cluster/           # Kind cluster configuration and kubeconfig
│   ├── config/
│   │   └── kind-cluster.yaml
│   └── kubeconfig
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

## Configuration

- **Cluster Name**: my-cluster
- **Nodes**: 1 control-plane + 2 workers
- **Kubeconfig**: `./cluster/kubeconfig`
