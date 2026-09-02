resource "aws_secretsmanager_secret" "secret" {
  name = var.secret_name
}

resource "aws_secretsmanager_secret_version" "secret_version" {
  secret_id                = aws_secretsmanager_secret.secret.id
  secret_string_wo         = var.secret_value
  secret_string_wo_version = var.secret_version
}