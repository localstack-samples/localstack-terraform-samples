#!/usr/bin/env sh

# Get the API Gateway ID
httpapi=$(aws --endpoint-url=http://localhost:4566 apigatewayv2 get-apis | jq -r .Items[0].ApiId)

# Make the curl request and capture the response
response=$(curl -s -X POST "$httpapi.execute-api.localhost.localstack.cloud:4566/example/test" \
  -H 'content-type: application/json' \
  -d '{ "greeter": "cesar" }' \
  --cookie "Cookie1=Yes;Cookie2=no")

# Output the response for debugging purposes
echo "API Response: $response"

# Smoke test to validate the output
if echo "$response" | grep -q "Hello, cesar!"; then
    echo "Smoke test passed: The response contains 'Hello, cesar!'."
else
    echo "Smoke test failed: The response does not contain 'Hello, cesar!'."
    exit 1
fi
