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
