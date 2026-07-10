locals {
  externaldns_namespace       = "external-dns"
  externaldns_service_account = "external-dns"
}

data "aws_iam_policy_document" "externaldns_assume_role" {
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
      values   = [local.externaldns_namespace]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/kubernetes-service-account"
      values   = [local.externaldns_service_account]
    }
  }
}

resource "aws_iam_role" "externaldns_role" {
  name               = "${local.config.project.name}-externaldns-addon"
  assume_role_policy = data.aws_iam_policy_document.externaldns_assume_role.json
}

data "aws_iam_policy_document" "externaldns_policy" {
  statement {
    effect = "Allow"

    actions = [
      "route53:ChangeResourceRecordSets",
      "route53:ListResourceRecordSets",
      "route53:ListTagsForResources"
    ]

    resources = [
      for zone in aws_route53_zone.managed : zone.arn
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "route53:ListHostedZones",
      "route53:ListHostedZonesByName"
    ]

    resources = ["*"]
  }
}

resource "aws_iam_policy" "externaldns_policy" {
  name   = "${local.config.project.name}-externaldns-policy"
  policy = data.aws_iam_policy_document.externaldns_policy.json
}

resource "aws_iam_role_policy_attachment" "externaldns_policy_attachment" {
  role       = aws_iam_role.externaldns_role.name
  policy_arn = aws_iam_policy.externaldns_policy.arn
}

resource "aws_eks_pod_identity_association" "example" {
  cluster_name    = var.eks_cluster_name
  namespace       = local.externaldns_namespace
  service_account = local.externaldns_service_account
  role_arn        = aws_iam_role.externaldns_role.arn
}

output "externaldns_role_arn" {
  description = "The ARN of the IAM role for ExternalDNS"
  value       = aws_iam_role.externaldns_role.arn
}