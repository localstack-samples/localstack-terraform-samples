variable "root_domain_name" {
  type    = string
  default = "helloworld.info"
}

resource "aws_route53_zone" "hello_world_zone" {
  name = var.root_domain_name
}

resource "aws_acm_certificate" "hello_certificate" {
  domain_name       = var.root_domain_name
  validation_method = "DNS"
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "hello_cert_dns" {
  allow_overwrite = true
  name            = tolist(aws_acm_certificate.hello_certificate.domain_validation_options)[0].resource_record_name
  records         = [tolist(aws_acm_certificate.hello_certificate.domain_validation_options)[0].resource_record_value]
  type            = tolist(aws_acm_certificate.hello_certificate.domain_validation_options)[0].resource_record_type
  zone_id         = aws_route53_zone.hello_world_zone.zone_id
  ttl             = 60
}

resource "aws_acm_certificate_validation" "hello_cert_validate" {
  certificate_arn         = aws_acm_certificate.hello_certificate.arn
  validation_record_fqdns = [aws_route53_record.hello_cert_dns.fqdn]
}


resource "aws_apigatewayv2_domain_name" "mydomain" {
  domain_name = var.root_domain_name
  domain_name_configuration {
    certificate_arn = aws_acm_certificate.hello_certificate.arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }
}
