# CI/CD Pipelines

GitHub Actions workflows for security scanning, validation, and infrastructure deployment.

## Workflow Overview

| Workflow | Trigger | Description |
|---|---|---|
| `main.yml` | push to `main`, `test/main` | Security scans and IaC deploy |
| `main-pr.yml` | PR to `main` | Security scans + auto-approve PR (owner only) |
| `main-prt.yml` | PR to `main` (pull_request_target), push to `test/main` | Terragrunt plan against production |
| `feature.yml` | push to `feature/**` | Security scans + IaC validation |

## Reusable Workflows

### Deployment

| Workflow | Description |
|---|---|
| `deploy-IaC.yml` | Terragrunt apply with OIDC AWS auth, posts summary to job |
| `plan-IaC.yml` | Terragrunt plan with OIDC AWS auth, posts summary to job |

### Validation

| Workflow | Description |
|---|---|
| `validate.yml` | Delegates to `validate-IaC.yml` |
| `validate-IaC.yml` | HCL formatting, HCL validation, tofu validate |

### Security Scanning

| Workflow | Description |
|---|---|
| `scan.yml` | Orchestrates CodeQL, Gitleaks, Trivy |
| `scan-codeql.yml` | CodeQL static analysis |
| `scan-gitleaks.yml` | Secret scanning |
| `scan-trivy.yml` | IaC config vulnerability scanning |

## Authentication

GitHub Actions workflows use OpenID Connect (OIDC) for keyless AWS authentication. The OIDC provider is configured in `IaC/demo-core` and scoped to the protected environment defined in `IaC/config.yaml`.
