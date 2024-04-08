terraform {
  required_version = ">= 1.6"

  backend "s3" {
    bucket     = "playground-infrastructure"
    key        = "selfhostingtalk/main.tfstate"
    region     = "us-east-1"
    encrypt    = true
    kms_key_id = "arn:aws:kms:us-east-1:625506553848:key/99fa0cc4-d366-4857-a34f-a3fb9be28382"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
  default_tags {
    tags = {
      Application = local.app
      Environment = local.env
    }
  }
}
