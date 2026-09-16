# OIDC: EKS Pod Identity

![scheme](./oidc-pod-identity.png "scheme.")

## Introduction

In my last post, I briefly mentioned the important topic of zero static credentials. This is especially relevant today, as interactions with AI agents in protected environments can unexpectedly expose credentials.

My entire demo flow requires zero static credentials. Let me explain it in more detail in three parts. Follow along for future posts.

## Kubernetes as an OIDC-compliant identity provider

You may be surprised to learn that a [ServiceAccount token](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/) issued by the Kubernetes control plane is an OIDC-compliant JWT. This makes Kubernetes an OIDC-compliant identity provider for external services.

The Kubernetes API server even publishes an OpenID Provider Configuration document at `/.well-known/openid-configuration` and related JSON Web Key Set (JWKS) at `/openid/v1/jwks`.

However, there are a few limitations.
First, the issuer URL is set out of the box to either https://kubernetes.default.svc.cluster.local or
https://kubernetes.default.svc, depending on the distribution.
Second, the OpenID Provider Configuration endpoint (/.well-known/openid-configuration) and the JWKS endpoint are not publicly accessible by default.
You can address this by configuring the API server with the --service-account-issuer and --service-account-jwks-uri flags and by mirroring the OIDC endpoints to a public server.

You may be surprised to learn (yes, again) that AWS EKS addresses this out of the box. Thanks to [IRSA](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html), it uses OIDC to work with AWS IAM.

Run the following command:
```
aws eks describe-cluster \
  --name <your-cluster-name> \
  --query "cluster.identity.oidc.issuer" \
  --output text
```
Then append the OIDC discovery path `/.well-known/openid-configuration` to the returned issuer URL.

## EKS Pod Identity Agent

[EKS Pod Identity](https://docs.aws.amazon.com/eks/latest/userguide/pod-identities.html) is a new way to grant an IAM role to an application running in a pod. AWS recommends using EKS Pod Identity whenever possible to grant pods access to AWS resources. [A comparison table is also available here](https://docs.aws.amazon.com/eks/latest/userguide/service-accounts.html).

### How it works

#### 1. [Create a Pod Identity association](https://docs.aws.amazon.com/eks/latest/userguide/pod-id-assign-target-role.html#_how_it_works)
outside Kubernetes, for example:
[eso-addon.tf](/IaC/aws-eks/eso-addon.tf)
```hcl
resource "aws_eks_pod_identity_association" "eso_addon" {
  cluster_name    = aws_eks_cluster.cluster.name  #eks cluster name
  namespace       = local.eso_namespace
  service_account = local.eso_service_account
  role_arn        = aws_iam_role.eso_role.arn     #role for service account
}
``` 
This association can be created before the Namespace and ServiceAccount are created.

#### 2. [When Amazon EKS](https://docs.aws.amazon.com/eks/latest/userguide/pod-id-how-it-works.html#pod-id-agent-pod) starts

a new pod that uses a service account with an EKS Pod Identity association, it adds the following content to the pod manifest:
```yaml
    env:
    - name: AWS_CONTAINER_AUTHORIZATION_TOKEN_FILE
      value: "/var/run/secrets/pods.eks.amazonaws.com/serviceaccount/eks-pod-identity-token"
    - name: AWS_CONTAINER_CREDENTIALS_FULL_URI
      value: "http://169.254.170.23/v1/credentials"
    volumeMounts:
    - mountPath: "/var/run/secrets/pods.eks.amazonaws.com/serviceaccount/"
      name: eks-pod-identity-token
  volumes:
  - name: eks-pod-identity-token
    projected:
      defaultMode: 420
      sources:
      - serviceAccountToken:
          audience: pods.eks.amazonaws.com
          expirationSeconds: 86400 # 24 hours
          path: eks-pod-identity-token
```
Pay attention to the volume configuration: it uses a [projected volume](https://kubernetes.io/docs/concepts/storage/projected-volumes/) with a [TokenRequest](https://kubernetes.io/docs/reference/kubernetes-api/storage/csi-driver-v1/#TokenRequest).
Kubernetes places a service account token with a specific audience at `/var/run/secrets/pods.eks.amazonaws.com/serviceaccount/eks-pod-identity-token`.
You can inspect it with:
```bash
cat /var/run/secrets/pods.eks.amazonaws.com/serviceaccount/eks-pod-identity-token \
  | cut -d. -f2 \
  | base64 -d 2>/dev/null \
  | jq .
```
It looks like this:
```JSON
{
  "aud": [
    "pods.eks.amazonaws.com"
  ],
  "iss": "https://oidc.eks.us-east-1.amazonaws.com/id/<EKS_CLUSTER_ID>",
  "kubernetes.io": {
    "namespace": "external-secrets",
    "node": {
      "name": "<EKS_NODE_NAME>"
    },
    "pod": {
      "name": "external-secrets-debug"
    },
    "serviceaccount": {
      "name": "external-secrets"
    }
  },
  "sub": "system:serviceaccount:external-secrets:external-secrets"
}
```

#### 3. An application running in a pod
obtains AWS STS credentials through the AWS SDK by using `eks-pod-identity-token` with `AWS_CONTAINER_CREDENTIALS_FULL_URI`:
```yaml
    env:
    - name: AWS_CONTAINER_AUTHORIZATION_TOKEN_FILE
      value: "/var/run/secrets/pods.eks.amazonaws.com/serviceaccount/eks-pod-identity-token"
    - name: AWS_CONTAINER_CREDENTIALS_FULL_URI
      value: "http://169.254.170.23/v1/credentials"
```
Pay attention: this is a local bind address. The Pod Identity Agent must run on the node.

### Installation

Prerequisites and documentation are available [here](https://docs.aws.amazon.com/eks/latest/userguide/pod-id-agent-setup.html#pod-id-agent-add-on-create).
Examples from the demo project are shown below.
Since my node role already includes `AmazonEKSWorkerNodePolicy`:
[eks-nodes-iam-roles](/IaC/aws-eks/eks-nodes-iam-roles.tf)
```terraform
resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.nodes.name
}
```
I only need to install the add-on:
[eks-addon-pod-identity-agent](/IaC/aws-eks/eks-addon-pod-identity-agent.tf)
```terraform
data "aws_eks_addon_version" "latest_pod_identity_agent" {
  addon_name         = "eks-pod-identity-agent"
  kubernetes_version = aws_eks_cluster.cluster.version
  most_recent        = true
}


resource "aws_eks_addon" "pod_identity_agent" {
  cluster_name  = aws_eks_cluster.cluster.name
  addon_name    = "eks-pod-identity-agent"
  addon_version = data.aws_eks_addon_version.latest_pod_identity_agent.version

  resolve_conflicts_on_update = "OVERWRITE"
}
```


