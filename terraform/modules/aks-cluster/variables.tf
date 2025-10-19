# AKS Cluster Module Variables

variable "location" {
  description = "Azure region where resources will be created"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "cluster_name" {
  description = "Name of the AKS cluster (optional, generated if not provided)"
  type        = string
  default     = null
}

variable "cluster_name_random_suffix" {
  description = "Add random suffix to cluster name"
  type        = bool
  default     = true
}

variable "sku_tier" {
  description = "SKU tier for AKS (Free, Standard, Premium)"
  type        = string
  default     = "Standard"
  validation {
    condition     = contains(["Free", "Standard", "Premium"], var.sku_tier)
    error_message = "SKU tier must be Free, Standard, or Premium."
  }
}

variable "automatic_channel_upgrade" {
  description = "Automatic upgrade channel (patch, rapid, node-image, stable, none)"
  type        = string
  default     = "node-image"
}

variable "node_os_channel_upgrade" {
  description = "Node OS upgrade channel"
  type        = string
  default     = "NodeImage"
}

variable "log_analytics_workspace_enabled" {
  description = "Enable Log Analytics workspace"
  type        = bool
  default     = true
}

variable "log_analytics_workspace" {
  description = "Log Analytics workspace configuration"
  type = object({
    id   = string
    name = string
  })
  default = null
}

variable "enable_auto_scaling" {
  description = "Enable autoscaling for default node pool"
  type        = bool
  default     = false
}

variable "agents_count" {
  description = "Number of agents in default node pool"
  type        = number
  default     = 2
}

variable "agents_size" {
  description = "VM size for default node pool"
  type        = string
  default     = "Standard_D2s_v3"
}

variable "agents_max_count" {
  description = "Maximum number of agents (if autoscaling enabled)"
  type        = number
  default     = null
}

variable "agents_min_count" {
  description = "Minimum number of agents (if autoscaling enabled)"
  type        = number
  default     = null
}

variable "vnet_subnet_id" {
  description = "Subnet ID for AKS nodes"
  type        = string
}

variable "network_plugin" {
  description = "Network plugin (azure, kubenet)"
  type        = string
  default     = "azure"
}

variable "network_policy" {
  description = "Network policy (azure, calico)"
  type        = string
  default     = "azure"
}

variable "load_balancer_sku" {
  description = "Load balancer SKU (basic, standard)"
  type        = string
  default     = "standard"
}

variable "node_pools" {
  description = "Additional node pools"
  type = map(object({
    name           = string
    vm_size        = string
    node_count     = number
    vnet_subnet_id = string
    max_count      = optional(number)
    min_count      = optional(number)
    node_labels    = optional(map(string))
    node_taints    = optional(list(string))
  }))
  default = {}
}

variable "local_account_disabled" {
  description = "Disable local accounts (use AAD only)"
  type        = bool
  default     = false
}

variable "role_based_access_control_enabled" {
  description = "Enable RBAC"
  type        = bool
  default     = true
}

variable "rbac_aad" {
  description = "Enable Azure AD RBAC"
  type        = bool
  default     = false
}

variable "rbac_aad_managed" {
  description = "Use AKS-managed Azure AD integration"
  type        = bool
  default     = false
}

variable "rbac_aad_admin_group_object_ids" {
  description = "Azure AD group object IDs for cluster admin"
  type        = list(string)
  default     = []
}

variable "private_cluster_enabled" {
  description = "Enable private cluster"
  type        = bool
  default     = false
}

variable "node_resource_group" {
  description = "Name of the node resource group"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
