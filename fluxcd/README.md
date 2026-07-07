# Flux CD

Continuous deployment using Flux v2 for GitOps-driven infrastructure and application management.

## Directory Structure

```
fluxcd/
├── bootstrap.md       # Bootstrap instructions for Flux
├── clusters/          # Cluster-specific Flux configurations (prod, staging, etc.)
│   └── prod/          # Production cluster configuration
│       └── flux-instance.yaml  # Flux instance with patches and kustomizations
├── infra/             # Infrastructure components (addons, operators)
│   ├── flux-instance/
│   ├── flux-operator/
│   └── ...
└── app/               # Application deployments
    ├── front/         # Frontend applications
    ├── back/          # Backend services
    └── ...
```

## Bootstrap

See [bootstrap.md](./bootstrap.md) for initial Flux installation and configuration.

## Production Configuration

Production cluster Flux configuration is defined in `clusters/prod/flux-instance.yaml`, which includes:

- **Kustomizations**: GitOps-driven resource rendering and application
- **Patches**: Cross-cutting modifications to Deployments (e.g., tolerations, affinity)
- **Dependencies**: Ordered reconciliation of components

### Tolerations

All Deployments in the production cluster receive the following tolerations:
- `CriticalAddonsOnly:NoSchedule`
- `role.core:NoSchedule` (for core node taints)

### Node Affinity

Deployments are scheduled with node affinity preferences for labeled nodes.

## Infrastructure Components

Located in `infra/`, these components provide cluster-wide capabilities:

- **flux-operator**: Flux control plane and management
- **flux-instance**: Cluster-specific Flux configuration
- Additional operators and system components

## Application Deployments

Located in `app/`, application manifests are organized by service:

- **frontend**: Web UI services
- **backend**: API and service mesh components
- ...

## GitOps Workflow

1. Push changes to repository branches
2. Flux reconciles configurations based on branch/environment rules
3. Updates propagate to the cluster automatically
