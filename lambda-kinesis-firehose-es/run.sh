#!/usr/bin/env bash
# fail on errors
set -eo pipefail
# enable alias in script
shopt -s expand_aliases

if [ $# -eq 1 ] && [ $1 = "aws" ]; then
  echo "Deploying on AWS."
else
  echo "Deploying on LocalStack."
  alias aws='awslocal'
  alias terraform='tflocal'
fi

terraform init; terraform plan; terraform apply --auto-approve
function_url=$(aws lambda get-function-url-config --function-name demolambda --region eu-west-1 | jq -r .FunctionUrl)
elasticsearch_endpoint=$(aws es describe-elasticsearch-domain --domain-name demo-domain --region eu-west-1 | jq -r .DomainStatus.Endpoint)
echo "Elasticsearch Endpoint: $elasticsearch_endpoint"
echo "Function URL: $function_url"
echo "Invoking function..."
curl $function_url
