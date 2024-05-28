#!/usr/bin/env sh

go mod init apigatewayv2-go-lambda
go get .
GOOS=linux GOARCH=amd64 go build -o lambda
zip -r lambda.zip lambda

terraform init; terraform plan; terraform apply --auto-approve

httpapi=$(aws --endpoint-url=http://localhost:4566 apigatewayv2 get-apis | jq -r .Items[0].ApiId)
curl -X POST "$httpapi.execute-api.localhost.localstack.cloud:4566/call?name=Localstack" -H 'content-type: application/x-www-form-urlencoded' -d "param1=value1&param2=value2"
