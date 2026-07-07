# Infrastructure as Code (IaC)

AWS infrastructure provisioning using OpenTofu and Terragrunt.

## Project Structure

```
IaC/
├── backend.tftpl           # Backend template rendered by Terragrunt
├── config.hcl              # Shared Terragrunt locals and config loading
├── config.yaml             # Central environment and tagging config
├── root.hcl                # Shared Terragrunt root configuration
├── demo-core/              # Core AWS bootstrap module
│   ├── data.tf             # Data sources (caller identity, region)
│   ├── kms.tf              # KMS key for encryption
│   ├── oidc.tf             # GitHub Actions OIDC provider
│   ├── output.tf           # Useful bootstrap outputs
│   ├── provider.tf         # AWS provider config + default tags
│   ├── role.tf             # IAM roles (execution + KMS + OIDC trust)
│   ├── s3.tf               # S3 bucket + policy for tfstate
│   ├── terraform.tf        # Provider requirements (AWS ~> 6.0)
│   ├── terragrunt.hcl      # Stack entrypoint and backend generation
│   ├── user.tf             # IAM automation user + access keys in Secrets Manager
│   └── variables.tf        # YAML config input and derived locals
└── aws-eks/                # EKS cluster and networking
    ├── alb-role.tf         # IAM policy/role + pod identity for ALB controller
    ├── alb-secgroup.tf     # Shared backend security group for ALB controller
    ├── alb-subnets.tf      # ALB/NLB subnets, associations, and ALB subnet ACL
    ├── data.tf             # Data sources (caller identity, region)
    ├── eks-addon-*.tf      # EKS add-ons (CoreDNS, kube-proxy, VPC CNI, pod-identity-agent)
    ├── eks-cluster-*.tf    # EKS cluster, IAM, OIDC, and access control
    ├── eks-nodes-*.tf      # Node groups, IAM, security groups, and launch templates
    ├── eks-pods-secgroups.tf # Pod security group configuration
    ├── node-subnets.tf     # Worker node subnets
    ├── pod-subnets.tf      # Pod secondary CIDR subnets
    ├── provider.tf         # AWS provider config + default tags
    ├── ssm.tf              # EC2 Instance Management Configuration
    ├── terraform.tf        # Provider requirements (AWS ~> 6.0)
    ├── terragrunt.hcl      # Stack entrypoint (inherits root config)
    ├── variables.tf        # YAML config input and local values
    └── vpc.tf              # VPC, IGW, route tables
```

Note: `IaC/test` is intentionally excluded.

## Module Overview

### demo-core

Bootstrap stack setting up foundational AWS resources:

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

### aws-eks

EKS cluster with networking, node groups, and add-ons:

| Resource | Purpose |
|---|---|
| `aws_vpc` | Primary VPC for cluster networking |
| `aws_vpc_ipv4_cidr_block_association` | Optional secondary CIDR for pod IPs |
| `aws_default_security_group` | Baseline VPC security group configuration |
| `aws_default_network_acl` | Baseline VPC network ACL configuration |
| `aws_subnet` (node/pod/alb/nlb) | Dedicated subnet groups per workload type |
| `aws_network_acl` (alb subnet) + associations | ALB subnet ACL guardrails and subnet bindings |
| `aws_route_table` + associations | Public/private route control for subnets |
| `aws_internet_gateway` | Internet egress for public routing |
| `aws_launch_template` | Launch template for self-managed EKS worker nodes |
| `aws_autoscaling_group` | Worker node capacity management |
| `aws_iam_role` + `aws_iam_instance_profile` (nodes) | Node IAM permissions and instance profile |
| `aws_security_group` (nodes) | Security group for EKS workers |
| `aws_security_group` (pods) | Security group for EKS pods (custom networking) |
| `aws_security_group` (alb shared backend) | Shared backend SG used by ALB controller-managed backends |
| `aws_vpc_security_group_ingress_rule`/`egress_rule` (pods) | Pod SG rules: self, nodes, and control plane |
| `aws_eks_cluster` | EKS control plane with API auth mode and network settings |
| `aws_iam_role` (cluster) + policy attachments | IAM role used by EKS control plane |
| `aws_eks_access_entry` + `aws_eks_access_policy_association` | IAM principal access mapping for nodes and admins |
| `aws_iam_openid_connect_provider` (eks) | OIDC provider for Kubernetes service account federation |
| `data.tls_certificate` (eks) | Cluster OIDC certificate thumbprint discovery |
| `aws_vpc_security_group_ingress_rule`/`egress_rule` (control plane) | Enables control plane and node communication |
| `aws_eks_addon` (vpc-cni) | VPC CNI addon with custom networking and prefix delegation |
| `aws_iam_role` (vpc-cni) | Pod identity IAM role for VPC CNI service account |
| `aws_iam_policy` + `aws_iam_role` (alb controller) | IAM permissions and role for AWS Load Balancer Controller |
| `aws_eks_pod_identity_association` (alb controller) | Binds ALB controller service account to IAM role |
| `aws_eks_addon` (coredns) | CoreDNS addon with autoscaling |
| `aws_eks_addon` (kube-proxy) | kube-proxy addon configured in nftables mode |
| `aws_eks_addon` (pod-identity-agent) | EKS Pod Identity Agent addon |
| `aws_ssm_service_setting` | Default EC2 instance management role for SSM |
| `aws_iam_role` (ssm) | IAM role used by SSM managed instances |
| `data.aws_ssm_parameter` (Bottlerocket AMI) | Resolves latest node AMI by EKS version/architecture |
| `data.aws_ec2_instance_type` | Validates node instance type details |

## Usage

### Normal workflow

```bash
cd IaC
terragrunt run --all -- plan
terragrunt run --all -- apply
```

### First-time initialization

```bash
cd IaC/demo-core

tofu init
tofu plan
tofu apply

# Enable plaintext fallback for state migration
sed -i 's/plaintext_fallback_enabled = false/plaintext_fallback_enabled = true/g' terragrunt.hcl
terragrunt apply

# Disable plaintext fallback
sed -i 's/plaintext_fallback_enabled = true/plaintext_fallback_enabled = false/g' terragrunt.hcl

cd ..
terragrunt run --all -- plan
terragrunt run --all -- apply
```

## Configuration

Terragrunt reads shared settings from `config.hcl`, which loads values from `config.yaml` and renders the backend configuration for each stack.

### Config Keys

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
| `eks.service_cidr` | `10.254.0.0/16` | Kubernetes service CIDR (used in VPC CNI SNAT exclusions) |
| `eks.nodes` | map of groups | Node groups (e.g., core, app) with capacity and settings |
| `common_tags` | `Project`, `Environment`, `Owner` | Default tags applied to resources |

### Node Groups Configuration

Node groups are defined as a map under `eks.nodes`. Each group specifies:

```yaml
eks:
  nodes:
    core:
      desired_capacity: 1
      max_capacity: 2
      min_capacity: 1
      type: t4g.small
      labels:
        role.core: "yes"
      taints:
        "role.core": ["true:NoSchedule"]
      max_pods: 16
```

Supports both map-based format (above) and legacy single-group format for backward compatibility.

### Module Variables

| Variable | Default | Description |
|---|---|---|
| `config_file` | `../config.yaml` | Path to the YAML config consumed by the module |
| `public_access_cidrs` | `["0.0.0.0/32"]` | CIDR blocks allowed to access the EKS cluster endpoint |
| `admin_user_arns` | `[]` | IAM user or role ARNs granted admin access to the EKS cluster |
