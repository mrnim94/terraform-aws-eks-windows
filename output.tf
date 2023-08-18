output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = module.eks.cluster_certificate_authority_data
}

output "cluster_endpoint" {
  description = "Endpoint for the EKS cluster. Used to communicate with the cluster."
  value       = module.eks.cluster_endpoint
}

output "cluster_id" {
  description = "The unique identifier for the EKS cluster"
  value       = module.eks.cluster_id
}

output "oidc_provider_arn" {
  description = "ARN of the OIDC provider for the EKS cluster. Used for setting up IAM roles for service accounts."
  value       = module.eks.oidc_provider_arn
}