resource "aws_acm_certificate" "public" {
  domain_name       = local.public_hostname
  validation_method = "DNS"
  subject_alternative_names = [
    "*.${local.public_hostname}",
  ]

  tags = {
    Name = local.public_hostname
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "public-certificate-validation" {
  for_each = {
    for dvo in aws_acm_certificate.public.domain_validation_options : dvo.domain_name => {
      domain = dvo.domain_name
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  type            = each.value.type
  ttl             = 600
  zone_id         = data.aws_route53_zone.main.zone_id
  records         = [each.value.record]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "public" {
  certificate_arn         = aws_acm_certificate.public.arn
  validation_record_fqdns = [for record in aws_route53_record.public-certificate-validation : record.fqdn]

  lifecycle {
    create_before_destroy = true
  }
}
