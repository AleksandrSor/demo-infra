TODO: implement ESO for secrets

Do not forget to create secrets for variable substitution

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: env-params
  namespace: flux-system
type: Opaque
stringData:
  commonDomain: "example.com"
---
apiVersion: v1
kind: Secret
metadata:
  name: alb-params
  namespace: flux-system
type: Opaque
stringData:
  backendSecurityGroup: "<your_sg_group_id_here_for_shared_backend>"
---
apiVersion: v1
kind: Secret
metadata:
  name: oidc-params
  namespace: flux-system
type: Opaque
stringData:
  jwksEndpoint: "https://<keycloak_url>/auth/realms/<keycloak_realm>//protocol/openid-connect/certs"
  issuer: "https://<keycloak_url>/auth/realms/<keycloak_realm>"
  aud: "<token_audience>"
```