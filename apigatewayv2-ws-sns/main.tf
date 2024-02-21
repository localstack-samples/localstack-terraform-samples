data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

resource "random_pet" "random" {
  length    = 2
  separator = "-"
}

# $default -> SNS integration
resource "aws_sns_topic" "sns_topic" {
  name = random_pet.random.id
}

resource "aws_iam_role" "execution_role" {
  name               = "api-gateway-sns-execution-role"
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
  policy_arn = "arn:aws:iam::aws:policy/AmazonSNSFullAccess"
}

resource "aws_apigatewayv2_api" "api" {
  name                       = random_pet.random.id
  protocol_type              = "WEBSOCKET"
  route_selection_expression = "$request.body.action"
}

resource "aws_apigatewayv2_route" "connect_route" {
  api_id                              = aws_apigatewayv2_api.api.id
  route_key                           = "$connect"
  target                              = "integrations/${aws_apigatewayv2_integration.mock.id}"
  authorization_type                  = "NONE"
  route_response_selection_expression = "$default"
}

resource "aws_apigatewayv2_route" "default_route" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "$default"

  target = "integrations/${aws_apigatewayv2_integration.integration.id}"
}

# connect -> mock integration
resource "aws_apigatewayv2_integration" "mock" {
  api_id                 = aws_apigatewayv2_api.api.id
  integration_type       = "MOCK"
  integration_method     = "POST"
  passthrough_behavior   = "WHEN_NO_MATCH"
  payload_format_version = "1.0"
  request_templates = {
    "200" : "{\"statusCode\": 200}"
  }
  template_selection_expression = "200"
}

resource "aws_apigatewayv2_route_response" "connect_route_response" {
  api_id             = aws_apigatewayv2_api.api.id
  route_id           = aws_apigatewayv2_route.connect_route.id
  route_response_key = "$default"
}

resource "aws_apigatewayv2_integration_response" "connect_integration_response" {
  api_id                        = aws_apigatewayv2_api.api.id
  integration_id                = aws_apigatewayv2_integration.mock.id
  integration_response_key      = "/200/"
  template_selection_expression = "default"
  response_templates = {
    "200" = "{\"statusCode\": 200, \"message\":\"order initiated\"}"
  }
}

resource "aws_apigatewayv2_integration" "integration" {
  api_id                    = aws_apigatewayv2_api.api.id
  integration_type          = "AWS"
  integration_method        = "POST"
  integration_uri           = "arn:aws:apigateway:${data.aws_region.current.name}:sns:action/Publish"
  passthrough_behavior      = "WHEN_NO_MATCH"
  content_handling_strategy = "CONVERT_TO_TEXT"
  payload_format_version    = "1.0"
  timeout_milliseconds      = 29000
  credentials_arn           = aws_iam_role.execution_role.arn
  request_parameters = {
    "integration.request.header.Content-Type" = "'application/x-www-form-urlencoded'"
  }
  request_templates = {
    "$default" = "Action=Publish&TopicArn=$util.urlEncode(\"${aws_sns_topic.sns_topic.id}\")&Message=$input.json('$')"
  }
  template_selection_expression = "$request.body.action"
}

resource "aws_apigatewayv2_route_response" "default_route_response" {
  api_id             = aws_apigatewayv2_api.api.id
  route_id           = aws_apigatewayv2_route.default_route.id
  route_response_key = "$default"
}

resource "aws_apigatewayv2_integration_response" "default_integration_response" {
  api_id                   = aws_apigatewayv2_api.api.id
  integration_id           = aws_apigatewayv2_integration.integration.id
  integration_response_key = "$default"

  response_templates = {
    "200" = "{\"statusCode\": 200, \"message\":\"order created\"}"
  }
}

resource "aws_apigatewayv2_stage" "stage" {
  name          = "dev"
  api_id        = aws_apigatewayv2_api.api.id
  deployment_id = aws_apigatewayv2_deployment.deployment.id

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.apigw_logs.arn
    format          = "$context.identity.sourceIp $context.identity.caller $context.identity.user [$context.requestTime] \"$context.httpMethod $context.routeKey $context.protocol\" $context.status $context.responseLength $context.requestId"
  }
}

resource "aws_cloudwatch_log_group" "apigw_logs" {
  name              = "/aws/apigateway/${aws_apigatewayv2_api.api.name}"
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

resource "aws_apigatewayv2_deployment" "deployment" {
  api_id = aws_apigatewayv2_api.api.id

  depends_on = [
    aws_apigatewayv2_route.default_route,
    aws_apigatewayv2_route.connect_route,
  ]
}

output "api_endpoint" {
  value = "${aws_apigatewayv2_api.api.api_endpoint}/${aws_apigatewayv2_stage.stage.name}"
}
