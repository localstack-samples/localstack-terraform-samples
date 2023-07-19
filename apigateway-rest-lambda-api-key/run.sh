#!/usr/bin/env sh

export TF_LOG=trace
rm terraform.tfstate* || true

tflocal init; tflocal plan; tflocal apply --auto-approve

restapi=$(aws apigateway --endpoint-url=http://localhost:4566 get-rest-apis | jq -r .items[0].id)
apikeyid=$(aws apigateway --endpoint-url=http://localhost:4566  get-api-keys | jq .items[].id)
apikeyvalue=$(aws apigateway --endpoint-url=http://localhost:4566  get-api-key --api-key ${apikeyid} --include-value --query "value" --output text)
curl -X POST  $restapi.execute-api.localhost.localstack.cloud:4566/dev/auth?apiKey=${apikeyvalue}
