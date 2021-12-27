locals {
  dlq_queue_name = "${var.queue_name}-dlq"
}


module "dynamo" {
  source = "./modules/dynamodb"

  count                  = var.dynamodb_enabled ? 1 : 0
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

	count       = var.s3_enabled ? 1 : 0

  bucket_name = var.bucket_name
  bucket_acl  = var.bucket_acl

  bucket_log_name = var.bucket_log_name
  bucket_log_acl  = var.bucket_log_acl
}
