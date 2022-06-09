# AWS ElastiCache For Redis

This example uses the Cloud Posse Terraform Module for Redis to spin up an Elasticache instance on LocalStack

The Terraform code was adapted from their complete example

## Run

This example requires LocalStack Pro

### Run Terraform

To initialize all Terraform modules, first run

```sh
terraform init
```

Then run 

```sh
terraform apply -var-file fixtures.us-east-1.tfvars
```

The creation of the stack may take a couple of minutes. Once complete, you should see something like:


### Interacting with ElastiCache for Redis