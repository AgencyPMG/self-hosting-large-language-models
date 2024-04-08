locals {
  # VPC from the AI Labs Staging Infrastructure
  vpc_id = "vpc-0088d8a9d8ff82315"
  private_subnet_ids = [
    "subnet-0a60e06fb7a998a04",
  ]
  public_subnet_ids = [
    "subnet-09dc0c3ab1d6342c5",
    "subnet-0e497fa8e8c042c53",
  ]
}

data "aws_vpc" "main" {
  id = local.vpc_id
}

data "aws_subnet" "private" {
  id = local.private_subnet_ids[0]
}
