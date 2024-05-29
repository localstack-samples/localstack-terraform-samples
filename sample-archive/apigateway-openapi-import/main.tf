resource "aws_api_gateway_rest_api" "example" {
  body = jsonencode({
    "info" : {
      "title" : "myapi",
      "version" : "1.0"
    },
    "paths" : {
      "/b" : {
        "get" : {
          "security" : [
            {
              "myapi-authorizer-0" : []
            }
          ],
          "x-amazon-apigateway-integration" : {
            "httpMethod" : "POST",
            "passthroughBehavior" : "when_no_match",
            "type" : "aws_proxy",
            "uri" : "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:000000000000:function:myapi04e7e42c-96578b5/invocations"
          }
        }
      },
      "/c" : {
        "get" : {
          "security" : [
            {
              "myapi-authorizer-0" : []
            }
          ],
          "x-amazon-apigateway-integration" : {
            "httpMethod" : "POST",
            "passthroughBehavior" : "when_no_match",
            "type" : "aws_proxy",
            "uri" : "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:000000000000:function:myapi04e7e42c-96578b5/invocations"
          }
        }
      }
    },
    "securityDefinitions" : {
      "myapi-authorizer-0" : {
        "in" : "query",
        "name" : "auth",
        "type" : "apiKey",
        "x-amazon-apigateway-authorizer" : {
          "authorizerCredentials" : "arn:aws:iam::000000000000:role/myapi-authorizer-0-authorizer-role-3bd761a",
          "authorizerUri" : "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:000000000000:function:myapi-authorizer-0-22ad13b/invocations",
          "identitySource" : "method.request.querystring.auth",
          "type" : "request"
        },
        "x-amazon-apigateway-authtype" : "custom"
      }
    },
    "swagger" : "2.0",
    "x-amazon-apigateway-api-key-source" : "HEADER",
    "x-amazon-apigateway-binary-media-types" : [
      "*/*"
    ],
    "x-amazon-apigateway-gateway-responses" : {
      "ACCESS_DENIED" : {
        "responseTemplates" : {
          "application/json" : "{\"message\": \"404 Not found\" }"
        },
        "statusCode" : 404
      },
      "MISSING_AUTHENTICATION_TOKEN" : {
        "responseTemplates" : {
          "application/json" : "{\"message\": \"404 Not found\" }"
        },
        "statusCode" : 404
      }
    }
  })

  name = "example"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}
