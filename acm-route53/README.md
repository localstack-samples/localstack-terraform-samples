# Generating an ACM certificate via Terraform

This example shows how to generate an ACM certificate for a domain via Terraform.

### Requirements

- LocalStack Community
- Terraform CLI
- `tflocal` wrapper script
- `awslocal` wrapper script

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
