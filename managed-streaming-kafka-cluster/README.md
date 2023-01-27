# Managed Streaming for Kafka

LocalStack supports a basic version of Managed Streaming for Kafka (MSK) for testing. This allows you to spin up Kafka clusters on the local machine, create topics for exchanging messages, and define event source mappings that trigger Lambda functions when messages are received on a certain topic.

## Requirements

- [LocalStack Pro](https://app.localstack.cloud/)
- [Terraform CLI](https://developer.hashicorp.com/terraform/downloads?product_intent=terraform)
- [`tflocal` CLI](https://github.com/localstack/terraform-local)

## Run

To run the example, start LocalStack, and then run the following commands:

```sh
terraform init

terraform plan

terraform apply --auto-approve
```
