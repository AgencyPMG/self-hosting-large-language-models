// we'll use this image to run the model rather than building our own
data "aws_sagemaker_prebuilt_ecr_image" "huggingface-cpu" {
  repository_name = "huggingface-pytorch-inference"
  image_tag = "2.1-transformers4.37-cpu-py310-ubuntu22.04"
}

data "aws_iam_policy_document" "sagemaker-trust" {
  statement {
    sid     = "AllowSagemakerTaskAssume"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["sagemaker.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_iam_role" "sagemaker" {
  name               = "self-hosting-demo-sagemaker@${local.app}-${local.env}"
  assume_role_policy = data.aws_iam_policy_document.sagemaker-trust.json
}

data "aws_iam_policy_document" "sagemaker-exec" {
  statement {
    sid = "AllowGetS3"
    effect = "Allow"
    actions = [
      "s3:GetObject",
    ]
    resources = [
      "${aws_s3_bucket.models.arn}/inf/*",
    ]
  }
    statement {
    effect = "Allow"
    actions = [
      "cloudwatch:PutMetricData",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:CreateLogGroup",
      "logs:DescribeLogStreams",
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "sagemaker-exec" {
  name   = "sagemaker-exec"
  role   = aws_iam_role.sagemaker.name
  policy = data.aws_iam_policy_document.sagemaker-exec.json
}

// but we still need an actual model to connect with an endpoint, so going
// to deploy a "broken" one here without the right config to actually work and
// will update it in other scripts
resource "aws_sagemaker_model" "gpt2-template" {
  name = "self-hosting-demo-gpt2-template"
  execution_role_arn = aws_iam_role.sagemaker.arn

  primary_container {
    image = data.aws_sagemaker_prebuilt_ecr_image.huggingface-cpu.registry_path
    environment = {
      HF_TASK = "text-generation"
    }
  }
}

resource "aws_sagemaker_endpoint_configuration" "gpt2-template" {
  name = "self-hosting-demo-gpt2-template"
  production_variants {
    variant_name = "default"
    model_name = aws_sagemaker_model.gpt2-template.name
    serverless_config {
      max_concurrency = 2
      memory_size_in_mb = 2048
    }
  }
}

resource "aws_sagemaker_endpoint" "gpt2" {
  name = "self-hosting-demo-gpt2"
  endpoint_config_name = aws_sagemaker_endpoint_configuration.gpt2-template.name
  lifecycle {
    ignore_changes = [endpoint_config_name]
  }
}

output "huggingface_image_uri" {
  value = data.aws_sagemaker_prebuilt_ecr_image.huggingface-cpu.registry_path
}

output "sagemaker_role_arn" {
  value = aws_iam_role.sagemaker.arn
}
