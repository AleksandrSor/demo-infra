# Clients are entities that can request authentication of a user.
# Reference: https://www.keycloak.org/docs/latest/server_admin/#_oidc_clients

locals {
  client_secret_version = 10
}

ephemeral "random_password" "kube_api_client_secret" {
  length  = 86
  special = false
}

resource "keycloak_openid_client" "kube_api" {
  realm_id  = keycloak_realm.realm.id
  client_id = "${local.config.project.name}-kube-api"
  name      = "${local.config.project.name}-kube-api"

  enabled = true

  access_type = "CONFIDENTIAL"

  client_authenticator_type = "client-secret"
  client_secret_wo          = ephemeral.random_password.kube_api_client_secret.result
  client_secret_wo_version  = local.client_secret_version


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
}