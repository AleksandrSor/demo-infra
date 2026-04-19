resource "aws_iam_user" "tf_user" {
  name = "test"
  path = "/test/"
}


// TODO: Refactor it to ephemeral block when terraform supports it, to avoid storing the secret key in state file
resource "aws_iam_access_key" "tf_user_key" {
  user = aws_iam_user.tf_user.name
}

resource "aws_secretsmanager_secret" "tf_user_key_id" {
  name = "tf_user_key_id"
}

resource "aws_secretsmanager_secret_version" "tf_user_key_id" {
  secret_id                = aws_secretsmanager_secret.tf_user_key_id.id
  secret_string_wo         = aws_iam_access_key.tf_user_key.id
  secret_string_wo_version = 1
}

resource "aws_secretsmanager_secret" "tf_user_key_secret" {
  name = "tf_user_key_secret"
}

resource "aws_secretsmanager_secret_version" "tf_user_key_secret" {
  secret_id                = aws_secretsmanager_secret.tf_user_key_secret.id
  secret_string_wo         = aws_iam_access_key.tf_user_key.secret
  secret_string_wo_version = 1
}