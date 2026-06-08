#!/usr/bin/env sh

# Get the API Gateway ID
httpapi=$(lstk aws apigatewayv2 get-apis | jq -r .Items[0].ApiId)

# Make the curl request and capture the HTTP status code.
# The backend Lambda returns a proxy response of {"statusCode": 200, ...} with no
# body, so we assert on the HTTP status code rather than the (empty) response body.
# A 403 here would mean the request authorizer denied the request.
status=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$httpapi.execute-api.localhost.localstack.cloud:4566/example/test" -H 'Authorization: secretToken')

# Output the status for debugging purposes
echo "API Response status: $status"

# Smoke test to validate the output
if [ "$status" = "200" ]; then
    echo "Smoke test passed: The response status code is 200."
else
    echo "Smoke test failed: The response status code is '$status', not 200."
    exit 1
fi
