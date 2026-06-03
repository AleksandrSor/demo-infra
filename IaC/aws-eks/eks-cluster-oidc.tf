# Get the OIDC issuer URL
locals {
  oidc_issuer_url = aws_eks_cluster.cluster.identity[0].oidc[0].issuer
  oidc_issuer     = replace(local.oidc_issuer_url, "https://", "")
}

# Fetch the thumbprint automatically
data "tls_certificate" "eks" {
  url = local.oidc_issuer_url
}

# Create the OIDC provider for EKS
resource "aws_iam_openid_connect_provider" "eks" {
  url = local.oidc_issuer_url

  client_id_list = ["sts.amazonaws.com"]

  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]

  tags = {
    Cluster = aws_eks_cluster.cluster.name
  }
}

output "eks_oidc_issuer" {
  value = local.oidc_issuer
}

# # Create a role for a Kubernetes service account
# data "aws_iam_policy_document" "eks_pod_trust" {
#   statement {
#     effect = "Allow"

#     principals {
#       type        = "Federated"
#       identifiers = [aws_iam_openid_connect_provider.eks.arn]
#     }

#     actions = ["sts:AssumeRoleWithWebIdentity"]

#     condition {
#       test     = "StringEquals"
#       variable = "${local.oidc_issuer}:sub"
#       values   = ["system:serviceaccount:default:my-app"]
#     }

#     condition {
#       test     = "StringEquals"
#       variable = "${local.oidc_issuer}:aud"
#       values   = ["sts.amazonaws.com"]
#     }
#   }
# }

# resource "aws_iam_role" "eks_pod" {
#   name               = "eks-my-app-pod-role"
#   assume_role_policy = data.aws_iam_policy_document.eks_pod_trust.json
# }