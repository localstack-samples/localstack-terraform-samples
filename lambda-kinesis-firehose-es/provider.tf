terraform {
  # Only allow this Terraform version. Note that if you upgrade to a newer version, Terraform won't allow you to use an
  # older version, so when you upgrade, you should upgrade everyone on your team and your CI servers all at once.

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.60.0, <= 4.22.0"
    }
  }
}
