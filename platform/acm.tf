locals {
  # Deliberately not gated on var.certificate_arn. Once you paste the ARN into
  # tfvars this must stay true, or the next apply would destroy the very
  # certificate the HTTPS listener is serving.
  create_certificate = var.create_certificate && var.app_domain != ""

  manage_validation_records = local.create_certificate && var.route53_zone_id != ""
}

resource "aws_acm_certificate" "this" {
  count = local.create_certificate ? 1 : 0

  domain_name               = var.app_domain
  subject_alternative_names = var.subject_alternative_names
  validation_method         = "DNS"

  tags = { Name = local.name }

  # Replacing a certificate that a listener is using fails unless the
  # replacement exists first.
  lifecycle {
    create_before_destroy = true
  }
}

# Keyed by domain name, per the AWS provider's documented pattern. An apex
# domain and its wildcard resolve to the same validation record, which is what
# allow_overwrite is for.
#
# `domain_validation_options` is only known after the certificate exists, so
# planning this in the same run that creates the certificate can fail with
# "for_each value depends on resource attributes that cannot be determined
# until apply". The README's phased `-target` sequence avoids that.
resource "aws_route53_record" "validation" {
  for_each = local.manage_validation_records ? {
    for option in aws_acm_certificate.this[0].domain_validation_options :
    option.domain_name => {
      name   = option.resource_record_name
      type   = option.resource_record_type
      record = option.resource_record_value
    }
  } : {}

  zone_id         = var.route53_zone_id
  name            = each.value.name
  type            = each.value.type
  records         = [each.value.record]
  ttl             = 60
  allow_overwrite = true
}

# Blocks until ACM reports the certificate ISSUED. Creates no infrastructure.
resource "aws_acm_certificate_validation" "this" {
  count = local.create_certificate ? 1 : 0

  certificate_arn = aws_acm_certificate.this[0].arn

  # Only wait on records this config owns. With external DNS there is nothing
  # to reference, so it just polls until the certificate issues.
  validation_record_fqdns = local.manage_validation_records ? [
    for record in aws_route53_record.validation : record.fqdn
  ] : null

  timeouts {
    create = var.certificate_validation_timeout
  }
}

output "acm_certificate_arn" {
  description = "ARN of the issued certificate. Paste into `certificate_arn` in terraform.tfvars."
  value       = one(aws_acm_certificate.this[*].arn)
}

output "acm_validation_records" {
  description = "DNS records proving domain ownership. Empty when Route 53 manages them. Leave these in place permanently — ACM reuses them to auto-renew."
  value = local.manage_validation_records ? {} : {
    for option in try(aws_acm_certificate.this[0].domain_validation_options, []) :
    option.domain_name => {
      name  = option.resource_record_name
      type  = option.resource_record_type
      value = option.resource_record_value
    }
  }
}
