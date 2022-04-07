#!/usr/bin/env sh

terraform init; terraform plan; terraform apply --auto-approve

echo "Copying file into bucket"
aws --endpoint-url http://localhost:4566 \
	s3 cp some-log-file.log s3://your-bucket-name/

sleep 1

echo "SQS notification record:"
aws --endpoint-url http://localhost:4566 \
	sqs receive-message \
	--queue-url http://localhost:4566/000000000000/s3-event-notification-queue \
 | jq -r '.Messages[0].Body' | jq .
