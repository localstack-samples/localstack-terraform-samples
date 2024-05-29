#!/usr/bin/env sh

terraform init; terraform plan; terraform apply --auto-approve


serverid=$(aws --endpoint-url=http://localhost:4566 transfer list-servers | grep "ServerId" | sed 's/"ServerId"\://' | cut -d ',' -f1)
aws --endpoint-url=http://localhost:4566 transfer test-identity-provider --server-id $serverid --user-name user1 --user-password Password1
