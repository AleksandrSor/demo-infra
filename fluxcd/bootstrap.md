
```bash
helm install flux-operator oci://ghcr.io/controlplaneio-fluxcd/charts/flux-operator \
  --namespace flux-system \
  --create-namespace
```

```bash
kubectl create secret generic demo-infra \
  --namespace=flux-system \
  --from-literal=githubAppID=4159512 \
  --from-literal=githubAppInstallationID=142927928 \
  --from-file=githubAppPrivateKey=./tmp/flux/flux-cd-source-controller.2026-06-27.private-key.pem
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
    ref: "refs/heads/feature/fluxcd"
    path: "fluxcd/clusters/prod"
    pullSecret: "demo-infra"
EOF
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
    ref: "refs/heads/feature/fluxcd"
    path: "fluxcd/demo-infra-cluster"
    pullSecret: "demo-infra"
    provider: github
    interval: 5m
EOF
```