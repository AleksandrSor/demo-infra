locals {

  config = yamldecode(file(var.config_file))

  realm_name = "${local.config.project.name}-project"
}

variable "config_file" {
  type    = string
  default = "../config.yaml"
}