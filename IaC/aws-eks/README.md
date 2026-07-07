# AWS EKS Stack

Self-managed EKS cluster with custom networking, multiple node groups, and managed add-ons.

## Quick Start

```bash
cd /workspaces/demo-infra/IaC/aws-eks

# Review and plan
terragrunt plan

# Apply
terragrunt apply
```

## Networking

- **Primary VPC CIDR**: `10.10.0.0/16` (configurable via `network.vpc_cidr`)
- **Secondary Pod CIDR**: `100.64.0.0/16` (configurable via `network.vpc_secondary_cidr`)
- **Service CIDR**: `10.254.0.0/16` (configurable via `eks.service_cidr`)

### Subnets

- **Node Subnets**: Worker node placement (public routing)
- **Pod Subnets**: Custom networking for pod IPs (private routing)
- **ALB Subnets**: Application Load Balancer ingress (public routing with ACL guardrails)
- **NLB Subnets**: Network Load Balancer ingress (private routing)

## Node Groups

Node groups are defined in `config.yaml` under `eks.nodes` as a map of groups:

```yaml
eks:
  nodes:
    core:
      desired_capacity: 1
      type: t4g.small
      labels:
        role.core: "yes"
      taints:
        role.core: ["true:NoSchedule"]
    app:
      desired_capacity: 1
      type: t4g.nano
      labels:
        role.app: "yes"
      taints:
        role.app: ["true:NoSchedule"]
```

Each group generates:
- Dedicated launch template (per instance type and node configuration)
- Dedicated Auto Scaling Group
- Custom Bottlerocket user data with labels and taints

## EKS Add-ons

Managed add-ons with custom configuration and autoscaling:

- **vpc-cni**: Custom networking, prefix delegation, pod identity
- **coredns**: Autoscaling (replica count based on total node capacity), node affinity, tolerations
- **kube-proxy**: nftables mode
- **pod-identity-agent**: EKS Pod Identity Agent for IRSA

## ALB Load Balancer Controller

IAM role and pod identity association for AWS Load Balancer Controller:
- Pulls IAM policy from GitHub repository
- Binds service account to IAM role via pod identity

## Security Groups

- **Node Security Group**: Intra-node and control plane communication
- **Pod Security Group**: Pod-to-pod, pod-to-node, and pod-to-control-plane communication
- **ALB Shared Backend Security Group**: Backend targets for ALB-managed load balancers

## Files Reference

See parent directory README for detailed file descriptions.
