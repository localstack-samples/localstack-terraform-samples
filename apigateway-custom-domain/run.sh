#!/usr/bin/env sh

export TF_LOG=debug
rm terraform.tfstate || true

terraform init; terraform plan; terraform apply --auto-approve

restapi=$(aws apigateway --endpoint-url=http://localhost:4566 get-rest-apis | jq -r .items[0].id)
curl $restapi.execute-api.localhost.localstack.cloud:4566/dev/test -H "Host: api.example.com"
