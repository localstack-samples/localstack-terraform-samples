variable "region" {
  default = "us-east-1"
}

# DynamoDB
variable "dynamodb_enabled" {}
variable "table_name" {}
variable "point_in_time_recovery" {}

# SQS
variable "sqs_enabled" {}
variable "queue_name" {}
variable "fifo_queue" {
  default = false
}
variable "queue_message_retention_seconds" {
  default = 14 * 24 * 60 * 60 # 14 days
}
variable "queue_visibility_timeout_seconds" {
  default = 60
}
variable "queue_delay_seconds" {
  default = 15 * 60 # 15 minutes
}
variable "queue_dlq_enabled" {
  default = false
}
variable "queue_dlq_message_retention_seconds" {
  default = 14 * 24 * 60 * 60 # 14 days
}
variable "queue_dlq_max_receive_count" {
  default = 100
}

# s3
variable "s3_enabled" {}
variable "s3_force_path_style" {}

variable "bucket_name" {}
variable "bucket_acl" {}

variable "bucket_log_name" {}
variable "bucket_log_acl" {}

# API Gateway v1
variable "apigw_enabled" {}
variable "apigw_v1_name" {}
variable "apigw_authorization" {}
variable "apigw_integration_type" {}
variable "apigw_authorizer_enabled" {}
variable "apigw_http_method" {}
variable "apigw_http_integration_method" {}
# Cognito
variable "cognito_enabled" {}
variable "cognito_authorizer_enabled" {}

# Lambda authorizer
variable "lambda_authorizer_enabled" {}
