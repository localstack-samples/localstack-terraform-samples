resource "random_pet" "random" {
  length = 2
}

resource "aws_api_gateway_rest_api" "api" {
  name        = random_pet.random.id
  description = "route53 failover api"
}

resource "aws_api_gateway_resource" "hello" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "hello"
}

resource "aws_api_gateway_method" "hello_get" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.hello.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_resource" "health" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "health"
}

resource "aws_api_gateway_method" "health_get" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.health.id
  http_method   = "GET"
  authorization = "NONE"
}

#
# Integration
#
resource "aws_iam_role" "role" {
  name = random_pet.random.id

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

resource "aws_lambda_permission" "hello_lambda" {
  statement_id  = "AllowExecutionFromAPIGatewayToHello"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.hello_lambda.function_name
  principal     = "apigateway.amazonaws.com"

  # More: http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-control-access-using-iam-policies-to-invoke-api.html
  source_arn = "${aws_api_gateway_rest_api.api.execution_arn}/*/*/*"
}

resource "aws_lambda_permission" "health_lambda" {
  statement_id  = "AllowExecutionFromAPIGatewayToHealth"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.health_lambda.function_name
  principal     = "apigateway.amazonaws.com"

  # More: http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-control-access-using-iam-policies-to-invoke-api.html
  source_arn = "${aws_api_gateway_rest_api.api.execution_arn}/*/*/*"
}


resource "aws_lambda_function" "hello_lambda" {
  filename      = "hello.zip"
  function_name = "hello-${random_pet.random.id}"
  role          = aws_iam_role.role.arn
  handler       = "hello.handler"

  source_code_hash = filebase64sha256("hello.zip")

  runtime = "nodejs16.x"
}

resource "aws_api_gateway_integration" "hello_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.hello.id
  http_method             = aws_api_gateway_method.hello_get.http_method
  integration_http_method = "POST"
  type                    = "AWS"
  uri                     = aws_lambda_function.hello_lambda.invoke_arn
}

resource "aws_lambda_function" "health_lambda" {
  filename      = "health.zip"
  function_name = "health-${random_pet.random.id}"
  role          = aws_iam_role.role.arn
  handler       = "health.handler"

  source_code_hash = filebase64sha256("health.zip")

  runtime = "nodejs16.x"
}

resource "aws_api_gateway_integration" "health_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.health.id
  http_method             = aws_api_gateway_method.health_get.http_method
  integration_http_method = "POST"
  type                    = "AWS"
  uri                     = aws_lambda_function.health_lambda.invoke_arn
}

resource "aws_api_gateway_method_response" "health_200" {
  http_method = aws_api_gateway_method.health_get.http_method
  resource_id = aws_api_gateway_resource.health.id
  rest_api_id = aws_api_gateway_rest_api.api.id
  status_code = 200
}

resource "aws_api_gateway_integration_response" "hello_200_response" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.hello.id
  http_method = aws_api_gateway_method.hello_get.http_method
  status_code = aws_api_gateway_method_response.hello_200.status_code

  depends_on = [aws_api_gateway_integration.hello_integration]
}

resource "aws_api_gateway_integration_response" "health_200_response" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.health.id
  http_method = aws_api_gateway_method.health_get.http_method
  status_code = aws_api_gateway_method_response.health_200.status_code

  depends_on = [aws_api_gateway_integration.health_integration]
}


resource "aws_api_gateway_method_response" "hello_200" {
  http_method = aws_api_gateway_method.hello_get.http_method
  resource_id = aws_api_gateway_resource.hello.id
  rest_api_id = aws_api_gateway_rest_api.api.id
  status_code = 200
}



resource "aws_api_gateway_deployment" "deployment" {
  rest_api_id = aws_api_gateway_rest_api.api.id

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_method.hello_get,
    aws_api_gateway_integration.hello_integration,
    aws_api_gateway_method.health_get,
    aws_api_gateway_integration.health_integration
  ]
}

resource "aws_api_gateway_stage" "stage" {
  deployment_id = aws_api_gateway_deployment.deployment.id
  rest_api_id   = aws_api_gateway_rest_api.api.id
  stage_name    = "dev"


  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.apigateway.arn
    format = jsonencode({
      "requestId" : "$context.requestId",
      "ip" : "$context.identity.sourceIp",
      "caller" : "$context.identity.caller",
      "user" : "$context.identity.user",
      "requestTime" : "$context.requestTime",
      "httpMethod" : "$context.httpMethod",
      "resourcePath" : "$context.resourcePath",
      "status" : "$context.status",
      "protocol" : "$context.protocol",
      "responseLength" : "$context.responseLength"
    })
  }

  depends_on = [aws_api_gateway_method.health_get, aws_api_gateway_method.hello_get]
}

resource "aws_acm_certificate" "cert" {
  domain_name       = "failover.localstack-test.cloud"
  validation_method = "DNS"
}

resource "aws_route53_zone" "dns_zone" {
  name = "localstack-test.cloud"
}

resource "aws_route53_record" "example" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = aws_route53_zone.dns_zone.id
}

resource "aws_acm_certificate_validation" "example" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.example : record.fqdn]
}

resource "aws_api_gateway_domain_name" "domain_name" {
  certificate_private_key   = aws_acm_certificate.cert.private_key
  domain_name               = "failover.localstack-test.cloud"
  regional_certificate_name = "failover-cert"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_route53_record" "record" {
  name    = aws_api_gateway_domain_name.domain_name.domain_name
  type    = "A"
  zone_id = aws_route53_zone.dns_zone.id

  alias {
    evaluate_target_health = false
    name                   = aws_api_gateway_domain_name.domain_name.regional_domain_name
    zone_id                = aws_api_gateway_domain_name.domain_name.regional_zone_id
  }
}

resource "aws_api_gateway_base_path_mapping" "example" {
  api_id      = aws_api_gateway_rest_api.api.id
  domain_name = aws_api_gateway_domain_name.domain_name.domain_name
  stage_name  = aws_api_gateway_stage.stage.stage_name
  base_path   = aws_api_gateway_stage.stage.stage_name
}

resource "aws_cloudwatch_log_group" "apigateway" {
  name              = "/aws/apigateway/${aws_api_gateway_rest_api.api.name}"
  retention_in_days = 3
}

#
# Outputs
#
output "rest_api_id" {
  value = aws_api_gateway_rest_api.api.id
}

output "regional_domain_name" {
  value = aws_api_gateway_domain_name.domain_name.regional_domain_name
}

output "distribution_domain_name" {
  value = aws_api_gateway_domain_name.domain_name.domain_name
}
