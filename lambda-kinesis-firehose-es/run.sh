#!/usr/bin/env bash
# fail on errors
set -eo pipefail

# Get the function URL
function_url=$(awslocal lambda get-function-url-config --function-name demolambda | jq -r .FunctionUrl)

# Get the Elasticsearch endpoint
elasticsearch_endpoint=$(awslocal es describe-elasticsearch-domain --domain-name demo-domain | jq -r .DomainStatus.Endpoint)

# Output the endpoints for debugging purposes
echo "Elasticsearch Endpoint: $elasticsearch_endpoint"
echo "Function URL: $function_url"

# Invoke the function and capture the response
echo "Invoking function..."
response=$(curl -s $function_url)

# Output the response for debugging purposes
echo "Function Response: $response"

# Smoke test to validate the output
if echo "$response" | grep -q "Hello World!"; then
    echo "Smoke test passed: The response contains 'Hello World!'."
else
    echo "Smoke test failed: The response does not contain 'Hello World!'."
    exit 1
fi
