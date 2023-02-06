#!/usr/bin/env sh

rm terraform.tfstate* || true

tflocal init; tflocal plan; tflocal apply --auto-approve

http_api=$(aws --endpoint-url=http://localhost:4566 apigatewayv2 get-apis | jq -r .Items[0].ApiId)

curl -X POST "$http_api.execute-api.localhost.localstack.cloud:4566/package/123/payloads"

curl -X POST "$http_api.execute-api.localhost.localstack.cloud:4566/package"

curl -X POST "$http_api.execute-api.localhost.localstack.cloud:4566/"
