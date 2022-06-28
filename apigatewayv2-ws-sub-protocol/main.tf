provider "aws" {
	region                      = "eu-west-1"
}

resource "aws_apigatewayv2_api" "ws" {
  name                       = "websocket-api"
  protocol_type              = "WEBSOCKET"
  route_selection_expression = "$request.body.action"
}

resource "aws_apigatewayv2_authorizer" "example" {
  api_id           = aws_apigatewayv2_api.ws.id
  authorizer_type  = "REQUEST"
  authorizer_uri   = aws_lambda_function.lambda_auth.invoke_arn
  identity_sources = ["route.request.header.Authorization"]
  name             = "authorizer"
}

resource "aws_apigatewayv2_route" "example" {
  api_id    = aws_apigatewayv2_api.ws.id
	route_key = "$connect"
	authorization_type = "CUSTOM"
	authorizer_id = aws_apigatewayv2_authorizer.example.id
	target = "integrations/${aws_apigatewayv2_integration.example.id}"
}

resource "aws_lambda_function" "lambda_auth" {
  filename      = "lambda-auth.zip"
  function_name = "lambda-auth"
  role          = aws_iam_role.role.arn
  handler       = "lambda-auth.handler"

  source_code_hash = filebase64sha256("lambda-auth.zip")

  runtime = "nodejs12.x"

  environment {
    variables = {
      foo = "bar"
    }
  }
}

resource "aws_apigatewayv2_integration" "example" {
  api_id           = aws_apigatewayv2_api.ws.id
  integration_type = "AWS_PROXY"
	integration_uri           = aws_lambda_function.lambda.invoke_arn
	integration_method        = "POST"
	connection_type           = "INTERNET"
}

resource "aws_lambda_function" "lambda" {
  filename      = "lambda.zip"
  function_name = "mylambda"
  role          = aws_iam_role.role.arn
  handler       = "lambda.handler"
	runtime       = "nodejs12.x"

	source_code_hash = filebase64sha256("lambda.zip")

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

resource "aws_lambda_permission" "lambda_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "apigateway.amazonaws.com"
	source_arn = "${aws_apigatewayv2_api.ws.execution_arn}/*/*/*"
}


resource "aws_apigatewayv2_deployment" "example" {
  api_id      = aws_apigatewayv2_route.example.api_id
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
  api_id = aws_apigatewayv2_api.ws.id
  name   = "beta"
}
