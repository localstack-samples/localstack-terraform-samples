# Generating an ACM certificate via Terraform

This example shows how to generate an ACM certificate for a domain via Terraform.

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

## Run

To run this example you need to execute:

```bash
lstk tf init
lstk tf plan
lstk tf apply --auto-approve
```

## Testing

Run the following command to test the example:

```bash
lstk aws acm list-certificates
```

You will see the following output:

```json
{
    "CertificateSummaryList": [
        {
            "CertificateArn": "arn:aws:acm:<REGION>:000000000000:certificate/<CERTIFICATE-ID>",
            "DomainName": "helloworld.info"
        }
    ]
}
```
