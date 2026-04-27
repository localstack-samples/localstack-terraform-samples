# Output variable definitions

output "arn" {
  description = "ARN of the bucket"
  value       = aws_s3_bucket.s3_bucket.arn
}

output "name" {
  description = "Name (id) of the bucket"
  value       = aws_s3_bucket.s3_bucket.id
}

output "domain" {
  description = "Domain name of the bucket"
  value       = "s3-website.localhost.localstack.cloud:4566"
}

output "website_endpoint" {
  description = "Website endpoint URL"
  value       = "http://${aws_s3_bucket.s3_bucket.id}.s3-website.localhost.localstack.cloud:4566"
}
