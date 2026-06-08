#!/usr/bin/env sh

# Get the API Gateway ID
restapi=$(lstk aws apigateway get-rest-apis | jq -r .items[0].id)

# Make the curl request and capture the response
response=$(curl -s -X POST "$restapi.execute-api.localhost.localstack.cloud:4566/dev/test" -H 'content-type: application/json' -d '{ "input": "{}", "name": "MyExecution"}')

# Output the response for debugging purposes
echo "API Response: $response"

# Extract the execution ARN from the response
execution_arn=$(echo "$response" | jq -r .executionArn)

# Check if the execution ARN was extracted successfully
if [ -z "$execution_arn" ] || [ "$execution_arn" = "null" ]; then
    echo "Smoke test failed: Execution ARN not found in the response."
    exit 1
fi

# Poll the execution status until it leaves the RUNNING state (up to ~30s)
status="RUNNING"
for _ in $(seq 1 15); do
    execution_response=$(lstk aws stepfunctions describe-execution --execution-arn "$execution_arn")
    status=$(echo "$execution_response" | jq -r .status)
    [ "$status" = "RUNNING" ] || break
    sleep 2
done

# Output the execution response for debugging purposes
echo "Execution Response: $execution_response"

# Smoke test to validate the status
if [ "$status" = "SUCCEEDED" ]; then
    echo "Smoke test passed: The execution status is 'SUCCEEDED'."
else
    echo "Smoke test failed: The execution status is '$status'."
    exit 1
fi
