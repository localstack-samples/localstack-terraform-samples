resource "aws_api_gateway_rest_api" "rest" {
  name = "Rest API"
}

resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.rest.id
  parent_id   = aws_api_gateway_rest_api.rest.root_resource_id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "method_get" {
  rest_api_id   = aws_api_gateway_rest_api.rest.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "method_post" {
  rest_api_id   = aws_api_gateway_rest_api.rest.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "POST"
	authorization = "CUSTOM"
	authorizer_id = aws_api_gateway_authorizer.demo.id
}


resource "aws_api_gateway_authorizer" "demo" {
  name                   = "jwt"
  rest_api_id            = aws_api_gateway_rest_api.rest.id
  authorizer_uri         = aws_lambda_function.authorizer.invoke_arn
  authorizer_credentials = aws_iam_role.role.arn
}

resource "aws_lambda_function" "authorizer" {
  filename      = "authorizer-function.zip"
  function_name = "api_gateway_authorizer"
  role          = aws_iam_role.role.arn
  handler       = "authorizer.handler"

	source_code_hash = filebase64sha256("authorizer-function.zip")

  runtime = "nodejs12.x"
}

resource "aws_api_gateway_integration" "integration" {
  rest_api_id             = aws_api_gateway_rest_api.rest.id
  resource_id             = aws_api_gateway_resource.proxy.id
	http_method = aws_api_gateway_method.method_get.http_method

  type = "HTTP_PROXY"
  integration_http_method = "POST"
  uri    = "http://httpbin.org/anything/{proxy}"
}

resource "aws_api_gateway_integration" "integration_post" {
  rest_api_id             = aws_api_gateway_rest_api.rest.id
  resource_id             = aws_api_gateway_resource.proxy.id
  http_method             = aws_api_gateway_method.method_post.http_method
  integration_http_method = "ANY"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda.invoke_arn
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
