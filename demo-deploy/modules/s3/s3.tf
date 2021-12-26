resource "aws_s3_bucket" "log_bucket" {
  bucket = var.bucket_log_name
  acl    = var.bucket_log_acl
}

resource "aws_s3_bucket" "bucket" {
  bucket = var.bucket_name
  acl    = var.bucket_acl

  logging {
    target_bucket = aws_s3_bucket.log_bucket.id
    target_prefix = "log/"
  }
}
