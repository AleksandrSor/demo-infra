locals {
  admin_users_arn = compact([
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root",
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/${var.tf_extra_admin_user}"
  ])
}