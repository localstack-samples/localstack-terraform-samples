#!/usr/bin/env sh

rm terraform.tfstate* || true

tflocal init; tflocal plan; tflocal apply --auto-approve

restapi=$(aws --endpoint-url=http://localhost:4566 apigateway  get-rest-apis | jq -r .items[0].id)
curl "$restapi.execute-api.localhost.localstack.cloud:4566/local/test" -H 'content-type: application/json' -d '{ "input": "{}", "name": "MyExecution"}'
