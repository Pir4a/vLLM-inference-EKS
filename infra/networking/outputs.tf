output "vpc_id" {
  description = "ID of the VPC. Consumed by EKS cluster + security groups in compute/."
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of public subnets (single element in single-AZ). Used by the ALB."
  value       = module.vpc.public_subnets
}

output "private_subnet_ids" {
  description = "IDs of private subnets (single element in single-AZ). Used by EKS node groups."
  value       = module.vpc.private_subnets
}
