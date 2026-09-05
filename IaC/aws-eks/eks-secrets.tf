resource "aws_secretsmanager_secret" "env_params" {
  name = "${local.config.project.name}-env-params"
}

resource "aws_secretsmanager_secret_version" "env_params" {
  secret_id = aws_secretsmanager_secret.env_params.id
  secret_string = jsonencode({
    projectName  = local.config.project.name
    region       = data.aws_region.current.region
    commonDomain = local.config.env.commonDomain
  })
}

