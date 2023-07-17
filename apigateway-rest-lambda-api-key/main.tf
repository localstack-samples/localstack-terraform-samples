resource "aws_api_gateway_rest_api" "api" {
  name = "rest"
  description = "api-key-auth"
  api_key_source = "AUTHORIZER"
}

// /auth
resource "aws_api_gateway_resource" "authorizer" {
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "auth"
  rest_api_id = aws_api_gateway_rest_api.api.id
}

// GET /auth
resource "aws_api_gateway_method" "method" {
  authorization    = "NONE"
  http_method      = "GET"
  resource_id      = aws_api_gateway_resource.authorizer.id
  rest_api_id      = aws_api_gateway_rest_api.api.id
  api_key_required = true
}

// REQUEST type authorizer
resource "aws_api_gateway_authorizer" "lambda_auth" {
  name        = "lambda_auth"
  rest_api_id = aws_api_gateway_rest_api.api.id
  type        = "REQUEST"
  authorizer_uri = aws_lambda_function.lambda_auth.invoke_arn
  authorizer_credentials = aws_iam_role.invocation_role.arn
  identity_source        = "method.request.querystring.apiKey"
}

// Authorizer lambda
resource "aws_lambda_function" "lambda_auth" {
  filename      = "lambda_auth/lambda_auth.zip"
  function_name = "authorizer-lambda"
  role          = aws_iam_role.assume_lambda_role.arn
  handler       = "lambda_auth.lambda_handler"

  source_code_hash = filebase64sha256("lambda_auth/lambda_auth.zip")

  runtime = "python3.10"

  environment {
    variables = {
      foo = "bar"
    }
  }
}

// lambda integration
resource "aws_api_gateway_integration" "integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.authorizer.id
  http_method             = aws_api_gateway_method.method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda.invoke_arn
  request_templates = {
    "application/json" = <<EOT
{ "statusCode": "200" }
    EOT
  }
}

// lambda
resource "aws_lambda_function" "lambda" {
  filename      = "lambda/lambda.zip"
  function_name = "integration-lambda"
  role          = aws_iam_role.invocation_role.arn
  handler       = "lambda.lambda_handler"

  source_code_hash = filebase64sha256("lambda/lambda.zip")

  runtime = "python3.10"

  environment {
    variables = {
      foo = "bar"
    }
  }
}

resource "aws_lambda_permission" "permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "apigateway.amazonaws.com"

  # More: http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-control-access-using-iam-policies-to-invoke-api.html
  source_arn = "${aws_api_gateway_rest_api.api.execution_arn}/*/*/*" // must contain full path as defined by API
}


resource "aws_iam_role_policy" "invocation_policy" {
  name = "default"
  role = aws_iam_role.invocation_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "lambda:InvokeFunction",
      "Effect": "Allow",
      "Resource": "${aws_lambda_function.lambda_auth.arn}"
    }
  ]
}
EOF
}

resource "aws_iam_role" "assume_lambda_role" {

  assume_role_policy = <<EOF
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
EOF
}

resource "aws_iam_role" "invocation_role" {
  name = "api_gateway_auth_invocation"
  path = "/"

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

resource "aws_api_gateway_api_key" "api-key" {
  name = "api-key"

  tags = {
    "organization" : "demo-org"
  }
}

resource "aws_api_gateway_usage_plan_key" "main" {
  key_id        = aws_api_gateway_api_key.api-key.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.plan.id
}

resource "aws_api_gateway_stage" "stage" {
  deployment_id = aws_api_gateway_deployment.deployment.id
  rest_api_id   = aws_api_gateway_rest_api.api.id
  stage_name    = "dev"
}

resource "aws_api_gateway_usage_plan" "plan" {
  name = "my_usage_plan"

  api_stages {
    api_id = aws_api_gateway_rest_api.api.id
    stage  = aws_api_gateway_stage.stage.stage_name
  }
}

resource "aws_api_gateway_deployment" "deployment" {
  rest_api_id = aws_api_gateway_rest_api.api.id

  triggers = {
    # NOTE: The configuration below will satisfy ordering considerations,
    #       but not pick up all future REST API changes. More advanced patterns
    #       are possible, such as using the filesha1() function against the
    #       Terraform configuration file(s) or removing the .id references to
    #       calculate a hash against whole resources. Be aware that using whole
    #       resources will show a difference after the initial implementation.
    #       It will stabilize to only change when resources change afterwards.
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.authorizer.id,
      aws_api_gateway_method.method.id,
      aws_api_gateway_integration.integration.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

output "apikey" {
  sensitive = true
  value     = aws_api_gateway_api_key.api-key.value
}
