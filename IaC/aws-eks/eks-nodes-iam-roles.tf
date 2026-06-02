# IAM Role for EKS Worker Nodes
# Reference: https://docs.aws.amazon.com/eks/latest/userguide/create-node-role.html
resource "aws_iam_role" "nodes" {
  name = "${local.config.project.name}-eks-node"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.nodes.name
}

# check how it work with externalSNAT
# resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
#   role       = aws_iam_role.nodes.name
# }

resource "aws_iam_role_policy_attachment" "eks_node_ec2_container_registry_read_only" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.nodes.name
}

resource "aws_iam_role_policy_attachment" "eks_node_ssm_managed_instance_core" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.nodes.name
}

resource "aws_iam_instance_profile" "eks_nodes" {
  name = "${local.config.project.name}-eks-nodes-profile"
  role = aws_iam_role.nodes.name

  tags = {
    Name = "${local.config.project.name}-eks-nodes-profile"
  }
}