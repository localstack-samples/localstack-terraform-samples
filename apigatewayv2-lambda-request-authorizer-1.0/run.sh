#!/usr/bin/env sh

set -eo pipefail

# Get the API Gateway ID
httpapi=$(aws --endpoint-url=http://localhost:4566 apigatewayv2 get-apis | jq -r .Items[0].ApiId)

# Make the curl request and capture the response
response=$(curl -s -X POST "$httpapi.execute-api.localhost.localstack.cloud:4566/example/test" -H 'Authorization: secretToken')

# Output the response for debugging purposes
echo "API Response: $response"

# Smoke test to validate the output
if echo "$response" | grep -q "\"message\":\"Hello from Lambda!\""; then
    echo "Smoke test passed: The response contains 'Hello from Lambda!'."
else
    echo "Smoke test failed: The response does not contain 'Hello from Lambda!'."
    exit 1
fi
