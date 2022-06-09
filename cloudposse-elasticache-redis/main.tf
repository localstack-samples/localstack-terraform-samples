module "vpc" {
  source = "cloudposse/vpc/aws"
  version = "1.1.0"
  
  context = module.this.context

  ipv4_primary_cidr_block = "10.0.0.0/16"

  assign_generated_ipv6_cidr_block = true
}

module "subnets" {
  source = "cloudposse/dynamic-subnets/aws"
  version = "2.0.2"

  context = module.this.context

  vpc_id             = module.vpc.vpc_id
  igw_id             = [module.vpc.igw_id]
  ipv4_cidr_block    = [module.vpc.vpc_cidr_block]
}

# Create a zone in order to validate fix for https://github.com/cloudposse/terraform-aws-elasticache-redis/issues/82
resource "aws_route53_zone" "private" {
  name = format("elasticache-redis-terratest-%s.testing.cloudposse.co", try(module.this.attributes[0], "default"))

  vpc {
    vpc_id = module.vpc.vpc_id
  }
}

module "redis" {
  source                  = "cloudposse/elasticache-redis/aws"
  version                 = "0.43.0"
  context                 = module.this.context

  namespace               = "ls"
  stage                   = "demo"
  name                    = "redis"
  environment             = "local"

  vpc_id                  = module.vpc.vpc_id
  zone_id                 = [aws_route53_zone.private.id]
  subnets                 = module.subnets.private_subnet_ids

  engine_version          = "4.0.10"

  parameter = [
    {
      name  = "notify-keyspace-events"
      value = "lK"
    }
  ]

  allowed_security_groups = [module.vpc.vpc_default_security_group_id]
  associated_security_group_ids = [module.vpc.vpc_default_security_group_id]
}
