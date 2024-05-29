#!/usr/bin/env sh

set -x

apikey=$(tflocal output -json | jq -r .apigw_key.value)

sleep 5

restapi=$(aws apigateway --endpoint-url=http://localhost:4566 get-rest-apis | jq -r .items[0].id)
curl $restapi.execute-api.localhost.localstack.cloud:4566/v1/pets -H "x-api-key: ${apikey}" -H 'Content-Type: application/json' --request POST --data-raw '{ "PetType": "dog", "PetName": "tito", "PetPrice": 250 }'

response=$(curl -H "x-api-key: ${apikey}" --request GET $restapi.execute-api.localhost.localstack.cloud:4566/v1/pets/dog)

echo "$response"

# Test to ensure the response contains the expected fields
echo "$response" | jq -e '
    .pets and
    .pets[0].id and
    .pets[0].PetType and
    .pets[0].PetName and
    .pets[0].PetPrice
' > /dev/null

if [ $? -eq 0 ]; then
    echo "Test passed: All expected fields are present."
else
    echo "Test failed: Expected fields are missing."
    exit 1
fi
