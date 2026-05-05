variable "project_name" {
  description = "Project identifier propagated as the VPC `Name` tag and prefix for sub-resources."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block of the VPC (e.g. 10.0.0.0/16)."
  type        = string
}

variable "availability_zone" {
  description = "Single AZ for both subnets. Enforces single-AZ topology — see ADR-006."
  type        = string
}

variable "public_subnet_cidr" {
  description = "CIDR for the public subnet hosting the ALB and the NAT Gateway."
  type        = string
}

variable "private_subnet_cidr" {
  description = "CIDR for the private subnet hosting EKS worker nodes (CPU and GPU node groups)."
  type        = string
}
