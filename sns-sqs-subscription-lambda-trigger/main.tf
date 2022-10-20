data "aws_region" "current" {}

resource "aws_sns_topic" "trigger-event-topic" {
  name = "trigger-event-topic"
}

resource "aws_sns_topic_subscription" "lambda-event-queue-sub" {
  topic_arn = aws_sns_topic.trigger-event-topic.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.lambda-event-queue.arn
}

resource "aws_sqs_queue" "lambda-event-queue" {
  name = "lambda-event-queue"
}

resource "aws_sqs_queue" "lambda-result-queue" {
  name = "lambda-result-queue"
}

resource "aws_lambda_event_source_mapping" "sqs-lambda-trigger" {
  event_source_arn = aws_sqs_queue.lambda-event-queue.arn
  enabled          = true
  function_name    = aws_lambda_function.event-echo-lambda.function_name
  batch_size       = 1
}

resource "aws_lambda_function" "event-echo-lambda" {
  filename         = "./lambda.zip"
  function_name    = "event-echo-lambda"
  role             = "arn:aws:iam::000000000000:role/lambda-exec"
  handler          = "lambda.handler"
  source_code_hash = filebase64sha256("./lambda.zip")
  runtime          = "python3.8"

  environment {
    variables = {
      BOTO_ENDPOINT_URL = "http://172.17.0.1:4566" # FIXME: should be injected transparently
      LAMBDA_RESULT_QUEUE = aws_sqs_queue.lambda-result-queue.url
    }
  }
}

