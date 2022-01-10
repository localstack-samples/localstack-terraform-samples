region = "eu-west-1"

dynamodb_enabled       = false
table_name             = "demo-table"
point_in_time_recovery = false

sqs_enabled = false
queue_name  = "demo-queue"

s3_enabled          = false
s3_force_path_style = false

bucket_name = "demo-bucket"
bucket_acl  = "private"

bucket_log_name = "demo-bucket-log"
bucket_log_acl  = "log-delivery-write"

apigw_enabled = true
# if true lambda authorizer will be used
apigw_authorizer_enabled = false
apigw_v1_name            = "apigwv1-demo"
# CUSTOM or COGNITO_USER_POOLS
apigw_authorization      = "COGNITO_USER_POOLS"
apigw_integration_type   = "HTTP_PROXY"
apigw_http_method = "ANY"
apigw_http_integration_method = "ANY"

cognito_enabled = false
cognito_authorizer_enabled = false

lambda_authorizer_enabled = false
