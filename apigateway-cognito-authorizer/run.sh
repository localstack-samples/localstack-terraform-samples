#!/usr/bin/env sh


terraform init; terraform plan;

#export TF_LOG=debug
terraform apply --auto-approve

restapi=$(aws apigateway --endpoint-url=http://localhost:4566 get-rest-apis | jq -r .items[0].id)
curl $restapi.execute-api.localhost.localstack.cloud:4566/local/demo -H "Authorization: Bearer ey"
