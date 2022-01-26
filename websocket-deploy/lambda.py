import re

def lambda_handler(event, context):
    print(f'event: {event}')
    print(f'context: {context}')
    return {"statusCode": 200}
