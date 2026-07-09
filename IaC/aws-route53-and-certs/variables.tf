locals {

  config = yamldecode(file(var.config_file))

}

variable "config_file" {
  type    = string
  default = "../config.yaml"
}