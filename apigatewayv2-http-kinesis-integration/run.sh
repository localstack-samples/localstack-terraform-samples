#!/usr/bin/env sh

terraform init; terraform plan; terraform apply --auto-approve

httpapi=$(aws --endpoint-url=http://localhost:4566 apigatewayv2 get-apis | jq -r .Items[0].ApiId)

```
curl -X POST \                                                                                                                        0 (8.295s) < 21:52:05
          https://r4m6re6gof.execute-api.us-east-1.amazonaws.com/ \
          -H 'Content-Type: application/json' \
          -d '{
        "data": "J0hlbGxvLCBXb3JsZCEnCg==",
        "partitionKey": "p1"
      }'
```
