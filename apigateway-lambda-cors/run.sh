#!/usr/bin/env sh

set -x

# Get the API Gateway ID
restapi=$(aws apigateway --endpoint-url=http://localhost:4566 get-rest-apis | jq -r .items[0].id)

# Make the curl request and capture the response
response=$(curl -s -X POST "$restapi.execute-api.localhost.localstack.cloud:4566/dev/cors" -d "bye")

# Output the response for debugging purposes
echo "$response"

# Smoke test to validate the output
if echo "$response" | grep -q "Hello from Lambda!"; then
    echo "Smoke test passed: The response contains 'Hello from Lambda!'."
else
    echo "Smoke test failed: The response does not contain 'Hello from Lambda!'."
    exit 1
fi
