#!/usr/bin/env sh

echo "Preparing lambda deployment"
zip lambda.zip lambda.py

echo "Apply the Terrform configuration"
terraform init; terraform plan; terraform apply --auto-approve


echo "Publishing a message to the topic:"
aws --endpoint-url http://localhost:4566 \
	s3 cp some-log-file.log s3://your-bucket-name/

aws --endpoint-url http://localhost:4566 \
	sns publish \
	--topic arn:aws:sns:us-east-1:000000000000:trigger-event-topic \
	--message '{"event_type":"testing","event_payload":"hello world"}'

sleep 1

echo "Lambda result queue:"
aws --endpoint-url http://localhost:4566 \
	sqs receive-message --wait-time-seconds 10 --visibility-timeout=0 \
	--queue=http://localhost:4566/000000000000/lambda-result-queue \
 | jq -r ".Messages[0].Body" | jq .
