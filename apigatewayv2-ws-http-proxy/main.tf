resource "random_pet" "random" {
  length    = 2
  separator = "-"
}


resource "aws_iam_role" "execution_role" {
  name               = "api-gateway-role"
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
        "Sid": "",
        "Effect": "Allow",
        "Principal": {
            "Service": "apigateway.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
        }
    ]
}
EOF
}

resource "aws_apigatewayv2_api" "websockets" {
  name                       = random_pet.random.id
  protocol_type              = "WEBSOCKET"
  route_selection_expression = "$request.body.action"
}

resource "aws_apigatewayv2_route" "connect_route" {
  api_id    = aws_apigatewayv2_api.websockets.id
  route_key = "$connect"
  target    = "integrations/${aws_apigatewayv2_integration.http.id}"
}

resource "aws_apigatewayv2_route" "disconnect_route" {
  api_id    = aws_apigatewayv2_api.websockets.id
  route_key = "$disconnect"
  target    = "integrations/${aws_apigatewayv2_integration.http.id}"
}

resource "aws_apigatewayv2_route" "default_route" {
  api_id    = aws_apigatewayv2_api.websockets.id
  route_key = "$default"
  target    = "integrations/${aws_apigatewayv2_integration.http.id}"
}

resource "aws_apigatewayv2_integration" "http" {
  api_id                        = aws_apigatewayv2_api.websockets.id
  credentials_arn               = aws_iam_role.execution_role.arn
  payload_format_version        = "1.0"
  integration_type              = "HTTP_PROXY"
  integration_method            = "POST"
  integration_uri               = "https://httpbin.org/anything/echo"
  template_selection_expression = "default"
  request_templates = {
    "default" = file("${path.module}/template.json")
  }
}

resource "aws_apigatewayv2_route_response" "connect_response" {
  api_id             = aws_apigatewayv2_api.websockets.id
  route_id           = aws_apigatewayv2_route.connect_route.id
  route_response_key = "$default"
}

resource "aws_apigatewayv2_route_response" "disconnect_response" {
  api_id             = aws_apigatewayv2_api.websockets.id
  route_id           = aws_apigatewayv2_route.disconnect_route.id
  route_response_key = "$default"
}

resource "aws_apigatewayv2_route_response" "default_response" {
  api_id             = aws_apigatewayv2_api.websockets.id
  route_id           = aws_apigatewayv2_route.default_route.id
  route_response_key = "$default"
}

resource "aws_apigatewayv2_stage" "stage" {
  api_id      = aws_apigatewayv2_api.websockets.id
  name        = "dev"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.log_group.arn
    format = jsonencode({
      requestId               = "$context.requestId"
      sourceIp                = "$context.identity.sourceIp"
      requestTime             = "$context.requestTime"
      message                 = "$context.messageId"
      status                  = "$context.status"
      responseLength          = "$context.responseLength"
      integrationErrorMessage = "$context.integrationErrorMessage"
      connectionId            = "$context.connectionId"
    })
  }

  default_route_settings {
    data_trace_enabled     = true
    logging_level          = "INFO"
    throttling_burst_limit = 100
    throttling_rate_limit  = 100
  }
}

resource "aws_apigatewayv2_deployment" "deployment" {
  api_id = aws_apigatewayv2_api.websockets.id
  depends_on = [
    aws_apigatewayv2_route_response.default_response,
  ]
}

resource "aws_cloudwatch_log_group" "log_group" {
  name              = random_pet.random.id
  retention_in_days = 1
}

resource "aws_cloudwatch_log_stream" "log_stream" {
  name           = random_pet.random.id
  log_group_name = aws_cloudwatch_log_group.log_group.name

  depends_on = [
    aws_cloudwatch_log_group.log_group
  ]
}

output "ws_url" {
  value = aws_apigatewayv2_api.websockets.api_endpoint
}
