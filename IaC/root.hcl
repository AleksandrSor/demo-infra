locals {
  config_file = "${get_parent_terragrunt_dir("root")}/config.yaml"
  config = yamldecode(local.config_file)
}

inputs = {
  config_file = local.config_file
}
