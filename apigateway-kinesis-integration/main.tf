data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "random_pet" "random" {
  length = 2
}

resource "aws_api_gateway_rest_api" "rest" {
  name = random_pet.random.id
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
  name                        = random_pet.random.id
  rest_api_id                 = aws_api_gateway_rest_api.rest.id
  validate_request_body       = true
  validate_request_parameters = true
}

resource "aws_iam_role" "apigw-role" {
  name               = "api_gateway_invocation"
  assume_role_policy = <<-EOF
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Sid": "",
          "Effect": "Allow",
          "Principal": {
            "Service": "apigateway.amazonaws.com"
          },
          "Action": "sts:AssumeRole"
        }
      ]
    }
  EOF
}

resource "aws_iam_policy" "put-record-policy" {
  name = "PutRecordPolicy"

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "kinesis:PutRecord",
            "Resource": "arn:aws:kinesis:${data.aws_region.current.name}:${data.aws_caller_identity.current
.account_id}:stream/${aws_kinesis_stream.stream.name}"
        }
    ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "apigwy_policy" {
  role       = aws_iam_role.apigw-role.name
  policy_arn = aws_iam_policy.put-record-policy.arn
}

resource "aws_api_gateway_integration" "integration" {
  rest_api_id             = aws_api_gateway_rest_api.rest.id
  resource_id             = aws_api_gateway_resource.ingest.id
  http_method             = aws_api_gateway_method.method.http_method
  integration_http_method = "POST"
  type                    = "AWS"
  credentials             = aws_iam_role.apigw-role.arn
  uri                     = "arn:aws:apigateway:${data.aws_region.current.name}:kinesis:action/PutRecord"

  passthrough_behavior = "NEVER"

  request_parameters = {
    "integration.request.header.Content-Type" = "'application/x-amz-json-1.1'"
  }

  request_templates = {
    "application/json" = <<EOT
       {
        "Data": "$util.base64Encode($input.body)",
        "PartitionKey": "$util.escapeJavaScript($input.params('ingest'))",
        "StreamName": "timeseries-ingest-stream"
       }
    EOT
  }
}

resource "aws_api_gateway_method_response" "status_code_200" {
  http_method = aws_api_gateway_method.method.http_method
  resource_id = aws_api_gateway_resource.ingest.id
  rest_api_id = aws_api_gateway_rest_api.rest.id
  status_code = 200

  response_parameters = {
    "method.response.header.Content-Type"                = true
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}


resource "aws_api_gateway_method_response" "status_code_400" {
  http_method = aws_api_gateway_method.method.http_method
  resource_id = aws_api_gateway_resource.ingest.id
  rest_api_id = aws_api_gateway_rest_api.rest.id
  status_code = 400

  response_parameters = {
    "method.response.header.Content-Type"                = true
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}


resource "aws_api_gateway_integration_response" "integration_success_response" {
  rest_api_id = aws_api_gateway_rest_api.rest.id
  resource_id = aws_api_gateway_resource.ingest.id
  http_method = aws_api_gateway_method.method.http_method
  status_code = aws_api_gateway_method_response.status_code_200.status_code

  response_parameters = {
    "method.response.header.Content-Type"                = "'application/json'"
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }

  response_templates = {
    "application/json" = <<EOT
      {
        "state": "ok"
      }
    EOT
  }

  depends_on = [aws_api_gateway_integration.integration]
}

resource "aws_api_gateway_integration_response" "integration_error_response" {
  rest_api_id = aws_api_gateway_rest_api.rest.id
  resource_id = aws_api_gateway_resource.ingest.id
  http_method = aws_api_gateway_method.method.http_method
  status_code = aws_api_gateway_method_response.status_code_400.status_code

  selection_pattern = "4\\d{2}"

  response_templates = {
    "application/json" = <<EOT
      {
        "state": "error",
        "message": "$util.escapeJavaScript($input.path('$.errorMessage'))"
      }
    EOT
  }

  response_parameters = {
    "method.response.header.Content-Type"                = "'application/json'"
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }

  depends_on = [aws_api_gateway_integration.integration]
}

resource "aws_api_gateway_deployment" "deployment" {
  rest_api_id = aws_api_gateway_rest_api.rest.id
  stage_name  = "dev"
  depends_on  = [aws_api_gateway_integration.integration]
}


resource "aws_kinesis_stream" "stream" {
  name        = "timeseries-ingest-stream"
  shard_count = "3"

  retention_period = 30

  shard_level_metrics = [
    "IncomingBytes",
    "OutgoingBytes",
    "OutgoingRecords",
    "ReadProvisionedThroughputExceeded",
    "WriteProvisionedThroughputExceeded",
    "IncomingRecords",
    "IteratorAgeMilliseconds",
  ]

}

resource "aws_iam_role" "role" {
  name                = random_pet.random.id
  path                = "/"
  managed_policy_arns = ["arn:aws:iam::aws:policy/AmazonKinesisFullAccess"]
  assume_role_policy  = <<POLICY
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
