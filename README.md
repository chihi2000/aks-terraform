# Production-Ready AKS Infrastructure with GitOps

> Enterprise-grade Azure Kubernetes Service with automated deployments using Terraform, Flux CD, and Kustomize in a single monorepo.

[![Terraform](https://img.shields.io/badge/Terraform-1.5+-623CE4?logo=terraform)](https://www.terraform.io/)
[![Azure](https://img.shields.io/badge/Azure-AKS-0078D4?logo=microsoft-azure)](https://azure.microsoft.com/)
[![Flux CD](https://img.shields.io/badge/Flux-v2-5468FF?logo=flux)](https://fluxcd.io/)

---

## 🎯 Project Goal

Build a **production-ready Kubernetes platform on Azure** with:
- Automated infrastructure provisioning via Terraform
- GitOps-based continuous deployment via Flux CD
- Zero-downtime application updates
- Production-grade security and high availability
- Multi-environment support (dev/staging/prod)

**Result:** Push code → Automatic build → Automatic deploy → Zero downtime

---

## 🏗️ Architecture

### High-Level Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                         AZURE CLOUD                             │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  AKS Cluster (Kubernetes)                                │  │
│  │  ┌────────────────┐  ┌──────────────────────────────┐   │  │
│  │  │ System Nodes   │  │  Application Nodes           │   │  │
│  │  │ • CoreDNS      │  │  ┌────────────────────────┐  │   │  │
│  │  │ • Metrics      │  │  │  Your Application      │  │   │  │
│  │  │ • Flux CD      │  │  │  • Auto-scaling (HPA)  │  │   │  │
│  │  └────────────────┘  │  │  • Load Balanced       │  │   │  │
│  │                      │  │  • Health Monitored    │  │   │  │
│  │                      │  └────────────────────────┘  │   │  │
│  │                      └──────────────────────────────┘   │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
│  ┌──────────────────┐        ┌──────────────────┐             │
│  │ Container        │        │ Log Analytics    │             │
│  │ Registry (ACR)   │        │ Workspace        │             │
│  │ • Private images │        │ • Monitoring     │             │
│  └──────────────────┘        └──────────────────┘             │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                         GITHUB                                  │
│  ┌───────────────┐   ┌──────────────┐   ┌─────────────────┐   │
│  │ app-source-   │   │ terraform/   │   │ app-manifests/  │   │
│  │ code/         │   │              │   │ (Flux watches)  │   │
│  │ • .NET API    │   │ • Infra code │   │ • K8s configs   │   │
│  └───────────────┘   └──────────────┘   └─────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

### Deployment Flow

```
┌──────────────┐
│  Developer   │
│  Pushes Code │
└──────┬───────┘
       │
       ▼
┌──────────────────────┐
│  GitHub Actions      │
│  • Build Docker      │
│  • Push to ACR       │
│  • Update Manifests  │
└──────┬───────────────┘
       │
       ▼
┌──────────────────────┐
│  Flux CD (in AKS)    │
│  • Watches Git       │
│  • Detects Change    │
│  • Applies Updates   │
└──────┬───────────────┘
       │
       ▼
┌──────────────────────┐
│  AKS Cluster         │
│  • Rolling Update    │
│  • Zero Downtime     │
│  • Health Checks     │
└──────────────────────┘
```

**Timeline:** Code push → Production in ~5 minutes

---

## 📁 Repository Structure

```
aks-terraform/                      # Single monorepo for everything
│
├── terraform/                      # Infrastructure as Code
│   ├── modules/aks-cluster/       # Reusable AKS module
│   └── environments/
│       └── dev/                    # Dev environment config
│           ├── main.tf            # Main infrastructure
│           ├── variables.tf       # Input variables
│           ├── outputs.tf         # Outputs (cluster name, ACR, etc)
│           └── terraform.tfvars.example
│
├── app-source-code/               # Application code (.NET API)
│   ├── Program.cs                 # Application logic
│   ├── Dockerfile                 # Container image definition
│   └── .github/workflows/
│       └── build-and-push.yml     # CI/CD pipeline
│
├── app-manifests/                 # Kubernetes manifests (Flux syncs this)
│   ├── base/                      # Base configuration
│   │   ├── namespace.yaml         # Application namespace
│   │   ├── deployment.yaml        # Pod definition with security
│   │   ├── service.yaml           # Load balancer
│   │   ├── hpa.yaml              # Auto-scaling rules
│   │   ├── pdb.yaml              # Disruption budget
│   │   └── network-policy.yaml   # Network security
│   └── overlays/
│       ├── dev/                   # Dev: 2 replicas, 128Mi RAM
│       └── prod/                  # Prod: 5 replicas, 512Mi RAM
│
├── .github/workflows/
│   └── terraform.yml              # Infrastructure CI/CD
│
└── scripts/                       # Helper scripts
    ├── validate-manifests.sh
    └── setup-remote-state.sh
```

**Key Design:** Monorepo with path-filtered workflows (only relevant pipelines trigger)

---

##  Implementation Guide

### Prerequisites

```bash
# Required tools
terraform >= 1.5.0
az-cli >= 2.40.0
kubectl >= 1.27

# Azure setup
az login
az account set --subscription "YOUR-SUBSCRIPTION-ID"

# Create resource group
az group create --name myproject-rg --location eastus
```

### Step 1: Configure Infrastructure

```bash
# 1. Navigate to terraform directory
cd terraform/environments/dev/

# 2. Create configuration from template
cp terraform.tfvars.example terraform.tfvars

# 3. Edit terraform.tfvars (minimum required):
subscription_id     = "your-azure-subscription-id"
resource_group_name = "myproject-rg"
prefix              = "mycompany"  # Max 10 chars, lowercase

# For GitOps
flux_git_repo_url = "https://github.com/YOUR-USERNAME/aks-terraform"
```

### Step 2: Deploy Infrastructure (~10 minutes)

```bash
# Initialize Terraform
terraform init

# Review what will be created
terraform plan

# Deploy infrastructure
terraform apply

# Expected output:
#  AKS cluster (3 nodes: 2 system + 1 app)
#  Azure Container Registry
# Flux CD installed and configured
# Virtual Network with subnet
#  Log Analytics workspace
```

### Step 3: Connect to Cluster

```bash
# Get cluster credentials
az aks get-credentials \
  --resource-group $(terraform output -raw resource_group_name) \
  --name $(terraform output -raw cluster_name)

# Verify connection
kubectl get nodes

# Expected output:
# NAME                                STATUS   ROLES   AGE
# aks-default-12345678-vmss000000    Ready    agent   5m
# aks-default-12345678-vmss000001    Ready    agent   5m
# aks-app-12345678-vmss000000        Ready    agent   5m
```

### Step 4: Configure GitHub Secrets

In your GitHub repository settings, add these secrets:

```
AZURE_CLIENT_ID         # From service principal
AZURE_TENANT_ID         # Azure tenant ID
AZURE_SUBSCRIPTION_ID   # Azure subscription ID
RESOURCE_GROUP_NAME     # Your resource group name
PREFIX                  # Same as terraform prefix
ACR_NAME               # From: terraform output acr_name
ACR_LOGIN_SERVER       # From: terraform output acr_login_server
```

### Step 5: Deploy Application

```bash
# Method 1: Automatic (via Git push)
echo "// trigger deployment" >> app-source-code/Program.cs
git add app-source-code/
git commit -m "feat: initial deployment"
git push origin main

# GitHub Actions will:
# 1. Build Docker image
# 2. Push to ACR
# 3. Update app-manifests/base/deployment.yaml
# 4. Commit manifest change
# 5. Flux detects change and deploys to AKS

# Method 2: Manual (for first time)
kubectl apply -k app-manifests/overlays/dev/

# Monitor deployment
kubectl get pods -n signin-app -w

# Watch Flux sync
flux logs --kind=Kustomization --follow
```

### Step 6: Verify Deployment

```bash
# Check application status
kubectl get all -n signin-app

# Get LoadBalancer IP
kubectl get svc signin-api -n signin-app
# Wait for EXTERNAL-IP to appear (~2 minutes)

# Test application
EXTERNAL_IP=$(kubectl get svc signin-api -n signin-app -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
curl http://$EXTERNAL_IP/health

# Expected: HTTP 200 OK
```

---

## Day-to-Day Usage

### Deploy Code Changes

```bash
# 1. Make changes to application
vim app-source-code/Program.cs

# 2. Commit and push
git add app-source-code/
git commit -m "feat: add new feature"
git push

# 3. Automatic deployment happens!
# Monitor at: https://github.com/YOUR-REPO/actions
```

### Update Infrastructure

```bash
# 1. Modify Terraform
vim terraform/environments/dev/main.tf

# 2. Review changes
cd terraform/environments/dev/
terraform plan

# 3. Apply changes
terraform apply
```

### Scale Application

```bash
# Manual scaling
kubectl scale deployment signin-api -n signin-app --replicas=5

# Or edit HPA limits
vim app-manifests/base/hpa.yaml
git commit -am "chore: increase max replicas to 20"
git push  # Flux auto-deploys
```

---

##  Multi-Environment Setup

### Create Production Environment

```bash
# 1. Copy dev environment
cp -r terraform/environments/dev terraform/environments/prod

# 2. Edit terraform/environments/prod/terraform.tfvars
# - Change resource_group_name
# - Set aks_sku_tier = "Standard"
# - Increase node counts
# - Set app_node_pool_auto_scaling = true
# - Update flux_git_repo_path = "./app-manifests/overlays/prod"

# 3. Deploy production
cd terraform/environments/prod/
terraform init
terraform apply
```

**Environment Comparison:**

| Feature | Development | Production |
|---------|-------------|------------|
| AKS Tier | Free | Standard (SLA) |
| System Nodes | 2x D2s_v3 | 3x D4s_v3 |
| App Nodes | 1x D2s_v3 | 5x D4s_v3 |
| Auto-scaling | Manual | Enabled (5-20) |
| Replicas | 2 | 5 |
| Resources | 128Mi/100m CPU | 512Mi/500m CPU |
| ACR | Basic | Premium |
| Cost/Month | ~$245 | ~$1,800 |

---

##  Security Features

**Implemented:**
- Non-root containers (UID 1000)
- Read-only root filesystem
-  Dropped all Linux capabilities
- Network policies (pod isolation)
- Pod Disruption Budgets (HA)
- Managed identities (no passwords)
-  seccomp security profiles

**Production Recommendations:**
- Enable Azure AD RBAC
- Use private cluster
- Implement Azure Key Vault
- Enable Azure Policy
- Set up Azure Defender

---

##  Monitoring & Operations

```bash
# Cluster health
kubectl get nodes
kubectl top nodes

# Application logs
kubectl logs -n signin-app -l app=signin-api --tail=100 -f

# Flux status
flux get sources git
flux get kustomizations

# Force Flux sync (don't wait 1 minute)
flux reconcile source git app-manifests --with-source

# Metrics
kubectl top pods -n signin-app
```

---

##  Troubleshooting

**Pods not starting (ImagePullBackOff)**
```bash
# Verify ACR integration
az aks check-acr \
  --name CLUSTER-NAME \
  --resource-group RG-NAME \
  --acr YOUR-ACR.azurecr.io
```

**Flux not syncing**
```bash
# Check Flux status
kubectl get pods -n flux-system
flux logs --kind=GitRepository --name=app-manifests

# Force sync
flux reconcile source git app-manifests --with-source
```

**GitHub Actions not triggering**
```bash
# Verify path filters
git diff --name-only HEAD~1 HEAD

# Terraform workflow triggers on: **.tf
# Build workflow triggers on: app-source-code/**
```

---

##  Cost Management

**Development:** ~$245/month
- AKS control plane: Free
- 3x D2s_v3 nodes: $210
- ACR Basic: $5
- Log Analytics: $30

**Production:** ~$1,800/month
- AKS control plane: $73
- 8x D4s_v3 nodes: $1,120
- ACR Premium: $500
- Log Analytics: $100

**Cost Optimization:**
```bash
# Stop dev cluster when not in use
az aks stop --name CLUSTER --resource-group RG
az aks start --name CLUSTER --resource-group RG

# Enable cluster autoscaler
# Set log retention to 30 days for dev
# Use spot instances for non-critical workloads
```

---


## Production Readiness Checklist

Before going to production:

- [ ] Configure `terrform.tfvars` with production values
- [ ] Set up Azure AD RBAC
- [ ] Enable private cluster (if needed)
- [ ] Configure backup and disaster recovery
- [ ] Set up monitoring alerts
- [ ] Review and adjust resource limits
- [ ] Enable ACR geo-replication
- [ ] Configure terraform remote state backend
- [ ] Set up branch protection rules
- [ ] Document runbooks for common operations

---

##  Key Concepts

**Terraform Modules:** Reusable infrastructure code
**Kustomize Overlays:** Environment-specific configs without duplication
**Flux CD:** Kubernetes operator that syncs Git → Cluster
**GitOps:** Infrastructure/app config stored in Git, auto-deployed
**HPA:** Horizontal Pod Autoscaler - scales based on CPU/memory
**PDB:** Pod Disruption Budget - ensures availability during updates

---



##  Quick Commands Reference

```bash
# Deploy infrastructure
cd terraform/environments/dev && terraform apply

# Deploy application
kubectl apply -k app-manifests/overlays/dev/

# Scale manually
kubectl scale deployment signin-api -n signin-app --replicas=5

# View logs
kubectl logs -n signin-app -l app=signin-api -f

# Force Flux sync
flux reconcile source git app-manifests --with-source

# Get service URL
kubectl get svc signin-api -n signin-app
```

---


*Built with Terraform + Flux CD + Kustomize for production-grade Kubernetes on Azure*
