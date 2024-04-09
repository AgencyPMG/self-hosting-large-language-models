resource "aws_cloudwatch_log_group" "datasync" {
  name              = "${local.app}-${local.env}-self-hosting-demo-datasync"
  retention_in_days = 7
}

data "aws_iam_policy_document" "datasync-logs" {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:PutLogEventsBatch",
    ]

    resources = [
      "${aws_cloudwatch_log_group.datasync.arn}:*",
    ]

    principals {
      identifiers = ["datasync.amazonaws.com"]
      type        = "Service"
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_cloudwatch_log_resource_policy" "datasync" {
  policy_document = data.aws_iam_policy_document.datasync-logs.json
  policy_name     = "${local.app}-${local.env}-self-hosting-demo-datasync"
}

data "aws_iam_policy_document" "datasync-trust" {
  statement {
    sid     = "AllowEcsTaskAssume"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["datasync.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_iam_role" "datasync" {
  name               = "self-hosting-demo-datasync@${local.app}-${local.env}"
  assume_role_policy = data.aws_iam_policy_document.datasync-trust.json
}

data "aws_iam_policy_document" "datasync" {
  statement {
    sid    = "AllowS3"
    effect = "Allow"
    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket",
      "s3:GetObject",
      "s3:GetObjectTagging",
      "s3:GetObjectVersion",
      "s3:GetObjectVersionTagging",
    ]
    resources = [
      aws_s3_bucket.models.arn,
      "${aws_s3_bucket.models.arn}/*",
    ]
  }
}

resource "aws_iam_role_policy" "datasync" {
  name   = "allow-datasync"
  role   = aws_iam_role.datasync.name
  policy = data.aws_iam_policy_document.datasync.json
}

resource "aws_security_group" "datasync" {
  name        = "self-hosting-demo-app-datasync@${local.app}-${local.env}"
  description = "Security group for the datasync"
  vpc_id      = data.aws_vpc.main.id
}

resource "aws_security_group_rule" "datasync-egress-all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.datasync.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_datasync_location_s3" "app-models" {
  s3_bucket_arn = aws_s3_bucket.models.arn
  subdirectory  = "/app"
  s3_config {
    bucket_access_role_arn = aws_iam_role.datasync.arn
  }
}

resource "aws_datasync_location_efs" "app-models" {
  efs_file_system_arn   = module.efs.mount_targets["private"].file_system_arn
  access_point_arn      = module.efs.access_points["app"].arn
  in_transit_encryption = "TLS1_2"

  ec2_config {
    security_group_arns = [aws_security_group.datasync.arn]
    subnet_arn          = data.aws_subnet.private.arn
  }
}

resource "aws_datasync_task" "app" {
  name                     = "self-hosting-demo-${local.env}-app"
  destination_location_arn = aws_datasync_location_efs.app-models.arn
  source_location_arn      = aws_datasync_location_s3.app-models.arn
  cloudwatch_log_group_arn = aws_cloudwatch_log_group.datasync.arn
  options {
    log_level = "TRANSFER"
    gid       = "NONE"
    uid       = "NONE"
  }
}

output "aws_datasync_task" {
  value = aws_datasync_task.app
}
