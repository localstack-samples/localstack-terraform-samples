def handler(event, context):
    return {
        'statusCode': 202,
        'headers': {
            "X-Wisetack-Token": "Test-Wisetack-Token"
        },
        # Return message, might be Base64 encoded
        'body': event["body"],
    }
