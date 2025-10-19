#!/bin/bash
# Setup Azure Remote State Backend for Terraform

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}=== Azure Terraform Remote State Setup ===${NC}\n"

# Get parameters
ENVIRONMENT=${1:-dev}
RESOURCE_GROUP_NAME="terraform-state-rg"
STORAGE_ACCOUNT_NAME="tfstate${ENVIRONMENT}$(openssl rand -hex 4)"
CONTAINER_NAME="tfstate"
LOCATION="eastus"

echo "Environment: $ENVIRONMENT"
echo "Resource Group: $RESOURCE_GROUP_NAME"
echo "Storage Account: $STORAGE_ACCOUNT_NAME"
echo "Container: $CONTAINER_NAME"
echo "Location: $LOCATION"
echo ""

read -p "Continue with these settings? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
fi

# Check Azure CLI
command -v az >/dev/null 2>&1 || { echo -e "${RED}Azure CLI is required but not installed${NC}"; exit 1; }

# Check login
echo -e "\n${YELLOW}Checking Azure login...${NC}"
if ! az account show >/dev/null 2>&1; then
    echo -e "${RED}Not logged in to Azure${NC}"
    az login
fi

SUBSCRIPTION_ID=$(az account show --query id -o tsv)
echo -e "${GREEN}✓ Logged in to subscription: $SUBSCRIPTION_ID${NC}"

# Create resource group
echo -e "\n${YELLOW}Creating resource group...${NC}"
if az group create --name "$RESOURCE_GROUP_NAME" --location "$LOCATION" >/dev/null 2>&1; then
    echo -e "${GREEN}✓ Resource group created${NC}"
else
    echo -e "${YELLOW}Resource group already exists${NC}"
fi

# Create storage account
echo -e "\n${YELLOW}Creating storage account...${NC}"
if az storage account create \
    --name "$STORAGE_ACCOUNT_NAME" \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --location "$LOCATION" \
    --sku Standard_LRS \
    --encryption-services blob \
    --tags Environment="$ENVIRONMENT" ManagedBy="Terraform" >/dev/null 2>&1; then
    echo -e "${GREEN}✓ Storage account created${NC}"
else
    echo -e "${RED}✗ Failed to create storage account${NC}"
    exit 1
fi

# Get storage account key
ACCOUNT_KEY=$(az storage account keys list --resource-group "$RESOURCE_GROUP_NAME" --account-name "$STORAGE_ACCOUNT_NAME" --query '[0].value' -o tsv)

# Create container
echo -e "\n${YELLOW}Creating blob container...${NC}"
if az storage container create \
    --name "$CONTAINER_NAME" \
    --account-name "$STORAGE_ACCOUNT_NAME" \
    --account-key "$ACCOUNT_KEY" >/dev/null 2>&1; then
    echo -e "${GREEN}✓ Blob container created${NC}"
else
    echo -e "${YELLOW}Container already exists${NC}"
fi

# Enable versioning
echo -e "\n${YELLOW}Enabling blob versioning...${NC}"
az storage account blob-service-properties update \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --account-name "$STORAGE_ACCOUNT_NAME" \
    --enable-versioning true >/dev/null 2>&1
echo -e "${GREEN}✓ Blob versioning enabled${NC}"

# Output backend configuration
echo -e "\n${GREEN}=== Backend Configuration ===${NC}"
echo -e "\nAdd this to your terraform block in main.tf:\n"

cat <<EOF
terraform {
  backend "azurerm" {
    resource_group_name  = "$RESOURCE_GROUP_NAME"
    storage_account_name = "$STORAGE_ACCOUNT_NAME"
    container_name       = "$CONTAINER_NAME"
    key                  = "$ENVIRONMENT/aks.tfstate"
  }
}
EOF

echo -e "\n${GREEN}=== Environment Variables ===${NC}"
echo -e "\nOr set these environment variables:\n"

cat <<EOF
export ARM_ACCESS_KEY="$ACCOUNT_KEY"
EOF

echo -e "\n${GREEN}=== Initialization Command ===${NC}"
echo -e "\nRun this to migrate state:\n"
echo "  cd terraform/environments/$ENVIRONMENT/"
echo "  terraform init -migrate-state"

echo -e "\n${GREEN}=== Cleanup ===${NC}"
echo -e "\nTo delete remote state (WARNING: destructive):\n"
echo "  az group delete --name $RESOURCE_GROUP_NAME --yes --no-wait"

echo -e "\n${GREEN}✓ Remote state backend setup complete!${NC}\n"
