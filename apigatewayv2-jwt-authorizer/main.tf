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
		audience = [aws_cognito_user_pool_client.client.id]
		issuer   = "http://localhost:4566/${basename(aws_cognito_user_pool.pool.endpoint)}"
  }
}

resource "aws_apigatewayv2_authorizer" "admin" {
  api_id           = aws_apigatewayv2_api.example.id
  authorizer_type  = "JWT"
  identity_sources = ["$request.header.Authorization"]
  name             = "admin-authorizer"

  jwt_configuration {
		audience = [aws_cognito_user_pool_client.client.id]
		issuer   = "http://localhost:4566/${basename(aws_cognito_user_pool.pool.endpoint)}"
  }
}

resource "aws_apigatewayv2_integration" "user" {
  api_id                 = aws_apigatewayv2_api.example.id
  integration_type       = "AWS_PROXY"
  payload_format_version = "2.0"
  description            = "Lambda example"
  integration_method     = "ANY"
  integration_uri        = aws_lambda_function.user.invoke_arn
}

resource "aws_apigatewayv2_integration" "admin" {
  api_id                 = aws_apigatewayv2_api.example.id
  integration_type       = "AWS_PROXY"
  payload_format_version = "2.0"
  description            = "Lambda example"
  integration_method     = "ANY"
  integration_uri        = aws_lambda_function.admin.invoke_arn
}

resource "aws_apigatewayv2_route" "user" {
  api_id               = aws_apigatewayv2_api.example.id
  route_key            = "ANY /users/user"
  authorization_type   = "CUSTOM"
	authorization_scopes = ["user@domain.com"]
  authorizer_id        = aws_apigatewayv2_authorizer.user.id
  target               = "integrations/${aws_apigatewayv2_integration.user.id}"

}
resource "aws_apigatewayv2_route" "admin" {
  api_id             = aws_apigatewayv2_api.example.id
  route_key          = "ANY /users/admin"
  authorization_type = "CUSTOM"
  authorizer_id      = aws_apigatewayv2_authorizer.admin.id
  target             = "integrations/${aws_apigatewayv2_integration.admin.id}"
}

resource "aws_cognito_user_pool" "pool" {
  name = "user_pool"
}

resource "aws_cognito_user_pool_client" "client" {
  name                 = "example_external_api"
  user_pool_id         = aws_cognito_user_pool.pool.id
  allowed_oauth_scopes = ["email"]
  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH"
  ]
  supported_identity_providers = ["COGNITO"]
}

resource "aws_lambda_function" "admin" {
  filename      = "admin.zip"
  function_name = "mylambda"
  role          = aws_iam_role.role.arn
  handler       = "admin.handler"

  source_code_hash = filebase64sha256("admin.zip")

  runtime = "nodejs12.x"

  environment {
    variables = {
      foo = "bar"
    }
  }
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

output "user_pool_client_id" {
  value = aws_cognito_user_pool_client.client.id
}

output "user_pool_id" {
  value = aws_cognito_user_pool.pool.id
}
