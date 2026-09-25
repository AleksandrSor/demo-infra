# OIDC: AWS OIDC Federation

![scheme](./oidc-aws-federation.png "scheme.")

## Introduction

In my last posts, I briefly mentioned the important topic of zero static credentials. This is especially relevant today, as interactions with AI agents in protected environments can unexpectedly expose credentials.

In this part, I explain how to authenticate my GitHub Actions jobs with the AWS API to provision AWS resources without static credentials.

## GitHub OIDC Provider

GitHub provides a [GitHub Actions OIDC provider](https://docs.github.com/en/actions/concepts/security/openid-connect), so our repository, refs, pull requests, and even environments can act as identities for resource servers that accept OIDC tokens.

### Token

Token example from the official documentation:
```json
{
  "typ": "JWT",
  "alg": "RS256",
  "x5t": "example-thumbprint",
  "kid": "example-key-id"
}
{
  "jti": "example-id",
  "sub": "repo:octo-org/octo-repo:environment:prod",
  "environment": "prod",
  "aud": "https://github.com/octo-org",
  "ref": "refs/heads/main",
  "sha": "example-sha",
  "repository": "octo-org/octo-repo",
  "repository_owner": "octo-org",
  "actor_id": "12",
  "repository_visibility": "private",
  "repository_id": "74",
  "repository_owner_id": "65",
  "run_id": "example-run-id",
  "run_number": "10",
  "run_attempt": "2",
  "runner_environment": "github-hosted",
  "actor": "octocat",
  "workflow": "example-workflow",
  "head_ref": "",
  "base_ref": "",
  "event_name": "workflow_dispatch",
  "repo_property_workspace_id": "ws-abc123",
  "ref_type": "branch",
  "job_workflow_ref": "octo-org/octo-automation/.github/workflows/oidc.yml@refs/heads/main",
  "iss": "https://token.actions.githubusercontent.com",
  "nbf": 1632492967,
  "exp": 1632493867,
  "iat": 1632493567
}
```

Most important part is the `sub` claim.
> `sub` is the stable subject identifier for the token issuer, and it is usually the safest way to correlate a returning principal

The `sub` claim can vary depending on whether the job runs against a ref, tag, pull request, or environment.

#### Environment

The subject claim includes the environment name when the job [references](https://docs.github.com/en/actions/reference/security/oidc#filtering-for-a-specific-environment) an environment.

Syntax:
> repo:ORG-NAME/REPO-NAME:environment:ENVIRONMENT-NAME

Example:
> repo:octo-org/octo-repo:environment:Production

#### specific branch

The subject claim includes the branch name of the workflow, but only if the job doesn't reference an environment, and if the workflow is not triggered by a pull request event.

Syntax:
> repo:ORG-NAME/REPO-NAME:ref:refs/heads/BRANCH-NAME

Example:
> repo:octo-org/octo-repo:ref:refs/heads/demo-branch

More information is available in the [official documentation](https://docs.github.com/en/actions/reference/security/oidc).

### Token request

There is an [official GitHub Action](https://docs.github.com/en/actions/how-tos/secure-your-work/security-harden-deployments/oidc-in-aws) that helps not only with requesting a token, but also with configuring the AWS CLI to use it in a simple way.

```yaml
name: AWS example workflow
on:
  push
env:
  AWS_REGION : "AWS-REGION"
  ROLE-TO-ASSUME: "ROLE-ARN"
# permission can be added at job level or workflow level
permissions:
  id-token: write   # This is required for requesting the JWT
  contents: read    # This is required for actions/checkout
jobs:
  AWSGetCallerIdentity:
    runs-on: ubuntu-latest
    steps:
      - name: Git clone the repository
        uses: actions/checkout@v6
        with:
          fetch-depth: 0
      - name: configure aws credentials
        uses: aws-actions/configure-aws-credentials@v6.1.0
        with:
          role-to-assume: ${{ env.ROLE-TO-ASSUME }}
          aws-region: ${{ env.AWS_REGION }}
          output-credentials: true
      - name: get caller identity
        run: |
            aws sts get-caller-identity
```
More information is available [here](https://github.com/aws-actions/configure-aws-credentials).

## AWS Federation

## GitHub Actions Job