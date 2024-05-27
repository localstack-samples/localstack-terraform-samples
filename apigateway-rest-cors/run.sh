#!/usr/bin/env sh

# Get the API Gateway ID
restapi=$(aws --endpoint-url=http://localhost:4566 apigateway get-rest-apis | jq -r .items[0].id)

# Make the curl request and capture the response
response=$(curl -s -X OPTIONS "http://localhost:4566/restapis/$restapi/local/_user_request_/test" -H "Access-Control-Request-Headers: Content-Type,Authorization,X-Amz-Date,X-Api-Key,X-Amz-Security-Token")

# Output the response for debugging purposes
echo "API Response: $response"

# Smoke test to validate the status code
if echo "$response" | jq -e '.statusCode == 200' > /dev/null; then
    echo "Smoke test passed: The statusCode is 200."
else
    echo "Smoke test failed: The statusCode is not 200."
    exit 1
fi
