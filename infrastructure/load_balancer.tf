module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 9.8"

  name    = "${local.app}-${local.env}-self-hosting-demo"
  vpc_id  = local.vpc_id
  subnets = local.public_subnet_ids

  # Security Group
  security_group_ingress_rules = {
    all_http = {
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      description = "HTTP web traffic"
      cidr_ipv4   = "0.0.0.0/0"
    }
    all_https = {
      from_port   = 443
      to_port     = 443
      ip_protocol = "tcp"
      description = "HTTPS web traffic"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }

  security_group_egress_rules = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = data.aws_vpc.main.cidr_block
    }
  }

  listeners = {
    http-https-redirect = {
      port     = 80
      protocol = "HTTP"
      # redirect HTTP -> HTTPS
      redirect = {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
    https = {
      port            = 443
      protocol        = "HTTPS"
      certificate_arn = aws_acm_certificate_validation.public.certificate_arn
      # fixed response for things that don't match listener rules
      fixed_response = {
        content_type = "application/json"
        message_body = jsonencode({
          type        = "https://http.cat/404"
          title       = "Not Found"
          description = "the requested resource was not found"
        })
        status_code = 404
      }

      rules = {
        app = {
          priority = 1
          actions = [
            {
              type             = "forward"
              target_group_key = "app"
            }
          ]
          conditions = [
            {
              host_header = {
                values = [
                  "app.${local.public_hostname}",
                ]
              }
            }
          ]
        }
        inf = {
          priority = 2
          actions = [
            {
              type             = "forward"
              target_group_key = "inf"
            }
          ]
          conditions = [
            {
              host_header = {
                values = [
                  "inf.${local.public_hostname}",
                ]
              }
            }
          ]
        }
      }
    }
  }

  target_groups = {
    app = {
      name              = "${local.app}-${local.env}-self-hosting-app"
      protocol          = "HTTP"
      port              = 8080
      target_type       = "ip"
      create_attachment = false
      health_check = {
        enabled           = true
        path              = "/health"
        healthy_threshold = 2
        matcher           = "200"
      }
    }
    inf = {
      name              = "${local.app}-${local.env}-self-hosting-inf"
      protocol          = "HTTP"
      port              = 8080
      target_type       = "ip"
      create_attachment = false
      health_check = {
        enabled           = true
        path              = "/v2/health/ready"
        healthy_threshold = 2
        matcher           = "200"
      }
    }
  }
}
