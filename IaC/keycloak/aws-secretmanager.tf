provider "aws" {
  region = local.config.env.region # Change to your preferred region

  default_tags {
    tags = local.config.common_tags
  }
}

module "aws_secretmanager" {
  source = "./modules/aws-secretmanager"

  client_secret_version = local.client_secret_version
  oidc_client_config = {
    name        = "${local.config.project.name}-keycloak"
    client_id   = keycloak_openid_client.kube_api.client_id
    issuer_url = "keycloak_openid_client.kube_api.issuer_url"
  }
}