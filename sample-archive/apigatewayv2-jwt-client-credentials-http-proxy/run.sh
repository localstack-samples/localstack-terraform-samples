#!/usr/bin/env sh

rm -rf terraform.tfstate* || true

tflocal init; tflocal plan; tflocal apply --auto-approve

secret_token=$(terraform output -raw secret_token)
user_pool_client_id=$(terraform output -raw user_pool_client_id)
user_pool_id=$(terraform output -raw user_pool_id)
secret_hash=$(python secret_hash.py)

aws --endpoint-url=http://localhost:4566 cognito-idp sign-up --client-id $user_pool_client_id  --username "user@domain.com" --password "Ppassword123!" --secret-hash $secret_hash

aws --endpoint-url=http://localhost:4566 cognito-idp admin-confirm-sign-up --user-pool-id $user_pool_id --username "user@domain.com"

name=$(aws --endpoint-url=http://localhost:4566 cognito-idp describe-user-pool --user-pool-id $user_pool_id | jq -r .UserPool.Name)

access_token=$(curl -X POST http://localhost:4566/oauth2/token --user $user_pool_client_id:$secret_token -H "content-type: application/x-www-form-urlencoded" -d "grant_type=client_credentials&scope=$name%2Flocalstack" | jq -r .access_token)

echo "Access Token $access_token"

httpapi=$(aws --endpoint-url=http://localhost:4566 apigatewayv2 get-apis | jq -r .Items[0].ApiId)

curl -vvv -X POST "$httpapi.execute-api.localhost.localstack.cloud:4566/dev/users/user" -H "Authorization: Bearer $access_token"
