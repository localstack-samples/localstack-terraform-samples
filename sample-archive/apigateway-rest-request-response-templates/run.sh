#!/usr/bin/env sh

rm terraform.tfstate || true

lstk tf init; lstk tf plan; lstk tf apply --auto-approve

restapi=$(aws apigateway --endpoint-url=http://localhost:4566 get-rest-apis | jq -r .items[0].id)
curl -v -H "Content-Type: application/json" -d "{\"httpStatus\": \"400\", \"errorMessage\": \"Test Bad request\"}" "https://$restapi.execute-api.localhost.localstack.cloud:4566/dev/products/abcd-1234/items?status=PENDING\&limit=100"
