#!/usr/bin/env sh

set -euo pipefail
set -x

rm terraform.tfstate* || true
tflocal init; tflocal apply --auto-approve

restapi=$(aws apigateway --endpoint-url=http://localhost:4566 get-rest-apis | jq -r .items[0].id)
curl -X POST "http://$restapi.execute-api.us-east-1.localhost.localstack.cloud:4566/dev/graphql"
