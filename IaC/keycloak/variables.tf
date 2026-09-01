locals {

  config = yamldecode(file(var.config_file))

  realm_name = local.config.keycloak.realm

  client_config = {
    name       = "${local.config.project.name}-keycloak"
    client_id  = keycloak_openid_client.kube_api.client_id
    issuer_url = var.realm_url
    audience   = ["${keycloak_openid_client.kube_api.client_id}"]

    groups_claim  = "roles"
    groups_prefix = "oidc:"

    username_claim  = "username"
    username_prefix = "oidc-"

    required_claims = tomap({})
  }
}

variable "config_file" {
  type    = string
  default = "../config.yaml"
}

variable "realm_url" {
  type        = string
  description = "The URL of the Keycloak realm, since it not possible to get it from the Keycloak provider, we need to pass it as a variable"
  default     = "https://keycloak.example.com/auth/realms/realm-name"
}