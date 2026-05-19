# Optional layer. Skip this directory entirely for App Service / VM products
# that have no Terraform-managed workload layer (app code ships via CI/CD pipelines).
# For AKS products, this layer holds cluster-bootstrap resources: ingress controller,
# cert-manager, base namespaces + RBAC. Application deployments ship via Argo CD / Flux.

terraform {
  required_version = "~> 1.11"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.20.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
  }
  backend "azurerm" {
    use_oidc = true
  }
}

provider "azurerm" {
  use_oidc = true
  features {}
}
