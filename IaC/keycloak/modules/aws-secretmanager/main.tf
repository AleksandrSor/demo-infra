resource "aws_secretsmanager_secret" "keycloak-oidc-config" {
  name = var.oidc_client_config.name
}

resource "aws_secretsmanager_secret_version" "keycloak-oidc-config" {
  secret_id                = aws_secretsmanager_secret.keycloak-oidc-config.id
  secret_string_wo         = jsonencode(var.oidc_client_config)
  secret_string_wo_version = var.client_secret_version
}