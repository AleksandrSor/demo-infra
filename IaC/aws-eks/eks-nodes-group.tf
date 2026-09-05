resource "aws_placement_group" "eks_nodes" {
  for_each = local.config.eks.nodes
  name     = "${local.config.project.name}-${each.key}-eks-nodes"
  strategy = "spread"
}

resource "aws_autoscaling_group" "eks_nodes" {
  for_each            = local.config.eks.nodes
  desired_capacity    = each.value.desired_capacity
  max_size            = each.value.max_capacity
  min_size            = each.value.min_capacity
  name                = "${local.config.project.name}-${each.key}-eks-nodes"
  vpc_zone_identifier = [for s in aws_subnet.node_subnet : s.id]

  wait_for_capacity_timeout = "0"

  placement_group = aws_placement_group.eks_nodes[each.key].id

  launch_template {
    id      = aws_launch_template.eks_nodes[each.key].id
    version = aws_launch_template.eks_nodes[each.key].latest_version
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