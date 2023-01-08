#!/usr/bin/env sh

eval "$(curl -q -s https://raw.githubusercontent.com/coryb/osht/master/osht.sh)"

rm terraform.tfstate

tflocal init; tflocal plan; tflocal apply --auto-approve

restapi=$(aws --endpoint-url=http://localhost:4566 apigateway  get-rest-apis | jq -r .items[0].id)
response=$(curl -X POST "$restapi.execute-api.localhost.localstack.cloud:4566/dev/test")
IS "$response" =~ "Hello from Lambda, version beta-version"
