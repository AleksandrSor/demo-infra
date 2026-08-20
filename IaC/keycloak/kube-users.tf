# Provisioned admin users
# Reference: https://www.keycloak.org/docs/latest/server_admin/index.html#assembly-managing-users_server_administration_guide

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