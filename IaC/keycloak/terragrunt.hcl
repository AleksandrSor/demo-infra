include "root" {
  path           = find_in_parent_folders("root.hcl")
  merge_strategy = "deep"
}

dependency "aws_eks" {
  config_path = "${get_terragrunt_dir()}/../aws-eks"

  mock_outputs_allowed_terraform_commands = ["init", "validate"]
  mock_outputs = {
    cluster_name = "demo-eks-cluster"
  }
  skip_outputs = get_env("IAC_QUICK_CHECK", "false") == "true"
}

inputs = {
  realm_url = "${get_env("KEYCLOAK_URL")}${get_env("KEYCLOAK_BASE_PATH")}/realms/${get_env("KEYCLOAK_REALM")}"
}