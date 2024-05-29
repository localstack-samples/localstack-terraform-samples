data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "random_pet" "random" {
  length = 2
}

resource "aws_iam_role" "role" {
  name = random_pet.random.id

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

resource "aws_api_gateway_rest_api" "api" {
  name = random_pet.random.id
}

resource "aws_api_gateway_resource" "resource" {
  path_part   = "{statusCode}"
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  rest_api_id = aws_api_gateway_rest_api.api.id
}

resource "aws_api_gateway_method" "method" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.resource.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.resource.id
  http_method             = aws_api_gateway_method.method.http_method
  integration_http_method = "POST"
  type                    = "AWS"
  uri                     = "arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/${aws_lambda_function.lambda.arn}/invocations"

  request_templates = {
    "application/json" = <<JSON
    #set($inputRoot = $input.path('$'))
{
  "statusCode": "$input.params('statusCode')"
}
JSON
  }
}

resource "aws_api_gateway_method_response" "method_response_200" {
  http_method = aws_api_gateway_method.method.http_method
  resource_id = aws_api_gateway_resource.resource.id
  rest_api_id = aws_api_gateway_rest_api.api.id
  status_code = "200"
}

resource "aws_api_gateway_method_response" "method_response_400" {
  http_method = aws_api_gateway_method.method.http_method
  resource_id = aws_api_gateway_resource.resource.id
  rest_api_id = aws_api_gateway_rest_api.api.id
  status_code = "405"
}

resource "aws_api_gateway_method_response" "method_response_500" {
  http_method = aws_api_gateway_method.method.http_method
  resource_id = aws_api_gateway_resource.resource.id
  rest_api_id = aws_api_gateway_rest_api.api.id
  status_code = "502"
}

resource "aws_api_gateway_integration_response" "integration_response" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.resource.id
  status_code = aws_api_gateway_method_response.method_response_200.status_code
  http_method = aws_api_gateway_method_response.method_response_200.http_method
}


resource "aws_api_gateway_integration_response" "integration_response_400" {
  rest_api_id       = aws_api_gateway_rest_api.api.id
  resource_id       = aws_api_gateway_resource.resource.id
  status_code       = aws_api_gateway_method_response.method_response_400.status_code
  http_method       = aws_api_gateway_method_response.method_response_400.http_method
  selection_pattern = ".*400.*"
}

resource "aws_api_gateway_integration_response" "integration_response_500" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.resource.id
  status_code = aws_api_gateway_method_response.method_response_500.status_code
  http_method = aws_api_gateway_method_response.method_response_500.http_method

  selection_pattern = ".*5\\d\\d.*"
}

resource "aws_api_gateway_stage" "stage" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  stage_name    = "dev"
  deployment_id = aws_api_gateway_deployment.deployment.id
}

resource "aws_api_gateway_deployment" "deployment" {
  rest_api_id = aws_api_gateway_rest_api.api.id

  triggers = {
    redeployment = sha1(jsonencode({
      lambda = aws_lambda_function.lambda.arn
    }))
  }
}

resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/*/*"
}

resource "aws_lambda_function" "lambda" {
  filename      = "lambda.zip"
  function_name = random_pet.random.id
  role          = aws_iam_role.role.arn
  handler       = "lambda.handler"

  source_code_hash = filebase64sha256("lambda.zip")

  runtime = "python3.10"
}


output "api_url" {
  value = aws_api_gateway_deployment.deployment.invoke_url
}
