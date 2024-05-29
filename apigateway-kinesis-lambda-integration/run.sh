#!/usr/bin/env sh

set -x

# Get the API Gateway ID
restapi=$(aws apigateway --endpoint-url=http://localhost:4566 get-rest-apis | jq -r .items[0].id)

# Make the curl request and capture the response
response=$(curl -s -X POST "$restapi.execute-api.localhost.localstack.cloud:4566/dev/api?who=god")

# Output the response for debugging purposes
echo "$response"

# Smoke test to validate the output
echo "$response" | jq -e '
  .state == "ok"
' > /dev/null

if [ $? -eq 0 ]; then
    echo "Smoke test passed: The state is 'ok'."
else
    echo "Smoke test failed: The state is not 'ok'."
    exit 1
fi
