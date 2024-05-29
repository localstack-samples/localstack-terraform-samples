import os
import json

import boto3

def handler(event, context):
    print(event)

    # FIXME: here i'm assuming that localstack runs on the host and there's a docker network
    sqs = boto3.client("sqs", endpoint_url=os.getenv("BOTO_ENDPOINT_URL"))

    queue_url = os.environ['LAMBDA_RESULT_QUEUE']
    print("sending s3 message to", queue_url)
    sqs.send_message(QueueUrl=queue_url, MessageBody=json.dumps({"status":"ok", "raw_event": event}))

    return {"status": "ok"}
