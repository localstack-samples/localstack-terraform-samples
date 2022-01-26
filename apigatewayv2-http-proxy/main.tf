# curl -X POST "a750e94d.execute-api.localhost.localstack.cloud:4566/example/test" -H 'content-type: application/json' -d '{ "greeter": "cesar" }'

resource "aws_apigatewayv2_api" "example" {
  name          = "example-http-api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "example" {
  api_id           = aws_apigatewayv2_api.example.id
  integration_type = "HTTP_PROXY"

  integration_method = "POST"
  integration_uri    = "http://httpbin.org/anything/{proxy}"
}


resource "aws_apigatewayv2_route" "example" {
  api_id    = aws_apigatewayv2_api.example.id
  route_key = "POST /example/{proxy+}"

  target = "integrations/${aws_apigatewayv2_integration.example.id}"
}
