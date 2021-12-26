region = "eu-west-1"

dynamodb_enabled       = false
table_name             = "demo-table"
point_in_time_recovery = true

sqs_enabled = false
queue_name  = "demo-queue"

bucket_name = "demo-bucket"
bucket_acl  = "private"

bucket_log_name = "demo-bucket-log"
bucket_log_acl  = "log-delivery-write"
