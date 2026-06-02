locals {

  config = yamldecode(file(var.config_file))

  # admin_user_arns = concat(
  #   ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"],
  #   [for user in coalesce(try(local.config.env.tf_extra_admin_users, []), []) : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/${user}"]
  # )

  eks_cluster_name = "${local.config.project.name}-eks-cluster"
}

variable "config_file" {
  type    = string
  default = "../config.yaml"
}

variable "public_access_cidrs" {
  description = "A list of CIDR blocks allowed to access the EKS cluster endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}