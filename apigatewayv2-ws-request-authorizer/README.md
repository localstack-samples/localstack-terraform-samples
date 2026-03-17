# API Gateway V2 WebSocket Request Authorizer

This sample demonstrates a WebSocket API with request authorization and Cognito user authentication flows.

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

## Run Terraform

`terraform init; terraform plan; terraform apply --auto-approve`

## Create Cognito users

Using the outputs run the following commands,

```
 awslocal cognito-idp sign-up \
      --client-id <user_pool_client_id> \
      --username "user@domain.com" \
      --password "Ppassword123!"
```

then,

```
awslocal cognito-idp admin-confirm-sign-up \
      --user-pool-id <user_pool_id> \
      --username "user@domain.com"
```

then,

```
awslocal cognito-idp initiate-auth \
      --auth-flow USER_PASSWORD_AUTH \
      --auth-parameters USERNAME="user@domain.com",PASSWORD="password" \
      --client-id <user_pool_client_id>
```
