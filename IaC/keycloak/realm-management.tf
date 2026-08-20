data "keycloak_openid_client" "realm_management" {
  realm_id  = keycloak_realm.realm.id
  client_id = "realm-management"
}

data "keycloak_role" "realm-admin" {
  realm_id  = keycloak_realm.realm.id
  client_id = data.keycloak_openid_client.realm_management.id
  name      = "realm-admin"
}

data "keycloak_role" "query-realms" {
  realm_id  = keycloak_realm.realm.id
  client_id = data.keycloak_openid_client.realm_management.id
  name      = "query-realms"
}