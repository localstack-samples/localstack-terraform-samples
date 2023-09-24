data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "random_pet" "random" {
  length = 2
}

resource "aws_api_gateway_rest_api" "api" {
  name        = random_pet.random.id
  description = "cognito-authorization"
}

resource "aws_api_gateway_resource" "resource" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "demo"
}

resource "aws_api_gateway_method" "method" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.resource.id
  http_method   = "ANY"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.authorizer.id
}

resource "aws_api_gateway_authorizer" "authorizer" {
  name            = "demo"
  type            = "COGNITO_USER_POOLS"
  rest_api_id     = aws_api_gateway_rest_api.api.id
  provider_arns   = [aws_cognito_user_pool.pool.arn]
  identity_source = "method.request.header.X-Auth-Token"
}

#
# Integration
#

resource "aws_api_gateway_integration" "integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.resource.id
  http_method             = aws_api_gateway_method.method.http_method
  integration_http_method = "ANY"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda.invoke_arn
}

resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "apigateway.amazonaws.com"

  # More: http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-control-access-using-iam-policies-to-invoke-api.html
  #  source_arn = "arn:aws:execute-api:${local.region}:${local.account_id}:${aws_api_gateway_rest_api.demo.id}/*/${aws_api_gateway_method.any.http_method}${aws_api_gateway_resource.demo.path}"
  source_arn = "${aws_api_gateway_rest_api.api.execution_arn}/*/*/*"
}

resource "aws_api_gateway_stage" "example" {
  deployment_id = aws_api_gateway_deployment.deployment.id
  rest_api_id   = aws_api_gateway_rest_api.api.id
  stage_name    = "dev"


  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.apigateway.arn
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

  depends_on = [aws_api_gateway_method.method]
}

resource "aws_cloudwatch_log_group" "apigateway" {
  name              = "/aws/apigateway/${aws_api_gateway_rest_api.api.name}"
  retention_in_days = 3
}

resource "aws_api_gateway_deployment" "deployment" {
  rest_api_id = aws_api_gateway_rest_api.api.id

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_method.method,
    aws_api_gateway_integration.integration
  ]
}

resource "aws_lambda_function" "lambda" {
  filename      = "lambda.zip"
  function_name = random_pet.random.id
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


#
# Cognito
#
resource "aws_cognito_user_pool" "pool" {
  name = random_pet.random.id

  auto_verified_attributes = ["email"]
  username_attributes      = ["email"]

  schema {
    name = "externalid"
    attribute_data_type = "String"
    mutable = true
    required = false
  }

  admin_create_user_config {
    allow_admin_create_user_only = true

  }
}

resource "aws_cognito_user_pool_client" "client" {
  name         = random_pet.random.id
  user_pool_id = aws_cognito_user_pool.pool.id

  supported_identity_providers = ["COGNITO"]

  allowed_oauth_flows = ["client_credentials"]
  allowed_oauth_scopes = [
    "${random_pet.random.id}/notification",
    "${random_pet.random.id}/cancellation",
  ]
  allowed_oauth_flows_user_pool_client = true
  generate_secret                      = true
  refresh_token_validity               = 7
}

resource "aws_cognito_resource_server" "resource_server" {
  name         = random_pet.random.id
  identifier   = random_pet.random.id
  user_pool_id = aws_cognito_user_pool.pool.id
  scope {
    scope_name        = "notification"
    scope_description = "for notification API calls"
  }
  scope {
    scope_name        = "cancellation"
    scope_description = "for cancellation API calls"
  }
}

resource "aws_cognito_user_pool_domain" "main" {
  domain       = random_pet.random.id
  user_pool_id = aws_cognito_user_pool.pool.id
}


output "rest_api_id" {
  value = aws_api_gateway_rest_api.api.id
}

output "user_pool_client_id" {
  value = aws_cognito_user_pool_client.client.id
}

output "user_pool_id" {
  value = aws_cognito_user_pool.pool.id
}
