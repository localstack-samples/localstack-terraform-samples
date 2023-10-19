resource "random_pet" "random" {
  length    = 2
  separator = "-"
}

resource "aws_apigatewayv2_api" "example" {
  name                       = random_pet.random.id
  protocol_type              = "WEBSOCKET"
  route_selection_expression = "$request.body.action"
}

resource "aws_apigatewayv2_authorizer" "example" {
  name             = random_pet.random.id
  api_id           = aws_apigatewayv2_api.example.id
  authorizer_uri   = aws_lambda_function.lambda_auth.invoke_arn
  authorizer_type  = "REQUEST"
  identity_sources = ["route.request.header.Authorization"]
}

resource "aws_apigatewayv2_route" "route" {
  api_id                              = aws_apigatewayv2_api.example.id
  route_key                           = "$connect"
  route_response_selection_expression = "$default"
  target                              = "integrations/${aws_apigatewayv2_integration.example.id}"
  authorizer_id                       = aws_apigatewayv2_authorizer.example.id
  authorization_type                  = "JWT"
}

resource "aws_apigatewayv2_route" "default_route" {
  api_id                              = aws_apigatewayv2_api.example.id
  route_key                           = "$default"
  route_response_selection_expression = "$default"
  target                              = "integrations/${aws_apigatewayv2_integration.example.id}"
  authorizer_id                       = aws_apigatewayv2_authorizer.example.id
  authorization_type                  = "JWT"
}


resource "aws_apigatewayv2_integration" "example" {
  api_id                 = aws_apigatewayv2_api.example.id
  integration_type       = "AWS_PROXY"
  payload_format_version = "1.0"
  integration_method     = "ANY"
  integration_uri        = aws_lambda_function.lambda.invoke_arn
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
