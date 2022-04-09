output "endpoint" {
  value = "https://${aws_apigatewayv2_api.poc-hello-rest-api.api_endpoint}/${aws_apigatewayv2_stage.poc-hello-gateway-stage.name}"
}
