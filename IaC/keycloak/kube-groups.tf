# Groups in Keycloak manage a common set of attributes and role mappings for each user.
# Reference: https://www.keycloak.org/docs/latest/server_admin/index.html#proc-managing-groups_server_administration_guide

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
