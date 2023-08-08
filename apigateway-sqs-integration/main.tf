// apigateway sqs integration

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_iam_role" "api" {
  name = "my-api-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "apigateway.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_sqs_queue" "queue" {
  name = random_pet.random.id
}

resource "aws_iam_policy" "policy" {
  name = "queue-policy"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
        "Action": [
            "sqs:SendMessage"
        ],
        "Effect": "Allow",
        "Resource": "${aws_sqs_queue.queue.arn}"
        },
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

resource "aws_iam_role_policy_attachment" "api" {
  role       = aws_iam_role.api.name
  policy_arn = aws_iam_policy.policy.arn
}

resource "random_pet" "random" {
  length = 2
}

resource "aws_api_gateway_rest_api" "rest" {
  name = random_pet.random.id
}

resource "aws_api_gateway_resource" "resource" {
  rest_api_id = aws_api_gateway_rest_api.rest.id
  parent_id   = aws_api_gateway_rest_api.rest.root_resource_id
  path_part   = "sqs"
}

resource "aws_api_gateway_method" "method" {
  authorization    = "NONE"
  http_method      = "POST"
  resource_id      = aws_api_gateway_resource.resource.id
  rest_api_id      = aws_api_gateway_rest_api.rest.id
  api_key_required = false
}

resource "aws_api_gateway_integration" "integration" {
  http_method             = aws_api_gateway_method.method.http_method
  resource_id             = aws_api_gateway_resource.resource.id
  rest_api_id             = aws_api_gateway_rest_api.rest.id
  credentials             = aws_iam_role.api.arn
  type                    = "AWS"
  uri                     = "arn:aws:apigateway:${data.aws_region.current.name}:sqs:path/${aws_sqs_queue.queue.name}"
  integration_http_method = "POST"
  passthrough_behavior    = "NEVER"

  request_parameters = {
    "integration.request.header.Content-Type" = "'application/x-www-form-urlencoded'"
  }

  // Action=SendMessage&MessageBody=$input.body
  request_templates = {
    "application/json" = "Action=SendMessage&MessageBody=$input.body"
  }
}

resource "aws_api_gateway_method_response" "response" {
  http_method = aws_api_gateway_method.method.http_method
  resource_id = aws_api_gateway_resource.resource.id
  rest_api_id = aws_api_gateway_rest_api.rest.id
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration_response" "integration_response" {
  rest_api_id = aws_api_gateway_rest_api.rest.id
  resource_id = aws_api_gateway_resource.resource.id
  http_method = aws_api_gateway_method.method.http_method
  status_code = aws_api_gateway_method_response.response.status_code

  response_templates = {
    "application/json" = "{\"message\": \"great success!\"}"
  }
}

resource "aws_api_gateway_stage" "stage" {
  deployment_id = aws_api_gateway_deployment.deployment.id
  rest_api_id   = aws_api_gateway_rest_api.rest.id
  stage_name    = "dev"
}

resource "aws_api_gateway_deployment" "deployment" {
  rest_api_id = aws_api_gateway_rest_api.rest.id

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [aws_api_gateway_rest_api.rest, aws_api_gateway_method.method, aws_api_gateway_integration.integration]
}

output "test_curl" {
  value = "curl -X POST -H 'Content-Type: application/json' -d '{\"id\":\"test\", \"docs\":[{\"key\":\"value\"}]}' ${aws_api_gateway_stage.stage.invoke_url}/${aws_api_gateway_resource.resource.path_part}"
}
