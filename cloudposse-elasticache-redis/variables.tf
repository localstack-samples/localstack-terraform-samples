variable "region" {
  type        = string
  default     = "us-east-1"
  description = "AWS region"
}
variable "family" {
  type        = string
  description = "Redis cluster namespace"
}
variable "engine_version" {
  type        = string
  description = "Redis cluster namespace"
}