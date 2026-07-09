resource "aws_route53_zone" "managed" {
  for_each = local.config.zone

  name = each.value.domain
}

# Output the authoritative nameservers
output "name_servers" {
  description = "Update these nameservers at your domain registrar."
  value       = { for k, v in aws_route53_zone.managed : k => v.name_servers }
}
