# Reference: https://external-secrets.io/latest/provider/aws-access/

locals {
  eso_namespace       = "external-secrets"
  eso_service_account = "external-secrets"
}

data "aws_iam_policy_document" "eso_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }

    actions = [
      "sts:AssumeRole",
      "sts:TagSession"
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/kubernetes-namespace"
      values   = [local.eso_namespace]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/kubernetes-service-account"
      values   = [local.eso_service_account]
    }
  }
}

resource "aws_iam_role" "eso_role" {
  name               = "${local.config.project.name}-external-secrets-addon"
  assume_role_policy = data.aws_iam_policy_document.eso_assume_role.json
}

# Reference: https://external-secrets.io/latest/provider/aws-secrets-manager/
data "aws_iam_policy_document" "eso_addon" {
  statement {
    effect = "Allow"

    actions = [
      "secretsmanager:ListSecrets",
      "secretsmanager:BatchGetSecretValue"
    ]

    resources = ["*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "secretsmanager:GetResourcePolicy",
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
      "secretsmanager:ListSecretVersionIds"
    ]

    resources = [
      "arn:aws:secretsmanager:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:secret:${local.config.project.name}-*"
    ]
  }
}

resource "aws_iam_policy" "eso_addon" {
  name   = "${local.config.project.name}-external-secrets-addon"
  policy = data.aws_iam_policy_document.eso_addon.json
}

resource "aws_iam_role_policy_attachment" "eso_addon_policy_attachment" {
  role       = aws_iam_role.eso_role.name
  policy_arn = aws_iam_policy.eso_addon.arn
}

resource "aws_eks_pod_identity_association" "eso_addon" {
  cluster_name    = aws_eks_cluster.cluster.name
  namespace       = local.eso_namespace
  service_account = local.eso_service_account
  role_arn        = aws_iam_role.eso_role.arn
}