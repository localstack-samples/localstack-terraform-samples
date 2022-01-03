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
  request_parameters = var.request_parameters
}

# ANY /{proxy+}
resource "aws_api_gateway_method" "apigw-method_proxy" {
  rest_api_id        = aws_api_gateway_rest_api.apigw.id
  resource_id        = aws_api_gateway_resource.apigw-resource_proxy.id
  http_method        = var.http_method
  authorization      = var.authorization
  request_parameters = var.request_parameters
}

# ANY /api/{proxy+}
resource "aws_api_gateway_method" "apigw-method_api_proxy" {
  rest_api_id        = aws_api_gateway_rest_api.apigw.id
  resource_id        = aws_api_gateway_resource.apigw-resource_api_proxy.id
  http_method        = var.http_method
  authorization      = var.authorization
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

# integration /api
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
