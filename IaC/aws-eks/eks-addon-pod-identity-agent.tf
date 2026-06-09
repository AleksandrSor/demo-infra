data "aws_eks_addon_version" "latest_pod_identity_agent" {
  addon_name         = "eks-pod-identity-agent"
  kubernetes_version = aws_eks_cluster.cluster.version
  most_recent        = true
}


resource "aws_eks_addon" "pod_identity_agent" {
  cluster_name  = aws_eks_cluster.cluster.name
  addon_name    = "eks-pod-identity-agent"
  addon_version = data.aws_eks_addon_version.latest_pod_identity_agent.version

  resolve_conflicts_on_update = "OVERWRITE"
}