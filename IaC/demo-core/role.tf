data "aws_iam_policy_document" "tf_execution_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "AWS"
      identifiers = concat(local.admin_user_arns, [aws_iam_user.tf_user.arn])
    }
  }
}

resource "aws_iam_role" "tf_execution_role" {
  name               = local.config.env.tf_role_name
  assume_role_policy = data.aws_iam_policy_document.tf_execution_role_policy.json
}

data "aws_iam_policy_document" "tf_kms_user_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "tf_kms_user_role" {
  name = "kms-encryption-role-${local.config.project.name}"

  assume_role_policy = data.aws_iam_policy_document.tf_kms_user_role_policy.json
}
