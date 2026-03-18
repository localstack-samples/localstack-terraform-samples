# S3-SQS-Notifications

## Description

- This sample deploys a Terraform configuration
- Copies a log file into an S3 bucket
- Sends a notification to an SQS queue
- Retrieves a message from an SQS queue

## Prerequisites

- A valid [LocalStack for AWS license](https://localstack.cloud/pricing). Your license provides a [`LOCALSTACK_AUTH_TOKEN`](https://docs.localstack.cloud/getting-started/auth-token/).
- [Docker](https://docs.docker.com/get-docker/)
- [`localstack` CLI](https://docs.localstack.cloud/getting-started/installation/#localstack-cli)
- [`awslocal` CLI](https://docs.localstack.cloud/user-guide/integrations/aws-cli/)
- [Terraform](https://developer.hashicorp.com/terraform/downloads)
- `make` and `jq`

## Start LocalStack

```bash
export LOCALSTACK_AUTH_TOKEN=<your-auth-token>
make start
make ready
```

## Deployment

1. Clone the repository and navigate to the sample directory.

- Run the `./deploy.sh` script to deploy the full sample.

## Files

- `./deploy.sh`:  Deployment script
- `main.tf`: Terraform configuration file
- `provider.tf`: Terraform provider configuration file
- `some-log-file.log`: Sample log file
