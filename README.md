# demo-infra

Infrastructure as Code (IaC) project to provision AWS resources for running a fullstack demo application.

Built with [OpenTofu](https://opentofu.org/) and managed inside a dev container.

---

## Project Structure

```
demo-infra/
├── .devcontainer/          # Dev container config (OpenTofu, AWS CLI, kubectl, Helm)
├── demo-core/              # Core AWS bootstrap module
│   ├── terraform.tf        # Provider requirements (AWS ~> 6.0)
│   ├── provider.tf         # AWS provider config
│   ├── variables.tf        # Input variables (region, project name, IAM user)
│   ├── data.tf             # Data sources (caller identity, region)
│   ├── user.tf             # IAM automation user + access keys stored in Secrets Manager
└── .gitignore
```

### `demo-core`

Bootstrap module that sets up the foundational AWS resources needed before other modules can run:

| Resource | Purpose |
|---|---|
| `aws_iam_user` | Automation IAM user for IaC pipelines |
| `aws_iam_access_key` | Access key for the automation user |
| `aws_secretsmanager_secret` | Stores the access key ID and secret securely |

---

## Prerequisites

- [Dev Containers](https://containers.dev/) — all tooling is pre-installed inside the container
- AWS credentials configured under `.aws/` at the workspace root

## Usage

```bash
cd demo-core

tofu init
tofu plan
tofu apply
```

## Variables

| Variable | Default | Description |
|---|---|---|
| `project_region` | `us-east-1` | AWS region to deploy into |
| `project_name` | `sa-demo` | Project name prefix |
| `user_name` | `sa-demo-tf-user` | IAM automation user name |
| `user_path` | `/automation/iac/` | IAM path for the user |
