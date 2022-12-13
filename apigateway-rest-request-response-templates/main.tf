resource "random_pet" "random" {
  length = 2
}

resource "aws_iam_role" "apigw-role" {
  name               = "api_gateway_invocation"
  assume_role_policy = <<-EOF
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Sid": "",
          "Effect": "Allow",
          "Principal": {
            "Service": "apigateway.amazonaws.com"
          },
          "Action": "sts:AssumeRole"
        }
      ]
    }
  EOF
}

resource "aws_iam_role_policy" "invocation_policy" {
  name = "default"
  role = aws_iam_role.apigw-role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "lambda:InvokeFunction",
      "Effect": "Allow",
      "Resource": "${aws_lambda_function.lambda.arn}"
    }
  ]
}
EOF
}

resource "aws_api_gateway_rest_api" "api" {
  name = random_pet.random.id
  body = jsonencode({
    openapi = "3.0.1"
    info = {
      "title"   = random_pet.random.id
      "version" = "1.0.0"
    },
    paths = {
      "/products/{productId}/items" = {
        post = {
          parameters = [
            {
              name     = "productId"
              in       = "path"
              required = true
              schema = {
                type = "string"
              }
            }
          ]
          requestBody = {
            required = true
            content = {
              "application/json" = {
                schema = {
                  "$ref" = "#/components/schemas/TransactionRequest"
                }
              }
            }
          }
          responses = {
            "200" = {
              description = "Ok"
              content = {
                "application/json" = {
                  schema = {
                    "$ref" = "#/components/schemas/TransactionResponse"
                  }
                }
              }
            }
            "202" : {
              description = "Accepted, but some fields were dropped due to invalid inputs. Errors can be found on response message tag, beginning with \"The following fields have been dropped\"."
              content = {
                "application/json" = {
                  schema = {
                    "$ref" = "#/components/schemas/TransactionResponse"
                  }
                }
              }
            }
            "400" : {
              description = "Bad Request"
              content = {
                "application/json" = {
                  schema = {
                    "$ref" = "#/components/schemas/Error"
                  }
                }
              }
            }
          }
          "x-amazon-apigateway-integration" = {
            "uri"        = aws_lambda_function.lambda.invoke_arn
            "httpMethod" = "POST"
            "type"       = "aws"
            "requestTemplates" = {
              "application/json" = <<EOF
#set($allParams = $input.params())
#set($jsonBody = $input.json('$'))
#set($path = $allParams.get('path'))
#set($querystring = $allParams.get('querystring'))
#set($header = $allParams.get('header'))
#set($stage = $context.stage)
{
    "apiContext": {
        "apiId": "$context.apiId",
        "method": "$context.httpMethod",
        "sourceIp": "$context.identity.sourceIp",
        "userAgent": "$context.identity.userAgent",
        "path": "$context.path",
        "protocol": "$context.protocol",
        "requestId": "$context.requestId",
        "stage": "$stage"
    },
    "path": {
        "parameterMap": {
            #foreach($paramName in $path.keySet())
            "$paramName": "$util.escapeJavaScript($path.get($paramName))"#if($foreach.hasNext),#end
            #end
        }
    },
    "querystring": {
        "parameterMap":{
            #foreach($paramName in $querystring.keySet())
            "$paramName": "$util.escapeJavaScript($querystring.get($paramName))"#if($foreach.hasNext),#end
            #end
        }
    },
    "header": {
        "parameterMap": {
            #foreach($paramName in $header.keySet())
            "$paramName": "$util.escapeJavaScript($header.get($paramName))"#if($foreach.hasNext),#end
            #end
        }
    },
    "body": $jsonBody
}
EOF
            }
            "responses" = {
              "default" = {
                "statusCode" = "200"
                "responseTemplates" = {
                  "application/json" = <<EOF
#set($responseBody = $input.json('$.responseBody'))
#set($errorMessage = $input.path('$.errorMessage'))
#set($errorType = $input.path('$.errorType'))
#set($headers = $input.path('$.headers'))
#set($stage = $context.stage)
#foreach($headerName in $headers.keySet())
    #set($context.responseOverride.header["$headerName"] = "$headers.get($headerName)")#if($foreach.hasNext),#end
#end
#if($errorMessage && !$errorMessage.empty)
{
    "mapping_template": true,
    #if($responseBody && !$responseBody.empty && $responseBody != '""' && $responseBody != '{}')
    "response": $responseBody,
    #end
    #if($errorType && !$errorType.empty)
    "type": "$errorType",
    #end
    #if($errorMessage.startsWith('{'))
        #set ($errorMessageObj = $util.parseJson($errorMessage))
        #if($errorMessageObj.httpStatus && $errorMessageObj.errorMessage)
            #set($context.responseOverride.status = $errorMessageObj.httpStatus)
            "message": "$errorMessageObj.errorMessage"
        #else
            "message": $errorMessage
        #end
    #else
        "message": "$errorMessage"
    #end
}
#else
    #set($context.responseOverride.status = $input.path('$.statusCode'))
    $responseBody
#end
EOF
                }
              }
              ".*httpStatus\\\":400.*" = {
                "statusCode" = "400"
                responseTemplates = {
                  "application/json" = "#set($errorMessage = $input.path('$.errorMessage'))\n $errorMessage"
                }
              }
            }
          }
        }
        get = {
          parameters = [
            {
              name     = "productId"
              in       = "path"
              required = true
              schema = {
                type = "string"
              }
            },
            {
              "in"   = "query",
              "name" = "limit",
              "schema" = {
                "type" = "integer"
              },
              "required" = false
            },
            {
              "in"   = "query",
              "name" = "startingAfter",
              "schema" = {
                "type" = "string"
              },
              "required" = false
            },
            {
              "in"   = "query",
              "name" = "endingBefore",
              "schema" = {
                "type" = "string"
              },
              "required" = false
            },
            {
              "in"   = "query",
              "name" = "status",
              "schema" = {
                "type" = "string"
              },
              "required" = false
            }
          ]
          responses = {
            "200" = {
              description = "Ok"
              content = {
                "application/json" = {
                  schema = {
                    "$ref" = "#/components/schemas/TransactionResponse"
                  }
                }
              }
            }
            "400" : {
              description = "Bad Request"
              content = {
                "application/json" = {
                  schema = {
                    "$ref" = "#/components/schemas/Error"
                  }
                }
              }
            }
          }
          "x-amazon-apigateway-integration" = {
            "uri"         = aws_lambda_function.lambda.invoke_arn
            "credentials" = aws_iam_role.apigw-role.arn
            "httpMethod"  = "POST"
            "type"        = "aws"
            "requestTemplates" = {
              "application/json" = replace(replace(file("./request-template.vm"), "\n", ""), "\"", "\\\"")
            }
            "responses" = {
              "default" = {
                "statusCode" = "200"
                "responseTemplates" = {
                  "application/json" = replace(replace(file("./response-template.vm"), "\n", ""), "\"", "\\\"")
                }
              }
              ".*httpStatus\\\":400.*" = {
                "statusCode" = "400"
                responseTemplates = {
                  "application/json" = "#set($errorMessage = $input.path('$.errorMessage'))\n $errorMessage"
                }
              }
            }
          }
        }
      }
    }
    components = {
      headers = {
        "accessControl" = {
          content = {
            "application/json" = {
              schema = {
                "type" = "string"
              }
            }
          }
        }
      }
      schemas = {
        "Error" = {
          "type" = "object"
        }
        "TransactionRequest" = {
          "type" = "object"
        }
        "TransactionResponse" = {
          "type" = "object"
        }
        "TransactionsResponse" = {
          "type" = "array"
        }
      }
    }
  })
}

resource "aws_lambda_permission" "lambda_permission" {
  statement_id  = "AllowAPIInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "apigateway.amazonaws.com"

  # The /*/*/* part allows invocation from any stage, method and resource path
  # within API Gateway REST API.
  source_arn = "${aws_api_gateway_rest_api.api.execution_arn}/*/*/*"
}

resource "aws_api_gateway_deployment" "deployment" {
  rest_api_id = aws_api_gateway_rest_api.api.id

  triggers = {
    redeployment = sha1(jsonencode(aws_api_gateway_rest_api.api.body))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "stage" {
  deployment_id = aws_api_gateway_deployment.deployment.id
  rest_api_id   = aws_api_gateway_rest_api.api.id
  stage_name    = "dev"

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.apigateway.arn
    format = jsonencode({
      "requestId" : "$context.requestId",
      "trueRequestId" : "$context.extendedRequestId",
      "sourceIp" : "$context.identity.sourceIp",
      "requestTime" : "$context.requestTime",
      "httpMethod" : "$context.httpMethod",
      "resourcePath" : "$context.resourcePath",
      "status" : "$context.status",
      "protocol" : "$context.protocol",
      "responseLength" : "$context.responseLength",
      "responseLatency" : "$context.responseLatency",
      "integrationLatency" : "$context.integration.latency",
      "validationError" : "$context.error.validationErrorString",
      "userAgent" : "$context.identity.userAgent",
      "path" : "$context.path"
    })
  }
}

resource "aws_iam_role" "lambda-role" {
  name               = random_pet.random.id
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "lambda_policy_auth" {
  role       = aws_iam_role.lambda-role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "lambda" {
  filename      = "lambda.zip"
  function_name = random_pet.random.id
  role          = aws_iam_role.lambda-role.arn
  handler       = "lambda.handler"

  source_code_hash = filebase64sha256("lambda.zip")

  runtime = "python3.8"
}

resource "aws_cloudwatch_log_group" "apigateway" {
  name              = "/aws/apigateway/${aws_api_gateway_rest_api.api.name}"
  retention_in_days = 3
}
