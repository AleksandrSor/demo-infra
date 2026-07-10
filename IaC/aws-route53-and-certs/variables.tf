locals {

  config = yamldecode(file(var.config_file))

}

variable "config_file" {
  type    = string
  default = "../config.yaml"
}

variable "eks_cluster_name" {
  description = "The name of the EKS cluster"
  type        = string
}