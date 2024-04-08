locals {
  model_root_path = "/models"
}

resource "aws_ecr_repository" "nginx" {
  name = "${local.app}-${local.env}-self-hosted-demo-nginx"
}

resource "aws_ecr_repository" "app" {
  name = "${local.app}-${local.env}-self-hosted-demo-app"
}

resource "aws_ecs_service" "app" {
  name                               = "app"
  cluster                            = aws_ecs_cluster.main.name
  desired_count                      = 0
  task_definition                    = aws_ecs_task_definition.app.arn
  deployment_minimum_healthy_percent = "100"
  launch_type                        = "FARGATE"
  propagate_tags                     = "SERVICE"
  enable_execute_command             = true

  load_balancer {
    target_group_arn = module.alb.target_groups["app"].arn
    container_name   = "nginx"
    container_port   = "80"
  }

  network_configuration {
    subnets = local.private_subnet_ids
    security_groups = [
      aws_security_group.task.id,
    ]
    assign_public_ip = false
  }
}

resource "aws_ecs_task_definition" "app" {
  family                   = "${local.app}-${local.env}-self-hosted-demo-app"
  execution_role_arn  = aws_iam_role.task-exec.arn
  task_role_arn            = aws_iam_role.task.arn
  cpu                      = 1024
  memory                   = 2048
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  volume {
    name = "models"
    efs_volume_configuration {
      file_system_id          = module.efs.id
      transit_encryption      = "ENABLED"
      authorization_config {
        access_point_id = module.efs.access_points["app"].id
        iam             = "ENABLED"
      }
    }
  }

  container_definitions = jsonencode([
    {
      name      = "nginx"
      image     = "${aws_ecr_repository.nginx.repository_url}:latest"
      essential = true
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.task.name
          awslogs-region        = "us-east-1"
          awslogs-stream-prefix = "app-nginx"
        }
      },
      portMappings = [{
        containerPort = 80
      }],
      environment = []
      linuxParameters = {
        initProcessEnabled = true
      }
    },
    {
      name      = "app"
      image     = "${aws_ecr_repository.app.repository_url}:latest"
      essential = true
      user = "${local.app_efs_uid}:${local.app_efs_gid}"
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.task.name
          awslogs-region        = "us-east-1"
          awslogs-stream-prefix = "app"
        }
      },
      environment = [
        {
          name  = "MODEL_ROOT_PATH"
          value = local.model_root_path
        },
      ]
      mountPoints = [
        {
          sourceVolume = "models"
          containerPath = local.model_root_path
          readOnly = true
        }
      ]
      linuxParameters = {
        initProcessEnabled = true
      }
    }
  ])

  lifecycle {
    create_before_destroy = "true"
  }
}

output "nginx_repository" {
  value = aws_ecr_repository.nginx.repository_url
}

output "app_repository" {
  value = aws_ecr_repository.app.repository_url
}
