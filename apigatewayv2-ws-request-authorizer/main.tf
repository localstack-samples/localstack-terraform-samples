data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
locals {
  account_id = data.aws_caller_identity.current.account_id
}

resource "random_pet" "random" {
  length    = 2
  separator = "-"
}

resource "aws_apigatewayv2_api" "api" {
  name                       = random_pet.random.id
  protocol_type              = "WEBSOCKET"
  route_selection_expression = "$request.body.action"
}

resource "aws_apigatewayv2_authorizer" "authorizer" {
  name             = random_pet.random.id
  api_id           = aws_apigatewayv2_api.api.id
  authorizer_uri   = aws_lambda_function.lambda_auth.invoke_arn
  authorizer_type  = "REQUEST"
  identity_sources = ["route.request.header.Authorization"]
}

resource "aws_apigatewayv2_route" "route" {
  api_id                              = aws_apigatewayv2_api.api.id
  route_key                           = "$connect"
  route_response_selection_expression = "$default"
  target                              = "integrations/${aws_apigatewayv2_integration.integration.id}"
  authorizer_id                       = aws_apigatewayv2_authorizer.authorizer.id
  authorization_type                  = "CUSTOM"
}

resource "aws_apigatewayv2_route" "default_route" {
  api_id                              = aws_apigatewayv2_api.api.id
  route_key                           = "$default"
  route_response_selection_expression = "$default"
  target                              = "integrations/${aws_apigatewayv2_integration.integration.id}"
}


resource "aws_apigatewayv2_integration" "integration" {
  api_id                 = aws_apigatewayv2_api.api.id
  integration_type       = "AWS_PROXY"
  payload_format_version = "1.0"
  integration_method     = "POST"
  integration_uri        = aws_lambda_function.lambda.invoke_arn
}

resource "aws_apigatewayv2_stage" "stage" {
  api_id = aws_apigatewayv2_api.api.id
  name   = "dev"

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.log_group.arn
    format = jsonencode({
      "requestId" : "$context.requestId",
      "ip" : "$context.identity.sourceIp",
      "caller" : "$context.identity.caller",
      "user" : "$context.identity.user",
      "requestTime" : "$context.requestTime",
      "httpMethod" : "$context.httpMethod",
      "resourcePath" : "$context.resourcePath",
      "status" : "$context.status",
      "protocol" : "$context.protocol",
      "responseLength" : "$context.responseLength"
    })
  }
}

resource "aws_apigatewayv2_deployment" "deployment" {
  api_id = aws_apigatewayv2_api.api.id

  lifecycle {
    create_before_destroy = true
  }

  triggers = {
    redeployment = sha1(jsonencode(aws_apigatewayv2_integration.integration))
  }

  depends_on = [
    aws_apigatewayv2_route.route,
    aws_apigatewayv2_stage.stage
  ]
}

resource "aws_lambda_function" "lambda_auth" {
  function_name = "${random_pet.random.id}-auth"
  filename      = "lambda-auth.zip"
  role          = aws_iam_role.role.arn
  handler       = "lambda-auth.handler"

  source_code_hash = filebase64sha256("lambda-auth.zip")

  runtime = "nodejs18.x"

  environment {
    variables = {
      foo = "bar"
    }
  }
}

resource "aws_lambda_function" "lambda" {
  function_name = random_pet.random.id
  filename      = "lambda.zip"
  role          = aws_iam_role.role.arn
  handler       = "lambda.handler"

  source_code_hash = filebase64sha256("lambda.zip")

  runtime = "nodejs18.x"

  environment {
    variables = {
      foo = "bar"
    }
  }
}

resource "aws_iam_role" "role" {
  name = random_pet.random.id

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

resource "aws_lambda_permission" "lambda_permission_auth" {
  statement_id  = "AllowExecutionFromAPIGatewayAuth"
  action        = "lambda:InvokeFunction"
  principal     = "apigateway.amazonaws.com"
  function_name = aws_lambda_function.lambda_auth.function_name
  source_arn    = "arn:aws:execute-api:${data.aws_region.current.id}:${local.account_id}:${aws_apigatewayv2_api.api.id}/authorizers/${aws_apigatewayv2_authorizer.authorizer.id}"
}

resource "aws_lambda_permission" "lambda_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:${data.aws_region.current.id}:${local.account_id}:${aws_apigatewayv2_api.api.id}/*/$connect"
}


resource "aws_iam_role_policy_attachment" "lambda_policy_auth" {
  role       = aws_iam_role.role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}



resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name              = "/aws/lambda/${aws_lambda_function.lambda.function_name}"
  retention_in_days = 1
}

resource "aws_cloudwatch_log_group" "lambda_log_group_auth" {
  name              = "/aws/lambda/${aws_lambda_function.lambda_auth.function_name}"
  retention_in_days = 1
}

resource "aws_cloudwatch_log_group" "log_group" {
  name              = "/aws/api-gateway/${aws_apigatewayv2_api.api.id}"
  retention_in_days = 1
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

output "ws_endpoint" {
  value = aws_apigatewayv2_api.api.api_endpoint
}

output "deploy" {
  value = aws_apigatewayv2_deployment.deployment.auto_deployed
}
