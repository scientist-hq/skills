---
name: condominium-database
description: "Add a new Postgres database + role on the shared condominium RDS instance, with the K8s secret pushed into the consuming namespace. Covers the two gotchas that bite first-time adds (RBAC whitelist + namespace ordering)."
---

# Condominium Database

The shared production Postgres instance `condominium` (`db.t3.xlarge`, 17.4, eu-central-1) lives in `scientist-hq/infra/terraform/rds/condominium.tf`. Most non-RX apps in the cluster share it: n8n, benchmate, langflow, librechat, keycloak, backstage, grafana, etc. New AI/internal-tool workloads should default to adding a database here rather than provisioning a new RDS instance.

## When to use this skill

- You're adding a service to the k3 cluster that needs Postgres
- The data volume is small-to-medium (~GBs, not TBs) and isolation is logical (its own database + role) rather than instance-level
- You're not running an analytics workload that needs its own large instance

For analytics / dbt / large workloads, use `rx-production-aurora` patterns instead.

## What you're adding (four resources + one whitelist line)

In `scientist-hq/infra/terraform/rds/condominium.tf`, append a block following the `sci_<service>_production` pattern. Look at the existing `sci_n8n_production` or `sci_benchmate_production` blocks for current style — copy one verbatim and rename:

```hcl
# ############################################################################
# sci_<service>_production
# ############################################################################

resource "postgresql_role" "condominium-sci_<service>_production" {
  provider = postgresql.condominium-admin

  name     = "sci_<service>_production"
  password = random_password.condominium-sci_<service>_production.result

  login               = true
  encrypted_password  = true
  skip_reassign_owned = true
  skip_drop_role      = true

  lifecycle { prevent_destroy = true }

  depends_on = [aws_db_instance.condominium]
}

resource "random_password" "condominium-sci_<service>_production" {
  length  = 24
  special = false
}

resource "postgresql_database" "condominium-sci_<service>_production" {
  provider = postgresql.condominium-admin

  name  = "sci_<service>_production"
  owner = postgresql_role.condominium-sci_<service>_production.name

  lifecycle { prevent_destroy = true }

  depends_on = [postgresql_role.condominium-sci_<service>_production]
}

resource "kubernetes_secret" "condominium-sci_<service>_production" {
  metadata {
    name      = "<service>-postgres-direct-secret"
    namespace = "<service>"
  }
  data = {
    POSTGRES_DB       = postgresql_database.condominium-sci_<service>_production.name
    POSTGRES_HOST     = aws_db_instance.condominium.address
    POSTGRES_PASSWORD = random_password.condominium-sci_<service>_production.result
    POSTGRES_PORT     = tostring(aws_db_instance.condominium.port)
    POSTGRES_URL      = "postgres://${postgresql_role.condominium-sci_<service>_production.name}:${random_password.condominium-sci_<service>_production.result}@${aws_db_instance.condominium.address}:${aws_db_instance.condominium.port}/${postgresql_database.condominium-sci_<service>_production.name}"
    POSTGRES_USER     = postgresql_role.condominium-sci_<service>_production.name
  }
}
```

If the service needs extensions (`pgvector`, `pgcrypto`, `uuid-ossp`), add `postgresql_extension` resources after the database — see `sci_benchmate_production` for the pattern.

## CRITICAL: also add the secret name to the RBAC whitelist

This is the step that gets forgotten and breaks the apply. Edit `terraform/k3/kube-system/roles/gha-rds-rbac.yaml` and add your new secret name to the `gha-rds-secrets` ClusterRole's `resourceNames` list:

```yaml
rules:
- apiGroups: [""]
  resources: ["secrets"]
  resourceNames:
  - rx-postgres-direct-secret
  - benchmate-postgres-direct-secret
  - ...
  - <service>-postgres-direct-secret   # <-- add this line
  verbs: ["get", "update", "delete", "patch"]
```

**Why this matters:** the `create` verb in the ClusterRole is unrestricted (no `resourceNames`), but `get/update/delete/patch` is whitelisted. Terraform's `kubernetes_secret` resource creates *then immediately reads back* the secret to capture computed fields. If your secret name isn't whitelisted, the create succeeds (orphan secret lands in cluster) but the read fails with:

```
secrets "<your-secret>" is forbidden: User "gha-rds" cannot get resource "secrets" in API group "" in the namespace "<your-ns>"
```

Terraform then reports failure, the resource is missing from state, and you're in a half-applied limbo.

Both files (`condominium.tf` and `gha-rds-rbac.yaml`) belong in the **same PR** so the two applies stay in sync.

## CRITICAL: the target namespace must exist *before* terraform apply

`kubernetes_secret` does not create namespaces — it can only push secrets into existing ones. If the namespace doesn't exist when the `Terraform: rds` workflow runs, the apply will fail with a not-found error.

You have two ways to handle the ordering:

- **Preferred:** open the k3-applications PR first (the one that adds your service's ArgoCD `Application` with `CreateNamespace=true`). Let ArgoCD create the namespace. Then merge the infra PR — terraform finds the namespace ready and pushes the secret.
- **Acceptable:** `kubectl create namespace <service>` manually before merging the infra PR. The ArgoCD Application will adopt the existing namespace later.

Putting the infra PR *first* with no namespace strategy means the apply fails and you have to redo it.

## Apply order

The `Terraform: rds` GitHub Actions workflow runs on merge to main. It applies all of `terraform/rds/`. The `Terraform: k3` workflow applies the RBAC YAML and is generally faster.

If both PRs (infra + k3-applications) merge close together, occasionally the `Terraform: rds` workflow can race the `Terraform: k3` apply. Recovery if that happens:

```bash
# 1. Confirm the RBAC update has landed
kubectl auth can-i get secrets/<service>-postgres-direct-secret -n <service> --as=gha-rds   # → yes

# 2. Delete the orphan secret (no consumer yet)
kubectl -n <service> delete secret <service>-postgres-direct-secret

# 3. Re-run the rds workflow
gh workflow run "Terraform: rds" --ref main
```

After the second apply, Terraform state contains the secret resource and reality matches.

## Consuming the secret from a Helm chart

Most charts in `k3-applications` source the connection from `valueFrom.secretKeyRef`. Example (LangFlow shape):

```yaml
backend:
  externalDatabase:
    enabled: true
    driver: postgresql
    host:
      valueFrom:
        secretKeyRef: { name: <service>-postgres-direct-secret, key: POSTGRES_HOST }
    port:
      valueFrom:
        secretKeyRef: { name: <service>-postgres-direct-secret, key: POSTGRES_PORT }
    user:
      valueFrom:
        secretKeyRef: { name: <service>-postgres-direct-secret, key: POSTGRES_USER }
    password:
      valueFrom:
        secretKeyRef: { name: <service>-postgres-direct-secret, key: POSTGRES_PASSWORD }
    database:
      valueFrom:
        secretKeyRef: { name: <service>-postgres-direct-secret, key: POSTGRES_DB }
```

Some charts want a single `DATABASE_URL` — use the `POSTGRES_URL` key instead.

## Verification

After both applies are green:

```bash
# Secret has all six keys
kubectl -n <service> get secret <service>-postgres-direct-secret \
  -o jsonpath='{.data}' | jq 'keys'
# → ["POSTGRES_DB","POSTGRES_HOST","POSTGRES_PASSWORD","POSTGRES_PORT","POSTGRES_URL","POSTGRES_USER"]

# RBAC reads back cleanly (the thing that breaks if you forget the whitelist)
kubectl auth can-i get secrets/<service>-postgres-direct-secret -n <service> --as=gha-rds
# → yes

# Database exists and is owned by the new role
PGPASSWORD=<admin-pw> psql -h condominium-rds-endpoint -U <admin> -c "\l" | grep sci_<service>
```

## Naming conventions

- Postgres database & role name: `sci_<service>_production` (snake_case, ASCII only — pgsql is strict)
- K8s secret name: `<service>-postgres-direct-secret` (kebab-case)
- TF resource suffix: `condominium-sci_<service>_production`
- Namespace: typically the same as `<service>`

Keep these three names aligned across all of `condominium.tf`, `gha-rds-rbac.yaml`, and the consuming Application yaml — drift here is the #2 cause of apply failures after the RBAC trap.

## Real-world examples in the repo

- **n8n** — `sci_n8n_production` (control-plane DB) + `sci_n8n_workflows_production` (workflow scratch DB) — pattern for a service that wants two databases
- **benchmate** — `sci_benchmate_production` with pgvector + pgcrypto extensions
- **litellm** — `sci_litellm_production` (vanilla, no extensions, recent example following exactly this skill)
- **keycloak** — `sci_keycloak_production`

Copy whichever is closest to your shape.
