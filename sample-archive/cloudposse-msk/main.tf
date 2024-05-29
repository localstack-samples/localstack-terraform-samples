module "vpc" {
  source  = "cloudposse/vpc/aws"
  version = "1.1.0"

  context = module.this.context

  ipv4_primary_cidr_block = "10.0.0.0/16"

  assign_generated_ipv6_cidr_block = true

}

module "subnets" {
  source  = "cloudposse/dynamic-subnets/aws"
  version = "2.0.2"

  context = module.this.context

  availability_zones = var.availability_zones
  vpc_id             = module.vpc.vpc_id
  igw_id             = [module.vpc.igw_id]
  ipv4_cidr_block    = [module.vpc.vpc_cidr_block]
}

module "kafka" {
  source  = "cloudposse/msk-apache-kafka-cluster/aws"
  version = "0.8.6"

  context = module.this.context

  vpc_id     = module.vpc.vpc_id
  zone_id    = var.zone_id
  subnet_ids = module.subnets.private_subnet_ids

  kafka_version          = "2.4.1"
  number_of_broker_nodes = 2 # this has to be a multiple of the # of subnet_ids
  broker_instance_type   = "kafka.m5.large"

  # security groups to put on the cluster itself
  associated_security_group_ids = [module.vpc.vpc_default_security_group_id]
  # security groups to give access to the cluster
  allowed_security_group_ids = [module.vpc.vpc_default_security_group_id]
}
