# OIDC: Deliver OIDC parameters unattended using External Secrets, AWS Secrets Manager, and FluxCD

![scheme](./oidc-external-secrets.png "scheme.")

## Introduction

In one of my [previous posts](./oidc-jwt-validation.md), I described how I tested new possibilities for using the Gateway API implementation of the AWS Load Balancer Controller for JWT validation.

I also covered [how to configure Keycloak](./oidc-keycloak.md) as an identity provider for issuing JWTs to access Kubernetes through a JWT-validated load balancer endpoint.

In this post, I want to describe how to deliver OIDC parameters from a Keycloak client all the way down to the actual load balancer configuration in an unattended manner.

Moreover, the entire flow does not require any static credentials to be stored. I promise to explain how to achieve a zero-static-credentials setup in a future post. Follow me!

## AWS Secrets Manager

As a first step, let OpenTofu/Terraform store the client parameters in [AWS Secrets Manager](https://aws.amazon.com/secrets-manager/). From there, they can be delivered further using the pull-based approach of the [External Secrets Operator](https://external-secrets.io/).

I am using an ephemeral resource to avoid storing the client secret in the state.

[kube-api-client.tf](/IaC/keycloak/kube-api-client.tf)
```hcl
locals {
  client_secret_version = 10
}

ephemeral "random_password" "kube_api_client_secret" {
  length  = 86
  special = false
}

resource "keycloak_openid_client" "kube_api" {
  ...
  client_secret_wo          = ephemeral.random_password.kube_api_client_secret.result
  client_secret_wo_version  = local.client_secret_version
  ...
}
```

A small abstraction layer helps loosen the coupling between the Keycloak stack and AWS Secrets Manager.

[aws-secretmanager.tf](/IaC/keycloak/aws-secretmanager.tf)
```hcl
module "aws_secretmanager" {
  source         = "./modules/aws-secretmanager"
  secret_name    = local.client_config.name
  secret_version = local.client_secret_version
  secret_value = jsonencode({
    name          = local.client_config.name
    client_id     = local.client_config.client_id
    client_secret = ephemeral.random_password.kube_api_client_secret.result
    issuer_url    = local.client_config.issuer_url
    audience      = local.client_config.audience

    groups_claim  = local.client_config.groups_claim
    groups_prefix = local.client_config.groups_prefix

    username_claim  = local.client_config.username_claim
    username_prefix = local.client_config.username_prefix

    required_claims = local.client_config.required_claims
    jwksEndpoint    = local.client_config.jwksEndpoint
  })
}
```

The entire configuration is stored as JSON.
[main.tf](/IaC/keycloak/modules/aws-secretmanager/main.tf)
```hcl
resource "aws_secretsmanager_secret" "secret" {
  name = var.secret_name
}

resource "aws_secretsmanager_secret_version" "secret_version" {
  secret_id                = aws_secretsmanager_secret.secret.id
  secret_string_wo         = var.secret_value
  secret_string_wo_version = var.secret_version
}
```

## External Secrets Operator

[External Secrets Operator](https://external-secrets.io/latest/) is a Kubernetes operator that retrieves information from external APIs and automatically injects the values into a Kubernetes Secret.

ESO supports [AWS Secrets Manager](https://aws.amazon.com/secrets-manager/) and also [EKS Pod Identity](https://docs.aws.amazon.com/eks/latest/userguide/pod-identities.html) as a way to access secrets securely without static credentials.

Let's create a role for ESO.

[eso-addon.tf](/IaC/aws-eks/eso-addon.tf)
```hcl
# Reference: https://external-secrets.io/latest/provider/aws-access/

locals {
  eso_namespace       = "external-secrets"
  eso_service_account = "external-secrets"
}

data "aws_iam_policy_document" "eso_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }

    actions = [
      "sts:AssumeRole",
      "sts:TagSession"
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/kubernetes-namespace"
      values   = [local.eso_namespace]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/kubernetes-service-account"
      values   = [local.eso_service_account]
    }
  }
}

resource "aws_iam_role" "eso_role" {
  name               = "${local.config.project.name}-external-secrets-addon"
  assume_role_policy = data.aws_iam_policy_document.eso_assume_role.json
}

# Reference: https://external-secrets.io/latest/provider/aws-secrets-manager/
data "aws_iam_policy_document" "eso_addon" {
  statement {
    effect = "Allow"

    actions = [
      "secretsmanager:ListSecrets",
      "secretsmanager:BatchGetSecretValue"
    ]

    resources = ["*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "secretsmanager:GetResourcePolicy",
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
      "secretsmanager:ListSecretVersionIds"
    ]

    resources = [
      "arn:aws:secretsmanager:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:secret:${local.config.project.name}-*"
    ]
  }
}

resource "aws_iam_policy" "eso_addon" {
  name   = "${local.config.project.name}-external-secrets-addon"
  policy = data.aws_iam_policy_document.eso_addon.json
}

resource "aws_iam_role_policy_attachment" "eso_addon_policy_attachment" {
  role       = aws_iam_role.eso_role.name
  policy_arn = aws_iam_policy.eso_addon.arn
}
```

And an identity association. It can be created before the namespace and service account are created.
```hcl
resource "aws_eks_pod_identity_association" "eso_addon" {
  cluster_name    = aws_eks_cluster.cluster.name
  namespace       = local.eso_namespace
  service_account = local.eso_service_account
  role_arn        = aws_iam_role.eso_role.arn
}
```

Installing ESO via FluxCD.

[external-secrets.yaml](/fluxcd/infra/external-secrets/base/external-secrets.yaml)
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: external-secrets
---
apiVersion: source.toolkit.fluxcd.io/v1
kind: HelmRepository
metadata:
  name: external-secrets
  namespace: external-secrets
spec:
  url: https://charts.external-secrets.io
---
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: external-secrets
  namespace: external-secrets
spec:
  chart:
    spec:
      chart: external-secrets
      version: "2.10.x"
      sourceRef:
        kind: HelmRepository
        name: external-secrets
  interval: 30m
  releaseName: external-secrets
  values:
    serviceAccount:
      name: external-secrets
```

[external-secrets.yaml](/fluxcd/clusters/prod/external-secrets.yaml)
```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: external-secrets
  namespace: flux-system
spec:
  sourceRef:
    kind: GitRepository
    name: flux-system
  path: ./fluxcd/infra/external-secrets/prod
  prune: true
  interval: 30m
  retryInterval: 5m
  timeout: 5m
```

## ESO custom resources: SecretStore and ExternalSecret

The [SecretStore](https://external-secrets.io/latest/api/secretstore/) specifies how External Secrets accesses the external API.

[ClusterSecretStore.yaml](/fluxcd/infra/external-secrets-custom/base/ClusterSecretStore.yaml)
```yaml
apiVersion: external-secrets.io/v1
kind: ClusterSecretStore
metadata:
  name: aws-secretmanager
spec:
  provider:
    aws:
      service: SecretsManager
      region: "${region}"
```

The [ExternalSecret resource](https://external-secrets.io/latest/api/externalsecret/) describes what data should be fetched, how it should be transformed, and where it should be stored as a Kubernetes Secret.

[ExternalSecret.yaml](/fluxcd/infra/external-secrets-custom/base/ExternalSecret.yaml)
```yaml
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: oidc-params
  namespace: flux-system
spec:
  refreshInterval: 1h0m0s
  secretStoreRef:
    kind: ClusterSecretStore
    name: aws-secretmanager
  target:
    name: oidc-params
    creationPolicy: Owner
  dataFrom:
  - extract:
      key: "${projectName}-keycloak"
```

The result is a Kubernetes Secret that can be used by FluxCD to substitute values in custom resources for the AWS Load Balancer Controller.

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: oidc-params
  namespace: flux-system
data:
  audience: demo-infra-kube-api
  client_id: demo-infra-kube-api
  client_secret: <secret_value>
  groups_claim: roles
  groups_prefix: "oidc:"
  issuer_url: https://<keycloak_url>/auth/realms/demo-infra-project
  jwksEndpoint: https://<keycloak_url>/auth/realms/demo-infra-project/protocol/openid-connect/certs
  name: demo-infra-keycloak
  required_claims: {}
  username_claim: username
  username_prefix: oidc-
```

## FluxCD post-build variable substitution

With [.spec.postBuild.substituteFrom](https://fluxcd.io/flux/components/kustomize/kustomizations/#post-build-variable-substitution), you can provide a list of ConfigMaps and Secrets from which variables are loaded. The ConfigMap and Secret data keys are used as the variable names.

Let's implement this in the ListenerRuleConfiguration for the AWS Load Balancer Controller.

[ListenerRuleConfiguration.yaml](/fluxcd/infra/envoy-kube-proxy/prod/ListenerRuleConfiguration.yaml)
```yaml
apiVersion: gateway.k8s.aws/v1
kind: ListenerRuleConfiguration
metadata:
  name: envoy-kube-proxy-jwt-validation
spec:
  actions:
    - type: "jwt-validation"
      jwtValidationConfig:
        jwksEndpoint: "${jwksEndpoint}"
        issuer: "${issuer_url}"
        additionalClaims:
          - name: "aud"
            format: "single-string"
            values: ${audience}
```

[envoy-kube-proxy.yaml](/fluxcd/clusters/prod/envoy-kube-proxy.yaml)
```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: envoy-kube-proxy
  namespace: flux-system
spec:
  ...
  postBuild:
  ...
      - kind: Secret
        name: oidc-params
```

## Conclusion

Voilà! I have implemented an unattended flow to deliver OIDC parameters to the AWS Load Balancer.
In a future post, I will explain the zero-static-credentials setup in more detail. Stay in touch!