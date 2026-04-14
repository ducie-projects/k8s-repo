# Ports Reference

Complete reference of all ports used in the K8s repository cluster.

## Table of Contents

1. [ArgoCD Ports](#argocd-ports)
2. [Application Ports](#application-ports)
3. [Kubernetes Ports](#kubernetes-ports)
4. [Port Forwarding](#port-forwarding)
5. [Port Summary Table](#port-summary-table)

---

## ArgoCD Ports

### Default ArgoCD Service Ports

| Port | Protocol | Service | Type | Description |
|------|----------|---------|------|-------------|
| 443 | HTTPS | argocd-server | ClusterIP | ArgoCD Web UI & gRPC API (encrypted) |
| 80 | HTTP | argocd-server | ClusterIP | ArgoCD HTTP (redirects to HTTPS) |
| 8083 | TCP | argocd-metrics | ClusterIP | Prometheus metrics for ArgoCD |
| 8085 | TCP | argocd-dex-server | ClusterIP | Dex OIDC authentication server |
| 8088 | TCP | argocd-repo-server | ClusterIP | Repository server (internal) |
| 6379 | TCP | argocd-redis | ClusterIP | Redis cache (internal) |

### ArgoCD Local Access

```bash
# Access ArgoCD UI via port-forward
kubectl port-forward -n argocd svc/argocd-server 8080:443

# Then visit: https://localhost:8080
```

| Local Port | Remote Port | Service | Use Case |
|-----------|------------|---------|----------|
| 8080 | 443 | argocd-server | Web UI Access |

---

## Application Ports

### Web App

| Port | Protocol | Service | Type | Access |
|------|----------|---------|------|--------|
| 80 | HTTP | web-app | ClusterIP | Internal (Kubernetes) |
| 8080 | TCP | web-app | ClusterIP | Cluster internal |

**Local Access:**
```bash
kubectl port-forward -n production svc/web-app 8080:80
# Visit: http://localhost:8080
```

### API Service

| Port | Protocol | Service | Type | Access |
|------|----------|---------|------|--------|
| 3000 | TCP | api-service | ClusterIP | Internal (Kubernetes) |

**Local Access:**
```bash
kubectl port-forward -n production svc/api-service 3000:3000
# Visit: http://localhost:3000
```

---

## Kubernetes Ports

### Control Plane Ports

| Port | Protocol | Component | Description |
|------|----------|-----------|-------------|
| 6443 | TCP | API Server | Kubernetes API Server |
| 10250 | TCP | Kubelet | Kubelet API (node communications) |
| 10251 | TCP | Scheduler | Scheduler (internal) |
| 10252 | TCP | Controller Manager | Controller Manager (internal) |

### Node Ports

| Port | Protocol | Component | Description |
|------|----------|-----------|-------------|
| 10250 | TCP | Kubelet | Kubelet API |
| 10248 | TCP | Kubelet | Health endpoint |
| 30000-32767 | TCP/UDP | NodePort Services | Range for NodePort services |

### etcd Ports (Control Plane Only)

| Port | Protocol | Component | Description |
|------|----------|-----------|-------------|
| 2379 | TCP | etcd | Client API |
| 2380 | TCP | etcd | Peer communication |

---

## Port Forwarding

### Quick Reference Commands

```bash
# Set kubeconfig
export KUBECONFIG=$(pwd)/cluster/kubeconfig

# ArgoCD UI (most common)
kubectl port-forward -n argocd svc/argocd-server 8080:443

# Web App
kubectl port-forward -n production svc/web-app 8080:80

# API Service
kubectl port-forward -n production svc/api-service 3000:3000

# Multiple port-forwards in background
kubectl port-forward -n argocd svc/argocd-server 8080:443 &
kubectl port-forward -n production svc/web-app 8081:80 &
kubectl port-forward -n production svc/api-service 3000:3000 &

# Kill all port-forwards
killall kubectl
```

### Port Forwarding Template

```bash
kubectl port-forward -n <namespace> svc/<service-name> <local-port>:<service-port>
```

Parameters:
- `<namespace>`: Kubernetes namespace (e.g., argocd, production)
- `<service-name>`: Service name
- `<local-port>`: Port on your local machine
- `<service-port>`: Port exposed by the service

---

## Port Summary Table

### Complete Port Reference

| Local | Remote | Namespace | Service | Type | URL |
|-------|--------|-----------|---------|------|-----|
| 8080 | 443 | argocd | argocd-server | HTTPS | https://localhost:8080 |
| 8081 | 80 | production | web-app | HTTP | http://localhost:8081 |
| 3000 | 3000 | production | api-service | HTTP | http://localhost:3000 |
| 6443 | 6443 | - | kubernetes API | TCP | https://localhost:6443 |

---

## Port by Service Type

### ClusterIP Services (Internal Only)

These services are accessible **only within the cluster** unless port-forwarded.

```
- argocd-server:443
- argocd-metrics:8083
- argocd-dex-server:8085
- argocd-repo-server:8088
- argocd-redis:6379
- web-app:80
- api-service:3000
```

### NodePort Services (If Configured)

Currently: **None configured**

To expose a service externally:
```bash
kubectl patch svc <service-name> -p '{"spec":{"type":"NodePort"}}'
```

### LoadBalancer Services (If Configured)

Currently: **None configured**

---

## Network Policies

### Current Setup

- **Cluster Network**: Internal Docker bridge (kind)
- **External Access**: Port-forward only (development)
- **Namespace Isolation**: None (open cluster)

### Security Notes

⚠️ **Development Environment**

This is configured for local development. For production:

1. Use proper Ingress controllers
2. Configure Network Policies
3. Use TLS certificates
4. Implement authentication/authorization
5. Use LoadBalancer or NodePort with proper firewall rules

---

## Common Tasks

### Access ArgoCD

```bash
# Port-forward
kubectl port-forward -n argocd svc/argocd-server 8080:443 &

# Get password
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d

# Visit: https://localhost:8080
# Username: admin
# Password: (from command above)
```

### Access Application

```bash
# Web App
kubectl port-forward -n production svc/web-app 8080:80
# Visit: http://localhost:8080

# API Service
kubectl port-forward -n production svc/api-service 3000:3000
# Visit: http://localhost:3000
```

### List All Services and Ports

```bash
# All services
kubectl get svc -A

# Services in specific namespace
kubectl get svc -n argocd
kubectl get svc -n production

# Services with port details
kubectl get svc -A -o wide
```

### Check Port Usage on Local Machine

```bash
# macOS/Linux
lsof -i :8080

# List all listening ports
netstat -tuln | grep LISTEN
```

---

## Troubleshooting

### Port Already in Use

```bash
# Find what's using the port (macOS)
lsof -i :8080

# Find what's using the port (Linux)
netstat -tuln | grep 8080

# Kill the process
kill -9 <PID>
```

### Port-Forward Not Working

```bash
# Check if service exists
kubectl get svc -n argocd

# Check if pods are running
kubectl get pods -n argocd

# Check pod logs
kubectl logs -n argocd deployment/argocd-server

# Verify kubeconfig
echo $KUBECONFIG
```

### Connection Refused

```bash
# Verify port-forward is running
ps aux | grep port-forward

# Check if service is accessible
kubectl exec -it <pod> -n <namespace> -- curl localhost:<port>
```

---

## Reference Links

- [Kubernetes Networking](https://kubernetes.io/docs/concepts/services-networking/)
- [Port Forwarding](https://kubernetes.io/docs/tasks/access-application-cluster/port-forward-access-application-cluster/)
- [ArgoCD Installation](https://argo-cd.readthedocs.io/en/stable/operator-manual/installation/)
- [Service Types](https://kubernetes.io/docs/concepts/services-networking/service/#publishing-services-service-types)

---

**Last Updated**: 2026-04-14
