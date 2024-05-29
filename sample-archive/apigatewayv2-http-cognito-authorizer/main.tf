resource "random_pet" "random" {
  length = 2
}

resource "aws_apigatewayv2_api" "api" {
  name                       = random_pet.random.id
  protocol_type              = "HTTP"
  route_selection_expression = "$request.method $request.path"
}
resource "aws_apigatewayv2_authorizer" "authorizer" {
  name             = random_pet.random.id
  api_id           = aws_apigatewayv2_api.api.id
  authorizer_type  = "JWT"
  identity_sources = ["$request.header.Authorization"]

  authorizer_payload_format_version = "2.0"
  enable_simple_responses           = false

  jwt_configuration {
    audience = ["audience"]
    issuer   = "https://issuer"
  }
}

resource "aws_apigatewayv2_route" "route" {
  api_id = aws_apigatewayv2_api.api.id

  route_key          = "$default"
  authorizer_id      = aws_apigatewayv2_authorizer.authorizer.id
  authorization_type = "JWT"
  target             = "integrations/${aws_apigatewayv2_integration.integration.id}"
}

resource "aws_apigatewayv2_integration" "integration" {
  api_id             = aws_apigatewayv2_api.api.id
  integration_type   = "HTTP_PROXY"
  integration_method = "ANY"
  integration_uri    = "https://example.com"
}


resource "aws_cloudwatch_log_group" "log_group" {
  name              = "/aws/api-gateway/${aws_apigatewayv2_api.api.id}"
  retention_in_days = 1
}

resource "aws_apigatewayv2_stage" "stage" {
  api_id = aws_apigatewayv2_api.api.id
  name   = "dev"

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.log_group.arn
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
}

resource "aws_apigatewayv2_deployment" "deployment" {
  api_id = aws_apigatewayv2_api.api.id

  lifecycle {
    create_before_destroy = true
  }

  triggers = {
    redeployment = sha1(jsonencode(aws_apigatewayv2_integration.integration))
  }

  depends_on = [
    aws_apigatewayv2_route.route,
    aws_apigatewayv2_stage.stage
  ]
}
