data "aws_eks_addon_version" "latest_coredns" {
  addon_name         = "coredns"
  kubernetes_version = aws_eks_cluster.cluster.version
  most_recent        = true
}

resource "aws_eks_addon" "coredns" {
  cluster_name  = aws_eks_cluster.cluster.name
  addon_name    = "coredns"
  addon_version = data.aws_eks_addon_version.latest_coredns.version

  configuration_values = jsonencode({
    autoScaling = {
      enabled     = true
      minReplicas = max(try(local.config.eks.nodes.min_capacity, 0), 2)
      maxReplicas = try(local.config.eks.nodes.max_capacity, 2)
    }
  })

  resolve_conflicts_on_update = "OVERWRITE"

  # Minimize wait windows to force progress if it hungs due to no nodes available
  timeouts {
    create = "2m"
    update = "2m"
  }

  depends_on = [aws_autoscaling_group.eks_nodes, aws_eks_addon.vpc_cni]
}