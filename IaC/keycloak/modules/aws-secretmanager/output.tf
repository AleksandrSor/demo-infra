output "keycloak_secret_id" {
  value = aws_secretsmanager_secret.keycloak-oidc-config.id
}

output "keycloak_sercet_arn" {
  value = aws_secretsmanager_secret.keycloak-oidc-config.arn
}