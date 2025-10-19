# Development Environment
# This is the main configuration for the development AKS cluster

terraform {
  required_version = ">= 1.5.0"

  # Configure remote state for production use
  # backend "azurerm" {
  #   resource_group_name  = "terraform-state-rg"
  #   storage_account_name = "tfstatedev<uniqueid>"
  #   container_name       = "tfstate"
  #   key                  = "dev/aks.tfstate"
  # }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

# Providers
provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = true
    }
    key_vault {
      purge_soft_delete_on_destroy = false
    }
  }
  subscription_id = var.subscription_id
  #skip_provider_registration = true
}

provider "kubernetes" {
  host                   = module.aks_cluster.cluster_fqdn
  client_certificate     = base64decode(module.aks_cluster.client_certificate)
  client_key             = base64decode(module.aks_cluster.client_key)
  cluster_ca_certificate = base64decode(module.aks_cluster.cluster_ca_certificate)
}

provider "helm" {
  kubernetes {
    host                   = module.aks_cluster.cluster_fqdn
    client_certificate     = base64decode(module.aks_cluster.client_certificate)
    client_key             = base64decode(module.aks_cluster.client_key)
    cluster_ca_certificate = base64decode(module.aks_cluster.cluster_ca_certificate)
  }
}

# Data Sources
data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

data "azurerm_client_config" "current" {}

# Local Variables
locals {
  environment = "dev"
  location    = data.azurerm_resource_group.main.location

  common_tags = merge(
    var.common_tags,
    {
      Environment = "Development"
      ManagedBy   = "Terraform"
      Workspace   = terraform.workspace
    }
  )

  # Network Configuration
  vnet_name           = "${var.prefix}-${local.environment}-vnet"
  node_resource_group = "MC_${var.resource_group_name}_${var.prefix}-${local.environment}-aks_${local.location}"
}

# Random suffix for globally unique names
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

##############################################
# Network Module
##############################################

module "network" {
  source  = "Azure/vnet/azurerm"
  version = "4.1.0"

  resource_group_name = data.azurerm_resource_group.main.name
  vnet_location       = local.location
  use_for_each        = true

  vnet_name       = local.vnet_name
  address_space   = var.vnet_address_space
  subnet_names    = keys(var.subnet_configuration)
  subnet_prefixes = values(var.subnet_configuration)

  tags = local.common_tags
}

##############################################
# Monitoring Module
##############################################

resource "azurerm_log_analytics_workspace" "aks" {
  name                = "${var.prefix}-${local.environment}-logs"
  location            = local.location
  resource_group_name = data.azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = var.log_retention_days

  tags = merge(
    local.common_tags,
    {
      Purpose = "AKS Monitoring"
    }
  )
}

##############################################
# Container Registry Module
##############################################

resource "azurerm_container_registry" "acr" {
  count               = var.enable_acr ? 1 : 0
  name                = "${var.prefix}acr${random_string.suffix.result}"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = local.location
  sku                 = var.acr_sku
  admin_enabled       = false

  # Enable for production
  # georeplications {
  #   location = "East US"
  #   tags     = local.common_tags
  # }

  tags = merge(
    local.common_tags,
    {
      Purpose = "Container Registry"
    }
  )
}

##############################################
# AKS Cluster Module
##############################################

module "aks_cluster" {
  source = "../../modules/aks-cluster"

  location            = local.location
  resource_group_name = data.azurerm_resource_group.main.name
  prefix              = var.prefix
  cluster_name        = "${var.prefix}-${local.environment}-aks"

  sku_tier                  = var.aks_sku_tier
  automatic_channel_upgrade = "node-image"
  node_os_channel_upgrade   = "NodeImage"

  # Monitoring
  log_analytics_workspace_enabled = true
  log_analytics_workspace = {
    id   = azurerm_log_analytics_workspace.aks.id
    name = azurerm_log_analytics_workspace.aks.name
  }

  # System Node Pool
  enable_auto_scaling = var.system_node_pool_auto_scaling
  agents_count        = var.system_node_pool_count
  agents_min_count    = var.system_node_pool_auto_scaling ? var.system_node_pool_min_count : null
  agents_max_count    = var.system_node_pool_auto_scaling ? var.system_node_pool_max_count : null
  agents_size         = var.system_node_pool_vm_size

  # Networking
  vnet_subnet_id    = module.network.vnet_subnets_name_id["nodes"]
  network_plugin    = "azure"
  network_policy    = "azure"
  load_balancer_sku = "standard"

  # Application Node Pool
  node_pools = {
    app = {
      name           = "app"
      vm_size        = var.app_node_pool_vm_size
      node_count     = var.app_node_pool_count
      vnet_subnet_id = module.network.vnet_subnets_name_id["nodes"]
      min_count      = var.app_node_pool_auto_scaling ? var.app_node_pool_min_count : null
      max_count      = var.app_node_pool_auto_scaling ? var.app_node_pool_max_count : null
      node_labels = {
        role        = "application"
        environment = local.environment
      }
    }
  }

  # RBAC (disable AAD for development)
  local_account_disabled            = false
  role_based_access_control_enabled = true
  rbac_aad                          = false

  # Security
  private_cluster_enabled = false

  # Node Resource Group
  node_resource_group = local.node_resource_group

  tags = local.common_tags
}

##############################################
# ACR Integration
##############################################

resource "azurerm_role_assignment" "aks_acr_pull" {
  count                            = var.enable_acr ? 1 : 0
  principal_id                     = module.aks_cluster.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = azurerm_container_registry.acr[0].id
  skip_service_principal_aad_check = true
}

##############################################
# Flux CD Installation
##############################################

resource "helm_release" "flux" {
  count = var.enable_flux ? 1 : 0

  repository       = "https://fluxcd-community.github.io/helm-charts"
  chart            = "flux2"
  name             = "flux2"
  namespace        = "flux-system"
  create_namespace = true
  version          = var.flux_version

  depends_on = [module.aks_cluster]
}

##############################################
# Flux GitOps Configuration
##############################################

resource "kubernetes_manifest" "flux_git_source" {
  count = var.enable_flux && var.flux_git_repo_url != "" ? 1 : 0

  manifest = {
    apiVersion = "source.toolkit.fluxcd.io/v1"
    kind       = "GitRepository"
    metadata = {
      name      = "app-manifests"
      namespace = "flux-system"
    }
    spec = {
      interval = "1m"
      ref = {
        branch = var.flux_git_repo_branch
      }
      url = var.flux_git_repo_url
    }
  }

  depends_on = [helm_release.flux]
}

resource "kubernetes_manifest" "flux_app_kustomization" {
  count = var.enable_flux && var.flux_git_repo_url != "" ? 1 : 0

  manifest = {
    apiVersion = "kustomize.toolkit.fluxcd.io/v1"
    kind       = "Kustomization"
    metadata = {
      name      = "apps-${local.environment}"
      namespace = "flux-system"
    }
    spec = {
      path     = "${var.flux_git_repo_path}/overlays/${local.environment}"
      interval = "1m"
      sourceRef = {
        kind = "GitRepository"
        name = "app-manifests"
      }
      prune = true
    }
  }

  depends_on = [kubernetes_manifest.flux_git_source]
}
