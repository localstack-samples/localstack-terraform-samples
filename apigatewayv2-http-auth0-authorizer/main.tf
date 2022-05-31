variable "auth0_tenant_domain_url" {
	default = "https://localstack-dev.eu.auth0.com"
}

resource "aws_apigatewayv2_api" "example" {
  name          = "example-http-api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_authorizer" "user" {
  api_id           = aws_apigatewayv2_api.example.id
  authorizer_type  = "JWT"
  identity_sources = ["$request.header.Authorization"]
	name             = "user-authorizer"

	jwt_configuration {
		audience = ["https://auth0-jwt-authorizer"]
    issuer   = var.auth0_tenant_domain_url
  }
}

resource "aws_apigatewayv2_integration" "user" {
  api_id                 = aws_apigatewayv2_api.example.id
  integration_type       = "AWS_PROXY"
  payload_format_version = "2.0"
  description            = "Lambda example"
  integration_method     = "POST"
  integration_uri        = aws_lambda_function.user.invoke_arn
}

resource "aws_apigatewayv2_route" "user" {
  api_id             = aws_apigatewayv2_api.example.id
  route_key          = "ANY /users/user"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.user.id
  target             = "integrations/${aws_apigatewayv2_integration.user.id}"

}

resource "aws_lambda_function" "user" {
  filename      = "lambda.zip"
  function_name = "myadminlambda"
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
