output "vpc_id" {
  description = "ID of the VPC. Consumed by EKS cluster + security groups in compute/."
  value       = module.networking.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of public subnets (single element in single-AZ). Used by the ALB."
  value       = module.networking.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of private subnets (single element in single-AZ). Used by EKS node groups."
  value       = module.networking.private_subnet_ids
}

output "cluster_name" {
  description = "EKS cluster name. Use with `aws eks update-kubeconfig --name <X>` to configure kubectl."
  value       = module.compute.cluster_name
}

output "cluster_endpoint" {
  description = "EKS API server endpoint."
  value       = module.compute.cluster_endpoint
}
