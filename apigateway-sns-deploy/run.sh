#!/usr/bin/env sh

# Get the API Gateway ID
restapi=$(aws apigateway --endpoint-url=http://localhost:4566 get-rest-apis | jq -r .items[0].id)

# Make the curl request and capture the response
response=$(curl -s -X POST "$restapi.execute-api.localhost.localstack.cloud:4566/local/ingest" -H 'Content-Type: application/json' -d '{
              "HID": "ad",
              "SID": "consequat ex velit sed",
              "Data": {
                "ipsum_e_": 50662226
              }
            }')

# Output the response for debugging purposes
echo "API Response: $response"

# Smoke test to validate the output
if echo "$response" | jq -e '.status == "message published"' > /dev/null; then
    echo "Smoke test passed: The status is 'message published'."
else
    echo "Smoke test failed: The status is not 'message published'."
    exit 1
fi
