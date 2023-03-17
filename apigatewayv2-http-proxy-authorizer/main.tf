data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

resource "random_pet" "random" {
  length    = 2
  separator = "-"
}

resource "aws_apigatewayv2_api" "example" {
  name          = random_pet.random.id
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_authorizer" "example" {
  api_id           = aws_apigatewayv2_api.example.id
  authorizer_type  = "REQUEST"
  authorizer_uri   = aws_lambda_function.authorizer.invoke_arn
  identity_sources = ["$request.header.Cookie"]
  name             = "authorizer"
}

resource "aws_lambda_function" "authorizer" {
  filename      = "authorizer.zip"
  function_name = "authorizer"
  role          = aws_iam_role.role.arn
  handler       = "authorizer.handler"
  runtime       = "nodejs12.x"
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

resource "aws_apigatewayv2_route" "example" {
  api_id             = aws_apigatewayv2_api.example.id
  route_key          = "ANY /{proxy+}"
  authorization_type = "CUSTOM"
  authorizer_id      = aws_apigatewayv2_authorizer.example.id
  target             = "integrations/${aws_apigatewayv2_integration.example.id}"
}

resource "aws_apigatewayv2_integration" "example" {
  api_id                 = aws_apigatewayv2_api.example.id
  integration_type       = "AWS_PROXY"
  payload_format_version = "2.0"
  description            = "Lambda example"
  integration_method     = "ANY"
  integration_uri        = aws_lambda_function.lambda.invoke_arn
}

resource "aws_lambda_function" "lambda" {
  filename      = "lambda.zip"
  function_name = "lambda"
  role          = aws_iam_role.role.arn
  handler       = "lambda.handler"
  runtime       = "nodejs12.x"
}
