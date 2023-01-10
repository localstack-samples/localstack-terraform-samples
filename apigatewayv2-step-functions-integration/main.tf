resource "random_pet" "random" {
  length = 2
}

resource "aws_iam_role" "apigateway" {
  name               = "apigw-sfn"
  assume_role_policy = data.aws_iam_policy_document.apigw_assume.json
}

data "aws_iam_policy_document" "apigw_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["apigateway.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy_attachment" "policy_invoke_sfn" {
  name       = random_pet.random.id
  roles      = [aws_iam_role.apigateway.name]
  policy_arn = "arn:aws:iam::aws:policy/AWSStepFunctionsFullAccess"
}

resource "aws_apigatewayv2_api" "api" {
  name          = random_pet.random.id
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_stage" "stage" {
  api_id      = aws_apigatewayv2_api.api.id
  name        = "$default"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.apigateway.arn
    format          = jsonencode({
      "requestId" : "$context.requestId"
      "ip" : "$context.identity.sourceIp"
      "requestTime" : "$context.requestTime"
      "httpMethod" : "$context.httpMethod"
      "routeKey" : "$context.routeKey"
      "status" : "$context.status"
      "protocol" : "$context.protocol"
      "responseLength" : "$context.responseLength"
      "authorizationError" : "$context.authorizer.error"
    })
  }
}

resource "aws_cloudwatch_log_group" "apigateway" {
  name              = "/aws/apigateway/${aws_apigatewayv2_api.api.name}"
  retention_in_days = 3
}

resource "aws_apigatewayv2_route" "route" {
  api_id             = aws_apigatewayv2_api.api.id
  route_key          = "POST /test"
  target             = "integrations/${aws_apigatewayv2_integration.integration.id}"
  authorization_type = "NONE"
}

resource "aws_apigatewayv2_integration" "integration" {
  api_id = aws_apigatewayv2_api.api.id
  description = "Invoke Step Functions"
  integration_type       = "AWS_PROXY"
  integration_subtype    = "StepFunctions-StartExecution"
  credentials_arn = aws_iam_role.apigateway.arn
  payload_format_version = "1.0"
  timeout_milliseconds   = 30000
  request_parameters     = {
    "StateMachineArn" = aws_sfn_state_machine.sfn_state_machine.arn
    "Input"           = "$request.body",
  }
}

resource "aws_iam_role" "sfn_role" {
  name               = "api-sfn"
  assume_role_policy = data.aws_iam_policy_document.sfn_assume.json
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

resource "aws_sfn_state_machine" "sfn_state_machine" {
  name     = random_pet.random.id
  role_arn = aws_iam_role.sfn_role.arn

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

resource "aws_iam_policy" "policy_invoke_lambda" {
  name = "StepFunctionLambdaFunctionInvocationPolicy"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "lambda:InvokeFunction",
                "lambda:InvokeAsync"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "iam_for_sfn_attach_policy_invoke_lambda" {
  role       = aws_iam_role.sfn_role.name
  policy_arn = aws_iam_policy.policy_invoke_lambda.arn
}

resource "aws_lambda_function" "lambda" {
  filename      = "lambda.zip"
  function_name = random_pet.random.id
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda.handler"

  source_code_hash = filebase64sha256("lambda.zip")

  runtime = "nodejs12.x"

  environment {
    variables = {
      foo = "bar"
    }
  }
}

resource "aws_iam_role" "lambda_role" {
  name               = "assume-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

data "aws_iam_policy_document" "lambda_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "lambda_policy_auth" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
