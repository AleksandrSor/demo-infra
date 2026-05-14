data "aws_iam_policy_document" "kms_tf_state_access" {
  # admin users (root and extra admin user) should have full access to the KMS key
  statement {
    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = concat(local.admin_user_arns, [aws_iam_role.tf_execution_role.arn])
    }
  }

  statement {
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.tf_kms_user_role.arn]
    }
  }
}

resource "aws_kms_key" "tf_state" {
  description             = "KMS key for Terraform state encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = data.aws_iam_policy_document.kms_tf_state_access.json
}

resource "aws_kms_alias" "tf_state" {
  name          = "alias/tf-state-${local.config.project.name}-key"
  target_key_id = aws_kms_key.tf_state.key_id
}
