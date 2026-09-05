resource "aws_eks_identity_provider_config" "eks_oidc_provider" {
  cluster_name = var.eks_cluster_name
  oidc {
    identity_provider_config_name = var.eks_oidc_provider_config.name
    client_id                     = var.eks_oidc_provider_config.client_id
    issuer_url                    = var.eks_oidc_provider_config.issuer_url

    groups_claim  = lookup(var.eks_oidc_provider_config, "groups_claim", null)
    groups_prefix = lookup(var.eks_oidc_provider_config, "groups_prefix", null)

    username_claim  = lookup(var.eks_oidc_provider_config, "username_claim", null)
    username_prefix = lookup(var.eks_oidc_provider_config, "username_prefix", null)

    required_claims = lookup(var.eks_oidc_provider_config, "required_claims", null)
  }

}