resource "random_pet" "random" {
  length = 2
}

resource "aws_kinesis_stream" "kinesis_stream" {
  name        = random_pet.random.id
  shard_count = 1
}

resource "aws_apigatewayv2_api" "api" {
  name          = random_pet.random.id
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_route" "route" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "POST /"
  target    = "integrations/${aws_apigatewayv2_integration.integration.id}"
}

resource "aws_apigatewayv2_integration" "integration" {
  api_id                 = aws_apigatewayv2_api.api.id
  integration_type       = "AWS_PROXY"
  integration_subtype    = "Kinesis-PutRecord"
  passthrough_behavior   = "WHEN_NO_MATCH"
  payload_format_version = "1.0"
  credentials_arn        = aws_iam_role.role.arn

  request_parameters = {
    "Data"         = "$request.body.data"
    "PartitionKey" = "$request.body.partitionKey"
    "StreamName"   = aws_kinesis_stream.kinesis_stream.name
  }
}

resource "aws_apigatewayv2_stage" "stage" {
  api_id      = aws_apigatewayv2_api.api.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_iam_role" "role" {
  name = "apigw_kinesis_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
        Effect = "Allow"
      },
    ]
  })
}

resource "aws_iam_role_policy" "policy" {
  name = "apigw_kinesis_policy"
  role = aws_iam_role.role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "kinesis:PutRecord",
          "kinesis:PutRecords",
        ]
        Resource = "*"
        Effect   = "Allow"
      },
    ]
  })
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

output "api_invoke_url" {
  description = "The URL to invoke the API"
  value       = aws_apigatewayv2_stage.stage.invoke_url
}
