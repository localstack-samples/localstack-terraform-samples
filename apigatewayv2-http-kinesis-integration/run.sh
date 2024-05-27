#!/usr/bin/env sh

# Get the API Gateway ID
httpapi=$(aws --endpoint-url=http://localhost:4566 apigatewayv2 get-apis | jq -r .Items[0].ApiId)

# Make the curl request and capture the response
response=$(curl -s -X POST "$httpapi.execute-api.localhost.localstack.cloud:4566/" \
  -H 'Content-Type: application/json' \
  -d '{
    "data": "J0hlbGxvLCBXb3JsZCEnCg==",
    "partitionKey": "partitionKey1"
  }')

# Output the response for debugging purposes
echo "API Response: $response"

# Smoke test to validate the output
if echo "$response" | jq -e '.ShardId and .SequenceNumber and .EncryptionType' > /dev/null; then
    echo "Smoke test passed: The response contains 'ShardId', 'SequenceNumber', and 'EncryptionType'."
else
    echo "Smoke test failed: The response does not contain the expected fields."
    exit 1
fi
