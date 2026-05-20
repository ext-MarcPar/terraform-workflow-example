# ── PoC mode: remote state reads disabled ─────────────────────────────────────
# To wire up to real Azure, restore backend "azurerm" in versions.tf, then
# uncomment below and add `locals { core = ..., data = ... }` to main.tf.

# locals {
#   state_backend = {
#     resource_group_name  = "pl-tfstate-prd-rg"
#     storage_account_name = "onterristfstateprd"
#     container_name       = "tfstate"
#     use_oidc             = true
#   }
#   bu_code      = "ct"
#   product_name = "example01"
# }
#
# data "terraform_remote_state" "core" {
#   backend = "azurerm"
#   config  = merge(local.state_backend, {
#     key = "${local.bu_code}/${local.product_name}/core/terraform.tfstate"
#   })
# }
#
# data "terraform_remote_state" "data" {
#   backend = "azurerm"
#   config  = merge(local.state_backend, {
#     key = "${local.bu_code}/${local.product_name}/data/terraform.tfstate"
#   })
# }
