#!/usr/bin/env sh

tflocal init; tflocal plan; tflocal apply -auto-approve

restapi=$(aws --endpoint-url=http://localhost:4566 apigateway  get-rest-apis | jq -r .items[0].id)
curl --location --request POST "$restapi.execute-api.localhost.localstack.cloud:4566/local/orders" --header 'Content-Type: application/json' \
--data-raw '{ "items":[ {"Detail":"{\"data\":\"Order is created\"}", "DetailType":"Test", "Source":"com.inv.order"}]}'
