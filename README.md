# demo-infra

Demo Infrastructure as Code (IaC) project to provision AWS resources for a fullstack demo application.

Built with [OpenTofu](https://opentofu.org/) and managed inside a dev container.

---

## Project Structure

```
demo-infra/
├── .devcontainer/              # Dev container config (OpenTofu, AWS CLI, kubectl, Helm)
├── .github/
│   └── workflows/              # CI/CD pipelines (security scanning)
├── IaC/
│   ├── backend.tftpl           # Backend template rendered by Terragrunt
│   ├── config.hcl              # Shared Terragrunt locals and config loading
│   ├── config.yaml             # Central environment and tagging config
│   ├── root.hcl                # Shared Terragrunt root configuration
│   └── demo-core/              # Core AWS bootstrap module
│       ├── terragrunt.hcl      # Stack entrypoint and backend generation
│       ├── terraform.tf        # Provider requirements (AWS ~> 6.0)
│       ├── provider.tf         # AWS provider config + default tags
│       ├── variables.tf        # YAML config input and derived locals
│       ├── data.tf             # Data sources (caller identity, region)
│       ├── user.tf             # IAM automation user + access keys in Secrets Manager
│       ├── role.tf             # IAM roles (execution + KMS + OIDC trust)
│       ├── kms.tf              # KMS key for encryption
│       ├── s3.tf               # S3 bucket + policy for tfstate
│       ├── oidc.tf             # GitHub Actions OIDC provider
│       └── output.tf           # Useful bootstrap outputs
├── .pre-commit-config.yaml     # Pre-commit hooks (Gitleaks secret scanning)
└── .gitignore
```

Note: IaC/test is intentionally excluded from this README.

### IaC/demo-core

Bootstrap stack that sets up the foundational AWS resources needed before other modules can run:

| Resource | Purpose |
|---|---|
| `aws_iam_user` | Automation IAM user for IaC pipelines |
| `aws_iam_access_key` | Access key for the automation user |
| `aws_secretsmanager_secret` | Stores access key ID and secret (KMS-encrypted) |
| `aws_kms_key` | KMS key used for state/secret encryption |
| `aws_iam_role` (execution) | Role assumed by the automation user or GitHub Actions via OIDC |
| `aws_iam_role` (kms) | Role for KMS encryption operations |
| `aws_s3_bucket` | Terraform state bucket with versioning and encryption |
| `aws_iam_openid_connect_provider` | GitHub Actions OIDC provider for keyless auth |

---

## CI/CD

GitHub Actions workflows under `.github/workflows/`:

| Workflow | Trigger | Description |
|---|---|---|
| `main.yml` | push to `main` | Security scans on merge |
| `main-pr.yml` | PR to `main` | Security scans + auto-approve PR (owner only) |
| `main-prt.yml` | PR to `main` (pull_request_target), push to `test/main` | Terragrunt plan against production |
| `feature.yml` | push to `feature/**` | Security scans + IaC validation |
| `scan.yml` | reusable | Orchestrates CodeQL, Gitleaks, Trivy |
| `scan-codeql.yml` | reusable | CodeQL static analysis |
| `scan-gitleaks.yml` | reusable | Secret scanning |
| `scan-trivy.yml` | reusable | IaC config vulnerability scanning |
| `validate.yml` | reusable | Delegates to `validate-IaC.yml` |
| `validate-IaC.yml` | reusable | HCL formatting, HCL validation, tofu validate |
| `plan-IaC.yml` | reusable | Terragrunt plan with OIDC AWS auth, posts summary to job |

---

## Prerequisites

- [Dev Containers](https://containers.dev/) — all tooling is pre-installed inside the container
- AWS credentials configured under `.aws/` at the workspace root

## Usage

normal use
```bash
cd IaC

terragrunt run --all -- plan
terragrunt run --all -- apply
```

first init
```bash
cd IaC/demo-core

tofu init
tofu plan
tofu apply

# enable plaintext_fallback_enabled in terragrunt.hcl for state migration
sed -i 's/plaintext_fallback_enabled = false/plaintext_fallback_enabled = true/g' terragrunt.hcl
terragrunt apply
# disable plaintext_fallback_enabled 
sed -i 's/plaintext_fallback_enabled = true/plaintext_fallback_enabled = false/g' terragrunt.hcl

cd ..
terragrunt run --all -- plan
terragrunt run --all -- apply
```

## Configuration

Terragrunt reads shared settings from `IaC/config.hcl`, which loads values from `IaC/config.yaml` and renders the backend configuration for the stack.

| Config Key | Example | Description |
|---|---|---|
| `env.region` | `us-east-1` | AWS region |
| `env.tf_user.name` | `tf-user` | IAM automation user name |
| `env.tf_user.path` | `/automation/iac/` | IAM path for the user |
| `env.tf_role_name` | `TFExecutionRole` | IAM execution role name |
| `env.tf_extra_admin_users` | `["terraf1admin"]` | Extra IAM users with admin-level key access |
| `env.repository.name` | `owner/demo-infra` | GitHub repo used to scope the OIDC trust policy |
| `env.repository.protected_environment` | `production` | GitHub environment allowed to assume the execution role |
| `project.name` | `demo-infra` | Project name prefix |
| `common_tags` | `Project`, `Environment`, `Owner` | Default tags applied to resources |

## Module Variable

| Variable | Default | Description |
|---|---|---|
| `config_file` | `../config.yaml` | Path to the YAML config consumed by the module |
