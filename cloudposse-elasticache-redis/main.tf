module "vpc" {
  source = "cloudposse/vpc/aws"
  version = "1.1.0"
  
  context = module.this.context

  ipv4_primary_cidr_block = "10.0.0.0/16"

  assign_generated_ipv6_cidr_block = true

}

module "redis" {
  source                  = "cloudposse/elasticache-redis/aws"
  version                 = "0.43.0"
  context                 = module.this.context

  vpc_id                  = module.vpc.vpc_id
  allowed_security_groups = [module.vpc.vpc_default_security_group_id]
  associated_security_group_ids = [module.vpc.vpc_default_security_group_id]

  namespace               = var.namespace
  stage                   = var.stage
  name                    = var.name
  family                  = var.family
  engine_version          = var.engine_version

  parameter = [
    {
      name  = "notify-keyspace-events"
      value = "lK"
    }
  ]

}
