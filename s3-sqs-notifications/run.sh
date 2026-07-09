#!/usr/bin/env sh

echo "Copying file into bucket"
lstk aws s3 cp some-log-file.log s3://your-bucket-name/

sleep 1

echo "SQS notification record:"
MESSAGE=$(lstk aws sqs receive-message --queue-url http://localhost:4566/000000000000/s3-event-notification-queue | jq -r '.Messages[0].Body')

validate_json() {
  echo "$1" | jq -e '
    .Service and
    .Event and
    .Time and
    .Bucket and
    .RequestId and
    .HostId and
    (.Service == "Amazon S3") and
    (.Event == "s3:TestEvent")
  ' > /dev/null
}

if validate_json "$MESSAGE"; then
  echo "Test passed: Received valid message."
else
  echo "Test failed: Message does not match expected structure or values."
  echo "Received: $MESSAGE"
  exit 1
fi
