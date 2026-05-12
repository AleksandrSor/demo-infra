include "root" {
  path = find_in_parent_folders("root.hcl")
  merge_strategy = "deep"
  expose = true
}

locals {
  config = yamldecode(file(include.root.locals.config_file))
  kms_key_id = "alias/tf-state-${local.config.project.name}-key"
  state_bucket_name = "tf-state-${local.config.project.name}-${get_aws_account_id()}-${local.region}-an"
  region = local.config.env.region
}

generate "backend" {
  path      = "backend.tf"
  if_exists = "overwrite"
  contents = <<EOF
terraform {

  encryption {
    method "unencrypted" "migrate" {}

    key_provider "aws_kms" "basic" {
      kms_key_id = "${local.kms_key_id}"
      region = "us-east-1"
      key_spec = "AES_256"
    }
  }
  backend "s3" {
    bucket         = "${local.state_bucket_name}"
    key            = "${path_relative_to_include()}/tofu.tfstate"
    region         = "${local.region}"
    use_lockfile   = true
    encrypt        = true
  }
}
EOF
}

inputs = {
  
}