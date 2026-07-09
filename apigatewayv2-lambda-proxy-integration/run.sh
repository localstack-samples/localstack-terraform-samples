#!/usr/bin/env sh

# Get the API Gateway ID
http_api=$(lstk aws apigatewayv2 get-apis | jq -r .Items[0].ApiId)

# Make the curl requests and capture the HTTP status codes.
# The Lambda returns a proxy response of {"statusCode": 200, ...} with no body,
# so we assert on the HTTP status code rather than the (empty) response body.
status1=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$http_api.execute-api.localhost.localstack.cloud:4566/package/123/payloads")
status2=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$http_api.execute-api.localhost.localstack.cloud:4566/package")
status3=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$http_api.execute-api.localhost.localstack.cloud:4566/")

# Output the statuses for debugging purposes
echo "Status 1: $status1"
echo "Status 2: $status2"
echo "Status 3: $status3"

# Smoke test to validate the outputs
check_status_code() {
  status=$1
  if [ "$status" = "200" ]; then
    echo "Smoke test passed: The response status code is 200."
  else
    echo "Smoke test failed: The response status code is '$status', not 200."
    exit 1
  fi
}

check_status_code "$status1"
check_status_code "$status2"
check_status_code "$status3"
