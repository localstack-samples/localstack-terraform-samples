# Generating an ACM certificate via Terraform

This example shows how to generate an ACM certificate for a domain via Terraform.

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

## Run

To run this example you need to execute:

```bash
tflocal init
tflocal plan
tflocal apply --auto-approve
```

## Testing

Run the following command to test the example:

```bash
awslocal acm list-certificates
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
