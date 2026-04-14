# ArgoCD Applications

This directory contains ArgoCD Application definitions with separated configuration values.

## Structure

```
applications/
├── base/
│   ├── application.yaml      # Base template for applications
│   └── kustomization.yaml
├── values/
│   ├── web-app-values.yaml   # Values for web-app
│   └── api-service-values.yaml
├── web-app.yaml              # Web App Application
├── api-service.yaml          # API Service Application
└── README.md
```

## How It Works

1. **Base Template** (`base/application.yaml`)
   - Generic Application template that all apps inherit from
   - Contains common sync policies and settings

2. **Values Files** (`values/`)
   - Store application-specific configuration
   - Image names, replicas, resources, environment variables
   - One values file per application

3. **Application Definitions** (`*.yaml`)
   - Individual Application resources
   - Reference the values from `values/` directory
   - Define namespace and other app-specific settings

## Creating a New Application

1. Create a new values file in `values/`:
   ```yaml
   # values/my-app-values.yaml
   app:
     name: my-app
     namespace: production
   image:
     repository: myregistry/my-app
     tag: v1.0.0
   replicas: 2
   ```

2. Create a new Application definition:
   ```yaml
   # my-app.yaml
   apiVersion: argoproj.io/v1alpha1
   kind: Application
   metadata:
     name: my-app
     namespace: argocd
   spec:
     project: default
     source:
       repoURL: https://github.com/ducie-projects/k8s-repo
       targetRevision: HEAD
       path: manifests/
     destination:
       server: https://kubernetes.default.svc
       namespace: production
     syncPolicy:
       automated:
         prune: false
         selfHeal: false
       syncOptions:
         - CreateNamespace=true
   ```

3. ArgoCD will sync the application based on the manifests in `manifests/` and apply the values configuration.

## Values Reference

Each values file should contain:
- **app**: Application name and namespace
- **image**: Container image details
- **replicas**: Number of replicas
- **service**: Service configuration
- **resources**: CPU/Memory requests and limits
- **env**: Environment variables

## Applying Applications

```bash
# Apply all applications
kubectl apply -f argocd/applications/*.yaml -n argocd

# Or use ArgoCD CLI
argocd app create web-app --repo https://github.com/ducie-projects/k8s-repo --path argocd/applications --dest-server https://kubernetes.default.svc --dest-namespace production
```
