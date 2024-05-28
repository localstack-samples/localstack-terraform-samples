#!/usr/bin/env sh

# Get the API Gateway ID
http_api=$(aws --endpoint-url=http://localhost:4566 apigatewayv2 get-apis | jq -r .Items[0].ApiId)

# Make the curl requests and capture the responses
response1=$(curl -s -X POST "$http_api.execute-api.localhost.localstack.cloud:4566/package/123/payloads")
response2=$(curl -s -X POST "$http_api.execute-api.localhost.localstack.cloud:4566/package")
response3=$(curl -s -X POST "$http_api.execute-api.localhost.localstack.cloud:4566/")

# Output the responses for debugging purposes
echo "Response 1: $response1"
echo "Response 2: $response2"
echo "Response 3: $response3"

# Smoke test to validate the outputs
check_status_code() {
  response=$1
  if echo "$response" | jq -e '.statusCode == 200' > /dev/null; then
    echo "Smoke test passed: The response contains 'statusCode: 200'."
  else
    echo "Smoke test failed: The response does not contain 'statusCode: 200'."
    exit 1
  fi
}

check_status_code "$response1"
check_status_code "$response2"
check_status_code "$response3"
