---
name: k3-irsa-role
description: "Grant a k3 workload access to AWS services (S3, RDS, Bedrock, Athena, etc.) via IRSA — IAM Roles for Service Accounts. Covers the role + policy + SA-annotation pattern, the Bedrock-specific policy template, and the known-broken integrations that need a static-key escape hatch."
---

# IRSA Roles for k3 Workloads

The k3 cluster uses **IRSA** (IAM Roles for Service Accounts) to grant pods AWS access without static credentials. Every workload that talks to AWS — RX, n8n, embeddings, LiteLLM, Velero, the load-balancer controller, all of it — uses this pattern. New workloads should default to IRSA unless they hit one of the known broken paths documented at the end of this skill.

## How IRSA works (one-paragraph refresher)

EKS publishes an OIDC provider that AWS STS trusts. When a pod with a service account that's annotated with `eks.amazonaws.com/role-arn` runs, kubelet projects a JWT into the pod. The AWS SDK reads `AWS_ROLE_ARN`, `AWS_WEB_IDENTITY_TOKEN_FILE`, and `AWS_REGION` (all auto-injected by the pod-identity webhook), calls `sts:AssumeRoleWithWebIdentity`, and gets short-lived credentials scoped to the role's inline policy. The role's trust policy restricts which (namespace, SA-name) pair can assume it, so a compromised pod in one namespace can't steal another workload's credentials.

## When to use this skill

- Your workload needs AWS access (any service)
- You're using a runtime whose SDK respects the default credential provider chain — Python boto3, Go aws-sdk-go-v2, Rust aws-sdk-rust, Node @aws-sdk/* v3, Ruby aws-sdk gem. (95% of cases.)

When *not* to use it — see "Known broken integrations" at the bottom.

## What you're adding (one file)

In `scientist-hq/infra/terraform/k3-eks-service-accounts/`, create `role_<service>.tf`:

```hcl
resource "aws_iam_role" "k3-<service>" {
  name = "k3-<service>"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = format("arn:aws:iam::%s:oidc-provider/%s", local.aws_account_id, local.oidc_provider_id)
        }
        Condition = {
          StringEquals = {
            # Lock to one specific namespace + SA name.
            "${local.oidc_provider_id}:sub" : "system:serviceaccount:<namespace>:<sa-name>",
            "${local.oidc_provider_id}:aud" : "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  inline_policy {
    name = "<policy-name>"
    policy = jsonencode({
      Version = "2012-10-17",
      Statement = [
        # minimum permissions the workload needs
      ]
    })
  }
}
```

Use `StringEquals` for an exact namespace/SA match (preferred, principle of least privilege). Use `StringLike` with a wildcard like `"system:serviceaccount:transformers:*"` only when one role serves many SAs in one namespace (see `role_embeddings.tf` for that pattern — it intentionally trusts every SA in the `transformers` namespace).

## What you change in k3-applications (one annotation)

In the Helm values for your Application, annotate the service account:

```yaml
serviceAccount:
  create: true
  name: <sa-name>                        # must match the trust policy
  annotations:
    eks.amazonaws.com/role-arn: "arn:aws:iam::554546661178:role/k3-<service>"
```

The role ARN is derived from the role `name` in the Terraform — `arn:aws:iam::554546661178:role/k3-<service>`. The AWS account ID `554546661178` is the Scientist.com production account and rarely changes; if you're unsure, copy from another `serviceAccount.annotations.eks.amazonaws.com/role-arn` in the repo.

## Bedrock — worked example

Bedrock is currently the most-requested IRSA use case. The standard inline policy grants `bedrock:InvokeModel` + `bedrock:InvokeModelWithResponseStream` against the Claude family in eu-central-1 inference profiles (and the underlying foundation models, since inference profiles fan out):

```hcl
inline_policy {
  name = "bedrock-invoke"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = [
        "bedrock:InvokeModel",
        "bedrock:InvokeModelWithResponseStream"
      ],
      Resource = [
        "arn:aws:bedrock:eu-central-1:554546661178:inference-profile/*",
        "arn:aws:bedrock:*::foundation-model/anthropic.claude-*"
      ]
    }]
  })
}
```

Workloads using this policy: `k3-embeddings`, `k3-sparkle-ai-service`, `k3-litellm`, `k3-n8n` (for non-langchain nodes). Copy the policy verbatim into your new role.

If you need additional Bedrock surface (guardrails, knowledge bases, agents), add the corresponding `bedrock:*` actions and ARN patterns — but invocation against Claude in eu-central-1 is the 95% case.

## Other common policies

Look for an existing role with the access you need and copy its inline policy:

| Need | Reference role file |
|---|---|
| Read/write a specific S3 bucket | `role_rx_production.tf`, `role_velero.tf` |
| Bedrock | `role_embeddings.tf`, `role_litellm.tf`, `role_sparkle_ai.tf` |
| RDS data API | `role_rx_production.tf` |
| Athena + Glue | `role_airflow.tf`, `role_superset.tf` |
| Route53 | `role_cert_manager.tf`, `role_external_dns.tf` |
| ECR | role files for build/deploy workloads |

When in doubt, grep `terraform/k3-eks-service-accounts/role_*.tf` for the AWS action you need.

## Apply order

`Terraform: k3-eks-service-accounts` GitHub Actions workflow runs on merge to main. Apply takes seconds.

The k3-applications side (the SA annotation) syncs through ArgoCD — typically a couple of minutes after merge.

If the SA already exists when terraform creates the role, IRSA starts working as soon as the pod's next token refresh (~10 minutes worst case, or restart the pod to force it).

## Verification

```bash
# Role exists with the expected ARN
aws iam get-role --role-name k3-<service> --query 'Role.Arn'
# → "arn:aws:iam::554546661178:role/k3-<service>"

# SA has the annotation
kubectl -n <namespace> get sa <sa-name> -o jsonpath='{.metadata.annotations.eks\.amazonaws\.com/role-arn}'
# → arn:aws:iam::554546661178:role/k3-<service>

# Pod can actually assume the role and call the API
kubectl -n <namespace> exec deploy/<deployment> -- aws sts get-caller-identity
# → "Arn": "arn:aws:sts::554546661178:assumed-role/k3-<service>/..."
```

If `get-caller-identity` works but the actual API call (e.g. `bedrock:InvokeModel`) returns AccessDenied, the role assumption is fine but the inline policy is missing the action or the ARN pattern doesn't match. Check CloudTrail for the exact action and resource that was rejected.

## Known broken integrations — when IRSA is *not* enough

Some applications hard-code "give me static `accessKeyId` + `secretAccessKey`" and ignore the AWS SDK's default credential chain. IRSA can't help those. Two ways out:

### Option A: AssumeRole hop (when the app supports an assume-role credential type)

n8n supports an `awsAssumeRole` credential type (introduced in PR #20626 + IRSA support in PR #22316, available in n8n ≥2.22.0). The pod's IRSA role STS-signs the request, then assumes a *second* role with the actual permissions. Pattern: see `role_n8n_bedrock_invoke.tf` — `k3-n8n` (IRSA) can `sts:AssumeRole` into `n8n-bedrock-invoke` (which holds the actual `bedrock:InvokeModel` policy).

Two roles, IRSA at the entrance, assume-role for the workload-specific permission set.

### Option B: Static IAM user (last resort)

For workloads whose code path neither uses the SDK chain *nor* supports an assume-role hop, the only path is a plain `aws_iam_user` with access keys. **No `aws_iam_access_key` resources exist anywhere in the infra repo by design** — the keys never enter Terraform state or git. The operator creates them manually post-apply and pastes them into the app's credential UI.

Worked example: `terraform/k3-eks-service-accounts/user_n8n_bedrock.tf` — the `n8n-bedrock-user` IAM user that exists because n8n's langchain `lmChatAwsBedrock` node ignores the SDK chain (LiteLLM, deployed as the AI gateway in front of n8n, dodges this — IRSA-only). See the file's header comment for the three n8n upstream gaps that justified the exception, and `docs/k3-eks-service-accounts/content/index.md` for the rotation procedure.

Treat Option B as a documented escape hatch, not a default. Once the upstream bug is fixed, delete the user.

### Known affected applications (current as of 2026-05)

| Workload | Issue | Workaround |
|---|---|---|
| n8n `lmChatAwsBedrock` (langchain Bedrock chat) | Sends empty-string creds when no static keys set; doesn't accept `awsAssumeRole` credential type ([n8n-io/n8n#22700](https://github.com/n8n-io/n8n/issues/22700)) | Route through LiteLLM (preferred) or fall back to Option B |
| n8n HTTP Request + AWS credential against Bedrock | Signs as service `bedrock-runtime` while AWS demands `bedrock` ([n8n-io/n8n#14623](https://github.com/n8n-io/n8n/issues/14623)) | Route through LiteLLM |

When in doubt, before designing your IRSA role, try the workload in dev with the SDK default chain (no keys) — if it works, you're set; if it fails with "InvalidClientTokenId" or "empty string" errors, you've hit one of the broken paths.

## Real-world examples in the repo

- **`role_embeddings.tf`** — wildcards across SAs in one namespace (`system:serviceaccount:transformers:*`), S3 read/write
- **`role_litellm.tf`** — single namespace + SA pinned (`system:serviceaccount:litellm:litellm`), Bedrock policy
- **`role_n8n.tf`** + **`role_n8n_bedrock_invoke.tf`** — the AssumeRole-hop pattern (Option A above), with the cross-role trust policy
- **`role_rx_production.tf`** — large multi-service inline policy across S3/RDS/SES, production RX workload

Copy whichever is closest in shape to your need.
