locals {
  github_actions_issuer = "https://token.actions.githubusercontent.com"
}

resource "keycloak_kubernetes_identity_provider" "github_actions" {
  alias = "github-actions"
  realm = keycloak_realm.realm.id
  issuer = local.github_actions_issuer

  lifecycle {
    prevent_destroy = true
  }
}

resource "keycloak_openid_client" "github_actions" {
  realm_id = keycloak_realm.realm.id
  client_id = "repo:${local.config.env.repository.name}:environment:${local.config.env.repository.protected_environment}"
  name = "github-actions-${replace(local.config.env.repository.name, "/[^a-zA-Z0-9]/", "-")}-env-${local.config.env.repository.protected_environment}"
  enabled = true
  access_type = "CONFIDENTIAL"
  standard_flow_enabled = false
  direct_access_grants_enabled = false
  service_accounts_enabled = true
  client_authenticator_type = "federated-jwt"

  extra_config = {
    "jwt.credential.issuer" = keycloak_kubernetes_identity_provider.github_actions.alias
    "jwt.credential.sub" = "repo:${local.config.env.repository.name}:environment:${local.config.env.repository.protected_environment}"
  }

  description = jsonencode(local.config.common_tags)

}

resource "keycloak_openid_client_service_account_role" "github_actions_service_account_role_realm_admin" {
  realm_id                = keycloak_realm.realm.id
  service_account_user_id = keycloak_openid_client.github_actions.service_account_user_id
  client_id               = data.keycloak_openid_client.realm_management.id
  role                    = data.keycloak_role.realm-admin.name
}

resource "keycloak_openid_client_service_account_role" "github_actions_service_account_role_query_realms" {
  realm_id                = keycloak_realm.realm.id
  service_account_user_id = keycloak_openid_client.github_actions.service_account_user_id
  client_id               = data.keycloak_openid_client.realm_management.id
  role                    = data.keycloak_role.query-realms.name
}