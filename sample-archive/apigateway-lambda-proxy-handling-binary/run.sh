#!/usr/bin/env sh

terraform init; terraform plan; terraform apply --auto-approve

restapi=$(aws --endpoint-url=http://localhost:4566 apigateway get-rest-apis | jq -r .items[0].id)
curl -X POST "$restapi.execute-api.localhost.localstack.cloud:4566/local/test?foo=bar" -H 'content-type: application/json' -d '{ "greeter": "cesar" }'
curl -X POST "$restapi.execute-api.localhost.localstack.cloud:4566/local/test?demo64Flag=1" -H 'content-type: image/jpeg' --data-binary @./nyan-cat.jpg --output -
