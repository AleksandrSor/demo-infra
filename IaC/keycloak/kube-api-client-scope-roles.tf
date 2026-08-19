# Role scope mapping allows you to limit the roles that get declared inside an access token for a client.
# Reference: https://www.keycloak.org/docs/latest/server_admin/#_client_scope_mappings

resource "keycloak_generic_role_mapper" "kube_api_cluster_admin" {
  realm_id        = keycloak_realm.realm.id
  client_scope_id = keycloak_openid_client_scope.kube_api.id
  role_id         = keycloak_role.kube_api_cluster_admin.id
}

resource "keycloak_generic_role_mapper" "kube_api_cluster_edit" {
  realm_id        = keycloak_realm.realm.id
  client_scope_id = keycloak_openid_client_scope.kube_api.id
  role_id         = keycloak_role.kube_api_cluster_edit.id
}

resource "keycloak_generic_role_mapper" "kube_api_cluster_view" {
  realm_id        = keycloak_realm.realm.id
  client_scope_id = keycloak_openid_client_scope.kube_api.id
  role_id         = keycloak_role.kube_api_cluster_view.id
}