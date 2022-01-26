locals {
  dlq_queue_name = "${var.queue_name}-dlq"
}


module "dynamo" {
  source = "./modules/dynamodb"

  count = var.dynamodb_enabled ? 1 : 0

  table_name             = var.table_name
  point_in_time_recovery = var.point_in_time_recovery
}

module "sqs" {
  source = "./modules/sqs"

  count = var.sqs_enabled ? 1 : 0

  queue_name                 = var.queue_name
  fifo_queue                 = var.fifo_queue
  delay_seconds              = var.queue_delay_seconds
  message_retention_seconds  = var.queue_message_retention_seconds
  visibility_timeout_seconds = var.queue_visibility_timeout_seconds

  dlq_enabled                   = var.queue_dlq_enabled
  dlq_queue_name                = local.dlq_queue_name
  dlq_message_retention_seconds = var.queue_dlq_message_retention_seconds
  dlq_max_receive_count         = var.queue_dlq_max_receive_count
}

module "s3" {
  source = "./modules/s3"

  count = var.s3_enabled ? 1 : 0

  bucket_name = var.bucket_name
  bucket_acl  = var.bucket_acl

  bucket_log_name = var.bucket_log_name
  bucket_log_acl  = var.bucket_log_acl
}

module "apigateway" {
  source = "./modules/apigateway"

  count = var.apigw_enabled ? 1 : 0

  apigw_name = var.apigw_v1_name
  path_part  = "{proxy+}"

  http_method   = var.apigw_http_method
  authorization = var.apigw_authorization

  request_parameters = {
    "method.request.path.proxy" = true
  }

  integration_type        = var.apigw_integration_type
  integration_http_method = var.apigw_http_integration_method

  integration_uri                   = "https://httpbin.org/anything/{proxy}"
  integration_passthrough_behaviour = "WHEN_NO_MATCH"

  integration_request_parameters = {
    "integration.request.path.proxy" = "method.request.path.proxy"
  }

  authorizer_enabled    = var.apigw_authorizer_enabled
  authorizer_arn        = var.apigw_authorizer_enabled ? module.lambda_authorizer[0].lambda_arn : ""
  authorizer_invoke_arn = var.apigw_authorizer_enabled ? module.lambda_authorizer[0].lambda_invoke_arn : ""

  cognito_authorizer_enabled = var.cognito_authorizer_enabled
  cognito_pool_arn           = var.cognito_enabled ? module.cognito_authorizer[0].pool_arn : ""
}

module "cognito_authorizer" {
  source = "./modules/cognito"

  count = var.cognito_enabled ? 1 : 0
}

module "lambda_authorizer" {
  source = "./modules/lambda"

  count = var.lambda_authorizer_enabled ? 1 : 0
}
