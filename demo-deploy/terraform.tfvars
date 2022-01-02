region = "eu-west-1"

dynamodb_enabled       = false
table_name             = "demo-table"
point_in_time_recovery = false

sqs_enabled = false
queue_name  = "demo-queue"

s3_enabled          = false
s3_force_path_style = true

bucket_name = "demo-bucket"
bucket_acl  = "private"

bucket_log_name = "demo-bucket-log"
bucket_log_acl  = "log-delivery-write"

apigw_v1_name = "apigwv1-demo"
