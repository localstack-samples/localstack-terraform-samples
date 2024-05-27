#!/usr/bin/env sh

set -x

# Get the API Gateway ID
restapi=$(aws apigateway --endpoint-url=http://localhost:4566 get-rest-apis | jq -r .items[0].id)

# Make the curl request and capture the response
response=$(curl -s http://$restapi.execute-api.localhost.localstack.cloud:4566/local/proxy)

# Output the response for debugging purposes
echo "$response"

# Smoke test to validate the output
echo "$response" | jq -e '
  .args and
  .data and
  .files and
  .form and
  .headers and
  .json == null and
  .method == "GET" and
  .origin and
  .url
' > /dev/null

if [ $? -eq 0 ]; then
    echo "Smoke test passed: All expected fields are present."
else
    echo "Smoke test failed: Expected fields are missing."
    exit 1
fi
