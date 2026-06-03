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
│   ├── demo-core/              # Core AWS bootstrap module
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
│   └── aws-eks/                # stack for EKS
│       ├── terragrunt.hcl      # Stack entrypoint (inherits root config)
│       ├── terraform.tf         # Provider requirements (AWS ~> 6.0)
│       ├── data.tf              # Data sources (caller identity, region)
│       ├── provider.tf         # AWS provider config + default tags
│       ├── variables.tf        # YAML config input and local values
│       ├── vpc.tf              # VPC, IGW, route tables
│       ├── node-subnets.tf     # Worker node subnets
│       ├── pod-subnets.tf      # Pod secondary CIDR subnets
│       ├── alb-subnets.tf      # ALB subnets and associations
│       ├── nlb-subnets.tf      # NLB subnets and associations
│       ├── eks-nodes-iam-roles.tf # IAM role and instance profile for EKS nodes
│       ├── eks-nodes-secgroups.tf # Security group rules for EKS nodes
│       ├── eks-nodes-template.tf  # Launch template for self-managed nodes
│       ├── eks-nodes-group.tf     # Auto Scaling Group for EKS nodes
│       ├── eks-cluster.tf         # EKS cluster and control plane IAM role
│       ├── eks-cluster-secgroup.tf # Control plane <-> nodes SG rules
│       ├── eks-cluster-access.tf  # EKS access entries and admin policy mapping
│       ├── eks-cluster-oidc.tf    # EKS OIDC provider discovery and setup
│       └── ssm.tf              # Default Host Management Configuration
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

### IaC/aws-eks

stack for EKS networking and self-managed worker nodes:

| Resource | Purpose |
|---|---|
| `aws_vpc` | Primary VPC for cluster networking |
| `aws_vpc_ipv4_cidr_block_association` | Optional secondary CIDR for pod IPs |
| `aws_default_security_group` | Baseline VPC security group configuration |
| `aws_default_network_acl` | Baseline VPC network ACL configuration |
| `aws_subnet` (node/pod/alb/nlb) | Dedicated subnet groups per workload type |
| `aws_route_table` + associations | Public/private route control for subnets |
| `aws_internet_gateway` | Internet egress for public routing |
| `aws_launch_template` | Launch template for self-managed EKS worker nodes |
| `aws_autoscaling_group` | Worker node capacity management |
| `aws_iam_role` + `aws_iam_instance_profile` (nodes) | Node IAM permissions and instance profile |
| `aws_security_group` (nodes) | Security group for EKS workers |
| `aws_eks_cluster` | EKS control plane with API auth mode and network settings |
| `aws_iam_role` (cluster) + policy attachments | IAM role used by EKS control plane |
| `aws_eks_access_entry` + `aws_eks_access_policy_association` | IAM principal access mapping for nodes and admins |
| `aws_iam_openid_connect_provider` (eks) | OIDC provider for Kubernetes service account federation |
| `data.tls_certificate` (eks) | Cluster OIDC certificate thumbprint discovery |
| `aws_vpc_security_group_ingress_rule`/`egress_rule` (control plane) | Enables control plane and node communication |
| `aws_ssm_service_setting` | Default EC2 instance management role for SSM |
| `aws_iam_role` (ssm) | IAM role used by SSM managed instances |
| `data.aws_ssm_parameter` (Bottlerocket AMI) | Resolves latest node AMI by EKS version/architecture |
| `data.aws_ec2_instance_type` | Validates node instance type details |


---

## CI/CD

GitHub Actions workflows under `.github/workflows/`:

| Workflow | Trigger | Description |
|---|---|---|
| `main.yml` | push to `main`, `test/main` | Security scans and IaC deploy |
| `main-pr.yml` | PR to `main` | Security scans + auto-approve PR (owner only) |
| `main-prt.yml` | PR to `main` (pull_request_target), push to `test/main` | Terragrunt plan against production |
| `feature.yml` | push to `feature/**` | Security scans + IaC validation |
| `deploy-IaC.yml` | reusable | Terragrunt apply with OIDC AWS auth, posts summary to job |
| `plan-IaC.yml` | reusable | Terragrunt plan with OIDC AWS auth, posts summary to job |
| `scan.yml` | reusable | Orchestrates CodeQL, Gitleaks, Trivy |
| `scan-codeql.yml` | reusable | CodeQL static analysis |
| `scan-gitleaks.yml` | reusable | Secret scanning |
| `scan-trivy.yml` | reusable | IaC config vulnerability scanning |
| `validate.yml` | reusable | Delegates to `validate-IaC.yml` |
| `validate-IaC.yml` | reusable | HCL formatting, HCL validation, tofu validate |
| `plan-IaC.yml` | reusable | Terragrunt plan with OIDC AWS auth, posts summary to job |
| `deploy-IaC.yml` | reusable | Terragrunt apply with OIDC AWS auth, posts summary to job |

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
| `env.repository.name` | `AleksandrSor/demo-infra` | GitHub repo used to scope the OIDC trust policy |
| `env.repository.protected_environment` | `production` | GitHub environment allowed to assume the execution role |
| `project.name` | `demo-infra` | Project name prefix |
| `network.vpc_cidr` | `10.10.0.0/16` | Primary VPC CIDR for aws-eks stack |
| `network.vpc_secondary_cidr` | `100.64.0.0/16` | Secondary CIDR used for pod subnet ranges |
| `eks.version` | `1.35` | EKS version used for Bottlerocket AMI lookup |
| `eks.nodes.type` | `t4g.nano` | Instance type for self-managed EKS nodes |
| `eks.nodes.desired_capacity` | `1` | Desired node count |
| `eks.nodes.min_capacity` | `1` | Minimum node count |
| `eks.nodes.max_capacity` | `2` | Maximum node count |
| `common_tags` | `Project`, `Environment`, `Owner` | Default tags applied to resources |

## Module Variable

| Variable | Default | Description |
|---|---|---|
| `config_file` | `../config.yaml` | Path to the YAML config consumed by the module |
