resource "aws_s3_bucket" "models" {
  bucket = "${local.app}-${local.env}-self-hosting-demo-models"
}

resource "aws_s3_bucket_public_access_block" "models" {
  bucket = aws_s3_bucket.models.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "models" {
  bucket = aws_s3_bucket.models.id
  versioning_configuration {
    status = "Enabled"
  }
}

output "models_bucket" {
  value = aws_s3_bucket.models.bucket
}
