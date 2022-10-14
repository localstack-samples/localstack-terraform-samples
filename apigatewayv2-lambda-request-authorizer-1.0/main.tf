# curl -X POST "a750e94d.execute-api.localhost.localstack.cloud:4566/example/test" -H 'content-type: application/json' -d '{ "greeter": "cesar" }'

resource "aws_apigatewayv2_api" "example" {
  name          = "example-http-api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_authorizer" "example" {
  api_id                            = aws_apigatewayv2_api.example.id
  authorizer_type                   = "REQUEST"
  authorizer_uri                    = aws_lambda_function.lambda_auth.invoke_arn
  authorizer_payload_format_version = "1.0"
  identity_sources                  = ["$request.header.Authorization"]
  name                              = "example-authorizer"
}

resource "aws_apigatewayv2_integration" "example" {
  api_id                 = aws_apigatewayv2_api.example.id
  integration_type       = "AWS_PROXY"
  payload_format_version = "2.0"
  description            = "Lambda example"
  integration_method     = "ANY"
  integration_uri        = aws_lambda_function.lambda.invoke_arn

  request_parameters = {
    "overwrite:header.x-syna-accountalias" : "$context.authorizer.accountAlias"
    "overwrite:header.x-syna-accountid" : "$context.authorizer.accountId"
    "overwrite:header.x-syna-permissions" : "$context.authorizer.permissions"
    "overwrite:header.x-syna-projectid" : "$context.authorizer.projectId"
    "overwrite:header.x-syna-tenantid" : "$context.authorizer.tenantId"
    "overwrite:header.x-syna-userid" : "$context.authorizer.userId"
  }
}

resource "aws_apigatewayv2_route" "example" {
  api_id             = aws_apigatewayv2_api.example.id
  route_key          = "ANY /example/{proxy+}"
  authorization_type = "CUSTOM"
  authorizer_id      = aws_apigatewayv2_authorizer.example.id
  target             = "integrations/${aws_apigatewayv2_integration.example.id}"
}

resource "aws_lambda_function" "lambda_auth" {
  filename      = "lambda-auth.zip"
  function_name = "lambda-auth"
  role          = aws_iam_role.role.arn
  handler       = "lambda-auth.handler"

  source_code_hash = filebase64sha256("lambda-auth.zip")

  runtime = "nodejs12.x"

  environment {
    variables = {
      foo = "bar"
    }
  }
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
