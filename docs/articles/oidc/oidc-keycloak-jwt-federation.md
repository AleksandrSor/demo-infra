# OIDC: Keycloak JWT Federation

![scheme](./oidc-aws-federation.png "scheme.")

## Introduction

In my previous posts, I mentioned the important topic of zero static credentials. This is especially relevant today, as interactions with AI agents in protected environments can unexpectedly expose credentials.

In this part, I explain how to authenticate GitHub Actions jobs so they can provision Keycloak without static credentials. A dirty trick is involved, and I explain it below.

## GitHub OIDC Provider

GitHub provides a [GitHub Actions OIDC provider](https://docs.github.com/en/actions/concepts/security/openid-connect), so our repository, refs, pull requests, and even environments can act as identities for resource servers that accept OIDC tokens.

The token format and the `sub` claim are covered in my [previous post](/docs/articles/oidc/oidc-aws-federation.md). 

For AWS authentication, I used an official action that helps retrieve a token from the GitHub OIDC provider. Keycloak does not currently have an official action, so I had to use custom steps to obtain the token.

[action.yml](.github/actions/keycloak-token/action.yml)
```yaml
name: Keycloak Token Action
description: 'Action to obtain a Keycloak token'
inputs:
  keycloak-url:
    description: 'The URL of the Keycloak server'
    required: true
  keycloak-realm:
    description: 'The Keycloak realm'
    required: true
  keycloak-base-path:
    description: 'The base path for Keycloak (optional)'
    required: false
runs:
  using: "composite"
  steps:
    - name: Get JWT token
      id: get-gh-token
      env:
        KEYCLOAK_AUDIENCE: "${{ inputs.keycloak-url }}${{ inputs.keycloak-base-path || '' }}/realms/${{ inputs.keycloak-realm }}"
      uses: actions/github-script@v9
      with:
        script: |
          const audience = process.env['KEYCLOAK_AUDIENCE'];
          let ghToken = await core.getIDToken(audience);
          core.setOutput('ghToken', ghToken);

          function decodeJWT(jwtToken) {
            try {
              // A JWT has 3 parts: Header, Payload, Signature
              const [header, payload, signature] = jwtToken.split('.');
              
              // Decode base64url string to standard UTF-8 text
              const decodedPayload = Buffer.from(payload, 'base64').toString('utf8');
              
              // Parse the string into a readable JavaScript object
              return JSON.parse(decodedPayload);
            } catch (error) {
              console.error("Invalid JWT format", error);
              return null;
            }
          }

          console.log('----');
          console.log(decodeJWT(ghToken));
          console.log('----');
```
This composite action uses `actions/github-script` and the `core.getIDToken(audience)` function with a custom audience value. Keycloak expects the `aud` claim to match the `issuer_url` of the Keycloak realm endpoint.

Example of a decoded GitHub token from the test workflow:
```json
{
  actor: 'AleksandrSor',
  actor_id: '...',
  aud: 'https://<KEYCLOAK_URL>/auth/realms/demo-infra-project',
  ...
  environment: 'test-keycloak',
  ...
  iss: 'https://token.actions.githubusercontent.com',
  ...
  sub: 'repo:AleksandrSor/demo-infra:environment:test-keycloak',
  ...
}
```

More information about a custom way of obtaining a GitHub OIDC token can be found [here](https://docs.github.com/en/actions/how-tos/secure-your-work/security-harden-deployments/oidc-in-cloud-providers).

Now I need to exchange my GitHub token for a Keycloak token with the correct permissions to manage my Keycloak instance. Before I can do that, I need to register the GitHub OIDC provider in Keycloak.

## Keycloak JWT Federation

I want to eliminate the need to store static credentials, and Keycloak JWT federation helps me achieve that.

The first step to setting up federated client authentication is to define a trust relationship between Keycloak and the external identity providers. This is done by creating a new identity provider in the realm.

Keycloak currently has three types of identity providers that support federated client authentication:

- OpenID Connect

- SPIFFE

- Kubernetes

More information is available in this [blog post](https://www.keycloak.org/2026/01/federated-client-authentication).

Since the GitHub OIDC provider does not expose a client authentication endpoint, it cannot be registered properly as an OpenID Connect provider. It also cannot be used as a SPIFFE provider.

This is where the dirty trick comes in. I register the GitHub OIDC provider as Kubernetes. This works because Keycloak expects an OIDC discovery endpoint at `<ISSUER URL>/.well-known/openid-configuration`, and GitHub exposes it there: [https://token.actions.githubusercontent.com/.well-known/openid-configuration](https://token.actions.githubusercontent.com/.well-known/openid-configuration).