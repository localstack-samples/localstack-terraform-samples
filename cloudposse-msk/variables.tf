variable "availability_zones" {
  type        = list(string)
  description = "List of availability zones for VPC creation"
}

variable "zone_id" {
  type        = string
  description = "ZoneID for DNS Hostnames of MSK Brokers"
}

variable "kafka_version" {
  type        = string
  description = "Specify the desired Kafka software version"
}

variable "broker_instance_type" {
  type        = string
  description = "Specify the instance type to use for the kafka brokers"
}

variable "number_of_broker_nodes" {
  type        = number
  description = "The desired total number of broker nodes in the kafka cluster. It must be a multiple of the number of specified client subnets."
}

variable "region" {
  type        = string
  description = "AWS region"
}
