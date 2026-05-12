---
name: argocd-gitops
description: "Add and manage ArgoCD Applications in the k3-applications GitOps repo (Helm charts, kustomize, operators)."
---

# ArgoCD GitOps Applications

Patterns for adding services, operators, and Helm charts to the `scientist-hq/k3-applications` GitOps repository. ArgoCD syncs from this repo to the k3s cluster automatically.

## When to Use

- Adding a new service/operator to the cluster
- Updating Helm chart versions or values
- Creating new ArgoCD Projects for access control
- Debugging sync failures

## Repository Structure

```
k3-applications/
├── projects/
│   ├── kustomization.yaml        # Lists all project YAMLs
│   └── <name>-project.yaml       # One per logical group
├── applications/
│   ├── kustomization.yaml        # Lists all application dirs
│   └── <name>/
│       ├── kustomization.yaml    # Lists YAML files in this dir
│       └── <name>-application.yaml
└── README.md
```

## Adding a New Application

### 1. Create the AppProject (access control boundary)

`projects/<name>-project.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: <project-name>
  namespace: argo
spec:
  description: <Human-readable description>
  sourceRepos:
    - <helm-repo-url>
  destinations:
    - namespace: <target-namespace>
      server: https://kubernetes.default.svc
  clusterResourceWhitelist:
    - group: "rbac.authorization.k8s.io"
      kind: "*"
    - group: "apiextensions.k8s.io"
      kind: "*"
    - group: "admissionregistration.k8s.io"
      kind: "*"
```

Add to `projects/kustomization.yaml` (alphabetical order).

### 2. Create the Application

`applications/<name>/<name>-application.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: <release-name>
  namespace: argo
spec:
  project: <project-name>
  syncPolicy:
    automated:
      prune: true
    syncOptions:
      - CreateNamespace=true
      - ServerSideApply=true
  source:
    repoURL: <helm-repo-url>
    targetRevision: <chart-version>
    chart: <chart-name>
    helm:
      releaseName: <release-name>
      valuesObject:
        # Only override non-default values
        key: value
  destination:
    server: https://kubernetes.default.svc
    namespace: <target-namespace>
```

Add `<name>/` to `applications/kustomization.yaml` (alphabetical order).

Create `applications/<name>/kustomization.yaml`:
```yaml
resources:
  - <name>-application.yaml
```

### 3. Commit and PR

```bash
git checkout -b add-<name>
git add -A
git commit -m "Add <Name> <description>"
git push -u origin HEAD
gh pr create --title "Add <Name>" --body "..."
```

## Verification

After merging, check ArgoCD:

```bash
# Check sync status
kubectl get applications -n argo <app-name> -o jsonpath='{.status.sync.status}'
# Check health
kubectl get applications -n argo <app-name> -o jsonpath='{.status.health.status}'
```

## Common Helm Repos

| Operator/Chart | Repo URL |
|---|---|
| Tailscale operator | `https://pkgs.tailscale.com/helmcharts` |
| External Secrets | `https://charts.external-secrets.io` |
| Ingress NGINX | `https://kubernetes.github.io/ingress-nginx` |
| Envoy Gateway | `https://charts.gateway.envoyproxy.io` |
| Kubecost | `https://kubecost.github.io/cost-analyzer/` |

## Pitfalls

- **clusterResourceWhitelist**: Be specific — don't use `"*"/"*"` unless necessary. Check what CRDs/ClusterRoles the chart installs.
- **ServerSideApply**: Use for charts with large CRDs or webhook configs to avoid annotation size limits.
- **CreateNamespace=true**: Required if the namespace doesn't exist yet; the AppProject must also allow that namespace.
- **sourceRepos in AppProject**: Must exactly match the `repoURL` in the Application. If the app also references the k3-applications repo itself (for raw manifests), add `https://github.com/scientist-hq/k3-applications.git` too.
- **Secrets/credentials**: Never hardcode secrets in the repo. Use ExternalSecrets, sealed-secrets, or placeholder values with a note in the PR body.
- **Chart version**: Always pin to a specific version (`targetRevision`), not `*` or a branch.
