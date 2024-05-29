#!/usr/bin/env sh

# Get the API Gateway ID
api_id=$(aws apigatewayv2 --endpoint-url=http://localhost:4566 get-apis | jq -r .Items[0].ApiId)

# Make the curl request and save the output to output.jpg
curl -s -X POST -H 'content-type: image/jpeg' --data-binary @./nyan-cat.jpg http://$api_id.execute-api.localhost.localstack.cloud:4566/example/test/foo/bar --output output.jpg

# Output for debugging purposes
echo "Curl command executed. Checking if output.jpg was created..."

# Smoke test to validate the output
if [ -f output.jpg ]; then
    echo "Smoke test passed: The file 'output.jpg' was created."
else
    echo "Smoke test failed: The file 'output.jpg' was not created."
    exit 1
fi
