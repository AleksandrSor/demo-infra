# Client Roles for kube-api client
# Reference: https://www.keycloak.org/docs/latest/server_admin/#con-client-roles_server_administration_guide

resource "keycloak_role" "kube_api_cluster_admin" {
  realm_id    = keycloak_realm.realm.id
  client_id   = keycloak_openid_client.kube_api.id
  name        = "admin"
  description = "cluster-admin role for kube-api"
}

resource "keycloak_role" "kube_api_cluster_edit" {
  realm_id    = keycloak_realm.realm.id
  client_id   = keycloak_openid_client.kube_api.id
  name        = "edit"
  description = "cluster-edit role for kube-api"
}

resource "keycloak_role" "kube_api_cluster_view" {
  realm_id    = keycloak_realm.realm.id
  client_id   = keycloak_openid_client.kube_api.id
  name        = "view"
  description = "cluster-view role for kube-api"
}