locals {
  # DNS zone from ailabs/staging
  dns_zone_id     = "Z06660833KLO0Q6PDBGL3"
  public_hostname = "selfhosting.${data.aws_route53_zone.main.name}"
}

data "aws_route53_zone" "main" {
  zone_id = local.dns_zone_id
}

resource "aws_route53_record" "root" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = local.public_hostname
  type    = "A"

  alias {
    name                   = module.alb.dns_name
    zone_id                = module.alb.zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "star" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "*.${local.public_hostname}"
  type    = "A"

  alias {
    name                   = module.alb.dns_name
    zone_id                = module.alb.zone_id
    evaluate_target_health = false
  }
}
