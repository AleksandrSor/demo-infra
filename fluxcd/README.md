# Flux CD

Continuous deployment using Flux v2 for GitOps-driven infrastructure and application management.

## Directory Structure

```
fluxcd/
├── bootstrap-flux-operator.yaml   # Bootstrap manifest for Flux Operator
├── bootstrap.md                   # Bootstrap instructions for Flux
├── clusters/
│   └── prod/
│       ├── aws-load-balancer-controller.yaml
│       ├── aws-load-balancer-gateway-customization.yaml
│       ├── envoy-kube-proxy.yaml
│       ├── external-dns.yaml
│       ├── external-secrets-custom.yaml
│       ├── external-secrets.yaml
│       ├── flux-instance.yaml
│       ├── flux-operator.yaml
│       ├── README.md
│       └── webapp.yaml
├── infra/
│   ├── aws-load-balancer-controller/
│   │   ├── base/
│   │   └── prod/
│   ├── aws-load-balancer-gateway-customization/
│   │   ├── base/
│   │   └── prod/
│   ├── envoy-kube-proxy/
│   │   ├── base/
│   │   ├── gateway/
│   │   ├── prod/
│   │   └── rbac/
│   ├── external-dns/
│   │   ├── base/
│   │   └── prod/
│   ├── external-secrets/
│   │   ├── base/
│   │   └── prod/
│   ├── external-secrets-custom/
│   │   ├── base/
│   │   └── prod/
│   ├── flux-instance/
│   │   ├── base/
│   │   └── prod/
│   └── flux-operator/
│       ├── base/
│       └── prod/
└── app/
    └── front/
        └── webapp/
            ├── base/
            ├── dev/
            ├── flux/
            ├── gateway/
            ├── httproute/
            └── prod/
```

## Bootstrap

See [bootstrap.md](./bootstrap.md) for initial Flux installation and configuration.

## Production Configuration

Production cluster Flux configuration is defined in `clusters/prod/` and managed via multiple Kustomization entries such as `flux-instance.yaml`, `flux-operator.yaml`, `aws-load-balancer-controller.yaml`, `envoy-kube-proxy.yaml`, `external-dns.yaml`, `external-secrets.yaml`, and `webapp.yaml`. These include:

- **Kustomizations**: GitOps-driven rendering and reconciliation of platform and app resources
- **Patches**: Environment-specific overrides for deployments and routes
- **Dependencies**: Ordered reconciliation for infrastructure before workloads
- **Runtime configuration**: Production-specific tuning for gateways, controllers, and app settings

### Tolerations

Production workloads can be pinned to control-plane or core node pools using tolerations such as:
- `CriticalAddonsOnly:NoSchedule`
- `role.core:NoSchedule`

### Node Affinity

Critical system components and applications are scheduled against labeled core nodes using node affinity rules.

## Infrastructure Components

Located in `infra/`, these components provide cluster-wide capabilities:

- **flux-operator**: Flux operator installation and control-plane configuration
- **flux-instance**: Cluster-specific Flux instance and reconciliation settings
- **aws-load-balancer-controller**: AWS Load Balancer Controller deployment and tuning
- **aws-load-balancer-gateway-customization**: Gateway API defaults and ALB settings
- **envoy-kube-proxy**: Envoy-based Kubernetes API gateway and proxy configuration
- **external-dns**: DNS record management for public services
- **external-secrets**: Cluster secret synchronization and Kubernetes integration
- **external-secrets-custom**: Custom secret-store and secret wiring for application credentials

## Application Deployments

Located in `app/`, application manifests are organized by service and environment:

- **front/webapp**: Web application workload with `base`, `dev`, `prod`, `gateway`, `httproute`, and `flux` overlays
- **Environment-specific overlays**: Separate kustomize layers for dev and production
- **Ingress/Gateway routing**: HTTPRoute and Gateway configuration for exposed services

## GitOps Workflow

1. Push changes to repository branches
2. Flux reconciles configurations based on branch/environment rules
3. Updates propagate to the cluster automatically
