resource "random_pet" "random" {
  length = 2
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_partition" "current" {}

resource "aws_iam_role" "execution_role" {
  name               = "api-gateway-kinesis-execution-role"
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
  policy_arn = "arn:aws:iam::aws:policy/AmazonKinesisFullAccess"
}

resource "aws_apigatewayv2_api" "websocket" {
  name                       = random_pet.random.id
  protocol_type              = "WEBSOCKET"
  route_selection_expression = "\\$default"
}

resource "aws_apigatewayv2_route" "default_route" {
  api_id             = aws_apigatewayv2_api.websocket.id
  route_key          = "$default"
  target             = "integrations/${aws_apigatewayv2_integration.integration.id}"
  authorization_type = "NONE"
  api_key_required   = false
}

# {
#  "deviceID": "$input.json('$.deviceID')",
#  "recordingID": "$input.json('$.recordingID')",
#  "stop": $input.json('$.stop'),
#  "deviceTimestamp": $input.json('$.deviceTimestamp'),
#  "payload": $input.json('$.payload'),
#  "connectionID": "$context.connectionId"
# }
resource "aws_apigatewayv2_integration" "integration" {
  api_id             = aws_apigatewayv2_api.websocket.id
  integration_type   = "AWS"
  integration_method = "POST"
  integration_uri    = "arn:aws:apigateway:${data.aws_region.current.name}:kinesis:action/PutRecord"
  credentials_arn    = aws_iam_role.execution_role.arn
  request_templates = {
    "default" = <<TEMPLATE
      #set($data = "{""deviceID"": $input.json('$.deviceID'), ""recordingID"": $input.json('$.recordingID'), ""stop"": $input.json('$.stop'), ""deviceTimestamp"": $input.json('$.deviceTimestamp'), ""payload"": $input.json('$.payload'), ""connectionID"": ""$context.connectionId""}")
      {
          "Data": "$util.base64Encode($data)",
          "PartitionKey": $input.json('$.deviceID'),
          "StreamName": "${aws_kinesis_stream.stream.name}"
      }
    TEMPLATE
  }
  template_selection_expression = "default"
}

resource "aws_apigatewayv2_integration_response" "response" {
  api_id                   = aws_apigatewayv2_api.websocket.id
  integration_id           = aws_apigatewayv2_integration.integration.id
  integration_response_key = "/200/"
}

resource "aws_apigatewayv2_route_response" "response" {
  api_id             = aws_apigatewayv2_api.websocket.id
  route_id           = aws_apigatewayv2_route.default_route.id
  route_response_key = "$default"
}

resource "aws_apigatewayv2_stage" "stage" {
  name          = "v1"
  api_id        = aws_apigatewayv2_api.websocket.id
  deployment_id = aws_apigatewayv2_deployment.deployment.id
  auto_deploy   = true

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
  api_id = aws_apigatewayv2_api.websocket.id

  triggers = {
    redeployment = sha1(join(",", tolist([
      jsonencode(aws_apigatewayv2_integration.integration),
    ])))
  }

  depends_on = [
    aws_apigatewayv2_api.websocket,
    aws_apigatewayv2_route.default_route,
    aws_apigatewayv2_integration.integration,
  ]
}

resource "aws_kinesis_stream" "stream" {
  name        = random_pet.random.id
  shard_count = 1
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

output "ws_endpoint" {
  value = aws_apigatewayv2_stage.stage.invoke_url
}
