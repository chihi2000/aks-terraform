# AKS Cluster Module
# This module creates an AKS cluster with best practices

module "aks" {
  source  = "Azure/aks/azurerm"
  version = "8.0.0"

  # Basic Configuration
  location            = var.location
  resource_group_name = var.resource_group_name
  prefix              = var.prefix
  cluster_name        = var.cluster_name
  cluster_name_random_suffix = var.cluster_name_random_suffix

  # SKU and Upgrade Strategy
  sku_tier                  = var.sku_tier
  automatic_channel_upgrade = var.automatic_channel_upgrade
  node_os_channel_upgrade   = var.node_os_channel_upgrade

  # Monitoring
  log_analytics_workspace_enabled = var.log_analytics_workspace_enabled
  log_analytics_workspace         = var.log_analytics_workspace

  # System Node Pool
  enable_auto_scaling = var.enable_auto_scaling
  agents_count        = var.agents_count
  agents_size         = var.agents_size
  agents_max_count    = var.agents_max_count
  agents_min_count    = var.agents_min_count

  # Networking
  vnet_subnet_id  = var.vnet_subnet_id
  network_plugin  = var.network_plugin
  network_policy  = var.network_policy
  load_balancer_sku = var.load_balancer_sku

  # Additional Node Pools
  node_pools = var.node_pools

  # RBAC
  local_account_disabled            = var.local_account_disabled
  role_based_access_control_enabled = var.role_based_access_control_enabled
  rbac_aad                          = var.rbac_aad
  rbac_aad_managed                  = var.rbac_aad_managed
  rbac_aad_admin_group_object_ids   = var.rbac_aad_admin_group_object_ids

  # Security
  private_cluster_enabled = var.private_cluster_enabled

  # Node Resource Group
  node_resource_group = var.node_resource_group

  # Tags
  tags = var.tags
}
