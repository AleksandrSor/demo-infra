data "aws_ec2_instance_type" "eks_nodes" {
  instance_type = local.config.eks.nodes.type
}

data "aws_ssm_parameter" "eks_nodes_ami_id" {
  name = "/aws/service/bottlerocket/aws-k8s-${local.config.eks.version}/${one(data.aws_ec2_instance_type.eks_nodes.supported_architectures)}/latest/image_id"
}

resource "aws_launch_template" "eks_nodes" {
  name_prefix   = "${local.config.project.name}-nodes-"
  image_id      = data.aws_ssm_parameter.eks_nodes_ami_id.value
  instance_type = data.aws_ec2_instance_type.eks_nodes.instance_type

  update_default_version = true

  iam_instance_profile {
    arn = aws_iam_instance_profile.eks_nodes.arn
  }

  # Reference: https://bottlerocket.dev/en/os/1.60.x/api/settings/kubernetes/
  user_data = base64encode(<<-EOT
[settings.kubernetes]
cluster-name = "${aws_eks_cluster.cluster.name}"
api-server = "${aws_eks_cluster.cluster.endpoint}"
cluster-certificate = "${aws_eks_cluster.cluster.certificate_authority[0].data}"
max-pods = ${local.config.eks.nodes.max_pods}
EOT
  )

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.eks_nodes.id]
  }

  metadata_options {
    http_tokens = "required"
  }

  lifecycle {
    create_before_destroy = true
  }

}
