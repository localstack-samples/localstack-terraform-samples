resource "aws_apigatewayv2_api" "websockets" {
  name                       = "example-websocket-api"
  protocol_type              = "WEBSOCKET"
  route_selection_expression = "$request.body.action"
}

resource "aws_apigatewayv2_route" "route" {
  api_id                              = aws_apigatewayv2_api.websockets.id
  route_key                           = "$connect"
  route_response_selection_expression = "$default"
  target                              = "integrations/${aws_apigatewayv2_integration.http.id}"
}

resource "aws_apigatewayv2_integration" "http" {
  api_id = aws_apigatewayv2_api.websockets.id

  payload_format_version = "1.0"

  integration_type = "HTTP"

  integration_method = "POST"
  integration_uri    = "http://httpbin.org/anything/echo"

  template_selection_expression = "\\$default"
  request_templates = {
    "$default" = file("${path.module}/template.json")
  }

}

resource "aws_apigatewayv2_route_response" "example" {
  api_id             = aws_apigatewayv2_api.websockets.id
  route_id           = aws_apigatewayv2_route.route.id
  route_response_key = "$default"
}

resource "aws_apigatewayv2_integration_response" "response" {
  api_id                        = aws_apigatewayv2_api.websockets.id
  integration_id                = aws_apigatewayv2_integration.http.id
  integration_response_key      = "/200/"
  template_selection_expression = "$integration.response.statuscode"
  response_templates = {
    "$default" = file("${path.module}/template.json")
  }
}

resource "aws_apigatewayv2_stage" "example" {
  api_id = aws_apigatewayv2_api.websockets.id
  name   = "prod"
}
