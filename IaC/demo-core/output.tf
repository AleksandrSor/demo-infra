output "account_id" {
  value = data.aws_caller_identity.current.account_id
}

output "aws_region" {
  value = data.aws_region.current.region
}

output "kms_key_id" {
  value = aws_kms_key.tf_state.key_id
}

output "kms_key_alias" {
  value = aws_kms_alias.tf_state.name
}

output "tf_user_arn" {
  value = aws_iam_user.tf_user.arn
}

output "tf_execute_role_arn" {
  value = aws_iam_role.tf_execution_role.arn
}

output "s3_bucket_name" {
  value = aws_s3_bucket.tf_state.bucket_domain_name
}