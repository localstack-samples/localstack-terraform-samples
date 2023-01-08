#!/usr/bin/env sh

set -x

tflocal init; tflocal plan; tflocal apply --auto-approve

client_id=$(tflocal output -json | jq -r .user_pool_client_id.value)
pool_id=$(tflocal output -json | jq -r .user_pool_id.value)
secret=$(aws cognito-idp --endpoint-url=http://localhost:4566 describe-user-pool-client --user-pool-id $pool_id --client-id $client_id | jq -r .UserPoolClient.ClientSecret)
client_name=$(aws cognito-idp --endpoint-url=http://localhost:4566 describe-user-pool-client --user-pool-id $pool_id --client-id $client_id | jq -r .UserPoolClient.ClientName)

access_token=$(curl http://localhost:4566/oauth2/token \
									-u "$client_id:$secret" \
                  -H 'content-type: application/x-www-form-urlencoded' \
                  -d "grant_type=client_credentials&scope=$client_name/cancellation" | jq -r .access_token)

restapi=$(aws apigateway --endpoint-url=http://localhost:4566 get-rest-apis | jq -r .items[0].id)
curl $restapi.execute-api.localhost.localstack.cloud:4566/local/demo -H "X-Auth-Token: Bearer $access_token"
