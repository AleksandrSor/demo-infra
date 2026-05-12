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
│   ├── config.yaml             # Central environment and tagging config
│   ├── root.hcl                # Shared Terragrunt root configuration
│   └── demo-core/              # Core AWS bootstrap module
│       ├── terraform.tf        # Provider requirements (AWS ~> 6.0)
│       ├── provider.tf         # AWS provider config + default tags
│       ├── variables.tf        # Input variable: config_path + locals
│       ├── data.tf             # Data sources (caller identity, region)
│       ├── user.tf             # IAM automation user + access keys in Secrets Manager
│       ├── role.tf             # IAM roles (execution + KMS)
│       ├── kms.tf              # KMS key for encryption
│       ├── s3.tf               # S3 bucket + policy for tfstate
│       └── output.tf           # Useful bootstrap outputs
├── .pre-commit-config.yaml     # Pre-commit hooks (Gitleaks secret scanning)
└── .gitignore
```

Note: IaC/test is intentionally excluded from this README.

### IaC/demo-core

Bootstrap module that sets up the foundational AWS resources needed before other modules can run:

| Resource | Purpose |
|---|---|
| `aws_iam_user` | Automation IAM user for IaC pipelines |
| `aws_iam_access_key` | Access key for the automation user |
| `aws_secretsmanager_secret` | Stores access key ID and secret (KMS-encrypted) |
| `aws_kms_key` | KMS key used for state/secret encryption |
| `aws_iam_role` (execution) | Role assumed by the automation user to run Tofu |
| `aws_iam_role` (kms) | Role for KMS encryption operations |
| `aws_s3_bucket` | Terraform state bucket with versioning and encryption |

---

## CI/CD

GitHub Actions workflows under `.github/workflows/`:

| Workflow | Trigger | Description |
|---|---|---|
| `main.yml` | push / PR to `main`, `feature/**` | Orchestrates all scan jobs |
| `scan.yml` | reusable | Orchestrates reusable scan workflows |
| `scan-codeql.yml` | reusable | CodeQL static analysis |
| `scan-gitleaks.yml` | reusable | Secret scanning |
| `scan-trivy.yml` | reusable | IaC config vulnerability scanning |

---

## Prerequisites

- [Dev Containers](https://containers.dev/) — all tooling is pre-installed inside the container
- AWS credentials configured under `.aws/` at the workspace root

## Usage

```bash
cd IaC/demo-core

tofu init
tofu plan
tofu apply
```

## Configuration

The module reads most settings from IaC/config.yaml.

| Config Key | Example | Description |
|---|---|---|
| `env.region` | `us-east-1` | AWS region |
| `env.tf_user.name` | `tf-user` | IAM automation user name |
| `env.tf_user.path` | `/automation/iac/` | IAM path for the user |
| `env.tf_role_name` | `TFExecutionRole` | IAM execution role name |
| `env.tf_extra_admin_users` | `["terraf1admin"]` | Extra IAM users with admin-level key access |
| `project.name` | `demo-infra` | Project name prefix |
| `common_tags` | `Project`, `Environment`, `Owner` | Default tags applied to resources |

## Module Variable

| Variable | Default | Description |
|---|---|---|
| `config_path` | `../config.yaml` | Path to the YAML config consumed by the module |
