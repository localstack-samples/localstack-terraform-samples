module "lambda_function" {
  source = "terraform-aws-modules/lambda/aws"

  function_name = "poc-function"
  description   = "POC lambda hello world"
  handler       = "app.lambdaHandler"
  runtime       = "nodejs14.x"

  source_path = [
    {
      path     = "${path.module}/poc_function"
      commands = ["npm install --only prod --no-bin-links --no-fund", ":zip"]
    }
  ]
}

data "template_file" "poc-hello-definition" {
  template = file("${path.module}/api_gateway_definition.yml")

  vars = {
    lambda_invocation_arn = module.lambda_function.lambda_function_invoke_arn
  }
}

resource "aws_apigatewayv2_api" "poc-hello-rest-api" {
  name          = "poc-hello-rest-api"
  protocol_type = "HTTP"
  body          = data.template_file.poc-hello-definition.rendered
}

resource "aws_apigatewayv2_deployment" "poc-hello-gateway-deployment" {
  api_id = aws_apigatewayv2_api.poc-hello-rest-api.id

  triggers = {
    redeployment = sha1(data.template_file.poc-hello-definition.rendered)
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_apigatewayv2_stage" "poc-hello-gateway-stage" {
  deployment_id = aws_apigatewayv2_deployment.poc-hello-gateway-deployment.id
  api_id        = aws_apigatewayv2_api.poc-hello-rest-api.id
  name          = "dev"
}
