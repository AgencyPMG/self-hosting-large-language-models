data "aws_iam_policy_document" "task-trust" {
  statement {
    sid     = "AllowEcsTaskAssume"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_iam_role" "task" {
  name               = "self-hosting-demo-task@${local.app}-${local.env}"
  assume_role_policy = data.aws_iam_policy_document.task-trust.json
}

resource "aws_iam_role" "task-exec" {
  name               = "self-hosting-demo-task-exec@${local.app}-${local.env}"
  assume_role_policy = data.aws_iam_policy_document.task-trust.json
}

resource "aws_iam_role_policy_attachment" "task-exec" {
  role       = aws_iam_role.task-exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

data "aws_iam_policy_document" "ssm-exec" {
  statement {
    sid    = "AllowEcsExec"
    effect = "Allow"
    actions = [
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "task-ssm-exec" {
  name   = "ssm-exec"
  role   = aws_iam_role.task.name
  policy = data.aws_iam_policy_document.ssm-exec.json
}

data "aws_iam_policy_document" "task-exec-permissions" {
  statement {
    sid    = "AllowGetParameters"
    effect = "Allow"
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters",
    ]
    resources = [
      "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/self-hosting-demo/${local.env}/*",
    ]
  }
}

resource "aws_iam_role_policy" "task-exec-permissions" {
  name   = "task-exec-permissions"
  role   = aws_iam_role.task-exec.name
  policy = data.aws_iam_policy_document.task-exec-permissions.json
}

resource "aws_security_group" "task" {
  name        = "self-hosting-demo-app-task@${local.app}-${local.env}"
  description = "Security group for the ECS task of the self-hosting-demo-app"
  vpc_id      = data.aws_vpc.main.id
}

resource "aws_security_group_rule" "task-alb-ingress" {
  type                     = "ingress"
  description              = "ingress from the load balancer"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  security_group_id        = aws_security_group.task.id
  source_security_group_id = module.alb.security_group_id
}

resource "aws_security_group_rule" "task-egress-all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.task.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_cloudwatch_log_group" "task" {
  name              = "${local.app}-${local.env}-self-hosting-demo"
  retention_in_days = 7
}

resource "aws_ecs_cluster" "main" {
  name = "self-hosting-demo-${local.env}"
}
