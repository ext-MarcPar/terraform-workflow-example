locals {
  state_backend = {
    resource_group_name  = "pl-tfstate-prd-rg"
    storage_account_name = "onterristfstateprd"
    container_name       = "tfstate"
    use_oidc             = true
  }
  bu_code      = "ct"
  product_name = "example01"
}

# L5 Edge depends on L3 Compute (for origin endpoint IDs).
# Only add data.terraform_remote_state.workloads if your edge origins
# reference resource IDs that the workloads layer creates.
data "terraform_remote_state" "core" {
  backend = "azurerm"
  config  = merge(local.state_backend, {
    key = "${local.bu_code}/${local.product_name}/core/terraform.tfstate"
  })
}

data "terraform_remote_state" "compute" {
  backend = "azurerm"
  config  = merge(local.state_backend, {
    key = "${local.bu_code}/${local.product_name}/compute/terraform.tfstate"
  })
}
