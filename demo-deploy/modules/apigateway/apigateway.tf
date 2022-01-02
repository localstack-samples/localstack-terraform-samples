resource "aws_api_gateway_rest_api" "apigw" {
  name = var.apigw_name
}

resource "aws_api_gateway_resource" "apigw-resource" {
  rest_api_id = aws_api_gateway_rest_api.apigw.id
  parent_id   = aws_api_gateway_rest_api.apigw.root_resource_id
  path_part   = var.path_part
}

resource "aws_api_gateway_method" "apigw-method" {
  rest_api_id   = aws_api_gateway_rest_api.apigw.id
  resource_id   = aws_api_gateway_resource.apigw-resource.id
  http_method   = var.http_method
  authorization = var.authorization

	request_parameters = var.request_parameters
}

resource "aws_api_gateway_integration" "apigw-integration" {
  rest_api_id             = aws_api_gateway_rest_api.apigw.id
  resource_id             = aws_api_gateway_resource.apigw-resource.id
  http_method             = aws_api_gateway_method.apigw-method.http_method
  type                    = var.integration_type
  integration_http_method = var.integration_http_method
  uri                     = var.integration_uri
  passthrough_behavior    = var.integration_passthrough_behaviour
	request_parameters = var.integration_request_parameters

}
