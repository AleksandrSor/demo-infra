resource "keycloak_kubernetes_identity_provider" "github_actions" {
  alias = "github-actions"
  realm = keycloak_realm.realm.id
  issuer = "https://token.actions.githubusercontent.com"

  lifecycle {
    prevent_destroy = true
  }
}