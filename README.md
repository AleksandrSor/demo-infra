# demo-infra

Demo Infrastructure as Code (IaC) project to provision AWS resources for a fullstack demo application.

Built with [OpenTofu](https://opentofu.org/) and [Flux v2](https://fluxcd.io/) for GitOps, managed inside a dev container.

---

## Quick Links

- **[Infrastructure as Code (IaC)](IaC/README.md)** — OpenTofu/Terragrunt configuration for AWS resources
- **[CI/CD Pipelines](.github/workflows/README.md)** — GitHub Actions workflows for security, validation, and deployment
- **[Flux CD (GitOps)](fluxcd/README.md)** — Continuous deployment configuration
- **[AWS EKS Stack](IaC/aws-eks/README.md)** — Self-managed Kubernetes cluster details
- **[AWS EKS OIDC Stack](IaC/aws-eks-oidc/)** — EKS external OIDC identity provider configuration
- **[Route53 and Certificates Stack](IaC/aws-route53-and-certs/)** — Public DNS hosted zones and ACM certificates

---

## Project Structure

```
demo-infra/
├── .devcontainer/              # Dev container with OpenTofu, AWS CLI, kubectl, Helm
├── .github/
│   └── workflows/              # CI/CD pipelines (see .github/README.md)
├── IaC/                        # Infrastructure as Code (see IaC/README.md)
│   ├── demo-core/              # AWS bootstrap and foundational resources
│   ├── aws-eks/                # EKS cluster, networking, and node groups
│   ├── aws-eks-oidc/           # EKS external OIDC identity provider configuration
│   └── aws-route53-and-certs/  # Route53 hosted zones, ACM certificates, and ExternalDNS IAM
├── fluxcd/                     # Flux v2 configuration (see fluxcd/README.md)
│   ├── clusters/               # Cluster-specific configurations
│   ├── infra/                  # Infrastructure components
│   └── app/                    # Application deployments
├── .pre-commit-config.yaml     # Pre-commit hooks
└── README.md                   # This file
```

---

## Prerequisites

- [Dev Containers](https://containers.dev/) — all tooling is pre-installed
- AWS credentials configured under `.aws/` at workspace root
- Git repository set up for GitOps (GitHub or similar)

---

## Getting Started

### 1. Initialize Infrastructure (First-time only)

```bash
cd IaC/demo-core
tofu init
tofu plan
tofu apply

# Follow state migration steps if needed
cd ..
terragrunt run --all -- plan
terragrunt run --all -- apply
```

See [IaC/README.md](IaC/README.md#first-time-initialization) for detailed steps.

### 2. Deploy Flux CD

```bash
cd fluxcd
# Follow bootstrap.md instructions
```

### 3. Manage Infrastructure

```bash
cd IaC
terragrunt run --all -- plan
terragrunt run --all -- apply
```

---

## Configuration

All configuration is centralized in `IaC/config.yaml`:

- **Networking**: VPC CIDR, subnets, routing
- **EKS**: Cluster version, node groups, add-ons
- **EKS OIDC**: External OIDC identity provider config for Kubernetes API authentication
- **DNS/TLS**: Route53 hosted zones and ACM certificates
- **IAM**: OIDC provider, automation users, roles
- **Tagging**: Default tags for all resources

For detailed configuration options, see [IaC/README.md#configuration](IaC/README.md#configuration).

---

## CI/CD

Automated workflows handle:
- Security scanning (CodeQL, Gitleaks, Trivy)
- Validation (HCL formatting, syntax checks)
- Deployment (Terragrunt apply with OIDC AWS auth)

See [.github/workflows/README.md](.github/workflows/README.md) for workflow details.

---

## Development

### Code Quality

Pre-commit hooks ensure HCL and YAML formatting:

```bash
pre-commit run --all-files
```

### Local Validation

```bash
cd IaC/aws-eks
tofu validate
tofu fmt --recursive
```

---

## Support & Documentation

- [IaC/README.md](IaC/README.md) — Infrastructure resources and modules
- [IaC/aws-eks/README.md](IaC/aws-eks/README.md) — EKS-specific configuration
- [IaC/aws-eks-oidc/](IaC/aws-eks-oidc/) — EKS identity provider configuration stack
- [IaC/aws-route53-and-certs/](IaC/aws-route53-and-certs/) — Route53 and ACM stack
- [.github/workflows/README.md](.github/workflows/README.md) — CI/CD workflows
- [fluxcd/README.md](fluxcd/README.md) — GitOps deployment
- [fluxcd/bootstrap.md](fluxcd/bootstrap.md) — Flux initialization steps

---

## License

See LICENSE file for details.
