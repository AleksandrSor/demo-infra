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
  eks_cluster_name = dependency.aws_eks.outputs.cluster_name
}