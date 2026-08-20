import {
  to = keycloak_realm.realm
  id = local.realm_name
}

resource "keycloak_realm" "realm" {
  realm = local.realm_name

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [login_theme]
  }
}

output "realm_id" {
  value = keycloak_realm.realm.id
}