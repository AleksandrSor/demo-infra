include "root" {
  path           = find_in_parent_folders("root.hcl")
  merge_strategy = "deep"
}

inputs = {
  realm_url = "${get_env("KEYCLOAK_URL")}${get_env("KEYCLOAK_BASE_PATH")}/realms/${get_env("KEYCLOAK_REALM")}"
}