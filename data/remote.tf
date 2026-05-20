# Single source of truth for upstream state reads in this tier.
#
# RULE: per-project sub-modules never call data "terraform_remote_state"
# directly. They receive everything as input variables passed from main.tf.
#
# ── PoC mode ──────────────────────────────────────────────────────────────────
# Remote state reads are commented out while using the local backend.
# To wire up to real Azure:
#   1. Restore backend "azurerm" { use_oidc = true } in versions.tf
#   2. Update the state_backend locals below to match your environment
#   3. Uncomment the data "terraform_remote_state" "core" block
#   4. In main.tf, add: locals { core = data.terraform_remote_state.core.outputs }

# locals {
#   state_backend = {
#     resource_group_name  = "pl-tfstate-prd-rg"   # ← your state RG
#     storage_account_name = "onterristfstateprd"   # ← your state SA
#     container_name       = "tfstate"
#     use_oidc             = true
#   }
#   bu_code      = "ct"        # matches BU_CODE repo variable
#   product_name = "example01" # matches PRODUCT_NAME repo variable
# }
#
# data "terraform_remote_state" "core" {
#   backend = "azurerm"
#   config  = merge(local.state_backend, {
#     key = "${local.bu_code}/${local.product_name}/core/terraform.tfstate"
#   })
# }
