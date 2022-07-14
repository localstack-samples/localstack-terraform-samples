variable "region" {
  default = "eu-west-1"
}

resource "aws_iam_role" "role_auth" {
  name = "role-auth"

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

resource "aws_lambda_function" "lambda_auth" {
  filename      = "lambda-auth.zip"
  function_name = "lambda-auth"
  role          = aws_iam_role.role_auth.arn
  handler       = "lambda-auth.handler"

  source_code_hash = filebase64sha256("lambda-auth.zip")

  runtime = "nodejs12.x"

  environment {
    variables = {
      foo = "bar"
    }
  }
}

resource "aws_iam_role_policy_attachment" "lambda_policy_auth" {
  role       = aws_iam_role.role_auth.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role" "role" {
  name = "role"

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

resource "aws_lambda_function" "lambda" {
  filename      = "lambda-connect.zip"
  function_name = "lambda"
  role          = aws_iam_role.role.arn
  handler       = "lambda-connect.handler"
  runtime       = "nodejs12.x"

  source_code_hash = filebase64sha256("lambda-connect.zip")

  environment {
    variables = {
      foo = "bar"
    }
  }
}

resource "aws_lambda_function" "lambda_disconnect" {
  filename      = "lambda-disconnect.zip"
  function_name = "lambda-disconnect"
  role          = aws_iam_role.role.arn
  handler       = "lambda-disconnect.handler"
  runtime       = "nodejs12.x"

  source_code_hash = filebase64sha256("lambda-disconnect.zip")

  environment {
    variables = {
      foo = "bar"
    }
  }
}

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name              = "/aws/lambda/${aws_lambda_function.lambda.function_name}"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_group" "lambda_log_group_auth" {
  name              = "/aws/lambda/${aws_lambda_function.lambda_auth.function_name}"
  retention_in_days = 30
}

resource "aws_apigatewayv2_api" "ws" {
  name                       = "websocket-api"
  protocol_type              = "WEBSOCKET"
  route_selection_expression = "$request.body.action"
}

resource "aws_apigatewayv2_authorizer" "authorizer" {
  api_id           = aws_apigatewayv2_api.ws.id
  authorizer_type  = "REQUEST"
  authorizer_uri   = aws_lambda_function.lambda_auth.invoke_arn
  identity_sources = ["route.request.header.HeaderAuth1"]
  name             = "authorizer"
}

resource "aws_apigatewayv2_route" "connect_route" {
  api_id             = aws_apigatewayv2_api.ws.id
  route_key          = "$connect"
  authorization_type = "CUSTOM"
  authorizer_id      = aws_apigatewayv2_authorizer.authorizer.id
  target             = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_apigatewayv2_route" "disconnect_route" {
  api_id             = aws_apigatewayv2_api.ws.id
  route_key          = "$disconnect"
  authorization_type = "NONE"
  target             = "integrations/${aws_apigatewayv2_integration.lambda_disconnect.id}"
}


resource "aws_apigatewayv2_integration" "lambda" {
  api_id             = aws_apigatewayv2_api.ws.id
  integration_type   = "AWS_PROXY"
  integration_uri    = aws_lambda_function.lambda.invoke_arn
  integration_method = "POST"
}

resource "aws_apigatewayv2_integration" "lambda_disconnect" {
  api_id             = aws_apigatewayv2_api.ws.id
  integration_type   = "AWS_PROXY"
  integration_uri    = aws_lambda_function.lambda_disconnect.invoke_arn
  integration_method = "POST"
}

data "aws_caller_identity" "current" {}
locals {
  account_id = data.aws_caller_identity.current.account_id
}

resource "aws_lambda_permission" "lambda_permission_auth" {
  statement_id  = "AllowExecutionFromAPIGatewayAuth"
  action        = "lambda:InvokeFunction"
  principal     = "apigateway.amazonaws.com"
  function_name = aws_lambda_function.lambda_auth.function_name
  source_arn    = "arn:aws:execute-api:${var.region}:${local.account_id}:${aws_apigatewayv2_api.ws.id}/authorizers/${aws_apigatewayv2_authorizer.authorizer.id}"
}

resource "aws_lambda_permission" "lambda_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:${var.region}:${local.account_id}:${aws_apigatewayv2_api.ws.id}/*/$connect"
}

resource "aws_apigatewayv2_deployment" "example" {
  api_id      = aws_apigatewayv2_api.ws.id
  description = "ws deployment"

  lifecycle {
    create_before_destroy = true
  }

  triggers = {
    redeployment = sha1(jsonencode(aws_apigatewayv2_api.ws.body))
  }
}

resource "aws_apigatewayv2_stage" "example" {
  deployment_id = aws_apigatewayv2_deployment.example.id
  api_id        = aws_apigatewayv2_api.ws.id
  name          = "beta"
}


resource "aws_iam_role" "cloudwatch" {
  name = "api_gateway_cloudwatch_global"

  assume_role_policy = <<EOF
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

resource "aws_iam_role_policy" "cloudwatch" {
  name = "default"
  role = aws_iam_role.cloudwatch.id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:DescribeLogGroups",
                "logs:DescribeLogStreams",
                "logs:PutLogEvents",
                "logs:GetLogEvents",
                "logs:FilterLogEvents"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_api_gateway_account" "demo" {
  cloudwatch_role_arn = aws_iam_role.cloudwatch.arn
}
