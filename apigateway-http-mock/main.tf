
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
  rest_api_id             = aws_api_gateway_rest_api.mock.id
  resource_id             = aws_api_gateway_resource.mock.id
  http_method             = aws_api_gateway_method.method.http_method
	type                    = "MOCK"
	passthrough_behavior    = "WHEN_NO_MATCH"
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

	response_models = {
		"application/json" = "Empty2"
	}
}


resource "aws_api_gateway_integration_response" "integration" {
  rest_api_id = aws_api_gateway_rest_api.mock.id
  resource_id = aws_api_gateway_resource.mock.id
  http_method = aws_api_gateway_method.method.http_method
  status_code = aws_api_gateway_method_response.response_200.status_code

  response_templates = {
    "application/json" = <<EOF
{"statusCode": 200,"id2": $input.params().path.id}
EOF
  }
}

resource "aws_api_gateway_deployment" "example" {
  rest_api_id = aws_api_gateway_rest_api.mock.id

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "example" {
  deployment_id = aws_api_gateway_deployment.example.id
  rest_api_id   = aws_api_gateway_rest_api.mock.id
	stage_name    = "test"
}
