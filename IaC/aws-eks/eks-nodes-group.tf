resource "aws_placement_group" "eks_nodes" {
  name     = "${local.config.project.name}-eks-nodes-pg"
  strategy = "spread"
}

resource "aws_autoscaling_group" "eks_nodes" {
  desired_capacity    = local.config.eks.nodes.desired_capacity
  max_size            = local.config.eks.nodes.max_capacity
  min_size            = local.config.eks.nodes.min_capacity
  name                = "${local.config.project.name}-eks-nodes-asg"
  vpc_zone_identifier = [for s in aws_subnet.node_subnet : s.id]

  wait_for_capacity_timeout = "0"

  placement_group = aws_placement_group.eks_nodes.id

  launch_template {
    id      = aws_launch_template.eks_nodes.id
    version = aws_launch_template.eks_nodes.latest_version
  }

  tag {
    key                 = "kubernetes.io/cluster/${local.eks_cluster_name}"
    value               = "owned"
    propagate_at_launch = true
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
    # triggers = ["launch_template"] # Forces refresh on template changes
  }
}