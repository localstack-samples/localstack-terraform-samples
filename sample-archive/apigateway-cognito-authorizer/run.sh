#!/usr/bin/env sh

set -x

lstk tf init; lstk tf plan; lstk tf apply --auto-approve

client_id=$(lstk tf output -json | jq -r .user_pool_client_id.value)
pool_id=$(lstk tf output -json | jq -r .user_pool_id.value)

sleep 5

secret=$(lstk aws cognito-idp --endpoint-url=http://localhost:4566 describe-user-pool-client --user-pool-id $pool_id --client-id $client_id | jq -r .UserPoolClient.ClientSecret)
hash=$(python secret_hash.py test@localstack.com $client_id $secret)

access_token=$(lstk aws cognito-idp initiate-auth --auth-flow USER_PASSWORD_AUTH --client-id $client_id --auth-parameters USERNAME="test@localstack.com",PASSWORD="L0c4lst4ck!",SECRET_HASH=$hash | jq -r .AuthenticationResult.AccessToken)

restapi=$(lstk aws apigateway --endpoint-url=http://localhost:4566 get-rest-apis | jq -r .items[0].id)
curl $restapi.execute-api.localhost.localstack.cloud:4566/local/demo -H "X-Auth-Token: Bearer $access_token"
