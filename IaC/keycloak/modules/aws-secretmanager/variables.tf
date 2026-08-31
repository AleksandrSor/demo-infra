variable "oidc_client_config" {
  description = "OIDC client configuration for EKS cluster"
  type = object({
    name = string
    client_id = string
    client_secret = optional(string)
    issuer_url = string

    groups_claim = optional(string, "roles")
    groups_prefix = optional(string, "oidc:")
    
    username_claim = optional(string, "username")
    username_prefix = optional(string, "oidc-")
    
    required_claims = optional(map(string))
  })
  sensitive = true
}

variable "client_secret_version" {
  type = number
}