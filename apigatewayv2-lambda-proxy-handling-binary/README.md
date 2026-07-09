# APIgatewayv2 Lambda Proxy Handling Binary

This sample demonstrates Terraform-based AWS service emulation with LocalStack.

## Prerequisites

- A valid [LocalStack for AWS license](https://localstack.cloud/pricing). Your license provides a [`LOCALSTACK_AUTH_TOKEN`](https://docs.localstack.cloud/getting-started/auth-token/).
- [Docker](https://docs.docker.com/get-docker/)
- [`lstk` CLI](https://docs.localstack.cloud/aws/tooling/lstk/)
- [Terraform](https://developer.hashicorp.com/terraform/downloads)
- `make` and `jq`

## Start LocalStack

```bash
export LOCALSTACK_AUTH_TOKEN=<your-auth-token>
make start
```

## Run Sample

```bash
make install
make init
make deploy
make test
```
