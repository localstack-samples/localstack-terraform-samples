#!/usr/bin/env sh

export TF_LOG=debug
rm terraformstate* || true

terraform init; terraform plan; terraform apply --auto-approve

restapi=$(aws --endpoint-url=http://localhost:4566 apigateway  get-rest-apis | jq -r .items[0].id)
curl -X POST "$restapi.execute-api.localhost.localstack.cloud:4566/local/test" -H 'content-type: application/json'
