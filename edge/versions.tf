# Optional layer. Skip for AVD-only, internal-only, or App Service products
# that use the built-in FQDN with no custom domain or Front Door.

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
