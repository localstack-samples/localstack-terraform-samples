## Run Terraform

`terraform init; terraform plan; terraform apply --auto-approve`

## Create Cognito users

Using the outputs run the following commands,

```
 awslocal cognito-idp sign-up \
      --client-id <user_pool_client_id> \
      --username "user@domain.com" \
      --password "Ppassword123!" \
      --secret-hash <secret_hash>
```

then,

```
awslocal cognito-idp admin-confirm-sign-up \
      --user-pool-id <user_pool_id> \
      --username "user@domain.com"
```

then,

```
curl -X POST \                                                                                                                                     0 (0.477s) < 23:51:26
                      https://united-fly.auth.eu-west-1.amazoncognito.com/oauth2/token \
                      --user '<client_id>:<client_secret>' \
                      -H 'content-type: application/x-www-form-urlencoded' \
                      -d 'grant_type=client_credentials&scope=<scope-name>%2Flocalstack'
```
