terraform {
  required_version = "~> 1.11"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.20.0"
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
