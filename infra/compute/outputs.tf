output "cluster_name" {
  description = "EKS cluster name. Use with `aws eks update-kubeconfig --name <X>` to configure kubectl."
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS API server endpoint."
  value       = module.eks.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  description = "Base64-encoded CA certificate for kubectl client trust."
  value       = module.eks.cluster_certificate_authority_data
}

output "cluster_oidc_issuer_url" {
  description = "OIDC provider URL exposed by the cluster. Required for IRSA — used later by KEDA and vLLM service accounts."
  value       = module.eks.cluster_oidc_issuer_url
}
