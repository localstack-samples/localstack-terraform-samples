#!/usr/bin/env sh

terraform init; terraform plan; terraform apply --auto-approve

httpapi=$(aws --endpoint-url=http://localhost:4566 apigatewayv2 get-apis | jq -r .Items[0].ApiId)
curl -X POST "$httpapi.execute-api.localhost.localstack.cloud:4566/example/test" -H 'content-type: application/json' -d '{ "greeter": "cesar" }'
