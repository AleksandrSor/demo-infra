resource "aws_iam_user" "tf_user" {

  name = local.config.env.tf_user.name
  path = local.config.env.tf_user.path

}


// TODO: Refactor it to ephemeral block when terraform supports it, to avoid storing the secret key in state file
resource "aws_iam_access_key" "tf_user_key" {
  user = aws_iam_user.tf_user.name
}

resource "aws_secretsmanager_secret" "tf_user_key_id" {
  name = "tf-user-${local.config.project.name}-key-id"

  kms_key_id = aws_kms_alias.tf_state.name

}

resource "aws_secretsmanager_secret_version" "tf_user_key_id" {
  secret_id                = aws_secretsmanager_secret.tf_user_key_id.id
  secret_string_wo         = aws_iam_access_key.tf_user_key.id
  secret_string_wo_version = 1
}

resource "aws_secretsmanager_secret" "tf_user_key_secret" {
  name = "tf-user-${local.config.project.name}-key-secret"

  kms_key_id = aws_kms_alias.tf_state.name

}

resource "aws_secretsmanager_secret_version" "tf_user_key_secret" {
  secret_id                = aws_secretsmanager_secret.tf_user_key_secret.id
  secret_string_wo         = aws_iam_access_key.tf_user_key.secret
  secret_string_wo_version = 1
}