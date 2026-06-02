resource "aws_security_group" "eks_nodes" {
  name        = "${local.config.project.name}-eks-nodes-sg"
  description = "Security group for EKS nodes"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${local.config.project.name}-eks-nodes-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "eks_nodes_allow_all" {
  security_group_id            = aws_security_group.eks_nodes.id
  referenced_security_group_id = aws_security_group.eks_nodes.id

  ip_protocol = "-1"

  description = "Allow all within the sg"
}

resource "aws_vpc_security_group_egress_rule" "eks_nodes_allow_all" {
  security_group_id = aws_security_group.eks_nodes.id

  ip_protocol = "-1"
  cidr_ipv4   = "0.0.0.0/0"

  description = "Allow all outbound traffic"
}