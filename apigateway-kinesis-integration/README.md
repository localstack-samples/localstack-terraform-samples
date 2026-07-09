## API Gateway with Kinesis Integration

![LocalStack](https://img.shields.io/static/v1?label=Works&message=@LocalStack&color=purple)
![AWS](https://img.shields.io/static/v1?label=Works&message=@AWS&color=orange)

This project contains an example of an API Gateway with Kinesis Integration.

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

### Run

Execute the following commands to run the example:

```bash
./run.sh
```

## Notes

Use `tfswitch` or `tfenv` to install the required provider version
