#!/usr/bin/env sh

set -x

tflocal init; tflocal plan; tflocal apply --auto-approve

apikey=$(tflocal output -json | jq -r .apigw_key.value)

sleep 5

restapi=$(aws apigateway --endpoint-url=http://localhost:4566 get-rest-apis | jq -r .items[0].id)
curl $restapi.execute-api.localhost.localstack.cloud:4566/v1/pets -H "x-api-key: ${apikey}" -H 'Content-Type: application/json' --request POST --data-raw '{ "PetType": "dog", "PetName": "tito", "PetPrice": 250 }'

curl -H "x-api-key: ${apikey}" --request GET $restapi.execute-api.localhost.localstack.cloud:4566/v1/pets/dog
