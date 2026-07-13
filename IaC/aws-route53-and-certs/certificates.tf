resource "aws_acm_certificate" "certificates" {
  for_each = local.config.certificates

  domain_name               = each.value.domain
  subject_alternative_names = each.value.subject_alternative_names
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

locals {
  dvo = {
    for dvo in flatten([
      for _, certificate in aws_acm_certificate.certificates : [
        for record in certificate.domain_validation_options : merge(record, {
          zone_id = one([
            for _, zone in aws_route53_zone.managed : zone.zone_id
            if record.domain_name == trimsuffix(zone.name, ".") || endswith(record.domain_name, ".${trimsuffix(zone.name, ".")}")
          ])
        })
      ]
    ]) : trim(replace(replace(dvo.domain_name, "*", "wc"), "/[^0-9A-Za-z-]/", "-"), "-") => dvo
  }
}

resource "aws_route53_record" "dvo" {
  for_each = local.dvo

  allow_overwrite = true
  name            = each.value.resource_record_name
  records         = [each.value.resource_record_value]
  ttl             = 60
  type            = each.value.resource_record_type
  zone_id         = each.value.zone_id

}

output "certificates_arn" {
  description = "The ARN of the ACM certificates."
  value       = { for k, v in aws_acm_certificate.certificates : v.domain_name => v.arn }
}