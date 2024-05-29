# AWS Managed Streaming for Kafka

This example uses the [Cloud Posse Terraform Module](https://github.com/cloudposse/terraform-aws-msk-apache-kafka-cluster) for Apache Kafka to spin up a Kafka cluster on LocalStack.

The Terraform code was adapted from their [complete example](https://github.com/cloudposse/terraform-aws-msk-apache-kafka-cluster/tree/master/examples/complete).

## Run

This example requires LocalStack Pro.

### Prepare LocalStack

Once you have started LocalStack, proceed to prepare a route53 zone:

```sh
awslocal route53 create-hosted-zone \
	--name my-kafka.localhost.localstack.cloud \
	--caller-reference cli-invocation-0
```

and extract the ID from the `HostedZone` key:

```json
{
    "HostedZone": {
        "Id": "/hostedzone/BNO2IHZH6J52EJS",
//                         ^^^^^^^^^^^^^^^
//                         zone id
```

### Run Terraform

To initialize all Terraform modules, first run

    terraform init


Then run

    terraform apply -var-file fixtures.us-east-1.tfvars

When Terraform prompts for the ZoneID, use the route53 id from the hosted zone created earlier:

```
var.zone_id
  ZoneID for DNS Hostnames of MSK Brokers

  Enter a value: BNO2IHZH6J52EJS
```

The creation of the stack may take a couple of minutes.
Once complete, you should see something like:

```
Apply complete! Resources: 38 added, 0 changed, 0 destroyed.

Outputs:

cluster_arn = "arn:aws:kafka:us-east-1:000000000000:cluster/eg-ue1-test-msk-test/404bc537-7d80-4c9b-b5c7-b17e98c2e7dc-25"
cluster_name = "eg-ue1-test-msk-test"
config_arn = "arn:aws:kafka:us-east-1:000000000000:configuration/eg-ue1-test-msk-test"
hostname = "msk-test-broker-1.my-kafka.localhost.localstack.cloud,msk-test-broker-2.my-kafka.localhost.localstack.cloud"
security_group_id = "sg-354f76f59ec23d335"
security_group_name = "eg-ue1-test-msk-test"
```

### Interacting with Kafka

Once the cluster has been provisioned, you can interact with the Kafka cluster.
You can find out more at https://docs.localstack.cloud/aws/managed-streaming-for-kafka.


## Licenses

* Original Terraform example code: Apache License Version 2.0, Copyright 2020 Cloud Posse, LLC
