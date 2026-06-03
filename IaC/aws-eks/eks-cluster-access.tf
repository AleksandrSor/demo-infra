resource "aws_eks_access_entry" "node_access" {
  cluster_name  = aws_eks_cluster.cluster.name
  principal_arn = aws_iam_role.nodes.arn
  type          = "EC2_LINUX" # Tells EKS this role belongs to worker nodes joining the cluster
}

# 1. Admin access entry for cluster administration
resource "aws_eks_access_entry" "admin" {
  cluster_name = aws_eks_cluster.cluster.name

  for_each      = toset(var.admin_user_arns)
  principal_arn = each.value
  type          = "STANDARD" # Used for generic IAM users and roles
}

# 2. Attach the Managed Cluster Admin Policy to the Access Entry
resource "aws_eks_access_policy_association" "admin_policy" {
  cluster_name = aws_eks_cluster.cluster.name
  policy_arn   = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  for_each      = toset(var.admin_user_arns)
  principal_arn = each.value

  # Admin permissions require full cluster scope
  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.admin]
}