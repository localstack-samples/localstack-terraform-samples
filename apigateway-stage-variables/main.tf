data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

resource "random_pet" "random" {
  length = 2
}

resource "aws_api_gateway_rest_api" "api" {
  name        = random_pet.random.id
  description = "Sample showing use of stage variables"
}

resource "aws_api_gateway_resource" "resource" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "test"
}

resource "aws_api_gateway_method" "method" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.resource.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "integration" {
  type                    = "AWS"
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.resource.id
  http_method             = aws_api_gateway_method.method.http_method
  integration_http_method = "POST" # Must be POST for invoking Lambda function

  uri = "arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/arn:aws:lambda:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:function:$${stageVariables.lambdaFunction}/invocations"

  request_templates = {
    "application/json" = <<EOF
#set($inputRoot = $input.json('$'))
{
  "version": "$stageVariables.version"
}
EOF
  }

  depends_on = [aws_api_gateway_method.method]
}

resource "aws_api_gateway_method_response" "response_200" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.resource.id
  http_method = aws_api_gateway_method.method.http_method
  status_code = "200"
  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration_response" "integration_response_200" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.resource.id
  http_method = aws_api_gateway_method.method.http_method
  status_code = aws_api_gateway_method_response.response_200.status_code

  depends_on = [
    aws_api_gateway_integration.integration,
    aws_api_gateway_method_response.response_200
  ]
}

resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/*/*"
}

resource "aws_lambda_function" "lambda" {
  filename         = "lambda.zip"
  function_name    = random_pet.random.id
  role             = aws_iam_role.role.arn
  handler          = "lambda.handler"
  source_code_hash = filebase64sha256("lambda.zip")

  runtime = "nodejs20.x"

  environment {
    variables = {
      foo = "bar"
    }
  }
}

resource "aws_iam_role" "role" {
  name = "myrole"

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

resource "aws_api_gateway_deployment" "dev" {
  depends_on = [
    aws_api_gateway_integration.integration,
    aws_api_gateway_integration_response.integration_response_200
  ]

  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name  = "dev"
  variables = {
    "lambdaFunction" = random_pet.random.id
    "version"        = "beta-version"
  }
}
