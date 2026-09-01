output "keycloak_secret_id" {
  value = aws_secretsmanager_secret.secret.id
}

output "keycloak_secret_arn" {
  value = aws_secretsmanager_secret.secret.arn
}