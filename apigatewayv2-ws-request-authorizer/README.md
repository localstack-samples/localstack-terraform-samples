# API Gateway V2 WebSocket Request Authorizer

This sample demonstrates a WebSocket API with request authorization and Cognito user authentication flows.

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

## Run Terraform

`terraform init; terraform plan; terraform apply --auto-approve`

## Create Cognito users

Using the outputs run the following commands,

```
 lstk aws cognito-idp sign-up \
      --client-id <user_pool_client_id> \
      --username "user@domain.com" \
      --password "Ppassword123!"
```

then,

```
lstk aws cognito-idp admin-confirm-sign-up \
      --user-pool-id <user_pool_id> \
      --username "user@domain.com"
```

then,

```
lstk aws cognito-idp initiate-auth \
      --auth-flow USER_PASSWORD_AUTH \
      --auth-parameters USERNAME="user@domain.com",PASSWORD="password" \
      --client-id <user_pool_client_id>
```
