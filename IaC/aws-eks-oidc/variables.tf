locals {

  config = yamldecode(file(var.config_file))

}

variable "config_file" {
  type    = string
  default = "../config.yaml"
}

variable "eks_cluster_name" {
  description = "The name of the EKS cluster"
  type        = string
}

variable "eks_oidc_provider_config" {
  description = "OIDC identity provider configuration for EKS cluster"
  type = object({
    name = string
    client_id = string
    issuer_url = string

    groups_claim = optional(string)
    groups_prefix = optional(string)
    
    username_claim = optional(string)
    username_prefix = optional(string)
    
    required_claims = optional(map(string))
  })
}