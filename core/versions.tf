terraform {
  required_version = "~> 1.11"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.20"
    }
  }

  # PoC: local backend — no Azure storage required.
  # Production: change to backend "azurerm" { use_oidc = true }
  backend "local" {}
}
