#!/usr/bin/env sh

terraform init; terraform plan; terraform apply --auto-approve


httpapi=$(aws --endpoint-url=http://localhost:4566 apigatewayv2 get-apis | jq -r .Items[0].ApiId)

curl -vs -X GET "$httpapi.execute-api.localhost.localstack.cloud:4566/dev/hello/API"
curl -vs -X GET --referer https://my.site.example.com/ "https://$httpapi.execute-api.localhost.localstack.cloud:4566/dev/hello/API"
curl -vs -X POST "$httpapi.execute-api.localhost.localstack.cloud:4566/dev/hello/API"
curl -vs -X POST --referer https://localhost.localstack.cloud/ "$httpapi.execute-api.localhost.localstack.cloud:4566/dev/hello/API"
curl -vs -X POST --referer https://my.site.example.com/ "$httpapi.execute-api.localhost.localstack.cloud:4566/dev/hello/API"
