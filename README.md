# AKS Terraform Infrastructure

This repository contains Terraform configuration to deploy an Azure Kubernetes Service (AKS) cluster with Flux CD for GitOps-based deployments.

## Overview

This infrastructure automatically provisions:
- Azure Virtual Network (VNet) with custom subnet configuration
- Azure Kubernetes Service (AKS) cluster with:
  - System node pool (2 nodes, `Standard_D2s_v3`)
  - Application node pool (1 node, `Standard_D2s_v3`)
  - Azure CNI networking
  - Azure Network Policy
- Flux CD v2 for GitOps workflows

## Architecture

- **VNet Configuration**: Custom address space with configurable subnets
- **AKS Cluster**: Standard tier with auto-upgrade enabled for node images
- **Node Pools**:
  - System pool for cluster operations
  - Dedicated application pool for workloads
- **GitOps**: Flux CD deployed via Helm for continuous deployment

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) >= 1.0
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- Azure subscription with appropriate permissions
- Existing Azure Resource Group

## Required Variables

Create a `terraform.tfvars` file with the following variables:

```hcl
subscription_id      = "your-azure-subscription-id"
resource_group_name  = "your-existing-resource-group"
prefix              = " your preferred prefix "

vnet_address_space = ["10.0.0.0/16"]

subnet_configuration = {
  nodes = "10.0.1.0/24"
  # Add additional subnets as needed
}

common_tags = {
  Environment = "dev"
  ManagedBy   = "terraform"
}
```

## Usage

### Initialize Terraform

```bash
terraform init
```

### Plan Infrastructure

```bash
terraform plan
```

### Deploy Infrastructure

```bash
terraform apply
```

### Access the Cluster

After deployment, configure kubectl:

```bash
az aks get-credentials --resource-group <resource-group-name> --name <cluster-name>
```

### Retrieve Outputs

Get cluster connection details:

```bash
terraform output host
terraform output client_certificate
terraform output client_key
terraform output cluster_ca_certificate
```

## Modules Used

- [Azure/vnet/azurerm](https://registry.terraform.io/modules/Azure/vnet/azurerm) - Version 4.1.0
- [Azure/aks/azurerm](https://registry.terraform.io/modules/Azure/aks/azurerm) - Version 8.0.0
- [Flux CD Helm Chart](https://fluxcd-community.github.io/helm-charts) - Flux2

## Cluster Configuration

### Node Pools

| Pool | Type | VM Size | Node Count | Auto-scaling |
|------|------|---------|------------|--------------|
| System | Default | Standard_D2s_v3 | 2 | Disabled |
| Application | Custom | Standard_D2s_v3 | 1 | Disabled |

### Networking

- **Network Plugin**: Azure CNI
- **Network Policy**: Azure Network Policy
- **Load Balancer**: Standard SKU

## Security

- Role-Based Access Control (RBAC) enabled
- Local accounts enabled for initial setup
- Azure AD integration disabled (can be enabled via `rbac_aad` variable)

## Maintenance

- **Node OS Upgrade**: Automatic via NodeImage channel
- **Cluster Upgrade**: Automatic via node-image channel
- **Log Analytics**: Disabled (enable if monitoring is required)

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

⚠️ **Warning**: This will permanently delete all resources managed by this Terraform configuration.




