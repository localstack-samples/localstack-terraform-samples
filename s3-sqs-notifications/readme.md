# S3-SQS-Notifications

## Description

- This sample deploys a Terraform configuration
- Copies a log file into an S3 bucket
- Sends a notification to an SQS queue
- Retrieves a message from an SQS queue

## Prerequisites

- Terraform
- AWS CLI
- jq

## Deployment

1. Clone the repository and navigate to the sample directory.

- Run the `./deploy.sh` script to deploy the full sample.

## Files

- `./deploy.sh`:  Deployment script
- `main.tf`: Terraform configuration file
- `provider.tf`: Terraform provider configuration file
- `some-log-file.log`: Sample log file
