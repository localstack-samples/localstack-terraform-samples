## API Gateway V2 Lambda Request Authorizer

![LocalStack](https://img.shields.io/static/v1?label=Works&message=@LocalStack&color=purple)
![AWS](https://img.shields.io/static/v1?label=Works&message=@AWS&color=orange)

This project contains a sample Lambda function that can be used as a request authorizer for API Gateway V2.

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

### Run

Execute the following commands to run the example:

```bash
./run.sh
```

## Notes

Use `tfswitch` or `tfenv` to install the required provider version
