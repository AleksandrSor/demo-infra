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

You may be surprised to learn (yes, again) that AWS EKS supports this out of the box. Thanks to IRSA, it works through OIDC.

Run the following command:
```
aws eks describe-cluster \
  --name <your-cluster-name> \
  --query "cluster.identity.oidc.issuer" \
  --output text
```
Then append the OIDC discovery path `/.well-known/openid-configuration` to the returned issuer URL.