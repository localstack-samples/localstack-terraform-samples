data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "random_pet" "random" {
  length = 2
}

#
# API Gateway resources
#

resource "aws_api_gateway_rest_api" "rest" {
  name = random_pet.random.id
}

resource "aws_api_gateway_resource" "root" {
  rest_api_id = aws_api_gateway_rest_api.rest.id
  parent_id   = aws_api_gateway_rest_api.rest.root_resource_id
  path_part   = "api"
}

resource "aws_api_gateway_method" "method" {
  rest_api_id          = aws_api_gateway_rest_api.rest.id
  resource_id          = aws_api_gateway_resource.root.id
  http_method          = "ANY"
  authorization        = "NONE"
  request_validator_id = aws_api_gateway_request_validator.validator.id

  request_parameters = {
    "method.request.querystring.who" = true
  }
}

resource "aws_api_gateway_request_validator" "validator" {
  name                        = random_pet.random.id
  rest_api_id                 = aws_api_gateway_rest_api.rest.id
  validate_request_body       = true
  validate_request_parameters = true
}

#
# Permission for API Gateway to invoke Lambda
#
resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.producer.function_name
  principal     = "apigateway.amazonaws.com"

  # More: http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-control-access-using-iam-policies-to-invoke-api.html
  source_arn = "arn:aws:execute-api:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.rest.id}/*/${aws_api_gateway_method.method.http_method}${aws_api_gateway_resource.root.path}"
}

#
# API Gateway Integration call to Lambda
#
resource "aws_api_gateway_integration" "integration" {
  rest_api_id             = aws_api_gateway_rest_api.rest.id
  resource_id             = aws_api_gateway_resource.root.id
  http_method             = aws_api_gateway_method.method.http_method
  integration_http_method = "POST"
  type                    = "AWS"
  uri                     = aws_lambda_function.producer.invoke_arn
  passthrough_behavior    = "NEVER"

  request_parameters = {
    "integration.request.querystring.who" : "method.request.querystring.who"
    "integration.request.header.Content-Type" = "'application/json'"
  }

  request_templates = {
    "application/json" = <<EOT
       {
        "action": "sayHello"
       }
    EOT
  }
}

resource "aws_api_gateway_method_response" "status_code_200" {
  http_method = aws_api_gateway_method.method.http_method
  resource_id = aws_api_gateway_resource.root.id
  rest_api_id = aws_api_gateway_rest_api.rest.id
  status_code = 200

  response_parameters = {
    "method.response.header.Content-Type"                = true
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}


resource "aws_api_gateway_method_response" "status_code_400" {
  http_method = aws_api_gateway_method.method.http_method
  resource_id = aws_api_gateway_resource.root.id
  rest_api_id = aws_api_gateway_rest_api.rest.id
  status_code = 400

  response_parameters = {
    "method.response.header.Content-Type"                = true
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}


resource "aws_api_gateway_integration_response" "integration_success_response" {
  rest_api_id = aws_api_gateway_rest_api.rest.id
  resource_id = aws_api_gateway_resource.root.id
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
  resource_id = aws_api_gateway_resource.root.id
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

#
# Lambda function will push to Kinesis stream
#
resource "aws_lambda_function" "producer" {
  filename      = "producer.zip"
  function_name = "producer"
  role          = aws_iam_role.role.arn
  handler       = "producer.handler"

  source_code_hash = filebase64sha256("producer.zip")

  runtime = "nodejs12.x"

  environment {
    variables = {
      foo = "bar"
    }
  }
}

#
# Lambda function will read from Kinesis stream
#
resource "aws_lambda_function" "consumer" {
  filename      = "consumer.zip"
  function_name = "consumer"
  role          = aws_iam_role.role.arn
  handler       = "consumer.handler"

  source_code_hash = filebase64sha256("consumer.zip")

  runtime = "nodejs14.x"

  environment {
    variables = {
      foo = "bar"
    }
  }
}

#
# Push to lambda from Kinesis (event source mapping)
#
resource "aws_lambda_event_source_mapping" "example" {
  event_source_arn  = aws_kinesis_stream.stream.arn
  function_name     = aws_lambda_function.consumer.arn
  starting_position = "LATEST"
  batch_size        = 5
  enabled           = true
}

#
# Kinesis stream
#
resource "aws_kinesis_stream" "stream" {
  name        = "stream"
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
  name               = random_pet.random.id
  path               = "/"
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

## IAM Role Policies
resource "aws_iam_role_policy_attachment" "terraform_lambda_iam_policy_basic_execution" {
  role       = aws_iam_role.role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
resource "aws_iam_role_policy_attachment" "terraform_lambda_iam_policy_kinesis_execution" {
  role       = aws_iam_role.role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaKinesisExecutionRole"
}
