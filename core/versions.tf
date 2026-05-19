terraform {
  required_version = "~> 1.11"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.20.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.0"
    }
  }

  # Partial backend — resource_group_name, storage_account_name, container_name,
  # and key are all injected by CI via -backend-config flags.
  backend "azurerm" {
    use_oidc = true
  }
}

provider "azurerm" {
  use_oidc = true
  features {}
}

provider "azuread" {
  use_oidc  = true
  tenant_id = var.tenant_id
}
