# EKS Control Plane allow for worker node communication
resource "aws_vpc_security_group_ingress_rule" "eks_control_plane_allow_nodes" {
  security_group_id            = aws_eks_cluster.cluster.vpc_config[0].cluster_security_group_id
  referenced_security_group_id = aws_security_group.eks_nodes.id

  ip_protocol = "-1"

  description = "Allow all inbound traffic from nodes to control plane"
}

resource "aws_vpc_security_group_egress_rule" "eks_control_plane_allow_nodes" {
  security_group_id            = aws_eks_cluster.cluster.vpc_config[0].cluster_security_group_id
  referenced_security_group_id = aws_security_group.eks_nodes.id

  ip_protocol = "-1"

  description = "Allow all outbound traffic to nodes from control plane"
}

# Pods <> Control plane

resource "aws_vpc_security_group_ingress_rule" "eks_control_plane_allow_pods" {
  security_group_id            = aws_eks_cluster.cluster.vpc_config[0].cluster_security_group_id
  referenced_security_group_id = aws_security_group.eks_pods.id

  ip_protocol = "-1"

  description = "Allow all inbound traffic from pods to control plane"
}

resource "aws_vpc_security_group_egress_rule" "eks_control_plane_allow_pods" {
  security_group_id            = aws_eks_cluster.cluster.vpc_config[0].cluster_security_group_id
  referenced_security_group_id = aws_security_group.eks_pods.id

  ip_protocol = "-1"

  description = "Allow all outbound traffic to pods from control plane"
}