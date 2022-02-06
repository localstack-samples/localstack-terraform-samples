variable "region" {
	default = "eu-west-1"
}

resource "aws_api_gateway_rest_api" "rest" {
  name = "API Gateway to Kinesis"
}

resource "aws_api_gateway_resource" "ingest" {
  rest_api_id = aws_api_gateway_rest_api.rest.id
  parent_id   = aws_api_gateway_rest_api.rest.root_resource_id
  path_part   = "{ingest}"
}

resource "aws_api_gateway_method" "method" {
  rest_api_id   = aws_api_gateway_rest_api.rest.id
  resource_id   = aws_api_gateway_resource.ingest.id
  http_method   = "POST"
	authorization = "NONE"
	request_models = {
		"application/json" = aws_api_gateway_model.model.name
	}
	request_validator_id = aws_api_gateway_request_validator.validator.id
}

resource "aws_api_gateway_model" "model" {
  rest_api_id  = aws_api_gateway_rest_api.rest.id
  name         = "packet"
  description  = "packet format"
  content_type = "application/json"

  schema = <<EOF
{"$schema":"http://json-schema.org/draft-04/schema#","title":"Todos","type":"object","properties":{"HID":{"type":"string"},"SID":{"type":"string"},"Data":{"type":"object"}},"required":["HID","SID","Data"]}
EOF
}

resource "aws_api_gateway_request_validator" "validator" {
  name                        = "demo-validator"
  rest_api_id                 = aws_api_gateway_rest_api.rest.id
  validate_request_body       = true
  validate_request_parameters = false
}

resource "aws_api_gateway_integration" "integration" {
  rest_api_id             = aws_api_gateway_rest_api.rest.id
  resource_id             = aws_api_gateway_resource.ingest.id
  http_method             = aws_api_gateway_method.method.http_method
  integration_http_method = "POST"
  type                    = "AWS"
	credentials = ""
	uri                     = "arn:aws:apigateway:${var.region}:kinesis:action/PutRecord"

 request_parameters = {
    "integration.request.header.Content-Type" = "'application/x-amz-json-1.1'"
  }
  request_templates = {
    "application/json" = <<EOT
       {
        "Data": "$util.base64Encode($input.body)",
        "PartitionKey1": "$util.escapeJavaScript($input.params('ingest'))",
        "StreamName": "timeseries-ingest-stream"
       }
    EOT
  }
}

resource "aws_iam_role" "role" {
  name = "myrole"
	path = "/"
	managed_policy_arns = ["arn:aws:iam::aws:policy/AmazonKinesisFullAccess"]
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
