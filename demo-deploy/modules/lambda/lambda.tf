
resource "aws_iam_role" "lambda" {
  name = "demo-lambda"

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

resource "aws_lambda_function" "authorizer" {
  filename         = "${path.module}/files/lambda-function.zip"
  function_name    = "api_gateway_authorizer"
  role             = aws_iam_role.lambda.arn
  handler          = "exports.handler"
  runtime          = "nodejs12.x"
  source_code_hash = filebase64sha256("${path.module}/files/lambda-function.zip")
}

output "lambda_arn" {
  value = aws_lambda_function.authorizer.arn
}

output "lambda_invoke_arn" {
  value = aws_lambda_function.authorizer.invoke_arn
}
