#!/usr/bin/env sh

set -x

tflocal init; tflocal plan; tflocal apply --auto-approve

restapi=$(aws apigateway --endpoint-url=http://localhost:4566 get-rest-apis | jq -r .items[0].id)
curl -vvv "$restapi.execute-api.localhost.localstack.cloud:4566/dev/api/v1/user/techops+proviosion@gmail.com"

curl -vvv "$restapi.execute-api.localhost.localstack.cloud:4566/dev/api/v1/user/techops%2Bproviosion@gmail.com"
