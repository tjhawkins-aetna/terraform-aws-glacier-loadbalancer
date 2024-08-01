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
  type        = string
  description = "Security Groups"
}

variable "security_group_cidr_range" {
  type        = string
  default     = "10.208.0.0/16"
  description = "Security Group CIDR range."
}

variable "certificate_arn" {
  type        = string
  description = "Certificate ARN."
}

# tflint-ignore: terraform_naming_convention
variable "target_ec2" {
  type        = string
  description = "Target EC2 instance."
}

variable "port_number" {
  type        = string
  default     = 443
  description = "Source port number."
}

variable "target_port_number" {
  type        = string
  default     = 443
  description = "Target port number."
}

variable "endpoint" {
  type        = string
  description = "Endpoint."
}
