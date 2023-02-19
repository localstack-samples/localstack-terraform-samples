variable "aws_region" {
  default = "eu-west-1"
}

resource "aws_iam_role" "lambda_role" {
  name = "demorole"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
POLICY
}

resource "aws_iam_role" "firehose_role" {
  name = "firehose_test_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "firehose.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_lambda_function" "demo_lambda" {
  filename      = "lambda.zip"
  function_name = "demolambda"
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda.handler"

  source_code_hash = filebase64sha256("lambda.zip")

  runtime = "python3.9"

  environment {
    variables = {
      STREAM_NAME = aws_kinesis_stream.demo_kinesis_stream.name
    }
  }
}

resource "aws_lambda_function_url" "demo_lambda_url" {
  function_name      = aws_lambda_function.demo_lambda.function_name
  authorization_type = "NONE"
}

resource "aws_elasticsearch_domain" "demo_es_domain" {
  domain_name           = "demo-domain"
  elasticsearch_version = "7.10"
}

resource "aws_kinesis_stream" "demo_kinesis_stream" {
  name        = "demo-kinesis-stream"
  shard_count = "1"
}

resource "aws_s3_bucket" "demo_skipped_docs_bucket" {
  bucket = "demo-skipped-docs-bucket"
}

resource "aws_kinesis_firehose_delivery_stream" "demo_firehose_stream" {
  name        = "demo-firehose-delivery-stream"
  destination = "elasticsearch"

  s3_configuration {
    role_arn   = aws_iam_role.firehose_role.arn
    bucket_arn = aws_s3_bucket.demo_skipped_docs_bucket.arn
  }

  kinesis_source_configuration {
    kinesis_stream_arn = aws_kinesis_stream.demo_kinesis_stream.arn
    role_arn           = aws_iam_role.firehose_role.arn
  }

  elasticsearch_configuration {
    domain_arn = aws_elasticsearch_domain.demo_es_domain.arn
    role_arn   = aws_iam_role.firehose_role.arn
    index_name = "test"
    type_name  = "test"
  }
}