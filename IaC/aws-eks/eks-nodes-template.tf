data "aws_ec2_instance_type" "eks_nodes" {
  for_each = local.config.eks.nodes
  instance_type = each.value.type
}

data "aws_ssm_parameter" "eks_nodes_ami_id" {
  for_each = local.config.eks.nodes
  name = "/aws/service/bottlerocket/aws-k8s-${local.config.eks.version}/${one(data.aws_ec2_instance_type.eks_nodes[each.key].supported_architectures)}/latest/image_id"
}

resource "aws_launch_template" "eks_nodes" {

  for_each = local.config.eks.nodes

  name_prefix   = "${local.config.project.name}-${each.key}-nodes-"
  image_id      = data.aws_ssm_parameter.eks_nodes_ami_id[each.key].value
  instance_type = data.aws_ec2_instance_type.eks_nodes[each.key].instance_type

  update_default_version = true

  iam_instance_profile {
    arn = aws_iam_instance_profile.eks_nodes.arn
  }

  # Reference: https://bottlerocket.dev/en/os/1.60.x/api/settings/kubernetes/
  user_data = base64encode(templatefile("${path.module}/eks-nodes-template-bottlerocket.tftpl", {
    cluster_name        = aws_eks_cluster.cluster.name
    cluster_endpoint    = aws_eks_cluster.cluster.endpoint
    cluster_certificate = aws_eks_cluster.cluster.certificate_authority[0].data
    max_pods            = try(each.value.max_pods, null)
    node_labels         = try(each.value.labels, {})
    node_taints         = try(each.value.taints, {})
    })
  )

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.eks_nodes.id]
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
    instance_metadata_tags      = "disabled" #there is a bug - it cannot provide tags formatted as "kubernetes.io/cluster/${aws_eks_cluster.cluster.name}"
    # and leads to "Failed to launch node with error: 'kubernetes.io/cluster/cluster-name' is not a valid tag key"
  }

  lifecycle {
    create_before_destroy = true
  }

}
