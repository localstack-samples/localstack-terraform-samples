
# curl http://localhost:4566/restapis/${API_ID}/test/_user_request_/test -v
resource "aws_api_gateway_rest_api" "mock" {
  name = "Mock API"
}

resource "aws_api_gateway_resource" "mock" {
  rest_api_id = aws_api_gateway_rest_api.mock.id
  parent_id   = aws_api_gateway_rest_api.mock.root_resource_id
  path_part   = "{id}"
}

resource "aws_api_gateway_method" "method" {
  rest_api_id   = aws_api_gateway_rest_api.mock.id
  resource_id   = aws_api_gateway_resource.mock.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "integration" {
  rest_api_id          = aws_api_gateway_rest_api.mock.id
  resource_id          = aws_api_gateway_resource.mock.id
  http_method          = aws_api_gateway_method.method.http_method
  type                 = "MOCK"
  passthrough_behavior = "WHEN_NO_MATCH"
  request_templates = {
    "application/json" = <<EOF
{
   "statusCode" : 200
}
EOF
  }
}

resource "aws_api_gateway_method_response" "response_200" {
  rest_api_id = aws_api_gateway_rest_api.mock.id
  resource_id = aws_api_gateway_resource.mock.id
  http_method = aws_api_gateway_method.method.http_method
  status_code = "200"

  # Empty2 is not a valid value
  response_models = {
    "application/json" = "Empty"
  }
}


resource "aws_api_gateway_integration_response" "integration" {
  rest_api_id = aws_api_gateway_rest_api.mock.id
  resource_id = aws_api_gateway_resource.mock.id
  http_method = aws_api_gateway_method.method.http_method
  status_code = aws_api_gateway_method_response.response_200.status_code

  response_templates = {
    "application/json" = <<EOF
{"statusCode": 200,"id": $input.params().path.id}
EOF
  }
}

resource "aws_api_gateway_deployment" "example" {
  rest_api_id = aws_api_gateway_rest_api.mock.id
  triggers = {
    # NOTE: The configuration below will satisfy ordering considerations,
    #       but not pick up all future REST API changes. More advanced patterns
    #       are possible, such as using the filesha1() function against the
    #       Terraform configuration file(s) or removing the .id references to
    #       calculate a hash against whole resources. Be aware that using whole
    #       resources will show a difference after the initial implementation.
    #       It will stabilize to only change when resources change afterwards.
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.mock.id,
      aws_api_gateway_method.method.id,
      aws_api_gateway_integration.integration.id,
    ]))
	}

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "example" {
  deployment_id = aws_api_gateway_deployment.example.id
  rest_api_id   = aws_api_gateway_rest_api.mock.id
  stage_name    = "test"
}
