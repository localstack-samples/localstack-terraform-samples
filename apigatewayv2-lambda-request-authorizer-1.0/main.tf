variable "region" {
  default = "eu-west-1"
}

resource "random_pet" "random_name" {
  length = 2
}

#
# Create an API Gateway HTTP API
#
resource "aws_apigatewayv2_api" "apigw" {
  name          = random_pet.random_name.id
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["POST", "GET"]
    allow_headers = ["content-type", "Authorization"]
  }
}

resource "aws_cloudwatch_log_group" "apigateway" {
  name              = "/aws/apigateway/${aws_apigatewayv2_api.apigw.name}"
  retention_in_days = 30
}

resource "aws_iam_role" "apigateway" {
  name               = "apigateway"
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "apigateway.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
POLICY
}

resource "aws_apigatewayv2_route" "example" {
  api_id             = aws_apigatewayv2_api.apigw.id
  route_key          = "ANY /example/{proxy+}"
  authorization_type = "CUSTOM"
  authorizer_id      = aws_apigatewayv2_authorizer.authorizer.id
  target             = "integrations/${aws_apigatewayv2_integration.example.id}"
}

resource "aws_apigatewayv2_authorizer" "authorizer" {
  name                              = "example-authorizer"
  api_id                            = aws_apigatewayv2_api.apigw.id
  authorizer_type                   = "REQUEST"
  authorizer_uri                    = aws_lambda_function.lambda_auth.invoke_arn
  identity_sources                  = ["$request.header.Authorization"]
  authorizer_payload_format_version = "1.0"
  enable_simple_responses           = false
}

resource "aws_lambda_permission" "authorizer_lambda_permission" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_auth.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.apigw.execution_arn}/authorizers/${aws_apigatewayv2_authorizer.authorizer.id}"
}

resource "aws_apigatewayv2_integration" "example" {
  api_id                 = aws_apigatewayv2_api.apigw.id
  integration_type       = "AWS_PROXY"
  payload_format_version = "2.0"
  integration_method     = "POST"
  integration_uri        = aws_lambda_function.lambda.invoke_arn

  request_parameters = {
    "overwrite:header.x-syna-accountalias" : "$context.authorizer.accountAlias"
    "overwrite:header.x-syna-accountid" : "$context.authorizer.accountId"
    "overwrite:header.x-syna-permissions" : "$context.authorizer.permissions"
    "overwrite:header.x-syna-projectid" : "$context.authorizer.projectId"
    "overwrite:header.x-syna-tenantid" : "$context.authorizer.tenantId"
    "overwrite:header.x-syna-userid" : "$context.authorizer.userId"
  }
}

resource "aws_lambda_permission" "apigw_to_lambda" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.apigw.execution_arn}/*/*"
}

resource "aws_apigatewayv2_stage" "testing" {
  api_id      = aws_apigatewayv2_api.apigw.id
  name        = "testing"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.apigateway.arn
    format          = jsonencode({
      "requestId" : "$context.requestId"
      "ip" : "$context.identity.sourceIp"
      "requestTime" : "$context.requestTime"
      "httpMethod" : "$context.httpMethod"
      "routeKey" : "$context.routeKey"
      "status" : "$context.status"
      "protocol" : "$context.protocol"
      "responseLength" : "$context.responseLength"
      "authorizationError": "$context.authorizer.error"
    })
  }
}

resource "aws_apigatewayv2_deployment" "example" {
  api_id      = aws_apigatewayv2_api.apigw.id
  description = "deployment"

  depends_on = [aws_apigatewayv2_route.example]
  lifecycle {
    create_before_destroy = true
  }
}

#
# Lambdas
#
resource "aws_iam_role" "role" {
  name = random_pet.random_name.id

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

resource "aws_iam_role_policy_attachment" "lambda_policy_auth" {
  role       = aws_iam_role.role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "lambda_auth" {
  role          = aws_iam_role.role.arn
  filename      = "lambda-auth.zip"
  handler       = "lambda_auth.handler"
  function_name = "lambda-auth"

  source_code_hash = filebase64sha256("lambda-auth.zip")

  runtime = "nodejs14.x"
}

resource "aws_lambda_function" "lambda" {
  role          = aws_iam_role.role.arn
  filename      = "lambda.zip"
  handler       = "lambda.handler"
  function_name = "lambda"

  source_code_hash = filebase64sha256("lambda.zip")

  runtime = "nodejs14.x"

  environment {
    variables = {
      foo = "bar"
    }
  }
}
