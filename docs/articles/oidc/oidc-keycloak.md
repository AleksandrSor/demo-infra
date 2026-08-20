# OIDC: JWT validation with ALB controller and Gateway API

![scheme](./oidc-keycloak.png "scheme.")

## Introduction

In my [previous article](./oidc-jwt-validation.md), I tested using ALB CRDs to offload validation of JWTs for OIDC based authentication to the Amazon EKS Kubernetes API.

In this article, I will share the Terraform/OpenTofu stack required to set up Keycloak as the OIDC provider with an explanation.

## Client

[Keycloak clients](https://www.keycloak.org/docs/latest/server_admin/index.html#assembly-managing-clients_server_administration_guide) is an entry point that your OIDC client interacts with to get authentication tokens.

[kube-api-client.tf](https://github.com/AleksandrSor/demo-infra/blob/main/IaC/keycloak/kube-api-client.tf)
```hcl
  realm_id  = keycloak_realm.realm.id
  client_id = "${local.config.project.name}-kube-api"
  name      = "${local.config.project.name}-kube-api"

  enabled = true

  access_type = "CONFIDENTIAL"

  client_authenticator_type = "client-secret"

  standard_flow_enabled                     = true
  implicit_flow_enabled                     = false
  direct_access_grants_enabled              = false
  service_accounts_enabled                  = false
  standard_token_exchange_enabled           = false
  oauth2_jwt_authorization_grant_enabled    = false
  oauth2_device_authorization_grant_enabled = false

  full_scope_allowed = false

  valid_redirect_uris = [
    "http://localhost:8000",
    "http://localhost:18000",
    "https://oauth.pstmn.io/v1/callback",
    "https://oauth.pstmn.io/v1/browser-callback",
  ]

  web_origins = [
    "+",
  ]
```

### explanation

```hcl
access_type = "CONFIDENTIAL"
client_authenticator_type = "client-secret"
```
create non-public client with client secret

```hcl
standard_flow_enabled                     = true
```
enable [Authorization Code Grant flow](https://aaronparecki.com/oauth-2-simplified/)


```hcl
full_scope_allowed = false
```
token contains roles scoped only for this client.


```hcl
valid_redirect_uris = [
    "http://localhost:8000",
    "http://localhost:18000",
    "https://oauth.pstmn.io/v1/callback",
    "https://oauth.pstmn.io/v1/browser-callback",
]
```
redirect urls allowed for standard flow.


``` 
    "http://localhost:8000",
    "http://localhost:18000",
```
for [kubelogin](https://github.com/int128/kubelogin).


```
    "https://oauth.pstmn.io/v1/callback",
    "https://oauth.pstmn.io/v1/browser-callback",
```
for [Postman](https://learning.postman.com/docs/use/send-requests/authorization/oauth-20).


## Client roles

[Client roles](https://www.keycloak.org/docs/latest/server_admin/#con-client-roles_server_administration_guide) dedicated for this client.

[kube-api-client-roles.tf](https://github.com/AleksandrSor/demo-infra/blob/main/IaC/keycloak/kube-api-client-roles.tf)
```hcl
resource "keycloak_role" "kube_api_cluster_admin" {
  realm_id    = keycloak_realm.realm.id
  client_id   = keycloak_openid_client.kube_api.id
  name        = "admin"
  description = "cluster-admin role for kube-api"
}
```
This client-specific role will be included in a role claim of the token if they are assigned to a user.

## Groups

[Groups in Keycloak]() manage role mappings for each user.

kube-groups.tf
```hcl
resource "keycloak_group" "kube_admin" {
  realm_id = keycloak_realm.realm.id
  name     = "kube-admin"
}

resource "keycloak_group_roles" "kube_admin_group_roles" {
  realm_id = keycloak_realm.realm.id
  group_id = keycloak_group.kube_admin.id

  role_ids = [
    keycloak_role.kube_api_cluster_admin.id,
  ]
}
```
I'm mapping client-specific role to a group.

## Users

[Maneging users](https://www.keycloak.org/docs/latest/server_admin/index.html#assembly-managing-users_server_administration_guide).

[kube-users.tf](https://github.com/AleksandrSor/demo-infra/blob/main/IaC/keycloak/kube-users.tf)
```hcl
resource "keycloak_user" "kube_user" {
  realm_id       = keycloak_realm.realm.id
  for_each       = { for user in local.config.keycloak.users : user.username => user }
  username       = each.value.username
  email          = each.value.email
  email_verified = true

  lifecycle {
    ignore_changes = [
      first_name,
      last_name,
    ]
  }
}
```


[kube-user-groups.tf](https://github.com/AleksandrSor/demo-infra/blob/main/IaC/keycloak/kube-user-groups.tf) assign them to groups.
```hcl
resource "keycloak_user_groups" "kube_admin_user_groups" {
  for_each = {
    for user in local.config.keycloak.users : user.username => user
    if contains(try(user.groups, []), keycloak_group.kube_admin.name)
  }
  realm_id   = keycloak_realm.realm.id
  user_id    = keycloak_user.kube_user[each.key].id
  exhaustive = false

  group_ids = [
    keycloak_group.kube_admin.id
  ]
}
```

## Client scope

[Shared client configuration](https://www.keycloak.org/docs/latest/server_admin/#_client_scopes) in an entity called a client scope. In my example, it is simply a set of mappers.

[kube-api-client-scope.tf](https://github.com/AleksandrSor/demo-infra/blob/main/IaC/keycloak/kube-api-client-scope.tf)
```hcl
resource "keycloak_openid_client_scope" "kube_api" {
  realm_id = keycloak_realm.realm.id
  name     = "kube-api"
}
```

## Client scope mappers
OIDC token [mappers](https://www.keycloak.org/docs/latest/server_admin/#_protocol-mappers) for kube-api client scope


[kube-api-client-scope-mapper.tf](https://github.com/AleksandrSor/demo-infra/blob/main/IaC/keycloak/kube-api-client-scope-mapper.tf)

### username mapper
```hcl
resource "keycloak_openid_user_attribute_protocol_mapper" "kube_api_username" {
  realm_id        = keycloak_realm.realm.id
  client_scope_id = keycloak_openid_client_scope.kube_api.id
  name            = "username"

  user_attribute = "username"
  claim_name     = "username"

  add_to_access_token = true
  add_to_id_token     = true
}

```
***add_to_access_token*** - add this mapping to access token

***add_to_id_token*** - add this mapping to OIDC ID token

### role mapper - most important
```hcl
resource "keycloak_openid_user_client_role_protocol_mapper" "kube_api_user_client_role_mapper" {
  realm_id        = keycloak_realm.realm.id
  client_scope_id = keycloak_openid_client_scope.kube_api.id
  name            = "kube-api-roles"

  claim_name       = "roles"
  claim_value_type = "String"
  multivalued      = true

  client_id_for_role_mappings = keycloak_openid_client.kube_api.client_id
  client_role_prefix          = "kube-"

  add_to_access_token = true
  add_to_id_token     = true
}
```
***claim_name***  - claim name

***client_id_for_role_mappings*** - client for roles mapping

***client_role_prefix*** - prefix for role value

As a result, the roles claim contains a flat, single-level list of assigned roles.

### Audience mapper

Mapping the clientID to the audience claim enables [additional token validation](https://github.com/AleksandrSor/demo-infra/blob/6503ff504cf5a4e77697048d20a2c44f8132d2f4/fluxcd/infra/envoy-kube-proxy/prod/ListenerRuleConfiguration.yaml#L11).

```hcl
resource "keycloak_openid_audience_protocol_mapper" "audience_mapper" {
  realm_id        = keycloak_realm.realm.id
  client_scope_id = keycloak_openid_client_scope.kube_api.id
  name            = "audience-mapper-client-id"

  included_client_audience = keycloak_openid_client.kube_api.client_id
  add_to_access_token      = true
  add_to_id_token          = true
}
```

## Role scope mapping

[Role scope mapping](https://www.keycloak.org/docs/latest/server_admin/#_client_scope_mappings) limits the roles declared inside the client access token.

[kube-api-client-scope-roles.tf](https://github.com/AleksandrSor/demo-infra/blob/main/IaC/keycloak/kube-api-client-scope-roles.tf)

```hcl
resource "keycloak_generic_role_mapper" "kube_api_cluster_admin" {
  realm_id        = keycloak_realm.realm.id
  client_scope_id = keycloak_openid_client_scope.kube_api.id
  role_id         = keycloak_role.kube_api_cluster_admin.id
}
```