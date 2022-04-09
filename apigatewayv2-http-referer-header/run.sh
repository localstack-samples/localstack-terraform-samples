#!/usr/bin/env sh

terraform init; terraform plan; terraform apply --auto-approve


httpapi=$(aws --endpoint-url=http://localhost:4566 apigatewayv2 get-apis | jq -r .Items[0].ApiId)
curl -X POST "$httpapi.execute-api.localhost.localstack.cloud:4566/example/test" -H 'content-type: application/json' -d '{ "greeter": "cesar" }' --cookie "Cookie1=Yes;Cookie2=no"


curl -vs -X GET "https://$httpapi.execute-api.localhost.localstack.cloud:4566/dev/hello/API"
curl -vs -X GET --referer https://my.site.example.com/ "https://$httpapi.execute-api.localhost.localstack.cloud:4566/dev/hello/API"
curl -vs -X POST "https://$httpapi.execute-api.localhost.localstack.cloud:4566/dev/hello/API"
curl -vs -X POST --referer https://localhost.localstack.cloud/ "https://$httpapi.execute-api.localhost.localstack.cloud:4566/dev/hello/API"
curl -vs -X POST --referer https://my.site.example.com/ "https://$httpapi.execute-api.localhost.localstack.cloud:4566/dev/hello/API"
