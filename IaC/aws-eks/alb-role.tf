locals {
  # Reference: https://github.com/kubernetes-sigs/aws-load-balancer-controller/tree/main/helm/aws-load-balancer-controller#setup-iam-for-serviceaccount
  alb_policy_url      = "https://raw.githubusercontent.com/kubernetes-sigs/aws-alb-ingress-controller/main/docs/install/iam_policy.json"
  alb_namespace       = "kube-system"
  alb_service_account = "aws-load-balancer-controller"
}

data "http" "alb_iam_policy_source" {
  url = local.alb_policy_url

  # Optional: Handle request headers if your URL requires authentication
  request_headers = {
    Accept = "application/json"
  }
}

resource "aws_iam_policy" "alb_load_balancer_controller" {
  name        = "${local.config.project.name}-alb-controller-policy"
  description = "IAM policy for AWS ALB Load Balancer Controller"
  policy      = data.http.alb_iam_policy_source.response_body
}

data "aws_iam_policy_document" "alb_assume_role" {
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
      values   = [local.alb_namespace]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/kubernetes-service-account"
      values   = [local.alb_service_account]
    }
  }
}

resource "aws_iam_role" "alb_controller_role" {
  name               = "${local.config.project.name}-alb-controller-role"
  assume_role_policy = data.aws_iam_policy_document.alb_assume_role.json
}

resource "aws_iam_role_policy_attachment" "alb_controller_role_attachment" {
  policy_arn = aws_iam_policy.alb_load_balancer_controller.arn
  role       = aws_iam_role.alb_controller_role.name
}

resource "aws_eks_pod_identity_association" "alb_controller" {
  cluster_name    = aws_eks_cluster.cluster.name
  role_arn        = aws_iam_role.alb_controller_role.arn
  namespace       = local.alb_namespace
  service_account = local.alb_service_account
}

output "alb_controller_role_arn" {
  value       = aws_iam_role.alb_controller_role.arn
  description = "ARN of the IAM role for AWS ALB Load Balancer Controller"
}