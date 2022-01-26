locals {
  authorizer_name = "${var.apigw_name}-authorizer"
}

# REST API
resource "aws_api_gateway_rest_api" "apigw" {
  name = var.apigw_name
}

# /api
resource "aws_api_gateway_resource" "apigw_resource_api" {
  rest_api_id = aws_api_gateway_rest_api.apigw.id
  parent_id   = aws_api_gateway_rest_api.apigw.root_resource_id
  path_part   = "api"
}

# /{proxy+}
resource "aws_api_gateway_resource" "apigw-resource_proxy" {
  rest_api_id = aws_api_gateway_rest_api.apigw.id
  parent_id   = aws_api_gateway_rest_api.apigw.root_resource_id
  path_part   = var.path_part
}

# /api/{proxy+}
resource "aws_api_gateway_resource" "apigw-resource_api_proxy" {
  rest_api_id = aws_api_gateway_rest_api.apigw.id
  parent_id   = aws_api_gateway_resource.apigw_resource_api.id
  path_part   = var.path_part
}

# ANY /api
resource "aws_api_gateway_method" "apigw-method_api" {
  rest_api_id        = aws_api_gateway_rest_api.apigw.id
  resource_id        = aws_api_gateway_resource.apigw_resource_api.id
  http_method        = var.http_method
  authorization      = var.authorization
  authorizer_id      = var.cognito_authorizer_enabled ? aws_api_gateway_authorizer.cognito_authorizer[0].id : var.authorizer_enabled ? aws_api_gateway_authorizer.authorizer[0].id : ""
  request_parameters = var.request_parameters
}

# ANY /{proxy+}
resource "aws_api_gateway_method" "apigw-method_proxy" {
  rest_api_id        = aws_api_gateway_rest_api.apigw.id
  resource_id        = aws_api_gateway_resource.apigw-resource_proxy.id
  http_method        = var.http_method
  authorization      = var.authorization
  authorizer_id      = var.cognito_authorizer_enabled ? aws_api_gateway_authorizer.cognito_authorizer[0].id : var.authorizer_enabled ? aws_api_gateway_authorizer.authorizer[0].id : ""
  request_parameters = var.request_parameters
}

# ANY /api/{proxy+}
resource "aws_api_gateway_method" "apigw-method_api_proxy" {
  rest_api_id        = aws_api_gateway_rest_api.apigw.id
  resource_id        = aws_api_gateway_resource.apigw-resource_api_proxy.id
  http_method        = var.http_method
  authorization      = var.authorization
  authorizer_id      = var.cognito_authorizer_enabled ? aws_api_gateway_authorizer.cognito_authorizer[0].id : var.authorizer_enabled ? aws_api_gateway_authorizer.authorizer[0].id : ""
  request_parameters = var.request_parameters
}


# integration /api/{proxy+}
resource "aws_api_gateway_integration" "apigw-integration-api-proxy" {
  rest_api_id             = aws_api_gateway_rest_api.apigw.id
  resource_id             = aws_api_gateway_resource.apigw-resource_api_proxy.id
  http_method             = aws_api_gateway_method.apigw-method_api_proxy.http_method
  type                    = var.integration_type
  integration_http_method = var.integration_http_method
  uri                     = var.integration_uri
  passthrough_behavior    = var.integration_passthrough_behaviour
  request_parameters      = var.integration_request_parameters
}

# # integration /api
resource "aws_api_gateway_integration" "apigw-integration-api" {
  rest_api_id             = aws_api_gateway_rest_api.apigw.id
  resource_id             = aws_api_gateway_resource.apigw_resource_api.id
  http_method             = aws_api_gateway_method.apigw-method_api.http_method
  type                    = var.integration_type
  integration_http_method = var.integration_http_method
  uri                     = var.integration_uri
  passthrough_behavior    = var.integration_passthrough_behaviour
  request_parameters      = var.integration_request_parameters
}

# integration /{proxy+}
resource "aws_api_gateway_integration" "apigw-integration-proxy" {
  rest_api_id             = aws_api_gateway_rest_api.apigw.id
  resource_id             = aws_api_gateway_resource.apigw-resource_proxy.id
  http_method             = aws_api_gateway_method.apigw-method_proxy.http_method
  type                    = var.integration_type
  integration_http_method = var.integration_http_method
  uri                     = var.integration_uri
  passthrough_behavior    = var.integration_passthrough_behaviour
  request_parameters      = var.integration_request_parameters

}

# lambda authorizer
resource "aws_api_gateway_authorizer" "authorizer" {
  count                  = var.authorizer_enabled ? 1 : 0
  name                   = local.authorizer_name
  rest_api_id            = aws_api_gateway_rest_api.apigw.id
  authorizer_uri         = var.authorizer_invoke_arn
  authorizer_credentials = aws_iam_role.invocation_role[count.index].arn
}

# cognito authorizer
resource "aws_api_gateway_authorizer" "cognito_authorizer" {
  count = var.cognito_authorizer_enabled ? 1 : 0

  name          = "CognitoUserPoolAuthorizer"
  type          = "COGNITO_USER_POOLS"
  rest_api_id   = aws_api_gateway_rest_api.apigw.id
  provider_arns = [var.cognito_pool_arn]
}


resource "aws_iam_role" "invocation_role" {
  count = var.authorizer_enabled ? 1 : 0

  name = "api_gateway_auth_invocation"
  path = "/"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "apigateway.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "invocation_policy" {
  count = var.authorizer_enabled ? 1 : 0

  name = "default"
  role = aws_iam_role.invocation_role[count.index].id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "lambda:InvokeFunction",
      "Effect": "Allow",
      "Resource": "${var.authorizer_arn}"
    }
  ]
}
EOF
}


output "rest_api_id" {
  value = aws_api_gateway_rest_api.apigw.*.id
}
