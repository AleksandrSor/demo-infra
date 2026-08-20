# Shared client configuration in an entity called a client scope
# Reference: https://www.keycloak.org/docs/latest/server_admin/#_client_scopes

resource "keycloak_openid_client_scope" "kube_api" {
  realm_id = keycloak_realm.realm.id
  name     = "kube-api"

  include_in_token_scope              = true
  include_in_openid_provider_metadata = true
}

data "keycloak_openid_client_scope" "acr" {
  realm_id = keycloak_realm.realm.id
  name     = "acr"
}

data "keycloak_openid_client_scope" "basic" {
  realm_id = keycloak_realm.realm.id
  name     = "basic"
}

data "keycloak_openid_client_scope" "web_origins" {
  realm_id = keycloak_realm.realm.id
  name     = "web-origins"
}

resource "keycloak_openid_client_default_scopes" "kube_api" {
  realm_id  = keycloak_realm.realm.id
  client_id = keycloak_openid_client.kube_api.id

  default_scopes = [
    data.keycloak_openid_client_scope.acr.name,
    data.keycloak_openid_client_scope.basic.name,
    data.keycloak_openid_client_scope.web_origins.name,
    keycloak_openid_client_scope.kube_api.name,
  ]
}

resource "keycloak_openid_client_optional_scopes" "kube_api" {
  realm_id  = keycloak_realm.realm.id
  client_id = keycloak_openid_client.kube_api.id

  optional_scopes = [

  ]
}