# Terraform sample showing SNS SQS Lambda integration

This Terraform sample demonstrates SNS delivery to SQS queues via subscriptions, Lambda invocations through SQS event source mappings, and accessing LocalStack services from lambdas.

The basic pipeline is:

* Publish -> SNS Topic (via user input)
* SNS Topic -> SQS queue (via SNS subscription)
* SQS Queue -> Lambda invokation (Lambda event source mapping)
* Lambda -> SQS (via AWS SDK from within a Lambda)
* SQS -> Receive message (via user input)

## Limitation

Currently you need to manually set `BOTO_ENDPOINT_URL` in `main.tf` to the host name that the LocalStack Lambda container can reach LocalStack.

## Resources

* https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_subscription
* https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_event_source_mapping
