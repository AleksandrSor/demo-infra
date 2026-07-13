# AWS Route53 and Certificates Stack

Public DNS and TLS stack for:

- creating Route53 hosted zones
- requesting ACM certificates
- creating DNS validation records from ACM domain validation options (DVO)
- integrating ExternalDNS IAM role and pod identity

## Files

- `zone.tf`: Route53 hosted zones and nameserver output
- `certificates.tf`: ACM certificates, `local.dvo` map, and validation records
- `externaldns-iam-role-and-identity.tf`: IAM role/policy and pod identity for ExternalDNS
- `variables.tf`: shared config input
- `terragrunt.hcl`: stack entrypoint

## DVO Shape

This stack builds a normalized map in `certificates.tf`:

```hcl
local.dvo = {
  "wc-aws-alek-sor-website" = {
    domain_name           = "*.aws.alek-sor.website"
    resource_record_name  = "_xxxx.aws.alek-sor.website"
    resource_record_type  = "CNAME"
    resource_record_value = "_yyyy.acm-validations.aws."
    zone_id               = "Z1234567890"
  }
  "aws-alek-sor-website" = {
    domain_name           = "aws.alek-sor.website"
    resource_record_name  = "_zzzz.aws.alek-sor.website"
    resource_record_type  = "CNAME"
    resource_record_value = "_wwww.acm-validations.aws."
    zone_id               = "Z1234567890"
  }
}
```

Key format notes:

- wildcard `*` becomes `wc`
- non-alphanumeric/dash characters are replaced by `-`
- leading/trailing `-` are trimmed

## Current Implementation (Already Enabled)

Validation records are created directly from `local.dvo`:

```hcl
resource "aws_route53_record" "dvo" {
  for_each = local.dvo

  allow_overwrite = true
  name            = each.value.resource_record_name
  records         = [each.value.resource_record_value]
  ttl             = 60
  type            = each.value.resource_record_type
  zone_id         = each.value.zone_id
}
```

## Example: Add Explicit ACM Validation Resource

If you also want Terraform/OpenTofu to track certificate validation completion:

```hcl
resource "aws_acm_certificate_validation" "certificates" {
  for_each = aws_acm_certificate.certificates

  certificate_arn = each.value.arn

  validation_record_fqdns = [
    for dvo in each.value.domain_validation_options :
    aws_route53_record.dvo[
      trim(replace(replace(dvo.domain_name, "*", "wc"), "/[^0-9A-Za-z-]/", "-"), "-")
    ].fqdn
  ]
}
```

## Example: Reuse DVO Output in Another Module

If you expose DVO as an output in this stack and consume it from another stack:

```hcl
# producer output shape
output "dvo" {
  value = local.dvo
}
```

```hcl
# consumer
variable "dvo" {
  type = map(object({
    domain_name           = string
    resource_record_name  = string
    resource_record_type  = string
    resource_record_value = string
    zone_id               = string
  }))
}

resource "aws_route53_record" "cert_validation" {
  for_each = var.dvo

  allow_overwrite = true
  name            = each.value.resource_record_name
  type            = each.value.resource_record_type
  records         = [each.value.resource_record_value]
  ttl             = 60
  zone_id         = each.value.zone_id
}
```

## Usage

```bash
cd IaC/aws-route53-and-certs
terragrunt plan
terragrunt apply
```

After apply:

1. update your registrar with nameservers from `output.name_servers`
2. wait for DNS propagation
3. ACM certificates move from `PENDING_VALIDATION` to `ISSUED`
