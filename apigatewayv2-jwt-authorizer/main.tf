data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

resource "random_pet" "random" {
  length    = 2
  separator = "-"
}

resource "aws_apigatewayv2_api" "api" {
  name          = random_pet.random.id
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_authorizer" "user" {
  api_id           = aws_apigatewayv2_api.api.id
  authorizer_type  = "JWT"
  identity_sources = ["$request.header.Authorization"]
  name             = "${random_pet.random.id}-user-authorizer"

  jwt_configuration {
    audience = [aws_cognito_user_pool_client.client.id]
    //issuer = "https://${aws_cognito_user_pool.pool.endpoint}"
    issuer = "http://localhost:4566/${basename(aws_cognito_user_pool.pool.endpoint)}"
  }
}

resource "aws_apigatewayv2_authorizer" "admin" {
  api_id           = aws_apigatewayv2_api.api.id
  authorizer_type  = "JWT"
  identity_sources = ["$request.header.Authorization"]
  name             = "${random_pet.random.id}-admin-authorizer"

  jwt_configuration {
    audience = [aws_cognito_user_pool_client.client.id]
    issuer   = "http://localhost:4566/${basename(aws_cognito_user_pool.pool.endpoint)}"
    //issuer = "https://${aws_cognito_user_pool.pool.endpoint}"
  }
}

resource "aws_apigatewayv2_integration" "user" {
  api_id                 = aws_apigatewayv2_api.api.id
  integration_type       = "AWS_PROXY"
  payload_format_version = "1.0"
  description            = "Lambda user integration"
  integration_method     = "POST"
  integration_uri        = aws_lambda_function.user.invoke_arn
}

resource "aws_apigatewayv2_integration" "admin" {
  api_id                 = aws_apigatewayv2_api.api.id
  integration_type       = "AWS_PROXY"
  payload_format_version = "2.0"
  description            = "Lambda admin integration"
  integration_method     = "POST"
  integration_uri        = aws_lambda_function.admin.invoke_arn
}

resource "aws_apigatewayv2_route" "user" {
  api_id             = aws_apigatewayv2_api.api.id
  route_key          = "ANY /users/user"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.user.id
  target             = "integrations/${aws_apigatewayv2_integration.user.id}"

}
resource "aws_apigatewayv2_route" "admin" {
  api_id             = aws_apigatewayv2_api.api.id
  route_key          = "ANY /users/admin"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.admin.id
  target             = "integrations/${aws_apigatewayv2_integration.admin.id}"
}

resource "aws_apigatewayv2_stage" "stage" {
  api_id = aws_apigatewayv2_api.api.id
  name   = "dev"
}

resource "aws_cognito_user_pool" "pool" {
  name = random_pet.random.id

  account_recovery_setting {
    recovery_mechanism {
      name     = "admin_only"
      priority = 1
    }
  }
}

resource "aws_cognito_resource_server" "resource" {
  identifier   = random_pet.random.id
  name         = random_pet.random.id
  user_pool_id = aws_cognito_user_pool.pool.id

  scope {
    scope_name        = "localstack"
    scope_description = "read access to localstack"
  }
}

resource "aws_cognito_user_pool_client" "client" {
  name                 = random_pet.random.id
  user_pool_id         = aws_cognito_user_pool.pool.id
  allowed_oauth_flows  = ["client_credentials"]
  allowed_oauth_scopes = aws_cognito_resource_server.resource.scope_identifiers
  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH"
  ]
  supported_identity_providers         = ["COGNITO"]
  allowed_oauth_flows_user_pool_client = true
  generate_secret                      = true
}

resource "aws_cognito_user_pool_domain" "domain" {
  domain       = random_pet.random.id
  user_pool_id = aws_cognito_user_pool.pool.id
}

resource "aws_lambda_function" "admin" {
  filename      = "admin.zip"
  function_name = "${random_pet.random.id}-admin"
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

resource "aws_lambda_permission" "apigateway_admin" {
  statement_id  = "AllowExecutionFromAPIGateway-admin"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.admin.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "arn:aws:execute-api:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${aws_apigatewayv2_api.api.id}/*"
}


resource "aws_lambda_permission" "apigateway_user" {
  statement_id  = "AllowExecutionFromAPIGateway-user"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.user.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "arn:aws:execute-api:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${aws_apigatewayv2_api.api.id}/*"
}


resource "aws_lambda_function" "user" {
  filename      = "lambda.zip"
  function_name = "${random_pet.random.id}-user"
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

resource "aws_iam_role_policy_attachment" "lambda_policy_auth" {
  role       = aws_iam_role.role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}


output "user_pool_client_id" {
  value = aws_cognito_user_pool_client.client.id
}

output "user_pool_id" {
  value = aws_cognito_user_pool.pool.id
}

output "secret_token" {
  value     = aws_cognito_user_pool_client.client.client_secret
  sensitive = true
}
