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
│   └── demo-core/              # Core AWS bootstrap module
│       ├── terraform.tf        # Provider requirements (AWS ~> 6.0)
│       ├── provider.tf         # AWS provider config + default tags
│       ├── variables.tf        # Input variables and common tags
│       ├── locals.tf           # Local computed values (admin ARNs)
│       ├── data.tf             # Data sources (caller identity, region)
│       ├── user.tf             # IAM automation user + access keys in Secrets Manager
│       ├── role.tf             # IAM roles (execution + KMS)
│       ├── kms.tf              # KMS key for encryption
│       ├── s3.tf               # S3 bucket + policy for tfstate
│       └── output.tf           # Useful bootstrap outputs
├── .pre-commit-config.yaml     # Pre-commit hooks (Gitleaks secret scanning)
└── .gitignore
```

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

## Variables

| Variable | Default | Description |
|---|---|---|
| `project_region` | `us-east-1` | AWS region to deploy into |
| `project_name` | `sa-demo` | Project name prefix |
| `tf_user_name` | `sa-demo-tf-user` | IAM automation user name |
| `tf_user_path` | `/automation/iac/` | IAM path for the user |
| `tf_role_name` | `TFExecutionRole` | Name of the IAM execution role |
| `tf_extra_admin_user` | `terraf1admin` | Additional user granted admin access to KMS/policies |
| `common_tags` | `Project`, `Environment`, `Owner` | Tags applied to all resources |
