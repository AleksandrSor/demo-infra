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

  iam_instance_profile {
    arn = aws_iam_instance_profile.eks_nodes.arn
  }

  # Essential for self-managed nodes to join the cluster
#   user_data = base64encode(<<-EOT
#     #!/bin/bash
#     set -o xtrace
#     /etc/eks/bootstrap.sh ${var.cluster_name} \
#       --b64-cluster-ca ${var.cluster_ca_cert} \
#       --apiserver-endpoint ${var.cluster_endpoint}
#   EOT
#   )

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
