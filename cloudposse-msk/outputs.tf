output "cluster_arn" {
  description = "Amazon Resource Name (ARN) of the MSK cluster"
  value       = module.kafka.cluster_arn
}

output "config_arn" {
  description = "Amazon Resource Name (ARN) of the MSK configuration"
  value       = module.kafka.config_arn
}

output "hostname" {
  description = "DNS hostname of MSK cluster"
  value       = module.kafka.hostname
}

output "security_group_id" {
  description = "The ID of the security group rule for the MSK cluster"
  value       = module.kafka.security_group_id
}

output "security_group_name" {
  description = "The name of the security group rule for the MSK cluster"
  value       = module.kafka.security_group_name
}

output "cluster_name" {
  description = "The cluster name of the MSK cluster"
  value       = module.kafka.cluster_name
}

