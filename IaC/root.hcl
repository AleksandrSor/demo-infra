## Default config included in stacks
## This config not included in demo-core project

dependency "core" {
  config_path = "${get_terragrunt_dir()}/../demo-core"

  mock_outputs_allowed_terraform_commands = ["init", "validate"]
  mock_outputs = {
    kms_key_alias         = "alias/tf-state-${local.config.project.name}-key"
    state_bucket_name     = "tf-state-${local.config.project.name}-${local.get_aws_account_id}-${local.config.env.region}-an"
    region                = local.config.env.region
    admin_user_arns       = []
    tf_execution_role_arn = ""
  }
  skip_outputs = get_env("IAC_QUICK_CHECK", "false") == "true"
}

locals {
  config_hcl = read_terragrunt_config(find_in_parent_folders("config.hcl"))

  config = local.config_hcl.locals.config

  get_aws_account_id = get_env("IAC_QUICK_CHECK", "false") == "true" ? "NA" : get_aws_account_id()

  backend_render_vars = {
    key_spec                   = "AES_256"
    state_key                  = "${get_path_from_repo_root()}/tofu.tfstate"
    plaintext_fallback_enabled = true
  }

}

inputs = {
  config_file     = local.config_hcl.locals.config_file
  admin_user_arns = concat(dependency.core.outputs.admin_user_arns, [dependency.core.outputs.tf_execution_role_arn])
}

generate "backend" {
  path      = "backend.tf"
  if_exists = "overwrite"
  contents  = templatefile(local.config_hcl.locals.backend_render_tpl, merge(local.backend_render_vars, dependency.core.outputs))
  disable   = get_env("IAC_QUICK_CHECK", "false") == "true"
}
