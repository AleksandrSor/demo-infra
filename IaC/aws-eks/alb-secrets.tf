resource "aws_secretsmanager_secret" "alb_params" {
  name = "${local.config.project.name}-alb-params"
}

resource "aws_secretsmanager_secret_version" "alb_params" {
  secret_id = aws_secretsmanager_secret.alb_params.id
  secret_string = jsonencode({
    backendSecurityGroup = aws_security_group.alb_shared_backend.id
  })
}