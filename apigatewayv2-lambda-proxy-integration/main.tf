data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "random_pet" "random" {
  length = 2
}

resource "aws_apigatewayv2_api" "api" {
  name          = random_pet.random.id
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "package" {
  api_id                 = aws_apigatewayv2_api.api.id
  integration_type       = "AWS_PROXY"
  payload_format_version = "2.0"
  integration_method     = "POST"
  integration_uri        = aws_lambda_function.package.invoke_arn
}

resource "aws_apigatewayv2_integration" "package_payload" {
  api_id                 = aws_apigatewayv2_api.api.id
  integration_type       = "AWS_PROXY"
  payload_format_version = "2.0"
  integration_method     = "POST"
  integration_uri        = aws_lambda_function.package_payload.invoke_arn
}

resource "aws_apigatewayv2_route" "package" {
  api_id             = aws_apigatewayv2_api.api.id
  route_key          = "POST /package"
  target             = "integrations/${aws_apigatewayv2_integration.package.id}"
  authorization_type = "NONE"
}

resource "aws_apigatewayv2_route" "package_payload" {
  api_id             = aws_apigatewayv2_api.api.id
  route_key          = "POST /package/{id}/payloads"
  target             = "integrations/${aws_apigatewayv2_integration.package_payload.id}"
  authorization_type = "NONE"
}

resource "aws_apigatewayv2_route" "default" {
  api_id             = aws_apigatewayv2_api.api.id
  route_key          = "$default"
  target             = "integrations/${aws_apigatewayv2_integration.package.id}"
  authorization_type = "NONE"
}

resource "aws_lambda_function" "package" {
  filename      = "lambda.zip"
  function_name = "package"
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

resource "aws_lambda_permission" "default" {
  statement_id  = "AllowExecutionFromAPIGateway_default"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.package.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "arn:aws:execute-api:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${aws_apigatewayv2_api.api.id}/$default/$default"
}

resource "aws_lambda_permission" "package" {
  statement_id  = "AllowExecutionFromAPIGateway_package"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.package.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "arn:aws:execute-api:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${aws_apigatewayv2_api.api.id}/*/*"
}

resource "aws_lambda_permission" "package_payload" {
  statement_id  = "AllowExecutionFromAPIGateway_package_payload"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.package_payload.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "arn:aws:execute-api:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${aws_apigatewayv2_api.api.id}/*/*"
}

resource "aws_lambda_function" "package_payload" {
  filename      = "lambda.zip"
  function_name = "package_payload"
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

# add lambda cloudwatch logs
resource "aws_iam_role_policy" "lambda_logs" {
  name = random_pet.random.id
  role = aws_iam_role.role.id

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    }
  ]
}
POLICY
}

resource "aws_cloudwatch_log_group" "access_logs" {
  name              = random_pet.random.id
  retention_in_days = 1
}

resource "aws_apigatewayv2_stage" "stage" {
  api_id = aws_apigatewayv2_api.api.id
  name   = "dev"

  auto_deploy = true

  # enable access logging
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.access_logs.arn
    format          = "$context.identity.sourceIp - $context.identity.caller - $context.identity.user [$context.requestTime] \"$context.httpMethod $context.routeKey $context.protocol\" $context.status $context.responseLength $context.requestId"
  }
}

resource "aws_apigatewayv2_deployment" "deployment" {
  api_id      = aws_apigatewayv2_api.api.id
  description = "HTTP API deployment"

  triggers = {
    redeployment = sha1(join(",", tolist([
      jsonencode(aws_apigatewayv2_integration.package),
      jsonencode(aws_apigatewayv2_route.package),
    ])))
  }

  lifecycle {
    create_before_destroy = true
  }
}
