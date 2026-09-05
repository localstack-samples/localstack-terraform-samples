#!/usr/bin/env sh

set -x

lstk tf init; lstk tf plan; lstk tf apply --auto-approve

restapi=$(aws apigateway --endpoint-url=http://localhost:4566 get-rest-apis | jq -r .items[0].id)
curl $restapi.execute-api.localhost.localstack.cloud:4566/dev/test -H "Host: api.example.com"
