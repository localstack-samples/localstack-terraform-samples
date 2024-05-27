#!/usr/bin/env sh

# Get the API Gateway ID
restapi=$(aws --endpoint-url=http://localhost:4566 apigateway get-rest-apis | jq -r .items[0].id)

# Make the curl request and capture the response
response=$(curl -s -X POST "$restapi.execute-api.localhost.localstack.cloud:4566/local/test" -H 'content-type: application/json' -d '{ "input": "{}", "name": "MyExecution"}')

# Output the response for debugging purposes
echo "API Response: $response"

# Extract the execution ARN from the response
execution_arn=$(echo "$response" | jq -r .executionArn)

# Check if the execution ARN was extracted successfully
if [ -z "$execution_arn" ]; then
    echo "Smoke test failed: Execution ARN not found in the response."
    exit 1
fi

# Wait for 5 seconds before checking the status
sleep 5

# Describe the execution and capture the response
execution_response=$(awslocal stepfunctions describe-execution --execution-arn "$execution_arn")

# Output the execution response for debugging purposes
echo "Execution Response: $execution_response"

# Smoke test to validate the status
if echo "$execution_response" | jq -e '.status == "SUCCEEDED"' > /dev/null; then
    echo "Smoke test passed: The execution status is 'SUCCEEDED'."
else
    echo "Smoke test failed: The execution status is not 'SUCCEEDED'."
    exit 1
fi
