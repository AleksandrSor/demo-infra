locals {
  config_hcl = read_terragrunt_config(find_in_parent_folders("config.hcl"))

  config = local.config_hcl.locals.config

  backend_render_vars = {
    kms_key_alias     = "alias/tf-state-${local.config.project.name}-key"
    key_spec          = "AES_256"
    state_bucket_name = "tf-state-${local.config.project.name}-${get_aws_account_id()}-${local.config.env.region}-an"
    region            = local.config.env.region
    state_key         = "${get_path_from_repo_root()}/tofu.tfstate"
    # Init stage!
    plaintext_fallback_enabled = false # Enable it for init stage to migrate state from unencrypted state
  }

  backend_render = templatefile(local.config_hcl.locals.backend_render_tpl, local.backend_render_vars)
}

inputs = {
  config_file = local.config_hcl.locals.config_file
}

generate "backend" {
  path      = "backend.tf"
  if_exists = "overwrite"
  contents  = local.backend_render
  disable   = get_env("IAC_QUICK_CHECK", "false") == "true"
}
