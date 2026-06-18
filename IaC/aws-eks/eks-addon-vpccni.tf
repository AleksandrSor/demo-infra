locals {
  vpc_cni_policy_arn      = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  vpc_cni_namespace       = "kube-system"
  vpc_cni_service_account = "aws-node"
  eniConfig = {
    create = true
    region = local.config.env.region
    subnets = {
      for subnet_name, subnet in aws_subnet.pod_subnet : local.config.network.pod_subnets[subnet_name].az => {
        id             = subnet.id
        securityGroups = [aws_security_group.eks_pods.id]
      }
    }
  }
}

data "aws_eks_addon_version" "latest_vpc_cni" {
  addon_name         = "vpc-cni"
  kubernetes_version = aws_eks_cluster.cluster.version
  most_recent        = true
}

resource "aws_eks_addon" "vpc_cni" {
  cluster_name  = aws_eks_cluster.cluster.name
  addon_name    = "vpc-cni"
  addon_version = data.aws_eks_addon_version.latest_vpc_cni.version

  configuration_values = jsonencode({
    env = {
      AWS_VPC_K8S_CNI_EXTERNALSNAT       = "false"
      AWS_VPC_K8S_CNI_CUSTOM_NETWORK_CFG = "true"
      ENI_CONFIG_LABEL_DEF               = "topology.kubernetes.io/zone"
      ENABLE_PREFIX_DELEGATION           = "true"
      ENABLE_SUBNET_DISCOVERY            = "false"
      AWS_VPC_K8S_CNI_EXCLUDE_SNAT_CIDRS = "${local.config.eks.service_cidr},${local.config.network.vpc_cidr},${local.config.network.vpc_secondary_cidr}"
    }
    eniConfig = local.eniConfig
  })

  pod_identity_association {
    role_arn        = aws_iam_role.vpc_cni_role.arn
    service_account = local.vpc_cni_service_account
  }

  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [
    aws_iam_role_policy_attachment.vpc_cni_role_attachment_AmazonEKS_CNI_Policy,
    aws_vpc_security_group_egress_rule.eks_pods_allow_control_plane,
    aws_vpc_security_group_egress_rule.eks_control_plane_allow_pods,
    aws_vpc_security_group_ingress_rule.eks_control_plane_allow_pods
  ]
}

data "aws_iam_policy_document" "vpc_cni_assume_role" {
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
      values   = [local.vpc_cni_namespace]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/kubernetes-service-account"
      values   = [local.vpc_cni_service_account]
    }
  }
}

resource "aws_iam_role" "vpc_cni_role" {
  name               = "${local.config.project.name}-vpc-cni-addon"
  assume_role_policy = data.aws_iam_policy_document.vpc_cni_assume_role.json
}

resource "aws_iam_role_policy_attachment" "vpc_cni_role_attachment_AmazonEKS_CNI_Policy" {
  policy_arn = local.vpc_cni_policy_arn
  role       = aws_iam_role.vpc_cni_role.name
}