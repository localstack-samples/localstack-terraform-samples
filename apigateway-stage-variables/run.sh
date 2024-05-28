#!/usr/bin/env sh

# Get the API Gateway ID
restapi=$(aws --endpoint-url=http://localhost:4566 apigateway get-rest-apis | jq -r .items[0].id)

# Make the curl request and capture the response
response=$(curl -s -X POST "$restapi.execute-api.localhost.localstack.cloud:4566/dev/test")

# Output the response for debugging purposes
echo "API Response: $response"

# Smoke test to validate the output
if echo "$response" | grep -q "Hello from Lambda, version beta-version"; then
    echo "Smoke test passed: The response contains 'Hello from Lambda, version beta-version'."
else
    echo "Smoke test failed: The response does not contain 'Hello from Lambda, version beta-version'."
    exit 1
fi
