resource "aws_apigatewayv2_api" "example" {
  name                       = "example-websocket-api"
  protocol_type              = "WEBSOCKET"
  route_selection_expression = "$request.body.action"
}

resource "aws_apigatewayv2_route" "example" {
  api_id    = aws_apigatewayv2_api.example.id
  route_key = "$default"

  target = "integrations/${aws_apigatewayv2_integration.example.id}"
}

resource "aws_apigatewayv2_integration" "example" {
  api_id           = aws_apigatewayv2_api.example.id
  integration_type = "HTTP"

  integration_method = "POST"
  integration_uri    = "http://httpbin.org/anything/{proxy}"

  request_parameters = {
    "connectionId" : "$context.connectionId",
    "payload" : "$util.escapeJavaScript($input.json('$.message'))",
    "userAgent" : "$context.identity.userAgent"
  }
}
