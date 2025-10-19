# AKS Cluster Module Outputs

output "cluster_id" {
  description = "AKS cluster ID"
  value       = module.aks.aks_id
}

output "cluster_name" {
  description = "AKS cluster name"
  value       = module.aks.aks_name
}

output "cluster_fqdn" {
  description = "AKS cluster FQDN"
  value       = module.aks.cluster_fqdn
  sensitive   = true
}

output "kube_config_raw" {
  description = "Raw kubeconfig"
  value       = module.aks.kube_config_raw
  sensitive   = true
}

output "client_certificate" {
  description = "Client certificate"
  value       = module.aks.client_certificate
  sensitive   = true
}

output "client_key" {
  description = "Client key"
  value       = module.aks.client_key
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "Cluster CA certificate"
  value       = module.aks.cluster_ca_certificate
  sensitive   = true
}

output "kubelet_identity" {
  description = "Kubelet managed identity"
  value       = module.aks.kubelet_identity
}

output "node_resource_group" {
  description = "Node resource group name"
  value       = module.aks.node_resource_group
}
