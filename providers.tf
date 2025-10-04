provider "azurerm" {
  features {}
  subscription_id            = var.subscription_id
  skip_provider_registration = true
}
provider "helm" {
  kubernetes {
    host                   = module.app.cluster_fqdn
    client_certificate     = base64decode(module.app.client_certificate)
    client_key             = base64decode(module.app.client_key)
    cluster_ca_certificate = base64decode(module.app.cluster_ca_certificate)
  }
}