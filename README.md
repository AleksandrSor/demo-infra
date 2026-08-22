# demo-infra

Demo Infrastructure as Code (IaC) project to provision AWS resources for a fullstack demo application.

Built with [OpenTofu](https://opentofu.org/) and [Flux v2](https://fluxcd.io/) for GitOps, managed inside a dev container.


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
│   ├── keycloak/               # Keycloak realm, groups, and user provisioning
│   └── aws-route53-and-certs/  # Route53 hosted zones, ACM certificates, and ExternalDNS IAM
├── fluxcd/                     # Flux v2 configuration (see fluxcd/README.md)
│   ├── clusters/               # Cluster-specific configurations
│   ├── infra/                  # Infrastructure components
│   └── app/                    # Application deployments
├── docs/                       # Articles and technical write-ups (see docs/README.md)
│   └── articles/               # In-depth guides (e.g. OIDC JWT validation)
├── .pre-commit-config.yaml     # Pre-commit hooks
└── README.md                   # This file
```

## Support & Documentation

- [docs/articles/oidc/oidc-jwt-validation.md](docs/articles/oidc/oidc-jwt-validation.md) — OIDC JWT validation with ALB controller and Gateway API
- [docs/articles/oidc/oidc-keycloak.md](docs/articles/oidc/oidc-keycloak.md) — OIDC with Keycloak and ALB Gateway API
- [.github/workflows/README.md](.github/workflows/README.md) — CI/CD workflows
- [fluxcd/README.md](fluxcd/README.md) — GitOps deployment
- [fluxcd/bootstrap.md](fluxcd/bootstrap.md) — Flux initialization steps

---

## License

See LICENSE file for details.
