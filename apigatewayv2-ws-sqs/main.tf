data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

resource "random_pet" "random" {
  length    = 2
  separator = "-"
}

resource "aws_iam_role" "execution_role" {
  name               = "api-gateway-sqs-execution-role"
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

resource "aws_iam_role_policy_attachment" "execution_role" {
  role       = aws_iam_role.execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSQSFullAccess"
}

resource "aws_apigatewayv2_api" "websocket_api" {
  name                       = random_pet.random.id
  protocol_type              = "WEBSOCKET"
  route_selection_expression = "$request.body.action"
}

resource "aws_sqs_queue" "sqs_queue" {
  name = random_pet.random.id
}

resource "aws_apigatewayv2_integration" "sqs_integration" {
  api_id                 = aws_apigatewayv2_api.websocket_api.id
  credentials_arn        = aws_iam_role.execution_role.arn
  integration_type       = "AWS"
  payload_format_version = "1.0"
  integration_method     = "POST"
  integration_uri        = "arn:aws:apigateway:${data.aws_region.current.name}:sqs:path/${data.aws_caller_identity.current.account_id}/${aws_sqs_queue.sqs_queue.name}"
  passthrough_behavior   = "NEVER"
  request_parameters = {
    "integration.request.header.Content-Type" = "'application/x-www-form-urlencoded'"
  }
  request_templates = {
    "default" : "Action=SendMessage&MessageBody=$util.urlEncode($input.body)"
  }
  template_selection_expression = "default"
}

resource "aws_apigatewayv2_integration" "mock_integration" {
  api_id           = aws_apigatewayv2_api.websocket_api.id
  integration_type = "MOCK"

  request_templates = {
    "default" = <<EOF
{
  "statusCode": 200
}
EOF
  }
  template_selection_expression = "default"
}

resource "aws_apigatewayv2_integration" "disconnect_sqs_integration" {
  api_id                 = aws_apigatewayv2_api.websocket_api.id
  credentials_arn        = aws_iam_role.execution_role.arn
  integration_type       = "AWS"
  payload_format_version = "1.0"
  integration_method     = "POST"
  integration_uri        = "arn:aws:apigateway:${data.aws_region.current.name}:sqs:path/${data.aws_caller_identity.current.account_id}/${aws_sqs_queue.sqs_queue.name}"
  passthrough_behavior   = "NEVER"
  request_parameters = {
    "integration.request.header.Content-Type" = "'application/x-www-form-urlencoded'"
  }
  request_templates = {
    "default" : "Action=SendMessage&MessageBody=$util.urlEncode('Client disconnected')"
  }
  template_selection_expression = "default"
}

resource "aws_apigatewayv2_route" "connect_route" {
  api_id    = aws_apigatewayv2_api.websocket_api.id
  route_key = "$connect"
  target    = "integrations/${aws_apigatewayv2_integration.mock_integration.id}"
}

resource "aws_apigatewayv2_route" "default_route" {
  api_id    = aws_apigatewayv2_api.websocket_api.id
  route_key = "$default"
  target    = "integrations/${aws_apigatewayv2_integration.sqs_integration.id}"
}

resource "aws_apigatewayv2_route" "disconnect_route" {
  api_id    = aws_apigatewayv2_api.websocket_api.id
  route_key = "$disconnect"
  target    = "integrations/${aws_apigatewayv2_integration.disconnect_sqs_integration.id}"
}

resource "aws_apigatewayv2_route_response" "connect_route_response" {
  api_id             = aws_apigatewayv2_api.websocket_api.id
  route_id           = aws_apigatewayv2_route.connect_route.id
  route_response_key = "$default"
}

resource "aws_apigatewayv2_integration_response" "mock_response" {
  api_id                   = aws_apigatewayv2_api.websocket_api.id
  integration_id           = aws_apigatewayv2_integration.mock_integration.id
  integration_response_key = "$default"
  response_templates = {
    "$default" = "{'statusCode': 200}"
  }
}

resource "aws_apigatewayv2_route_response" "default_route_response" {
  api_id             = aws_apigatewayv2_api.websocket_api.id
  route_id           = aws_apigatewayv2_route.default_route.id
  route_response_key = "$default"
}

resource "aws_apigatewayv2_integration_response" "sqs_response" {
  api_id                   = aws_apigatewayv2_api.websocket_api.id
  integration_id           = aws_apigatewayv2_integration.sqs_integration.id
  integration_response_key = "$default"
  response_templates = {
    "$default" = "$input.body"
  }
}

resource "aws_cloudwatch_log_group" "apigw_logs" {
  name              = "/aws/apigateway/${aws_apigatewayv2_api.websocket_api.name}"
  retention_in_days = 1
}

resource "aws_iam_role_policy" "apigw_logs" {
  name = "APIGWLogsPolicy"
  role = aws_iam_role.execution_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams",
        "logs:PutLogEvents",
        "logs:GetLogEvents",
        "logs:FilterLogEvents"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_apigatewayv2_stage" "stage" {
  api_id      = aws_apigatewayv2_api.websocket_api.id
  name        = "dev"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.apigw_logs.arn
    format          = "$context.identity.sourceIp $context.identity.caller $context.identity.user [$context.requestTime] \"$context.httpMethod $context.routeKey $context.protocol\" $context.status $context.responseLength $context.requestId"
  }
}

output "websocket_api_endpoint" {
  value = "${aws_apigatewayv2_api.websocket_api.api_endpoint}/${aws_apigatewayv2_stage.stage.name}"
}
