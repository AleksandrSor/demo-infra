
```bash
helm install flux-operator oci://ghcr.io/controlplaneio-fluxcd/charts/flux-operator \
  --namespace flux-system \
  -f bootstrap-flux-operator.yaml
  --create-namespace
```

```bash
kubectl create secret generic demo-infra \
  --namespace=flux-system \
  --from-literal=githubAppID=<GITHUB_APP_ID> \
  --from-literal=githubAppInstallationID=<GITHUB_APP_INSTALLATION_ID> \
  --from-file=githubAppPrivateKey=/path/to/github-app.private-key.pem
```

```bash
kubectl apply -f - <<EOF
apiVersion: fluxcd.controlplane.io/v1
kind: FluxInstance
metadata:
  name: flux
  namespace: flux-system
spec:
  distribution:
    version: "2.8.x"
    registry: "ghcr.io/fluxcd"
  components:
    - source-controller
    - source-watcher
    - kustomize-controller
    - helm-controller
    - notification-controller
  cluster:
    type: kubernetes
    multitenant: false
    networkPolicy: true
    domain: "cluster.local"
  sync:
    kind: GitRepository
    url: "https://github.com/AleksandrSor/demo-infra.git"
    ref: "refs/heads/prod"
    path: "fluxcd/clusters/prod"
    pullSecret: "demo-infra"
    provider: github
    interval: 5m
  kustomize:  
    patches:
      - target:
          kind: Deployment
        patch: |-
          apiVersion: apps/v1
          kind: Deployment
          metadata:
            name: all
          spec:
            template:
              spec:
                affinity:
                  nodeAffinity:
                    requiredDuringSchedulingIgnoredDuringExecution:
                      nodeSelectorTerms:
                        - matchExpressions:
                            - key: role.core
                              operator: Exists
                tolerations:
                  - key: CriticalAddonsOnly
                    operator: Exists
                    effect: NoSchedule
                  - key: role.core
                    operator: Exists
                    effect: NoSchedule
EOF
```