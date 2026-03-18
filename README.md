# LocalStack Terraform Samples

This repository contains Terraform-based sample projects that can be deployed on your local machine using [LocalStack](https://localstack.cloud/).

Each example in the repository is prefixed with the AWS service being used. For example, the `apigateway-dynamodb` directory contains a sample showing API Gateway and DynamoDB resources provisioned with Terraform. Refer to each sample directory for detailed instructions.

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/)
- [`localstack` CLI](https://docs.localstack.cloud/getting-started/installation/#localstack-cli)
- [`awslocal` CLI](https://docs.localstack.cloud/user-guide/integrations/aws-cli/)
- [Terraform](https://developer.hashicorp.com/terraform/downloads)
- `make` and `jq`

## Configuration

All samples require a valid [LocalStack for AWS license](https://localstack.cloud/pricing). Your license provides a [`LOCALSTACK_AUTH_TOKEN`](https://docs.localstack.cloud/getting-started/auth-token/) to activate LocalStack.

Set it before running any sample:

```bash
export LOCALSTACK_AUTH_TOKEN=<your-auth-token>
```

Alternatively, use the LocalStack CLI to persist the token:

```bash
localstack auth set-token <your-auth-token>
```

You can find your auth token in the [LocalStack Web Application](https://app.localstack.cloud/workspace/auth-token).

## Outline

| Sample Name | Description |
| --- | --- |
| [ACM + Route53](acm-route53) | Generate an ACM certificate and validate it with Route53 records. |
| [API Gateway + DynamoDB](apigateway-dynamodb) | Provision a REST API that works with DynamoDB. |
| [API Gateway HTTP Proxy Authorizer](apigateway-http-proxy-authorizer) | Configure API Gateway REST methods with Lambda authorizer and proxy integrations. |
| [API Gateway + Kinesis](apigateway-kinesis-integration) | Integrate API Gateway REST endpoints with Kinesis streams. |
| [API Gateway + Kinesis + Lambda](apigateway-kinesis-lambda-integration) | Connect API Gateway to Kinesis with Lambda producer and consumer functions. |
| [API Gateway Lambda CORS](apigateway-lambda-cors) | Configure API Gateway Lambda integration with CORS support. |
| [API Gateway REST CORS](apigateway-rest-cors) | Configure REST API MOCK integrations and CORS responses. |
| [API Gateway SNS Deploy](apigateway-sns-deploy) | Publish API Gateway requests to SNS topics. |
| [API Gateway Stage Cluster](apigateway-stage-cluster) | Deploy API Gateway stages and stage-specific routes/integrations. |
| [API Gateway Stage Variables](apigateway-stage-variables) | Use stage variables with API Gateway REST APIs. |
| [API Gateway + Step Functions](apigateway-step-functions-integration) | Integrate API Gateway REST endpoints with Step Functions. |
| [API Gateway V2 HTTP + Kinesis](apigatewayv2-http-kinesis-integration) | Integrate HTTP APIs (v2) with Kinesis streams. |
| [API Gateway V2 Lambda Proxy](apigatewayv2-lambda-proxy) | Create an HTTP API (v2) with Lambda proxy integration. |
| [API Gateway V2 Lambda Binary Proxy](apigatewayv2-lambda-proxy-handling-binary) | Handle binary payloads using API Gateway v2 Lambda proxy integrations. |
| [API Gateway V2 Lambda Proxy Integration](apigatewayv2-lambda-proxy-integration) | API Gateway v2 Lambda proxy integration flow. |
| [API Gateway V2 Lambda Authorizer 1.0](apigatewayv2-lambda-request-authorizer-1.0) | HTTP API Lambda request authorizer with payload format version 1.0. |
| [API Gateway V2 Lambda Authorizer 2.0](apigatewayv2-lambda-request-authorizer-2.0) | HTTP API Lambda request authorizer with payload format version 2.0. |
| [API Gateway V2 + Step Functions](apigatewayv2-step-functions-integration) | Integrate HTTP APIs (v2) with Step Functions. |
| [API Gateway V2 WebSocket + HTTP](apigatewayv2-ws-http) | WebSocket API integration with HTTP backends. |
| [API Gateway V2 WebSocket HTTP Proxy](apigatewayv2-ws-http-proxy) | WebSocket API integration using HTTP proxy mode. |
| [API Gateway V2 WebSocket + Kinesis](apigatewayv2-ws-kinesis-integration) | WebSocket API integration with Kinesis streams. |
| [API Gateway V2 WebSocket Authorizer](apigatewayv2-ws-request-authorizer) | WebSocket API with Lambda request authorizer. |
| [API Gateway V2 WebSocket Sample](apigatewayv2-ws-sample) | End-to-end WebSocket API sample with connect/disconnect handlers and auth. |
| [API Gateway V2 WebSocket + SNS](apigatewayv2-ws-sns) | Publish WebSocket messages through SNS integrations. |
| [API Gateway V2 WebSocket + SQS](apigatewayv2-ws-sqs) | Publish WebSocket messages through SQS integrations. |
| [API Gateway V2 WebSocket Subprotocol](apigatewayv2-ws-sub-protocol) | WebSocket API handling custom sub-protocols. |
| [Cognito Group Example](cognito-group-example) | Create Cognito user pools and user groups. |
| [Demo Deploy](demo-deploy) | Modular Terraform deployment for API Gateway, S3, SQS, DynamoDB, and authorizers. |
| [Lambda + Kinesis + Firehose + Elasticsearch](lambda-kinesis-firehose-es) | Build a data pipeline with Lambda, Kinesis, Firehose, and Elasticsearch/OpenSearch resources. |
| [Managed Streaming for Kafka Cluster](managed-streaming-kafka-cluster) | Provision a Kafka cluster and supporting resources with Terraform. |
| [S3 + SQS Notifications](s3-sqs-notifications) | Configure S3 event notifications to SQS. |
| [S3 Static Website](s3-static-website) | Deploy a static website on S3. |
| [WebSocket Deploy](websocket-deploy) | Basic WebSocket API deployment with Lambda backend. |

Archived and non-functional samples are kept in [`sample-archive/`](sample-archive/README.md).

## Checking Out A Single Sample

To check out only one sample directory:

```bash
mkdir localstack-terraform-samples && cd localstack-terraform-samples
git init
git remote add origin -f git@github.com:localstack-samples/localstack-terraform-samples.git
git config core.sparseCheckout true
echo <LOCALSTACK_SAMPLE_DIRECTORY_NAME> >> .git/info/sparse-checkout
git pull origin master
```

The commands above use sparse checkout to pull only the sample you need.

## License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.
