locals {
  config_file = "${get_parent_terragrunt_dir()}/config.yaml"
  config = yamldecode(file(local.config_file))
  backend_render_tpl = "${get_parent_terragrunt_dir()}/backend.tftpl"
}