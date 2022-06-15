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

resource "aws_iam_role" "sftp" {
  name = "sftp-server-iam-role-${var.stage}"

  assume_role_policy = <<-POLICY
    {
        "Version": "2012-10-17",
        "Statement": [
            {
            "Effect": "Allow",
            "Principal": {
                "Service": "transfer.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
            }
        ]
    }
  POLICY
}

resource "aws_iam_role" "sftp_log" {
  # log role for SFTP server
  name = "sftp-server-iam-log-role-${var.stage}"

  assume_role_policy = <<-POLICY
    {
        "Version": "2012-10-17",
        "Statement": [
            {
            "Effect": "Allow",
            "Principal": {
                "Service": "transfer.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
            }
        ]
    }
  POLICY
}

resource "aws_iam_role_policy" "sftp" {
  # policy to allow invocation of IdP API
  name = "sftp-server-iam-policy-${var.stage}"
  role = aws_iam_role.sftp.id

  policy = <<-POLICY
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Sid": "InvokeApi",
          "Effect": "Allow",
          "Action": [
            "execute-api:Invoke"
          ],
          "Resource": "arn:aws:execute-api:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.sftp-idp-secrets.id}/${var.stage}/GET/*"
        },
        {
          "Sid": "ReadApi",
          "Effect": "Allow",
          "Action": [
            "apigateway:GET"
          ],
          "Resource": "*"
        }
      ]
    }
  POLICY
}

resource "aws_iam_role_policy" "sftp_log" {
  # policy to allow logging to Cloudwatch
  name = "sftp-server-iam-log-policy-${var.stage}"
  role = aws_iam_role.sftp_log.id

  policy = <<-POLICY
    {
      "Version": "2012-10-17",
      "Statement": [{
          "Sid": "AllowFullAccesstoCloudWatchLogs",
          "Effect": "Allow",
          "Action": [
            "logs:*"
          ],
          "Resource": "*"
        }
      ]
    }
  POLICY
}

resource "aws_secretsmanager_secret" "secret" {
  name                = "SFTP/user1"
}

resource "aws_secretsmanager_secret_version" "secret" {
  secret_id     = "${aws_secretsmanager_secret.secret.id}"
  secret_string = <<-EOF
    {
      "HomeDirectoryDetails": "[{\"Entry\": \"/\", \"Target\": \"/test.devopsgoat/$${Transfer:UserName}\"}]",
      "Password": "Password1",
      "Role": "arn:aws:iam::XXXXXXX:role/transfer-user-iam-role",
      "UserId": "user1",
      "AcceptedIpNetwork": "192.168.1.0/24",
    }
  EOF
}

resource "aws_transfer_server" "sftp" {
  identity_provider_type = "API_GATEWAY"
  logging_role           = aws_iam_role.sftp_log.arn
  url                    = aws_api_gateway_stage.stage.invoke_url
  invocation_role        = aws_iam_role.sftp.arn
  endpoint_type          = "PUBLIC"

  tags = {
    NAME = "sftp-server"
  }
}

resource "aws_s3_bucket" "sftp" {
  bucket_prefix = "sftpbucket"
  acl           = "private"
}

resource "aws_iam_role" "transfer" {
  name = "transfer-user-iam-role-${var.stage}"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
        "Effect": "Allow",
        "Principal": {
            "Service": "transfer.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy" "transfer" {
  name = "transfer-user-iam-policy-${var.stage}"
  role = aws_iam_role.transfer.id

  policy = <<-POLICY
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Sid": "AllowListingOfUserFolder",
                "Action": [
                    "s3:ListBucket",
                    "s3:GetBucketLocation"
                ],
                "Effect": "Allow",
                "Resource": [
                    "${aws_s3_bucket.sftp.arn}"
                ]
            },
            {
                "Sid": "HomeDirObjectAccess",
                "Effect": "Allow",
                "Action": [
                    "s3:PutObject",
                    "s3:GetObject",
                    "s3:DeleteObjectVersion",
                    "s3:DeleteObject",
                    "s3:GetObjectVersion"
                ],
                "Resource": ["${aws_s3_bucket.sftp.arn}","${aws_s3_bucket.sftp.arn}/*"]
            }
        ]
    }
  POLICY
}

output "endpoint" {
  value = aws_transfer_server.sftp.endpoint
}

output "role" {
  value = aws_iam_role.transfer.arn
}

output "auth_url" {
	value = aws_api_gateway_stage.stage.invoke_url
}
