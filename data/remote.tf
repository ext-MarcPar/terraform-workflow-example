# Single source of truth for upstream state reads in this tier.
#
# RULE: per-project sub-modules (data/shared/, data/project1/) never call
# data "terraform_remote_state" directly. They receive everything as input
# variables passed from main.tf. This keeps sub-modules pure, testable,
# and readable in isolation.
#
# Reference: Platform_Deployment_Pattern_Followups_2026-05-11.md
# "Pattern Detail: remote.tf Consolidation Per Tier"

locals {
  # Update these to match your environment. The state storage account is
  # shared (platform-owned); the BU and product name are per-product-repo.
  state_backend = {
    resource_group_name  = "pl-tfstate-prd-rg"
    storage_account_name = "onterristfstateprd"
    container_name       = "tfstate"
    use_oidc             = true
  }
  bu_code      = "ct"        # 2-char BU code — matches BU_CODE repo variable
  product_name = "example01" # product + instance suffix — matches PRODUCT_NAME repo variable
}

data "terraform_remote_state" "core" {
  backend = "azurerm"
  config  = merge(local.state_backend, {
    key = "${local.bu_code}/${local.product_name}/core/terraform.tfstate"
  })
}
