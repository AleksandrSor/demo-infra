resource "aws_security_group" "eks_nodes" {
  name        = "${local.config.project.name}-eks-nodes-sg"
  description = "Security group for EKS nodes"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${local.config.project.name}-eks-nodes-sg"
    # "kubernetes.io/cluster/${local.eks_cluster_name}" = "owned"
  }
}

resource "aws_vpc_security_group_ingress_rule" "eks_nodes_allow_all" {
  security_group_id            = aws_security_group.eks_nodes.id
  referenced_security_group_id = aws_security_group.eks_nodes.id

  ip_protocol = "-1"

  description = "Allow all within the sg"
}

resource "aws_vpc_security_group_egress_rule" "eks_nodes_allow_self" {
  security_group_id            = aws_security_group.eks_nodes.id
  referenced_security_group_id = aws_security_group.eks_nodes.id

  ip_protocol = "-1"

  description = "Allow all outbound traffic to self"
}

#trivy:ignore:AWS-0104
resource "aws_vpc_security_group_egress_rule" "eks_nodes_allow_all" {
  security_group_id = aws_security_group.eks_nodes.id

  ip_protocol = "-1"
  cidr_ipv4   = "0.0.0.0/0"

  description = "Allow all outbound traffic"
}

#trivy:ignore:AWS-0104
resource "aws_vpc_security_group_egress_rule" "eks_nodes_allow_all_ipv6" {
  security_group_id = aws_security_group.eks_nodes.id

  ip_protocol = "-1"
  cidr_ipv6   = "::/0"

  description = "Allow all outbound traffic"
}


# EKS Control Plane
resource "aws_vpc_security_group_ingress_rule" "eks_nodes_allow_control_plane" {
  security_group_id            = aws_security_group.eks_nodes.id
  referenced_security_group_id = aws_eks_cluster.cluster.vpc_config[0].cluster_security_group_id

  ip_protocol = "-1"

  description = "Allow all inbound traffic from control plane"
}

resource "aws_vpc_security_group_egress_rule" "eks_nodes_allow_control_plane" {
  security_group_id            = aws_security_group.eks_nodes.id
  referenced_security_group_id = aws_eks_cluster.cluster.vpc_config[0].cluster_security_group_id

  ip_protocol = "-1"

  description = "Allow all outbound traffic to control plane"
}

# Pods <-> Nodes rules

resource "aws_vpc_security_group_ingress_rule" "eks_nodes_allow_pods" {
  security_group_id            = aws_security_group.eks_nodes.id
  referenced_security_group_id = aws_security_group.eks_pods.id

  ip_protocol = "-1"

  description = "Allow all inbound traffic from pods"
}

resource "aws_vpc_security_group_egress_rule" "eks_nodes_allow_pods" {
  security_group_id            = aws_security_group.eks_nodes.id
  referenced_security_group_id = aws_security_group.eks_pods.id

  ip_protocol = "-1"

  description = "Allow all outbound traffic to pods"
}