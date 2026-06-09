data "aws_eks_addon_version" "latest_kube_proxy" {
  addon_name         = "kube-proxy"
  kubernetes_version = aws_eks_cluster.cluster.version
  most_recent        = true
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name  = aws_eks_cluster.cluster.name
  addon_name    = "kube-proxy"
  addon_version = data.aws_eks_addon_version.latest_kube_proxy.version

  configuration_values = jsonencode({
    "mode" = "nftables"
    # "conntrack"           = { #TODO: add conntrack settings then AWS EKS supports it, currently it is not supported and will cause error "InvalidParameterException: Unsupported configuration value for addon kube-proxy: conntrack"
    #   "maxPerCore"       = 0
    #   "min"              = 0
    # }
  })

  resolve_conflicts_on_update = "OVERWRITE"
}