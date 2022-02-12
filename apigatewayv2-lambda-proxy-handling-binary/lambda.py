# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.

# Permission is hereby granted, free of charge, to any person obtaining a copy of this
# software and associated documentation files (the "Software"), to deal in the Software
# without restriction, including without limitation the rights to use, copy, modify,
# merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
# PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
# HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

from base64 import b64encode


def handler(event, context):
    print(JSON.stringify(event, null, 2))
    # For demo purposes only - define whether plain text response in base64 encoded
    demo64Flag = int(event.get("queryStringParameters", {}).get("demo64Flag", 0))

    # Define desired output formate from accept header, default to JPEG
    accept = event.get("headers", {}).get("accept", "image/jpeg")

    # Get the RESTful VERB
    verb = event.get("requestContext", {}).get("http", {}).get("method", "GET").split()[0]

    # Return failure message as unencoded string to API-GW
    if demo64Flag == 0:
        return_string = "Text path: Unknown encoding requested"
        return_encode = False
        # Return failure message as unencoded string to API-GW
    else:
        return_string = b64encode(("Binary path: Unknown encoding requested").encode('utf-8'))
        return_encode = True

    return {
        'statusCode': 200,
        # Return the mime type of the response
        'headers': {
            'Content-Type': 'text/plain'
        },
        # Return message, might be Base64 encoded
        'body': event["body"],
        # Tell API-GW whether it's Base64 encoded.
        'isBase64Encoded': event["isBase64Encoded"]
    }
