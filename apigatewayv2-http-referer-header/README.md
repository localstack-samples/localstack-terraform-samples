# Hello, World API Gateway Example

## Setup

1. Clone this repo and `cd` into its working directory
2. Install [Terraform](https://www.terraform.io/downloads) (v1.1.0 or higher)
3. Start LocalStack in the foreground so you can watch the logs:
   ```
   docker compose up
   ```
4. Open another terminal window and `cd` into the same working directory
5. Create the API Gateway HTTP API and all of its dependencies in LocalStack:
   ```
   terraform apply -auto-approve
   ```

## Testing the Gateway

This API defines one resource with two different verbs:

- `GET /hello/{name}`
- `POST /hello/{name}`

Both routes do the exact same thing: Return a JSON object of the form
```
{
  "message": "Hello, {name}",
  "event": { ...exact copy of the API Gateway event message... }
}
```

1. Get the LocalStack API Gateway endpoint for the API:
   ```
   $ awslocal apigatewayv2 get-apis
   {
       "Items": [
           {
               "ApiEndpoint": "d0de6d83.execute-api.localhost.localstack.cloud:4566",
               "ApiId": "4c9f379b",
               "ApiKeySelectionExpression": "$request.header.x-api-key",
               "Description": "",
               "Name": "poc-hello-rest-api",
               "ProtocolType": "HTTP",
               "RouteSelectionExpression": "$request.method $request.path",
               "Tags": {},
               "Version": ""
           }
       ]
   }
   ```
2. Invoke the API in each of the following ways (replacing the hostname with the `ApiEndpoint` from above):
   ```
   curl -vs -X GET https://d0de6d83.execute-api.localhost.localstack.cloud:4566/dev/hello/API
   curl -vs -X GET --referer https://my.site.example.com/ https://d0de6d83.execute-api.localhost.localstack.cloud:4566/dev/hello/API
   curl -vs -X POST https://d0de6d83.execute-api.localhost.localstack.cloud:4566/dev/hello/API
   curl -vs -X POST --referer https://localhost.localstack.cloud/ https://d0de6d83.execute-api.localhost.localstack.cloud:4566/dev/hello/API
   curl -vs -X POST --referer https://my.site.example.com/ https://d0de6d83.execute-api.localhost.localstack.cloud:4566/dev/hello/API
   ```

The first 4 invocations will succeed and return the expected results. The last will fail with a status of 403. If you look at the LocalStack log at that point, you'll see the error:
```
INFO:localstack.services.generic_proxy: Blocked CORS request from forbidden origin https://my.site.example.com/
```

It appears that LocalStack is blocking any `POST` request with a `Referer` header unless the referer starts with `https://localhost.localstack.cloud`


@credits to https://github.com/mbklein