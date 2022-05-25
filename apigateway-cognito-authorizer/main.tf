data "aws_caller_identity" "current" {}

# data "aws_region" "current" {
#   provider = aws.localstack
# }

# locals {
#   account_id = data.aws_caller_identity.current.account_id
#   region     = data.aws_region.current.name
#}


resource "aws_api_gateway_rest_api" "demo" {
  name        = "auth-demo"
  description = "cognito-authorization"
}

resource "aws_api_gateway_resource" "demo" {
  rest_api_id = aws_api_gateway_rest_api.demo.id
  parent_id   = aws_api_gateway_rest_api.demo.root_resource_id
  path_part   = "demo"
}

resource "aws_api_gateway_method" "any" {
  rest_api_id   = aws_api_gateway_rest_api.demo.id
  resource_id   = aws_api_gateway_resource.demo.id
  http_method   = "ANY"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.demo.id
}

resource "aws_api_gateway_authorizer" "demo" {
  name            = "demo"
  type            = "COGNITO_USER_POOLS"
  rest_api_id     = aws_api_gateway_rest_api.demo.id
  provider_arns   = [aws_cognito_user_pool.pool.arn]
  identity_source = "method.request.header.Authorization"
}

#
# Integration
#

resource "aws_api_gateway_integration" "integration" {
  rest_api_id             = aws_api_gateway_rest_api.demo.id
  resource_id             = aws_api_gateway_resource.demo.id
  http_method             = aws_api_gateway_method.any.http_method
  integration_http_method = "ANY"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda.invoke_arn
}

resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "apigateway.amazonaws.com"

  # More: http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-control-access-using-iam-policies-to-invoke-api.html
	#  source_arn = "arn:aws:execute-api:${local.region}:${local.account_id}:${aws_api_gateway_rest_api.demo.id}/*/${aws_api_gateway_method.any.http_method}${aws_api_gateway_resource.demo.path}"
  source_arn = "${aws_api_gateway_rest_api.demo.execution_arn}/*/*/*"
}


resource "aws_lambda_function" "lambda" {
  filename      = "lambda.zip"
  function_name = "mylambda"
  role          = aws_iam_role.role.arn
  handler       = "lambda.handler"

  source_code_hash = filebase64sha256("lambda.zip")

  runtime = "nodejs12.x"

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


#
# Cognito
#
resource "aws_cognito_user_pool" "pool" {
  name = "user_pool"
}

resource "aws_cognito_user_pool_client" "client" {
  name         = "example_external_api"
  user_pool_id = aws_cognito_user_pool.pool.id
  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH"
  ]
}

output "rest_api_id" {
  value = aws_api_gateway_rest_api.demo.id
}

output "user_pool_client_id" {
  value = aws_cognito_user_pool_client.client.id
}

output "user_pool_id" {
  value = aws_cognito_user_pool.pool.id
}
