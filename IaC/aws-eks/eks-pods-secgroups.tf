resource "aws_security_group" "eks_pods" {
  name        = "${local.config.project.name}-eks-pods-sg"
  description = "Security group for EKS pods"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${local.config.project.name}-eks-pods-sg"
  }
}

# Self-referencing rules for pods security group

resource "aws_vpc_security_group_ingress_rule" "eks_pods_allow_self" {
  security_group_id            = aws_security_group.eks_pods.id
  referenced_security_group_id = aws_security_group.eks_pods.id

  ip_protocol = "-1"

  description = "Allow all within the sg"
}

resource "aws_vpc_security_group_egress_rule" "eks_pods_allow_self" {
  security_group_id            = aws_security_group.eks_pods.id
  referenced_security_group_id = aws_security_group.eks_pods.id

  ip_protocol = "-1"

  description = "Allow all outbound traffic to self"
}

# Pods <-> Nodes rules

resource "aws_vpc_security_group_ingress_rule" "eks_pods_allow_nodes" {
  security_group_id            = aws_security_group.eks_pods.id
  referenced_security_group_id = aws_security_group.eks_nodes.id

  ip_protocol = "-1"

  description = "Allow all inbound traffic from nodes"
}

resource "aws_vpc_security_group_egress_rule" "eks_pods_allow_nodes" {
  security_group_id            = aws_security_group.eks_pods.id
  referenced_security_group_id = aws_security_group.eks_nodes.id

  ip_protocol = "-1"

  description = "Allow all outbound traffic to nodes"
}

# Pods <-> Control plane rules
resource "aws_vpc_security_group_ingress_rule" "eks_pods_allow_control_plane" {
  security_group_id            = aws_security_group.eks_pods.id
  referenced_security_group_id = aws_eks_cluster.cluster.vpc_config[0].cluster_security_group_id

  ip_protocol = "-1"

  description = "Allow all inbound traffic from control plane"
}

resource "aws_vpc_security_group_egress_rule" "eks_pods_allow_control_plane" {
  security_group_id            = aws_security_group.eks_pods.id
  referenced_security_group_id = aws_eks_cluster.cluster.vpc_config[0].cluster_security_group_id

  ip_protocol = "-1"

  description = "Allow all outbound traffic to control plane"
}

# Pods <-> ALB
resource "aws_vpc_security_group_ingress_rule" "eks_pods_allow_alb" {
  security_group_id            = aws_security_group.eks_pods.id
  referenced_security_group_id = aws_security_group.alb_shared_backend.id

  ip_protocol = "-1"

  description = "Allow all inbound traffic from ALB"
}

resource "aws_vpc_security_group_egress_rule" "eks_pods_allow_alb" {
  security_group_id            = aws_security_group.eks_pods.id
  referenced_security_group_id = aws_security_group.alb_shared_backend.id

  ip_protocol = "-1"

  description = "Allow all outbound traffic to ALB"
}

# All traffic

#trivy:ignore:AWS-0107
# resource "aws_vpc_security_group_ingress_rule" "eks_pods_allow_all" {
#   security_group_id = aws_security_group.eks_pods.id

#   ip_protocol = "-1"
#   cidr_ipv4   = "0.0.0.0/0"

#   description = "Allow all inbound traffic"
# }

#trivy:ignore:AWS-0104
resource "aws_vpc_security_group_egress_rule" "eks_pods_allow_all" {
  security_group_id = aws_security_group.eks_pods.id

  ip_protocol = "-1"
  cidr_ipv4   = "0.0.0.0/0"

  description = "Allow all outbound traffic"
}