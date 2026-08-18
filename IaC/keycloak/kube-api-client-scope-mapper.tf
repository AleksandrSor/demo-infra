# OIDC token mappers for kube-api client scope
# Reference: https://www.keycloak.org/docs/latest/server_admin/#_protocol-mappers

resource "keycloak_openid_user_attribute_protocol_mapper" "kube_api_username" {
  realm_id        = keycloak_realm.realm.id
  client_scope_id = keycloak_openid_client_scope.kube_api.id
  name            = "username"

  user_attribute = "username"
  claim_name     = "username"

  add_to_access_token = true
  add_to_id_token     = true
  add_to_userinfo     = true
}

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
  add_to_userinfo     = true
}

resource "keycloak_openid_audience_protocol_mapper" "audience_mapper" {
  realm_id        = keycloak_realm.realm.id
  client_scope_id = keycloak_openid_client_scope.kube_api.id
  name            = "audience-mapper-client-id"

  included_client_audience = keycloak_openid_client.kube_api.client_id
  add_to_access_token      = true
  add_to_id_token          = true
}