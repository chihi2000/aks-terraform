# Development Environment Outputs

##############################################
# AKS Cluster Outputs
##############################################

output "cluster_name" {
  description = "AKS cluster name"
  value       = module.aks_cluster.cluster_name
}

output "cluster_id" {
  description = "AKS cluster ID"
  value       = module.aks_cluster.cluster_id
}

output "cluster_fqdn" {
  description = "AKS cluster FQDN"
  value       = module.aks_cluster.cluster_fqdn
  sensitive   = true
}

output "kube_config" {
  description = "Raw kubeconfig"
  value       = module.aks_cluster.kube_config_raw
  sensitive   = true
}

output "get_credentials_command" {
  description = "Command to get AKS credentials"
  value       = "az aks get-credentials --resource-group ${data.azurerm_resource_group.main.name} --name ${module.aks_cluster.cluster_name}"
}

##############################################
# Network Outputs
##############################################

output "vnet_id" {
  description = "VNet ID"
  value       = module.network.vnet_id
}

output "vnet_name" {
  description = "VNet name"
  value       = module.network.vnet_name
}

output "subnet_ids" {
  description = "Subnet IDs"
  value       = module.network.vnet_subnets
}

##############################################
# Container Registry Outputs
##############################################

output "acr_name" {
  description = "ACR name"
  value       = var.enable_acr ? azurerm_container_registry.acr[0].name : null
}

output "acr_login_server" {
  description = "ACR login server URL"
  value       = var.enable_acr ? azurerm_container_registry.acr[0].login_server : null
}

output "acr_id" {
  description = "ACR resource ID"
  value       = var.enable_acr ? azurerm_container_registry.acr[0].id : null
}

##############################################
# Monitoring Outputs
##############################################

output "log_analytics_workspace_id" {
  description = "Log Analytics Workspace ID"
  value       = azurerm_log_analytics_workspace.aks.id
}

output "log_analytics_workspace_name" {
  description = "Log Analytics Workspace name"
  value       = azurerm_log_analytics_workspace.aks.name
}

##############################################
# Resource Group Outputs
##############################################

output "resource_group_name" {
  description = "Resource group name"
  value       = data.azurerm_resource_group.main.name
}

output "resource_group_location" {
  description = "Resource group location"
  value       = data.azurerm_resource_group.main.location
}

output "node_resource_group" {
  description = "AKS node resource group"
  value       = module.aks_cluster.node_resource_group
}

##############################################
# Flux CD Outputs
##############################################

output "flux_enabled" {
  description = "Flux CD enabled status"
  value       = var.enable_flux
}

output "flux_namespace" {
  description = "Flux CD namespace"
  value       = var.enable_flux ? "flux-system" : null
}
