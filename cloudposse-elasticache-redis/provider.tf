provider "aws" {
  region                      = var.region
  access_key                  = "fake"
  secret_key                  = "fake"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    apigateway      = "http://localhost:4566"
    apigatewayv2    = "http://localhost:4566"
    applicationautoscaling = "http://localhost:4566"
    autoscaling     = "http://localhost:4566"
    cloudformation  = "http://localhost:4566"
    cloudwatch      = "http://localhost:4566"
    cognitoidp      = "http://localhost:4566"
    cognitosync     = "http://localhost:4566"
    cognitoidentity = "http://localhost:4566"
    dynamodb        = "http://localhost:4566"
    ec2             = "http://localhost:4566"
    es              = "http://localhost:4566"
    elasticache     = "http://localhost:4566"
    firehose        = "http://localhost:4566"
    iam             = "http://localhost:4566"
    kafka           = "http://localhost:4566"
    kinesis         = "http://localhost:4566"
    lambda          = "http://localhost:4566"
    rds             = "http://localhost:4566"
    redshift        = "http://localhost:4566"
    route53         = "http://localhost:4566"
    s3              = "http://localhost:4566"
    secretsmanager  = "http://localhost:4566"
    ses             = "http://localhost:4566"
    sns             = "http://localhost:4566"
    sqs             = "http://localhost:4566"
    ssm             = "http://localhost:4566"
    stepfunctions   = "http://localhost:4566"
    sts             = "http://localhost:4566"
  }

  default_tags {
    tags = {
      Environment = "Local"
      Service     = "LocalStack"
    }
  }
}