provider "aws" {
  region                      = "us-east-1"

  default_tags {
    tags = {
      Environment = "Local"
      Service     = "LocalStack"
    }
  }
}

terraform {
  # The configuration for this backend will be filled in by Terragrunt or via a backend.hcl file. See
  # https://www.terraform.io/docs/backends/config.html#partial-configuration
  #  backend "s3" {}

  # Only allow this Terraform version. Note that if you upgrade to a newer version, Terraform won't allow you to use an
  # older version, so when you upgrade, you should upgrade everyone on your team and your CI servers all at once.
  #required_version = "= 1.1.2"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.60.0, <= 3.69.0"
    }
  }
}
