# Development Environment Variables

##############################################
# Required Variables
##############################################

variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "resource_group_name" {
  description = "Name of existing resource group"
  type        = string
}

##############################################
# Basic Configuration
##############################################

variable "prefix" {
  description = "Prefix for all resource names"
  type        = string
  default     = "tacowagon"

  validation {
    condition     = length(var.prefix) <= 10 && can(regex("^[a-z0-9]+$", var.prefix))
    error_message = "Prefix must be alphanumeric lowercase and max 10 characters."
  }
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    Project    = "AKS-Infrastructure"
    CostCenter = "Engineering"
    Owner      = "Platform-Team"
  }
}

##############################################
# Network Configuration
##############################################

variable "vnet_address_space" {
  description = "VNet address space"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "subnet_configuration" {
  description = "Subnet configuration map"
  type        = map(string)
  default = {
    nodes = "10.0.1.0/24"
  }
}

##############################################
# AKS Configuration
##############################################

variable "aks_sku_tier" {
  description = "AKS SKU tier (Free for dev, Standard for prod)"
  type        = string
  default     = "Free"
}

variable "system_node_pool_count" {
  description = "Number of system nodes"
  type        = number
  default     = 2
}

variable "system_node_pool_vm_size" {
  description = "VM size for system node pool"
  type        = string
  default     = "Standard_D2s_v3"
}

variable "system_node_pool_auto_scaling" {
  description = "Enable autoscaling for system node pool"
  type        = bool
  default     = false
}

variable "system_node_pool_min_count" {
  description = "Minimum nodes for system pool (if autoscaling enabled)"
  type        = number
  default     = 2
}

variable "system_node_pool_max_count" {
  description = "Maximum nodes for system pool (if autoscaling enabled)"
  type        = number
  default     = 5
}

variable "app_node_pool_count" {
  description = "Number of application nodes"
  type        = number
  default     = 1
}

variable "app_node_pool_vm_size" {
  description = "VM size for application node pool"
  type        = string
  default     = "Standard_D2s_v3"
}

variable "app_node_pool_auto_scaling" {
  description = "Enable autoscaling for app node pool"
  type        = bool
  default     = false
}

variable "app_node_pool_min_count" {
  description = "Minimum nodes for app pool (if autoscaling enabled)"
  type        = number
  default     = 1
}

variable "app_node_pool_max_count" {
  description = "Maximum nodes for app pool (if autoscaling enabled)"
  type        = number
  default     = 3
}

##############################################
# Container Registry
##############################################

variable "enable_acr" {
  description = "Enable Azure Container Registry"
  type        = bool
  default     = true
}

variable "acr_sku" {
  description = "ACR SKU (Basic for dev, Standard/Premium for prod)"
  type        = string
  default     = "Basic"
}

##############################################
# Monitoring
##############################################

variable "log_retention_days" {
  description = "Log Analytics retention period (days)"
  type        = number
  default     = 30
}

##############################################
# Flux CD (GitOps)
##############################################

variable "enable_flux" {
  description = "Enable Flux CD for GitOps"
  type        = bool
  default     = true
}

variable "flux_version" {
  description = "Flux Helm chart version"
  type        = string
  default     = "2.12.0"
}

variable "flux_git_repo_url" {
  description = "Git repository URL for Flux (leave empty to skip)"
  type        = string
  default     = ""
}

variable "flux_git_repo_branch" {
  description = "Git repository branch for Flux"
  type        = string
  default     = "main"
}

variable "flux_git_repo_path" {
  description = "Path within the Git repository for Flux to watch (for monorepo setup)"
  type        = string
  default     = "./app-manifests"
}
