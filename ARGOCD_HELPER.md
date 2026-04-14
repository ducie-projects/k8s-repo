# ArgoCD Helper Script

Comprehensive helper script for managing ArgoCD operations and administration.

## Overview

The `argocd-helper.sh` script provides convenient commands for:
- Installing ArgoCD CLI
- Managing credentials and authentication
- Creating and managing user accounts
- Port forwarding and access
- Monitoring ArgoCD health
- Exporting configurations

## Usage

```bash
./scripts/argocd-helper.sh <command> [options]
```

## Commands

### Installation & Setup

#### `install-cli`
Install the ArgoCD command-line tool.

```bash
./scripts/argocd-helper.sh install-cli
```

**Features:**
- Auto-detects OS (macOS/Linux)
- Uses Homebrew on macOS if available
- Downloads from GitHub releases
- Adds to system PATH

#### `port-forward`
Start port-forward to ArgoCD server.

```bash
./scripts/argocd-helper.sh port-forward [local-port]
```

**Examples:**
```bash
# Default port 8080
./scripts/argocd-helper.sh port-forward

# Custom port
./scripts/argocd-helper.sh port-forward 9000
```

**Output:**
- Shows connection details
- Provides access URL
- Awaits Ctrl+C to stop

---

### Authentication & Credentials

#### `get-password`
Retrieve ArgoCD admin password from Kubernetes secret.

```bash
./scripts/argocd-helper.sh get-password
```

**Output:**
```
✓ ArgoCD Credentials:
  Username: admin
  Password: xxxxxxxxxxxx
```

**Use Case:**
- Initial setup
- Getting credentials after fresh installation

#### `get-token`
Generate ArgoCD API token for programmatic access.

```bash
./scripts/argocd-helper.sh get-token
```

**Output:**
```
✓ ArgoCD API Token:
  eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Use Case:**
- CI/CD integration
- API automation
- External tool authentication

#### `login`
Interactively login to ArgoCD using CLI.

```bash
./scripts/argocd-helper.sh login
```

**Features:**
- Automatic port-forward
- Automatic password retrieval
- Login to ArgoCD server
- CLI context setup

**Use Case:**
- One-time setup for argocd CLI
- Enabling local CLI commands

#### `change-password`
Change ArgoCD admin password.

```bash
./scripts/argocd-helper.sh change-password
```

**Prompts:**
- Current password (auto-filled if available)
- New password
- Password confirmation

**Use Case:**
- Security rotation
- Initial password change
- Account security

---

### User Management

#### `create-user`
Create a new ArgoCD user account.

```bash
./scripts/argocd-helper.sh create-user <username>
```

**Example:**
```bash
./scripts/argocd-helper.sh create-user developer
```

**Output:**
```
✓ User created successfully
  Username: developer
  Temporary Password: xxxxxxxxxxx

User must change password on first login
```

**Use Case:**
- Adding team members
- Creating CI/CD service accounts
- Multi-user setup

#### `delete-user`
Delete an ArgoCD user account.

```bash
./scripts/argocd-helper.sh delete-user <username>
```

**Example:**
```bash
./scripts/argocd-helper.sh delete-user developer
```

**Safety:**
- Requires confirmation (y/N)
- Cannot be undone

**Use Case:**
- Removing user access
- Cleaning up test accounts
- Offboarding team members

---

### Application Management

#### `list-apps`
List all ArgoCD applications.

```bash
./scripts/argocd-helper.sh list-apps
```

**Output:**
```
NAME          SYNC STATUS   HEALTH STATUS
web-app       Synced        Healthy
api-service   Synced        Healthy
```

**Use Case:**
- Quick status check
- CI/CD pipelines
- Monitoring

#### `get-app`
Get detailed information about an application.

```bash
./scripts/argocd-helper.sh get-app <app-name>
```

**Example:**
```bash
./scripts/argocd-helper.sh get-app web-app
```

**Output:**
- Full YAML configuration
- Status details
- Sync information

**Use Case:**
- Debugging
- Configuration review
- Audit purposes

---

### Monitoring & Health

#### `health`
Check ArgoCD health and status.

```bash
./scripts/argocd-helper.sh health
```

**Checks:**
- Server deployment status
- Repository server status
- Application controller status
- All pod status
- Service status

**Output:**
```
ArgoCD Server Status:
NAME                    READY   UP-TO-DATE   AVAILABLE
argocd-server           1/1     1            1

ArgoCD Repo Server Status:
NAME                      READY   UP-TO-DATE   AVAILABLE
argocd-repo-server        1/1     1            1

...
```

**Use Case:**
- Troubleshooting
- Health monitoring
- Status verification

---

### Configuration & Backup

#### `export-config`
Export ArgoCD configuration for backup.

```bash
./scripts/argocd-helper.sh export-config
```

**Exports:**
- ConfigMaps
- Secrets
- Applications
- RBAC configurations

**Output Location:**
```
argocd/backups/YYYYMMDD_HHMMSS/
├── configmaps.yaml
├── secrets.yaml
├── applications.yaml
└── rolebindings.yaml
```

**Use Case:**
- Disaster recovery
- Configuration backup
- Migration preparation

---

## Quick Start Examples

### Initial Setup
```bash
# 1. Install ArgoCD CLI
./scripts/argocd-helper.sh install-cli

# 2. Get credentials
./scripts/argocd-helper.sh get-password

# 3. Start port-forward
./scripts/argocd-helper.sh port-forward

# In another terminal:
# 4. Login
./scripts/argocd-helper.sh login
```

### Daily Operations
```bash
# Check health
./scripts/argocd-helper.sh health

# List applications
./scripts/argocd-helper.sh list-apps

# Check specific app
./scripts/argocd-helper.sh get-app web-app
```

### User Management
```bash
# Create developer account
./scripts/argocd-helper.sh create-user john

# Create CI/CD service account
./scripts/argocd-helper.sh create-user ci-bot

# Get API token for CI/CD
./scripts/argocd-helper.sh get-token
```

### Maintenance
```bash
# Export backup
./scripts/argocd-helper.sh export-config

# Change admin password
./scripts/argocd-helper.sh change-password

# Delete old user
./scripts/argocd-helper.sh delete-user temporary-user
```

---

## Integration Examples

### CI/CD Pipeline
```bash
#!/bin/bash

# Get token for automation
TOKEN=$(./scripts/argocd-helper.sh get-token 2>&1 | tail -1)

# Use token in API calls
curl -H "Authorization: Bearer $TOKEN" \
  https://argocd.example.com/api/v1/applications
```

### Monitoring Script
```bash
#!/bin/bash

# Monitor health
./scripts/argocd-helper.sh health

# Check application status
./scripts/argocd-helper.sh list-apps
```

### Backup Job
```bash
#!/bin/bash

# Daily backup
./scripts/argocd-helper.sh export-config

# Archive backups
tar -czf argocd-backup-$(date +%Y%m%d).tar.gz argocd/backups/
```

---

## Environment Variables

### Customization
```bash
# Custom ArgoCD namespace
export ARGOCD_NAMESPACE=custom-argocd

# Custom kubeconfig
export KUBECONFIG=/path/to/kubeconfig

./scripts/argocd-helper.sh get-password
```

---

## Troubleshooting

### CLI Not Found After Installation
```bash
# Add to PATH manually
export PATH="/usr/local/bin:$PATH"

# Or reinstall
./scripts/argocd-helper.sh install-cli
```

### Port-Forward Fails
```bash
# Check if port is in use
lsof -i :8080

# Kill existing process
kill -9 <PID>

# Try again with different port
./scripts/argocd-helper.sh port-forward 9000
```

### Password Retrieval Fails
```bash
# Check if secret exists
kubectl get secret -n argocd argocd-initial-admin-secret

# If not found, reset password
kubectl -n argocd set env deployment/argocd-server \
  ARGOCD_INITIAL_PASSWORD_HASH='' --overwrite
```

### Login Issues
```bash
# Verify ArgoCD is running
./scripts/argocd-helper.sh health

# Check pod logs
kubectl logs -n argocd deployment/argocd-server

# Restart if needed
kubectl rollout restart deployment/argocd-server -n argocd
```

---

## Related Scripts

- **[init.sh](scripts/init.sh)** — Full cluster initialization
- **[setup.sh](scripts/setup.sh)** — Cluster creation only
- **[install-argocd.sh](scripts/install-argocd.sh)** — ArgoCD installation

---

## Help

```bash
./scripts/argocd-helper.sh help
```

Shows all available commands and usage information.

---

**Last Updated**: 2026-04-14

For more information, see:
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [PORTS.md](PORTS.md) - Networking reference
- [QUICKSTART.md](QUICKSTART.md) - Getting started guide
