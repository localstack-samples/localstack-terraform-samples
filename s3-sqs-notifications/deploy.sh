#!/usr/bin/env sh

terraform init; terraform plan; terraform apply --auto-approve

echo "Copying file into bucket"
aws s3 cp some-log-file.log s3://your-bucket-name/  --endpoint-url http://localhost:4566

sleep 1

echo "SQS notification record:"
aws  sqs receive-message --queue-url http://localhost:4566/000000000000/s3-event-notification-queue --endpoint-url http://localhost:4566  |  jq -r '.Messages[0].Body' |  jq .
