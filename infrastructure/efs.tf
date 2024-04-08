locals {
  app_efs_uid = 100
  app_efs_gid = 1000
  app_models_root_path = "/models"

  inf_efs_uid = 200
  inf_efs_gid = 2000
}

module "efs" {
  source = "terraform-aws-modules/efs/aws"
  version = "~> 1.6"

  name = "${local.app}-${local.env}-self-hosting-demo"

  # just hosting models, skipping encryption at reset
  encrypted = false

  # one zone EFS for this demo
  availability_zone_name = data.aws_subnet.private.availability_zone

  # no backups!
  create_backup_policy = false
  enable_backup_policy = false

  security_group_vpc_id = local.vpc_id
  security_group_name = "self-hosted-demo-efs@${local.app}-${local.env}"
  security_group_description = "Security group for self hosted demo EFS"
  security_group_rules = {
    tasks = {
      description = "Ingress from ECS tasks"
      source_security_group_id = aws_security_group.task.id
    }
    datasync = {
      description = "Ingress from DataSync"
      source_security_group_id = aws_security_group.datasync.id
    }
  }

  access_points = {
    app = {
      name = "${local.app}-${local.env}-self-hosting-demo-app"
      posix_user = {
        uid = local.app_efs_uid
        gid = local.app_efs_gid
      }
      root_directory = {
        path = "/app"
        creation_info = {
          owner_uid = local.app_efs_uid
          owner_gid = local.app_efs_gid
          permissions = "0750"
        }
      }
    }
    inf = {
      name = "${local.app}-${local.env}-self-hosting-demo-inf"
      posix_user = {
        uid = local.inf_efs_uid
        gid = local.inf_efs_gid
      }
      root_directory = {
        path = "/inf"
        creation_info = {
          owner_uid = local.inf_efs_uid
          owner_gid = local.inf_efs_gid
          permissions = "0750"
        }
      }
    }
  }

  attach_policy  = true
  policy_statements = [
    {
      sid = "AllowECSTasks"
      effect = "Allow"
      actions = [
        "elasticfilesystem:ClientMount",
        "elasticfilesystem:ClientWrite",
      ]
      principals = [
        {
          type        = "AWS"
          identifiers = [
            aws_iam_role.task.arn,
            aws_iam_role.datasync.arn,
          ]
        },
      ]
    },
  ]

  mount_targets = {
    private = {
      subnet_id = data.aws_subnet.private.id
    }
  }
}
