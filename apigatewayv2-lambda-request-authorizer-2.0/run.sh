#!/usr/bin/env sh

# Get the API Gateway ID
httpapi=$(aws --endpoint-url=http://localhost:4566 apigatewayv2 get-apis | jq -r .Items[0].ApiId)

# Make the curl request and capture the response
response=$(curl -s -X POST "$httpapi.execute-api.localhost.localstack.cloud:4566/example/test" -H 'Authorization: secretToken')

# Output the response for debugging purposes
echo "API Response: $response"

# Smoke test to validate the output
if echo "$response" | jq -e '.statusCode == 200' > /dev/null; then
    echo "Smoke test passed: The response contains 'statusCode: 200'."
else
    echo "Smoke test failed: The response does not contain 'statusCode: 200'."
    exit 1
fi
