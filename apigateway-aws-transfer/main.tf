data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

variable "stage" {
  description = "The deployment stage"
  default     = "dev"
}

locals {
  auth_source_name  = "SecretsManagerRegion"
  auth_source_value = data.aws_region.current.name
}

data "template_file" "api-definition" {
  template = file("${path.module}/openapi-2.yaml")

  vars = {
    LAMBDA_INVOKE_ARN = aws_lambda_function.sftp-idp.invoke_arn
  }
}

resource "aws_lambda_function" "sftp-idp" {
  filename         = "${path.module}/lambda.zip"
  function_name    = "sftp-idp-${var.stage}"
  role             = aws_iam_role.iam_for_lambda_idp.arn
  handler          = "index.lambda_handler"
  source_code_hash = filebase64sha256("lambda.zip")
  runtime          = "python3.7"

  environment {
    variables = {
      "${local.auth_source_name}" = local.auth_source_value
    }
  }
}

resource "aws_iam_role" "iam_for_lambda_idp" {
  name = "iam_for_lambda_idp-${var.stage}"

  assume_role_policy = <<-EOF
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

resource "aws_iam_role_policy_attachment" "lambda_logs_idp" {
  role       = aws_iam_role.iam_for_lambda_idp.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_policy" "sftp-idp" {
  name        = "sftp-idp-${var.stage}"
  path        = "/"
  description = "IAM policy IdP service for SFTP in Lambda"

  policy = <<-EOF
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Action": "secretsmanager:GetSecretValue",
                "Resource": "arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:SFTP/*"
            }
        ]
    }
  EOF
}

resource "aws_iam_role_policy_attachment" "sftp-idp1" {
  role       = aws_iam_role.iam_for_lambda_idp.name
  policy_arn = aws_iam_policy.sftp-idp.arn
}

resource "aws_iam_role_policy_attachment" "sftp-idp2" {
  role       = aws_iam_role.iam_for_lambda_idp.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}


resource "aws_iam_role" "iam_for_apigateway_idp" {
  name = "iam_for_apigateway_idp-${var.stage}"

  assume_role_policy = <<-EOF
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


resource "aws_iam_role_policy_attachment" "apigateway-cloudwatchlogs" {
  role       = aws_iam_role.iam_for_apigateway_idp.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}

resource "aws_api_gateway_account" "api_gateway_account" {
  cloudwatch_role_arn = aws_iam_role.iam_for_apigateway_idp.arn
}

resource "aws_api_gateway_rest_api" "sftp-idp-secrets" {
  name        = "sftp-idp-secrets"
  description = "This API provides an IDP for AWS Transfer service"
  endpoint_configuration {
    types = ["REGIONAL"]
  }
  body = data.template_file.api-definition.rendered
}

resource "aws_lambda_permission" "allow_apigateway" {
  statement_id  = "AllowExecutionFromApigateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.sftp-idp.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.sftp-idp-secrets.execution_arn}/*/*/*"
}

resource "aws_api_gateway_deployment" "deployment" {
  rest_api_id = aws_api_gateway_rest_api.sftp-idp-secrets.id
  triggers = {
    redeployment = sha1(jsonencode([aws_api_gateway_rest_api.sftp-idp-secrets.body]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "stage" {
  stage_name    = var.stage
  rest_api_id   = aws_api_gateway_rest_api.sftp-idp-secrets.id
  deployment_id = aws_api_gateway_deployment.deployment.id
}
