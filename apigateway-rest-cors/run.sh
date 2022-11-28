#!/usr/bin/env sh

tflocal init; tflocal plan; tflocal apply --auto-approve

restapi=$(aws --endpoint-url=http://localhost:4566 apigateway  get-rest-apis | jq -r .items[0].id)
curl -X OPTIONS -v "http://localhost:4566/restapis/$restapi/local/_user_request_/test"
