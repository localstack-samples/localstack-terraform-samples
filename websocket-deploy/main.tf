resource "aws_apigatewayv2_api" "ws" {
  name                       = "ws-demo"
  description                = "Websocket on LocalStack"
  protocol_type              = "WEBSOCKET"
  route_selection_expression = "$request.body.action"
}

# Forward special requests ($connect, $disconnect) to our Lambda function so we can manage their state
resource "aws_apigatewayv2_route" "_connect" {
  api_id    = aws_apigatewayv2_api.ws.id
  route_key = "$connect"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_main.id}"
}

resource "aws_apigatewayv2_route" "_disconnect" {
  api_id    = aws_apigatewayv2_api.ws.id
  route_key = "$disconnect"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_main.id}"
}

resource "aws_apigatewayv2_route" "_default" {
  api_id    = aws_apigatewayv2_api.ws.id
  route_key = "$default"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_main.id}"
}

resource "aws_apigatewayv2_stage" "lambda" {
  api_id      = aws_apigatewayv2_api.ws.id
  name        = "local"
  auto_deploy = true
}

# Use our Lambda function to service requests
resource "aws_apigatewayv2_integration" "lambda_main" {
  api_id = aws_apigatewayv2_api.ws.id
  #integration_uri    = aws_lambda_function.lambda.invoke_arn
  #integration_type   = "AWS_PROXY"
  integration_type   = "HTTP"
  integration_method = "POST"
  integration_uri    = "http://httpbin.org/anything"

  template_selection_expression = "$default"

  request_parameters = {
    "connectionId" : "$context.connectionId",
    "payload" : "$util.escapeJavaScript($input.json('$.message'))",
    "userAgent" : "$context.identity.userAgent"
  }
}

resource "aws_lambda_function" "lambda" {
  filename      = "lambda.zip"
  function_name = "mylambda"
  role          = aws_iam_role.lambda.arn
  handler       = "lambda.lambda_handler"
  runtime       = "python3.8"

  source_code_hash = filebase64sha256("lambda.zip")
}

resource "aws_iam_role" "lambda" {
  name = "demo-lambda"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

# Allow the API Gateway to invoke Lambda function
resource "aws_lambda_permission" "api_gw_main_lambda_main" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.ws.execution_arn}/*/*"
}

# Store various outputs for quick retrieval from our scripts
output "ws_url" {
  value = aws_apigatewayv2_stage.lambda.invoke_url
}
