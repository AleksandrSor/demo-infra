locals {
  config_file = "${get_parent_terragrunt_dir()}/config.yaml"
  config = yamldecode(file(local.config_file))
  kms_key_id = "alias/tf-state-${local.config.project.name}-key"
  state_bucket_name = "tf-state-${local.config.project.name}-${get_aws_account_id()}-${local.region}-an"
  region = local.config.env.region
}

inputs = {
  config_file = local.config_file
}

generate "backend" {
  path      = "backend.tf"
  if_exists = "overwrite"
  contents = <<EOF
terraform {

  encryption {
    method "unencrypted" "migrate" {}

    key_provider "aws_kms" "state" {
      kms_key_id = "${local.kms_key_id}"
      region = "${local.region}"
      key_spec = "AES_256"
    }

    method "aes_gcm" "aws_state" {
      keys = key_provider.aws_kms.state
    }

    state {
      method = method.aes_gcm.aws_state

      # Remove the fallback block when all workspaces have been migrated to KMS encryption
      fallback {
        method = method.unencrypted.migrate
      }
      # enforced = true # Uncomment this line to enforce KMS encryption and disable fallback to unencrypted state
    }

    plan {
      method = method.aes_gcm.aws_state

      enforced = true
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
