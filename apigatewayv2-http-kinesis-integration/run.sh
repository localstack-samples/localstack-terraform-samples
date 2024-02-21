#!/usr/bin/env sh

tflocal init; tflocal plan; tflocal apply --auto-approve

httpapi=$(aws --endpoint-url=http://localhost:4566 apigatewayv2 get-apis | jq -r .Items[0].ApiId)

curl "$httpapi.execute-api.localhost.localstack.cloud:4566/" \
  -H 'Content-Type: application/json' \
  -d '{
    "data": "J0hlbGxvLCBXb3JsZCEnCg==",
    "partitionKey": "partitionKey1"
  }'

