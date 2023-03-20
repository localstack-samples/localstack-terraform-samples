data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

resource "random_pet" "random" {
  length    = 2
  separator = "-"
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
    issuer   = "https://${aws_cognito_user_pool.pool.endpoint}"
    //issuer = "http://localhost:4566/${basename(aws_cognito_user_pool.pool.endpoint)}"
  }
}

resource "aws_apigatewayv2_authorizer" "admin" {
  api_id           = aws_apigatewayv2_api.api.id
  authorizer_type  = "JWT"
  identity_sources = ["$request.header.Authorization"]
  name             = "${random_pet.random.id}-admin-authorizer"

  jwt_configuration {
    audience = [aws_cognito_user_pool_client.client.id]
    //issuer   = "http://localhost:4566/${basename(aws_cognito_user_pool.pool.endpoint)}"
    issuer = "https://${aws_cognito_user_pool.pool.endpoint}"
  }
}

resource "aws_apigatewayv2_integration" "user" {
  api_id                 = aws_apigatewayv2_api.api.id
  integration_type       = "HTTP_PROXY"
  payload_format_version = "1.0" // payload 2.0 not supported for HTTP_PROXY integrations
  description            = "HTTP user integration"
  integration_method     = "POST"
  integration_uri        = "https://httpbin.org/anything"
}

resource "aws_apigatewayv2_integration" "admin" {
  api_id                 = aws_apigatewayv2_api.api.id
  integration_type       = "HTTP_PROXY"
  payload_format_version = "1.0" // payload 2.0 not supported for HTTP_PROXY integrations
  description            = "HTTP admin integration"
  integration_method     = "POST"
  integration_uri        = "https://httpbin.org/anything"
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
