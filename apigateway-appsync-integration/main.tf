data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "random_pet" "random" {
  length = 2
}

resource "aws_api_gateway_rest_api" "api" {
  name        = random_pet.random.id
  description = "apigateway-appsync"
}

resource "aws_api_gateway_resource" "resource" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "graphql"
}

resource "aws_api_gateway_method" "method" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.resource.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.resource.id
  http_method             = aws_api_gateway_method.method.http_method
  credentials             = aws_iam_role.apigateway_appsync.arn
  type                    = "AWS"
  integration_http_method = "POST"
  uri                     = "arn:aws:apigateway:${data.aws_region.current.name}:appsync:action/${aws_appsync_graphql_api.api.id}/types/Query/fields/singlePost"

  # http headers
  request_parameters = {
    "integration.request.header.x-api-key" = "'${aws_appsync_api_key.apikey.key}'"
  }

  # request template for appsync single post query
  request_templates = {
    "application/json" = <<EOF
{
    "version": "2018-05-29",
    "method": "POST",
    "resourcePath": "/",
    "params":{
        "headers": {
            "x-api-key": "${aws_appsync_api_key.apikey.key}"
        },
        "querystring": $input.params().querystring,
        "body": $input.json('$')
    }
}
EOF
  }
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

resource "aws_api_gateway_stage" "example" {
  deployment_id = aws_api_gateway_deployment.deployment.id
  rest_api_id   = aws_api_gateway_rest_api.api.id
  stage_name    = "example"
}

resource "aws_api_gateway_method_response" "method_response" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.resource.id
  http_method = aws_api_gateway_method.method.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration_response" "integration_response" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.resource.id
  http_method = aws_api_gateway_method.method.http_method
  status_code = aws_api_gateway_method_response.method_response.status_code

  response_templates = {
    "application/json" = ""
  }
}

resource "aws_iam_role" "apigateway_appsync" {
  name = "apigateway_appsync"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "apigateway.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

# apigateway role policy to call appsync
resource "aws_iam_role_policy" "apigateway_appsync" {
  name = "apigateway_appsync"
  role = aws_iam_role.apigateway_appsync.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "appsync:GraphQL"
      ],
      "Effect": "Allow",
      "Resource": [
        "arn:aws:appsync:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:apis/${aws_appsync_graphql_api.api.id}/*"
      ]
    }
  ]
}
EOF
}

resource "aws_appsync_api_key" "apikey" {
  api_id = aws_appsync_graphql_api.api.id
}

resource "aws_appsync_graphql_api" "api" {
  name = random_pet.random.id

  authentication_type = "API_KEY"
  schema              = file("schema.graphql")
}

resource "aws_appsync_datasource" "datasource" {
  api_id           = aws_appsync_graphql_api.api.id
  name             = "dt_dynamo"
  service_role_arn = aws_iam_role.appsync_dynamo.arn
  type             = "AMAZON_DYNAMODB"

  dynamodb_config {
    table_name = aws_dynamodb_table.table.name
  }
}

resource "aws_appsync_resolver" "resolver" {
  api_id      = aws_appsync_graphql_api.api.id
  field       = "singlePost"
  type        = "Query"
  data_source = aws_appsync_datasource.datasource.name

  request_template = <<EOF
{
    "version" : "2017-02-28",
    "operation" : "GetItem",
    "key" : {
        "id" : $util.dynamodb.toDynamoDBJson($ctx.args.id)
    }
}
EOF

  response_template = <<EOF
#if($ctx.result.statusCode == 200)
    $ctx.result.body
#else
    $util.toJson($ctx.result)
#end
EOF

  caching_config {
    caching_keys = [
      "$context.identity.sub",
      "$context.arguments.id"
    ]
    ttl = 60
  }
}

resource "aws_dynamodb_table" "table" {
  name           = "appsync_dynamo"
  read_capacity  = 1
  write_capacity = 1
  hash_key       = "id"
  range_key      = "title"

  attribute {
    name = "id"
    type = "S"
  }

  attribute {
    name = "title"
    type = "S"
  }
}

resource "aws_iam_role" "appsync_dynamo" {
  name = "appsync_dynamo"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "appsync.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "example" {
  name = "example"
  role = aws_iam_role.appsync_dynamo.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "dynamodb:*"
      ],
      "Effect": "Allow",
      "Resource": [
        "${aws_dynamodb_table.table.arn}"
      ]
    }
  ]
}
EOF
}
