provider "aws" {
  region = local.config.env.region # Change to your preferred region

  default_tags {
    tags = local.config.common_tags
  }
}

module "aws_secretmanager" {
  source         = "./modules/aws-secretmanager"
  secret_name    = local.client_config.name
  secret_version = local.client_secret_version
  secret_value = jsonencode({
    name          = local.client_config.name
    client_id     = local.client_config.client_id
    client_secret = ephemeral.random_password.kube_api_client_secret.result
    issuer_url    = local.client_config.issuer_url
    audience      = local.client_config.audience

    groups_claim  = local.client_config.groups_claim
    groups_prefix = local.client_config.groups_prefix

    username_claim  = local.client_config.username_claim
    username_prefix = local.client_config.username_prefix

    required_claims = local.client_config.required_claims
  })
}