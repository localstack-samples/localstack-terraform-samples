#!/usr/bin/env sh

# Get the API Gateway ID
httpapi=$(aws --endpoint-url=http://localhost:4566 apigatewayv2 get-apis | jq -r .Items[0].ApiId)

# Make the curl request and capture the response
response=$(curl -s "$httpapi.execute-api.localhost.localstack.cloud:4566/test" -H 'content-type: application/json' -d '{ "IsHelloWorldExample": "Yes" }')

# Output the response for debugging purposes
echo "API Response: $response"

# Extract the execution ARN from the response
execution_arn=$(echo "$response" | jq -r .executionArn)

# Check if the execution ARN was extracted successfully
if [ -z "$execution_arn" ]; then
    echo "Smoke test failed: Execution ARN not found in the response."
    exit 1
fi

# Sleep for a few seconds to allow the execution to complete
sleep 10

# Describe the execution and capture the response
execution_response=$(awslocal stepfunctions describe-execution --execution-arn "$execution_arn")

# Output the execution response for debugging purposes
echo "Execution Response: $execution_response"

# Smoke test to validate the output
if echo "$execution_response" | jq -e '.status == "SUCCEEDED"' > /dev/null; then
    echo "Smoke test passed: The execution status is 'SUCCEEDED'."
else
    echo "Smoke test failed: The execution status is not 'SUCCEEDED'."
    exit 1
fi
