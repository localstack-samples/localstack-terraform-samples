#!/usr/bin/env sh

# Get the API Gateway ID
httpapi=$(aws --endpoint-url=http://localhost:4566 apigatewayv2 get-apis | jq -r .Items[0].ApiId)

# Make the curl request and capture the response
response=$(curl -s -X POST "$httpapi.execute-api.localhost.localstack.cloud:4566/call?name=Localstack" -H 'content-type: application/x-www-form-urlencoded' -d "param1=value1&param2=value2")

# Output the response for debugging purposes
echo "API Response: $response"

# Smoke test to validate the output
if echo "$response" | grep -q "Hello, Localstack!"; then
    echo "Smoke test passed: The response contains 'Hello, Localstack!'."
else
    echo "Smoke test failed: The response does not contain 'Hello, Localstack!'."
    exit 1
fi
