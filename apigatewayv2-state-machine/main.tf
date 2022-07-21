resource "aws_apigatewayv2_api" "api" {
  name          = "example-sfn-api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_stage" "apigateway" {
  api_id      = aws_apigatewayv2_api.api.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_apigatewayv2_route" "apigateway_get_job" {
  api_id             = aws_apigatewayv2_api.apigateway.id
  route_key          = "GET /test"
  target             = "integrations/${aws_apigatewayv2_integration.apigateway_get_job.id}"
  authorization_type = "NONE"
}

resource "aws_apigatewayv2_integration" "state_machine_lmbd" {
  api_id = aws_apigatewayv2_api.rest_api_gateway.id

  integration_type       = "AWS_PROXY"
  integration_subtype    = "StepFunctions-StartExecution"
  description            = "..."
  payload_format_version = "1.0"
  timeout_milliseconds   = 30000

  request_parameters = {
    StateMachineArn = var.aws_sfn_state_machine-fn_lambda-arn
    Input           = "$request.body.Input",
  }
}

data "aws_iam_policy_document" "sfn_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["states.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "sfn" {
  name               = "api-sfn"
  assume_role_policy = data.aws_iam_policy_document.sfn_assume.json
}

resource "aws_sfn_state_machine" "sfn_state_machine" {
  name     = "my-state-machine"
  role_arn = aws_iam_role.sfn.arn

  definition = <<EOF
{
  "Comment": "A Hello World example of the Amazon States Language using an AWS Lambda Function",
  "StartAt": "HelloWorld",
  "States": {
    "HelloWorld": {
      "Type": "Task",
      "Resource": "${aws_lambda_function.lambda.arn}",
      "End": true
    }
  }
}
EOF
}

resource "aws_lambda_function" "lambda" {
  filename      = "lambda.zip"
  function_name = "mylambda"
  role          = aws_iam_role.role.arn
  handler       = "lambda.handler"

  source_code_hash = filebase64sha256("lambda.zip")

  runtime = "nodejs12.x"

  environment {
    variables = {
      foo = "bar"
    }
  }
}

resource "aws_iam_role" "role" {
  name = "myrole"

  assume_role_policy = <<POLICY
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
POLICY
}
