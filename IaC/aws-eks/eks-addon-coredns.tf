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
      minReplicas = max(try(local.config.eks.nodes["core"].min_capacity, 0), 2)
      maxReplicas = try(local.config.eks.nodes["core"].max_capacity, 2)
      minReplicas = 2
      maxReplicas = 5
    }
    affinity = {
      nodeAffinity = {
        requiredDuringSchedulingIgnoredDuringExecution = {
          nodeSelectorTerms = [{
            matchExpressions = [{
              key      = "role.core"
              operator = "Exists"
            }]
          }]
        }
      }
    }
    tolerations = [
      {
        key      = "CriticalAddonsOnly"
        operator = "Exists"
        effect   = "NoSchedule"
      },
      {
        key      = "role.core"
        operator = "Exists"
        effect   = "NoSchedule"
      }
    ]
  })

  resolve_conflicts_on_update = "OVERWRITE"

  # Minimize wait windows to force progress if it hungs due to no nodes available
  timeouts {
    create = "2m"
    update = "2m"
  }

  depends_on = [aws_autoscaling_group.eks_nodes, aws_eks_addon.vpc_cni]
}