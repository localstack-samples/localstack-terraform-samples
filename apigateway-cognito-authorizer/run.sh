#!/usr/bin/env sh

tflocal init; tflocal plan; tflocal apply --auto-approve

restapi=$(aws apigateway --endpoint-url=http://localhost:4566 get-rest-apis | jq -r .items[0].id)
curl $restapi.execute-api.localhost.localstack.cloud:4566/local/demo -H "Authorization: Bearer ey"

# aws cognito-idp describe-user-pool-client --user-pool-id <pool-id> --client-id <client-id>
#curl -X POST \                                                                                                        0 (18.486s) < 16:30:32
#      https://legal-lacewing.auth.eu-west-1.amazoncognito.com/oauth2/token \
#      -H 'authorization: Basic ***c2VndGc3dHRqbjVhZjFmMzU5aDM0N***' \
#      -H 'content-type: application/x-www-form-urlencoded' \
#      -d 'grant_type=client_credentials&scope=legal-lacewing/cancellation'
