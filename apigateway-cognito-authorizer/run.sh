#!/usr/bin/env sh

set -x

tflocal init; tflocal plan; tflocal apply --auto-approve


# Generate secret

```python
python3 secret_hash.py <username> <app_client_id> <app_client_secret>
```

# Authentication flow

```
aws cognito-idp initiate-auth \                                                                                                      0 (1.077s) < 09:33:09
          --auth-flow USER_PASSWORD_AUTH \
          --client-id 6d0bu9s7mham2auv66e1u64k5m \
          --auth-parameters USERNAME="test@localstack.com",PASSWORD="L0c4lst4ck!",SECRET_HASH=<secret-hash>
```

restapi=$(aws apigateway --endpoint-url=http://localhost:4566 get-rest-apis | jq -r .items[0].id)
curl $restapi.execute-api.localhost.localstack.cloud:4566/local/demo -H "X-Auth-Token: Bearer $access_token"
