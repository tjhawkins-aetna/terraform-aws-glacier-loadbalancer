variable "name" {
  type        = string
  description = "The name of the load balancer"
}

variable "environment" {
  type        = string
  description = "The environment for the load balancer"
}

variable "vpc" {
  type        = string
  description = "The vpc for the load balancer"
}

variable "subnets" {
  type        = list(string)
  description = "Subnet IDs."
}

variable "security_groups" {
  type        = list(string)
  description = "Security Group IDs."
}

variable "certificate_arn" {
  type        = string
  description = "Certificate ARN."
}
