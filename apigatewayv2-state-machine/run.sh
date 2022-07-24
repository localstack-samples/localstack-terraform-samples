#!/usr/bin/env sh

rm terraform.tfstate || true

terraform init; terraform plan; terraform apply --auto-approve

httpapi=$(aws --endpoint-url=http://localhost:4566 apigatewayv2 get-apis | jq -r .Items[0].ApiId)
curl "$httpapi.execute-api.localhost.localstack.cloud:4566/test" -H 'content-type: application/json' -d '{ "input": "{}", "name": "MyExecution", "stateMachineArn": "arn:aws:states:eu-west-1:000000000000:stateMachine:my-state-machine"}'
