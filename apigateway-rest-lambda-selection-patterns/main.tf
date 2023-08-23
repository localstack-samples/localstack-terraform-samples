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

resource "aws_api_gateway_resource" "resource_200" {
  path_part   = "200"
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  rest_api_id = aws_api_gateway_rest_api.api.id
}

resource "aws_api_gateway_resource" "resource_404" {
  path_part   = "404"
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  rest_api_id = aws_api_gateway_rest_api.api.id
}

resource "aws_api_gateway_method" "method_200" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.resource_200.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "method_404" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.resource_404.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "integration_200" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.resource_200.id
  http_method             = aws_api_gateway_method.method_200.http_method
  integration_http_method = "POST"
  type                    = "AWS"
  uri                     = "arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/${aws_lambda_function.lambda_200.arn}/invocations"
}


resource "aws_api_gateway_integration" "integration_404" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.resource_404.id
  http_method             = aws_api_gateway_method.method_404.http_method
  integration_http_method = "POST"
  type                    = "AWS"
  uri                     = "arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/${aws_lambda_function.lambda_404.arn}/invocations"
}

resource "aws_api_gateway_method_response" "method_200_response" {
  http_method = aws_api_gateway_method.method_200.http_method
  resource_id = aws_api_gateway_resource.resource_200.id
  rest_api_id = aws_api_gateway_rest_api.api.id
  status_code = "200"
}

resource "aws_api_gateway_method_response" "method_404_response" {
  http_method = aws_api_gateway_method.method_404.http_method
  resource_id = aws_api_gateway_resource.resource_404.id
  rest_api_id = aws_api_gateway_rest_api.api.id
  status_code = "404"
}

resource "aws_api_gateway_integration_response" "integration_success_response" {
  http_method = aws_api_gateway_method_response.method_200_response.http_method
  resource_id = aws_api_gateway_resource.resource_200.id
  rest_api_id = aws_api_gateway_rest_api.api.id
  status_code = aws_api_gateway_method_response.method_200_response.status_code

  selection_pattern = ""
}

resource "aws_api_gateway_integration_response" "integration_error_response" {
  http_method = aws_api_gateway_method_response.method_404_response.http_method
  resource_id = aws_api_gateway_resource.resource_404.id
  rest_api_id = aws_api_gateway_rest_api.api.id
  status_code = aws_api_gateway_method_response.method_404_response.status_code

  selection_pattern = ".*No value present.*"
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
      lambda_200 = aws_lambda_function.lambda_200.arn,
      lambda_404 = aws_lambda_function.lambda_404.arn,
    }))
  }
}

resource "aws_lambda_permission" "apigw_lambda_200" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_200.arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/*/*"
}


resource "aws_lambda_permission" "apigw_lambda_404" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_404.arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/*/*"
}


resource "aws_lambda_function" "lambda_200" {
  filename      = "lambda_200.zip"
  function_name = "${random_pet.random.id}-200"
  role          = aws_iam_role.role.arn
  handler       = "lambda_200.handler"

  source_code_hash = filebase64sha256("lambda_200.zip")

  runtime = "python3.10"
}

resource "aws_lambda_function" "lambda_404" {
  filename      = "lambda_404.zip"
  function_name = "${random_pet.random.id}-404"
  role          = aws_iam_role.role.arn
  handler       = "lambda_404.handler"

  source_code_hash = filebase64sha256("lambda_404.zip")

  runtime = "python3.10"
}


output "api_url" {
  value = aws_api_gateway_deployment.deployment.invoke_url
}
