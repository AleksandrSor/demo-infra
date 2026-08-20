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